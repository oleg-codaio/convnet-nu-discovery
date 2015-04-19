#!/bin/sh
#
# Times the code and sends a text message to two numbers once finished.

set -e

if [[ $# -ne 5 || -z "$1" ]]; then
    echo "usage: $0 <username> <auth_id> <auth_token> <number_one> <number_two>"
    exit 1
fi

auth_id=$2
auth_token=$3
number_one=$4
number_two=$5

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
echo "Running from $DIR in scratch folder of user '$1'"
cd $DIR

sed -i -E "s%work=\".*\"%work=\"${DIR}\"%g" make-data.bash
sed -i -E "s%#BSUB -cwd.*%#BSUB -cwd ${DIR}%g" make-data.bash
sed -i -E "s%scratch_username=\".*\"%scratch_username=\"${1}\"%g" make-data.bash

username="$1"
OLDIFS=$IFS
IFS=','
for bsub_n_and_ptile in 1,1 2,1 2,2 4,1 4,2, 4,4 8,1 8,2 8,4 8,8 16,2 16,4 16,8 16,16 32,4 32,8 32,16 32,32; do
    set $bsub_n_and_ptile
    echo "***************** RUNNING WITH n = $1 and ptile = $2"
    sed -i -E "s/#BSUB -n [0-9]+/#BSUB -n $1/" make-data.bash
    sed -i -E "s/#BSUB -R \"span\[ptile=[0-9]+\]\"/#BSUB -R \"span[ptile=$2]\"/" make-data.bash
    sed -i -E "s/mpirun -np [0-9]+/mpirun -np $1/" make-data.bash
    for s in seq 10; do
        echo "========= Starting trial #$s"
        for n in 1 2 4 8 16 32 64 128 256 512; do
            rm -f output_file error_file
            rm -f hostlist-tcp hostlistrun
            mkdir -p "/scratch/$username/batch"
            rm -rf "/scratch/$username/batch/*"

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
    done
done
IFS=$OLDIFS

# Send text messages!
for dest in $number_one $number_two; do
    echo "Sending text message to $dest"
    wget --no-check-certificate --post-data="{\"src\": \"15744408596\", \"dst\": \"$dest\", \"text\": \"make-data has finished!!!! :)\"}" --user="$auth_id" --password="$auth_token" --header="Content-Type: application/json" "https://api.plivo.com/v1/Account/$auth_id/Message/"
    sleep 1
done

echo "Done!"
