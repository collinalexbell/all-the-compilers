<?hh

class C {
  private $prop = null;
  public function prop() {
    return $this->prop;
  }
  public function propset($p, $v) {
    $this->$p = $v;
  }
}

<<__EntryPoint>>
function main(): void {
  $c = new C();
  var_dump($c->prop());
  $c->propset('prop', 'new value');
  var_dump($c->prop());
}
