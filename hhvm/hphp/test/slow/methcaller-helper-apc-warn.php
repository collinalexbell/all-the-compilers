<?hh

class C { function  m() {} }

<<__EntryPoint>>
function main() {
  $mc1 = meth_caller(C::class, 'm');
  $mc2 = __hhvm_intrinsics\launder_value($mc1);

  $v1 = vec[$mc1];
  $v2 = __hhvm_intrinsics\launder_value(vec[$mc2]);

  $d1 = dict['a' => $mc1];
  $d2 = __hhvm_intrinsics\launder_value(dict['a' => $mc2]);

  $x1 = dict['a' => vec[$mc1]];
  $x2 = __hhvm_intrinsics\launder_value(dict['a' => vec[$mc2]]);

  apc_store('mc1', $mc1);
  apc_store('mc2', $mc2);
  apc_store('v1', $v1);
  apc_store('v2', $v2);
  apc_store('d1', $d1);
  apc_store('d2', $d2);

  var_dump(__hhvm_intrinsics\apc_fetch_no_check('mc1'));
  var_dump(__hhvm_intrinsics\apc_fetch_no_check('mc2'));
  var_dump(__hhvm_intrinsics\apc_fetch_no_check('v1'));
  var_dump(__hhvm_intrinsics\apc_fetch_no_check('v2'));
  var_dump(__hhvm_intrinsics\apc_fetch_no_check('d1'));
  var_dump(__hhvm_intrinsics\apc_fetch_no_check('d2'));
}

