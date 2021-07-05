<?hh

class C {}

class D {}

class Foo {
  static public function bar<T>(): void {
    print __METHOD__;
    print "\n";
  }
}

function baz<T>(): void {
  print __FUNCTION__;
  print "\n";
}

function func1($p0 = Foo::bar<>) {
  $p0();
}
function func2($p0 = baz<>) {
  $p0();
}
function func3($p0 = Foo::bar<_>) {
  $p0();
}
function func4($p0 = baz<_>) {
  $p0();
}
function func5($p0 = Foo::bar<int>) {
  $p0();
}
function func6($p0 = baz<int>) {
  $p0();
}
function func7($p0 = Foo::bar<D>) {
  $p0();
}
function func8($p0 = baz<D>) {
  $p0();
}

<<__EntryPoint>>
function main() {
  func1();
  func2();
  func3();
  func4();
  func5();
  func6();
  func7();
  func8();

  // With passed in argument
  func1(Foo::bar<string>);
  func2(baz<string>);
  func3(Foo::bar<D>);
  func4(baz<D>);
  func5(Foo::bar<_>);
  func6(baz<_>);
  func5(Foo::bar<>);
  func6(baz<>);
}
