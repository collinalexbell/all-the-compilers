<?hh

/* Compile only test. Used to crash hphp */ class X {
  protected $map;
  protected $parents;
  public function __construct(AnyArray $map, AnyArray $parents) {
    $this->map = $map;
    $this->parents = $parents;
  }
}
<<__EntryPoint>> function main(): void { echo "Done.\n"; }
