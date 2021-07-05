<?hh
/* Prototype  : string decoct  ( int $number  )
 * Description: Returns a string containing an octal representation of the given number argument.
 * Source code: ext/standard/math.c
 */

<<__EntryPoint>> function main(): void {
echo "*** Testing decoct() : usage variations ***\n";


// heredoc string
$heredoc = <<<EOT
abc
xyz
EOT;

// get a resource variable
$fp = fopen(__FILE__, "r");

$inputs = varray[
       // int data
/*1*/  0,
       1,
       12345,
       -2345,
       PHP_INT_MAX,  // largest decimal
       PHP_INT_MIN,

       // float data
/*7*/  10.5,
       -10.5,
       12.3456789000e10,
       12.3456789000E-10,
       .5,

       // null data
/*12*/ NULL,
       null,

       // boolean data
/*14*/ true,
       false,
       TRUE,
       FALSE,

       // empty data
/*18*/ "",
       '',
       varray[],

       // string data
/*21*/ "abcxyz",
       'abcxyz',
       $heredoc,

       // resource variable
/*25*/ $fp
];

// loop through each element of $inputs to check the behaviour of decoct()
$iterator = 1;
foreach($inputs as $input) {
    echo "\n-- Iteration $iterator --\n";
    var_dump(decoct($input));
    $iterator++;
};
fclose($fp);
echo "===Done===";
}
