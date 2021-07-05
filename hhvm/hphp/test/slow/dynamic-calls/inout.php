<?hh
// Copyright 2004-present Facebook. All Rights Reserved.



function func1(inout $x) {}
<<__DynamicallyCallable>> function func4(inout $x) {}

class A {
  public function func2(inout $x) {}
  public static function func3(inout $x) {}
}

class B {
  <<__DynamicallyCallable>> public function func5(inout $x) {}
  <<__DynamicallyCallable>> public static function func6(inout $x) {}
}

function positive_tests() {
  echo "====================== positive tests ========================\n";
  $v = 123;

  $x = 'func1'; $x(inout $v);
  $x = 'A::func3'; $x(inout $v);

  $x = varray['A', 'func3']; $x(inout $v);

  $x = varray[new A, 'func2']; $x(inout $v);
  $x = varray[new A, 'func3']; $x(inout $v);



  $x = 'A'; $x::func3(inout $v);



  $x = 'func3'; A::$x(inout $v);

  $obj = new A; $x = 'func2'; $obj->$x(inout $v);


}

function negative_tests() {
  echo "====================== negative tests ========================\n";
  $v = 123;

  $x = 'func4'; $x(inout $v);
  $x = 'B::func6'; $x(inout $v);

  $x = varray['B', 'func6']; $x(inout $v);

  $x = varray[new B, 'func5']; $x(inout $v);
  $x = varray[new B, 'func6']; $x(inout $v);

  $x = 'B'; $x::func6(inout $v);

  $x = 'func6'; B::$x(inout $v);

  $obj = new B; $x = 'func5'; $obj->$x(inout $v);


}
<<__EntryPoint>> function main(): void {
positive_tests();
negative_tests();
}
