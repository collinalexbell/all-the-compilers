//// base-a.php
<?hh
class A {}
//// base-b.php
<?hh
class B extends A {
    public function foo(): int { return 0; }
}

//// changed-a.php
<?hh
class A {
    public function foo(): arraykey { return "s"; }
}
//// changed-b.php
<?hh
class B extends A {
    public function foo(): int { return 0; }
}
