<?hh
//line 2
//line 3
//line 4
//line 5
<<__EntryPoint>> function main(): void {
$s = new SplFileObject(__FILE__);
echo $s->current();
$s->next();

echo $s->current();
}