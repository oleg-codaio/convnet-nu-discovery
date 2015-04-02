#!/bin/sh
#
# Generates training batches based on the ILSVRC dataset.

if [[ $# -ne 1 || -z "$1" ]]; then
    echo "usage: $0 <username>"
    exit 1
fi

python $(dirname $0)/make-data.py --src-dir /scratch/$1/data --tgt-dir /scratch/$1/batch

