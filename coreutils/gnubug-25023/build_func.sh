#!/bin/bash
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
benchmark_name=$(echo $script_dir | rev | cut -d "/" -f 3 | rev)
project_name=$(echo $script_dir | rev | cut -d "/" -f 2 | rev)
bug_id=$(echo $script_dir | rev | cut -d "/" -f 1 | rev)
dir_name=/experiment_func/$benchmark_name/$project_name/$bug_id
cd $dir_name/src

if [[ -z "${OPT}" ]]; then # if not set, use -O0
  OPT=-O0
fi

PROJECT_CFLAGS="-ggdb -Wno-error ${OPT}"
PROJECT_CXXFLAGS="-ggdb -Wno-error ${OPT}"
PROJECT_LDFLAGS="-Wno-error ${OPT}"

if [[ -n "${CFLAGS}" ]]; then
  PROJECT_CFLAGS="${PROJECT_CFLAGS} ${CFLAGS}"
fi
if [[ -n "${CXXFLAGS}" ]]; then
  PROJECT_CXXFLAGS="${PROJECT_CXXFLAGS} ${CXXFLAGS}"
fi
if [[ -n "${LDFLAGS}" ]]; then
  PROJECT_LDFLAGS="${PROJECT_LDFLAGS} ${LDFLAGS}"
fi

make CFLAGS="${PROJECT_CFLAGS}" CXXFLAGS="${PROJECT_CXXFLAGS}" LDFLAGS="${PROJECT_LDFLAGS}" -j`nproc`
make CFLAGS="${PROJECT_CFLAGS}" CXXFLAGS="${PROJECT_CXXFLAGS}" LDFLAGS="${PROJECT_LDFLAGS}" -j`nproc` src/pr
