export = ->(describe, it, assert) {

  describe("writing", ->{

    it("adds properties to objects", ->{
      class Box {}
      let myBox = Box()
      myBox.name = "charly"
      myBox.age = 16

      assert(myBox.name, "charly")
      assert(myBox.age, 16)
    })

    it("adds functions to objects", ->{
      class Box {}
      let myBox = Box()
      myBox.name = "charly"
      myBox.age = 16
      myBox.to_s = func() {
        assert(self == myBox, true)
        myBox.do_stuff = func() {
          "it works!"
        }

        myBox.name + " - " + myBox.age
      }

      assert(myBox.name, "charly")
      assert(myBox.age, 16)
      assert(myBox.do_stuff, null)
      assert(myBox.to_s(), "charly - 16")
      assert(myBox.do_stuff(), "it works!")
    })

    it("assigns via index expressions", ->{
      let Box = {
        let name = "test"
      }

      Box["name"] = "it works"

      assert(Box["name"], "it works")
    })

  })

  describe("scoping", ->{

    it("anonymous functions's self is sourced from the stack ", ->{
      let val = 0

      let box1 = {
        let val = 1

        func callback(callback) {
          callback()
        }
      }

      let box2 = {
        let val = 2

        func call() {
          box1.callback(func() {
            @val = 200
          })
        }
      }

      box2.call()
      assert(val, 0)
      assert(box1.val, 1)
      assert(box2.val, 200)
    })

    it("assigns the correct scope to functions that are added from the outside", ->{
      let Box = {
        let val = 0

        func do(callback) {
          callback(self)
        }
      }

      let val = 0

      Box.do(func(Box) {
        val = 30
        Box.val = 60
      })

      assert(val, 30)
      assert(Box.val, 60)

      Box.do2 = func() {
        val = 120
        @val = 90
      }
      Box.do2()

      assert(val, 120)
      assert(Box.val, 90)
    })

  })

  describe("pretty_printing", ->{

    it("displays objects as a string", ->{
      let Box = {
        let name = "charly"
        let data = {
          let foo = "okay"
          let hello = "world"
        }
      }

      let render = Box.to_s()

      assert(render, "{\n  name: charly\n  data: {\n    foo: okay\n    hello: world\n  }\n}")
    })

    it("renders arrays", ->{
      let arr = [1, 2, 3, 4]

      let render = arr.to_s()

      assert(render, "[1, 2, 3, 4]")
    })

    it("renders circular objects", ->{
      let Box = {}
      Box.box = {}
      Box.box.box = {}
      Box.box.box.box = Box

      let render = Box.to_s()
      let pretty_render = Object.pretty_print(Box)

      assert(render, "{\n  box: {\n    box: {\n      box: (circular)\n    }\n  }\n}")
      assert(pretty_render, "{\n  box: {\n    box: {\n      box: (circular)\n    }\n  }\n}")
    })

    it("renders circular arrays", ->{
      let a = []
      let b = []

      a.push(b)
      b.push(a)

      let render = a.to_s()
      let pretty_render = Array.pretty_print(a)

      assert(render, "[[(circular)]]")
      assert(pretty_render, "[[(circular)]]")
    })

    it("renders literals", ->{
      let box = {}
      box.string = "hello world"
      box.num = 25
      box.bool = true
      box.nil = null
      box.nan = NAN

      let render = box.to_s()

      assert(render, "{\n  string: hello world\n  num: 25\n  bool: true\n  nil: null\n  nan: NAN\n}")
    })

  })

  describe("keys", ->{

    it("returns all keys of an object", ->{
      let Box = {
        let name = "charly"
        let data = {
          let foo = "okay"
          let hello = "world"
        }
      }

      const keys = Object.keys(Box)
      assert(keys, ["name", "data"])
    })

    it("returns all keys of a class", ->{
      class Foo {
        static property lol

        static func bar() {
          "it works"
        }
      }

      let keys = Object.keys(Foo)
      assert(keys, ["lol", "bar", "name"])
    })

    it("returns all keys of a primitive class", ->{
      let keys = Object.keys(Array)
      assert(keys, [
        "pretty_print",
        "of_size",
        "name",
        "methods"
      ])
    })

    it("returns all keys of a function", ->{
      func foo() {}
      foo.some_data = [1, 2, 3]

      let keys = Object.keys(foo)
      assert(keys, ["name", "some_data"])
    })

    it("returns all keys of internal functions", ->{
      let method = __internal__method("_isolate_object")
      method.foo = 25

      let keys = Object.keys(method)
      assert(keys, ["name", "foo"])
    })

  })

  describe("tap", ->{

    it("passes the value to the callback", ->{
      let a = 25
      let check
      let c1 = ->check = $0
      a.tap(c1)
      assert(check, 25)
    })

  })

  describe("typeof", ->{

    it("returns the type of a variable", ->{
      assert(typeof false, "Boolean")
      assert(typeof true, "Boolean")
      assert(typeof "test", "String")
      assert(typeof 25, "Numeric")
      assert(typeof 25.5, "Numeric")
      assert(typeof [1, 2, 3], "Array")
      assert(typeof class Test {}, "Class")
      assert(typeof func() {}, "Function")
      assert(typeof {}, "Object")
      assert(typeof null, "Null")
    })

  })

  describe("to_n", ->{

    it("casts string to numeric", ->{
      assert("25".to_n(), 25)
      assert("25.5".to_n(), 25.5)
      assert("0".to_n(), 0)
      assert("100029".to_n(), 100029)
      assert("-89.2".to_n(), -89.2)

      assert("hello".to_n(), NAN)
      assert("25test".to_n(), 25)
      assert("ermokay30".to_n(), NAN)
      assert("-2.25this".to_n(), -2.25)

      assert("123.45e2".to_n(), 12345)
      assert("2e5".to_n(), 200_000)
      assert("25e-5".to_n(), 0.00025)
      assert("9e-2".to_n(), 0.09)
    })

  })

  describe("pipe", ->{

    it("pipes a value to different functions", ->{
      let res1
      let res2
      let res3

      func setRes1(v) {
        res1 = v
      }

      func setRes2(v) {
        res2 = v
      }

      func setRes3(v) {
        res3 = v
      }

      5.pipe(setRes1, setRes2, setRes3)

      assert(res1, 5)
      assert(res2, 5)
      assert(res3, 5)
    })

  })

  describe("transform", ->{

    it("transforms an array", ->{
      func reverse(array) {
        array.reverse()
      }

      func addOne(array) {
        array.map(func(e) { e + 1 })
      }

      func multiplyByTwo(array) {
        array.map(func(e) { e * 2 })
      }

      const nums = [1, 2, 3, 4, 5]
      const result = nums.transform(multiplyByTwo, reverse, addOne)
      assert(result, [11, 9, 7, 5, 3])
    })

  })

  describe("assign", ->{

    it("copies keys from one or more objects to another", ->{
      let Box1 = {
        let name = "box1"
      }

      let Box2 = {
        let age = 20
      }

      let Box3 = Object.assign({}, Box1, Box2)

      assert(Box3.name, "box1")
      assert(Box3.age, 20)
    })

  })

  describe("copy", ->{

    it("copies an object", ->{
      let test = {
        let name = "test"
        let foo = 25
      }

      let new_test = test.copy()
      test.name = "it changed"

      assert(new_test.name, "test")

      new_test.foo = 30

      assert(test.foo, 25)
    })

    it("doesn't copy sub-arrays", ->{
      let arr = [1, 2, 3]
      let obj = {
        let arr = arr
      }

      let copy = obj.copy()

      assert(copy.arr.length(), 3)

      arr.push(4)

      assert(copy.arr.length(), 4)
    })

    it("doesn't copy sub-objects", ->{
      let obj1 = { let prop = 1 }
      let obj2 = { let prop = obj1 }

      let copy = obj2.copy()

      obj1.prop = 25

      assert(copy.prop.prop, 25)

      obj2.prop = 200

      assert(typeof copy.prop, "Object")
    })

    describe("throws when trying to copy uncopiable values", ->{

      it("throws on functions", ->{
        try {
          Object.copy(func() {})
        } catch(e) {
          return assert(e.message, "Cannot copy functions")
        }

        assert(true, false)
      })

      it("throws on classes", ->{
        try {
          Object.copy(class Foo {})
        } catch(e) {
          return assert(e.message, "Cannot copy classes")
        }

        assert(true, false)
      })

      it("throws on primitive classes", ->{
        primitive class Foo {}

        try {
          Object.copy(Foo)
        } catch(e) {
          return assert(e.message, "Cannot copy primitive classes")
        }

        assert(true, false)
      })

    })

  })

  describe("deep_copy", ->{

    it("recursively copies an object", ->{
      let obj1 = { let prop = 2 }
      let obj2 = { let prop = obj1 }
      let obj3 = { let prop = obj2 }

      let copy = obj3.deep_copy()

      obj1.prop = 20

      assert(copy.prop.prop.prop, 2)

      obj3.prop = 200

      assert(typeof copy.prop, "Object")
    })

    it("copies sub-arrays", ->{
      let arr = [1, 2, 3]
      let obj = { let prop = arr }

      let copy = obj.deep_copy()

      arr.push(4)

      assert(copy.prop.length(), 3)
    })

    describe("throws when trying to copy uncopiable values", ->{

      it("throws on functions", ->{
        try {
          Object.deep_copy(func() {})
        } catch(e) {
          return assert(e.message, "Cannot deep_copy functions")
        }

        assert(true, false)
      })

      it("throws on classes", ->{
        try {
          Object.deep_copy(class Foo {})
        } catch(e) {
          return assert(e.message, "Cannot deep_copy classes")
        }

        assert(true, false)
      })

      it("throws on primitive classes", ->{
        primitive class Foo {}

        try {
          Object.deep_copy(Foo)
        } catch(e) {
          return assert(e.message, "Cannot deep_copy primitive classes")
        }

        assert(true, false)
      })

    })

  })

  describe("object_id", ->{

    it("returns the memory address of a value", ->{
      let a = 25
      let b = a

      let ad1 = Object.object_id(a)
      let ad2 = Object.object_id(b)

      assert(ad1, ad2)
    })

    it("returns the memory address of function arguments", ->{
      func foo(a, b, c) {
        arguments.map(Object.object_id)
      }

      let a = 1
      let b = 2
      let c = 3

      let adresses = [a, b, c].map(Object.object_id)

      let argument_adresses = foo(a, b, c)
      assert(adresses, argument_adresses)
    })

    it("returns the memory address of object properties", ->{
      let num = 200

      let box = {}
      box.value = num

      let ad1 = Object.object_id(num)
      let ad2 = Object.object_id(box.value)

      assert(ad1, ad2)
    })

  })

}
