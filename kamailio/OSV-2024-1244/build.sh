#!/bin/bash
set -x

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
benchmark_name=$(echo $script_dir | rev | cut -d "/" -f 3 | rev)
project_name=$(echo $script_dir | rev | cut -d "/" -f 2 | rev)
bug_id=$(echo $script_dir | rev | cut -d "/" -f 1 | rev)
dir_name=/experiment/$benchmark_name/$project_name/$bug_id
cd $dir_name/src

PROJECT_CFLAGS="-fsanitize=address -fno-omit-frame-pointer -g -Wno-error -O0"
PROJECT_CXXFLAGS="-fsanitize=address -fno-omit-frame-pointer -g -Wno-error -O0"
PROJECT_LDFLAGS="-fsanitize=address"

PROJECT_CFLAGS="${PROJECT_CFLAGS} ${CFLAGS:-} ${R_CFLAGS:-}"
PROJECT_CXXFLAGS="${PROJECT_CXXFLAGS} ${CXXFLAGS:-} ${R_CXXFLAGS:-}"
PROJECT_LDFLAGS="${PROJECT_LDFLAGS} ${LDFLAGS:-} ${R_LDFLAGS:-}"

export CC_OPT="${PROJECT_CFLAGS}"
export LD_EXTRA_OPTS="${PROJECT_CFLAGS}"

sed -i 's/int main(/int main2(/g' ./src/main.c

export MEMPKG=sys
make Q=verbose CFLAGS="${PROJECT_CFLAGS}" CXXFLAGS="${PROJECT_CXXFLAGS}" LDFLAGS="${PROJECT_LDFLAGS}" -j`nproc` || true

cd src
rm -rf objects libkamilio.a
mkdir objects && find . -name "*.o" -exec cp {} ./objects/ \;
ar -r libkamilio.a ./objects/*.o
cd ../

CC=cc
CXX=c++

rm -rf main_parse_msg main_parse_msg.o

$CC ${PROJECT_CFLAGS} ./misc/fuzz/main_parse_msg.c -c -DFAST_LOCK -D__CPU_i386 ./src/libkamilio.a -I./src/ -I./src/core/parser -ldl -lresolv -lm

# $CXX ${PROJECT_CXXFLAGS} ${PROJECT_LDFLAGS} main_parse_msg.o -o ./main_parse_msg \
$CC ${PROJECT_CFLAGS} ${PROJECT_LDFLAGS} main_parse_msg.o -o ./main_parse_msg -DFAST_LOCK -D__CPU_i386 ./src/libkamilio.a -I./src/ -I./src/core/parser -ldl -lresolv -lm