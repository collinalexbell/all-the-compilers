/*
 * Copyright (c) 2020, 2020, Oracle and/or its affiliates. All rights reserved.
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
package com.oracle.svm.core.genscavenge;

import java.nio.ByteBuffer;
import java.util.List;

import org.graalvm.compiler.core.common.NumUtil;

import com.oracle.svm.core.SubstrateUtil;
import com.oracle.svm.core.genscavenge.ChunkedImageHeapAllocator.AlignedChunk;
import com.oracle.svm.core.genscavenge.ChunkedImageHeapAllocator.Chunk;
import com.oracle.svm.core.genscavenge.ChunkedImageHeapAllocator.UnalignedChunk;
import com.oracle.svm.core.image.ImageHeap;
import com.oracle.svm.core.image.ImageHeapLayoutInfo;

public class ChunkedImageHeapLayouter extends AbstractImageHeapLayouter<ChunkedImageHeapPartition> {
    private final ImageHeapInfo heapInfo;
    private final long startOffset;
    private final boolean compressedNullPadding;
    private final long hugeObjectThreshold;
    private ChunkedImageHeapAllocator allocator;

    public ChunkedImageHeapLayouter(ImageHeapInfo heapInfo, long startOffset, boolean compressedNullPadding) {
        this.heapInfo = heapInfo;
        this.startOffset = startOffset;
        this.compressedNullPadding = compressedNullPadding;
        this.hugeObjectThreshold = HeapPolicy.getLargeArrayThreshold().rawValue();
    }

    @Override
    protected ChunkedImageHeapPartition[] createPartitionsArray(int count) {
        return new ChunkedImageHeapPartition[count];
    }

    @Override
    protected ChunkedImageHeapPartition createPartition(String name, boolean containsReferences, boolean writable, boolean hugeObjects) {
        return new ChunkedImageHeapPartition(name, writable, hugeObjects);
    }

    @Override
    protected long getHugeObjectThreshold() {
        return hugeObjectThreshold;
    }

    @Override
    protected ImageHeapLayoutInfo doLayout(ImageHeap imageHeap) {
        assert !compressedNullPadding || AlignedHeapChunk.getObjectsStartOffset().aboveThan(0) : "Expecting header to pad start so object offsets are strictly greater than 0";
        allocator = new ChunkedImageHeapAllocator(imageHeap, startOffset);
        for (ChunkedImageHeapPartition partition : getPartitions()) {
            partition.layout(allocator);
        }
        return populateInfoObjects(imageHeap.countDynamicHubs());
    }

    private ImageHeapLayoutInfo populateInfoObjects(int dynamicHubCount) {
        // Determine writable start boundary from chunks: a chunk that contains writable objects
        // must also have a writable card table
        long writableBegin = getWritablePrimitive().getStartOffset();
        for (AlignedChunk chunk : allocator.getAlignedChunks()) {
            if (chunk.isWritable() && chunk.getBegin() < writableBegin) {
                assert writableBegin <= chunk.getEnd();
                writableBegin = chunk.getBegin();
                break; // (chunks are in ascending memory order)
            }
        }
        long firstWritableUnalignedChunk = -1;
        for (UnalignedChunk chunk : allocator.getUnalignedChunks()) {
            if (chunk.isWritable()) {
                firstWritableUnalignedChunk = chunk.getBegin();
            }
            break;
        }

        heapInfo.initialize(getReadOnlyPrimitive().firstObject, getReadOnlyPrimitive().lastObject, getReadOnlyReference().firstObject, getReadOnlyReference().lastObject,
                        getReadOnlyRelocatable().firstObject, getReadOnlyRelocatable().lastObject, getWritablePrimitive().firstObject, getWritablePrimitive().lastObject,
                        getWritableReference().firstObject, getWritableReference().lastObject, getWritableHuge().firstObject, getWritableHuge().lastObject,
                        getReadOnlyHuge().firstObject, getReadOnlyHuge().lastObject, writableBegin, firstWritableUnalignedChunk, dynamicHubCount);

        return createLayoutInfo(startOffset, writableBegin);
    }

    @Override
    public void writeMetadata(ByteBuffer imageHeapBytes, long imageHeapOffsetInBuffer) {
        long layoutToBufferOffsetAddend = imageHeapOffsetInBuffer - startOffset;
        ImageHeapChunkWriter writer = SubstrateUtil.HOSTED ? new HostedImageHeapChunkWriter(imageHeapBytes, layoutToBufferOffsetAddend)
                        : new RuntimeImageHeapChunkWriter(imageHeapBytes, layoutToBufferOffsetAddend);
        writeHeaders(writer, allocator.getAlignedChunks());
        writeHeaders(writer, allocator.getUnalignedChunks());
    }

    private static void writeHeaders(ImageHeapChunkWriter writer, List<? extends Chunk> chunks) {
        Chunk previous = null;
        Chunk current = null;
        for (Chunk next : chunks) {
            writeHeader(writer, previous, current, next);
            previous = current;
            current = next;
        }
        writeHeader(writer, previous, current, null);
    }

    private static void writeHeader(ImageHeapChunkWriter writer, Chunk previous, Chunk current, Chunk next) {
        if (current != null) {
            long offsetToPrevious = (previous != null) ? (previous.getBegin() - current.getBegin()) : 0;
            long offsetToNext = (next != null) ? (next.getBegin() - current.getBegin()) : 0;
            int chunkPosition = NumUtil.safeToInt(current.getBegin());
            if (current instanceof AlignedChunk) {
                AlignedChunk aligned = (AlignedChunk) current;
                writer.initializeAlignedChunk(chunkPosition, current.getTopOffset(), current.getEndOffset(), offsetToPrevious, offsetToNext);
                writer.enableRememberedSetForAlignedChunk(chunkPosition, aligned.getObjects());
            } else {
                assert current instanceof UnalignedChunk;
                writer.initializeUnalignedChunk(chunkPosition, current.getTopOffset(), current.getEndOffset(), offsetToPrevious, offsetToNext);
                writer.enableRememberedSetForUnalignedChunk(chunkPosition);
            }
        }
    }
}
