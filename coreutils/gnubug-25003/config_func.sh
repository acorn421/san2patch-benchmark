#!/bin/bash
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
benchmark_name=$(echo $script_dir | rev | cut -d "/" -f 3 | rev)
project_name=$(echo $script_dir | rev | cut -d "/" -f 2 | rev)
bug_id=$(echo $script_dir | rev | cut -d "/" -f 1 | rev)
dir_name=/experiment_func/$benchmark_name/$project_name/$bug_id
cd $dir_name/src

PROJECT_CFLAGS="-g -O0 "
PROJECT_CXXFLAGS="-g -O0 "

if [[ -n "${CFLAGS}" ]]; then
  PROJECT_CFLAGS="${PROJECT_CFLAGS} ${CFLAGS}"
fi
if [[ -n "${CXXFLAGS}" ]]; then
  PROJECT_CXXFLAGS="${PROJECT_CXXFLAGS} ${CXXFLAGS}"
fi

if [[ -n "${R_CFLAGS}" ]]; then
  PROJECT_CFLAGS="${R_CFLAGS}"
fi

if [[ -n "${R_CXXFLAGS}" ]]; then
  PROJECT_CFLAGS="${R_CXXFLAGS}"
fi

FORCE_UNSAFE_CONFIGURE=1  ./configure CFLAGS="${PROJECT_CFLAGS}"  CXXFLAGS="${PROJECT_CXXFLAGS}"
