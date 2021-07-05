<?hh
/* 
 Prototype: array fgetcsv ( resource $handle [, int $length [, string $delimiter [, string $enclosure]]] );
 Description: Gets line from file pointer and parse for CSV fields
*/

/* Testing fgetcsv() to read a line from a file which doesn't have any CSV field */
<<__EntryPoint>> function main(): void {
echo "*** Testing fgetcsv() : reading the line which is without csv fields ***\n";


$filename = __SystemLib\hphp_test_tmppath('fgetcsv_variation13.tmp');
@unlink($filename);

$file_modes = varray ["r","rb", "rt", "r+", "r+b", "r+t",
                     "a+", "a+b", "a+t",
                     "w+", "w+b", "w+t",
                     "x+", "x+b", "x+t"]; 

$loop_counter = 1;
  for($mode_counter = 0; $mode_counter < count($file_modes); $mode_counter++) {
    // create the file and add the content with has csv fields
    if ( strstr($file_modes[$mode_counter], "r") ) {
      $file_handle = fopen($filename, "w");
    } else {
      $file_handle = fopen($filename, $file_modes[$mode_counter] );
    }
    if ( !$file_handle ) {
      echo "Error: failed to create file $filename!\n";
      exit();
    }
    // write line of text
    fwrite($file_handle, "This is line of text without csv fields\n");

    // close the file if the mode to be used is read mode  and re-open using read mode
    // else rewind the file pointer to beginning of the file 
    if ( strstr($file_modes[$mode_counter], "r" ) ) {
      fclose($file_handle);
      $file_handle = fopen($filename, $file_modes[$mode_counter]);
    } else {
      // rewind the file pointer to bof
      rewind($file_handle);
    }
      
    echo "\n-- Testing fgetcsv() with file opened using $file_modes[$mode_counter] mode --\n"; 

     
    // read the line which is without csv fields, provide delimiter and see the working of fgetcsv
    $fp_pos = ftell($file_handle);
    var_dump( fgetcsv($file_handle) );
    // check the file pointer position and if eof
    var_dump( ftell($file_handle) );
    var_dump( feof($file_handle) );

    // close the file
    fclose($file_handle);
    //delete file
    unlink($filename);
  } //end of mode loop 

echo "Done\n";
}