/*
 * Copyright (c) 2013, 2017, Oracle and/or its affiliates. All rights reserved.
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

import org.graalvm.compiler.api.replacements.Fold;
import org.graalvm.compiler.word.Word;
import org.graalvm.nativeimage.Platform;
import org.graalvm.nativeimage.Platforms;
import org.graalvm.word.UnsignedWord;
import org.graalvm.word.WordFactory;

import com.oracle.svm.core.SubstrateGCOptions;
import com.oracle.svm.core.SubstrateUtil;
import com.oracle.svm.core.annotate.Uninterruptible;
import com.oracle.svm.core.config.ConfigurationValues;
import com.oracle.svm.core.heap.GCCause;
import com.oracle.svm.core.heap.PhysicalMemory;
import com.oracle.svm.core.heap.ReferenceAccess;
import com.oracle.svm.core.jdk.UninterruptibleUtils;
import com.oracle.svm.core.log.Log;
import com.oracle.svm.core.option.XOptions;
import com.oracle.svm.core.thread.VMOperation;
import com.oracle.svm.core.util.UnsignedUtils;
import com.oracle.svm.core.util.UserError;
import com.oracle.svm.core.util.VMError;

/** HeapPolicy contains policies for the parameters and behaviors of the heap and collector. */
public final class HeapPolicy {
    private static final OutOfMemoryError OUT_OF_MEMORY_ERROR = new OutOfMemoryError("Garbage-collected heap size exceeded.");

    static final long LARGE_ARRAY_THRESHOLD_SENTINEL_VALUE = 0;
    static final int ALIGNED_HEAP_CHUNK_FRACTION_FOR_LARGE_ARRAY_THRESHOLD = 8;

    @Platforms(Platform.HOSTED_ONLY.class)
    HeapPolicy() {
        if (!SubstrateUtil.isPowerOf2(getAlignedHeapChunkSize().rawValue())) {
            throw UserError.abort("AlignedHeapChunkSize (%d) should be a power of 2.", getAlignedHeapChunkSize().rawValue());
        }
        if (!getLargeArrayThreshold().belowOrEqual(getAlignedHeapChunkSize())) {
            throw UserError.abort("LargeArrayThreshold (%d) should be below or equal to AlignedHeapChunkSize (%d).",
                            getLargeArrayThreshold().rawValue(), getAlignedHeapChunkSize().rawValue());
        }
    }

    @Uninterruptible(reason = "Called from uninterruptible code.", mayBeInlined = true)
    public static Word getProducedHeapChunkZapWord() {
        return (Word) producedHeapChunkZapWord;
    }

    @Uninterruptible(reason = "Called from uninterruptible code.", mayBeInlined = true)
    public static int getProducedHeapChunkZapInt() {
        return (int) producedHeapChunkZapInt.rawValue();
    }

    @Uninterruptible(reason = "Called from uninterruptible code.", mayBeInlined = true)
    public static Word getConsumedHeapChunkZapWord() {
        return (Word) consumedHeapChunkZapWord;
    }

    @Uninterruptible(reason = "Called from uninterruptible code.", mayBeInlined = true)
    public static int getConsumedHeapChunkZapInt() {
        return (int) consumedHeapChunkZapInt.rawValue();
    }

    public static UnsignedWord m(long bytes) {
        assert 0 <= bytes;
        return WordFactory.unsigned(bytes).multiply(1024).multiply(1024);
    }

    @Uninterruptible(reason = "Called from uninterruptible code.", mayBeInlined = true)
    public static int getMaxSurvivorSpaces() {
        return HeapPolicyOptions.MaxSurvivorSpaces.getValue();
    }

    /*
     * Memory configuration
     */

    private static UnsignedWord maximumYoungGenerationSize;
    private static UnsignedWord minimumHeapSize;
    private static UnsignedWord maximumHeapSize;

    public static UnsignedWord getMaximumYoungGenerationSize() {
        Log trace = Log.noopLog().string("[HeapPolicy.getMaximumYoungGenerationSize:");
        if (maximumYoungGenerationSize.aboveThan(WordFactory.zero())) {
            trace.string("  returns maximumYoungGenerationSize: ").unsigned(maximumYoungGenerationSize).string(" ]").newline();
            return maximumYoungGenerationSize;
        }
        XOptions.XFlag xmn = XOptions.getXmn();
        if (xmn.getEpoch() > 0) {
            trace.string("  -Xmn.epoch: ").unsigned(xmn.getEpoch()).string("  -Xmn.value: ").unsigned(xmn.getValue());
            setMaximumYoungGenerationSize(WordFactory.unsigned(xmn.getValue()));
            trace.string("  returns: ").unsigned(maximumYoungGenerationSize)
                            .string(" ]").newline();
            return maximumYoungGenerationSize;
        }
        long hostedValue = SubstrateGCOptions.MaxNewSize.getHostedValue();
        if (hostedValue != 0) {
            trace.string("  returns maximumYoungGenerationSize: ").unsigned(hostedValue).string(" ]").newline();
            return WordFactory.unsigned(hostedValue);
        }

        /* If none of those is set, use fraction of the maximum heap size. */
        UnsignedWord maxHeapSize = getMaximumHeapSize();
        UnsignedWord youngSizeAsFraction = maxHeapSize.unsignedDivide(100).multiply(getMaximumYoungGenerationSizePercent());
        /* But not more than 256MB. */
        UnsignedWord maxSize = m(256);
        UnsignedWord youngSize = (youngSizeAsFraction.belowOrEqual(maxSize) ? youngSizeAsFraction : maxSize);
        trace.string("  youngSize: ").unsigned(youngSize)
                        .string(" ]").newline();
        /* But do not cache the result as it is based on values that might change. */
        return youngSize;
    }

    private static int getMaximumYoungGenerationSizePercent() {
        int result = HeapPolicyOptions.MaximumYoungGenerationSizePercent.getValue();
        VMError.guarantee((result >= 0) && (result <= 100), "MaximumYoungGenerationSizePercent should be in [0 ..100]");
        return result;
    }

    /** Set the maximum young generation size, returning the previous value. */
    public static UnsignedWord setMaximumYoungGenerationSize(UnsignedWord value) {
        UnsignedWord result = maximumYoungGenerationSize;
        maximumYoungGenerationSize = value;
        return result;
    }

    public static UnsignedWord getMaximumHeapSize() {
        if (maximumHeapSize.aboveThan(WordFactory.zero())) {
            return maximumHeapSize;
        }
        XOptions.XFlag xmx = XOptions.getXmx();
        if (xmx.getEpoch() > 0) {
            HeapPolicy.setMaximumHeapSize(WordFactory.unsigned(xmx.getValue()));
            return maximumHeapSize;
        }
        long hostedValue = SubstrateGCOptions.MaxHeapSize.getHostedValue();
        if (hostedValue != 0) {
            return WordFactory.unsigned(hostedValue);
        }
        /*
         * If the physical size is known yet, the maximum size of the heap is a fraction of the size
         * of the physical memory.
         */
        UnsignedWord addressSpaceSize = getAddressSpaceSize();
        if (PhysicalMemory.isInitialized()) {
            UnsignedWord physicalMemorySize = PhysicalMemory.getCachedSize();
            int maximumHeapSizePercent = getMaximumHeapSizePercent();
            /* Do not cache because `-Xmx` option parsing may not have happened yet. */
            UnsignedWord result = physicalMemorySize.unsignedDivide(100).multiply(maximumHeapSizePercent);
            if (result.belowThan(addressSpaceSize)) {
                return result;
            }
        }
        return addressSpaceSize;
    }

    private static UnsignedWord getAddressSpaceSize() {
        int compressionShift = ReferenceAccess.singleton().getCompressEncoding().getShift();
        if (compressionShift > 0) {
            int referenceSize = ConfigurationValues.getObjectLayout().getReferenceSize();
            return WordFactory.unsigned(1L << (referenceSize * Byte.SIZE)).shiftLeft(compressionShift);
        }
        return UnsignedUtils.MAX_VALUE;
    }

    private static int getMaximumHeapSizePercent() {
        int result = HeapPolicyOptions.MaximumHeapSizePercent.getValue();
        VMError.guarantee((result >= 0) && (result <= 100), "MaximumHeapSizePercent should be in [0 ..100]");
        return result;
    }

    /** Set the maximum heap size, returning the previous value. */
    public static UnsignedWord setMaximumHeapSize(UnsignedWord value) {
        Log trace = Log.noopLog().string("[HeapPolicy.setMaximumHeapSize:");
        UnsignedWord result = maximumHeapSize;
        maximumHeapSize = value;
        trace.string("  old: ").unsigned(result).string("  new: ").unsigned(maximumHeapSize).string(" ]").newline();
        return result;
    }

    public static UnsignedWord getMinimumHeapSize() {
        Log trace = Log.noopLog().string("[HeapPolicy.getMinimumHeapSize:");
        if (minimumHeapSize.aboveThan(WordFactory.zero())) {
            /* If someone has set the minimum heap size, use that value. */
            trace.string("  returns: ").unsigned(minimumHeapSize).string(" ]").newline();
            return minimumHeapSize;
        }
        XOptions.XFlag xms = XOptions.getXms();
        if (xms.getEpoch() > 0) {
            /* If `-Xms` has been parsed from the command line, use that value. */
            trace.string("  -Xms.epoch: ").unsigned(xms.getEpoch()).string("  -Xms.value: ").unsigned(xms.getValue());
            setMinimumHeapSize(WordFactory.unsigned(xms.getValue()));
            trace.string("  returns: ").unsigned(minimumHeapSize).string(" ]").newline();
            return minimumHeapSize;
        }
        long hostedValue = SubstrateGCOptions.MinHeapSize.getHostedValue();
        if (hostedValue != 0) {
            trace.string("  returns: ").unsigned(hostedValue).string(" ]").newline();
            return WordFactory.unsigned(hostedValue);
        }
        /* A default value chosen to delay the first full collection. */
        UnsignedWord result = getMaximumYoungGenerationSize().multiply(2);
        /* But not larger than -Xmx. */
        if (result.aboveThan(getMaximumHeapSize())) {
            result = getMaximumHeapSize();
        }
        /* But do not cache the result as it is based on values that might change. */
        trace.string("  returns: ").unsigned(result).string(" ]").newline();
        return result;
    }

    /** Set the minimum heap size, returning the previous value. */
    public static UnsignedWord setMinimumHeapSize(UnsignedWord value) {
        UnsignedWord result = minimumHeapSize;
        minimumHeapSize = value;
        return result;
    }

    @Fold
    public static UnsignedWord getAlignedHeapChunkSize() {
        return WordFactory.unsigned(HeapPolicyOptions.AlignedHeapChunkSize.getValue());
    }

    @Fold
    static UnsignedWord getAlignedHeapChunkAlignment() {
        return getAlignedHeapChunkSize();
    }

    @Fold
    public static UnsignedWord getLargeArrayThreshold() {
        long largeArrayThreshold = HeapPolicyOptions.LargeArrayThreshold.getValue();
        if (LARGE_ARRAY_THRESHOLD_SENTINEL_VALUE == largeArrayThreshold) {
            return getAlignedHeapChunkSize().unsignedDivide(ALIGNED_HEAP_CHUNK_FRACTION_FOR_LARGE_ARRAY_THRESHOLD);
        } else {
            return WordFactory.unsigned(HeapPolicyOptions.LargeArrayThreshold.getValue());
        }
    }

    /*
     * Zapping
     */

    public static boolean getZapProducedHeapChunks() {
        return HeapPolicyOptions.ZapChunks.getValue() || HeapPolicyOptions.ZapProducedHeapChunks.getValue();
    }

    public static boolean getZapConsumedHeapChunks() {
        return HeapPolicyOptions.ZapChunks.getValue() || HeapPolicyOptions.ZapConsumedHeapChunks.getValue();
    }

    static {
        Word.ensureInitialized();
    }

    private static final UnsignedWord producedHeapChunkZapInt = WordFactory.unsigned(0xbaadbeef);
    private static final UnsignedWord producedHeapChunkZapWord = producedHeapChunkZapInt.shiftLeft(32).or(producedHeapChunkZapInt);

    private static final UnsignedWord consumedHeapChunkZapInt = WordFactory.unsigned(0xdeadbeef);
    private static final UnsignedWord consumedHeapChunkZapWord = consumedHeapChunkZapInt.shiftLeft(32).or(consumedHeapChunkZapInt);

    /*
     * Collection-triggering Policies
     */

    private static final UninterruptibleUtils.AtomicUnsigned edenUsedBytes = new UninterruptibleUtils.AtomicUnsigned();
    private static final UninterruptibleUtils.AtomicUnsigned youngUsedBytes = new UninterruptibleUtils.AtomicUnsigned();

    public static void setEdenAndYoungGenBytes(UnsignedWord edenBytes, UnsignedWord youngBytes) {
        assert VMOperation.isGCInProgress() : "would cause races otherwise";
        youngUsedBytes.set(youngBytes);
        edenUsedBytes.set(edenBytes);
    }

    public static void increaseEdenUsedBytes(UnsignedWord value) {
        youngUsedBytes.addAndGet(value);
        edenUsedBytes.addAndGet(value);
    }

    @Uninterruptible(reason = "Called from uninterruptible code.", mayBeInlined = true)
    public static UnsignedWord getYoungUsedBytes() {
        assert !VMOperation.isGCInProgress() : "value is incorrect during a GC";
        return youngUsedBytes.get();
    }

    public static UnsignedWord getEdenUsedBytes() {
        assert !VMOperation.isGCInProgress() : "value is incorrect during a GC";
        return edenUsedBytes.get();
    }

    private static UnsignedWord getAllocationBeforePhysicalMemorySize() {
        return WordFactory.unsigned(HeapPolicyOptions.AllocationBeforePhysicalMemorySize.getValue());
    }

    public static void maybeCollectOnAllocation() {
        if (GCImpl.hasNeverCollectPolicy()) {
            // Don't initiate a safepoint if we won't do a collection anyways.
            if (HeapPolicy.getEdenUsedBytes().aboveThan(HeapPolicy.getMaximumHeapSize())) {
                throw OUT_OF_MEMORY_ERROR;
            }
        } else {
            UnsignedWord maxYoungSize = getMaximumYoungGenerationSize();
            boolean outOfMemory = maybeCollectOnAllocation(maxYoungSize);
            if (outOfMemory) {
                throw OUT_OF_MEMORY_ERROR;
            }
        }
    }

    @Uninterruptible(reason = "Avoid races with other threads that also try to trigger a GC")
    private static boolean maybeCollectOnAllocation(UnsignedWord maxYoungSize) {
        if (youngUsedBytes.get().aboveOrEqual(maxYoungSize)) {
            return GCImpl.getGCImpl().collectWithoutAllocating(GenScavengeGCCause.OnAllocation, false);
        }
        return false;
    }

    public static void maybeCauseUserRequestedCollection() {
        if (!SubstrateGCOptions.DisableExplicitGC.getValue()) {
            HeapImpl.getHeapImpl().getGC().collectCompletely(GCCause.JavaLangSystemGC);
        }
    }

    public static final class TestingBackDoor {
        private TestingBackDoor() {
        }

        /** The size, in bytes, of what qualifies as a "large" array. */
        public static long getUnalignedObjectSize() {
            return HeapPolicy.getLargeArrayThreshold().rawValue();
        }
    }

    /*
     * Periodic tasks
     */

    /** Sample the physical memory size, before the first collection but after some allocation. */
    static void samplePhysicalMemorySize() {
        if (HeapImpl.getHeapImpl().getGCImpl().getCollectionEpoch().equal(WordFactory.zero()) &&
                        getYoungUsedBytes().aboveThan(getAllocationBeforePhysicalMemorySize())) {
            PhysicalMemory.tryInitialize();
        }
    }
}
