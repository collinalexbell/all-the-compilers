/*
 * Copyright (c) 2017, Oracle and/or its affiliates. All rights reserved.
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
package com.oracle.truffle.tools.chromeinspector.instrument;

import com.oracle.truffle.api.instrumentation.TruffleInstrument;

import com.oracle.truffle.tools.chromeinspector.TypeHandler;

@TruffleInstrument.Registration(id = TypeProfileInstrument.ID, services = {Enabler.class, TypeHandler.Provider.class}, internal = true)
public final class TypeProfileInstrument extends TruffleInstrument implements Enabler, TypeHandler.Provider {

    public static final String ID = "TypeProfileInstrument";

    private Env env;
    private TypeHandler th;

    @Override
    protected void onCreate(Env e) {
        this.env = e;
        e.registerService(this);
    }

    @Override
    protected void onDispose(Env e) {
        disable();
        super.onDispose(e);
    }

    @Override
    public void enable() {
        if (th == null) {
            th = new TypeHandler(env);
        }
    }

    @Override
    public void disable() {
        th = null;
    }

    @Override
    public TypeHandler getTypeHandler() {
        return th;
    }

}
