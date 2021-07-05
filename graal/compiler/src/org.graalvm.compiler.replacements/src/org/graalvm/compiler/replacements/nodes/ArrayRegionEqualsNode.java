/*
 * Copyright (c) 2013, 2020, Oracle and/or its affiliates. All rights reserved.
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
package org.graalvm.compiler.replacements.nodes;

import static org.graalvm.compiler.core.common.GraalOptions.UseGraalStubs;
import static org.graalvm.compiler.nodeinfo.InputType.Memory;

import org.graalvm.compiler.core.common.spi.ForeignCallLinkage;
import org.graalvm.compiler.core.common.type.StampFactory;
import org.graalvm.compiler.graph.NodeClass;
import org.graalvm.compiler.nodeinfo.NodeCycles;
import org.graalvm.compiler.nodeinfo.NodeInfo;
import org.graalvm.compiler.nodeinfo.NodeSize;
import org.graalvm.compiler.nodes.FixedWithNextNode;
import org.graalvm.compiler.nodes.NamedLocationIdentity;
import org.graalvm.compiler.nodes.ValueNode;
import org.graalvm.compiler.nodes.ValueNodeUtil;
import org.graalvm.compiler.nodes.memory.MemoryAccess;
import org.graalvm.compiler.nodes.memory.MemoryKill;
import org.graalvm.compiler.nodes.spi.LIRLowerable;
import org.graalvm.compiler.nodes.spi.NodeLIRBuilderTool;
import org.graalvm.word.LocationIdentity;
import org.graalvm.word.Pointer;

import jdk.vm.ci.meta.JavaKind;
import jdk.vm.ci.meta.MetaAccessProvider;
import jdk.vm.ci.meta.Value;

// JaCoCo Exclude

/**
 * Compares two array regions with a given length.
 */
@NodeInfo(cycles = NodeCycles.CYCLES_UNKNOWN, size = NodeSize.SIZE_128)
public class ArrayRegionEqualsNode extends FixedWithNextNode implements LIRLowerable, MemoryAccess {

    public static final NodeClass<ArrayRegionEqualsNode> TYPE = NodeClass.create(ArrayRegionEqualsNode.class);

    /** {@link JavaKind} of the arrays to compare. */
    protected final JavaKind kind1;
    protected final JavaKind kind2;

    /** Pointer to first array region to be tested for equality. */
    @Input protected ValueNode array1;

    /** Pointer to second array region to be tested for equality. */
    @Input protected ValueNode array2;

    /** Length of the array region. */
    @Input protected ValueNode length;

    @OptionalInput(Memory) protected MemoryKill lastLocationAccess;

    public ArrayRegionEqualsNode(ValueNode array1, ValueNode array2, ValueNode length, @ConstantNodeParameter JavaKind kind1, @ConstantNodeParameter JavaKind kind2) {
        this(TYPE, array1, array2, length, kind1, kind2);
    }

    protected ArrayRegionEqualsNode(NodeClass<? extends ArrayRegionEqualsNode> c, ValueNode array1, ValueNode array2, ValueNode length, @ConstantNodeParameter JavaKind kind1,
                    @ConstantNodeParameter JavaKind kind2) {
        super(c, StampFactory.forKind(JavaKind.Boolean));
        this.kind1 = kind1;
        this.kind2 = kind2;
        this.array1 = array1;
        this.array2 = array2;
        this.length = length;
    }

    public static boolean regionEquals(Pointer array1, Pointer array2, int length, @ConstantNodeParameter JavaKind kind) {
        return regionEquals(array1, array2, length, kind, kind);
    }

    @NodeIntrinsic
    public static native boolean regionEquals(Pointer array1, Pointer array2, int length, @ConstantNodeParameter JavaKind kind1, @ConstantNodeParameter JavaKind kind2);

    public ValueNode getArray1() {
        return array1;
    }

    public ValueNode getArray2() {
        return array2;
    }

    public JavaKind getKind1() {
        return kind1;
    }

    public JavaKind getKind2() {
        return kind2;
    }

    public ValueNode getLength() {
        return length;
    }

    @Override
    public void generate(NodeLIRBuilderTool gen) {
        if (UseGraalStubs.getValue(graph().getOptions())) {
            ForeignCallLinkage linkage = gen.lookupGraalStub(this);
            if (linkage != null) {
                Value result = gen.getLIRGeneratorTool().emitForeignCall(linkage, null, gen.operand(array1), gen.operand(array2), gen.operand(length));
                gen.setResult(this, result);
                return;
            }
        }
        generateArrayRegionEquals(gen);
    }

    protected void generateArrayRegionEquals(NodeLIRBuilderTool gen) {
        Value result;
        MetaAccessProvider metaAccess = gen.getLIRGeneratorTool().getMetaAccess();
        int array1BaseOffset = metaAccess.getArrayBaseOffset(kind1);
        int array2BaseOffset = metaAccess.getArrayBaseOffset(kind2);
        if (kind1 == kind2) {
            result = gen.getLIRGeneratorTool().emitArrayEquals(kind1, array1BaseOffset, array2BaseOffset, gen.operand(array1), gen.operand(array2), gen.operand(length), true);
        } else {
            result = gen.getLIRGeneratorTool().emitArrayEquals(kind1, kind2, array1BaseOffset, array2BaseOffset, gen.operand(array1), gen.operand(array2), gen.operand(length), true);
        }
        gen.setResult(this, result);
    }

    @Override
    public LocationIdentity getLocationIdentity() {
        return kind1 != kind2 ? LocationIdentity.ANY_LOCATION : NamedLocationIdentity.getArrayLocation(kind1);
    }

    @Override
    public MemoryKill getLastLocationAccess() {
        return lastLocationAccess;
    }

    @Override
    public void setLastLocationAccess(MemoryKill lla) {
        updateUsages(ValueNodeUtil.asNode(lastLocationAccess), ValueNodeUtil.asNode(lla));
        lastLocationAccess = lla;
    }

}
