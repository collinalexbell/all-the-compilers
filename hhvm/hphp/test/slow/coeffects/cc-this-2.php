<?hh

abstract class A {
  abstract const ctx C;
  public static function f()[this::C] {
    echo "in f\n";
  }
}

class B1 extends A { const ctx C = []; }
class B2 extends A { const ctx C = [rx]; }
class B3 extends A { const ctx C = [defaults]; }

function pure($c)[]   { $c::f(); }
function rx($c)[rx]   { $c::f(); }
function defaults($c) { $c::f(); }


<<__EntryPoint>>
function main() {
  $classes = vec['B1', 'B2', 'B3'];
  $callers = vec['pure', 'rx', 'defaults'];
  foreach ($callers as $caller) {
    foreach ($classes as $cls) {
      $caller($cls);
    }
  }
}
