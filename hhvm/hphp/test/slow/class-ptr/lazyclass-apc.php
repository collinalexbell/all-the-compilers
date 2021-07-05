<?hh

class bar {}
class foobar {}
class fizz {}

<<__EntryPoint>>
function main() {
  apc_store('mainf', bar::class);
  apc_store('maina', varray[1, bar::class, 'foo']);

  apc_store('sysf', foobar::class);
  apc_store('sysa', varray[10, fizz::class, 'foo']);

  var_dump(__hhvm_intrinsics\apc_fetch_no_check('mainf'));
  var_dump(__hhvm_intrinsics\apc_fetch_no_check('maina'));

  var_dump(__hhvm_intrinsics\apc_fetch_no_check('sysf'));
  var_dump(__hhvm_intrinsics\apc_fetch_no_check('sysa'));
}
