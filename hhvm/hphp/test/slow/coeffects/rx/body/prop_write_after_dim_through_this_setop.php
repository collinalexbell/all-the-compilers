<?hh

class C {
  public $p;

  public function bad()[rx] {
    $this->p = new stdClass();

    $this->p->q *= 2;
  }
}

<<__EntryPoint>>
function test() {
  $c = new C();
  $c->bad();
}
