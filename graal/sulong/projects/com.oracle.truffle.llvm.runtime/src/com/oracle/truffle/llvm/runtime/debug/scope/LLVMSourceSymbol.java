/*
 * Copyright (c) 2017, 2020, Oracle and/or its affiliates.
 *
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification, are
 * permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice, this list of
 * conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice, this list of
 * conditions and the following disclaimer in the documentation and/or other materials provided
 * with the distribution.
 *
 * 3. Neither the name of the copyright holder nor the names of its contributors may be used to
 * endorse or promote products derived from this software without specific prior written
 * permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS
 * OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
 * COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
 * GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED
 * AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 * NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */
package com.oracle.truffle.llvm.runtime.debug.scope;

import java.util.Objects;

import com.oracle.truffle.api.CompilerDirectives.TruffleBoundary;
import com.oracle.truffle.llvm.runtime.debug.type.LLVMSourceType;

public abstract class LLVMSourceSymbol {

    public static LLVMSourceSymbol create(String name, LLVMSourceLocation location, LLVMSourceType type, boolean isStatic) {
        if (isStatic) {
            return new Static(name, location, type);
        } else {
            return new Dynamic(name, location, type);
        }
    }

    private final String name;
    private final LLVMSourceLocation location;
    private final LLVMSourceType type;

    private LLVMSourceSymbol(String name, LLVMSourceLocation location, LLVMSourceType type) {
        this.name = name;
        this.location = location;
        this.type = type;
    }

    public String getName() {
        return name;
    }

    public LLVMSourceLocation getLocation() {
        return location;
    }

    public LLVMSourceType getType() {
        return type;
    }

    public abstract boolean isStatic();

    @Override
    public String toString() {
        return name;
    }

    @Override
    @TruffleBoundary
    public boolean equals(Object o) {
        if (this == o) {
            return true;
        }

        if (o == null || getClass() != o.getClass()) {
            return false;
        }

        final LLVMSourceSymbol symbol = (LLVMSourceSymbol) o;

        if (!name.equals(symbol.name)) {
            return false;
        }

        return Objects.equals(location, symbol.location);
    }

    @Override
    @TruffleBoundary
    public int hashCode() {
        return name.hashCode() ^ Objects.hashCode(location);
    }

    private static final class Static extends LLVMSourceSymbol {

        private Static(String name, LLVMSourceLocation location, LLVMSourceType type) {
            super(name, location, type);
        }

        @Override
        public boolean isStatic() {
            return true;
        }
    }

    private static final class Dynamic extends LLVMSourceSymbol {

        private Dynamic(String name, LLVMSourceLocation location, LLVMSourceType type) {
            super(name, location, type);
        }

        @Override
        public boolean isStatic() {
            return false;
        }
    }
}
