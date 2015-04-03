#!/bin/sh

TRAIN_RANGE=0-0 # 0-417
TEST_RANGE=1000-1016
EPOCHS=90
INNER_SIZE=224
GPU=0
MINI=128
TEST_FREQ=201
COLOR_NOISE=0.1

if [[ $# -ne 1 || -z "$1" ]]; then
    echo "usage: $0 <username>"
    exit 1
fi

export LIB_JPEG_PATH="$(pwd)/jpeg-8/output/lib"
export LD_LIBRARY_PATH=$LIB_JPEG_PATH:$LD_LIBRARY_PATH

exec python convnet.py --data-path /scratch/$1/batch/ --train-range $TRAIN_RANGE --test-range $TEST_RANGE --save-path /scratch/$1/training --epochs $EPOCHS --layer-def layers/layers-imagenet-1gpu.cfg --layer-params layers/layer-params-imagenet-1gpu.cfg --data-provider image --inner-size $INNER_SIZE --gpu $GPU --mini $MINI --test-freq $TEST_FREQ --color-noise $COLOR_NOISE

