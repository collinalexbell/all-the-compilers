<?hh

function returns_object()[rx] {
  $o = new stdClass();
  $o->p = darray[5 => true];
  return $o;
}

<<__EntryPoint>>
function bad()[rx] {
  $lp = 'p';
  unset(returns_object()->{$lp}[5]);
}
