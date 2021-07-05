/*
 * Copyright (c) 2018, 2020, Oracle and/or its affiliates. All rights reserved.
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
package com.oracle.truffle.polyglot;

import static com.oracle.truffle.api.CompilerDirectives.shouldNotReachHere;
import static com.oracle.truffle.polyglot.EngineAccessor.LANGUAGE;

import java.util.Collection;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.function.Function;

import org.graalvm.polyglot.Source;

import com.oracle.truffle.api.Assumption;
import com.oracle.truffle.api.CallTarget;
import com.oracle.truffle.api.Truffle;
import com.oracle.truffle.api.TruffleLanguage;
import com.oracle.truffle.api.TruffleLanguage.ContextPolicy;
import com.oracle.truffle.api.TruffleLanguage.ContextReference;
import com.oracle.truffle.api.TruffleLanguage.LanguageReference;
import com.oracle.truffle.api.interop.TruffleObject;
import com.oracle.truffle.api.nodes.RootNode;
import com.oracle.truffle.polyglot.PolyglotImpl.VMObject;
import com.oracle.truffle.polyglot.PolyglotLocals.LanguageContextLocal;
import com.oracle.truffle.polyglot.PolyglotLocals.LanguageContextThreadLocal;
import com.oracle.truffle.polyglot.PolyglotLocals.LocalLocation;

final class PolyglotLanguageInstance implements VMObject {

    final PolyglotLanguage language;
    final TruffleLanguage<Object> spi;

    private final PolyglotSourceCache sourceCache;
    private final Map<Class<?>, PolyglotValueDispatch> valueCache;
    private final Map<Class<?>, CallTarget> callTargetCache;

    final Map<Object, Object> hostToGuestCodeCache = new ConcurrentHashMap<>();
    private volatile OptionValuesImpl firstOptionValues;
    private volatile boolean multiContextInitialized;
    private final Assumption singleContext = Truffle.getRuntime().createAssumption("Single context per language instance.");

    /**
     * Direct language lookups in the current language.
     */
    private final LanguageReference<TruffleLanguage<Object>> directLanguageSupplier;

    /**
     * Direct context lookups in the current language.
     */
    private final ContextReference<Object> directContextSupplier;

    // effectively final
    List<LanguageContextLocal<?>> contextLocals;
    List<LanguageContextThreadLocal<?>> contextThreadLocals;
    LocalLocation[] contextLocalLocations;
    LocalLocation[] contextThreadLocalLocations;
    int claimedCount;

    @SuppressWarnings("unchecked")
    PolyglotLanguageInstance(PolyglotLanguage language) {
        this.language = language;
        this.sourceCache = new PolyglotSourceCache();
        this.valueCache = new ConcurrentHashMap<>();
        this.callTargetCache = new ConcurrentHashMap<>();
        try {
            this.spi = (TruffleLanguage<Object>) language.cache.loadLanguage();
            LANGUAGE.initializeLanguage(spi, language.info, language, this);
        } catch (Exception e) {
            throw new IllegalStateException(String.format("Error initializing language '%s' using class '%s'.", language.cache.getId(), language.cache.getClassName()), e);
        }

        boolean mayBeUsedInInnerContext = language.cache.getPolicy() != ContextPolicy.EXCLUSIVE;
        boolean currentExclusive = language.getEffectiveContextPolicy(language) == ContextPolicy.EXCLUSIVE;

        Assumption useDirectSingleContext = currentExclusive ? null : singleContext;
        Assumption useInnerContext = mayBeUsedInInnerContext ? language.engine.noInnerContexts : null;

        if (language.engine.conservativeContextReferences) {
            this.directContextSupplier = language.getConservativeContextReference();
        } else {
            if (useDirectSingleContext == null && useInnerContext == null) {
                // no checks can use direct reference
                this.directContextSupplier = PolyglotReferences.createAlwaysSingleContext(language, currentExclusive);
            } else {
                this.directContextSupplier = PolyglotReferences.createAssumeSingleContext(language,
                                useInnerContext,
                                useDirectSingleContext,
                                language.getContextReference(), currentExclusive);
            }
        }
        this.directLanguageSupplier = PolyglotReferences.createAlwaysSingleLanguage(language, this);
        PolyglotValueDispatch.createDefaultValues(getImpl(), this, this.valueCache);
    }

    CallTarget lookupCallTarget(Class<? extends RootNode> rootNodeClass) {
        return callTargetCache.get(rootNodeClass);
    }

    CallTarget installCallTarget(RootNode rootNode) {
        return callTargetCache.computeIfAbsent(rootNode.getClass(), (r) -> Truffle.getRuntime().createCallTarget(rootNode));
    }

    public PolyglotEngineImpl getEngine() {
        return language.engine;
    }

    boolean areOptionsCompatible(OptionValuesImpl newOptionValues) {
        OptionValuesImpl firstOptions = this.firstOptionValues;
        if (firstOptionValues == null) {
            return true;
        } else {
            return EngineAccessor.LANGUAGE.areOptionsCompatible(spi, firstOptions, newOptionValues);
        }
    }

    void claim(OptionValuesImpl optionValues) {
        assert Thread.holdsLock(language.engine.lock);
        if (this.firstOptionValues == null) {
            this.firstOptionValues = optionValues;
        }
        claimedCount++;
    }

    void patchFirstOptions(OptionValuesImpl optionValues) {
        this.firstOptionValues = optionValues;
    }

    void ensureMultiContextInitialized() {
        assert Thread.holdsLock(language.engine.lock);
        if (!language.engine.singleContext.isValid() && language.cache.getPolicy() != ContextPolicy.EXCLUSIVE) {
            if (!multiContextInitialized) {
                multiContextInitialized = true;
                language.engine.initializeMultiContext(null);
                this.singleContext.invalidate();
                LANGUAGE.initializeMultiContext(spi);
            }
        }
    }

    PolyglotSourceCache getSourceCache() {
        return sourceCache;
    }

    /**
     * Direct context references can safely be shared within one AST of a language.
     */
    ContextReference<Object> getDirectContextSupplier() {
        return directContextSupplier;
    }

    /**
     * Looks up the context reference to use for a foreign language AST.
     */
    ContextReference<Object> lookupContextSupplier(PolyglotLanguage sourceLanguage) {
        assert language != sourceLanguage;
        ContextReference<Object> ref;
        switch (language.getEffectiveContextPolicy(sourceLanguage)) {
            case EXCLUSIVE:
                ref = PolyglotReferences.createAssumeSingleContext(language, language.engine.noInnerContexts, null,
                                language.getContextReference(), true);
                break;
            case REUSE:
            case SHARED:
                ref = this.language.getContextReference();
                break;
            default:
                throw shouldNotReachHere();
        }
        return ref;
    }

    /**
     * Direct language references can safely be shared within one AST of a language.
     */
    LanguageReference<TruffleLanguage<Object>> getDirectLanguageReference() {
        return directLanguageSupplier;
    }

    /**
     * Looks up the language reference to use for a foreign language AST.
     */
    LanguageReference<TruffleLanguage<Object>> lookupLanguageSupplier(PolyglotLanguage sourceLanguage) {
        assert language != sourceLanguage;
        switch (language.getEffectiveContextPolicy(sourceLanguage)) {
            case EXCLUSIVE:
                return PolyglotReferences.createAssumeSingleLanguage(language, this, language.singleInstance, language.getLanguageReference());
            case REUSE:
            case SHARED:
                return this.language.getLanguageReference();
            default:
                throw shouldNotReachHere();
        }
    }

    void listCachedSources(Collection<Source> sources) {
        sourceCache.listCachedSources(this, sources);
    }

    PolyglotValueDispatch lookupValueCache(PolyglotContextImpl context, Object guestValue) {
        PolyglotValueDispatch cache = valueCache.get(guestValue.getClass());
        if (cache == null) {
            Object prev = language.engine.enterIfNeeded(context, true);
            try {
                cache = lookupValueCacheImpl(guestValue);
            } finally {
                language.engine.leaveIfNeeded(prev, context);
            }
        }
        return cache;
    }

    private synchronized PolyglotValueDispatch lookupValueCacheImpl(Object guestValue) {
        PolyglotValueDispatch cache = valueCache.computeIfAbsent(guestValue.getClass(), new Function<Class<?>, PolyglotValueDispatch>() {
            public PolyglotValueDispatch apply(Class<?> t) {
                return PolyglotValueDispatch.createInteropValue(PolyglotLanguageInstance.this, (TruffleObject) guestValue, guestValue.getClass());
            }
        });
        return cache;
    }

}
