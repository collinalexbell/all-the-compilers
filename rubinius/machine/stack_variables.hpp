#ifndef RBX_SCOPE_VARIABLES_HPP
#define RBX_SCOPE_VARIABLES_HPP

#include "class/object.hpp"

namespace rubinius {
  class VariableScope;
  class Symbol;

  class StackVariables {
  public: // Treat these like private!
    VariableScope* on_heap_;
    VariableScope* parent_;
    Object* self_;
    Symbol* name_;
    Object* block_;
    Module* module_;
    Object* last_match_;
    Object* locals_[0];

  public:
    void initialize(Object* self, Symbol* name, Object* block, Module* module, int locals) {
      on_heap_ = 0;
      parent_ = 0;
      self_ = self;
      name_ = name;
      block_ = block;
      module_ = module;
      last_match_ = cNil;

      for(int i = 0; i < locals; i++) {
        locals_[i] = cNil;
      }
    }

    VariableScope* on_heap() const {
      return on_heap_;
    }

    VariableScope* parent() const {
      return parent_;
    }

    void set_parent(VariableScope* scope) {
      parent_ = scope;
    }

    void set_block(Object* block) {
      block_ = block;
    }

    Object* self() const {
      return self_;
    }

    Symbol* name() const {
      return name_;
    }

    Object* block() const {
      return block_;
    }

    Module* module() const {
      return module_;
    }

    bool made_alias_p() const {
      return on_heap_ != 0;
    }

    Object* get_local(int which) const {
      return locals_[which];
    }

    void set_local(int which, Object* val) {
      locals_[which] = val;
    }

    void set_last_match(STATE, Object* obj);

    Object* last_match(STATE);

    VariableScope* create_heap_alias(STATE, CallFrame* call_frame, bool full=true);
    void flush_to_heap(STATE);
  };

#define ALLOCA_STACKVARIABLES(local_size) \
  reinterpret_cast<StackVariables*>(alloca(sizeof(StackVariables) + (sizeof(Object*) * local_size)))
}

#endif
