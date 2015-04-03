convnet-nu-discovery
====================
Based off cuda-convnet2, this framework for fast convolutional neural networks
is ported to run on Northeastern University's Discovery Cluster.

As part of coursework for EECE 5640: High-Performance Computing, we are adapting
this framework for use on NU's Discovery Cluster, with the intention to increase
performance via CUDA, OpenMP and MPI.

Loading modules
---------------
To make things easier, add these lines to your ~/.bashrc:

    module load gnu-4.4-compilers 
    module load fftw-3.3.3
    module load platform-mpi
    module load gnu-4.8.1-compilers
    module load python-2.7.5
    module load oracle_java_1.7u40
    module load atlas-sse3-3.8.4-2
    module load matlab_dce_2013b
    module load cuda-6.5
    module load ant-1.9.3
    module load apache-maven-3.2.3
    module load protobuf-2.6.1
    module load vtk-5.10.1
    module load opencv

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
username). This may take a couple hours. For this, it is recommended that you
use `tmux` to avoid losing your progress in case you get logged out or need to
disconnect. In that case, simply run `tmux a` to reattach to your session after
logging back into the cluster.

    source ./load_modules.sh
    cd make-data
    ./make-data.sh vaskevich.o

Training
--------
First, connect to a login node and launch `tmux`. Then open an interactive
session on a GPU node.

    bsub -Is -n 32 -q par-gpu -R span[ptile=32] /bin/bash

To train the neural network, use the provided script.

    ./run.sh vaskevich.o

You may need to tweak it to meet your requirements.

Further reading
---------------
See [cuda-convnet2](https://code.google.com/p/cuda-convnet2/wiki/TrainingExample).

