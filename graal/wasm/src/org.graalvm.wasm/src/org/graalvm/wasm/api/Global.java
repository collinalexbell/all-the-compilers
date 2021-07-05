/*
 * Copyright (c) 2020, 2021, Oracle and/or its affiliates. All rights reserved.
 * DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS FILE HEADER.
 *
 * The Universal Permissive License (UPL), Version 1.0
 *
 * Subject to the condition set forth below, permission is hereby granted to any
 * person obtaining a copy of this software, associated documentation and/or
 * data (collectively the "Software"), free of charge and under any and all
 * copyright rights in the Software, and any and all patent rights owned or
 * freely licensable by each licensor hereunder covering either (i) the
 * unmodified Software as contributed to or provided by such licensor, or (ii)
 * the Larger Works (as defined below), to deal in both
 *
 * (a) the Software, and
 *
 * (b) any piece of software and/or hardware listed in the lrgrwrks.txt file if
 * one is included with the Software each a "Larger Work" to which the Software
 * is contributed by such licensors),
 *
 * without restriction, including without limitation the rights to copy, create
 * derivative works of, display, perform, and distribute the Software and make,
 * use, sell, offer for sale, import, export, have made, and have sold the
 * Software and the Larger Work(s), and to sublicense the foregoing rights on
 * either these or other terms.
 *
 * This license is subject to the following condition:
 *
 * The above copyright notice and either this complete permission notice or at a
 * minimum a reference to the UPL must be included in all copies or substantial
 * portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */
package org.graalvm.wasm.api;

import com.oracle.truffle.api.interop.InteropLibrary;
import com.oracle.truffle.api.interop.UnknownIdentifierException;
import com.oracle.truffle.api.library.ExportLibrary;
import com.oracle.truffle.api.library.ExportMessage;
import org.graalvm.wasm.exception.WasmJsApiException;

@ExportLibrary(InteropLibrary.class)
public class Global extends Dictionary {
    private final ValueType valueType;
    private final boolean mutable;
    private Object value;

    public Global(String valueType, boolean mutable, Object value) {
        this.valueType = ValueType.valueOf(valueType);
        this.mutable = mutable;
        setInternal(value);
        addMembers(new Object[]{
                        "descriptor", new GlobalDescriptor(valueType, mutable),
                        "valueOf", new Executable(args -> get())
        });
    }

    public Object get() {
        return value;
    }

    public ValueType valueType() {
        return valueType;
    }

    public boolean mutable() {
        return mutable;
    }

    public void set(Object value) {
        if (!mutable) {
            throw WasmJsApiException.format(WasmJsApiException.Kind.TypeError, "Global is not mutable.");
        }
        setInternal(value);
    }

    private void setInternal(Object value) {
        switch (valueType) {
            case i32:
                if (!(value instanceof Integer)) {
                    throw WasmJsApiException.format(WasmJsApiException.Kind.TypeError, "Global type %s, value: %s", valueType, value);
                }
                this.value = value;
                break;
            case i64:
                if (!(value instanceof Long)) {
                    throw WasmJsApiException.format(WasmJsApiException.Kind.TypeError, "Global type %s, value: %s", valueType, value);
                }
                this.value = value;
                break;
            case f32:
                if (!(value instanceof Float)) {
                    throw WasmJsApiException.format(WasmJsApiException.Kind.TypeError, "Global type %s, value: %s", valueType, value);
                }
                this.value = value;
                break;
            case f64:
                if (!(value instanceof Double)) {
                    throw WasmJsApiException.format(WasmJsApiException.Kind.TypeError, "Global type %s, value: %s", valueType, value);
                }
                this.value = value;
                break;
        }
    }

    @ExportMessage
    @Override
    public boolean isMemberReadable(String member) {
        return "value".equals(member) || super.isMemberReadable(member);
    }

    @ExportMessage
    public boolean isMemberModifiable(String member) {
        return "value".equals(member);
    }

    @SuppressWarnings({"unused"})
    @ExportMessage
    public boolean isMemberInsertable(String member) {
        return false;
    }

    @ExportMessage
    @Override
    public Object readMember(String member) throws UnknownIdentifierException {
        if ("value".equals(member)) {
            return get();
        } else {
            return super.readMember(member);
        }
    }

    @ExportMessage
    public void writeMember(String member, Object newValue) throws UnknownIdentifierException {
        if ("value".equals(member)) {
            set(newValue);
        } else {
            throw unknown(member);
        }
    }

}
