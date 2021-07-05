<?hh

function my_apc_add($key) {
  var_dump(
    apc_add(
      $key,
      123,
      30,
    )
  );
}

<<__EntryPoint>>
function main() {
  my_apc_add("abc", "def");
  my_apc_add("", "def");
  my_apc_add(dict["abc" => "def"]);
  my_apc_add(dict["" => "abc"]);
}
