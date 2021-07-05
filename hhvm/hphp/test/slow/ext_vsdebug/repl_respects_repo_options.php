<?hh

function skipEvents() {
  $msg = json_decode(getNextVsDebugMessage(), true);
  while ($msg['type'] == 'event') {
    if ($msg['event'] === 'output') {
      $body = $msg['body'];
      if ($body['category'] === 'stdout') {
        printf("STDOUT: %s", $body['output']);
      }
    }
    $msg = json_decode(getNextVsDebugMessage(), true);
  }

  return $msg;
}
<<__EntryPoint>> function main(): void {
chdir(__DIR__);
require('./common.inc');
$path = __FILE__ . ".test";
$testProcess = vsDebugLaunch($path, true, varray[]);
// We don't actually need the stack trace, but we do need a frame ID to execute
// in - even though we know what it will be, it won't be allocated until we
// request a stack trace, so, here goes nothing :)
sendVsCommand(darray[
  'command' => 'stackTrace',
  'type' => 'request',
  'arguments' => darray['threadId' => 1],
]);
skipEvents();

echo "---- FRAME: repo_options_test_main();-----\n";

$seq = sendVsCommand(darray[
  "command" => "evaluate",
  "type" => "request",
  "arguments" =>
  darray["frameId" => 2,
  "expression" => 'Aliased\\hello()',
  'context' => 'repl']]);

$msg = skipEvents();
checkObjEqualRecursively($msg, darray[
  "type" => "response",
  "command" => "evaluate",
  "success" => true,
  "request_seq" => $seq]);

echo "---- FRAME: hphp_debug_break() -----\n";

// Should fail, as `Aliased\` won't expand
$seq = sendVsCommand(darray[
  "command" => "evaluate",
  "type" => "request",
  "arguments" =>
  darray["frameId" => 1,
  "expression" => 'Aliased\\hello()',
  'context' => 'repl']]);
$msg = skipEvents();
checkObjEqualRecursively($msg, darray[
  "type" => "response",
  "command" => "evaluate",
  "success" => false,
  "request_seq" => $seq]);


echo "----- OK! -----\n";
}
