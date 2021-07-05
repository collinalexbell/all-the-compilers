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
package org.graalvm.compiler.lir.aarch64;

import static org.graalvm.compiler.asm.aarch64.AArch64Address.isImmediateScaled;
import static org.graalvm.compiler.asm.aarch64.AArch64Address.AddressingMode.IMMEDIATE_SIGNED_UNSCALED;
import static org.graalvm.compiler.asm.aarch64.AArch64Address.AddressingMode.IMMEDIATE_UNSIGNED_SCALED;

import java.util.EnumSet;

import org.graalvm.compiler.asm.aarch64.AArch64Address;
import org.graalvm.compiler.asm.aarch64.AArch64Address.AddressingMode;
import org.graalvm.compiler.core.common.NumUtil;
import org.graalvm.compiler.debug.GraalError;
import org.graalvm.compiler.lir.CompositeValue;
import org.graalvm.compiler.lir.InstructionValueConsumer;
import org.graalvm.compiler.lir.InstructionValueProcedure;
import org.graalvm.compiler.lir.LIRInstruction;
import org.graalvm.compiler.lir.LIRInstruction.OperandFlag;

import jdk.vm.ci.aarch64.AArch64;
import jdk.vm.ci.code.Register;
import jdk.vm.ci.code.RegisterValue;
import jdk.vm.ci.meta.AllocatableValue;
import jdk.vm.ci.meta.Value;
import jdk.vm.ci.meta.ValueKind;

public final class AArch64AddressValue extends CompositeValue {
    private static final EnumSet<OperandFlag> flags = EnumSet.of(OperandFlag.REG, OperandFlag.ILLEGAL);

    @Component({OperandFlag.REG, OperandFlag.ILLEGAL}) protected AllocatableValue base;
    @Component({OperandFlag.REG, OperandFlag.ILLEGAL}) protected AllocatableValue offset;
    private final int displacement;

    /**
     * Whether register offset should be scaled or not.
     */
    private final int scaleFactor;
    private final AddressingMode addressingMode;

    public AArch64AddressValue(ValueKind<?> kind, AllocatableValue base, AllocatableValue offset, int displacement, int scaleFactor, AddressingMode addressingMode) {
        super(kind);
        this.base = base;
        this.offset = offset;
        this.displacement = displacement;
        this.scaleFactor = scaleFactor;
        this.addressingMode = addressingMode;
    }

    /**
     * Generates an AArch64AddressValue of the form {@code base}.
     */
    public static AArch64AddressValue makeAddress(ValueKind<?> kind, int size, AllocatableValue base) {
        return makeAddress(kind, size, base, 0);
    }

    /**
     * Generates an AArch64AddressValue of the form {@code base + displacement}.
     *
     * Will fail if displacement cannot be represented directly as an immediate address.
     */
    public static AArch64AddressValue makeAddress(ValueKind<?> kind, int size, AllocatableValue base, int displacement) {
        assert size == 8 || size == 16 || size == 32 || size == 64 || size == 128;

        if (displacement == 0) {
            return new AArch64AddressValue(kind, base, Value.ILLEGAL, 0, 1, AddressingMode.BASE_REGISTER_ONLY);

        } else {
            int byteSize = size / 8;
            int log2TransferSize = NumUtil.log2Ceil(byteSize);
            /* Addresses using IMMEDIATE_UNSIGNED_SCALED must be non-negative and shiftable. */
            boolean canScale = displacement >= 0 &&
                            (displacement & (NumUtil.getNbitNumberInt(log2TransferSize))) == 0;
            AArch64Address.AddressingMode mode = canScale ? IMMEDIATE_UNSIGNED_SCALED : IMMEDIATE_SIGNED_UNSCALED;
            if (AArch64Address.isValidImmediateAddress(size, mode, displacement)) {
                int scalingFactor = isImmediateScaled(mode) ? byteSize : 1;
                return new AArch64AddressValue(kind, base, Value.ILLEGAL, displacement, scalingFactor, mode);
            } else {
                throw GraalError.shouldNotReachHere("Could not create AddressValue with requested displacement.");
            }
        }
    }

    private static Register toRegister(AllocatableValue value) {
        if (value.equals(Value.ILLEGAL)) {
            return AArch64.zr;
        } else {
            return ((RegisterValue) value).getRegister();
        }
    }

    public AllocatableValue getBase() {
        return base;
    }

    public AllocatableValue getOffset() {
        return offset;
    }

    public int getDisplacement() {
        return displacement;
    }

    public boolean isScaled() {
        return scaleFactor != 1;
    }

    public int getScaleFactor() {
        return scaleFactor;
    }

    public AddressingMode getAddressingMode() {
        return addressingMode;
    }

    public AArch64Address toAddress() {
        assert addressingMode != AddressingMode.EXTENDED_REGISTER_OFFSET;
        Register baseReg = toRegister(base);
        Register offsetReg = toRegister(offset);
        return AArch64Address.createAddress(addressingMode, baseReg, offsetReg, displacement / scaleFactor, isScaled(), null);
    }

    @Override
    public CompositeValue forEachComponent(LIRInstruction inst, LIRInstruction.OperandMode mode, InstructionValueProcedure proc) {
        AllocatableValue newBase = (AllocatableValue) proc.doValue(inst, base, mode, flags);
        AllocatableValue newOffset = (AllocatableValue) proc.doValue(inst, offset, mode, flags);
        if (!base.identityEquals(newBase) || !offset.identityEquals(newOffset)) {
            return new AArch64AddressValue(getValueKind(), newBase, newOffset, displacement, scaleFactor, addressingMode);
        }
        return this;
    }

    @Override
    protected void visitEachComponent(LIRInstruction inst, LIRInstruction.OperandMode mode, InstructionValueConsumer proc) {
        proc.visitValue(inst, base, mode, flags);
        proc.visitValue(inst, offset, mode, flags);
    }
}
