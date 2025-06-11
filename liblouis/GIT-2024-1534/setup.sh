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
fix_commit_id=b0d2b3e57d44ff27e33d61964d268c7475153c42
bug_commit_id=1d2768e8847b094559064ca9ebfe30811e384b8d

cd $dir_name
git clone $project_url src
cd src
git checkout $bug_commit_id
git format-patch -1 --stdout $fix_commit_id > fix.patch
cp fix.patch $dir_name/dev-patch/fix.patch

./autogen.sh
