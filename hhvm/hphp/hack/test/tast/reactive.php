<?hh // strict
<<__Rx>>

function foo() : Pure<(function (int) : void)> {
  throw new Exception();
}
