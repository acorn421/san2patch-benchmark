#!/bin/bash
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
benchmark_name=$(echo $script_dir | rev | cut -d "/" -f 3 | rev)
project_name=$(echo $script_dir | rev | cut -d "/" -f 2 | rev)
bug_id=$(echo $script_dir | rev | cut -d "/" -f 1 | rev)
dir_name=/experiment/$benchmark_name/$project_name/$bug_id
cd $dir_name/src

PROJECT_CFLAGS="-fsanitize=address -fPIC -g -O0"
if [[ -n "${CFLAGS}" ]]; then
  PROJECT_CFLAGS="${PROJECT_CFLAGS} ${CFLAGS}"
fi

PROJECT_CXXFLAGS="-fsanitize=address -fPIC -g -O0"
if [[ -n "${CFLAGS}" ]]; then
  PROJECT_CXXFLAGS="${PROJECT_CXXFLAGS} ${CXXFLAGS}"
fi

rm -rf build
mkdir build && cd build
CXXFLAGS=$PROJECT_CXXFLAGS CFLAGS=$PROJECT_CFLAGS cmake -DCMAKE_BUILD_TYPE=Release ..
cd ..