#!/bin/sh
#
# Times the code and sends a text message to two numbers once finished.

make_data_type="OpenMP"

set -e

if [[ $# -ne 5 || -z "$1" ]]; then
    echo "usage: $0 <username> <auth_id> <auth_token> <number_one> <number_two>"
    exit 1
fi

auth_id=$2
auth_token=$3
number_one=$4
number_two=$5

sendMessage() {
    return # no Internet on interactive node. :(
    message="$1"
    # Send text messages!
    for dest in $number_one $number_two; do
        echo "Sending text message to $dest"
        wget --no-check-certificate --post-data="{\"src\": \"15744408596\", \"dst\": \"$dest\", \"text\": \"$message\"}" --user="$auth_id" --password="$auth_token" --header="Content-Type: application/json" "https://api.plivo.com/v1/Account/$auth_id/Message/"
        sleep 1
    done
}

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
echo "Running from $DIR in scratch folder of user '$1'"
cd $DIR

sed -i -E "s%work=\".*\"%work=\"${DIR}\"%g" make-data.bash
sed -i -E "s%#BSUB -cwd.*%#BSUB -cwd ${DIR}%g" make-data.bash
sed -i -E "s%scratch_username=\".*\"%scratch_username=\"${1}\"%g" make-data.bash

username="$1"
OLDIFS=$IFS
IFS=','
for bsub_n_and_ptile in 32,32 32,16 32,8 32,4 16,16 16,8 16,4 16,2 8,8 8,4 8,2 8,1 4,4 4,2 4,1 2,2 2,1 1,1; do
    set $bsub_n_and_ptile
    echo "***************** RUNNING WITH n = $1 and ptile = $2"
    sed -i -E "s/#BSUB -n [0-9]+/#BSUB -n $1/" make-data.bash
    sed -i -E "s/#BSUB -R \"span\[ptile=[0-9]+\]\"/#BSUB -R \"span[ptile=$2]\"/" make-data.bash
    sed -i -E "s/mpirun -np [0-9]+/mpirun -np $1/" make-data.bash
    for n in 1024 512 256 128 64 32 30 20 16 10 8 4 2 1; do
        echo "========== Running with $n threads..."
        for s in {1..3}; do
            echo "----- Starting trial #$s"
            rm -f output_file error_file
            rm -f hostlist-tcp hostlistrun
            mkdir -p "/scratch/$username/batch"
            rm -rf "/scratch/$username/batch/*"

            sed -i -E "s/NUM_WORKER_THREADS\s*=\s*[0-9]+/NUM_WORKER_THREADS=$n/" \
                make-data.py

            bsub < make-data.bash
            sleep 1
            while bjobs -w | grep -qi "convnet-make-data"; do
                sleep 1
            done
            sleep 1
            if [ ! -f output_file ]; then
                time="ERROR"
            else
                time="$(cat output_file | grep "Overall time is:" | sed -r "s/.*\s([0-9]+\.[0-9]+)/\1/") s"
                mv output_file output_file_n$1_pt$2_t$s
                mv error_file error_file_n$1_pt$2_t$s
            fi
            echo "... time: $time"
        done
    done
    sendMessage "make-data ($make_data_type): Finished running with n = $1 and ptile = $2 (1 thread: $time s)"
done
IFS=$OLDIFS

sendMessage "Awesome, make-data has finished! :)"
echo "Done!"

