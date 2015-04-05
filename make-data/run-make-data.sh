#!/bin/sh

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
echo $DIR
echo $1
sed -i "s%temp_dir%${DIR}%g" make-data.bash
sed -i "s%scratch_dir%${1}%g" make-data.bash
bsub<make-data.bash
