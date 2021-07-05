#ifndef RBX_ARGUMENTS_HPP
#define RBX_ARGUMENTS_HPP

#include <stdint.h>
#include "class/array.hpp"
#include "class/tuple.hpp"

namespace rubinius {
  class Array;

  class Arguments {
    Symbol* name_;
    Object* recv_;
    Object* block_;

    uint32_t total_;
    Object** arguments_;
    Tuple* argument_container_;

  public:
    Arguments(Symbol* name, Object* recv, Object* block, uint32_t total, Object** buffer)
      : name_(name)
      , recv_(recv)
      , block_(block)
      , total_(total)
      , arguments_(buffer)
      , argument_container_(0)
    {}

    Arguments(Symbol* name, Object* recv, uint32_t total, Object** buffer)
      : name_(name)
      , recv_(recv)
      , block_(cNil)
      , total_(total)
      , arguments_(buffer)
      , argument_container_(0)
    {}

    Arguments(Symbol* name, uint32_t total, Object** buffer)
      : name_(name)
      , recv_(cNil)
      , block_(cNil)
      , total_(total)
      , arguments_(buffer)
      , argument_container_(0)
    {}

    Arguments(Symbol* name, Object* recv, Object* block)
      : name_(name)
      , recv_(recv)
      , block_(block)
      , total_(0)
      , arguments_(0)
      , argument_container_(0)
    {}

    Arguments(Symbol* name, Object* recv)
      : name_(name)
      , recv_(recv)
      , block_(cNil)
      , total_(0)
      , arguments_(0)
      , argument_container_(0)
    {}

    Arguments(Symbol* name)
      : name_(name)
      , recv_(cNil)
      , block_(cNil)
      , total_(0)
      , arguments_(0)
      , argument_container_(0)
    {}

    Arguments(Symbol* name, Object* recv, Object* block, Array* ary)
      : name_(name)
      , recv_(recv)
      , block_(block)
    {
      use_array(ary);
    }

    Arguments(Symbol* name, Object* recv, Array* ary)
      : name_(name)
      , recv_(recv)
      , block_(cNil)
    {
      use_array(ary);
    }

    Arguments(Symbol* name, Array* ary)
      : name_(name)
      , recv_(cNil)
      , block_(cNil)
    {
      use_array(ary);
    }

    Symbol* name() const {
      return name_;
    }

    void set_name(Symbol* n) {
      name_ = n;
    }

    Object* recv() const {
      return recv_;
    }

    Object*& recv_location() {
      return recv_;
    }

    void set_recv(Object* val) {
      recv_ = val;
    }

    Object* block() const {
      return block_;
    }

    Object*& block_location() {
      return block_;
    }

    void set_block(Object* val) {
      block_ = val;
    }

    Object* get_argument(uint32_t which) const {
      return arguments_[which];
    }

    Object** arguments() const {
      return arguments_;
    }

    Object**& arguments_location() {
      return arguments_;
    }

    Tuple* argument_container() const {
      return argument_container_;
    }

    void update_argument_container(Tuple* obj);

    uint32_t total() const {
      return total_;
    }

    void use_argument(Object* obj) {
      arguments_[0] = obj;
    }

    void use_array(Array* ary) {
      use_tuple(ary->tuple(), ary->size(), ary->offset());
    }

    void use_tuple(Tuple* tup, uint32_t size, uint32_t offset) {
      total_ = size;
      arguments_ = tup->field + offset;
      argument_container_ = tup;
    }

    void use_tuple(Tuple* tup, uint32_t size) {
      use_tuple(tup, size, 0);
    }

    Array* as_array(STATE);
    void append(STATE, Array* ary);
    void prepend(STATE, Array* ary);

    void unshift(STATE, Object* val);
    void unshift2(STATE, Object* val, Object* val2);

    Object* shift(STATE);
  };
}

#endif
