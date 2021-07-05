/*
 * Copyright (c) 2013, 2021, Oracle and/or its affiliates. All rights reserved.
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
package org.graalvm.compiler.truffle.runtime.hotspot;

import java.lang.ref.Reference;
import java.lang.reflect.Field;
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.nio.file.FileSystems;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Objects;
import java.util.function.Consumer;
import java.util.stream.Collectors;

import org.graalvm.compiler.truffle.common.CompilableTruffleAST;
import org.graalvm.compiler.truffle.common.TruffleCompiler;
import org.graalvm.compiler.truffle.common.hotspot.HotSpotTruffleCompiler;
import org.graalvm.compiler.truffle.common.hotspot.HotSpotTruffleCompilerRuntime;
import org.graalvm.compiler.truffle.options.PolyglotCompilerOptions;
import org.graalvm.compiler.truffle.runtime.BackgroundCompileQueue;
import org.graalvm.compiler.truffle.runtime.CompilationTask;
import org.graalvm.compiler.truffle.runtime.EngineData;
import org.graalvm.compiler.truffle.runtime.GraalTruffleRuntime;
import org.graalvm.compiler.truffle.runtime.OptimizedCallTarget;
import org.graalvm.compiler.truffle.runtime.OptimizedOSRLoopNode;
import org.graalvm.compiler.truffle.runtime.TruffleCallBoundary;

import com.oracle.truffle.api.CallTarget;
import com.oracle.truffle.api.CompilerAsserts;
import com.oracle.truffle.api.RootCallTarget;
import com.oracle.truffle.api.frame.FrameInstance;
import com.oracle.truffle.api.frame.FrameInstanceVisitor;
import com.oracle.truffle.api.impl.ThreadLocalHandshake;
import com.oracle.truffle.api.nodes.Node;
import com.oracle.truffle.api.nodes.RootNode;
import com.oracle.truffle.api.source.SourceSection;

import jdk.vm.ci.code.InstalledCode;
import jdk.vm.ci.code.stack.StackIntrospection;
import jdk.vm.ci.common.JVMCIError;
import jdk.vm.ci.hotspot.HotSpotConstantReflectionProvider;
import jdk.vm.ci.hotspot.HotSpotJVMCIRuntime;
import jdk.vm.ci.hotspot.HotSpotMetaAccessProvider;
import jdk.vm.ci.hotspot.HotSpotObjectConstant;
import jdk.vm.ci.hotspot.HotSpotResolvedJavaMethod;
import jdk.vm.ci.hotspot.HotSpotResolvedObjectType;
import jdk.vm.ci.hotspot.HotSpotSpeculationLog;
import jdk.vm.ci.hotspot.HotSpotVMConfigAccess;
import jdk.vm.ci.meta.JavaConstant;
import jdk.vm.ci.meta.JavaKind;
import jdk.vm.ci.meta.MetaAccessProvider;
import jdk.vm.ci.meta.ResolvedJavaField;
import jdk.vm.ci.meta.ResolvedJavaMethod;
import jdk.vm.ci.meta.ResolvedJavaType;
import jdk.vm.ci.meta.SpeculationLog;
import jdk.vm.ci.runtime.JVMCI;
import sun.misc.Unsafe;

/**
 * HotSpot specific implementation of a Graal-enabled Truffle runtime.
 *
 * This class contains functionality for interfacing with a HotSpot-based Truffle compiler,
 * independent of where the compiler resides (i.e., co-located in the HotSpot heap or running in a
 * native-image shared library).
 */
public abstract class AbstractHotSpotTruffleRuntime extends GraalTruffleRuntime implements HotSpotTruffleCompilerRuntime {

    static final sun.misc.Unsafe UNSAFE = getUnsafe();

    private static Unsafe getUnsafe() {
        try {
            return Unsafe.getUnsafe();
        } catch (SecurityException e) {
        }
        try {
            Field theUnsafeInstance = Unsafe.class.getDeclaredField("theUnsafe");
            theUnsafeInstance.setAccessible(true);
            return (Unsafe) theUnsafeInstance.get(Unsafe.class);
        } catch (Exception e) {
            throw new RuntimeException("exception while trying to get Unsafe.theUnsafe via reflection:", e);
        }
    }

    /**
     * Contains lazily computed data such as the compilation queue and helper for stack
     * introspection.
     */
    static final class Lazy extends BackgroundCompileQueue {
        StackIntrospection stackIntrospection;

        Lazy(AbstractHotSpotTruffleRuntime runtime) {
            super(runtime);
            runtime.installDefaultListeners();
        }

        @Override
        protected void compilerThreadIdled() {
            TruffleCompiler compiler = ((AbstractHotSpotTruffleRuntime) runtime).truffleCompiler;
            // truffleCompiler should never be null outside unit-tests, this check avoids transient
            // failures.
            if (compiler != null) {
                ((HotSpotTruffleCompiler) compiler).purgeCaches();
            }
        }
    }

    private volatile boolean traceTransferToInterpreter;
    private Boolean profilingEnabled;

    private volatile Lazy lazy;
    private volatile String lazyConfigurationName;

    private Lazy lazy() {
        if (lazy == null) {
            synchronized (this) {
                if (lazy == null) {
                    lazy = new Lazy(this);
                }
            }
        }
        return lazy;
    }

    private final List<ResolvedJavaMethod> truffleCallBoundaryMethods;
    private volatile CompilationTask initializationTask;
    private volatile boolean truffleCompilerInitialized;
    private volatile Throwable truffleCompilerInitializationException;

    private final HotSpotVMConfigAccess vmConfigAccess;
    private final int threadLocalPendingHandshakeOffset;

    public AbstractHotSpotTruffleRuntime() {
        super(Arrays.asList(HotSpotOptimizedCallTarget.class, InstalledCode.class, HotSpotThreadLocalHandshake.class));

        List<ResolvedJavaMethod> boundaryMethods = new ArrayList<>();
        MetaAccessProvider metaAccess = getMetaAccess();
        ResolvedJavaType type = metaAccess.lookupJavaType(OptimizedCallTarget.class);
        for (ResolvedJavaMethod method : type.getDeclaredMethods()) {
            if (method.getAnnotation(TruffleCallBoundary.class) != null) {
                boundaryMethods.add(method);
            }
        }
        this.truffleCallBoundaryMethods = boundaryMethods;
        setDontInlineCallBoundaryMethod(boundaryMethods);
        this.vmConfigAccess = new HotSpotVMConfigAccess(HotSpotJVMCIRuntime.runtime().getConfigStore());

        int offset;
        try {
            offset = vmConfigAccess.getFieldOffset("JavaThread::_jvmci_reserved0", Integer.class, "intptr_t*", -1);
        } catch (NoSuchMethodError error) {
            // jvmci is too old to have this overload of getFieldOffset
            offset = -1;
        }
        this.threadLocalPendingHandshakeOffset = offset;
    }

    @Override
    public final int getThreadLocalPendingHandshakeOffset() {
        return threadLocalPendingHandshakeOffset;
    }

    @Override
    public final ThreadLocalHandshake getThreadLocalHandshake() {
        return HotSpotThreadLocalHandshake.SINGLETON;
    }

    @Override
    public final Iterable<ResolvedJavaMethod> getTruffleCallBoundaryMethods() {
        return truffleCallBoundaryMethods;
    }

    @Override
    protected StackIntrospection getStackIntrospection() {
        Lazy l = lazy();
        if (l.stackIntrospection == null) {
            l.stackIntrospection = HotSpotJVMCIRuntime.runtime().getHostJVMCIBackend().getStackIntrospection();
        }
        return l.stackIntrospection;
    }

    @Override
    public HotSpotTruffleCompiler getTruffleCompiler(CompilableTruffleAST compilable) {
        Objects.requireNonNull(compilable, "Compilable must be non null.");
        if (truffleCompiler == null) {
            initializeTruffleCompiler((OptimizedCallTarget) compilable);
            rethrowTruffleCompilerInitializationException();
            assert truffleCompiler != null : "TruffleCompiler must be non null";
        }
        return (HotSpotTruffleCompiler) truffleCompiler;
    }

    /**
     * We need to trigger initialization of the Truffle compiler when the first call target is
     * created. Truffle call boundary methods are installed when the truffle compiler is
     * initialized, as it requires the compiler to do so. Until then the call boundary methods are
     * interpreted with the HotSpot interpreter (see {@link #setDontInlineCallBoundaryMethod(List)}
     * ). This is very slow and we want to avoid doing this as soon as possible. It can also be a
     * real issue when compilation is turned off completely and no call targets would ever be
     * compiled. Without ensureInitialized the stubs (see
     * {@link HotSpotTruffleCompiler#installTruffleCallBoundaryMethods}) would never be installed in
     * that case and we would use the HotSpot interpreter indefinitely.
     */
    private void ensureInitialized(OptimizedCallTarget firstCallTarget) {
        if (truffleCompilerInitialized) {
            return;
        }
        CompilationTask localTask = initializationTask;
        if (localTask == null) {
            final Object lock = this;
            synchronized (lock) {
                localTask = initializationTask;
                if (localTask == null && !truffleCompilerInitialized) {
                    rethrowTruffleCompilerInitializationException();
                    initializationTask = localTask = getCompileQueue().submitInitialization(firstCallTarget, new Consumer<CompilationTask>() {
                        @Override
                        public void accept(CompilationTask task) {
                            synchronized (lock) {
                                initializeTruffleCompiler(firstCallTarget);
                                assert truffleCompilerInitialized || truffleCompilerInitializationException != null;
                                assert initializationTask != null;
                                initializationTask = null;
                            }
                        }
                    });
                }
            }
        }
        if (localTask != null) {
            firstCallTarget.maybeWaitForTask(localTask);
            rethrowTruffleCompilerInitializationException();
        } else {
            assert truffleCompilerInitialized || truffleCompilerInitializationException != null;
        }
    }

    /*
     * Used reflectively in CompilerInitializationTest.
     */
    public final void resetCompiler() {
        truffleCompiler = null;
        truffleCompilerInitialized = false;
        truffleCompilerInitializationException = null;
    }

    private synchronized void initializeTruffleCompiler(OptimizedCallTarget callTarget) {
        // might occur for multiple compiler threads at the same time.
        if (!truffleCompilerInitialized) {
            rethrowTruffleCompilerInitializationException();
            try {
                EngineData engine = callTarget.engine;
                profilingEnabled = engine.profilingEnabled;
                TruffleCompiler compiler = newTruffleCompiler();
                compiler.initialize(getOptionsForCompiler(callTarget), callTarget, true);
                truffleCompiler = compiler;
                traceTransferToInterpreter = engine.traceTransferToInterpreter;
                truffleCompilerInitialized = true;
            } catch (Throwable e) {
                truffleCompilerInitializationException = e;
            }
        }
    }

    private void rethrowTruffleCompilerInitializationException() {
        if (truffleCompilerInitializationException != null) {
            throw sthrow(RuntimeException.class, truffleCompilerInitializationException);
        }
    }

    @SuppressWarnings({"unchecked", "unused"})
    private static <T extends Throwable> T sthrow(Class<T> type, Throwable t) throws T {
        throw (T) t;
    }

    @Override
    public final OptimizedCallTarget createOptimizedCallTarget(OptimizedCallTarget source, RootNode rootNode) {
        OptimizedCallTarget target = new HotSpotOptimizedCallTarget(source, rootNode);
        ensureInitialized(target);
        return target;
    }

    @Override
    public void onCodeInstallation(CompilableTruffleAST compilable, InstalledCode installedCode) {
        HotSpotOptimizedCallTarget callTarget = (HotSpotOptimizedCallTarget) compilable;
        callTarget.setInstalledCode(installedCode);
    }

    /**
     * Creates a log that {@code HotSpotSpeculationLog#managesFailedSpeculations() manages} a native
     * failed speculations list. An important invariant is that an nmethod compiled with this log
     * can never be executing once the log object dies. When the log object dies, it frees the
     * failed speculations list thus invalidating the
     * {@code HotSpotSpeculationLog#getFailedSpeculationsAddress() failed speculations address}
     * embedded in the nmethod. If the nmethod were to execute after this point and fail a
     * speculation, it would append the failed speculation to the already freed list.
     * <p>
     * Truffle ensures this cannot happen as it only attaches managed speculation logs to
     * {@link OptimizedCallTarget}s and {@link OptimizedOSRLoopNode}s. Executions of nmethods
     * compiled for an {@link OptimizedCallTarget} or {@link OptimizedOSRLoopNode} object will have
     * a strong reference to the object (i.e., as the receiver). This guarantees that such an
     * nmethod cannot be executing after the object has died.
     */
    @Override
    public SpeculationLog createSpeculationLog() {
        return new HotSpotSpeculationLog();
    }

    /**
     * Prevents C1 or C2 from inlining a call to and compiling a method annotated by
     * {@link TruffleCallBoundary} (i.e., <code>OptimizedCallTarget.callBoundary(Object[])</code>)
     * so that we never miss the chance to jump from the Truffle interpreter to compiled code.
     *
     * This is quite slow as it forces every call to
     * <code>OptimizedCallTarget.callBoundary(Object[])</code> to run in the HotSpot interpreter, so
     * later on we manually compile {@code callBoundary()} with Graal. This then lets a
     * C1/C2-compiled caller jump to Graal-compiled {@code callBoundary()}, instead of having to go
     * back to the HotSpot interpreter for every execution of {@code callBoundary()}.
     *
     * @see HotSpotTruffleCompiler#installTruffleCallBoundaryMethods(CompilableTruffleAST) which
     *      compiles callBoundary() with Graal
     */
    public static void setDontInlineCallBoundaryMethod(List<ResolvedJavaMethod> callBoundaryMethods) {
        for (ResolvedJavaMethod method : callBoundaryMethods) {
            setNotInlinableOrCompilable(method);
        }
    }

    static MetaAccessProvider getMetaAccess() {
        return JVMCI.getRuntime().getHostJVMCIBackend().getMetaAccess();
    }

    /**
     * Informs the VM to never compile or inline {@code method}.
     */
    private static void setNotInlinableOrCompilable(ResolvedJavaMethod method) {
        // JDK-8180487 and JDK-8186478 introduced breaking API changes so reflection is required.
        Method[] methods = HotSpotResolvedJavaMethod.class.getMethods();
        for (Method m : methods) {
            if (m.getName().equals("setNotInlineable") || m.getName().equals("setNotInlinableOrCompilable") || m.getName().equals("setNotInlineableOrCompileable")) {
                try {
                    m.invoke(method);
                    return;
                } catch (IllegalAccessException | IllegalArgumentException | InvocationTargetException e) {
                    throw new InternalError(e);
                }
            }
        }
        throw new InternalError(String.format(
                        "Could not find setNotInlineable, setNotInlinableOrCompilable or setNotInlineableOrCompileable in %s",
                        HotSpotResolvedJavaMethod.class));
    }

    @Override
    public BackgroundCompileQueue getCompileQueue() {
        return lazy();
    }

    @Override
    protected String getCompilerConfigurationName() {
        TruffleCompiler compiler = truffleCompiler;
        String compilerConfig;
        if (compiler != null) {
            compilerConfig = compiler.getCompilerConfigurationName();
            // disabled GR-10618
            // assert verifyCompilerConfiguration(compilerConfig);
        } else {
            compilerConfig = getLazyCompilerConfigurationName();
        }
        return compilerConfig;
    }

    @SuppressWarnings("unused")
    private boolean verifyCompilerConfiguration(String name) {
        String lazyName = getLazyCompilerConfigurationName();
        if (!name.equals(lazyName)) {
            throw new AssertionError("Expected compiler configuration name " + name + " but was " + lazyName + ".");
        }
        return true;
    }

    private String getLazyCompilerConfigurationName() {
        String compilerConfig = this.lazyConfigurationName;
        if (compilerConfig == null) {
            synchronized (this) {
                compilerConfig = this.lazyConfigurationName;
                if (compilerConfig == null) {
                    compilerConfig = initLazyCompilerConfigurationName();
                    this.lazyConfigurationName = compilerConfig;
                }
            }
        }
        return compilerConfig;
    }

    /**
     * Gets the compiler configuration name without requiring a compiler to be created.
     */
    protected abstract String initLazyCompilerConfigurationName();

    @SuppressWarnings("try")
    @Override
    public void bypassedInstalledCode(OptimizedCallTarget target) {
        if (!truffleCompilerInitialized) {
            // do not wait for initialization
            return;
        }
        getTruffleCompiler(target).installTruffleCallBoundaryMethods(target);
    }

    @Override
    protected CallMethods getCallMethods() {
        if (callMethods == null) {
            lookupCallMethods(getMetaAccess());
        }
        return callMethods;
    }

    @Override
    public void notifyTransferToInterpreter() {
        CompilerAsserts.neverPartOfCompilation();
        if (traceTransferToInterpreter) {
            TruffleCompiler compiler = truffleCompiler;
            assert compiler != null;
            TraceTransferToInterpreterHelper.traceTransferToInterpreter(this, (HotSpotTruffleCompiler) compiler);
        }
    }

    @Override
    public final boolean isProfilingEnabled() {
        if (profilingEnabled == null) {
            return true;
        }
        return profilingEnabled;
    }

    @Override
    protected JavaConstant forObject(final Object object) {
        final HotSpotConstantReflectionProvider constantReflection = (HotSpotConstantReflectionProvider) HotSpotJVMCIRuntime.runtime().getHostJVMCIBackend().getConstantReflection();
        return constantReflection.forObject(object);
    }

    @Override
    protected int getBaseInstanceSize(Class<?> type) {
        if (type.isArray() || type.isPrimitive()) {
            throw new IllegalArgumentException("Class " + type.getName() + " is a primitive type or an array class!");
        }

        HotSpotMetaAccessProvider meta = (HotSpotMetaAccessProvider) getMetaAccess();
        HotSpotResolvedObjectType resolvedType = (HotSpotResolvedObjectType) meta.lookupJavaType(type);
        return resolvedType.instanceSize();
    }

    private static boolean fieldIsNotEligible(Class<?> clazz, ResolvedJavaField f) {
        /*
         * "discovered" field of Reference class may reference unrelated objects that should not be
         * included. The condition is structured with the intention to minimize performance impact.
         * In any case, we have to check that the field is declared in the Reference class, because
         * the "discovered" field is private and so subclasses can have field of the same name.
         */
        return (Reference.class.isAssignableFrom(clazz) &&
                        f.getName().equals("discovered") && f.getDeclaringClass().isAssignableFrom(getMetaAccess().lookupJavaType(Reference.class)));
    }

    @Override
    protected Object[] getNonPrimitiveResolvedFields(Class<?> type) {
        if (type.isArray() || type.isPrimitive()) {
            throw new IllegalArgumentException("Class " + type.getName() + " is a primitive type or an array class!");
        }
        HotSpotMetaAccessProvider meta = (HotSpotMetaAccessProvider) getMetaAccess();
        ResolvedJavaType javaType = meta.lookupJavaType(type);
        ResolvedJavaField[] fields = javaType.getInstanceFields(true);
        ResolvedJavaField[] fieldsToReturn = new ResolvedJavaField[fields.length];
        int fieldsCount = 0;
        for (int i = 0; i < fields.length; i++) {
            final ResolvedJavaField f = fields[i];
            if (!f.getJavaKind().isPrimitive() && !fieldIsNotEligible(type, f)) {
                fieldsToReturn[fieldsCount++] = f;
            }
        }
        return Arrays.copyOf(fieldsToReturn, fieldsCount);
    }

    @SuppressWarnings("deprecation")
    @Override
    protected Object getFieldValue(ResolvedJavaField resolvedJavaField, Object obj) {
        assert obj != null;
        assert !resolvedJavaField.isStatic();
        assert resolvedJavaField.getJavaKind() == JavaKind.Object;
        assert resolvedJavaField.getDeclaringClass().isAssignableFrom(getMetaAccess().lookupJavaType(obj.getClass()));

        /*
         * The following code is extracted from
         * jdk.vm.ci.hotspot.HotSpotJDKReflection#readFieldValue(HotSpotResolvedJavaField, Object,
         * boolean) for this special case.
         */
        Object value;
        if (resolvedJavaField.isVolatile()) {
            value = UNSAFE.getObjectVolatile(obj, resolvedJavaField.getOffset());
        } else {
            value = UNSAFE.getObject(obj, resolvedJavaField.getOffset());
        }
        return value;
    }

    private <T> T getVMOptionValue(String name, Class<T> type) {
        try {
            return vmConfigAccess.getFlag(name, type);
        } catch (JVMCIError jvmciError) {
            // The option was not found. Throw rather IllegalArgumentException than JVMCIError
            throw new IllegalArgumentException(jvmciError);
        }
    }

    @Override
    protected int getObjectAlignment() {
        return getVMOptionValue("ObjectAlignmentInBytes", Integer.class);
    }

    @Override
    protected int getArrayIndexScale(Class<?> componentType) {
        MetaAccessProvider meta = getMetaAccess();
        ResolvedJavaType resolvedType = meta.lookupJavaType(componentType);

        return ((HotSpotJVMCIRuntime) JVMCI.getRuntime()).getArrayIndexScale(resolvedType.getJavaKind());
    }

    @Override
    protected int getArrayBaseOffset(Class<?> componentType) {
        MetaAccessProvider meta = getMetaAccess();
        ResolvedJavaType resolvedType = meta.lookupJavaType(componentType);

        return ((HotSpotJVMCIRuntime) JVMCI.getRuntime()).getArrayBaseOffset(resolvedType.getJavaKind());
    }

    @Override
    protected <T> T asObject(final Class<T> type, final JavaConstant constant) {
        if (constant.isNull()) {
            return null;
        }
        final HotSpotObjectConstant hsConstant = (HotSpotObjectConstant) constant;
        return hsConstant.asObject(type);
    }

    private static class TraceTransferToInterpreterHelper {
        private static final long THREAD_EETOP_OFFSET;

        static {
            try {
                THREAD_EETOP_OFFSET = UNSAFE.objectFieldOffset(Thread.class.getDeclaredField("eetop"));
            } catch (Exception e) {
                throw new InternalError(e);
            }
        }

        static void traceTransferToInterpreter(AbstractHotSpotTruffleRuntime runtime, HotSpotTruffleCompiler compiler) {
            FrameInstance currentFrame = runtime.getCurrentFrame();
            if (currentFrame == null) {
                return;
            }
            OptimizedCallTarget callTarget = (OptimizedCallTarget) currentFrame.getCallTarget();
            long thread = UNSAFE.getLong(Thread.currentThread(), THREAD_EETOP_OFFSET);
            long pendingTransferToInterpreterAddress = thread + compiler.pendingTransferToInterpreterOffset(callTarget);
            boolean deoptimized = UNSAFE.getByte(pendingTransferToInterpreterAddress) != 0;
            if (deoptimized) {
                logTransferToInterpreter(runtime, callTarget);
                UNSAFE.putByte(pendingTransferToInterpreterAddress, (byte) 0);
            }
        }

        private static String formatStackFrame(FrameInstance frameInstance, CallTarget target) {
            StringBuilder builder = new StringBuilder();
            if (target instanceof RootCallTarget) {
                RootNode root = ((RootCallTarget) target).getRootNode();
                String name = root.getName();
                if (name == null) {
                    builder.append("unnamed-root");
                } else {
                    builder.append(name);
                }
                Node callNode = frameInstance.getCallNode();
                SourceSection sourceSection = null;
                if (callNode != null) {
                    sourceSection = callNode.getEncapsulatingSourceSection();
                }
                if (sourceSection == null) {
                    sourceSection = root.getSourceSection();
                }

                if (sourceSection == null || sourceSection.getSource() == null) {
                    builder.append("(Unknown)");
                } else {
                    builder.append("(").append(formatPath(sourceSection)).append(":").append(sourceSection.getStartLine()).append(")");
                }

                if (target instanceof OptimizedCallTarget) {
                    OptimizedCallTarget callTarget = ((OptimizedCallTarget) target);
                    if (callTarget.getSourceCallTarget() != null) {
                        builder.append(" <split-" + Integer.toHexString(callTarget.hashCode()) + ">");
                    }
                }

            } else {
                builder.append(target.toString());
            }
            return builder.toString();
        }

        private static String formatPath(SourceSection sourceSection) {
            if (sourceSection.getSource().getPath() != null) {
                Path path = FileSystems.getDefault().getPath(".").toAbsolutePath();
                Path filePath = FileSystems.getDefault().getPath(sourceSection.getSource().getPath()).toAbsolutePath();

                try {
                    return path.relativize(filePath).toString();
                } catch (IllegalArgumentException e) {
                    // relativization failed
                }
            }
            return sourceSection.getSource().getName();
        }

        private static void logTransferToInterpreter(AbstractHotSpotTruffleRuntime runtime, OptimizedCallTarget callTarget) {
            final int limit = callTarget.getOptionValue(PolyglotCompilerOptions.TraceStackTraceLimit);
            StringBuilder messageBuilder = new StringBuilder();
            messageBuilder.append("transferToInterpreter at\n");
            runtime.iterateFrames(new FrameInstanceVisitor<Object>() {
                int frameIndex = 0;

                @Override
                public Object visitFrame(FrameInstance frameInstance) {
                    CallTarget target = frameInstance.getCallTarget();
                    StringBuilder line = new StringBuilder("  ");
                    if (frameIndex > 0) {
                        line.append("  ");
                    }
                    line.append(formatStackFrame(frameInstance, target)).append("\n");
                    frameIndex++;

                    messageBuilder.append(line);
                    if (frameIndex < limit) {
                        return null;
                    } else {
                        messageBuilder.append("    ...\n");
                        return frameInstance;
                    }
                }

            });
            final int skip = 3;
            StackTraceElement[] stackTrace = new Throwable().getStackTrace();
            String suffix = stackTrace.length > skip + limit ? "\n    ..." : "";
            messageBuilder.append(Arrays.stream(stackTrace).skip(skip).limit(limit).map(StackTraceElement::toString).collect(Collectors.joining("\n    ", "  ", suffix)));
            runtime.log(callTarget, messageBuilder.toString());
        }
    }

    public static AbstractHotSpotTruffleRuntime getRuntime() {
        return (AbstractHotSpotTruffleRuntime) GraalTruffleRuntime.getRuntime();
    }
}
