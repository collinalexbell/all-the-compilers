var Foo = /*#__PURE__*/function (_Bar) {
  "use strict";

  babelHelpers.inherits(Foo, _Bar);

  var _super = babelHelpers.createSuper(Foo);

  function Foo() {
    var _temp, _this;

    babelHelpers.classCallCheck(this, Foo);
    foo((_temp = _this = _super.call(this), _this.bar = "foo", _temp));
    return _this;
  }

  return Foo;
}(Bar);
