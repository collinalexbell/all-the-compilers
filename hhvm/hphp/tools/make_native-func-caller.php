<?hh
/*
   +----------------------------------------------------------------------+
   | HipHop for PHP                                                       |
   +----------------------------------------------------------------------+
   | Copyright (c) 2010-present Facebook, Inc. (http://www.facebook.com)  |
   +----------------------------------------------------------------------+
   | This source file is subject to version 3.01 of the PHP license,      |
   | that is bundled with this package in the file LICENSE, and is        |
   | available through the world-wide-web at the following url:           |
   | http://www.php.net/license/3_01.txt                                  |
   | If you did not receive a copy of the PHP license and are unable to   |
   | obtain it through the world-wide-web, please send a note to          |
   | license@php.net so we can mail you a copy immediately.               |
   +----------------------------------------------------------------------+
*/


/**
 * Generate the ABI wrapper functions for HPHP::Native::NativeFuncCaller
 *
 * The NativeFuncCaller class relies on specifics of the amd64 and ARMv8 ABIs
 * to reshuffle the order of certain arguments and reduce the number of
 * possible combinations (by a lot).
 *
 * If you don't understand how NativeFuncCaller works, don't use this script.
 * If you do, then adjust NUM_GP_ARGS/NUM_SIMD_ARGS as needed and pipe the
 * output of this script to runtime/vm/native-func-caller.h
 *
 * I solemnly swear that I am up to no good.
 */
const NUM_GP_ARGS = 32; // Must match kMaxBuiltinArgs
const NUM_SIMD_ARGS = 8; // Must match CPU's ABI definition for SIMD usage

function go($name, $ret) {
  $callerArgs = 'NativeFunction f, int64_t* GP, int GP_count, '.
                'double* SIMD, int SIMD_count';

  fwrite(STDOUT, "{$ret} callFunc{$name}Impl({$callerArgs}) {\n");
  fwrite(STDOUT, "  switch (GP_count) {\n");
  $gpargs = vec[];
  for ($gp = 0; $gp <= NUM_GP_ARGS; ++$gp) {
    fwrite(STDOUT, "    case {$gp}:\n");
    fwrite(STDOUT, "      switch (SIMD_count) {\n");
    $simdargs = vec[];
    for ($simd = 0; $simd <= NUM_SIMD_ARGS; ++$simd) {
      $argsD = implode(',', array_merge($gpargs, $simdargs));
      $argsC = vec[];
      for ($i = 0; $i < $gp; ++$i) {
        $argsC[] = "GP[$i]";
      }
      for ($i = 0; $i < $simd; ++$i) {
        $argsC[] = "SIMD[$i]";
      }
      $argsC = implode(',', $argsC);
      fwrite(STDOUT, "        case {$simd}:\n");
      fwrite(STDOUT, "          return (({$ret} (*)({$argsD}))f)({$argsC});\n");
      $simdargs[] = 'double';
    }
    fwrite(STDOUT, "        default: not_reached();\n");
    fwrite(STDOUT, "      }\n");
    $gpargs[] = 'int64_t';
  }
  fwrite(STDOUT, "    default: not_reached();\n");
  fwrite(STDOUT, "  }\n");
  fwrite(STDOUT, "}\n\n");
}

<<__EntryPoint>>
function main() {
  fwrite(STDOUT, "// @"."generated by hphp/tools/make_native-func-caller.php\n\n");

  fwrite(STDOUT, "static_assert(kMaxBuiltinArgs == " . NUM_GP_ARGS.
              ",\"Regenerate native-func-caller.h for updated ".
              "kMaxBuiltinArgs\");\n\n");

  fwrite(STDOUT, "static_assert(kNumSIMDRegs == " . NUM_SIMD_ARGS.
              ",\"Regenerate native-func-caller.h for updated ".
              "kNumSIMDRegs\");\n\n");

  go('Double', 'double');
  go('Int64', 'int64_t');
  go('TV', 'TypedValue');
  fwrite(STDOUT, "template<class IndirectRet>\n");
  go('Indirect', 'IndirectRet');
}