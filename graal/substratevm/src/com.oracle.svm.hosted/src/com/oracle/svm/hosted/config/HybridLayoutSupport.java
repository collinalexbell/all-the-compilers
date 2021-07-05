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
package com.oracle.svm.hosted.config;

import java.lang.reflect.Modifier;

import org.graalvm.collections.Pair;

import com.oracle.svm.core.annotate.Hybrid;
import com.oracle.svm.hosted.meta.HostedField;
import com.oracle.svm.hosted.meta.HostedInstanceClass;
import com.oracle.svm.hosted.meta.HostedType;

public class HybridLayoutSupport {
    public boolean isHybrid(HostedType clazz) {
        return clazz.isAnnotationPresent(Hybrid.class);
    }

    public boolean isHybridField(HostedField field) {
        return field.getAnnotation(Hybrid.Array.class) != null || field.getAnnotation(Hybrid.TypeIDSlots.class) != null;
    }

    public boolean canHybridFieldsBeDuplicated(HostedType clazz) {
        assert isHybrid(clazz) : "Can only be called on hybrid types";
        return clazz.getAnnotation(Hybrid.class).canHybridFieldsBeDuplicated();
    }

    /**
     * Finds the hybrid array and bitset fields of a class annotated with {@link Hybrid}.
     *
     * @param hybridClass A class annotated with {@link Hybrid}
     * @return A {@link Pair} containing the (non-null) hybrid array field in the left position, and
     *         the (nullable) hybrid bitset field in the right position.
     */
    public HybridFields findHybridFields(HostedInstanceClass hybridClass) {
        assert hybridClass.getAnnotation(Hybrid.class) != null;
        assert Modifier.isFinal(hybridClass.getModifiers());

        HostedField foundArrayField = null;
        HostedField foundTypeIDSlotsField = null;
        for (HostedField field : hybridClass.getInstanceFields(true)) {
            if (field.getAnnotation(Hybrid.Array.class) != null) {
                assert foundArrayField == null : "must have exactly one hybrid array field";
                assert field.getType().isArray();
                foundArrayField = field;
            }
            if (field.getAnnotation(Hybrid.TypeIDSlots.class) != null) {
                assert foundTypeIDSlotsField == null : "must have at most one typeid slot field";
                assert field.getType().isArray();
                foundTypeIDSlotsField = field;
            }
        }
        assert foundArrayField != null : "must have exactly one hybrid array field";
        return new HybridFields(foundArrayField, foundTypeIDSlotsField);
    }

    public static class HybridFields {
        public final HostedField arrayField;
        public final HostedField typeIDSlotsField;

        public HybridFields(HostedField arrayField, HostedField typeIDSlotsField) {
            this.arrayField = arrayField;
            this.typeIDSlotsField = typeIDSlotsField;
        }
    }
}
