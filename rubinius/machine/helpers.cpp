#include "arguments.hpp"
#include "memory.hpp"
#include "call_frame.hpp"
#include "helpers.hpp"
#include "lookup_data.hpp"
#include "object_utils.hpp"
#include "on_stack.hpp"
#include "thread_state.hpp"

#include "class/object.hpp"
#include "class/autoload.hpp"
#include "class/symbol.hpp"
#include "class/module.hpp"
#include "class/compiled_code.hpp"
#include "class/class.hpp"
#include "class/lexical_scope.hpp"
#include "class/lookup_table.hpp"
#include "class/tuple.hpp"
#include "class/system.hpp"
#include "class/thread.hpp"
#include "class/channel.hpp"
#include "class/method_table.hpp"
#include "class/location.hpp"
#include "class/exception.hpp"

#include <sstream>

namespace rubinius {
  namespace Helpers {
    Object* const_get_under(STATE, Module* mod, Symbol* name, ConstantMissingReason* reason, Object* filter, bool replace_autoload) {
      *reason = vNonExistent;

      while(!mod->nil_p()) {
        Object* result = mod->get_const(state, name, G(sym_public), reason, false, replace_autoload);
        if(*reason == vFound) {
          if(result != filter) return result;
          *reason = vNonExistent;
        }
        if(*reason == vPrivate) break;

        // Don't stop when you see Object, because we need to check any
        // includes into Object as well, and they're found via superclass
        mod = mod->superclass();
      }

      state->set_constant_missing_reason(*reason);
      return cNil;
    }

    Object* const_get(STATE, Symbol* name, ConstantMissingReason* reason, Object* filter, bool replace_autoload) {
      LexicalScope *cur;
      Object* result;

      *reason = vNonExistent;

      CallFrame* frame = state->get_ruby_frame();

      // Ok, this has to be explained or it will be considered black magic.
      // The scope chain always ends with an entry at the top that contains
      // a parent of nil, and a module of Object. This entry is put in
      // regardless of lexical scoping, it's the fallback scope (the default
      // scope). This is not case when deriving from BasicObject, which is
      // explained later.
      //
      // When looking up a constant, we don't want to consider the fallback
      // scope (ie, Object) initially because we need to lookup up
      // the superclass chain first, because falling back on the default.
      //
      // The rub comes from the fact that if a user explicitly opens up
      // Object in their code, we DO consider it. Like:
      //
      // class Idiot
      //   A = 2
      // end
      //
      // class ::Object
      //   A = 1
      //   class Stupid < Idiot
      //     def foo
      //       p A
      //     end
      //   end
      // end
      //
      // In this code, when A is looked up, Object must be considering during
      // the scope walk, NOT during the superclass walk.
      //
      // So, in this case, foo would print "1", not "2".
      //
      // As indicated above, the fallback scope isn't used when the superclass
      // chain directly rooted from BasicObject. To determine this is the
      // case, we record whether Object is seen when looking up the superclass
      // chain. If Object isn't seen, this means we are directly deriving from
      // BasicObject.

      cur = frame->lexical_scope();
      while(!cur->nil_p()) {
        // Detect the toplevel scope (the default) and get outta dodge.
        if(cur->top_level_p(state)) break;

        result = cur->module()->get_const(state, name, G(sym_private), reason, false, replace_autoload);
        if(*reason == vFound) {
          if(result != filter) return result;
          *reason = vNonExistent;
        }

        cur = cur->parent();
      }

      // Now look up the superclass chain.
      Module *fallback = G(object);

      cur = frame->lexical_scope();
      if(!cur->nil_p()) {
        bool object_seen = false;
        Module* mod = cur->module();
        while(!mod->nil_p()) {
          if(mod == G(object)) {
            object_seen = true;
          }
          if(!object_seen && mod == G(basicobject)) {
            fallback = NULL;
          }

          result = mod->get_const(state, name, G(sym_private), reason, false, replace_autoload);
          if(*reason == vFound) {
            if(result != filter) return result;
            *reason = vNonExistent;
          }

          mod = mod->superclass();
        }
      }

      // Lastly, check the fallback scope (=Object) specifically if needed
      if(fallback) {
        result = fallback->get_const(state, name, G(sym_private), reason, true, replace_autoload);
        if(*reason == vFound) {
          if(result != filter) return result;
          *reason = vNonExistent;
        }
      }

      return cNil;
    }

    Object* const_missing_under(STATE, Module* under, Symbol* sym) {
      Array* args = Array::create(state, 1);
      args->set(state, 0, sym);
      return under->send(state, G(sym_const_missing), args);
    }

    Object* const_missing(STATE, Symbol* sym) {
      Module* under;

      CallFrame* call_frame = state->get_ruby_frame();

      LexicalScope* scope = call_frame->lexical_scope();
      if(scope->nil_p()) {
        under = G(object);
      } else {
        under = scope->module();
      }

      Array* args = Array::create(state, 1);
      args->set(state, 0, sym);
      return under->send(state, G(sym_const_missing), args);
    }

    Class* open_class(STATE, Object* super, Symbol* name, bool* created) {
      Module* under;

      CallFrame* call_frame = state->get_ruby_frame();

      if(call_frame->lexical_scope()->nil_p()) {
        under = G(object);
      } else {
        under = call_frame->lexical_scope()->module();
      }

      return open_class(state, under, super, name, created);
    }

    static Class* add_class(STATE, Module* under, Object* super, Symbol* name) {
      if(super->nil_p()) super = G(object);
      Class* cls = Class::create(state, as<Class>(super));

      cls->set_name(state, name, under);
      under->set_const(state, name, cls);

      return cls;
    }

    static Class* check_superclass(STATE, Class* cls, Object* super) {
      if(super->nil_p()) return cls;
      if(cls->true_superclass(state) != super) {
        std::ostringstream message;
        message << "Superclass mismatch: given "
                << as<Module>(super)->debug_str(state)
                << " but previously set to "
                << cls->true_superclass(state)->debug_str(state);
        Exception* exc =
          Exception::make_type_error(state, Class::type, super, message.str().c_str());
        exc->locations(state, Location::from_call_stack(state));
        state->raise_exception(exc);
        return NULL;
      }

      return cls;
    }

    Class* open_class(STATE, Module* under, Object* super, Symbol* name, bool* created) {
      ConstantMissingReason reason;

      *created = false;

      Object* obj = under->get_const(state, name, G(sym_public), &reason);

      if(reason == vFound) {
        OnStack<4> os(state, under, super, name, obj);

        if(Autoload* autoload = try_as<Autoload>(obj)) {
          obj = autoload->resolve(state, under, true);

          // Check if an exception occurred
          if(!obj) return NULL;
        }

        // Autoload::resolve will return nil if code loading failed, in which
        // case we ignore the autoload.
        if(!obj->nil_p()) {
          return check_superclass(state, as<Class>(obj), super);
        }
      }

      *created = true;
      return add_class(state, under, super, name);
    }

    Module* open_module(STATE, Symbol* name) {
      Module* under = G(object);

      CallFrame* call_frame = state->get_ruby_frame();

      if(!call_frame->lexical_scope()->nil_p()) {
        under = call_frame->lexical_scope()->module();
      }

      return open_module(state, under, name);
    }

    Module* open_module(STATE, Module* under, Symbol* name) {
      Module* module;
      ConstantMissingReason reason;

      Object* obj = under->get_const(state, name, G(sym_public), &reason);

      if(reason == vFound) {
        OnStack<3> os(state, under, name, obj);

        if(Autoload* autoload = try_as<Autoload>(obj)) {
          obj = autoload->resolve(state, under, true);
        }

        // Check if an exception occurred
        if(!obj) return NULL;

        // Autoload::resolve will return nil if code loading failed, in which
        // case we ignore the autoload.
        if(!obj->nil_p()) {
          return as<Module>(obj);
        }
      }

      module = Module::create(state);

      module->set_name(state, name, under);
      under->set_const(state, name, module);

      return module;
    }
  }
}
