export = ->(describe, it, assert) {

  describe("regular notation", ->{

    it("saves named functions to the current scope", ->{
      func foo() {}
      assert(typeof foo, "Function")
    })

    it("gives named functions the name property", ->{
      func foo() {}
      assert(foo.name, "foo")
    })

    it("gives anonymous functions the name of the property they were assigned to", ->{
      let foo = func() {}
      assert(foo.name, "foo")

      let bar = func qux() {}
      assert(bar.name, "qux")

      func abc() {}
      let asdf = abc
      assert(abc.name, "abc")
      assert(asdf.name, "abc")
    })

    it("gives anonymous functions an empty string as a name if they are not assigned", ->{
      assert(func() {}.name, "")
    })

  })

  describe("lambda notation", ->{

    it("allows the parens to be omitted", ->{
      let foo = ->{}
    })

    it("allows the curly braces to be ommited", ->{
      let foo = ->(a, b) a + b
    })

    it("allows both parens and curly braces to be ommited", ->{
      let foo = ->bar()
    })

  })

  describe("call", ->{

    it("calls functions", ->{
      let called = false

      func foo() {
        called = true
      }

      foo()

      assert(called, true)
    })

    it("calls lambda functions", ->{
      let square = ->(num) num ** 2
      let double = ->(num) num * 2
      let increment = ->(num) num + 1

      let num = 5

      num = square(num)
      num = double(num)
      num = increment(num)

      assert(num, 51)
    })

    it("passes arguments to a function", ->{
      let arg1
      let arg2

      func foo(a, b) {
        arg1 = a
        arg2 = b
      }

      foo(1, 2)

      assert(arg1, 1)
      assert(arg2, 2)
    })

    it("inserts the __argument variable", ->{
      let received

      func foo() {
        received = arguments
      }

      foo(1, 2, 3, 4, 5)

      assert(received, [1, 2, 3, 4, 5])
    })

    it("inserts quick access identifiers", ->{
      let received

      func foo() {
        received = [
          $0, $1, $2, $3, $4
        ]
      }

      foo(1, 2, 3, 4, 5)

      assert(received, [1, 2, 3, 4, 5])
    })

    it("can overwrite quick access identifiers", ->{
      let received

      func foo($3, $2, $1, $0) {
        received = [
          $0, $1, $2, $3
        ]
      }

      foo(1, 2, 3, 4)

      assert(received, [4, 3, 2, 1])
    })

    it("arguments take precedence over parent scope variables", ->{
      let out = 20

      func foo(out) {
        out = 30
      }

      foo(20)

      assert(out, 20)
    })

  })

  describe("scoping", ->{

    it("runs callbacks in the right scope", ->{
      let change_me = false

      func call_me(callback) {
        let change_me = 25
        callback()
      }

      call_me(func() {
        change_me = "changed"
      })

      assert(change_me, "changed")
    })

  })

  it("does consecutive call expressions", ->{
    func call_me() {
      func() {
        func() {
          25
        }
      }
    }

    assert(call_me()()(), 25)
  })

  it("passes arguments in the right order", ->{
    let f1
    let f2
    let f3

    func(a1) {
      func(a2) {
        func(a3) {
          f1 = a1
          f2 = a2
          f3 = a3
        }
      }
    }(1)(2)(3)

    assert(f1, 1)
    assert(f2, 2)
    assert(f3, 3)
  })

  describe("self identifier", ->{

    it("gives functions the correct self pointer", ->{
      let box = {
        let val = "in box"

        func foo() {
          got = @val
        }
      }

      let got = null
      box.foo()

      assert(got, "in box")
    })

    it("gives direct function calls the correct self pointer", ->{
      let box = {
        let val = "in box"

        func foo() {
          func bar() {
            got = @val
          }

          bar()
        }
      }

      let got = null
      box.foo()

      assert(got, "in box")
    })

    it("callbacks receive the correct self pointer", ->{
      func foo(callback) {
        callback()
      }

      let box = {
        let val = "in box"

        func bar() {
          foo(func() {
            got = @val
          })
        }
      }

      let got = null
      box.bar()

      assert(got, "in box")
    })

    it("assigned functions receive the correct self pointer", ->{
      let box = {
        let val = "in box"
      }

      box.foo = func() {
        got = @val
      }

      let got = null
      box.foo()

      assert(got, "in box")
    })

    it("functions in nested objects get the correct self pointer", ->{
      let box = {
        let val = "upper box"

        let foo = {
          let val = "inner box"

          func bar() {
            got = @val
          }
        }
      }

      let got = null
      box.foo.bar()

      assert(got, "inner box")
    })

    it("assigned functions in nested objects get the correct self pointer", ->{
      let box = {
        let val = "upper box"

        let foo = {
          let val = "inner box"
        }
      }

      let got = null

      box.foo.bar = func bar() {
        got = @val
      }

      box.foo.bar()

      assert(got, "inner box")
    })

  })

  describe("return", ->{

    describe("explicit", ->{

      it("does explicit returns with an argument", ->{
        func foo() {
          return 25
        }

        assert(foo(), 25)
      })

      it("does explicit returns without argument", ->{
        func foo() {
          return
        }

        assert(foo(), null)
      })

      it("does explicit returns from an object", ->{
        let Box = {
          func foo() {
            return 25
          }
        }

        assert(Box.foo(), 25)
      })

      it("does explicit returns from nested ifs", ->{
        func foo(arg) {
          if arg <= 10 {
            return false
          }

          return true
        }

        assert(foo(0), false)
        assert(foo(5), false)
        assert(foo(10), false)

        assert(foo(15), true)
        assert(foo(20), true)
        assert(foo(25), true)
      })

    })

  })

  it("correctly parses nested lambda functions", ->{
    const myFunc = ->->{
      25
    }

    assert(typeof myFunc(), "Function")
    assert(myFunc()(), 25)
  })

  it("throws when disallowed names are used as a argument name", ->{
    func foo(self, __internal__method) {
      print(self, __internal__method)
    }

    try {
      foo(25)
    } catch(e) {
      assert(true, true)
      return
    }

    assert(false, true)
  })

  it("doesn't save methods without a name", ->{
    let box = {
      func() {}
    }

    assert(typeof box[""], "Null")
  })

  describe("internal methods", ->{

    it("loads internal methods", ->{
      let object_keys = __internal__method("_object_keys")

      assert(typeof object_keys, "Function")
      assert(object_keys.name, "_object_keys")

      let test_object = {
        let hello
        let world
      }

      assert(object_keys(test_object), ["hello", "world"])
    })

  })

  describe("bind", ->{

    it("binds a context to a function", ->{
      let context = {
        let name = "context name"
      }

      func foo() {
        @name
      }

      let bound_foo = foo.bind(context)

      assert(foo == bound_foo, false)

      assert(foo(), null)
      assert(bound_foo(), "context name")
    })

    it("binds the context of a callback", ->{
      func foo(context, callback) {
        callback.bind(context)()
      }

      let context = {}
      foo(context, ->{
        @name = "test"
        @prop = 25
      })

      assert(context.name, "test")
      assert(context.prop, 25)
    })

    it("binds arguments passed after the context", ->{
      func add(left, right) {
        left + right
      }

      let bound_add = add.bind(self, 2, 2)

      assert(bound_add(), 4)
    })

    it("partially binds arguments passed after the context", ->{
      func add(left, right) {
        left + right
      }

      let bound_add = add.bind(self, 2)

      assert(bound_add(2), 4)

      try {
        bound_add()
      } catch(e) {
        assert(e.message, "Method expected 2 arguments, got 0")
        return
      }

      assert(true, false)
    })

    it("bound context takes precedence over regular one", ->{
      let box = {
        let name = "box"

        func foo() {
          @name
        }
      }

      assert(box.foo(), "box")

      box.foo = box.foo.bind({
        let name = "overridden"
      })

      assert(box.foo(), "overridden")
    })

    it("bound arguments can take over a function completly", ->{
      func foo(a, b, c) {
        a + b + c
      }

      assert(foo(1, 2, 3), 6)

      foo = foo.bind(self, 5, 5, 5)

      assert(foo(1, 2, 3), 15)
    })

    it("doesn't modify the original function", ->{
      func foo(a, b) {
        a + b
      }

      let bar = foo.bind(self, 1, 2)

      assert(foo(5, 5), 10)
      assert(bar(5, 5), 3)
    })

    it("can append new arguments to an already bound function", ->{
      func foo(a, b, c) {
        a + b + c
      }

      let b1 = foo.bind(self, 50)
      let b2 = b1.bind(self, 50)
      let b3 = b2.bind(self, 50)

      assert(foo(1, 1, 1), 3)
      assert(b1(1, 1, 1), 52)
      assert(b2(1, 1, 1), 101)
      assert(b3(1, 1, 1), 150)
    })

    it("doesn't clone already bound arguments on rebind", ->{
      func foo(a) { a }

      let arr = [1, 2]

      let b1 = foo.bind(self, arr)
      let b2 = b1.bind(self)

      let r1 = b1()
      let r2 = b2()

      assert(r1, [1, 2])
      assert(r2, [1, 2])

      r1.push(3)

      assert(r1, [1, 2, 3])
      assert(r2, [1, 2, 3])
    })

  })

}
