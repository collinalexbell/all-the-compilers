/*
 * Copyright (c) 2019, 2020, Oracle and/or its affiliates. All rights reserved.
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
package com.oracle.svm.graal.isolated;

import java.io.ByteArrayOutputStream;
import java.io.DataOutputStream;
import java.io.IOException;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.Arrays;

import com.oracle.svm.core.graal.meta.SharedRuntimeMethod;

import jdk.vm.ci.common.JVMCIError;
import jdk.vm.ci.meta.ResolvedJavaMethod;
import jdk.vm.ci.meta.ResolvedJavaType;

/** Adapted from {@code jdk.vm.ci.hotspot.HotSpotSpeculationEncoding}. */
final class IsolatedSpeculationReasonEncoding extends ByteArrayOutputStream implements SpeculationReasonEncodingClone {

    private DataOutputStream dos = new DataOutputStream(this);
    private byte[] result;

    IsolatedSpeculationReasonEncoding() {
        super(SHA1_LENGTH);
    }

    private void checkOpen() {
        if (result != null) {
            throw new IllegalArgumentException("Cannot update closed speculation encoding");
        }
    }

    private static final int NULL_METHOD = -1;
    private static final int NULL_TYPE = -2;
    private static final int NULL_STRING = -3;

    @Override
    public void addByte(int value) {
        checkOpen();
        try {
            dos.writeByte(value);
        } catch (IOException e) {
            throw new InternalError(e);
        }
    }

    @Override
    public void addShort(int value) {
        checkOpen();
        try {
            dos.writeShort(value);
        } catch (IOException e) {
            throw new InternalError(e);
        }
    }

    @Override
    public void addMethod(ResolvedJavaMethod method) {
        ResolvedJavaMethod original = method;
        if (method instanceof SharedRuntimeMethod) {
            original = ((SharedRuntimeMethod) method).getOriginal();
        }
        addImageHeapObject(original, NULL_METHOD);
    }

    @Override
    public void addType(ResolvedJavaType type) {
        addImageHeapObject(type, NULL_TYPE);
    }

    private void addImageHeapObject(Object object, int nullValue) {
        if (!addNull(object, nullValue)) {
            checkOpen();
            try {
                dos.writeLong(ImageHeapObjects.ref(object).rawValue());
            } catch (IOException e) {
                throw new InternalError(e);
            }
        }
    }

    @Override
    public void addString(String value) {
        if (!addNull(value, NULL_STRING)) {
            checkOpen();
            try {
                dos.writeChars(value);
            } catch (IOException e) {
                throw new InternalError(e);
            }
        }
    }

    @Override
    public void addInt(int value) {
        checkOpen();
        try {
            dos.writeInt(value);
        } catch (IOException e) {
            throw new InternalError(e);
        }
    }

    @Override
    public void addLong(long value) {
        checkOpen();
        try {
            dos.writeLong(value);
        } catch (IOException e) {
            throw new InternalError(e);
        }
    }

    private boolean addNull(Object o, int nullValue) {
        if (o == null) {
            addInt(nullValue);
            return true;
        }
        return false;
    }

    /**
     * Prototype SHA1 digest that is cloned before use.
     */
    private static final MessageDigest SHA1 = getSHA1();
    private static final int SHA1_LENGTH = SHA1.getDigestLength();

    private static MessageDigest getSHA1() {
        try {
            MessageDigest sha1 = MessageDigest.getInstance("SHA-1");
            sha1.clone();
            return sha1;
        } catch (CloneNotSupportedException | NoSuchAlgorithmException e) {
            // Should never happen given that SHA-1 is mandated in a
            // compliant Java platform implementation.
            throw new JVMCIError("Expect a cloneable implementation of a SHA-1 message digest to be available", e);
        }
    }

    /**
     * Gets the final encoded byte array and closes this encoding such that any further attempts to
     * update it result in an {@link IllegalArgumentException}.
     */
    byte[] getByteArray() {
        if (result == null) {
            if (count > SHA1_LENGTH) {
                try {
                    MessageDigest md = (MessageDigest) SHA1.clone();
                    md.update(buf, 0, count);
                    result = md.digest();
                } catch (CloneNotSupportedException e) {
                    throw new InternalError(e);
                }
            } else {
                if (buf.length == count) {
                    // No need to copy the byte array
                    return buf;
                }
                result = Arrays.copyOf(buf, count);
            }
            dos = null;
        }
        return result;
    }
}
