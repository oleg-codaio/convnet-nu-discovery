#!/bin/sh
#
# Generates training batches based on the ILSVRC dataset.

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

rm -f output_file error_file
rm -f hostlist-tcp hostlistrun
mkdir -p "/scratch/$1/batch"
rm -rf "/scratch/$1/batch/*"

bsub < make-data.bash

echo "Running... use <Ctrl-C> and bpeek -f <jobid> to monitor output"
while bjobs -w | grep -qi "convnet-make-data"; do
    sleep 1
done

echo "Done!"

