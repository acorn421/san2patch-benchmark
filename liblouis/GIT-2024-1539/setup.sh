#!/bin/bash
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
benchmark_name=$(echo $script_dir | rev | cut -d "/" -f 3 | rev)
project_name=$(echo $script_dir | rev | cut -d "/" -f 2 | rev)
bug_id=$(echo $script_dir | rev | cut -d "/" -f 1 | rev)
dir_name=/experiment/$benchmark_name/$project_name/$bug_id
current_dir=$PWD
mkdir -p $dir_name
cd $dir_name
mkdir dev-patch

project_url=https://github.com/liblouis/liblouis
fix_commit_id=bcd508d9dfb2c3e01cf65da316f195163f4c093c
bug_commit_id=245bad8d825e18ad52f5e9c9dc2d010d7a0eb552

cd $dir_name
git clone $project_url src
cd src
git checkout $bug_commit_id
git format-patch -1 --stdout $fix_commit_id > fix.patch
cp fix.patch $dir_name/dev-patch/fix.patch

./autogen.sh
