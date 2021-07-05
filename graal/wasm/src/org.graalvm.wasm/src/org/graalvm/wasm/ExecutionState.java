/*
 * Copyright (c) 2019, 2020, Oracle and/or its affiliates. All rights reserved.
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
package org.graalvm.wasm;

import org.graalvm.wasm.collection.BooleanArrayList;
import org.graalvm.wasm.collection.ByteArrayList;
import org.graalvm.wasm.collection.IntArrayList;
import org.graalvm.wasm.exception.Failure;
import org.graalvm.wasm.exception.WasmException;
import org.graalvm.wasm.nodes.WasmBlockNode;

import java.util.ArrayList;

import static java.lang.Integer.compareUnsigned;

public class ExecutionState {
    private int profileCount;
    private final IntArrayList intConstants;
    private final ArrayList<int[]> branchTables;
    private final ByteArrayList stack;

    /**
     * Maximum number of values ever pushed on the stack during this execution.
     */
    private int maxStackSize;

    /**
     * Stack size at the beginning of each parent block.
     */
    private final IntArrayList ancestorsStackSizes;

    /**
     * Whereas each parent block is a loop body or not.
     */
    private final BooleanArrayList ancestorsIsLoop;

    /**
     * Current {@link WasmBlockNode}'s inclusive ancestors.
     */
    private final ArrayList<WasmBlockNode> ancestors;

    /**
     * Whereas the current point in code is reachable or not.
     */
    private boolean reachable;

    public ExecutionState() {
        this.stack = new ByteArrayList();
        this.maxStackSize = 0;
        this.profileCount = 0;
        this.intConstants = new IntArrayList();
        this.ancestorsStackSizes = new IntArrayList();
        this.ancestorsIsLoop = new BooleanArrayList();
        this.ancestors = new ArrayList<>();
        this.branchTables = new ArrayList<>();
        this.reachable = true;
    }

    public boolean isReachable() {
        return this.reachable;
    }

    public void setReachable(boolean reachable) {
        if (!reachable) {
            unwindStack(getStackSize(0));
        }
        this.reachable = reachable;
    }

    public void push(byte type) {
        stack.push(type);
        maxStackSize = Math.max(stack.size(), maxStackSize);
    }

    public byte pop() {
        final int blockStackSize = stack.size() - getStackSize(0);
        if (!isReachable() && blockStackSize == 0) {
            return -1;
        }
        Assert.assertIntGreater(blockStackSize, 0, "Cannot pop from the stack", Failure.TYPE_MISMATCH);
        return stack.popBack();
    }

    public void popChecked(byte expectedType) {
        assertTypesEqual(expectedType, pop());
    }

    private static void assertTypesEqual(byte expectedType, byte actualType) {
        if (expectedType != -1 && actualType != -1 && expectedType != actualType) {
            throw WasmException.format(Failure.TYPE_MISMATCH, "Expected type %s but got %s.", WasmType.toString(expectedType), WasmType.toString(actualType));
        }
    }

    public void unwindStack(int size) {
        assert compareUnsigned(size, stackSize()) <= 0 : "invalid stack shrink size";
        while (stackSize() > size) {
            stack.popBack();
        }
    }

    public void useIntConstant(int constant) {
        intConstants.add(constant);
    }

    public int depth() {
        return ancestors.size();
    }

    public int getStackSize(int offset) {
        Assert.assertUnsignedIntLess(offset, depth(), Failure.UNKNOWN_LABEL);
        return ancestorsStackSizes.get(depth() - 1 - offset);
    }

    public int getCurrentBlockStackSize() {
        return stackSize() - getStackSize(0);
    }

    public void startBlock(WasmBlockNode block, boolean isLoopBody) {
        ancestors.add(block);
        ancestorsIsLoop.add(isLoopBody);
        ancestorsStackSizes.add(stackSize());
    }

    public void endBlock() {
        final WasmBlockNode currentBlock = ancestors.get(ancestors.size() - 1);
        if (currentBlock.returnLength() == 1) {
            popChecked(currentBlock.returnTypeId());
        }
        Assert.assertIntEqual(getCurrentBlockStackSize(), 0, Failure.TYPE_MISMATCH);
        if (currentBlock.returnLength() == 1) {
            push(currentBlock.returnTypeId());
        }

        ancestorsStackSizes.popBack();
        ancestorsIsLoop.popBack();
        ancestors.remove(ancestors.size() - 1);
    }

    /**
     * The continuation length is the number of values that should be on the stack when breaking
     * from a break (BR, BR_IF or BR_TABLE) instruction to this block.
     * <p>
     * Given a block with type t1 -> t2, this is t2 ({@link WasmBlockNode#returnLength}) if block is
     * a normal block or the body of a condition, or t1 ({@link WasmBlockNode#inputLength()}) if it
     * is the body of a loop.
     */
    public int getContinuationLength(int unwindLevel) {
        final int index = depth() - 1 - unwindLevel;
        final boolean isLoop = ancestorsIsLoop.get(index);
        final WasmBlockNode block = ancestors.get(index);
        return isLoop ? block.inputLength() : block.returnLength();
    }

    public void checkContinuationType(int unwindLevel) {
        final int index = depth() - 1 - unwindLevel;
        final boolean isLoop = ancestorsIsLoop.get(index);
        final WasmBlockNode block = ancestors.get(index);
        if (!isLoop && block.returnLength() == 1) {
            popChecked(block.returnTypeId());
            push(block.returnTypeId());
        }
    }

    public int getRootBlockReturnLength() {
        return ancestors.get(0).returnLength();
    }

    public int stackSize() {
        return stack.size();
    }

    public int maxStackSize() {
        return maxStackSize;
    }

    public int intConstantOffset() {
        return intConstants.size();
    }

    public int[] intConstants() {
        return intConstants.toArray();
    }

    public void saveBranchTable(int[] branchTable) {
        branchTables.add(branchTable);
    }

    public int[] branchTable(int index) {
        return branchTables.get(index);
    }

    public int branchTableOffset() {
        return branchTables.size();
    }

    public int[][] branchTables() {
        return branchTables.toArray(new int[0][]);
    }

    public void incrementProfileCount() {
        ++profileCount;
    }

    public int profileCount() {
        return profileCount;
    }
}
