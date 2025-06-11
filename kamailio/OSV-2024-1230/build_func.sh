#!/bin/bash
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
benchmark_name=$(echo $script_dir | rev | cut -d "/" -f 3 | rev)
project_name=$(echo $script_dir | rev | cut -d "/" -f 2 | rev)
bug_id=$(echo $script_dir | rev | cut -d "/" -f 1 | rev)
dir_name=/experiment_func/$benchmark_name/$project_name/$bug_id
cd $dir_name/src

make -j`nproc` all
# make install

# if [[ -z "${OPT}" ]]; then # if not set, use -O0
#   OPT=-O0
# fi

# PROJECT_CFLAGS=" -static -ggdb ${OPT}"
# PROJECT_CXXFLAGS=" -static -ggdb ${OPT}"
# PROJECT_LDFLAGS="-static ${OPT}"

# PROJECT_CFLAGS="-shared -fPIC -fPIE -g -Wno-error ${OPT}"
# PROJECT_CXXFLAGS="-shared -fPIC -fPIE -g -Wno-error ${OPT}"
# PROJECT_LDFLAGS="-pie"

# PROJECT_CFLAGS="${PROJECT_CFLAGS} ${CFLAGS:-} ${R_CFLAGS:-}"
# PROJECT_CXXFLAGS="${PROJECT_CXXFLAGS} ${CXXFLAGS:-} ${R_CXXFLAGS:-}"
# PROJECT_LDFLAGS="${PROJECT_LDFLAGS} ${LDFLAGS:-} ${R_LDFLAGS:-}"

# make CFLAGS="${PROJECT_CFLAGS}" CXXFLAGS="${PROJECT_CXXFLAGS}" LDFLAGS="${PROJECT_LDFLAGS}" -I./src/ -L./src/ -j`nproc` all