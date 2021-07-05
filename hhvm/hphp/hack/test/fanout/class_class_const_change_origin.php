//// base-a.php
<?hh
class A {
  const int C = 3;
}
//// base-b.php
<?hh
class B extends A {
  const int C = 4;
}
//// base-c.php
<?hh
class C extends B {}
//// base-use.php
<?hh
function take_int(int $_): void {}
function use_a_const(): void {
  take_int(A::C);
}
function use_b_const(): void {
  take_int(B::C);
}
function use_c_const(): void {
  take_int(C::C);
}

//// changed-a.php
<?hh
class A {
  const int C = 3;
}
//// changed-b.php
<?hh
class B extends A {
  // Removing B::C will change the origin field of C::C and thus
  // trigger a type check of places that use C::C! Weird!
}
//// changed-c.php
<?hh
class C extends B {}
//// changed-use.php
<?hh
function take_int(int $_): void {}
function use_a_const(): void {
  take_int(A::C);
}
function use_b_const(): void {
  take_int(B::C);
}
function use_c_const(): void {
  take_int(C::C);
}
