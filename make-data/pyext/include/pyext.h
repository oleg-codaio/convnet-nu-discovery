/*
 * Copyright 2014 Google Inc. All rights reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#ifndef INCLUDE_PYEXT_H_
#define INCLUDE_PYEXT_H_

#include <stdio.h>
//#include <jpeglib.h>
#include <opencv2/cudawarping.hpp>
#include <opencv2/opencv.hpp>
#include <opencv2/imgcodecs/imgcodecs_c.h>
#include <Python.h>

#define JPEG_QUALITY      95

#ifndef DIVUP
#define DIVUP(a,b) (((a) + (b) - 1) / (b))
#endif

extern "C" {
    void init_MakeDataPyExt();
}
PyObject* resizeJPEG(PyObject *self, PyObject *args);

#endif  // INCLUDE_PYEXT_H_

