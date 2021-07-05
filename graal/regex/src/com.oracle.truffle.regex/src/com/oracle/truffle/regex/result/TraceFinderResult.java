/*
 * Copyright (c) 2018, 2021, Oracle and/or its affiliates. All rights reserved.
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
package com.oracle.truffle.regex.result;

import java.util.Arrays;

import com.oracle.truffle.api.CallTarget;
import com.oracle.truffle.api.CompilerDirectives.CompilationFinal;
import com.oracle.truffle.api.CompilerDirectives.TruffleBoundary;
import com.oracle.truffle.api.interop.InteropLibrary;
import com.oracle.truffle.api.library.ExportLibrary;
import com.oracle.truffle.api.library.ExportMessage;

@ExportLibrary(InteropLibrary.class)
public final class TraceFinderResult extends LazyResult {

    private final int[] indices;
    private final CallTarget traceFinderCallTarget;
    @CompilationFinal(dimensions = 1) private final PreCalculatedResultFactory[] preCalculatedResults;
    private boolean resultCalculated = false;

    public TraceFinderResult(Object input, int fromIndex, int end, CallTarget traceFinderCallTarget, PreCalculatedResultFactory[] preCalculatedResults) {
        super(input, fromIndex, end);
        this.indices = new int[preCalculatedResults[0].getNumberOfGroups() * 2];
        this.traceFinderCallTarget = traceFinderCallTarget;
        this.preCalculatedResults = preCalculatedResults;
    }

    @Override
    public int getStart(int groupNumber) {
        return indices[groupNumber * 2];
    }

    @Override
    public int getEnd(int groupNumber) {
        return indices[groupNumber * 2 + 1];
    }

    public int[] getIndices() {
        return indices;
    }

    public CallTarget getTraceFinderCallTarget() {
        return traceFinderCallTarget;
    }

    public PreCalculatedResultFactory[] getPreCalculatedResults() {
        return preCalculatedResults;
    }

    public boolean isResultCalculated() {
        return resultCalculated;
    }

    public Object[] createArgsTraceFinder() {
        return new Object[]{getInput(), getFromIndex(), getEnd()};
    }

    public void applyTraceFinderResult(int preCalcIndex) {
        preCalculatedResults[preCalcIndex].applyRelativeToEnd(indices, getEnd());
        resultCalculated = true;
    }

    /**
     * Forces evaluation of this lazy regex result. Do not use this method on any fast paths, use
     * {@link com.oracle.truffle.regex.runtime.nodes.TraceFinderGetResultNode} instead!
     */
    @TruffleBoundary
    @Override
    public void debugForceEvaluation() {
        if (!isResultCalculated()) {
            applyTraceFinderResult((int) traceFinderCallTarget.call(createArgsTraceFinder()));
        }
    }

    @TruffleBoundary
    @Override
    public String toString() {
        if (!isResultCalculated()) {
            debugForceEvaluation();
        }
        return Arrays.toString(indices);
    }

    @TruffleBoundary
    @ExportMessage
    @Override
    public Object toDisplayString(boolean allowSideEffects) {
        if (allowSideEffects) {
            return "TRegexLazyResult" + toString();
        }
        return "TRegexLazyResult" + (indices == null ? "[not computed yet]" : Arrays.toString(indices));
    }
}
