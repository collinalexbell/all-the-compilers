<?hh

class C { public static $p; }

<<__EntryPoint>>
function test()[rx] {
  $x = C::$p ?? false;
}
