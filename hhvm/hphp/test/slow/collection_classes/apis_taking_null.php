<?hh

<<__EntryPoint>>
function main_apis_taking_null() {
$x = new Vector(null);
var_dump($x);
$x->addAll(null);
var_dump($x);
$x->setAll(null);
var_dump($x);
unset($x);
$x = Vector::fromItems(null);
var_dump($x);
unset($x);
echo "========\n";
$x = new Map(null);
var_dump($x);
$x->addAll(null);
var_dump($x);
$x->setAll(null);
var_dump($x);
unset($x);
$x = Map::fromItems(null);
var_dump($x);
unset($x);
echo "========\n";
$x = new Set(null);
var_dump($x);
$x->addAll(null);
var_dump($x);
$x->addAllKeysOf(null);
var_dump($x);
unset($x);
$x = Set::fromItems(null);
var_dump($x);
unset($x);
$x = Set::fromKeysOf(null);
var_dump($x);
unset($x);
}