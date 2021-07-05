/*
 * Copyright (c) 2019, 2020, Oracle and/or its affiliates.
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
package com.oracle.truffle.llvm.parser.model.symbols.constants;

import com.oracle.truffle.llvm.parser.LLVMParserRuntime;
import com.oracle.truffle.llvm.parser.model.SymbolImpl;
import com.oracle.truffle.llvm.parser.model.SymbolTable;
import com.oracle.truffle.llvm.parser.model.visitors.SymbolVisitor;
import com.oracle.truffle.llvm.runtime.GetStackSpaceFactory;
import com.oracle.truffle.llvm.runtime.datalayout.DataLayout;
import com.oracle.truffle.llvm.runtime.nodes.api.LLVMExpressionNode;
import com.oracle.truffle.llvm.runtime.types.Type;

public final class SelectConstant extends AbstractConstant {

    private Constant condition;

    private Constant trueValue;
    private Constant falseValue;

    private SelectConstant(Type type) {
        super(type);
    }

    @Override
    public void replace(SymbolImpl original, SymbolImpl replacement) {
        if (condition == original) {
            condition = (Constant) replacement;
        }
        if (falseValue == original) {
            falseValue = (Constant) replacement;
        }
        if (trueValue == original) {
            trueValue = (Constant) replacement;
        }
    }

    public static SelectConstant fromSymbols(SymbolTable symbols, Type type, int condition, int trueValue, int falseValue) {
        final SelectConstant constant = new SelectConstant(type);
        constant.condition = (Constant) symbols.getForwardReferenced(condition, constant);
        constant.trueValue = (Constant) symbols.getForwardReferenced(trueValue, constant);
        constant.falseValue = (Constant) symbols.getForwardReferenced(falseValue, constant);
        return constant;
    }

    @Override
    public void accept(SymbolVisitor visitor) {
        visitor.visit(this);
    }

    @Override
    public LLVMExpressionNode createNode(LLVMParserRuntime runtime, DataLayout dataLayout, GetStackSpaceFactory stackFactory) {
        LLVMExpressionNode conditionNode = condition.createNode(runtime, dataLayout, stackFactory);
        LLVMExpressionNode trueValueNode = trueValue.createNode(runtime, dataLayout, stackFactory);
        LLVMExpressionNode falseValueNode = falseValue.createNode(runtime, dataLayout, stackFactory);
        return runtime.getNodeFactory().createSelect(getType(), conditionNode, trueValueNode, falseValueNode);
    }
}
