/*
 * Copyright (c) 2020, 2020, Oracle and/or its affiliates. All rights reserved.
 * DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS FILE HEADER.
 *
 * This code is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License version 2 only, as
 * published by the Free Software Foundation.
 *
 * This code is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
 * version 2 for more details (a copy is included in the LICENSE file that
 * accompanied this code).
 *
 * You should have received a copy of the GNU General Public License version
 * 2 along with this work; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA.
 *
 * Please contact Oracle, 500 Oracle Parkway, Redwood Shores, CA 94065 USA
 * or visit www.oracle.com if you need additional information or have any
 * questions.
 */
#ifndef _NESPRESSO_H
#define _NESPRESSO_H

#include <jni.h>
#include <trufflenfi.h>

JNIEXPORT void* JNICALL dupClosureRef(TruffleEnv *truffle_env, void* closure);

JNIEXPORT JNIEnv* JNICALL initializeNativeContext(TruffleEnv *truffle_env, void* (*fetch_by_name)(const char *));

JNIEXPORT void JNICALL disposeNativeContext(TruffleEnv* truffle_env, JNIEnv* env);

// varargs support
JNIEXPORT jboolean JNICALL pop_boolean(struct Varargs* varargs);
JNIEXPORT jbyte JNICALL pop_byte(struct Varargs* varargs);
JNIEXPORT jchar JNICALL pop_char(struct Varargs* varargs);
JNIEXPORT jshort JNICALL pop_short(struct Varargs* varargs);
JNIEXPORT jint JNICALL pop_int(struct Varargs* varargs);
JNIEXPORT jfloat JNICALL pop_float(struct Varargs* varargs);
JNIEXPORT jdouble JNICALL pop_double(struct Varargs* varargs);
JNIEXPORT jlong JNICALL pop_long(struct Varargs* varargs);
JNIEXPORT jobject JNICALL pop_object(struct Varargs* varargs);
JNIEXPORT void* JNICALL pop_word(struct Varargs* varargs);

JNIEXPORT void * JNICALL allocateMemory(size_t size);
JNIEXPORT void JNICALL freeMemory(void *ptr);
JNIEXPORT void * JNICALL reallocateMemory(void *ptr, size_t new_size);
JNIEXPORT void JNICALL ctypeInit(void);
JNIEXPORT jlong JNICALL get_SIZE_MAX();

#endif // _NESPRESSO_H


