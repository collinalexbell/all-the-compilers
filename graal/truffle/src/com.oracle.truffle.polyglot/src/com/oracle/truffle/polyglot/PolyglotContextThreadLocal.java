/*
 * Copyright (c) 2017, 2020, Oracle and/or its affiliates. All rights reserved.
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
package com.oracle.truffle.polyglot;

import com.oracle.truffle.api.Assumption;
import com.oracle.truffle.api.CompilerDirectives;
import com.oracle.truffle.api.CompilerDirectives.CompilationFinal;
import com.oracle.truffle.api.CompilerDirectives.TruffleBoundary;
import com.oracle.truffle.api.Truffle;

final class PolyglotContextThreadLocal extends ThreadLocal<Object> {

    private final Assumption singleThread = Truffle.getRuntime().createAssumption("single thread");
    private volatile PolyglotContextImpl activeSingleContext;
    private PolyglotContextImpl activeSingleContextNonVolatile;
    @CompilationFinal private volatile Thread activeSingleThreadCompilationFinal;
    private volatile Thread activeSingleThread;
    @CompilationFinal private volatile boolean compilationFinalThread = true;

    @Override
    protected Object initialValue() {
        if (Thread.currentThread() == getSingleThread()) {
            // must only happen once
            Object context = activeSingleContext;
            activeSingleContext = null;
            activeSingleThreadCompilationFinal = null;
            activeSingleThread = null;
            activeSingleContextNonVolatile = null;
            return context;
        }
        return null;
    }

    /**
     * Enabled when any engine was configured for storing for the first time.
     */
    public void enableStore() {
        if (singleThread.isValid() && compilationFinalThread) {
            Thread t = getSingleThread();
            /*
             * We cannot embed the thread as a constant if we plant to write the engine to disk.
             *
             * Since we enable store before we run or compile any code we can switch this using a
             * boolean instead of an assumption. This avoids deoptimizing unnecessarily if other
             * contexts were used in the same VM.
             */
            compilationFinalThread = false;
            setSingleThread(t);
        }
    }

    private void setSingleThread(Thread t) {
        if (compilationFinalThread) {
            activeSingleThreadCompilationFinal = t;
        } else {
            activeSingleThread = t;
        }
    }

    private Thread getSingleThread() {
        if (compilationFinalThread) {
            return activeSingleThreadCompilationFinal;
        } else {
            return activeSingleThread;
        }
    }

    public boolean isSet() {
        if (singleThread.isValid()) {
            boolean set = activeSingleContext != null;
            return Thread.currentThread() == getSingleThread() && set;
        } else {
            return getTL() != null;
        }
    }

    /**
     * If we are entered and there is a single thread we can globally ignore the thread check. We
     * can also read from a non volatile field in order to allow moving of context reads.
     */
    public Object getEntered() {
        if (singleThread.isValid()) {
            assert Thread.currentThread() == getSingleThread() : failIllegalState();
            return activeSingleContextNonVolatile;
        } else {
            return getTL();
        }
    }

    private static String failIllegalState() {
        throw new IllegalStateException("No context entered.");
    }

    @Override
    public Object get() {
        Object context;
        if (singleThread.isValid()) {
            if (Thread.currentThread() == getSingleThread()) {
                context = activeSingleContext;
            } else {
                CompilerDirectives.transferToInterpreter();
                context = getImplSlowPath();
            }
        } else {
            context = getTL();
        }
        return context;
    }

    @Override
    public void set(Object value) {
        setReturnParent((PolyglotContextImpl) value);
    }

    PolyglotContextImpl setReturnParent(PolyglotContextImpl value) {
        if (singleThread.isValid()) {
            PolyglotContextImpl prev;
            if (Thread.currentThread() == getSingleThread()) {
                prev = this.activeSingleContext;
                this.activeSingleContext = value;
                this.activeSingleContextNonVolatile = value;
            } else {
                CompilerDirectives.transferToInterpreter();
                prev = setReturnParentSlowPath(value);
            }
            return prev;
        } else {
            return setTLReturnParent(value);
        }
    }

    private synchronized Object getImplSlowPath() {
        if (!singleThread.isValid()) {
            return getTL();
        }
        return null;
    }

    @TruffleBoundary
    private Object getTL() {
        Thread current = Thread.currentThread();
        if (current instanceof PolyglotThread) {
            PolyglotThread polyglotThread = ((PolyglotThread) current);
            Object context = polyglotThread.context;
            if (context == null && getSingleThread() == current) {
                context = polyglotThread.context = activeSingleContext;
                activeSingleContext = null;
                activeSingleContextNonVolatile = null;
                activeSingleThreadCompilationFinal = null;
                activeSingleThread = null;
            }
            return context;
        } else {
            return super.get();
        }
    }

    @TruffleBoundary
    private PolyglotContextImpl setTLReturnParent(PolyglotContextImpl context) {
        Thread current = Thread.currentThread();
        if (current instanceof PolyglotThread) {
            PolyglotThread polyglotThread = ((PolyglotThread) current);
            PolyglotContextImpl prev = polyglotThread.context;
            polyglotThread.context = context;
            return prev;
        } else {
            Object prev = super.get();
            super.set(context);
            return (PolyglotContextImpl) prev;
        }
    }

    private synchronized PolyglotContextImpl setReturnParentSlowPath(PolyglotContextImpl context) {
        if (!singleThread.isValid()) {
            return setTLReturnParent(context);
        }
        Thread currentThread = Thread.currentThread();
        Thread storeThread = getSingleThread();
        PolyglotContextImpl prev = this.activeSingleContext;
        if (currentThread == storeThread) {
            this.activeSingleContext = context;
            this.activeSingleContextNonVolatile = context;
        } else {
            if (storeThread == null) {
                setSingleThread(currentThread);
                this.activeSingleContext = context;
                this.activeSingleContextNonVolatile = context;
            } else {
                this.singleThread.invalidate();
                return setTLReturnParent(context);
            }
        }
        return prev;
    }

    @Override
    public void remove() {
        throw new UnsupportedOperationException();
    }

}
