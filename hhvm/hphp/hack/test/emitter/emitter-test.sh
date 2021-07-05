#!/bin/bash

TEST="$1"
CHECKER="$2"
EMITTER="$3"
HHVM="$4"

HHVM_CMD="$HHVM -vRepo.Path=verify.hhbc"

HHAS="$TEST.hhas"
EXPECTED="$TEST.exp"

# First, compute the expected output using regular HHVM execution
(cat "$TEST"; echo "test();") | $HHVM_CMD /dev/stdin > "$EXPECTED"

# Typecheck, compile with the emitter and run the generated assembly
export HH_TEST_MODE=1  # avoid writing a bunch of telemetry
"$CHECKER" "$TEST" > /dev/null &&
"$EMITTER" --test "$TEST" > "$HHAS" &&
  $HHVM_CMD -vEval.AllowHhas=1 "$HHAS"
