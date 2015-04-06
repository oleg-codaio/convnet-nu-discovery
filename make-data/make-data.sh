#!/bin/sh
#
# Generates training batches based on the ILSVRC dataset.

if [[ $# -ne 1 || -z "$1" ]]; then
    echo "usage: $0 <username>"
    exit 1
fi

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
echo $DIR
echo $1
sed -i -E "s%work=\".*\"%work=\"${DIR}\"%g" make-data.bash
sed -i -E "s%#BSUB -cwd.*%#BSUB -cwd ${DIR}%g" make-data.bash
sed -i -E "s%scratch_username=\".*\"%scratch_username=\"${1}\"%g" make-data.bash

rm output_file error_file
rm hostlist-tcp hostlistrun

bsub<make-data.bash

while bjobs -w | grep -qi "convnet-make-data"; do
    sleep 1
done

echo "Done!"

