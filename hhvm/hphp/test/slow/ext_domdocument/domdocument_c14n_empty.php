<?hh

<<__EntryPoint>>
function main_domdocument_C14N_empty() {
$doc = new DOMDocument();
var_dump($doc->C14N());
}
