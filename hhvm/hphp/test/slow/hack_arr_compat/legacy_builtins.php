<?hh

function clear(inout $array) {
  shuffle(inout $array);
  $legacy = HH\is_array_marked_legacy($array);
  $array = HH\is_vec_or_varray($array)
    ? ($legacy ? HH\array_mark_legacy(varray[]) : varray[])
    : ($legacy ? HH\array_mark_legacy(darray[]) : darray[]);
}

function pop(inout $array) {
  return array_pop(inout $array);
}

function push(inout $array) {
  return array_push(inout $array, null);
}

function shift(inout $array) {
  return array_shift(inout $array);
}

function unshift(inout $array) {
  return array_unshift(inout $array, null);
}

function splice(inout $array) {
  return array_splice(inout $array, 1, 1);
}

function show($input) {
  return json_encode($input, JSON_FB_FORCE_HACK_ARRAYS);
}

function test($legacy, $input) {
  print("\n==============================================================\n");
  print('test('.$legacy.', '.show($input)."):\n");

  $fns = vec[
    sort<>,
    asort<>,
    ksort<>,
    rsort<>,
    arsort<>,
    krsort<>,
    clear<>,
    pop<>,
    push<>,
    shift<>,
    unshift<>,
    splice<>,
  ];
  foreach ($fns as $fn) {
    $marked = $legacy ? HH\array_mark_legacy($input) : $input;
    $fn(inout $marked);
    $fn_name = json_decode(json_encode($fn));
    while (strlen($fn_name) < 7) {
      $fn_name .= ' ';
    }
    $out = HH\is_array_marked_legacy($marked) ? 1 : 0;
    print("  $fn_name (legacy: $out): ".show($marked)."\n");
    if ($out != $legacy) throw new Error('Legacy bit mismatch!');
  }
}

function test_multisort($as, $bs) {
  print("\n==============================================================\n");
  print('test_multisort('.show($as).', '.show($bs)."):\n");

  $bits = vec[vec[0, 0], vec[0, 1], vec[1, 0], vec[1, 1]];
  foreach ($bits as $b) {
    $tas = $b[0] ? HH\array_mark_legacy($as) : $as;
    $tbs = $b[1] ? HH\array_mark_legacy($bs) : $bs;
    $direction = SORT_ASC;
    array_multisort3(inout $tas, inout $tbs, inout $direction);
    $out = vec[
      HH\is_array_marked_legacy($tas) ? 1 : 0,
      HH\is_array_marked_legacy($tbs) ? 1 : 0,
    ];
    print("  ".show($b).' => '.show($out).': '.show($tas).', '.show($tbs)."\n");
    if ($out[0] != $b[0]) throw new Error('Legacy bit mismatch!');
    if ($out[1] != $b[1]) throw new Error('Legacy bit mismatch!');
  }
}

<<__EntryPoint>>
function main() {
  foreach (vec[0, 1] as $legacy) {
    test($legacy, varray[]);
    test($legacy, varray[17]);
    test($legacy, varray[4, 5, 6]);
    test($legacy, varray[4, 6, 5]);
    test($legacy, darray[]);
    test($legacy, darray['a' => 17]);
    test($legacy, darray['a' => 17, 'b' => 34, 'c' => 51]);
    test($legacy, darray['a' => 17, 'c' => 51, 'b' => 34]);
  }

  test_multisort(varray[], darray[]);
  test_multisort(varray[5, 4], darray['b' => 34, 'a' => 17]);
}
