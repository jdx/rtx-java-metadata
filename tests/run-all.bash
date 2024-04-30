#!/usr/bin/env bash

# Set the working directory to the tests folder, as the script will only find
# tests relative to the current working directory.
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd "$SCRIPT_DIR" || exit

any_fail=0

for test_script in test.*; do
    if [ -x "$test_script" ]; then
        if ! ./"$test_script" ; then
            any_fail=1
        fi
    fi
done

# Return 0 if all tests pass, 1 if any test fails
exit $any_fail
