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
    ./make-data.sh vaskevich.o

Training
--------
First, install some more dependencies:

    pip install --user pillow

To train the neural network, run a command like this:

    ./run.sh

