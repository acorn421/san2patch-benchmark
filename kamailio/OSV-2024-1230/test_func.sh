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

cd $dir_name/src/test/unit

runnable_unit_tests=(1.sh 10.sh 19.sh 20.sh 21.sh 4.sh 5.sh 60.sh 9.sh)

rm -rf func_test.err
for unit_test in ${runnable_unit_tests[@]}; do
    echo "Running unit test $i"
    # run each unit test with timeout 30
    timeout 30 make run UNIT=$unit_test >> func_test.err 2>&1
done

if [[ $(grep -Ec "Test unit file [0-9]+\.sh: failed" func_test.err) -eq 0 ]] && [[ $(grep -Ec "Test unit file [0-9]+\.sh: ok" func_test.err) -eq 9 ]]; then
    echo "Test passed"
    exit 0
else
    echo "Test failed"
    exit 1
fi