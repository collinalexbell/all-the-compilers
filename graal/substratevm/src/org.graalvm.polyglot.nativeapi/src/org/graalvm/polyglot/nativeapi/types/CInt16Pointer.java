/*
 * Copyright (c) 2018, 2018, Oracle and/or its affiliates. All rights reserved.
 * DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS FILE HEADER.
 *
 * This code is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License version 2 only, as
 * published by the Free Software Foundation.  Oracle designates this
 * particular file as subject to the "Classpath" exception as provided
 * by Oracle in the LICENSE file that accompanied this code.
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
package org.graalvm.polyglot.nativeapi.types;

import org.graalvm.nativeimage.c.struct.CPointerTo;
import org.graalvm.word.PointerBase;
import org.graalvm.word.SignedWord;

/**
 * A pointer to a 16-bit C primitive value.
 *
 * @since 19.0
 */
@CPointerTo(nameOfCType = "int16_t")
public interface CInt16Pointer extends PointerBase {

    /**
     * Reads the value at the pointer address.
     *
     * @since 19.0
     */
    short read();

    /**
     * Reads the value of the array element with the specified index, treating the pointer as an
     * array of the C type.
     *
     * @since 19.0
     */
    short read(int index);

    /**
     * Reads the value of the array element with the specified index, treating the pointer as an
     * array of the C type.
     *
     * @since 19.0
     */
    short read(SignedWord index);

    /**
     * Writes the value at the pointer address.
     *
     * @since 19.0
     */
    void write(short value);

    /**
     * Writes the value of the array element with the specified index, treating the pointer as an
     * array of the C type.
     *
     * @since 19.0
     */
    void write(int index, short value);

    /**
     * Writes the value of the array element with the specified index, treating the pointer as an
     * array of the C type.
     *
     * @since 19.0
     */
    void write(SignedWord index, short value);

    /**
     * Computes the address of the array element with the specified index, treating the pointer as
     * an array of the C type.
     *
     * @since 19.0
     */
    CInt16Pointer addressOf(int index);

    /**
     * Computes the address of the array element with the specified index, treating the pointer as
     * an array of the C type.
     *
     * @since 19.0
     */
    CInt16Pointer addressOf(SignedWord index);
}
