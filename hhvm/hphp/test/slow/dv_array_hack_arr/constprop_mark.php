<?hh

<<__EntryPoint>>
function main() {
  $a = varray[0];
  $a = HH\array_mark_legacy($a);
  $a[0] += 10;
  var_dump($a);
  var_dump(HH\is_array_marked_legacy($a));
  $a[] = 42;
  var_dump($a);
  var_dump(HH\is_array_marked_legacy($a));
}
