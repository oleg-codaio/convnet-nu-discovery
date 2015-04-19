#!/bin/sh
#
# Times the code.

set -e

if [[ $# -ne 1 || -z "$1" ]]; then
    echo "usage: $0 <username>"
    exit 1
fi

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
echo "Running from $DIR in scratch folder of user '$1'"
cd $DIR

sed -i -E "s%work=\".*\"%work=\"${DIR}\"%g" make-data.bash
sed -i -E "s%#BSUB -cwd.*%#BSUB -cwd ${DIR}%g" make-data.bash
sed -i -E "s%scratch_username=\".*\"%scratch_username=\"${1}\"%g" make-data.bash

for n in 1 2 4 8 16 32 64 128 256 512; do
    rm -f output_file error_file
    rm -f hostlist-tcp hostlistrun
    mkdir -p "/scratch/$1/batch"
    rm -rf "/scratch/$1/batch/*"

    sed -i -E "s/NUM_WORKER_THREADS\s+=\s+[0-9]+/NUM_WORKER_THREADS=$n/" \
        make-data.py

    echo "Running with $n threads..."
    bsub < make-data.bash
    while bjobs -w | grep -qi "convnet-make-data"; do
        sleep 1
    done
    time=$(cat output_file | grep "Overall time is:" | sed -r "s/.*\s([0-9]+\.[0-9]+)/\1/")
    echo "... time: $time s"
done

echo "Done!"

