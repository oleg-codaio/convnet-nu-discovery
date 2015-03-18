#!/bin/sh
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
###############################################################################

set -e

# Fill in the below environment variables.
#
# If you're not sure what these paths should be, 
# you can use the find command to try to locate them.
# For example, NUMPY_INCLUDE_PATH contains the file
# arrayobject.h. So you can search for it like this:
# 
# find /usr -name arrayobject.h
# 
# (it'll almost certainly be under /usr)

# Make sure we've loaded the needed modules for the Discovery Cluster.
if module list 2>&1 | grep -q "No Modulefiles Currently Loaded"; then
    echo "Please run \"source load_modules.sh\" before running this script."
    exit 1
fi

# CUDA toolkit installation directory.
export CUDA_INSTALL_PATH=/shared/apps/cuda6.5

# Python include directory. This should contain the file Python.h, among others.
export PYTHON_INCLUDE_PATH=/shared/apps/python/Python-2.7.5/INSTALL/include/python2.7

# OpenCV include directory.
export OPENCV_INCLUDE_PATH=/shared/apps/opencv-3.0.0-beta/INSTALL/include

# pkg-config environment variable for OpenCV and Python config helpers.
export PKG_CONFIG_PATH=/shared/apps/opencv-3.0.0-beta/INSTALL/lib/pkgconfig:/shared/apps/python/Python-2.7.5/INSTALL/lib/pkgconfig:$PKG_CONFIG_PATH

# Numpy include directory. This should contain the file arrayobject.h, among others.
export NUMPY_INCLUDE_PATH=/shared/apps/python/Python-2.7.5/INSTALL/lib/python2.7/site-packages/numpy/core/include/numpy

# ATLAS library directory. This should contain the file libcblas.so, among others.
export ATLAS_LIB_PATH=/shared/apps/atlas-sse3/usr/lib64/atlas-sse3

# Make sure the compiler can find libjpeg-dev.
export LIB_JPEG_PATH="$(pwd)/jpeg-8"

# You don't have to change these:
export LD_LIBRARY_PATH=$CUDA_INSTALL_PATH/lib64:$LIB_JPEG_PATH:$LD_LIBRARY_PATH
export CUDA_SDK_PATH=$CUDA_INSTALL_PATH/samples
export PATH=$PATH:$CUDA_INSTALL_PATH/bin

cd jpeg-8 && ./configure && make clean && make -j $* && cd ..
cd util && make numpy=1 -j $* && cd ..
cd nvmatrix && make -j $* && cd ..
cd cudaconv3 && make -j $* && cd ..
cd cudaconvnet && make -j $* && cd ..
cd make-data/pyext && make -j $* && cd ../..

