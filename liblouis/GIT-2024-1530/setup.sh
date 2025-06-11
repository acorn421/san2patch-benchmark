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
fix_commit_id=781b0323d20083f3c7835f99efe2c1a60a01ecb4
bug_commit_id=fabd5f2e0d3429bc07cdc6d49cfb6a4b240e1495

cd $dir_name
git clone $project_url src
cd src
git checkout $bug_commit_id
git format-patch -1 --stdout $fix_commit_id > fix.patch
cp fix.patch $dir_name/dev-patch/fix.patch

./autogen.sh
