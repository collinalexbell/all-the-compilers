<?hh

function test($label, $value) {
  print("\n===============================================================\n");
  print("$label:\n");

  $modes = vec[
    0, // The default mode
    FB_SERIALIZE_VARRAY_DARRAY,
    FB_SERIALIZE_HACK_ARRAYS,
    FB_SERIALIZE_HACK_ARRAYS_AND_KEYSETS,
  ];

  foreach ($modes as $mode) {
    $serialized = fb_serialize($value, $mode);
    print(json_encode($serialized)."\n");
    $success = null;
    $unserialized = fb_unserialize($serialized, inout $success, $mode);
    invariant($success, 'fb_unserialize failed!');
    invariant(!HH\is_array_marked_legacy($unserialized), 'Output is legacy!');
    print(json_encode($unserialized, JSON_FB_FORCE_HACK_ARRAYS)."\n");
  }
}

<<__EntryPoint>>
function main() {
  $examples = vec[
    vec['Empty varray', varray[]],
    vec['Empty darray', darray[]],
    vec['List-like varray', varray[4, 5, 6]],
    vec['List-like darray', darray(varray[4, 5, 6])],
    vec['Map-like darray', darray['a' => 17, 'b' => 34]],
  ];
  foreach ($examples as list($label, $value)) {
    test($label, $value);
    test("$label (marked)", HH\array_mark_legacy($value));
  }
}
