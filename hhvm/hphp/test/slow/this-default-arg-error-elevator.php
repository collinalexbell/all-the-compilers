<?hh

class A {
  public function blarf($x = $this) {
    echo "blarf: ";
    var_dump($x);
  }
}

function err_handler($errno, $str, $file, $line, $ctx) {
  if (strpos($str, 'Undefined variable') is int) {
    throw new Exception("asdf");
  }
  return false;
};

<<__EntryPoint>>
function main() {
  set_error_handler(err_handler<>);
  $cls = new ReflectionClass("A");
  $meths = $cls->getMethods();
  var_dump($meths[0]->getParameters()[0]->getDefaultValue());
}
