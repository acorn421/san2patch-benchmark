#!/bin/bash

if [ -z "$EXPERIMENT_DIR" ]; then
  echo "EXPERIMENT_DIR NOT SET, TAKING DEFAULT VALUE TO BE ~"
fi
EXPERIMENT_DIR=${EXPERIMENT_DIR:-"~"}

export ASAN_OPTIONS=detect_leaks=0,halt_on_error=0

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
benchmark_name=$(echo $script_dir | rev | cut -d "/" -f 3 | rev)
project_name=$(echo $script_dir | rev | cut -d "/" -f 2 | rev)
bug_id=$(echo $script_dir | rev | cut -d "/" -f 1 | rev)
dir_name=/experiment_func/$benchmark_name/$project_name/$bug_id

cd $dir_name/src

################
#    Run test  #
################

make check -j`nproc` > func_test.err 2>&1

ret=$?
if [[ ret -eq 0 ]]; then
    echo "Test passed"
    exit 0
else
    # Check if the error is ERROR: 1 and FAIL: 1
    # TOTAL: 594
    # PASS:  432
    # SKIP:  160
    # XFAIL: 0
    # FAIL:  1
    # XPASS: 0
    # ERROR: 1
    if grep -q "ERROR: 1" func_test.err && grep -q "FAIL:  1" func_test.err; then
        echo "Test passed"
        exit 0
    else
        echo "Test failed"
        exit 1
    fi
fi