<?hh

function foo($a) {
  print "foo $a\n";
}

function bar(inout $a) {
  $a = 2;
  return $a;
}

function baz($a) {
  return 2;
}
<<__EntryPoint>> function main(): void {
$a = varray[1, 2];
array_map(foo<>, $a);

$a = call_user_func(baz<>, $a);
var_dump($a);
}
