<?hh

class Foo { function bar() { echo "bar\n"; } }

<<__EntryPoint>>
function main() {
  $mc = meth_caller(Foo::class, 'bar');
  $mc2 = __hhvm_intrinsics\launder_value(meth_caller(Foo::class, 'bar'));

  $mc(new Foo); $mc2(new Foo);

  require_once 'meth-caller-repo-dup.php.inc';

  other();
}
