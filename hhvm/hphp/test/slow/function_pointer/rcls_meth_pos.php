<?hh

<<__EntryPoint>>
function foo(): void {
  var_dump(42);
  // Test to see if the position of the error is correct
  Foo::bar<int>;
}
