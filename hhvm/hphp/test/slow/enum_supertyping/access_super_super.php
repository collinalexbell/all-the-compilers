<?hh
// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.

enum E1 : int {
  A = 1;
}

enum E2 : int {
  use E1;
}

enum F : int {
  use E2;
}

<<__EntryPoint>>
function main() : void {
  echo F::A . "\n";
}
