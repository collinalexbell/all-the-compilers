/*
 * Copyright (c) 2018, 2020, Oracle and/or its affiliates. All rights reserved.
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
package org.graalvm.compiler.replacements;

import static org.graalvm.compiler.nodeinfo.NodeCycles.CYCLES_256;
import static org.graalvm.compiler.nodeinfo.NodeSize.SIZE_64;

import org.graalvm.compiler.graph.NodeClass;
import org.graalvm.compiler.nodeinfo.NodeInfo;
import org.graalvm.compiler.nodes.spi.Lowerable;
import org.graalvm.compiler.nodes.spi.LoweringTool;
import org.graalvm.compiler.replacements.nodes.MacroNode;
import org.graalvm.compiler.replacements.nodes.MacroStateSplitNode;

/**
 * Represents a call to the following method, where the {@code str} argument (i.e. the characters
 * being searched for) is constant.
 *
 * <pre>
 * StringUTF16.indexOfUnsafe(byte[] value, int valueCount, byte[] str, int strCount, int fromIndex)
 * </pre>
 *
 * This node is only for JDK 9+. For JDK 8 or below, see {@link StringIndexOfNode}.
 */
@NodeInfo(size = SIZE_64, cycles = CYCLES_256)
public class StringUTF16IndexOfNode extends MacroStateSplitNode {
    public static final NodeClass<StringUTF16IndexOfNode> TYPE = NodeClass.create(StringUTF16IndexOfNode.class);

    public StringUTF16IndexOfNode(MacroParams p) {
        super(TYPE, p);
    }

    /**
     * Even though this implementation is the same as {@link Lowerable#lower}, it is required
     * because we would actually inherit {@link MacroNode#lower} which we do not want.
     */
    @Override
    public void lower(LoweringTool tool) {
        tool.getLowerer().lower(this, tool);
    }
}
