<?hh

class InfoBlob {
  public $foo;
  function __construct() {
    $this->foo = "Foo";
  }
}

<<__EntryPoint>>
function main(): void {
  $g_lang = 'tr_TR';
  putenv("LANG=$g_lang");
  setlocale(LC_ALL, $g_lang);

  echo "Instantiating an infoBlob with a lowercase i\n";
  $foobar = new infoBlob();
  echo $foobar->foo;
  echo "\nInstantiating an InfoBlob with an uppercase I\n";
  $foobar = new InfoBlob();
  echo $foobar->foo;
  echo "\n";
  setlocale(LC_ALL, "tr_TR.utf8");
  foreach (get_declared_classes() as $class) {
    if (!class_exists($class)) echo "$class No Longer Exists!\n";
  }
  echo "Done.\n";
}