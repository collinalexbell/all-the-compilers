<?hh

<<
__EntryPoint

>>
function
main
(

)
{
  $x


    = 10;
  $y = $x
    * $x;

  $z = $y +
    $y;

  echo "$z\n"

    ;

  $ret
    =
    null
    ;

  system(
    PHP_BINARY.
      ' -m dumpcoverage '.
      __FILE__
      ,
      inout
      $ret
    )
    ;

  // comment

  echo

    "$ret\n";

  var_dump(
    HH\
      get_executable_lines(
        __FILE__
       ,
      )
  )
  ;

}

// comment
