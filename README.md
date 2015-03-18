convnet-nu-discovery
====================
Based off cuda-convnet2, this framework for fast convolutional neural networks
is ported to run on Northeastern University's Discovery Cluster.

As part of coursework for EECE 5640: High-Performance Computing, we are adapting
this framework for use on NU's Discovery Cluster, with the intention to increase
performance via CUDA, OpenMP and MPI.

Compiling
---------
This framework is already preconfigured to run on the Discovery cluster. To
compile it, simply run `./build.sh` from the root of the repository.

Training data
-------------
First, download these components of the ILSVRC 2012 dataset: training images for
task 1 & 2, validation images for all tasks, development kit for tasks 1 & 2.
You should be able to use `wget` on the links obtained from this website:
`http://www.image-net.org/download-images`. Since the dataset is over 145 GB,
you may want to use `tmux` to download the data in the background. Save it into
`/scratch` under a subdirectory named as your NU login id, into a `data`
directory.

Now, generate the training batches (substitute `vaskevich.o` with your
username). This may take a couple hours.

    source ./load_modules.sh
    cd make-data
    python make-data.py --src-dir /scratch/vaskevich.o/data --tgt-dir /scratch/vaskevich.o/batches

Training
--------
To train the neural network, run a command like this:

    python convnet.py --data-path /scratch/vaskevich.o/batch/ --train-range 0-417 --test-range 1000-1016 --save-path /scratch/vaskevich.o/training --epochs 90 --layer-def layers/layers-imagenet-1gpu.cfg --layer-params layers/layer-params-imagenet-1gpu.cfg --data-provider image --inner-size 224 --gpu 0 --mini 128 --test-freq 201 --color-noise 0.1

