#!/shared/apps/python/Python-2.7.5/INSTALL/bin/python
#
# Copyright 2014 Google Inc. All rights reserved.
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#    http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#################################################################################


# This script makes batches suitable for training from raw ILSVRC 2012 tar files.

import tarfile
from pprint import pprint
from StringIO import StringIO
from random import shuffle
import sys
from time import time
from pyext._MakeDataPyExt import resizeJPEG
import itertools
import os
import cPickle
import scipy.io
import math
import argparse as argp

from mpi4py import MPI

# Set this to True to crop images to square. In this case each image will be
# resized such that its shortest edge is OUTPUT_IMAGE_SIZE pixels, and then the
# center OUTPUT_IMAGE_SIZE x OUTPUT_IMAGE_SIZE patch will be extracted.
#
# Set this to False to preserve image borders. In this case each image will be
# resized such that its shortest edge is OUTPUT_IMAGE_SIZE pixels. This was
# demonstrated to be superior by Andrew Howard in his very nice paper:
# http://arxiv.org/abs/1312.5402
CROP_TO_SQUARE          = True
OUTPUT_IMAGE_SIZE       = 256

# Number of threads to use for JPEG decompression and image resizing.
NUM_WORKER_THREADS      = 8

# Don't worry about these.
OUTPUT_BATCH_SIZE = 3072
OUTPUT_SUB_BATCH_SIZE = 1024

mComm = MPI.COMM_WORLD
mSize = mComm.Get_size()
mRank = mComm.Get_rank()
mName = MPI.Get_processor_name()

def pickle(filename, data):
    with open(filename, "w") as fo:
        cPickle.dump(data, fo, protocol=cPickle.HIGHEST_PROTOCOL)

def unpickle(filename):
    fo = open(filename, 'r')
    contents = cPickle.load(fo)
    fo.close()
    return contents

# http://code.activestate.com/recipes/425397-split-a-list-into-roughly-equal-sized-pieces/
def split_seq(seq, size):
    newseq = []
    splitsize = 1.0/size*len(seq)
    for i in range(size):
        newseq.append(seq[int(round(i*splitsize)):int(round((i+1)*splitsize))])
    return newseq

def partition_list(l, partition_size):
    divup = lambda a,b: (a + b - 1) / b
    return [l[i*partition_size:(i+1)*partition_size] for i in xrange(divup(len(l),partition_size))]

def open_tar(path, name):
    if not os.path.exists(path):
        if mRank == 0:
            print "ILSVRC 2012 %s not found at %s. Make sure to set ILSVRC_SRC_DIR correctly at the top of this file (%s)." % (name, path, sys.argv[0])
        sys.exit(1)
    return tarfile.open(path)

def makedir(path):
    if not os.path.exists(path):
        os.makedirs(path)

def parse_devkit_meta(ILSVRC_DEVKIT_TAR):
    tf = open_tar(ILSVRC_DEVKIT_TAR, 'devkit tar')
    fmeta = tf.extractfile(tf.getmember('ILSVRC2012_devkit_t12/data/meta.mat'))
    meta_mat = scipy.io.loadmat(StringIO(fmeta.read()))
    labels_dic = dict((m[0][1][0], m[0][0][0][0]-1) for m in meta_mat['synsets'] if m[0][0][0][0] >= 1 and m[0][0][0][0] <= 1000)
    label_names_dic = dict((m[0][1][0], m[0][2][0]) for m in meta_mat['synsets'] if m[0][0][0][0] >= 1 and m[0][0][0][0] <= 1000)
    label_names = [tup[1] for tup in sorted([(v,label_names_dic[k]) for k,v in labels_dic.items()], key=lambda x:x[0])]

    fval_ground_truth = tf.extractfile(tf.getmember('ILSVRC2012_devkit_t12/data/ILSVRC2012_validation_ground_truth.txt'))
    validation_ground_truth = [[int(line.strip()) - 1] for line in fval_ground_truth.readlines()]
    tf.close()
    return labels_dic, label_names, validation_ground_truth

def write_batches(target_dir, name, start_batch_num, labels, jpeg_files):
    jpeg_files = partition_list(jpeg_files, OUTPUT_BATCH_SIZE / mSize)
    labels = partition_list(labels, OUTPUT_BATCH_SIZE / mSize)
    makedir(target_dir)
    print "Writing %s batches..." % name
    for i,(labels_batch, jpeg_file_batch) in enumerate(zip(labels, jpeg_files)):
        t = time()
        jpeg_strings = list(itertools.chain.from_iterable(resizeJPEG([jpeg.read() for jpeg in jpeg_file_batch], OUTPUT_IMAGE_SIZE, NUM_WORKER_THREADS, CROP_TO_SQUARE)))
        batch_path = os.path.join(target_dir, 'data_batch_%d' % (start_batch_num + i))
        makedir(batch_path)
        for j in xrange(0, len(labels_batch), OUTPUT_SUB_BATCH_SIZE):
            pickle(os.path.join(batch_path, 'data_batch_%d.%d' % (start_batch_num + i, j/OUTPUT_SUB_BATCH_SIZE)), 
                   {'data': jpeg_strings[j:j+OUTPUT_SUB_BATCH_SIZE],
                    'labels': labels_batch[j:j+OUTPUT_SUB_BATCH_SIZE]})
        print "Wrote %s (%s batch %d of %d) (%.2f sec) - rank %d" % (batch_path, name, i+1, len(jpeg_files), time() - t, mRank)
    return i + 1

if __name__ == "__main__":
    mComm.barrier()
    START_TIME = None
    if mRank == 0:
        START_TIME = time()
    # TODO(sussman.sa): Parse only on master and broadcast.
    parser = argp.ArgumentParser()
    parser.add_argument('--src-dir', help='Directory containing ILSVRC2012_img_train.tar, ILSVRC2012_img_val.tar, and ILSVRC2012_devkit_t12.tar.gz', required=True)
    parser.add_argument('--tgt-dir', help='Directory to output ILSVRC 2012 batches suitable for cuda-convnet to train on.', required=True)
    args = parser.parse_args()
    print "CROP_TO_SQUARE: %s" % CROP_TO_SQUARE
    print "OUTPUT_IMAGE_SIZE: %s" % OUTPUT_IMAGE_SIZE
    print "NUM_WORKER_THREADS: %s" % NUM_WORKER_THREADS

    ILSVRC_TRAIN_TAR = os.path.join(args.src_dir, 'ILSVRC2012_img_train.tar')
    ILSVRC_VALIDATION_TAR = os.path.join(args.src_dir, 'ILSVRC2012_img_val.tar')
    ILSVRC_DEVKIT_TAR = os.path.join(args.src_dir, 'ILSVRC2012_devkit_t12.tar.gz')

    assert OUTPUT_BATCH_SIZE % OUTPUT_SUB_BATCH_SIZE == 0
    labels_dic, label_names, validation_labels = parse_devkit_meta(ILSVRC_DEVKIT_TAR)

    with open_tar(ILSVRC_TRAIN_TAR, 'training tar') as tf:
        synsets = tf.getmembers()
        mComm.Barrier()

        scatterable_synsets = split_seq(synsets, mSize)
        local_synsets = mComm.scatter(scatterable_synsets, root=0)
        print "node %d is extracting..." % mRank
        sys.stdout.flush()

        local_synset_tars = [tarfile.open(fileobj=tf.extractfile(s)) for s in local_synsets]
        mComm.barrier()
        if mRank == 0:
            print "Loaded synset tars."
            print "Building training set image list (this can take 10-20 minutes)..."
            sys.stdout.flush()
        mComm.barrier()
    
        t = time()
        local_train_jpeg_files = []
        # TODO(vaskevich.o): Fix global progress.
        #if mRank == 0:
        #    worker_progress = [[0] for _ in range(mSize)]
        #    for i in range(1, mSize):
        #        mComm.irecv(worker_progress[i], i)

        for i,st in enumerate(local_synset_tars):
            if i % 5 == 0: # 100
                #if mRank == 0:
                #    total_progress = reduce(lambda x, y: x[0] + y[0], worker_progress)
                #    print "%d%%..." % total_progress,
                #    sys.stdout.flush()
#                    for i in range(1, mSize):
#                        if mComm.Iprobe(i):
#                            mComm.
#                            mComm.Irecv(worker_progress[i], source=i)
                #else:
                #    local_percent_done = 100.0 * float(i) / len(local_synset_tars)
                #    mComm.isend([local_percent_done], 0)
                print "(rank %d) %d%% ..." % (mRank, int(round(100.0 * float(i) / len(local_synset_tars))))
                sys.stdout.flush()
            local_train_jpeg_files += [st.extractfile(m) for m in st.getmembers()]
            st.close()
        
        #mComm.barrier()

        #if mRank == 0:
        #    train_jpeg_files = [item for sublist in train_jpeg_files for item in sublist]
        shuffle(local_train_jpeg_files)
        local_train_labels = [[labels_dic[jpeg.name[:9]]] for jpeg in local_train_jpeg_files]
        print "done (%.2f sec) on node %d" % (time() - t, mRank)

        print "Total JPEG files found on node %d: %d; sample label: %s" % (mRank, len(local_train_jpeg_files), local_train_labels[0])
    
        #mComm.barrier()

        # Write training batches
        #if mRank == 0:
        #    scatterable_train_labels = split_seq(train_labels, mSize)
        #    scatterable_train_jpeg_files = split_seq(train_jpeg_files, mSize)
        #else:
        #    scatterable_train_labels = None
        #    scatterable_train_jpeg_files = None
#        train_labels = mComm.scatter(scatterable_train_labels, root=0)
#        train_jpeg_files = mComm.scatter(scatterable_train_jpeg_files, root=0)
        #mComm.barrier()
        i = write_batches(args.tgt_dir, 'training', 0, local_train_labels, local_train_jpeg_files)
    mComm.barrier()
    if mRank == 0:
        END_TIME = time()
        print "Overall time is: %.2f" % (END_TIME - START_TIME)
        sys.exit(1)
    
    # Write validation batches. Doesn't take long, so just do it on master
    mComm.barrier()
    train_jpeg_files = mComm.gather(local_train_jpeg_files)
    if mRank == 0:
        i = len(train_jpeg_files)
        val_batch_start = int(math.ceil((i / 1000.0))) * 1000
        with open_tar(ILSVRC_VALIDATION_TAR, 'validation tar') as tf:
            validation_jpeg_files = sorted([tf.extractfile(m) for m in tf.getmembers()], key=lambda x:x.name)
            write_batches(args.tgt_dir, 'validation', val_batch_start, validation_labels, validation_jpeg_files)
    
        # Write meta file
        meta = unpickle('input_meta')
        meta_file = os.path.join(args.tgt_dir, 'batches.meta')
        meta.update({'batch_size': OUTPUT_BATCH_SIZE,
                     'num_vis': OUTPUT_IMAGE_SIZE**2 * 3,
                     'label_names': label_names})
        pickle(meta_file, meta)
        print "Wrote %s" % meta_file
        print "All done! ILSVRC 2012 batches are in %s" % args.tgt_dir
        #END_TIME = time()
        #print "Overall time is: %.2f" % (END_TIME - START_TIME)

