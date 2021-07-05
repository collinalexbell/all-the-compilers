<?hh
<<__EntryPoint>> function main(): void {
$string_variation = varray[ "%5s", "%-5s", "%05s", "%'#5s" ];
$strings = varray[ NULL, "abc", 'aaa' ];

/* creating dumping file */
$data_file = __SystemLib\hphp_test_tmppath('fprintf_variation_009.phpt.txt');
if (!($fp = fopen($data_file, 'wt')))
   return;

$counter = 1;
/* string type variations */
fprintf($fp, "\n*** Testing fprintf() for string types ***\n");
foreach( $string_variation as $string_var ) {
  fprintf( $fp, "\n-- Iteration %d --\n",$counter);
  foreach( $strings as $str ) {
    fprintf( $fp, "\n");
    fprintf( $fp, $string_var, $str );
  }
  $counter++;
}

fclose($fp);

print_r(file_get_contents($data_file));
echo "\nDone";

unlink($data_file);
}