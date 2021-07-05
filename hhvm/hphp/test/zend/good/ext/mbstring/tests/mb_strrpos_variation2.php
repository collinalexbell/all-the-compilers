<?hh
/* Prototype  : int mb_strrpos(string $haystack, string $needle [, int $offset [, string $encoding]])
 * Description: Find position of last occurrence of a string within another
 * Source code: ext/mbstring/mbstring.c
 */

/*
 * Pass mb_strrpos() different data types as $needle argument to test behaviour
 */

// get a class
class classA
{
  public function __toString() {
    return "world";
  }
}
<<__EntryPoint>> function main(): void {
echo "*** Testing mb_strrpos() : usage variations ***\n";

// Initialise function arguments not being substituted
$haystack = 'hello, world';
$offset = 0;
$encoding = 'utf-8';


// heredoc string
$heredoc = <<<EOT
world
EOT;

// get a resource variable
$fp = fopen(__FILE__, "r");

// unexpected values to be passed to $needle argument
$inputs = varray[

       // int data
/*1*/  0,
       1,
       12345,
       -2345,

       // float data
/*5*/  10.5,
       -10.5,
       12.3456789000e10,
       12.3456789000E-10,
       .5,

       // null data
/*10*/ NULL,
       null,

       // boolean data
/*12*/ true,
       false,
       TRUE,
       FALSE,

       // empty data
/*16*/ "",
       '',

       // string data
/*18*/ "world",
       'world',
       $heredoc,

       // object data
/*21*/ new classA(),



       // resource variable
/*22*/ $fp
];

// loop through each element of $inputs to check the behavior of mb_strrpos()
$iterator = 1;
foreach($inputs as $input) {
  echo "\n-- Iteration $iterator --\n";
  try { var_dump( mb_strrpos($haystack, $input, $offset, $encoding)); } catch (Exception $e) { echo "\n".'Warning: '.$e->getMessage().' in '.__FILE__.' on line '.__LINE__."\n"; }
  $iterator++;
};

fclose($fp);

echo "Done";
}