#!/bin/sh
#
# Generates training batches based on the ILSVRC dataset.

set -e

if [[ $# -ne 4 || -z "$1" ]]; then
    echo "usage: $0 <username> <n> <ptile> <omp_threads>"
    exit 1
fi

username="$1"
n="$2"
ptile="$3"
omp_threads="$4"

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd $DIR

echo "Configuring Bash and Python files..."

sed -i -E "s%work=\".*\"%work=\"${DIR}\"%g" make-data.bash
sed -i -E "s%#BSUB -cwd.*%#BSUB -cwd ${DIR}%g" make-data.bash
sed -i -E "s%scratch_username=\".*\"%scratch_username=\"$username\"%g" make-data.bash
sed -i -E "s/#BSUB -n [0-9]+/#BSUB -n $n/" make-data.bash
sed -i -E "s/#BSUB -R \"span\[ptile=[0-9]+\]\"/#BSUB -R \"span[ptile=$ptile]\"/" make-data.bash
sed -i -E "s/mpirun -np [0-9]+/mpirun -np $n/" make-data.bash
sed -i -E "s/NUM_WORKER_THREADS\s*=\s*[0-9]+/NUM_WORKER_THREADS=$omp_threads/" make-data.py

echo "Removing old files..."
rm -f output_file error_file
rm -f hostlist-tcp hostlistrun
mkdir -p "/scratch/$username/batch"
rm -rf "/scratch/$username/batch/*"

echo "Running job..."
output="$(bsub < make-data.bash)"
jobid="$(echo $output | sed -E 's/.*<([0-9]+)>.*/\1/')"

sleep 1
while bjobs -w | grep "convnet-make-data" | grep -q "PEND"; do
    sleep 1
done

echo "Displaying bpeek contents (use <Ctrl+C> when finished):"
bpeek -f "$jobid"

