<?hh

<<file:__EnableUnstableFeatures('expression_trees')>>

async function bar(
  ExampleContext $_,
): Awaitable<ExprTree<Code, Code::TAst, (function(ExampleString): ExampleInt)>> {
  throw new Exception();
}

function foo(): void {
  $fun_call = Code`bar("baz")`;
}
