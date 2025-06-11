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

project_url=https://github.com/kamailio/kamailio.git
fix_commit_id=d4bbde619bbf808edebb31e131b3783ba2a4b34d
bug_commit_id=5.8.3

cd $dir_name
git clone $project_url src
cd src
git checkout $bug_commit_id
cp $current_dir/main_parse_msg.c ./misc/fuzz/main_parse_msg.c
git format-patch -1 $fix_commit_id
cp *.patch $dir_name/dev-patch/fix.patch
