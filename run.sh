#!/bin/sh

export LIB_JPEG_PATH="$(pwd)/jpeg-8"
export LD_LIBRARY_PATH=$LIB_JPEG_PATH:$LD_LIBRARY_PATH

python convnet.py --data-path /scratch/vaskevich.o/batch/ --train-range 0-417 --test-range 1000-1016 --save-path /scratch/vaskevich.o/training --epochs 90 --layer-def layers/layers-imagenet-1gpu.cfg --layer-params layers/layer-params-imagenet-1gpu.cfg --data-provider image --inner-size 224 --gpu 0 --mini 128 --test-freq 201 --color-noise 0.1

