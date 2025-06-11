# !/bin/bash

set -x

for dir1 in */; do
    if [ -d "$dir1" ]; then
        cd "$dir1" || exit
        for dir2 in */; do
            if [ -d "$dir2" ]; then
                cd "$dir2" || exit
		
		./config.sh && ./build.sh
		./test.sh $(ls ./tests | sort | head -1)

                cd .. || exit
            fi
        done
        cd .. || exit
    fi
done

set +x
