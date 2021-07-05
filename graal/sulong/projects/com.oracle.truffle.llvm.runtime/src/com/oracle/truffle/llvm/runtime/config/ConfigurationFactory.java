/*
 * Copyright (c) 2016, 2021, Oracle and/or its affiliates.
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
package com.oracle.truffle.llvm.runtime.config;

import com.oracle.truffle.llvm.runtime.ContextExtension;
import com.oracle.truffle.llvm.runtime.LLVMLanguage;
import java.util.List;

import org.graalvm.options.OptionDescriptor;
import org.graalvm.options.OptionValues;

public interface ConfigurationFactory<KEY> {

    /**
     * If two factories say they are active, the one with the higher priority wins.
     */
    int getPriority();

    /**
     * Parse the configuration specific options. This method should return a non-null value if the
     * given {@link OptionValues} indicate that this configuration is active. The object should
     * contain all information necessary to create the runtime {@link Configuration} object.
     */
    KEY parseOptions(OptionValues options);

    /**
     * Create a runtime {@link Configuration} object. This method will be called exactly once for
     * every {@link LLVMLanguage} instance, during context creation. It will be passed the KEY
     * returned from {@link #parseOptions}.
     *
     * The engine may decide to share code between different contexts with options that produce the
     * same KEY value. In that case, there is a single shared {@link LLVMLanguage} instance, and
     * {@link #createConfiguration} is only called once, for the first context.
     */
    Configuration createConfiguration(LLVMLanguage language, ContextExtension.Registry ctxExtRegistry, KEY key);

    List<OptionDescriptor> getOptionDescriptors();

    /**
     * Returns the name of the configuration.
     */
    String getName();

    /**
     * Returns a hint for the user on {@link #parseOptions required options} for this configuration.
     */
    String getHint();
}
