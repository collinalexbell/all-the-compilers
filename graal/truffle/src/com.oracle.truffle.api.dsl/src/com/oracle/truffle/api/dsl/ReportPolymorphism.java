/*
 * Copyright (c) 2012, 2020, Oracle and/or its affiliates. All rights reserved.
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
package com.oracle.truffle.api.dsl;

import com.oracle.truffle.api.nodes.Node;

import java.lang.annotation.ElementType;
import java.lang.annotation.Inherited;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

/**
 * Enables reporting of polymorphic specializations from this node or exported message to the
 * runtime.
 *
 * Polymorphic specializations include, but are not limited to, activating another specialization,
 * increasing the number of instances of an active specialization, excluding a specialization, etc.
 *
 * Additional information on the effect of {@link ReportPolymorphism} can be found in <a href=
 * "https://github.com/oracle/graal/blob/master/truffle/docs/splitting/ReportingPolymorphism.md">
 * ReportingPolymorphism.md</a>.
 *
 * @since 0.33
 */
@Retention(RetentionPolicy.CLASS)
@Target(ElementType.TYPE)
@Inherited
public @interface ReportPolymorphism {

    /**
     * Nodes (and their subclasses) or specializations annotated with this annotation will be
     * excluded from consideration when {@link Node#reportPolymorphicSpecialize() reporting
     * polymorphic specializations}.
     *
     * Individual specializations can be excluded from this consideration by using the
     * {@link ReportPolymorphism.Exclude} Polymorphic specializations are never reported on the
     * first specialization.
     *
     * @since 0.33
     */
    @Retention(RetentionPolicy.CLASS)
    @Target({ElementType.METHOD, ElementType.TYPE})
    @Inherited
    @interface Exclude {

    }

    /**
     * Specializations annotated with this annotation are considered megamorphic. This means that on
     * the first activation of such a specialization the node will
     * {@link Node#reportPolymorphicSpecialize() report a polymorphic specialization}.
     *
     * This annotation can be used independently of {@link ReportPolymorphism}. This means that a
     * node need not report every polymorphic specialization as with {@link ReportPolymorphism} but
     * only ones that produce generic and expensive cases. For example, if a node has several fast
     * specializations and a very slow generic specialization it does not make sense to report
     * activations of these fast specializations as polymorphic specializations as they perform well
     * even without runtime intervention (e.g. Splitting). On the other hand, the activation of the
     * generic case is slow and something that the runtime might be able to remove.
     *
     * @since 20.3
     */
    @Retention(RetentionPolicy.CLASS)
    @Target(ElementType.METHOD)
    @interface Megamorphic {

    }
}
