<?hh


function jccMain($i) {
  if (!$i) {
    echo "i is falsey\n";
  } else {
    echo "i is truthy\n";
  }

  if ($i === 2) {
    echo "i is 2\n";
  } else {
    echo "i is not 2\n";
  }
}


<<__EntryPoint>>
function main_jumps() {
jccMain(0);
jccMain(2);
}
