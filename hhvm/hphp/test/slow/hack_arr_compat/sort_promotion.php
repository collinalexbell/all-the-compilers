<?hh

function test($name, $sf) {
  echo "==== $name 0 ====\n";
  $a = varray[];
  $sf(inout $a);
  var_dump(is_varray($a), is_darray($a));

  echo "==== $name 1 ====\n";
  $a = varray[1];
  $sf(inout $a);
  var_dump(is_varray($a), is_darray($a));

  echo "==== $name 2 ====\n";
  $a = varray[2, 1];
  $sf(inout $a);
  var_dump(is_varray($a), is_darray($a));
}

function utest($name, $sf) {
  $cb = ($a, $b) ==> $a <=> $b;

  echo "==== $name 0 ====\n";
  $a = varray[];
  $sf(inout $a, $cb);
  var_dump(is_varray($a), is_darray($a));

  echo "==== $name 1 ====\n";
  $a = varray[1];
  $sf(inout $a, $cb);
  var_dump(is_varray($a), is_darray($a));

  echo "==== $name 2 ====\n";
  $a = varray[2, 1];
  $sf(inout $a, $cb);
  var_dump(is_varray($a), is_darray($a));
}

<<__EntryPoint>>
function main() {
  echo "====== never promote varray => darray ======\n";
  test( 'sort',  sort<>);
  test( 'rsort', rsort<>);
  utest('usort', usort<>);
  test( 'ksort', ksort<>);
  echo "====== always promote varray => darray ======\n";
  test( 'krsort', krsort<>);
  utest('uksort', uksort<>);
  test( 'asort',  asort<>);
  test( 'arsort', arsort<>);
  utest('uasort', uasort<>);
}
