module llvm.functions.link;

import std.array : array;
import std.algorithm.iteration : map, joiner;
import std.range : chain;

import llvm.config;
import llvm.types;
import core.stdc.stdint;

private nothrow auto orEmpty(T)(T v)
{
    return v? v : "";
}

__gshared extern(System) nothrow:

/+ Analysis +/

LLVMBool LLVMVerifyModule(LLVMModuleRef M, LLVMVerifierFailureAction Action, char** OutMessage);
LLVMBool LLVMVerifyFunction(LLVMValueRef Fn, LLVMVerifierFailureAction Action);
void LLVMViewFunctionCFG(LLVMValueRef Fn);
void LLVMViewFunctionCFGOnly(LLVMValueRef Fn);

/+ Bit Reader +/

static if (LLVM_Version < asVersion(3, 9, 0)) {
    LLVMBool LLVMParseBitcode(LLVMMemoryBufferRef MemBuf, LLVMModuleRef* OutModule, char** OutMessage);
}

static if (LLVM_Version >= asVersion(3, 8, 0)) {
    LLVMBool LLVMParseBitcode2(LLVMMemoryBufferRef MemBuf, LLVMModuleRef* OutModule);
}

static if (LLVM_Version < asVersion(3, 9, 0)) {
    LLVMBool LLVMParseBitcodeInContext(LLVMContextRef ContextRef, LLVMMemoryBufferRef MemBuf, LLVMModuleRef* OutModule, char** OutMessage);
}

static if (LLVM_Version >= asVersion(3, 8, 0)) {
    LLVMBool LLVMParseBitcodeInContext2(LLVMContextRef ContextRef, LLVMMemoryBufferRef MemBuf, LLVMModuleRef* OutModule);
}

static if (LLVM_Version < asVersion(3, 9, 0)) {
    LLVMBool LLVMGetBitcodeModuleInContext(LLVMContextRef ContextRef, LLVMMemoryBufferRef MemBuf, LLVMModuleRef* OutM, char** OutMessage);
}

static if (LLVM_Version >= asVersion(3, 8, 0)) {
    LLVMBool LLVMGetBitcodeModuleInContext2(LLVMContextRef ContextRef, LLVMMemoryBufferRef MemBuf, LLVMModuleRef* OutM);
}

static if (LLVM_Version < asVersion(3, 9, 0)) {
    LLVMBool LLVMGetBitcodeModule(LLVMMemoryBufferRef MemBuf, LLVMModuleRef* OutM, char** OutMessage);
}

static if (LLVM_Version >= asVersion(3, 8, 0)) {
    LLVMBool LLVMGetBitcodeModule2(LLVMMemoryBufferRef MemBuf, LLVMModuleRef* OutM);
}

static if (LLVM_Version < asVersion(3, 8, 0)) {
    LLVMBool LLVMGetBitcodeModuleProviderInContext(LLVMContextRef ContextRef, LLVMMemoryBufferRef MemBuf, LLVMModuleProviderRef* OutMP, char** OutMessage);
}

static if (LLVM_Version < asVersion(3, 8, 0)) {
    LLVMBool LLVMGetBitcodeModuleProvider(LLVMMemoryBufferRef MemBuf, LLVMModuleProviderRef* OutMP, char** OutMessage);
}

/+ Bit Writer +/

int LLVMWriteBitcodeToFile(LLVMModuleRef M, const(char)* Path);
int LLVMWriteBitcodeToFD(LLVMModuleRef M, int FD, int ShouldClose, int Unbuffered);
int LLVMWriteBitcodeToFileHandle(LLVMModuleRef M, int Handle);
static if (LLVM_Version >= asVersion(3, 6, 0)) {
    LLVMMemoryBufferRef LLVMWriteBitcodeToMemoryBuffer(LLVMModuleRef M);
}

/+ Transforms +/

/++ Interprocedural transformations ++/

void LLVMAddArgumentPromotionPass(LLVMPassManagerRef PM);
void LLVMAddConstantMergePass(LLVMPassManagerRef PM);
static if (LLVM_Version >= asVersion(10, 0, 0)) {
	void LLVMAddMergeFunctionsPass(LLVMPassManagerRef PM);
}
static if (LLVM_Version >= asVersion(6, 0, 0)) {
	void LLVMAddCalledValuePropagationPass(LLVMPassManagerRef PM);
}
void LLVMAddDeadArgEliminationPass(LLVMPassManagerRef PM);
void LLVMAddFunctionAttrsPass(LLVMPassManagerRef PM);
void LLVMAddFunctionInliningPass(LLVMPassManagerRef PM);
void LLVMAddAlwaysInlinerPass(LLVMPassManagerRef PM);
void LLVMAddGlobalDCEPass(LLVMPassManagerRef PM);
void LLVMAddGlobalOptimizerPass(LLVMPassManagerRef PM);
void LLVMAddIPConstantPropagationPass(LLVMPassManagerRef PM);
void LLVMAddPruneEHPass(LLVMPassManagerRef PM);
void LLVMAddIPSCCPPass(LLVMPassManagerRef PM);
void LLVMAddInternalizePass(LLVMPassManagerRef, uint AllButMain);
static if (LLVM_Version >= asVersion(10, 0, 0)) {
	void LLVMAddInternalizePassWithMustPreservePredicate( LLVMPassManagerRef PM, void* Context, MustPreserveCallback MustPreserve);
}
void LLVMAddStripDeadPrototypesPass(LLVMPassManagerRef PM);
void LLVMAddStripSymbolsPass(LLVMPassManagerRef PM);

/++ Pass manager builder ++/

LLVMPassManagerBuilderRef LLVMPassManagerBuilderCreate();
void LLVMPassManagerBuilderDispose(LLVMPassManagerBuilderRef PMB);
void LLVMPassManagerBuilderSetOptLevel(LLVMPassManagerBuilderRef PMB, uint OptLevel);
void LLVMPassManagerBuilderSetSizeLevel(LLVMPassManagerBuilderRef PMB, uint SizeLevel);
void LLVMPassManagerBuilderSetDisableUnitAtATime(LLVMPassManagerBuilderRef PMB, LLVMBool Value);
void LLVMPassManagerBuilderSetDisableUnrollLoops(LLVMPassManagerBuilderRef PMB, LLVMBool Value);
void LLVMPassManagerBuilderSetDisableSimplifyLibCalls(LLVMPassManagerBuilderRef PMB, LLVMBool Value);
void LLVMPassManagerBuilderUseInlinerWithThreshold(LLVMPassManagerBuilderRef PMB, uint Threshold);
void LLVMPassManagerBuilderPopulateFunctionPassManager(LLVMPassManagerBuilderRef PMB, LLVMPassManagerRef PM);
void LLVMPassManagerBuilderPopulateModulePassManager(LLVMPassManagerBuilderRef PMB, LLVMPassManagerRef PM);
void LLVMPassManagerBuilderPopulateLTOPassManager(LLVMPassManagerBuilderRef PMB, LLVMPassManagerRef PM, LLVMBool Internalize, LLVMBool RunInliner);

/++ Scalar transformations ++/

void LLVMAddAggressiveDCEPass(LLVMPassManagerRef PM);
static if (LLVM_Version >= asVersion(10, 0, 0)) {
    void LLVMAddDCEPass(LLVMPassManagerRef PM);
}
static if (LLVM_Version >= asVersion(7, 0, 0) && LLVM_Version < asVersion(8, 0, 0)) {
    void LLVMAddAggressiveInstCombinerPass(LLVMPassManagerRef PM);
}
static if (LLVM_Version >= asVersion(3, 7, 0)) {
    void LLVMAddBitTrackingDCEPass(LLVMPassManagerRef PM);
}
static if (LLVM_Version >= asVersion(3, 6, 0)) {
    void LLVMAddAlignmentFromAssumptionsPass(LLVMPassManagerRef PM);
}
void LLVMAddCFGSimplificationPass(LLVMPassManagerRef PM);
static if (LLVM_Version >= asVersion(5, 0, 0) && LLVM_Version < asVersion(6, 0, 0)) {
	void LLVMAddLateCFGSimplificationPass(LLVMPassManagerRef PM);
}
void LLVMAddDeadStoreEliminationPass(LLVMPassManagerRef PM);
static if (LLVM_Version >= asVersion(3, 5, 0)) {
    void LLVMAddScalarizerPass(LLVMPassManagerRef PM);
}
static if (LLVM_Version >= asVersion(3, 5, 0)) {
    void LLVMAddMergedLoadStoreMotionPass(LLVMPassManagerRef PM);
}
void LLVMAddGVNPass(LLVMPassManagerRef PM);
static if (LLVM_Version >= asVersion(4, 0, 0)) {
	void LLVMAddNewGVNPass(LLVMPassManagerRef PM);
}
void LLVMAddIndVarSimplifyPass(LLVMPassManagerRef PM);
void LLVMAddInstructionCombiningPass(LLVMPassManagerRef PM);
void LLVMAddJumpThreadingPass(LLVMPassManagerRef PM);
void LLVMAddLICMPass(LLVMPassManagerRef PM);
void LLVMAddLoopDeletionPass(LLVMPassManagerRef PM);
void LLVMAddLoopIdiomPass(LLVMPassManagerRef PM);
void LLVMAddLoopRotatePass(LLVMPassManagerRef PM);
static if (LLVM_Version >= asVersion(3, 4, 0)) {
    void LLVMAddLoopRerollPass(LLVMPassManagerRef PM);
}
void LLVMAddLoopUnrollPass(LLVMPassManagerRef PM);
void LLVMAddLoopUnswitchPass(LLVMPassManagerRef PM);
static if (LLVM_Version >= asVersion(8, 0, 0)) {
    void LLVMAddLowerAtomicPass(LLVMPassManagerRef PM);
}
void LLVMAddMemCpyOptPass(LLVMPassManagerRef PM);
static if (LLVM_Version >= asVersion(3, 4, 0)) {
    void LLVMAddPartiallyInlineLibCallsPass(LLVMPassManagerRef PM);
}
static if (LLVM_Version >= asVersion(3, 6, 0)) {
    void LLVMAddLowerSwitchPass(LLVMPassManagerRef PM);
}
void LLVMAddPromoteMemoryToRegisterPass(LLVMPassManagerRef PM);
static if (LLVM_Version >= asVersion(9, 0, 0)) {
    void LLVMAddAddDiscriminatorsPass(LLVMPassManagerRef PM);
}
void LLVMAddReassociatePass(LLVMPassManagerRef PM);
void LLVMAddSCCPPass(LLVMPassManagerRef PM);
void LLVMAddScalarReplAggregatesPass(LLVMPassManagerRef PM);
void LLVMAddScalarReplAggregatesPassSSA(LLVMPassManagerRef PM);
void LLVMAddScalarReplAggregatesPassWithThreshold(LLVMPassManagerRef PM, int Threshold);
void LLVMAddSimplifyLibCallsPass(LLVMPassManagerRef PM);
void LLVMAddTailCallEliminationPass(LLVMPassManagerRef PM);
void LLVMAddConstantPropagationPass(LLVMPassManagerRef PM);
void LLVMAddDemoteMemoryToRegisterPass(LLVMPassManagerRef PM);
void LLVMAddVerifierPass(LLVMPassManagerRef PM);
void LLVMAddCorrelatedValuePropagationPass(LLVMPassManagerRef PM);
void LLVMAddEarlyCSEPass(LLVMPassManagerRef PM);
static if (LLVM_Version >= asVersion(4, 0, 0)) {
	void LLVMAddEarlyCSEMemSSAPass(LLVMPassManagerRef PM);
}
void LLVMAddLowerExpectIntrinsicPass(LLVMPassManagerRef PM);
static if (LLVM_Version >= asVersion(10, 0, 0)) {
    void LLVMAddLowerConstantIntrinsicsPass(LLVMPassManagerRef PM);
}
void LLVMAddTypeBasedAliasAnalysisPass(LLVMPassManagerRef PM);
static if (LLVM_Version >= asVersion(3, 6, 0)) {
    void LLVMAddScopedNoAliasAAPass(LLVMPassManagerRef PM);
}
void LLVMAddBasicAliasAnalysisPass(LLVMPassManagerRef PM);
static if (LLVM_Version >= asVersion(8, 0, 0)) {
    void LLVMAddUnifyFunctionExitNodesPass(LLVMPassManagerRef PM);
}

/++ Vectorization transformations ++/

static if (LLVM_Version < asVersion(7, 0, 0)) {
	void LLVMAddBBVectorizePass(LLVMPassManagerRef PM);
}
static if (LLVM_Version >= asVersion(3, 2, 0)) {
    void LLVMAddLoopVectorizePass(LLVMPassManagerRef PM);
}

/+ Core +/

static if (LLVM_Version >= asVersion(3, 3, 0)) {
    void LLVMShutdown();
}
static if (LLVM_Version >= asVersion(3, 4, 0)) {
    char* LLVMCreateMessage(const(char)* Message);
}
void LLVMDisposeMessage(char* Message);
static if (LLVM_Version >= asVersion(3, 4, 0)) {
    void LLVMInstallFatalErrorHandler(LLVMFatalErrorHandler Handler);
}
static if (LLVM_Version >= asVersion(3, 4, 0)) {
    void LLVMResetFatalErrorHandler();
}
static if (LLVM_Version >= asVersion(3, 4, 0)) {
    void LLVMEnablePrettyStackTrace();
}

/++ Contexts ++/

LLVMContextRef LLVMContextCreate();
LLVMContextRef LLVMGetGlobalContext();
void LLVMContextDispose(LLVMContextRef C);
uint LLVMGetMDKindIDInContext(LLVMContextRef C, const(char)* Name, uint SLen);
uint LLVMGetMDKindID(const(char)* Name, uint SLen);


static if (LLVM_Version >= asVersion(3, 9, 0)) {
    uint LLVMGetEnumAttributeKindForName(const(char)*Name, size_t SLen);
}
static if (LLVM_Version >= asVersion(3, 9, 0)) {
    uint LLVMGetLastEnumAttributeKind();
}
static if (LLVM_Version >= asVersion(3, 9, 0)) {
    LLVMAttributeRef LLVMCreateEnumAttribute(LLVMContextRef C, uint KindID, ulong Val);
}
static if (LLVM_Version >= asVersion(3, 9, 0)) {
    uint LLVMGetEnumAttributeKind(LLVMAttributeRef A);
}
static if (LLVM_Version >= asVersion(3, 9, 0)) {
    ulong LLVMGetEnumAttributeValue(LLVMAttributeRef A);
}
static if (LLVM_Version >= asVersion(3, 9, 0)) {
    LLVMAttributeRef LLVMCreateStringAttribute(LLVMContextRef C, const(char)*K, uint KLength, const(char)*V, uint VLength);
}
static if (LLVM_Version >= asVersion(3, 9, 0)) {
    const(char)* LLVMGetStringAttributeKind(LLVMAttributeRef A, uint *Length);
}
static if (LLVM_Version >= asVersion(3, 9, 0)) {
    const(char)* LLVMGetStringAttributeValue(LLVMAttributeRef A, uint *Length);
}
static if (LLVM_Version >= asVersion(3, 9, 0)) {
    LLVMBool LLVMIsEnumAttribute(LLVMAttributeRef A);
}
static if (LLVM_Version >= asVersion(3, 9, 0)) {
    LLVMBool LLVMIsStringAttribute(LLVMAttributeRef A);
}

static if (LLVM_Version >= asVersion(3, 5, 0)) {
    void LLVMContextSetDiagnosticHandler (LLVMContextRef C, LLVMDiagnosticHandler Handler, void *DiagnosticContext);
}

static if (LLVM_Version >= asVersion(3, 9, 0)) {
    LLVMDiagnosticHandler LLVMContextGetDiagnosticHandler(LLVMContextRef C);
}
static if (LLVM_Version >= asVersion(3, 9, 0)) {
    void* LLVMContextGetDiagnosticContext(LLVMContextRef C);
}

static if (LLVM_Version >= asVersion(3, 5, 0)) {
    char* LLVMGetDiagInfoDescription(LLVMDiagnosticInfoRef DI);
}

static if (LLVM_Version >= asVersion(3, 5, 0)) {
    LLVMDiagnosticSeverity LLVMGetDiagInfoSeverity(LLVMDiagnosticInfoRef DI);
}
static if (LLVM_Version >= asVersion(3, 5, 0)) {
    void LLVMContextSetYieldCallback(LLVMContextRef C, LLVMYieldCallback Callback, void *OpaqueHandle);
}

static if (LLVM_Version >= asVersion(8, 0, 0)) {
    LLVMBool LLVMContextShouldDiscardValueNames(LLVMContextRef C);
    void LLVMContextSetDiscardValueNames(LLVMContextRef C, LLVMBool Discard);
}

/++ Modules ++/

LLVMModuleRef LLVMModuleCreateWithName(const(char)* ModuleID);
LLVMModuleRef LLVMModuleCreateWithNameInContext(const(char)* ModuleID, LLVMContextRef C);
static if (LLVM_Version >= asVersion(3, 6, 0)) {
    LLVMModuleRef LLVMCloneModule(LLVMModuleRef M);
}
void LLVMDisposeModule(LLVMModuleRef M);

static if (LLVM_Version >= asVersion(3, 9, 0)) {
    const(char)* LLVMGetModuleIdentifier(LLVMModuleRef M, size_t *Len);
}
static if (LLVM_Version >= asVersion(3, 9, 0)) {
    void LLVMSetModuleIdentifier(LLVMModuleRef M, const(char)* Ident, size_t Len);
}

const(char)* LLVMGetDataLayout(LLVMModuleRef M);

static if (LLVM_Version >= asVersion(3, 9, 0)) {
    const(char)* LLVMGetDataLayoutStr(LLVMModuleRef M);
}

void LLVMSetDataLayout(LLVMModuleRef M, const(char)* Triple);
const(char)* LLVMGetTarget(LLVMModuleRef M);
void LLVMSetTarget(LLVMModuleRef M, const(char)* Triple);
void LLVMDumpModule(LLVMModuleRef M);
static if (LLVM_Version >= asVersion(3, 2, 0)) {
    LLVMBool LLVMPrintModuleToFile(LLVMModuleRef M, const(char)* Filename, char** ErrorMessage);
}
static if (LLVM_Version >= asVersion(3, 4, 0)) {
    char* LLVMPrintModuleToString(LLVMModuleRef M);
}

static if (LLVM_Version >= asVersion(7, 0, 0)) {
	void LLVMSetModuleInlineAsm2(LLVMModuleRef M, const(char)* Asm, size_t Len);
}

static if (LLVM_Version >= asVersion(7, 0, 0)) {
	deprecated("Use LLVMSetModuleInlineAsm2 instead.") void LLVMSetModuleInlineAsm(LLVMModuleRef M, const(char)* Asm);
} else {
	void LLVMSetModuleInlineAsm(LLVMModuleRef M, const(char)* Asm);
}

LLVMContextRef LLVMGetModuleContext(LLVMModuleRef M);
LLVMTypeRef LLVMGetTypeByName(LLVMModuleRef M, const(char)* Name);
static if (LLVM_Version >= asVersion(8, 0, 0)) {
    LLVMNamedMDNodeRef LLVMGetFirstNamedMetadata(LLVMModuleRef M);

    LLVMNamedMDNodeRef LLVMGetLastNamedMetadata(LLVMModuleRef M);

    LLVMNamedMDNodeRef LLVMGetNextNamedMetadata(LLVMNamedMDNodeRef NamedMDNode);

    LLVMNamedMDNodeRef LLVMGetPreviousNamedMetadata(LLVMNamedMDNodeRef NamedMDNode);

    LLVMNamedMDNodeRef LLVMGetNamedMetadata(LLVMModuleRef M,
                                            const(char)* Name, size_t NameLen);

    LLVMNamedMDNodeRef LLVMGetOrInsertNamedMetadata(LLVMModuleRef M,
                                                    const(char)* Name,
                                                    size_t NameLen);

    const(char)* LLVMGetNamedMetadataName(LLVMNamedMDNodeRef NamedMD,
                                          size_t* NameLen);
}
uint LLVMGetNamedMetadataNumOperands(LLVMModuleRef M, const(char)* name);
void LLVMGetNamedMetadataOperands(LLVMModuleRef M, const(char)* name, LLVMValueRef *Dest);
void LLVMAddNamedMetadataOperand(LLVMModuleRef M, const(char)* name, LLVMValueRef Val);
static if (LLVM_Version >= asVersion(8, 0, 0)) {
    const(char)* LLVMGetDebugLocDirectory(LLVMValueRef Val, uint* Length);

    const(char)* LLVMGetDebugLocFilename(LLVMValueRef Val, uint* Length);

    uint LLVMGetDebugLocLine(LLVMValueRef Val);

    uint LLVMGetDebugLocColumn(LLVMValueRef Val);
}
LLVMValueRef LLVMAddFunction(LLVMModuleRef M, const(char)* Name, LLVMTypeRef FunctionTy);
LLVMValueRef LLVMGetNamedFunction(LLVMModuleRef M, const(char)* Name);
LLVMValueRef LLVMGetFirstFunction(LLVMModuleRef M);
LLVMValueRef LLVMGetLastFunction(LLVMModuleRef M);
LLVMValueRef LLVMGetNextFunction(LLVMValueRef Fn);
LLVMValueRef LLVMGetPreviousFunction(LLVMValueRef Fn);

/++ Types ++/

LLVMTypeKind LLVMGetTypeKind(LLVMTypeRef Ty);
LLVMBool LLVMTypeIsSized(LLVMTypeRef Ty);
LLVMContextRef LLVMGetTypeContext(LLVMTypeRef Ty);
static if (LLVM_Version >= asVersion(3, 4, 0)) {
    void LLVMDumpType(LLVMTypeRef Val);
}
static if (LLVM_Version >= asVersion(3, 4, 0)) {
    char* LLVMPrintTypeToString(LLVMTypeRef Val);
}

/+++ Integer Types +++/

LLVMTypeRef LLVMInt1TypeInContext(LLVMContextRef C);
LLVMTypeRef LLVMInt8TypeInContext(LLVMContextRef C);
LLVMTypeRef LLVMInt16TypeInContext(LLVMContextRef C);
LLVMTypeRef LLVMInt32TypeInContext(LLVMContextRef C);
LLVMTypeRef LLVMInt64TypeInContext(LLVMContextRef C);
static if (LLVM_Version >= asVersion(3, 8, 0)) {
    LLVMTypeRef LLVMInt128TypeInContext(LLVMContextRef C);
}
LLVMTypeRef LLVMIntTypeInContext(LLVMContextRef C, uint NumBits);
LLVMTypeRef LLVMInt1Type();
LLVMTypeRef LLVMInt8Type();
LLVMTypeRef LLVMInt16Type();
LLVMTypeRef LLVMInt32Type();
LLVMTypeRef LLVMInt64Type();
static if (LLVM_Version >= asVersion(3, 8, 0)) {
    LLVMTypeRef LLVMInt128Type();
}
LLVMTypeRef LLVMIntType(uint NumBits);
uint LLVMGetIntTypeWidth(LLVMTypeRef IntegerTy);

/+++ Floating Point Types +++/

LLVMTypeRef LLVMHalfTypeInContext(LLVMContextRef C);
LLVMTypeRef LLVMFloatTypeInContext(LLVMContextRef C);
LLVMTypeRef LLVMDoubleTypeInContext(LLVMContextRef C);
LLVMTypeRef LLVMX86FP80TypeInContext(LLVMContextRef C);
LLVMTypeRef LLVMFP128TypeInContext(LLVMContextRef C);
LLVMTypeRef LLVMPPCFP128TypeInContext(LLVMContextRef C);
LLVMTypeRef LLVMHalfType();
LLVMTypeRef LLVMFloatType();
LLVMTypeRef LLVMDoubleType();
LLVMTypeRef LLVMX86FP80Type();
LLVMTypeRef LLVMFP128Type();
LLVMTypeRef LLVMPPCFP128Type();

/+++ Function Types +++/

LLVMTypeRef LLVMFunctionType(LLVMTypeRef ReturnType, LLVMTypeRef* ParamTypes, uint ParamCount, LLVMBool IsVarArg);
LLVMBool LLVMIsFunctionVarArg(LLVMTypeRef FunctionTy);
LLVMTypeRef LLVMGetReturnType(LLVMTypeRef FunctionTy);
uint LLVMCountParamTypes(LLVMTypeRef FunctionTy);
void LLVMGetParamTypes(LLVMTypeRef FunctionTy, LLVMTypeRef* Dest);

/+++ Structure Types +++/

LLVMTypeRef LLVMStructTypeInContext(LLVMContextRef C, LLVMTypeRef* ElementTypes, uint ElementCount, LLVMBool Packed);
LLVMTypeRef LLVMStructType(LLVMTypeRef* ElementTypes, uint ElementCount, LLVMBool Packed);
LLVMTypeRef LLVMStructCreateNamed(LLVMContextRef C, const(char)* Name);
const(char)* LLVMGetStructName(LLVMTypeRef Ty);
void LLVMStructSetBody(LLVMTypeRef StructTy, LLVMTypeRef* ElementTypes, uint ElementCount, LLVMBool Packed);
uint LLVMCountStructElementTypes(LLVMTypeRef StructTy);
void LLVMGetStructElementTypes(LLVMTypeRef StructTy, LLVMTypeRef* Dest);
static if (LLVM_Version >= asVersion(3, 7, 0)) {
    LLVMTypeRef LLVMStructGetTypeAtIndex(LLVMTypeRef StructTy, uint i);
}
LLVMBool LLVMIsPackedStruct(LLVMTypeRef StructTy);
LLVMBool LLVMIsOpaqueStruct(LLVMTypeRef StructTy);
static if (LLVM_Version >= asVersion(8, 0, 0)) {
    LLVMBool LLVMIsLiteralStruct(LLVMTypeRef StructTy);
}

/+++ Sequential Types +++/

LLVMTypeRef LLVMGetElementType(LLVMTypeRef Ty);
static if (LLVM_Version >= asVersion(5,0,0)) {
	void LLVMGetSubtypes(LLVMTypeRef Tp, LLVMTypeRef* Arr);
}
static if (LLVM_Version >= asVersion(5,0,0)) {
	uint LLVMGetNumContainedTypes(LLVMTypeRef Tp);
}
LLVMTypeRef LLVMArrayType(LLVMTypeRef ElementType, uint ElementCount);
uint LLVMGetArrayLength(LLVMTypeRef ArrayTy);
LLVMTypeRef LLVMPointerType(LLVMTypeRef ElementType, uint AddressSpace);
uint LLVMGetPointerAddressSpace(LLVMTypeRef PointerTy);
LLVMTypeRef LLVMVectorType(LLVMTypeRef ElementType, uint ElementCount);
uint LLVMGetVectorSize(LLVMTypeRef VectorTy);

/+++ Other Types +++/

LLVMTypeRef LLVMVoidTypeInContext(LLVMContextRef C);
LLVMTypeRef LLVMLabelTypeInContext(LLVMContextRef C);
LLVMTypeRef LLVMX86MMXTypeInContext(LLVMContextRef C);
static if (LLVM_Version >= asVersion(6, 0, 0)) {
	LLVMTypeRef LLVMTokenTypeInContext(LLVMContextRef C);
}
static if (LLVM_Version >= asVersion(6, 0, 0)) {
	LLVMTypeRef LLVMMetadataTypeInContext(LLVMContextRef C);
}
LLVMTypeRef LLVMVoidType();
LLVMTypeRef LLVMLabelType();
LLVMTypeRef LLVMX86MMXType();

/++ Values ++/

/+++ General APIs +++/

LLVMTypeRef LLVMTypeOf(LLVMValueRef Val);
static if (LLVM_Version >= asVersion(3, 9, 0)) {
    LLVMValueKind LLVMGetValueKind(LLVMValueRef Val);
}

static if (LLVM_Version >= asVersion(7, 0, 0)) {
	const(char)* LLVMGetValueName2(LLVMValueRef Val, size_t* Length);
}

static if (LLVM_Version >= asVersion(7, 0, 0)) {
	deprecated("Use LLVMGetValueName2 instead.") const(char)* LLVMGetValueName(LLVMValueRef Val);
} else {
	const(char)* LLVMGetValueName(LLVMValueRef Val);
}

static if (LLVM_Version >= asVersion(7, 0, 0)) {
	void LLVMSetValueName2(LLVMValueRef Val, const(char*) Name, size_t NameLen);
}

static if (LLVM_Version >= asVersion(7, 0, 0)) {
	deprecated("Use LLVMSetValueName2 instead.")void LLVMSetValueName(LLVMValueRef Val, const(char)* Name);
} else {
	void LLVMSetValueName(LLVMValueRef Val, const(char)* Name);
}

void LLVMDumpValue(LLVMValueRef Val);
static if (LLVM_Version >= asVersion(3, 4, 0)) {
    char* LLVMPrintValueToString(LLVMValueRef Val);
}
void LLVMReplaceAllUsesWith(LLVMValueRef OldVal, LLVMValueRef NewVal);
LLVMBool LLVMIsConstant(LLVMValueRef Val);
LLVMBool LLVMIsUndef(LLVMValueRef Val);

LLVMValueRef LLVMIsAAllocaInst(LLVMValueRef Val);
LLVMValueRef LLVMIsAArgument(LLVMValueRef Val);
LLVMValueRef LLVMIsABasicBlock(LLVMValueRef Val);
static if (LLVM_Version >= asVersion(10, 0, 0)) {
    LLVMValueRef LLVMIsAUnaryOperator(LLVMValueRef Val);
}
LLVMValueRef LLVMIsABinaryOperator(LLVMValueRef Val);
LLVMValueRef LLVMIsABitCastInst(LLVMValueRef Val);
LLVMValueRef LLVMIsABlockAddress(LLVMValueRef Val);
LLVMValueRef LLVMIsABranchInst(LLVMValueRef Val);
LLVMValueRef LLVMIsACallInst(LLVMValueRef Val);
LLVMValueRef LLVMIsACastInst(LLVMValueRef Val);
static if (LLVM_Version >= asVersion(3, 4, 0)) {
    LLVMValueRef LLVMIsAAddrSpaceCastInst(LLVMValueRef Val);
}
LLVMValueRef LLVMIsACmpInst(LLVMValueRef Val);
LLVMValueRef LLVMIsAConstantAggregateZero(LLVMValueRef Val);
LLVMValueRef LLVMIsAConstantArray(LLVMValueRef Val);
static if (LLVM_Version >= asVersion(3, 4, 0)) {
    LLVMValueRef LLVMIsAConstantDataSequential(LLVMValueRef Val);
}
static if (LLVM_Version >= asVersion(3, 4, 0)) {
    LLVMValueRef LLVMIsAConstantDataArray(LLVMValueRef Val);
}
static if (LLVM_Version >= asVersion(3, 4, 0)) {
    LLVMValueRef LLVMIsAConstantDataVector(LLVMValueRef Val);
}

LLVMValueRef LLVMIsAConstantExpr(LLVMValueRef Val);
LLVMValueRef LLVMIsAConstantFP(LLVMValueRef Val);
LLVMValueRef LLVMIsAConstantInt(LLVMValueRef Val);
LLVMValueRef LLVMIsAConstant(LLVMValueRef Val);
LLVMValueRef LLVMIsAConstantPointerNull(LLVMValueRef Val);
LLVMValueRef LLVMIsAConstantStruct(LLVMValueRef Val);
static if (LLVM_Version >= asVersion(3, 8, 0)) {
    LLVMValueRef LLVMIsAConstantTokenNone(LLVMValueRef Val);
}
LLVMValueRef LLVMIsAConstantVector(LLVMValueRef Val);
static if (LLVM_Version >= asVersion(8, 0, 0)) {
    LLVMValueRef LLVMIsADbgVariableIntrinsic(LLVMValueRef Val);
}
LLVMValueRef LLVMIsADbgDeclareInst(LLVMValueRef Val);
static if (LLVM_Version >= asVersion(8, 0, 0)) {
    LLVMValueRef LLVMIsADbgLabelInst(LLVMValueRef Val);
}
LLVMValueRef LLVMIsADbgInfoIntrinsic(LLVMValueRef Val);
LLVMValueRef LLVMIsAExtractElementInst(LLVMValueRef Val);
LLVMValueRef LLVMIsAExtractValueInst(LLVMValueRef Val);
LLVMValueRef LLVMIsAFCmpInst(LLVMValueRef Val);
LLVMValueRef LLVMIsAFPExtInst(LLVMValueRef Val);
LLVMValueRef LLVMIsAFPToSIInst(LLVMValueRef Val);
LLVMValueRef LLVMIsAFPToUIInst(LLVMValueRef Val);
LLVMValueRef LLVMIsAFPTruncInst(LLVMValueRef Val);
LLVMValueRef LLVMIsAGetElementPtrInst(LLVMValueRef Val);
LLVMValueRef LLVMIsAGlobalValue(LLVMValueRef Val);
LLVMValueRef LLVMIsAGlobalAlias(LLVMValueRef Val);
static if (LLVM_Version >= asVersion(8, 0, 0)) {
    LLVMValueRef LLVMIsAGlobalIFunc(LLVMValueRef Val);
}
LLVMValueRef LLVMIsAGlobalObject(LLVMValueRef Val);
LLVMValueRef LLVMIsAFunction(LLVMValueRef Val);
LLVMValueRef LLVMIsAGlobalVariable(LLVMValueRef Val);
LLVMValueRef LLVMIsAICmpInst(LLVMValueRef Val);
LLVMValueRef LLVMIsAIndirectBrInst(LLVMValueRef Val);
LLVMValueRef LLVMIsAInlineAsm(LLVMValueRef Val);
LLVMValueRef LLVMIsAInsertElementInst(LLVMValueRef Val);
LLVMValueRef LLVMIsAInsertValueInst(LLVMValueRef Val);
LLVMValueRef LLVMIsAInstruction(LLVMValueRef Val);
LLVMValueRef LLVMIsAIntrinsicInst(LLVMValueRef Val);
LLVMValueRef LLVMIsAIntToPtrInst(LLVMValueRef Val);
LLVMValueRef LLVMIsAInvokeInst(LLVMValueRef Val);
LLVMValueRef LLVMIsALandingPadInst(LLVMValueRef Val);
LLVMValueRef LLVMIsALoadInst(LLVMValueRef Val);
LLVMValueRef LLVMIsAMDNode(LLVMValueRef Val);
LLVMValueRef LLVMIsAMDString(LLVMValueRef Val);
LLVMValueRef LLVMIsAMemCpyInst(LLVMValueRef Val);
LLVMValueRef LLVMIsAMemIntrinsic(LLVMValueRef Val);
LLVMValueRef LLVMIsAMemMoveInst(LLVMValueRef Val);
LLVMValueRef LLVMIsAMemSetInst(LLVMValueRef Val);
LLVMValueRef LLVMIsAPHINode(LLVMValueRef Val);
LLVMValueRef LLVMIsAPtrToIntInst(LLVMValueRef Val);
LLVMValueRef LLVMIsAResumeInst(LLVMValueRef Val);
static if (LLVM_Version >= asVersion(3, 8, 0)) {
    LLVMValueRef LLVMIsACleanupReturnInst(LLVMValueRef Val);
}
static if (LLVM_Version >= asVersion(3, 8, 0)) {
    LLVMValueRef LLVMIsACatchReturnInst(LLVMValueRef Val);
}
static if (LLVM_Version >= asVersion(10, 0, 0)) {
    LLVMValueRef LLVMIsACatchSwitchInst(LLVMValueRef Val);
    LLVMValueRef LLVMIsACallBrInst(LLVMValueRef Val);
}
static if (LLVM_Version >= asVersion(3, 8, 0)) {
    LLVMValueRef LLVMIsAFuncletPadInst(LLVMValueRef Val);
}
static if (LLVM_Version >= asVersion(3, 8, 0)) {
    LLVMValueRef LLVMIsACatchPadInst(LLVMValueRef Val);
}
static if (LLVM_Version >= asVersion(3, 8, 0)) {
    LLVMValueRef LLVMIsACleanupPadInst(LLVMValueRef Val);
}
LLVMValueRef LLVMIsAReturnInst(LLVMValueRef Val);
LLVMValueRef LLVMIsASelectInst(LLVMValueRef Val);
LLVMValueRef LLVMIsASExtInst(LLVMValueRef Val);
LLVMValueRef LLVMIsAShuffleVectorInst(LLVMValueRef Val);
LLVMValueRef LLVMIsASIToFPInst(LLVMValueRef Val);
LLVMValueRef LLVMIsAStoreInst(LLVMValueRef Val);
LLVMValueRef LLVMIsASwitchInst(LLVMValueRef Val);
LLVMValueRef LLVMIsATerminatorInst(LLVMValueRef Val);
LLVMValueRef LLVMIsATruncInst(LLVMValueRef Val);
LLVMValueRef LLVMIsAUIToFPInst(LLVMValueRef Val);
LLVMValueRef LLVMIsAUnaryInstruction(LLVMValueRef Val);
LLVMValueRef LLVMIsAUndefValue(LLVMValueRef Val);
LLVMValueRef LLVMIsAUnreachableInst(LLVMValueRef Val);
LLVMValueRef LLVMIsAUser(LLVMValueRef Val);
LLVMValueRef LLVMIsAVAArgInst(LLVMValueRef Val);
static if (LLVM_Version >= asVersion(10, 0, 0)) {
    LLVMValueRef LLVMIsAFreezeInst(LLVMValueRef Val);
    LLVMValueRef LLVMIsAAtomicCmpXchgInst(LLVMValueRef Val);
    LLVMValueRef LLVMIsAAtomicRMWInst(LLVMValueRef Val);
    LLVMValueRef LLVMIsAFenceInst(LLVMValueRef Val);
}
LLVMValueRef LLVMIsAZExtInst(LLVMValueRef Val);

/+++ Usage +++/

LLVMUseRef LLVMGetFirstUse(LLVMValueRef Val);
LLVMUseRef LLVMGetNextUse(LLVMUseRef U);
LLVMValueRef LLVMGetUser(LLVMUseRef U);
LLVMValueRef LLVMGetUsedValue(LLVMUseRef U);

/+++ User value +++/

LLVMValueRef LLVMGetOperand(LLVMValueRef Val, uint Index);
static if (LLVM_Version >= asVersion(3, 6, 0)) {
    LLVMUseRef LLVMGetOperandUse(LLVMValueRef Val, uint Index);
}
void LLVMSetOperand(LLVMValueRef User, uint Index, LLVMValueRef Val);
int LLVMGetNumOperands(LLVMValueRef Val);

/+++ Constants +++/

LLVMValueRef LLVMConstNull(LLVMTypeRef Ty);
LLVMValueRef LLVMConstAllOnes(LLVMTypeRef Ty);
LLVMValueRef LLVMGetUndef(LLVMTypeRef Ty);
LLVMBool LLVMIsNull(LLVMValueRef Val);
LLVMValueRef LLVMConstPointerNull(LLVMTypeRef Ty);

/++++ Scalar constants ++++/

LLVMValueRef LLVMConstInt(LLVMTypeRef IntTy, ulong N, LLVMBool SignExtend);
LLVMValueRef LLVMConstIntOfArbitraryPrecision(LLVMTypeRef IntTy, uint NumWords, const(ulong)* Words);
LLVMValueRef LLVMConstIntOfString(LLVMTypeRef IntTy, const(char)* Text, ubyte Radix);
LLVMValueRef LLVMConstIntOfStringAndSize(LLVMTypeRef IntTy, const(char)* Text, uint SLen, ubyte Radix);
LLVMValueRef LLVMConstReal(LLVMTypeRef RealTy, double N);
LLVMValueRef LLVMConstRealOfString(LLVMTypeRef RealTy, const(char)* Text);
LLVMValueRef LLVMConstRealOfStringAndSize(LLVMTypeRef RealTy, const(char)* Text, uint SLen);
ulong LLVMConstIntGetZExtValue(LLVMValueRef ConstantVal);
long LLVMConstIntGetSExtValue(LLVMValueRef ConstantVal);
static if (LLVM_Version >= asVersion(3, 6, 0)) {
    double LLVMConstRealGetDouble(LLVMValueRef ConstantVal, LLVMBool *losesInfo);
}

/++++ Composite Constants ++++/

LLVMValueRef LLVMConstStringInContext(LLVMContextRef C, const(char)* Str, uint Length, LLVMBool DontNullTerminate);
LLVMValueRef LLVMConstString(const(char)* Str, uint Length, LLVMBool DontNullTerminate);
static if (LLVM_Version >= asVersion(3, 6, 0)) {
    LLVMBool LLVMIsConstantString(LLVMValueRef c);
}
static if (LLVM_Version >= asVersion(3, 6, 0)) {
    const(char*) LLVMGetAsString(LLVMValueRef c, size_t* Length);
}
LLVMValueRef LLVMConstStructInContext(LLVMContextRef C, LLVMValueRef* ConstantVals, uint Count, LLVMBool Packed);
LLVMValueRef LLVMConstStruct(LLVMValueRef* ConstantVals, uint Count, LLVMBool Packed);
LLVMValueRef LLVMConstArray(LLVMTypeRef ElementTy, LLVMValueRef* ConstantVals, uint Length);
LLVMValueRef LLVMConstNamedStruct(LLVMTypeRef StructTy, LLVMValueRef* ConstantVals, uint Count);
static if (LLVM_Version >= asVersion(3, 6, 0)) {
    LLVMValueRef LLVMGetElementAsConstant(LLVMValueRef c, uint idx);
}
LLVMValueRef LLVMConstVector(LLVMValueRef* ScalarConstantVals, uint Size);

/++++ Constant Expressions ++++/

LLVMOpcode LLVMGetConstOpcode(LLVMValueRef ConstantVal);
LLVMValueRef LLVMAlignOf(LLVMTypeRef Ty);
LLVMValueRef LLVMSizeOf(LLVMTypeRef Ty);
LLVMValueRef LLVMConstNeg(LLVMValueRef ConstantVal);
LLVMValueRef LLVMConstNSWNeg(LLVMValueRef ConstantVal);
LLVMValueRef LLVMConstNUWNeg(LLVMValueRef ConstantVal);
LLVMValueRef LLVMConstFNeg(LLVMValueRef ConstantVal);
LLVMValueRef LLVMConstNot(LLVMValueRef ConstantVal);
LLVMValueRef LLVMConstAdd(LLVMValueRef LHSConstant, LLVMValueRef RHSConstant);
LLVMValueRef LLVMConstNSWAdd(LLVMValueRef LHSConstant, LLVMValueRef RHSConstant);
LLVMValueRef LLVMConstNUWAdd(LLVMValueRef LHSConstant, LLVMValueRef RHSConstant);
LLVMValueRef LLVMConstFAdd(LLVMValueRef LHSConstant, LLVMValueRef RHSConstant);
LLVMValueRef LLVMConstSub(LLVMValueRef LHSConstant, LLVMValueRef RHSConstant);
LLVMValueRef LLVMConstNSWSub(LLVMValueRef LHSConstant, LLVMValueRef RHSConstant);
LLVMValueRef LLVMConstNUWSub(LLVMValueRef LHSConstant, LLVMValueRef RHSConstant);
LLVMValueRef LLVMConstFSub(LLVMValueRef LHSConstant, LLVMValueRef RHSConstant);
LLVMValueRef LLVMConstMul(LLVMValueRef LHSConstant, LLVMValueRef RHSConstant);
LLVMValueRef LLVMConstNSWMul(LLVMValueRef LHSConstant, LLVMValueRef RHSConstant);
LLVMValueRef LLVMConstNUWMul(LLVMValueRef LHSConstant, LLVMValueRef RHSConstant);
LLVMValueRef LLVMConstFMul(LLVMValueRef LHSConstant, LLVMValueRef RHSConstant);
LLVMValueRef LLVMConstUDiv(LLVMValueRef LHSConstant, LLVMValueRef RHSConstant);
static if (LLVM_Version >= asVersion(4, 0, 0)) {
	LLVMValueRef LLVMConstExactUDiv(LLVMValueRef LHSConstant, LLVMValueRef RHSConstant);
}
LLVMValueRef LLVMConstSDiv(LLVMValueRef LHSConstant, LLVMValueRef RHSConstant);
LLVMValueRef LLVMConstExactSDiv(LLVMValueRef LHSConstant, LLVMValueRef RHSConstant);
LLVMValueRef LLVMConstFDiv(LLVMValueRef LHSConstant, LLVMValueRef RHSConstant);
LLVMValueRef LLVMConstURem(LLVMValueRef LHSConstant, LLVMValueRef RHSConstant);
LLVMValueRef LLVMConstSRem(LLVMValueRef LHSConstant, LLVMValueRef RHSConstant);
LLVMValueRef LLVMConstFRem(LLVMValueRef LHSConstant, LLVMValueRef RHSConstant);
LLVMValueRef LLVMConstAnd(LLVMValueRef LHSConstant, LLVMValueRef RHSConstant);
LLVMValueRef LLVMConstOr(LLVMValueRef LHSConstant, LLVMValueRef RHSConstant);
LLVMValueRef LLVMConstXor(LLVMValueRef LHSConstant, LLVMValueRef RHSConstant);
LLVMValueRef LLVMConstICmp(LLVMIntPredicate Predicate, LLVMValueRef LHSConstant, LLVMValueRef RHSConstant);
LLVMValueRef LLVMConstFCmp(LLVMRealPredicate Predicate, LLVMValueRef LHSConstant, LLVMValueRef RHSConstant);
LLVMValueRef LLVMConstShl(LLVMValueRef LHSConstant, LLVMValueRef RHSConstant);
LLVMValueRef LLVMConstLShr(LLVMValueRef LHSConstant, LLVMValueRef RHSConstant);
LLVMValueRef LLVMConstAShr(LLVMValueRef LHSConstant, LLVMValueRef RHSConstant);
LLVMValueRef LLVMConstGEP(LLVMValueRef ConstantVal, LLVMValueRef* ConstantIndices, uint NumIndices);
static if (LLVM_Version >= asVersion(8, 0, 0)) {
    LLVMValueRef LLVMConstGEP2(LLVMTypeRef Ty, LLVMValueRef ConstantVal,
                               LLVMValueRef* ConstantIndices, uint NumIndices);
}
LLVMValueRef LLVMConstInBoundsGEP(LLVMValueRef ConstantVal, LLVMValueRef* ConstantIndices, uint NumIndices);
static if (LLVM_Version >= asVersion(8, 0, 0)) {
    LLVMValueRef LLVMConstInBoundsGEP2(LLVMTypeRef Ty, LLVMValueRef ConstantVal,
                                       LLVMValueRef* ConstantIndices,
                                       uint NumIndices);
}
LLVMValueRef LLVMConstTrunc(LLVMValueRef ConstantVal, LLVMTypeRef ToType);
LLVMValueRef LLVMConstSExt(LLVMValueRef ConstantVal, LLVMTypeRef ToType);
LLVMValueRef LLVMConstZExt(LLVMValueRef ConstantVal, LLVMTypeRef ToType);
LLVMValueRef LLVMConstFPTrunc(LLVMValueRef ConstantVal, LLVMTypeRef ToType);
LLVMValueRef LLVMConstFPExt(LLVMValueRef ConstantVal, LLVMTypeRef ToType);
LLVMValueRef LLVMConstUIToFP(LLVMValueRef ConstantVal, LLVMTypeRef ToType);
LLVMValueRef LLVMConstSIToFP(LLVMValueRef ConstantVal, LLVMTypeRef ToType);
LLVMValueRef LLVMConstFPToUI(LLVMValueRef ConstantVal, LLVMTypeRef ToType);
LLVMValueRef LLVMConstFPToSI(LLVMValueRef ConstantVal, LLVMTypeRef ToType);
LLVMValueRef LLVMConstPtrToInt(LLVMValueRef ConstantVal, LLVMTypeRef ToType);
LLVMValueRef LLVMConstIntToPtr(LLVMValueRef ConstantVal, LLVMTypeRef ToType);
LLVMValueRef LLVMConstBitCast(LLVMValueRef ConstantVal, LLVMTypeRef ToType);
static if (LLVM_Version >= asVersion(3, 4, 0)) {
    LLVMValueRef LLVMConstAddrSpaceCast(LLVMValueRef ConstantVal, LLVMTypeRef ToType);
}
LLVMValueRef LLVMConstZExtOrBitCast(LLVMValueRef ConstantVal, LLVMTypeRef ToType);
LLVMValueRef LLVMConstSExtOrBitCast(LLVMValueRef ConstantVal, LLVMTypeRef ToType);
LLVMValueRef LLVMConstTruncOrBitCast(LLVMValueRef ConstantVal, LLVMTypeRef ToType);
LLVMValueRef LLVMConstPointerCast(LLVMValueRef ConstantVal, LLVMTypeRef ToType);
LLVMValueRef LLVMConstIntCast(LLVMValueRef ConstantVal, LLVMTypeRef ToType, LLVMBool isSigned);
LLVMValueRef LLVMConstFPCast(LLVMValueRef ConstantVal, LLVMTypeRef ToType);
LLVMValueRef LLVMConstSelect(LLVMValueRef ConstantCondition, LLVMValueRef ConstantIfTrue, LLVMValueRef ConstantIfFalse);
LLVMValueRef LLVMConstExtractElement(LLVMValueRef VectorConstant, LLVMValueRef IndexConstant);
LLVMValueRef LLVMConstInsertElement(LLVMValueRef VectorConstant, LLVMValueRef ElementValueConstant, LLVMValueRef IndexConstant);
LLVMValueRef LLVMConstShuffleVector(LLVMValueRef VectorAConstant, LLVMValueRef VectorBConstant, LLVMValueRef MaskConstant);
LLVMValueRef LLVMConstExtractValue(LLVMValueRef AggConstant, uint* IdxList, uint NumIdx);
LLVMValueRef LLVMConstInsertValue(LLVMValueRef AggConstant, LLVMValueRef ElementValueConstant, uint* IdxList, uint NumIdx);

static if (LLVM_Version >= asVersion(7, 0, 0)) {
	LLVMValueRef LLVMGetInlineAsm(LLVMTypeRef Ty,  char *AsmString, size_t AsmStringSize, char* Constraints, size_t ConstraintsSize, LLVMBool HasSideEffects, LLVMBool IsAlignStack, LLVMInlineAsmDialect Dialect);
}

static if (LLVM_Version >= asVersion(7, 0, 0)) {
	deprecated("Use LLVMGetInlineAsm instead.") LLVMValueRef LLVMConstInlineAsm(LLVMTypeRef Ty, const(char)* AsmString, const(char)* Constraints, LLVMBool HasSideEffects, LLVMBool IsAlignStack);
} else {
	LLVMValueRef LLVMConstInlineAsm(LLVMTypeRef Ty, const(char)* AsmString, const(char)* Constraints, LLVMBool HasSideEffects, LLVMBool IsAlignStack);
}

LLVMValueRef LLVMBlockAddress(LLVMValueRef F, LLVMBasicBlockRef BB);

/++++ Global Values ++++/

LLVMModuleRef LLVMGetGlobalParent(LLVMValueRef Global);
LLVMBool LLVMIsDeclaration(LLVMValueRef Global);
LLVMLinkage LLVMGetLinkage(LLVMValueRef Global);
void LLVMSetLinkage(LLVMValueRef Global, LLVMLinkage Linkage);
const(char)* LLVMGetSection(LLVMValueRef Global);
void LLVMSetSection(LLVMValueRef Global, const(char)* Section);
LLVMVisibility LLVMGetVisibility(LLVMValueRef Global);
void LLVMSetVisibility(LLVMValueRef Global, LLVMVisibility Viz);
static if (LLVM_Version >= asVersion(3, 5, 0)) {
    LLVMDLLStorageClass LLVMGetDLLStorageClass(LLVMValueRef Global);
}
static if (LLVM_Version >= asVersion(3, 5, 0)) {
    void LLVMSetDLLStorageClass(LLVMValueRef Global, LLVMDLLStorageClass Class);
}

static if (LLVM_Version >= asVersion(7, 0, 0)) {
	LLVMUnnamedAddr LLVMGetUnnamedAddress(LLVMValueRef Global);
}

static if (LLVM_Version >= asVersion(7, 0, 0)) {
	deprecated("Use LLVMGetUnnamedAddress instead.") LLVMBool LLVMHasUnnamedAddr(LLVMValueRef Global);
} else static if (LLVM_Version >= asVersion(3, 5, 0)) {
    LLVMBool LLVMHasUnnamedAddr(LLVMValueRef Global);
}

static if (LLVM_Version >= asVersion(7, 0, 0)) {
	void LLVMSetUnnamedAddress(LLVMValueRef Global, LLVMUnnamedAddr UnnamedAddr);
}

static if (LLVM_Version >= asVersion(7, 0, 0)) {
	deprecated("Use LLVMSetUnnamedAddress instead.") void LLVMSetUnnamedAddr(LLVMValueRef Global, LLVMBool HasUnnamedAddr);
} else static if (LLVM_Version >= asVersion(3, 5, 0)) {
    void LLVMSetUnnamedAddr(LLVMValueRef Global, LLVMBool HasUnnamedAddr);
}
static if (LLVM_Version >= asVersion(8, 0, 0)) {
    LLVMTypeRef LLVMGlobalGetValueType(LLVMValueRef Global);
}
uint LLVMGetAlignment(LLVMValueRef Global);
void LLVMSetAlignment(LLVMValueRef Global, uint Bytes);

static if (LLVM_Version >= asVersion(8, 0, 0)) {
    void LLVMGlobalSetMetadata(LLVMValueRef Global, uint Kind,
                               LLVMMetadataRef MD);

    void LLVMGlobalEraseMetadata(LLVMValueRef Global, uint Kind);

    void LLVMGlobalClearMetadata(LLVMValueRef Global);

    LLVMValueMetadataEntry *LLVMGlobalCopyAllMetadata(LLVMValueRef Value,
                                                      size_t* NumEntries);

    void LLVMDisposeValueMetadataEntries(LLVMValueMetadataEntry* Entries);

    uint LLVMValueMetadataEntriesGetKind(LLVMValueMetadataEntry* Entries,
                                         uint Index);

    LLVMMetadataRef
    LLVMValueMetadataEntriesGetMetadata(LLVMValueMetadataEntry* Entries,
                                        uint Index);
}

/+++++ Global Variables +++++/

LLVMValueRef LLVMAddGlobal(LLVMModuleRef M, LLVMTypeRef Ty, const(char)* Name);
LLVMValueRef LLVMAddGlobalInAddressSpace(LLVMModuleRef M, LLVMTypeRef Ty, const(char)* Name, uint AddressSpace);
LLVMValueRef LLVMGetNamedGlobal(LLVMModuleRef M, const(char)* Name);
LLVMValueRef LLVMGetFirstGlobal(LLVMModuleRef M);
LLVMValueRef LLVMGetLastGlobal(LLVMModuleRef M);
LLVMValueRef LLVMGetNextGlobal(LLVMValueRef GlobalVar);
LLVMValueRef LLVMGetPreviousGlobal(LLVMValueRef GlobalVar);
void LLVMDeleteGlobal(LLVMValueRef GlobalVar);
LLVMValueRef LLVMGetInitializer(LLVMValueRef GlobalVar);
void LLVMSetInitializer(LLVMValueRef GlobalVar, LLVMValueRef ConstantVal);
LLVMBool LLVMIsThreadLocal(LLVMValueRef GlobalVar);
void LLVMSetThreadLocal(LLVMValueRef GlobalVar, LLVMBool IsThreadLocal);
LLVMBool LLVMIsGlobalConstant(LLVMValueRef GlobalVar);
void LLVMSetGlobalConstant(LLVMValueRef GlobalVar, LLVMBool IsConstant);
static if (LLVM_Version >= asVersion(3, 3, 0)) {
    LLVMThreadLocalMode LLVMGetThreadLocalMode(LLVMValueRef GlobalVar);
}
static if (LLVM_Version >= asVersion(3, 3, 0)) {
    void LLVMSetThreadLocalMode(LLVMValueRef GlobalVar, LLVMThreadLocalMode Mode);
}
static if (LLVM_Version >= asVersion(3, 3, 0)) {
    LLVMBool LLVMIsExternallyInitialized(LLVMValueRef GlobalVar);
}
static if (LLVM_Version >= asVersion(3, 3, 0)) {
    void LLVMSetExternallyInitialized(LLVMValueRef GlobalVar, LLVMBool IsExtInit);
}

/+++++ Global Aliases +++++/

LLVMValueRef LLVMAddAlias(LLVMModuleRef M, LLVMTypeRef Ty, LLVMValueRef Aliasee, const(char)* Name);

/+++++ Function values +++++/

void LLVMDeleteFunction(LLVMValueRef Fn);
static if (LLVM_Version >= asVersion(3, 9, 0)) {
    LLVMBool LLVMHasPersonalityFn(LLVMValueRef Fn);
}
static if (LLVM_Version >= asVersion(3, 7, 0)) {
    LLVMValueRef LLVMGetPersonalityFn(LLVMValueRef Fn);
}
static if (LLVM_Version >= asVersion(3, 7, 0)) {
    void LLVMSetPersonalityFn(LLVMValueRef Fn, LLVMValueRef PersonalityFn);
}
static if (LLVM_Version >= asVersion(9, 0, 0)) {
    uint LLVMLookupIntrinsicID(const(char)* Name, size_t NameLen);
}
uint LLVMGetIntrinsicID(LLVMValueRef Fn);
static if (LLVM_Version >= asVersion(8, 0, 0)) {
    LLVMValueRef LLVMGetIntrinsicDeclaration(LLVMModuleRef Mod,
                                             uint ID,
                                             LLVMTypeRef* ParamTypes,
                                             size_t ParamCount);

    LLVMTypeRef LLVMIntrinsicGetType(LLVMContextRef Ctx, uint ID,
                                     LLVMTypeRef* ParamTypes, size_t ParamCount);

    const(char)* LLVMIntrinsicGetName(uint ID, size_t* NameLength);

    const(char)* LLVMIntrinsicCopyOverloadedName(uint ID,
                                                 LLVMTypeRef* ParamTypes,
                                                 size_t ParamCount,
                                                 size_t* NameLength);

    LLVMBool LLVMIntrinsicIsOverloaded(uint ID);
}
uint LLVMGetFunctionCallConv(LLVMValueRef Fn);
void LLVMSetFunctionCallConv(LLVMValueRef Fn, uint CC);
const(char)* LLVMGetGC(LLVMValueRef Fn);
void LLVMSetGC(LLVMValueRef Fn, const(char)* Name);
static if (LLVM_Version < asVersion(4, 0, 0)) {
	void LLVMAddFunctionAttr(LLVMValueRef Fn, LLVMAttribute PA);
}

static if (LLVM_Version >= asVersion(3, 9, 0)) {
    void LLVMAddAttributeAtIndex(LLVMValueRef F, LLVMAttributeIndex Idx, LLVMAttributeRef A);
}
static if (LLVM_Version >= asVersion(3, 9, 0)) {
    uint LLVMGetAttributeCountAtIndex(LLVMValueRef F, LLVMAttributeIndex Idx);
}
static if (LLVM_Version >= asVersion(3, 9, 0)) {
    void LLVMGetAttributesAtIndex(LLVMValueRef F, LLVMAttributeIndex Idx, LLVMAttributeRef *Attrs);
}
static if (LLVM_Version >= asVersion(3, 9, 0)) {
    LLVMAttributeRef LLVMGetEnumAttributeAtIndex(LLVMValueRef F, LLVMAttributeIndex Idx, uint KindID);
}
static if (LLVM_Version >= asVersion(3, 9, 0)) {
    LLVMAttributeRef LLVMGetStringAttributeAtIndex(LLVMValueRef F, LLVMAttributeIndex Idx, const(char)* K, uint KLen);
}
static if (LLVM_Version >= asVersion(3, 9, 0)) {
    void LLVMRemoveEnumAttributeAtIndex(LLVMValueRef F, LLVMAttributeIndex Idx, uint KindID);
}
static if (LLVM_Version >= asVersion(3, 9, 0)) {
    void LLVMRemoveStringAttributeAtIndex(LLVMValueRef F, LLVMAttributeIndex Idx, const(char)* K, uint KLen);
}



static if (LLVM_Version >= asVersion(3, 3, 0)) {
    void LLVMAddTargetDependentFunctionAttr(LLVMValueRef Fn, const(char)* A, const(char)* V);
}

static if (LLVM_Version < asVersion(4, 0, 0)) {
	LLVMAttribute LLVMGetFunctionAttr(LLVMValueRef Fn);
	void LLVMRemoveFunctionAttr(LLVMValueRef Fn, LLVMAttribute PA);
}
/++++++ Function Parameters ++++++/

uint LLVMCountParams(LLVMValueRef Fn);
void LLVMGetParams(LLVMValueRef Fn, LLVMValueRef* Params);
LLVMValueRef LLVMGetParam(LLVMValueRef Fn, uint Index);
LLVMValueRef LLVMGetParamParent(LLVMValueRef Inst);
LLVMValueRef LLVMGetFirstParam(LLVMValueRef Fn);
LLVMValueRef LLVMGetLastParam(LLVMValueRef Fn);
LLVMValueRef LLVMGetNextParam(LLVMValueRef Arg);
LLVMValueRef LLVMGetPreviousParam(LLVMValueRef Arg);

static if (LLVM_Version < asVersion(4, 0, 0)) {
	void LLVMAddAttribute(LLVMValueRef Arg, LLVMAttribute PA);
	void LLVMRemoveAttribute(LLVMValueRef Arg, LLVMAttribute PA);
	LLVMAttribute LLVMGetAttribute(LLVMValueRef Arg);
}

void LLVMSetParamAlignment(LLVMValueRef Arg, uint Align);

/+++ IFuncs +++/

static if (LLVM_Version >= asVersion(9, 0, 0)) {
    LLVMValueRef LLVMAddGlobalIFunc(LLVMModuleRef M, const(char)* Name, size_t NameLen, LLVMTypeRef Ty, uint AddrSpace, LLVMValueRef Resolver);
    LLVMValueRef LLVMGetNamedGlobalIFunc(LLVMModuleRef M, const(char)* Name, size_t NameLen);
    LLVMValueRef LLVMGetFirstGlobalIFunc(LLVMModuleRef M);
    LLVMValueRef LLVMGetLastGlobalIFunc(LLVMModuleRef M);
    LLVMValueRef LLVMGetNextGlobalIFunc(LLVMValueRef IFunc);
    LLVMValueRef LLVMGetPreviousGlobalIFunc(LLVMValueRef IFunc);
    LLVMValueRef LLVMGetGlobalIFuncResolver(LLVMValueRef IFunc);
    void LLVMSetGlobalIFuncResolver(LLVMValueRef IFunc, LLVMValueRef Resolver);
    void LLVMEraseGlobalIFunc(LLVMValueRef IFunc);
    void LLVMRemoveGlobalIFunc(LLVMValueRef IFunc);
}

/+++ Metadata +++/


static if (LLVM_Version >= asVersion(9, 0, 0)) {
    LLVMMetadataRef LLVMMDStringInContext2(LLVMContextRef C, const(char)* Str, size_t SLen);

    LLVMMetadataRef LLVMMDNodeInContext2(LLVMContextRef C, LLVMMetadataRef* MDs, size_t Count);

    deprecated("Use LLVMMDStringInContext2 instead.") LLVMValueRef LLVMMDStringInContext(LLVMContextRef C, const(char)* Str, uint SLen);
    deprecated("Use LLVMMDStringInContext2 instead.") LLVMValueRef LLVMMDString(const(char)* Str, uint SLen);

    deprecated("Use LLVMMDNodeInContext2") LLVMValueRef LLVMMDNodeInContext(LLVMContextRef C, LLVMValueRef* Vals, uint Count);
    deprecated("Use LLVMMDNodeInContext2") LLVMValueRef LLVMMDNode(LLVMValueRef* Vals, uint Count);
}
else {
    LLVMValueRef LLVMMDStringInContext(LLVMContextRef C, const(char)* Str, uint SLen);
    LLVMValueRef LLVMMDString(const(char)* Str, uint SLen);
    LLVMValueRef LLVMMDNodeInContext(LLVMContextRef C, LLVMValueRef* Vals, uint Count);
LLVMValueRef LLVMMDNode(LLVMValueRef* Vals, uint Count);
}

static if (LLVM_Version >= asVersion(5, 0, 0)) {
	LLVMValueRef LLVMMetadataAsValue(LLVMContextRef C, LLVMMetadataRef MD);
	LLVMMetadataRef LLVMValueAsMetadata(LLVMValueRef Val);
}
const(char)* LLVMGetMDString(LLVMValueRef V, uint* Len);
static if (LLVM_Version >= asVersion(3, 2, 0)) {
    uint LLVMGetMDNodeNumOperands(LLVMValueRef V);
}
static if (LLVM_Version >= asVersion(3, 2, 0)) {
    void LLVMGetMDNodeOperands(LLVMValueRef V, LLVMValueRef *Dest);
}

/+++ Basic Block +++/

LLVMValueRef LLVMBasicBlockAsValue(LLVMBasicBlockRef BB);
LLVMBool LLVMValueIsBasicBlock(LLVMValueRef Val);
LLVMBasicBlockRef LLVMValueAsBasicBlock(LLVMValueRef Val);
static if (LLVM_Version >= asVersion(3, 9, 0)) {
    const(char)* LLVMGetBasicBlockName(LLVMBasicBlockRef BB);
}
LLVMValueRef LLVMGetBasicBlockParent(LLVMBasicBlockRef BB);
LLVMValueRef LLVMGetBasicBlockTerminator(LLVMBasicBlockRef BB);
uint LLVMCountBasicBlocks(LLVMValueRef Fn);
void LLVMGetBasicBlocks(LLVMValueRef Fn, LLVMBasicBlockRef* BasicBlocks);
LLVMBasicBlockRef LLVMGetFirstBasicBlock(LLVMValueRef Fn);
LLVMBasicBlockRef LLVMGetLastBasicBlock(LLVMValueRef Fn);
LLVMBasicBlockRef LLVMGetNextBasicBlock(LLVMBasicBlockRef BB);
LLVMBasicBlockRef LLVMGetPreviousBasicBlock(LLVMBasicBlockRef BB);
LLVMBasicBlockRef LLVMGetEntryBasicBlock(LLVMValueRef Fn);
static if (LLVM_Version >= asVersion(9, 0, 0)) {
    void LLVMInsertExistingBasicBlockAfterInsertBlock(LLVMBuilderRef Builder, LLVMBasicBlockRef BB);
    void LLVMAppendExistingBasicBlock(LLVMValueRef Fn, LLVMBasicBlockRef BB);
}
static if (LLVM_Version >= asVersion(8, 0, 0)) {
    LLVMBasicBlockRef LLVMCreateBasicBlockInContext(LLVMContextRef C,
                                                    const(char)* Name);
}
LLVMBasicBlockRef LLVMAppendBasicBlockInContext(LLVMContextRef C, LLVMValueRef Fn, const(char)* Name);
LLVMBasicBlockRef LLVMAppendBasicBlock(LLVMValueRef Fn, const(char)* Name);
LLVMBasicBlockRef LLVMInsertBasicBlockInContext(LLVMContextRef C, LLVMBasicBlockRef BB, const(char)* Name);
LLVMBasicBlockRef LLVMInsertBasicBlock(LLVMBasicBlockRef InsertBeforeBB, const(char)* Name);
void LLVMDeleteBasicBlock(LLVMBasicBlockRef BB);
void LLVMRemoveBasicBlockFromParent(LLVMBasicBlockRef BB);
void LLVMMoveBasicBlockBefore(LLVMBasicBlockRef BB, LLVMBasicBlockRef MovePos);
void LLVMMoveBasicBlockAfter(LLVMBasicBlockRef BB, LLVMBasicBlockRef MovePos);
LLVMValueRef LLVMGetFirstInstruction(LLVMBasicBlockRef BB);
LLVMValueRef LLVMGetLastInstruction(LLVMBasicBlockRef BB);

/+++ Instructions +++/

int LLVMHasMetadata(LLVMValueRef Val);
LLVMValueRef LLVMGetMetadata(LLVMValueRef Val, uint KindID);
void LLVMSetMetadata(LLVMValueRef Val, uint KindID, LLVMValueRef Node);
static if (LLVM_Version >= asVersion(8, 0, 0)) {
    LLVMValueMetadataEntry*
    LLVMInstructionGetAllMetadataOtherThanDebugLoc(LLVMValueRef Instr,
                                                   size_t* NumEntries);
}
LLVMBasicBlockRef LLVMGetInstructionParent(LLVMValueRef Inst);
LLVMValueRef LLVMGetNextInstruction(LLVMValueRef Inst);
LLVMValueRef LLVMGetPreviousInstruction(LLVMValueRef Inst);
static if (LLVM_Version >= asVersion(3, 9, 0)) {
    void LLVMInstructionRemoveFromParent(LLVMValueRef Inst);
}
void LLVMInstructionEraseFromParent(LLVMValueRef Inst);
LLVMOpcode LLVMGetInstructionOpcode(LLVMValueRef Inst);
LLVMIntPredicate LLVMGetICmpPredicate(LLVMValueRef Inst);
static if (LLVM_Version >= asVersion(3, 6, 0)) {
    LLVMRealPredicate LLVMGetFCmpPredicate(LLVMValueRef Inst);
}
static if (LLVM_Version >= asVersion(3, 6, 0)) {
    LLVMValueRef LLVMInstructionClone(LLVMValueRef Inst);
}
LLVMBasicBlockRef LLVMGetSwitchDefaultDest(LLVMValueRef SwitchInstr);


static if (LLVM_Version >= asVersion(3, 9, 0)) {
    LLVMTypeRef LLVMGetAllocatedType(LLVMValueRef Alloca);
}
static if (LLVM_Version >= asVersion(3, 9, 0)) {
    LLVMBool LLVMIsInBounds(LLVMValueRef GEP);
}
static if (LLVM_Version >= asVersion(3, 9, 0)) {
    void LLVMSetIsInBounds(LLVMValueRef GEP, LLVMBool InBounds);
}

/++++ Call Sites and Invocations ++++/

static if (LLVM_Version >= asVersion(3, 9, 0)) {
    uint LLVMGetNumArgOperands(LLVMValueRef Instr);
}
void LLVMSetInstructionCallConv(LLVMValueRef Instr, uint CC);
uint LLVMGetInstructionCallConv(LLVMValueRef Instr);

static if (LLVM_Version < asVersion(4, 0, 0)) {
	void LLVMAddInstrAttribute(LLVMValueRef Instr, uint index, LLVMAttribute);
	void LLVMRemoveInstrAttribute(LLVMValueRef Instr, uint index, LLVMAttribute);
}
void LLVMSetInstrParamAlignment(LLVMValueRef Instr, uint index, uint Align);

static if (LLVM_Version >= asVersion(3, 9, 0)) {
    void LLVMAddCallSiteAttribute(LLVMValueRef C, LLVMAttributeIndex Idx, LLVMAttributeRef A);
}
static if (LLVM_Version >= asVersion(3, 9, 0)) {
    uint LLVMGetCallSiteAttributeCount(LLVMValueRef C, LLVMAttributeIndex Idx);
}
static if (LLVM_Version >= asVersion(3, 9, 0)) {
    void LLVMGetCallSiteAttributes(LLVMValueRef C, LLVMAttributeIndex Idx, LLVMAttributeRef *Attrs);
}
static if (LLVM_Version >= asVersion(3, 9, 0)) {
    LLVMAttributeRef LLVMGetCallSiteEnumAttribute(LLVMValueRef C, LLVMAttributeIndex Idx, uint KindID);
}
static if (LLVM_Version >= asVersion(3, 9, 0)) {
    LLVMAttributeRef LLVMGetCallSiteStringAttribute(LLVMValueRef C, LLVMAttributeIndex Idx, const(char)* K, uint KLen);
}
static if (LLVM_Version >= asVersion(3, 9, 0)) {
    void LLVMRemoveCallSiteEnumAttribute(LLVMValueRef C, LLVMAttributeIndex Idx, uint KindID);
}
static if (LLVM_Version >= asVersion(3, 9, 0)) {
    void LLVMRemoveCallSiteStringAttribute(LLVMValueRef C, LLVMAttributeIndex Idx, const(char)* K, uint KLen);
}

static if (LLVM_Version >= asVersion(8, 0, 0)) {
    LLVMTypeRef LLVMGetCalledFunctionType(LLVMValueRef C);
}
static if (LLVM_Version >= asVersion(3, 9, 0)) {
    LLVMValueRef LLVMGetCalledValue(LLVMValueRef Instr);
}

LLVMBool LLVMIsTailCall(LLVMValueRef CallInst);

static if (LLVM_Version >= asVersion(3, 9, 0)) {
    LLVMBasicBlockRef LLVMGetNormalDest(LLVMValueRef InvokeInst);
}
static if (LLVM_Version >= asVersion(3, 9, 0)) {
    LLVMBasicBlockRef LLVMGetUnwindDest(LLVMValueRef InvokeInst);
}
static if (LLVM_Version >= asVersion(3, 9, 0)) {
    void LLVMSetNormalDest(LLVMValueRef InvokeInst, LLVMBasicBlockRef B);
}
static if (LLVM_Version >= asVersion(3, 9, 0)) {
    void LLVMSetUnwindDest(LLVMValueRef InvokeInst, LLVMBasicBlockRef B);
}

void LLVMSetTailCall(LLVMValueRef CallInst, LLVMBool IsTailCall);
static if (LLVM_Version >= asVersion(3, 6, 0)) {
    uint LLVMGetNumSuccessors(LLVMValueRef Term);
}
static if (LLVM_Version >= asVersion(3, 6, 0)) {
    LLVMBasicBlockRef LLVMGetSuccessor(LLVMValueRef Term, uint i);
}
static if (LLVM_Version >= asVersion(3, 6, 0)) {
    void LLVMSetSuccessor(LLVMValueRef Term, uint i, LLVMBasicBlockRef block);
}
static if (LLVM_Version >= asVersion(3, 6, 0)) {
    LLVMBool LLVMIsConditional(LLVMValueRef Branch);
}
static if (LLVM_Version >= asVersion(3, 6, 0)) {
    LLVMValueRef LLVMGetCondition(LLVMValueRef Branch);
}
static if (LLVM_Version >= asVersion(3, 6, 0)) {
    void LLVMSetCondition(LLVMValueRef Branch, LLVMValueRef Cond);
}

/++++ PHI Nodes ++++/

void LLVMAddIncoming(LLVMValueRef PhiNode, LLVMValueRef* IncomingValues, LLVMBasicBlockRef* IncomingBlocks, uint Count);
uint LLVMCountIncoming(LLVMValueRef PhiNode);
LLVMValueRef LLVMGetIncomingValue(LLVMValueRef PhiNode, uint Index);
LLVMBasicBlockRef LLVMGetIncomingBlock(LLVMValueRef PhiNode, uint Index);



static if (LLVM_Version >= asVersion(3, 9, 0)) {
    uint LLVMGetNumIndices(LLVMValueRef Inst);
}
static if (LLVM_Version >= asVersion(3, 9, 0)) {
    const(uint)* LLVMGetIndices(LLVMValueRef Inst);
}

/++ Instruction Builders ++/

LLVMBuilderRef LLVMCreateBuilderInContext(LLVMContextRef C);
LLVMBuilderRef LLVMCreateBuilder();
void LLVMPositionBuilder(LLVMBuilderRef Builder, LLVMBasicBlockRef Block, LLVMValueRef Instr);
void LLVMPositionBuilderBefore(LLVMBuilderRef Builder, LLVMValueRef Instr);
void LLVMPositionBuilderAtEnd(LLVMBuilderRef Builder, LLVMBasicBlockRef Block);
LLVMBasicBlockRef LLVMGetInsertBlock(LLVMBuilderRef Builder);
void LLVMClearInsertionPosition(LLVMBuilderRef Builder);
void LLVMInsertIntoBuilder(LLVMBuilderRef Builder, LLVMValueRef Instr);
void LLVMInsertIntoBuilderWithName(LLVMBuilderRef Builder, LLVMValueRef Instr, const(char)* Name);
void LLVMDisposeBuilder(LLVMBuilderRef Builder);
static if (LLVM_Version >= asVersion(9, 0, 0)) {
    LLVMMetadataRef LLVMGetCurrentDebugLocation2(LLVMBuilderRef Builder);
    void LLVMSetCurrentDebugLocation2(LLVMBuilderRef Builder, LLVMMetadataRef Loc);

    LLVMMetadataRef LLVMBuilderGetDefaultFPMathTag(LLVMBuilderRef Builder);
    void LLVMBuilderSetDefaultFPMathTag(LLVMBuilderRef Builder, LLVMMetadataRef FPMathTag);

    deprecated("Passing the NULL location will crash. Use LLVMSetCurrentDebugLocation2 instead.") void LLVMSetCurrentDebugLocation(LLVMBuilderRef Builder, LLVMValueRef L);
    deprecated("Passing the NULL location will crash. Use LLVMGetCurrentDebugLocation2 instead.") LLVMValueRef LLVMGetCurrentDebugLocation(LLVMBuilderRef Builder);
} else {
    void LLVMSetCurrentDebugLocation(LLVMBuilderRef Builder, LLVMValueRef L);
    LLVMValueRef LLVMGetCurrentDebugLocation(LLVMBuilderRef Builder);
}
void LLVMSetInstDebugLocation(LLVMBuilderRef Builder, LLVMValueRef Inst);
LLVMValueRef LLVMBuildRetVoid(LLVMBuilderRef);
LLVMValueRef LLVMBuildRet(LLVMBuilderRef, LLVMValueRef V);
LLVMValueRef LLVMBuildAggregateRet(LLVMBuilderRef, LLVMValueRef* RetVals, uint N);
LLVMValueRef LLVMBuildBr(LLVMBuilderRef, LLVMBasicBlockRef Dest);
LLVMValueRef LLVMBuildCondBr(LLVMBuilderRef, LLVMValueRef If, LLVMBasicBlockRef Then, LLVMBasicBlockRef Else);
LLVMValueRef LLVMBuildSwitch(LLVMBuilderRef, LLVMValueRef V, LLVMBasicBlockRef Else, uint NumCases);
LLVMValueRef LLVMBuildIndirectBr(LLVMBuilderRef B, LLVMValueRef Addr, uint NumDests);
LLVMValueRef LLVMBuildInvoke(LLVMBuilderRef, LLVMValueRef Fn, LLVMValueRef* Args, uint NumArgs, LLVMBasicBlockRef Then, LLVMBasicBlockRef Catch, const(char)* Name);
static if (LLVM_Version >= asVersion(8, 0, 0)) {
    LLVMValueRef LLVMBuildInvoke2(LLVMBuilderRef, LLVMTypeRef Ty, LLVMValueRef Fn,
                                  LLVMValueRef* Args, uint NumArgs,
                                  LLVMBasicBlockRef Then, LLVMBasicBlockRef Catch,
                                  const(char)* Name);
}
static if (LLVM_Version >= asVersion(3, 7, 0)) {
	LLVMValueRef LLVMBuildLandingPad(LLVMBuilderRef B, LLVMTypeRef Ty, LLVMValueRef PersFn, uint NumClauses, const(char)* Name);
} else {
	LLVMValueRef LLVMBuildLandingPad(LLVMBuilderRef B, LLVMTypeRef Ty, uint NumClauses, const(char)* Name);
}
LLVMValueRef LLVMBuildResume(LLVMBuilderRef B, LLVMValueRef Exn);
LLVMValueRef LLVMBuildUnreachable(LLVMBuilderRef);
void LLVMAddCase(LLVMValueRef Switch, LLVMValueRef OnVal, LLVMBasicBlockRef Dest);
void LLVMAddDestination(LLVMValueRef IndirectBr, LLVMBasicBlockRef Dest);

static if (LLVM_Version >= asVersion(3, 9, 0)) {
    uint LLVMGetNumClauses(LLVMValueRef LandingPad);
}
static if (LLVM_Version >= asVersion(3, 9, 0)) {
    LLVMValueRef LLVMGetClause(LLVMValueRef LandingPad, uint Idx);
}
static if (LLVM_Version >= asVersion(3, 9, 0)) {
    LLVMBool LLVMIsCleanup(LLVMValueRef LandingPad);
}

void LLVMAddClause(LLVMValueRef LandingPad, LLVMValueRef ClauseVal);
void LLVMSetCleanup(LLVMValueRef LandingPad, LLVMBool Val);
LLVMValueRef LLVMBuildAdd(LLVMBuilderRef, LLVMValueRef LHS, LLVMValueRef RHS, const(char)* Name);
LLVMValueRef LLVMBuildNSWAdd(LLVMBuilderRef, LLVMValueRef LHS, LLVMValueRef RHS, const(char)* Name);
LLVMValueRef LLVMBuildNUWAdd(LLVMBuilderRef, LLVMValueRef LHS, LLVMValueRef RHS, const(char)* Name);
LLVMValueRef LLVMBuildFAdd(LLVMBuilderRef, LLVMValueRef LHS, LLVMValueRef RHS, const(char)* Name);
LLVMValueRef LLVMBuildSub(LLVMBuilderRef, LLVMValueRef LHS, LLVMValueRef RHS, const(char)* Name);
LLVMValueRef LLVMBuildNSWSub(LLVMBuilderRef, LLVMValueRef LHS, LLVMValueRef RHS, const(char)* Name);
LLVMValueRef LLVMBuildNUWSub(LLVMBuilderRef, LLVMValueRef LHS, LLVMValueRef RHS, const(char)* Name);
LLVMValueRef LLVMBuildFSub(LLVMBuilderRef, LLVMValueRef LHS, LLVMValueRef RHS, const(char)* Name);
LLVMValueRef LLVMBuildMul(LLVMBuilderRef, LLVMValueRef LHS, LLVMValueRef RHS, const(char)* Name);
LLVMValueRef LLVMBuildNSWMul(LLVMBuilderRef, LLVMValueRef LHS, LLVMValueRef RHS, const(char)* Name);
LLVMValueRef LLVMBuildNUWMul(LLVMBuilderRef, LLVMValueRef LHS, LLVMValueRef RHS, const(char)* Name);
LLVMValueRef LLVMBuildFMul(LLVMBuilderRef, LLVMValueRef LHS, LLVMValueRef RHS, const(char)* Name);
LLVMValueRef LLVMBuildUDiv(LLVMBuilderRef, LLVMValueRef LHS, LLVMValueRef RHS, const(char)* Name);
static if (LLVM_Version >= asVersion(4, 0, 0)) {
	LLVMValueRef LLVMBuildExactUDiv(LLVMBuilderRef, LLVMValueRef LHS, LLVMValueRef RHS, const(char)* Name);
}
LLVMValueRef LLVMBuildSDiv(LLVMBuilderRef, LLVMValueRef LHS, LLVMValueRef RHS, const(char)* Name);
LLVMValueRef LLVMBuildExactSDiv(LLVMBuilderRef, LLVMValueRef LHS, LLVMValueRef RHS, const(char)* Name);
LLVMValueRef LLVMBuildFDiv(LLVMBuilderRef, LLVMValueRef LHS, LLVMValueRef RHS, const(char)* Name);
LLVMValueRef LLVMBuildURem(LLVMBuilderRef, LLVMValueRef LHS, LLVMValueRef RHS, const(char)* Name);
LLVMValueRef LLVMBuildSRem(LLVMBuilderRef, LLVMValueRef LHS, LLVMValueRef RHS, const(char)* Name);
LLVMValueRef LLVMBuildFRem(LLVMBuilderRef, LLVMValueRef LHS, LLVMValueRef RHS, const(char)* Name);
LLVMValueRef LLVMBuildShl(LLVMBuilderRef, LLVMValueRef LHS, LLVMValueRef RHS, const(char)* Name);
LLVMValueRef LLVMBuildLShr(LLVMBuilderRef, LLVMValueRef LHS, LLVMValueRef RHS, const(char)* Name);
LLVMValueRef LLVMBuildAShr(LLVMBuilderRef, LLVMValueRef LHS, LLVMValueRef RHS, const(char)* Name);
LLVMValueRef LLVMBuildAnd(LLVMBuilderRef, LLVMValueRef LHS, LLVMValueRef RHS, const(char)* Name);
LLVMValueRef LLVMBuildOr(LLVMBuilderRef, LLVMValueRef LHS, LLVMValueRef RHS, const(char)* Name);
LLVMValueRef LLVMBuildXor(LLVMBuilderRef, LLVMValueRef LHS, LLVMValueRef RHS, const(char)* Name);
LLVMValueRef LLVMBuildBinOp(LLVMBuilderRef B, LLVMOpcode Op, LLVMValueRef LHS, LLVMValueRef RHS, const(char)* Name);
LLVMValueRef LLVMBuildNeg(LLVMBuilderRef, LLVMValueRef V, const(char)* Name);
LLVMValueRef LLVMBuildNSWNeg(LLVMBuilderRef B, LLVMValueRef V, const(char)* Name);
LLVMValueRef LLVMBuildNUWNeg(LLVMBuilderRef B, LLVMValueRef V, const(char)* Name);
LLVMValueRef LLVMBuildFNeg(LLVMBuilderRef, LLVMValueRef V, const(char)* Name);
LLVMValueRef LLVMBuildNot(LLVMBuilderRef, LLVMValueRef V, const(char)* Name);
LLVMValueRef LLVMBuildMalloc(LLVMBuilderRef, LLVMTypeRef Ty, const(char)* Name);
LLVMValueRef LLVMBuildArrayMalloc(LLVMBuilderRef, LLVMTypeRef Ty, LLVMValueRef Val, const(char)* Name);
static if (LLVM_Version >= asVersion(8, 0, 0)) {
    LLVMValueRef LLVMBuildMemSet(LLVMBuilderRef B, LLVMValueRef Ptr,
                                 LLVMValueRef Val, LLVMValueRef Len,
                                 uint Align);
    LLVMValueRef LLVMBuildMemCpy(LLVMBuilderRef B,
                                 LLVMValueRef Dst, uint DstAlign,
                                 LLVMValueRef Src, uint SrcAlign,
                                 LLVMValueRef Size);
    LLVMValueRef LLVMBuildMemMove(LLVMBuilderRef B,
                                  LLVMValueRef Dst, uint DstAlign,
                                  LLVMValueRef Src, uint SrcAlign,
                                  LLVMValueRef Size);
}
LLVMValueRef LLVMBuildAlloca(LLVMBuilderRef, LLVMTypeRef Ty, const(char)* Name);
LLVMValueRef LLVMBuildArrayAlloca(LLVMBuilderRef, LLVMTypeRef Ty, LLVMValueRef Val, const(char)* Name);
LLVMValueRef LLVMBuildFree(LLVMBuilderRef, LLVMValueRef PointerVal);
LLVMValueRef LLVMBuildLoad(LLVMBuilderRef, LLVMValueRef PointerVal, const(char)* Name);
LLVMValueRef LLVMBuildStore(LLVMBuilderRef, LLVMValueRef Val, LLVMValueRef Ptr);
LLVMValueRef LLVMBuildGEP(LLVMBuilderRef B, LLVMValueRef Pointer, LLVMValueRef* Indices, uint NumIndices, const(char)* Name);
LLVMValueRef LLVMBuildInBoundsGEP(LLVMBuilderRef B, LLVMValueRef Pointer, LLVMValueRef* Indices, uint NumIndices, const(char)* Name);
LLVMValueRef LLVMBuildStructGEP(LLVMBuilderRef B, LLVMValueRef Pointer, uint Idx, const(char)* Name);
static if (LLVM_Version >= asVersion(8, 0, 0)) {
    LLVMValueRef LLVMBuildGEP2(LLVMBuilderRef B, LLVMTypeRef Ty,
                               LLVMValueRef Pointer, LLVMValueRef* Indices,
                               uint NumIndices, const(char)* Name);
    LLVMValueRef LLVMBuildInBoundsGEP2(LLVMBuilderRef B, LLVMTypeRef Ty,
                                       LLVMValueRef Pointer, LLVMValueRef* Indices,
                                       uint NumIndices, const(char)* Name);
    LLVMValueRef LLVMBuildStructGEP2(LLVMBuilderRef B, LLVMTypeRef Ty,
                                     LLVMValueRef Pointer, uint Idx,
                                     const(char)* Name);
}
LLVMValueRef LLVMBuildGlobalString(LLVMBuilderRef B, const(char)* Str, const(char)* Name);
LLVMValueRef LLVMBuildGlobalStringPtr(LLVMBuilderRef B, const(char)* Str, const(char)* Name);
LLVMBool LLVMGetVolatile(LLVMValueRef MemoryAccessInst);
void LLVMSetVolatile(LLVMValueRef MemoryAccessInst, LLVMBool IsVolatile);
static if (LLVM_Version >= asVersion(10, 0, 0)) {
    LLVMBool LLVMGetWeak(LLVMValueRef CmpXchgInst);
    void LLVMSetWeak(LLVMValueRef CmpXchgInst, LLVMBool IsWeak);
}
static if (LLVM_Version >= asVersion(3, 8, 0)) {
    LLVMAtomicOrdering LLVMGetOrdering(LLVMValueRef MemoryAccessInst);
}
static if (LLVM_Version >= asVersion(3, 8, 0)) {
    void LLVMSetOrdering(LLVMValueRef MemoryAccessInst, LLVMAtomicOrdering Ordering);
}
static if (LLVM_Version >= asVersion(10, 0, 0)) {
    LLVMAtomicRMWBinOp LLVMGetAtomicRMWBinOp(LLVMValueRef AtomicRMWInst);
    void LLVMSetAtomicRMWBinOp(LLVMValueRef AtomicRMWInst, LLVMAtomicRMWBinOp BinOp);
}
LLVMValueRef LLVMBuildTrunc(LLVMBuilderRef, LLVMValueRef Val, LLVMTypeRef DestTy, const(char)* Name);
LLVMValueRef LLVMBuildZExt(LLVMBuilderRef, LLVMValueRef Val, LLVMTypeRef DestTy, const(char)* Name);
LLVMValueRef LLVMBuildSExt(LLVMBuilderRef, LLVMValueRef Val, LLVMTypeRef DestTy, const(char)* Name);
LLVMValueRef LLVMBuildFPToUI(LLVMBuilderRef, LLVMValueRef Val, LLVMTypeRef DestTy, const(char)* Name);
LLVMValueRef LLVMBuildFPToSI(LLVMBuilderRef, LLVMValueRef Val, LLVMTypeRef DestTy, const(char)* Name);
LLVMValueRef LLVMBuildUIToFP(LLVMBuilderRef, LLVMValueRef Val, LLVMTypeRef DestTy, const(char)* Name);
LLVMValueRef LLVMBuildSIToFP(LLVMBuilderRef, LLVMValueRef Val, LLVMTypeRef DestTy, const(char)* Name);
LLVMValueRef LLVMBuildFPTrunc(LLVMBuilderRef, LLVMValueRef Val, LLVMTypeRef DestTy, const(char)* Name);
LLVMValueRef LLVMBuildFPExt(LLVMBuilderRef, LLVMValueRef Val, LLVMTypeRef DestTy, const(char)* Name);
LLVMValueRef LLVMBuildPtrToInt(LLVMBuilderRef, LLVMValueRef Val, LLVMTypeRef DestTy, const(char)* Name);
LLVMValueRef LLVMBuildIntToPtr(LLVMBuilderRef, LLVMValueRef Val, LLVMTypeRef DestTy, const(char)* Name);
LLVMValueRef LLVMBuildBitCast(LLVMBuilderRef, LLVMValueRef Val, LLVMTypeRef DestTy, const(char)* Name);
static if (LLVM_Version >= asVersion(3, 4, 0)) {
    LLVMValueRef LLVMBuildAddrSpaceCast(LLVMBuilderRef, LLVMValueRef Val, LLVMTypeRef DestTy, const(char)* Name);
}
LLVMValueRef LLVMBuildZExtOrBitCast(LLVMBuilderRef, LLVMValueRef Val, LLVMTypeRef DestTy, const(char)* Name);
LLVMValueRef LLVMBuildSExtOrBitCast(LLVMBuilderRef, LLVMValueRef Val, LLVMTypeRef DestTy, const(char)* Name);
LLVMValueRef LLVMBuildTruncOrBitCast(LLVMBuilderRef, LLVMValueRef Val, LLVMTypeRef DestTy, const(char)* Name);
LLVMValueRef LLVMBuildCast(LLVMBuilderRef B, LLVMOpcode Op, LLVMValueRef Val, LLVMTypeRef DestTy, const(char)* Name);
LLVMValueRef LLVMBuildPointerCast(LLVMBuilderRef, LLVMValueRef Val, LLVMTypeRef DestTy, const(char)* Name);
static if (LLVM_Version >= asVersion(8, 0, 0)) {
    LLVMValueRef LLVMBuildIntCast2(LLVMBuilderRef, LLVMValueRef Val,
                                   LLVMTypeRef DestTy, LLVMBool IsSigned,
                                   const(char)* Name);
	deprecated("Use LLVMBuildIntCast2 instead.") LLVMValueRef LLVMBuildIntCast(LLVMBuilderRef, LLVMValueRef Val, LLVMTypeRef DestTy, const(char)* Name);
} else {
	LLVMValueRef LLVMBuildIntCast(LLVMBuilderRef, LLVMValueRef Val, LLVMTypeRef DestTy, const(char)* Name);
}
LLVMValueRef LLVMBuildFPCast(LLVMBuilderRef, LLVMValueRef Val, LLVMTypeRef DestTy, const(char)* Name);
LLVMValueRef LLVMBuildICmp(LLVMBuilderRef, LLVMIntPredicate Op, LLVMValueRef LHS, LLVMValueRef RHS, const(char)* Name);
LLVMValueRef LLVMBuildFCmp(LLVMBuilderRef, LLVMRealPredicate Op, LLVMValueRef LHS, LLVMValueRef RHS, const(char)* Name);
LLVMValueRef LLVMBuildPhi(LLVMBuilderRef, LLVMTypeRef Ty, const(char)* Name);
LLVMValueRef LLVMBuildCall(LLVMBuilderRef, LLVMValueRef Fn, LLVMValueRef* Args, uint NumArgs, const(char)* Name);
static if (LLVM_Version >= asVersion(8, 0, 0)) {
LLVMValueRef LLVMBuildCall2(LLVMBuilderRef, LLVMTypeRef, LLVMValueRef Fn,
                            LLVMValueRef* Args, uint NumArgs,
                            const(char)* Name);
}
LLVMValueRef LLVMBuildSelect(LLVMBuilderRef, LLVMValueRef If, LLVMValueRef Then, LLVMValueRef Else, const(char)* Name);
LLVMValueRef LLVMBuildVAArg(LLVMBuilderRef, LLVMValueRef List, LLVMTypeRef Ty, const(char)* Name);
LLVMValueRef LLVMBuildExtractElement(LLVMBuilderRef, LLVMValueRef VecVal, LLVMValueRef Index, const(char)* Name);
LLVMValueRef LLVMBuildInsertElement(LLVMBuilderRef, LLVMValueRef VecVal, LLVMValueRef EltVal, LLVMValueRef Index, const(char)* Name);
LLVMValueRef LLVMBuildShuffleVector(LLVMBuilderRef, LLVMValueRef V1, LLVMValueRef V2, LLVMValueRef Mask, const(char)* Name);
LLVMValueRef LLVMBuildExtractValue(LLVMBuilderRef, LLVMValueRef AggVal, uint Index, const(char)* Name);
LLVMValueRef LLVMBuildInsertValue(LLVMBuilderRef, LLVMValueRef AggVal, LLVMValueRef EltVal, uint Index, const(char)* Name);
static if (LLVM_Version >= asVersion(10, 0, 0)) {
    LLVMValueRef LLVMBuildFreeze(LLVMBuilderRef, LLVMValueRef Val, const(char)* Name);
}
LLVMValueRef LLVMBuildIsNull(LLVMBuilderRef, LLVMValueRef Val, const(char)* Name);
LLVMValueRef LLVMBuildIsNotNull(LLVMBuilderRef, LLVMValueRef Val, const(char)* Name);
LLVMValueRef LLVMBuildPtrDiff(LLVMBuilderRef, LLVMValueRef LHS, LLVMValueRef RHS, const(char)* Name);
static if (LLVM_Version >= asVersion(3, 3, 0)) {
    LLVMValueRef LLVMBuildAtomicRMW(LLVMBuilderRef B, LLVMAtomicRMWBinOp op, LLVMValueRef PTR, LLVMValueRef Val, LLVMAtomicOrdering ordering, LLVMBool singleThread);
}

static if (LLVM_Version >= asVersion(3, 9, 0)) {
    LLVMValueRef LLVMBuildAtomicCmpXchg(LLVMBuilderRef B, LLVMValueRef Ptr, LLVMValueRef Cmp, LLVMValueRef New, LLVMAtomicOrdering SuccessOrdering, LLVMAtomicOrdering FailureOrdering, LLVMBool SingleThread);
}
static if (LLVM_Version >= asVersion(3, 9, 0)) {
    LLVMBool LLVMIsAtomicSingleThread(LLVMValueRef AtomicInst);
}
static if (LLVM_Version >= asVersion(3, 9, 0)) {
    void LLVMSetAtomicSingleThread(LLVMValueRef AtomicInst, LLVMBool SingleThread);
}
static if (LLVM_Version >= asVersion(3, 9, 0)) {
    LLVMAtomicOrdering LLVMGetCmpXchgSuccessOrdering(LLVMValueRef CmpXchgInst);
}
static if (LLVM_Version >= asVersion(3, 9, 0)) {
    void LLVMSetCmpXchgSuccessOrdering(LLVMValueRef CmpXchgInst, LLVMAtomicOrdering Ordering);
}
static if (LLVM_Version >= asVersion(3, 9, 0)) {
    LLVMAtomicOrdering LLVMGetCmpXchgFailureOrdering(LLVMValueRef CmpXchgInst);
}
static if (LLVM_Version >= asVersion(3, 9, 0)) {
    void LLVMSetCmpXchgFailureOrdering(LLVMValueRef CmpXchgInst, LLVMAtomicOrdering Ordering);
}

static if (LLVM_Version >= asVersion(3, 5, 0)) {
    LLVMValueRef LLVMBuildFence(LLVMBuilderRef B, LLVMAtomicOrdering ordering, LLVMBool singleThread, const(char)*Name);
}

/++ Module Providers ++/

LLVMModuleProviderRef LLVMCreateModuleProviderForExistingModule(LLVMModuleRef M);
void LLVMDisposeModuleProvider(LLVMModuleProviderRef M);

/++ Memory Buffers ++/

LLVMBool LLVMCreateMemoryBufferWithContentsOfFile(const(char)* Path, LLVMMemoryBufferRef* OutMemBuf, char** OutMessage);
LLVMBool LLVMCreateMemoryBufferWithSTDIN(LLVMMemoryBufferRef* OutMemBuf, char** OutMessage);
static if (LLVM_Version >= asVersion(3, 3, 0)) {
    LLVMMemoryBufferRef LLVMCreateMemoryBufferWithMemoryRange(const(char)* InputData, size_t InputDataLength, const(char)* BufferName, LLVMBool RequiresNullTerminator);
}
static if (LLVM_Version >= asVersion(3, 3, 0)) {
    LLVMMemoryBufferRef LLVMCreateMemoryBufferWithMemoryRangeCopy(const(char)* InputData, size_t InputDataLength, const(char)* BufferName);
}
static if (LLVM_Version >= asVersion(3, 3, 0)) {
    const(char)* LLVMGetBufferStart(LLVMMemoryBufferRef MemBuf);
}
static if (LLVM_Version >= asVersion(3, 3, 0)) {
    size_t LLVMGetBufferSize(LLVMMemoryBufferRef MemBuf);
}
void LLVMDisposeMemoryBuffer(LLVMMemoryBufferRef MemBuf);

/++ Pass Registry ++/

LLVMPassRegistryRef LLVMGetGlobalPassRegistry();

/++ Pass Managers ++/

LLVMPassManagerRef LLVMCreatePassManager();
LLVMPassManagerRef LLVMCreateFunctionPassManagerForModule(LLVMModuleRef M);
LLVMPassManagerRef LLVMCreateFunctionPassManager(LLVMModuleProviderRef MP);
LLVMBool LLVMRunPassManager(LLVMPassManagerRef PM, LLVMModuleRef M);
LLVMBool LLVMInitializeFunctionPassManager(LLVMPassManagerRef FPM);
LLVMBool LLVMRunFunctionPassManager(LLVMPassManagerRef FPM, LLVMValueRef F);
LLVMBool LLVMFinalizeFunctionPassManager(LLVMPassManagerRef FPM);
void LLVMDisposePassManager(LLVMPassManagerRef PM);

/++ Threading ++/

static if (LLVM_Version >= asVersion(3, 3, 0) && LLVM_Version < asVersion(3, 5, 0)) {
    LLVMBool LLVMStartMultithreaded();
}
static if (LLVM_Version >= asVersion(3, 3, 0) && LLVM_Version < asVersion(3, 5, 0)) {
    void LLVMStopMultithreaded();
}
static if (LLVM_Version >= asVersion(3, 3, 0)) {
    LLVMBool LLVMIsMultithreaded();
}

/+ Disassembler +/

LLVMDisasmContextRef LLVMCreateDisasm(const(char)* TripleName, void* DisInfo, int TagType, LLVMOpInfoCallback GetOpInfo, LLVMSymbolLookupCallback SymbolLookUp);
static if (LLVM_Version >= asVersion(3, 3, 0)) {
    LLVMDisasmContextRef LLVMCreateDisasmCPU(const(char)* Triple, const(char)* CPU, void* DisInfo, int TagType, LLVMOpInfoCallback GetOpInfo, LLVMSymbolLookupCallback SymbolLookUp);
}
static if (LLVM_Version >= asVersion(3, 6, 0)) {
    LLVMDisasmContextRef LLVMCreateDisasmCPUFeatures(const(char)* Triple, const(char)* CPU, const(char)* Features, void *DisInfo, int TagType, LLVMOpInfoCallback GetOpInfo, LLVMSymbolLookupCallback SymbolLookUp);
}
static if (LLVM_Version >= asVersion(3, 2, 0)) {
    int LLVMSetDisasmOptions(LLVMDisasmContextRef DC, ulong Options);
}
void LLVMDisasmDispose(LLVMDisasmContextRef DC);
size_t LLVMDisasmInstruction(LLVMDisasmContextRef DC, ubyte* Bytes, ulong BytesSize, ulong PC, char* OutString, size_t OutStringSize);

/+ Enhanced Disassembly +/

static if (LLVM_Version < asVersion(3, 3, 0)) {
    int EDGetDisassembler(EDDisassemblerRef* disassembler, const(char)* triple, EDAssemblySyntax_t syntax);
}
static if (LLVM_Version < asVersion(3, 3, 0)) {
    int EDGetRegisterName(const(char)** regName, EDDisassemblerRef disassembler, uint regID);
}
static if (LLVM_Version < asVersion(3, 3, 0)) {
    int EDRegisterIsStackPointer(EDDisassemblerRef disassembler, uint regID);
}
static if (LLVM_Version < asVersion(3, 3, 0)) {
    int EDRegisterIsProgramCounter(EDDisassemblerRef disassembler, uint regID);
}
static if (LLVM_Version < asVersion(3, 3, 0)) {
    uint EDCreateInsts(EDInstRef* insts, uint count, EDDisassemblerRef disassembler, EDByteReaderCallback byteReader, ulong address, void* arg);
}
static if (LLVM_Version < asVersion(3, 3, 0)) {
    void EDReleaseInst(EDInstRef inst);
}
static if (LLVM_Version < asVersion(3, 3, 0)) {
    int EDInstByteSize(EDInstRef inst);
}
static if (LLVM_Version < asVersion(3, 3, 0)) {
    int EDGetInstString(const(char)** buf, EDInstRef inst);
}
static if (LLVM_Version < asVersion(3, 3, 0)) {
    int EDInstID(uint* instID, EDInstRef inst);
}
static if (LLVM_Version < asVersion(3, 3, 0)) {
    int EDInstIsBranch(EDInstRef inst);
}
static if (LLVM_Version < asVersion(3, 3, 0)) {
    int EDInstIsMove(EDInstRef inst);
}
static if (LLVM_Version < asVersion(3, 3, 0)) {
    int EDBranchTargetID(EDInstRef inst);
}
static if (LLVM_Version < asVersion(3, 3, 0)) {
    int EDMoveSourceID(EDInstRef inst);
}
static if (LLVM_Version < asVersion(3, 3, 0)) {
    int EDMoveTargetID(EDInstRef inst);
}
static if (LLVM_Version < asVersion(3, 3, 0)) {
    int EDNumTokens(EDInstRef inst);
}
static if (LLVM_Version < asVersion(3, 3, 0)) {
    int EDGetToken(EDTokenRef* token, EDInstRef inst, int index);
}
static if (LLVM_Version < asVersion(3, 3, 0)) {
    int EDGetTokenString(const(char)** buf, EDTokenRef token);
}
static if (LLVM_Version < asVersion(3, 3, 0)) {
    int EDOperandIndexForToken(EDTokenRef token);
}
static if (LLVM_Version < asVersion(3, 3, 0)) {
    int EDTokenIsWhitespace(EDTokenRef token);
}
static if (LLVM_Version < asVersion(3, 3, 0)) {
    int EDTokenIsPunctuation(EDTokenRef token);
}
static if (LLVM_Version < asVersion(3, 3, 0)) {
    int EDTokenIsOpcode(EDTokenRef token);
}
static if (LLVM_Version < asVersion(3, 3, 0)) {
    int EDTokenIsLiteral(EDTokenRef token);
}
static if (LLVM_Version < asVersion(3, 3, 0)) {
    int EDTokenIsRegister(EDTokenRef token);
}
static if (LLVM_Version < asVersion(3, 3, 0)) {
    int EDTokenIsNegativeLiteral(EDTokenRef token);
}
static if (LLVM_Version < asVersion(3, 3, 0)) {
    int EDLiteralTokenAbsoluteValue(ulong* value, EDTokenRef token);
}
static if (LLVM_Version < asVersion(3, 3, 0)) {
    int EDRegisterTokenValue(uint* registerID, EDTokenRef token);
}
static if (LLVM_Version < asVersion(3, 3, 0)) {
    int EDNumOperands(EDInstRef inst);
}
static if (LLVM_Version < asVersion(3, 3, 0)) {
    int EDGetOperand(EDOperandRef* operand, EDInstRef inst, int index);
}
static if (LLVM_Version < asVersion(3, 3, 0)) {
    int EDOperandIsRegister(EDOperandRef operand);
}
static if (LLVM_Version < asVersion(3, 3, 0)) {
    int EDOperandIsImmediate(EDOperandRef operand);
}
static if (LLVM_Version < asVersion(3, 3, 0)) {
    int EDOperandIsMemory(EDOperandRef operand);
}
static if (LLVM_Version < asVersion(3, 3, 0)) {
    int EDRegisterOperandValue(uint* value, EDOperandRef operand);
}
static if (LLVM_Version < asVersion(3, 3, 0)) {
    int EDImmediateOperandValue(ulong* value, EDOperandRef operand);
}
static if (LLVM_Version < asVersion(3, 3, 0)) {
    int EDEvaluateOperand(ulong* result, EDOperandRef operand, EDRegisterReaderCallback regReader, void* arg);
}
static if (LLVM_Version < asVersion(3, 3, 0)) {
    uint EDBlockCreateInsts(EDInstRef* insts, int count, EDDisassemblerRef disassembler, EDByteBlock_t byteBlock, ulong address);
}
static if (LLVM_Version < asVersion(3, 3, 0)) {
    int EDBlockEvaluateOperand(ulong* result, EDOperandRef operand, EDRegisterBlock_t regBlock);
}
static if (LLVM_Version < asVersion(3, 3, 0)) {
    int EDBlockVisitTokens(EDInstRef inst, EDTokenVisitor_t visitor);
}

/+ Execution Engine +/

LLVMGenericValueRef LLVMCreateGenericValueOfInt(LLVMTypeRef Ty, ulong N, LLVMBool IsSigned);
LLVMGenericValueRef LLVMCreateGenericValueOfPointer(void* P);
LLVMGenericValueRef LLVMCreateGenericValueOfFloat(LLVMTypeRef Ty, double N);
uint LLVMGenericValueIntWidth(LLVMGenericValueRef GenValRef);
ulong LLVMGenericValueToInt(LLVMGenericValueRef GenVal, LLVMBool IsSigned);
void* LLVMGenericValueToPointer(LLVMGenericValueRef GenVal);
double LLVMGenericValueToFloat(LLVMTypeRef TyRef, LLVMGenericValueRef GenVal);
void LLVMDisposeGenericValue(LLVMGenericValueRef GenVal);
LLVMBool LLVMCreateExecutionEngineForModule(LLVMExecutionEngineRef* OutEE, LLVMModuleRef M, char** OutError);
LLVMBool LLVMCreateInterpreterForModule(LLVMExecutionEngineRef* OutInterp, LLVMModuleRef M, char** OutError);
LLVMBool LLVMCreateJITCompilerForModule(LLVMExecutionEngineRef* OutJIT, LLVMModuleRef M, uint OptLevel, char** OutError);
static if (LLVM_Version >= asVersion(3, 3, 0)) {
    void LLVMInitializeMCJITCompilerOptions(LLVMMCJITCompilerOptions* Options, size_t SizeOfOptions);
}
static if (LLVM_Version >= asVersion(3, 3, 0)) {
    LLVMBool LLVMCreateMCJITCompilerForModule(LLVMExecutionEngineRef* OutJIT, LLVMModuleRef M, LLVMMCJITCompilerOptions* Options, size_t SizeOfOptions, char** OutError);
}
static if (LLVM_Version < asVersion(3, 8, 0)) {
    LLVMBool LLVMCreateExecutionEngine(LLVMExecutionEngineRef* OutEE, LLVMModuleProviderRef MP, char** OutError);
}
static if (LLVM_Version < asVersion(3, 8, 0)) {
    LLVMBool LLVMCreateInterpreter(LLVMExecutionEngineRef* OutInterp, LLVMModuleProviderRef MP, char** OutError);
}
static if (LLVM_Version < asVersion(3, 8, 0)) {
    LLVMBool LLVMCreateJITCompiler(LLVMExecutionEngineRef* OutJIT, LLVMModuleProviderRef MP, uint OptLevel, char** OutError);
}
void LLVMDisposeExecutionEngine(LLVMExecutionEngineRef EE);
void LLVMRunStaticConstructors(LLVMExecutionEngineRef EE);
void LLVMRunStaticDestructors(LLVMExecutionEngineRef EE);
int LLVMRunFunctionAsMain(LLVMExecutionEngineRef EE, LLVMValueRef F, uint ArgC, const(char*)* ArgV, const(char*)* EnvP);
LLVMGenericValueRef LLVMRunFunction(LLVMExecutionEngineRef EE, LLVMValueRef F, uint NumArgs, LLVMGenericValueRef* Args);
void LLVMFreeMachineCodeForFunction(LLVMExecutionEngineRef EE, LLVMValueRef F);
void LLVMAddModule(LLVMExecutionEngineRef EE, LLVMModuleRef M);
static if (LLVM_Version < asVersion(3, 8, 0)) {
    void LLVMAddModuleProvider(LLVMExecutionEngineRef EE, LLVMModuleProviderRef MP);
}
LLVMBool LLVMRemoveModule(LLVMExecutionEngineRef EE, LLVMModuleRef M, LLVMModuleRef* OutMod, char** OutError);
static if (LLVM_Version < asVersion(3, 8, 0)) {
    LLVMBool LLVMRemoveModuleProvider(LLVMExecutionEngineRef EE, LLVMModuleProviderRef MP, LLVMModuleRef* OutMod, char** OutError);
}
LLVMBool LLVMFindFunction(LLVMExecutionEngineRef EE, const(char)* Name, LLVMValueRef* OutFn);
void* LLVMRecompileAndRelinkFunction(LLVMExecutionEngineRef EE, LLVMValueRef Fn);
LLVMTargetDataRef LLVMGetExecutionEngineTargetData(LLVMExecutionEngineRef EE);
static if (LLVM_Version >= asVersion(3, 5, 0)) {
    LLVMTargetMachineRef LLVMGetExecutionEngineTargetMachine(LLVMExecutionEngineRef EE);
}
void LLVMAddGlobalMapping(LLVMExecutionEngineRef EE, LLVMValueRef Global, void* Addr);
void* LLVMGetPointerToGlobal(LLVMExecutionEngineRef EE, LLVMValueRef Global);
static if (LLVM_Version >= asVersion(3, 6, 0)) {
    ulong LLVMGetGlobalValueAddress(LLVMExecutionEngineRef EE, const(char)*Name);
}
static if (LLVM_Version >= asVersion(3, 6, 0)) {
    ulong LLVMGetFunctionAddress(LLVMExecutionEngineRef EE, const(char)*Name);
}
static if (LLVM_Version >= asVersion(3, 4, 0)) {
    LLVMMCJITMemoryManagerRef LLVMCreateSimpleMCJITMemoryManager(void* Opaque, LLVMMemoryManagerAllocateCodeSectionCallback AllocateCodeSection, LLVMMemoryManagerAllocateDataSectionCallback AllocateDataSection, LLVMMemoryManagerFinalizeMemoryCallback FinalizeMemory, LLVMMemoryManagerDestroyCallback Destroy);
}
static if (LLVM_Version >= asVersion(3, 4, 0)) {
    void LLVMDisposeMCJITMemoryManager(LLVMMCJITMemoryManagerRef MM);
}

/+ Initialization Routines +/

void LLVMInitializeCore(LLVMPassRegistryRef R);
void LLVMInitializeTransformUtils(LLVMPassRegistryRef R);
void LLVMInitializeScalarOpts(LLVMPassRegistryRef R);
static if (LLVM_Version >= asVersion(3, 3, 0)) {
    void LLVMInitializeObjCARCOpts(LLVMPassRegistryRef R);
}
void LLVMInitializeVectorization(LLVMPassRegistryRef R);
void LLVMInitializeInstCombine(LLVMPassRegistryRef R);
void LLVMInitializeIPO(LLVMPassRegistryRef R);
void LLVMInitializeInstrumentation(LLVMPassRegistryRef R);
void LLVMInitializeAnalysis(LLVMPassRegistryRef R);
void LLVMInitializeIPA(LLVMPassRegistryRef R);
void LLVMInitializeCodeGen(LLVMPassRegistryRef R);
void LLVMInitializeTarget(LLVMPassRegistryRef R);

/+ Linker +/

static if (LLVM_Version >= asVersion(3, 2, 0) && LLVM_Version < asVersion(3, 9, 0)) {
    LLVMBool LLVMLinkModules(LLVMModuleRef Dest, LLVMModuleRef Src, LLVMLinkerMode Mode, char** OutMessage);
}
static if (LLVM_Version >= asVersion(3, 8, 0)) {
    LLVMBool LLVMLinkModules2(LLVMModuleRef Dest, LLVMModuleRef Src);
}

/+ LTO +/

const(char)* lto_get_version();
const(char)* lto_get_error_message();
bool lto_module_is_object_file(const(char)* path);
bool lto_module_is_object_file_for_target(const(char)* path, const(char)* target_triple_prefix);
static if (LLVM_Version >= asVersion(3, 9, 0)) {
    lto_bool_t lto_module_has_objc_category(const(void)* mem, size_t length);
}
bool lto_module_is_object_file_in_memory(const(void)* mem, size_t length);
bool lto_module_is_object_file_in_memory_for_target(const(void)* mem, size_t length, const(char)* target_triple_prefix);
lto_module_t lto_module_create(const(char)* path);
lto_module_t lto_module_create_from_memory(const(void)* mem, size_t length);
static if (LLVM_Version >= asVersion(3, 5, 0)) {
    lto_module_t lto_module_create_from_memory_with_path(const(void)* mem, size_t length, const(char)*path);
}

static if (LLVM_Version >= asVersion(3, 6, 0)) {
    lto_module_t lto_module_create_in_local_context(const(void)* mem, size_t length, const(char)*path);
}
static if (LLVM_Version >= asVersion(3, 6, 0)) {
    lto_module_t lto_module_create_in_codegen_context(const(void)* mem, size_t length, const(char)*path, lto_code_gen_t cg);
}
lto_module_t lto_module_create_from_fd(int fd, const(char)* path, size_t file_size);
lto_module_t lto_module_create_from_fd_at_offset(int fd, const(char)* path, size_t file_size, size_t map_size, size_t offset);
void lto_module_dispose(lto_module_t mod);
const(char)* lto_module_get_target_triple(lto_module_t mod);
void lto_module_set_target_triple(lto_module_t mod, const(char)* triple);
uint lto_module_get_num_symbols(lto_module_t mod);
const(char)* lto_module_get_symbol_name(lto_module_t mod, uint index);
lto_symbol_attributes lto_module_get_symbol_attribute(lto_module_t mod, uint index);
static if (LLVM_Version >= asVersion(3, 5, 0) && LLVM_Version < asVersion(3, 7, 0)) {
    uint lto_module_get_num_deplibs(lto_module_t mod);
}
static if (LLVM_Version >= asVersion(3, 5, 0) && LLVM_Version < asVersion(3, 7, 0)) {
    const(char)* lto_module_get_deplib(lto_module_t mod, uint index);
}
static if (LLVM_Version >= asVersion(3, 5, 0) && LLVM_Version < asVersion(3, 7, 0)) {
    uint lto_module_get_num_linkeropts(lto_module_t mod);
}
static if (LLVM_Version >= asVersion(3, 5, 0) && LLVM_Version < asVersion(3, 7, 0)) {
    const(char)* lto_module_get_linkeropt(lto_module_t mod, uint index);
}
static if (LLVM_Version >= asVersion(3, 7, 0)) {
    const(char)* lto_module_get_linkeropts(lto_module_t mod);
}
static if (LLVM_Version >= asVersion(3, 5, 0)) {
    void lto_codegen_set_diagnostic_handler(lto_code_gen_t, lto_diagnostic_handler_t, void *);
}
lto_code_gen_t lto_codegen_create();
static if (LLVM_Version >= asVersion(3, 6, 0)) {
    lto_code_gen_t lto_codegen_create_in_local_context();
}
void lto_codegen_dispose(lto_code_gen_t);
bool lto_codegen_add_module(lto_code_gen_t cg, lto_module_t mod);
bool lto_codegen_set_debug_model(lto_code_gen_t cg, lto_debug_model);
bool lto_codegen_set_pic_model(lto_code_gen_t cg, lto_codegen_model);
void lto_codegen_set_cpu(lto_code_gen_t cg, const(char)* cpu);
void lto_codegen_set_assembler_path(lto_code_gen_t cg, const(char)* path);
void lto_codegen_set_assembler_args(lto_code_gen_t cg, const(char)** args, int nargs);
void lto_codegen_add_must_preserve_symbol(lto_code_gen_t cg, const(char)* symbol);
bool lto_codegen_write_merged_modules(lto_code_gen_t cg, const(char)* path);
const(void)* lto_codegen_compile(lto_code_gen_t cg, size_t* length);
bool lto_codegen_compile_to_file(lto_code_gen_t cg, const(char)** name);
static if (LLVM_Version >= asVersion(3, 7, 0)) {
    bool lto_codegen_optimize(lto_code_gen_t cg);
}
static if (LLVM_Version >= asVersion(3, 7, 0)) {
    const(void)* lto_codegen_compile_optimized(lto_code_gen_t cg, size_t* length);
}
static if (LLVM_Version >= asVersion(3, 7, 0)) {
    uint lto_api_version();
}
void lto_codegen_debug_options(lto_code_gen_t cg, const(char)* );
static if (LLVM_Version >= asVersion(10, 0, 0)) {
    void lto_codegen_debug_options_array(lto_code_gen_t cg, const(char*)*, int number);
}
static if (LLVM_Version >= asVersion(3, 3, 0)) {
    void lto_initialize_disassembler();
}
static if (LLVM_Version >= asVersion(3, 7, 0)) {
    void lto_codegen_set_should_internalize(lto_code_gen_t cg, bool ShouldInternalize);
}
static if (LLVM_Version >= asVersion(3, 7, 0)) {
    void lto_codegen_set_should_embed_uselists(lto_code_gen_t cg, bool ShouldEmbedUselists);
}

static if (LLVM_Version >= asVersion(10, 0, 0)) {
    const(char*)* lto_runtime_lib_symbols_list(size_t* size);
}

static if (LLVM_Version >= asVersion(3, 9, 0)) {
    thinlto_code_gen_t thinlto_create_codegen();
}
static if (LLVM_Version >= asVersion(3, 9, 0)) {
    void thinlto_codegen_dispose(thinlto_code_gen_t cg);
}
static if (LLVM_Version >= asVersion(3, 9, 0)) {
    void thinlto_codegen_add_module(thinlto_code_gen_t cg, const(char)* identifier, const(char)* data, int length);
}
static if (LLVM_Version >= asVersion(3, 9, 0)) {
    void thinlto_codegen_process(thinlto_code_gen_t cg);
}
static if (LLVM_Version >= asVersion(3, 9, 0)) {
    uint thinlto_module_get_num_objects(thinlto_code_gen_t cg);
}
static if (LLVM_Version >= asVersion(3, 9, 0)) {
    LTOObjectBuffer thinlto_module_get_object(thinlto_code_gen_t cg, uint index);
}
static if (LLVM_Version >= asVersion(4, 0, 0)) {
	uint thinlto_module_get_num_object_files(thinlto_code_gen_t cg);
	const(char)* thinlto_module_get_object_file(thinlto_code_gen_t cg, uint index);
}
static if (LLVM_Version >= asVersion(3, 9, 0)) {
    lto_bool_t thinlto_codegen_set_pic_model(thinlto_code_gen_t cg, lto_codegen_model);
}
static if (LLVM_Version >= asVersion(3, 9, 0)) {
    void thinlto_codegen_set_cache_dir(thinlto_code_gen_t cg, const(char)* cache_dir);
}
static if (LLVM_Version >= asVersion(3, 9, 0)) {
    void thinlto_codegen_set_cache_pruning_interval(thinlto_code_gen_t cg, int interval);
}
static if (LLVM_Version >= asVersion(3, 9, 0)) {
    void thinlto_codegen_set_final_cache_size_relative_to_available_space(thinlto_code_gen_t cg, uint percentage);
}
static if (LLVM_Version >= asVersion(3, 9, 0)) {
    void thinlto_codegen_set_cache_entry_expiration(thinlto_code_gen_t cg, uint expiration);
}
static if (LLVM_Version >= asVersion(3, 9, 0)) {
    void thinlto_codegen_set_savetemps_dir(thinlto_code_gen_t cg, const(char)* save_temps_dir);
}
static if (LLVM_Version >= asVersion(4, 0, 0)) {
	void thinlto_set_generated_objects_dir(thinlto_code_gen_t cg, const(char)* save_temps_dir);
}
static if (LLVM_Version >= asVersion(3, 9, 0)) {
    void thinlto_codegen_set_cpu(thinlto_code_gen_t cg, const(char)* cpu);
}
static if (LLVM_Version >= asVersion(3, 9, 0)) {
    void thinlto_codegen_disable_codegen(thinlto_code_gen_t cg, lto_bool_t disable);
}
static if (LLVM_Version >= asVersion(3, 9, 0)) {
    void thinlto_codegen_set_codegen_only(thinlto_code_gen_t cg, lto_bool_t codegen_only);
}
static if (LLVM_Version >= asVersion(3, 9, 0)) {
    void thinlto_debug_options(const(char*) *options, int number);
}
static if (LLVM_Version >= asVersion(3, 9, 0)) {
    lto_bool_t lto_module_is_thinlto(lto_module_t mod);
}
static if (LLVM_Version >= asVersion(3, 9, 0)) {
    void thinlto_codegen_add_must_preserve_symbol(thinlto_code_gen_t cg, const(char)* name, int length);
}
static if (LLVM_Version >= asVersion(3, 9, 0)) {
    void thinlto_codegen_add_cross_referenced_symbol(thinlto_code_gen_t cg, const(char)* name, int length);
}
static if (LLVM_Version >= asVersion(7, 0, 0)) {
	void thinlto_codegen_set_cache_size_bytes(thinlto_code_gen_t cg, uint max_size_bytes);
}
static if (LLVM_Version >= asVersion(8, 0, 0)) {
	void thinlto_codegen_set_cache_size_megabytes(thinlto_code_gen_t cg, uint max_size_megabytes);
}

static if (LLVM_Version >= asVersion(7, 0, 0)) {
	void thinlto_codegen_set_cache_size_files(thinlto_code_gen_t cg, uint max_size_files);
}

static if (LLVM_Version >= asVersion(9, 0, 0)) {
    lto_input_t lto_input_create(const(void)* buffer, size_t buffer_size, const(char)* path);

    void lto_input_dispose(lto_input_t input);

    uint lto_input_get_num_dependent_libraries(lto_input_t input);

    const(char)*  lto_input_get_dependent_library(lto_input_t input, size_t index, size_t* size);
}

/+ Object file reading and writing +/

static if (LLVM_Version >= asVersion(9, 0, 0)) {
    LLVMBinaryRef LLVMCreateBinary(LLVMMemoryBufferRef MemBuf, LLVMContextRef Context, char** ErrorMessage);
    void LLVMDisposeBinary(LLVMBinaryRef BR);
    LLVMMemoryBufferRef LLVMBinaryCopyMemoryBuffer(LLVMBinaryRef BR);
    LLVMBinaryType LLVMBinaryGetType(LLVMBinaryRef BR);
    LLVMBinaryRef LLVMMachOUniversalBinaryCopyObjectForArch(LLVMBinaryRef BR, const(char)* Arch, size_t ArchLen, char** ErrorMessage);
    LLVMSectionIteratorRef LLVMObjectFileCopySectionIterator(LLVMBinaryRef BR);
    LLVMBool LLVMObjectFileIsSectionIteratorAtEnd(LLVMBinaryRef BR, LLVMSectionIteratorRef SI);
    LLVMSymbolIteratorRef LLVMObjectFileCopySymbolIterator(LLVMBinaryRef BR);
    LLVMBool LLVMObjectFileIsSymbolIteratorAtEnd(LLVMBinaryRef BR, LLVMSymbolIteratorRef SI);

    deprecated("Use LLVMCreateBinary instead.") LLVMObjectFileRef LLVMCreateObjectFile(LLVMMemoryBufferRef MemBuf);
    deprecated("Use LLVMDisposeBinary instead.") void LLVMDisposeObjectFile(LLVMObjectFileRef ObjectFile);
    deprecated("Use LLVMObjectFileCopySectionIterator instead.") LLVMSectionIteratorRef LLVMGetSections(LLVMObjectFileRef ObjectFile);
    deprecated("Use LLVMObjectFileIsSectionIteratorAtEnd instead.") LLVMBool LLVMIsSectionIteratorAtEnd(LLVMObjectFileRef ObjectFile, LLVMSectionIteratorRef SI);
    deprecated("Use LLVMObjectFileCopySymbolIterator instead.") LLVMSymbolIteratorRef LLVMGetSymbols(LLVMObjectFileRef ObjectFile);
    deprecated("Use LLVMObjectFileIsSymbolIteratorAtEnd instead.") LLVMBool LLVMIsSymbolIteratorAtEnd(LLVMObjectFileRef ObjectFile, LLVMSymbolIteratorRef SI);
} else {
    LLVMObjectFileRef LLVMCreateObjectFile(LLVMMemoryBufferRef MemBuf);
    void LLVMDisposeObjectFile(LLVMObjectFileRef ObjectFile);
    LLVMSectionIteratorRef LLVMGetSections(LLVMObjectFileRef ObjectFile);
    LLVMBool LLVMIsSectionIteratorAtEnd(LLVMObjectFileRef ObjectFile, LLVMSectionIteratorRef SI);
    LLVMSymbolIteratorRef LLVMGetSymbols(LLVMObjectFileRef ObjectFile);
    LLVMBool LLVMIsSymbolIteratorAtEnd(LLVMObjectFileRef ObjectFile, LLVMSymbolIteratorRef SI);
}

void LLVMDisposeSectionIterator(LLVMSectionIteratorRef SI);
void LLVMMoveToNextSection(LLVMSectionIteratorRef SI);
void LLVMMoveToContainingSection(LLVMSectionIteratorRef Sect, LLVMSymbolIteratorRef Sym);
void LLVMDisposeSymbolIterator(LLVMSymbolIteratorRef SI);
void LLVMMoveToNextSymbol(LLVMSymbolIteratorRef SI);
const(char)* LLVMGetSectionName(LLVMSectionIteratorRef SI);
ulong LLVMGetSectionSize(LLVMSectionIteratorRef SI);
const(char)* LLVMGetSectionContents(LLVMSectionIteratorRef SI);
ulong LLVMGetSectionAddress(LLVMSectionIteratorRef SI);
LLVMBool LLVMGetSectionContainsSymbol(LLVMSectionIteratorRef SI, LLVMSymbolIteratorRef Sym);
LLVMRelocationIteratorRef LLVMGetRelocations(LLVMSectionIteratorRef Section);
void LLVMDisposeRelocationIterator(LLVMRelocationIteratorRef RI);
LLVMBool LLVMIsRelocationIteratorAtEnd(LLVMSectionIteratorRef Section, LLVMRelocationIteratorRef RI);
void LLVMMoveToNextRelocation(LLVMRelocationIteratorRef RI);
const(char)* LLVMGetSymbolName(LLVMSymbolIteratorRef SI);
ulong LLVMGetSymbolAddress(LLVMSymbolIteratorRef SI);
static if (LLVM_Version < asVersion(3, 5, 0)) {
    ulong LLVMGetSymbolFileOffset(LLVMSymbolIteratorRef SI);
}
ulong LLVMGetSymbolSize(LLVMSymbolIteratorRef SI);
static if (LLVM_Version < asVersion(3, 7, 0)) {
    ulong LLVMGetRelocationAddress(LLVMRelocationIteratorRef RI);
}
ulong LLVMGetRelocationOffset(LLVMRelocationIteratorRef RI);
LLVMSymbolIteratorRef LLVMGetRelocationSymbol(LLVMRelocationIteratorRef RI);
ulong LLVMGetRelocationType(LLVMRelocationIteratorRef RI);
const(char)* LLVMGetRelocationTypeName(LLVMRelocationIteratorRef RI);
const(char)* LLVMGetRelocationValueString(LLVMRelocationIteratorRef RI);

/+ Target information +/

mixin(LLVM_Targets.map!(t => "nothrow void LLVMInitialize" ~ t ~ "TargetInfo();").joiner.array.orEmpty);
mixin(LLVM_Targets.map!(t => "nothrow void LLVMInitialize" ~ t ~ "Target();").joiner.array.orEmpty);
mixin(LLVM_Targets.map!(t => "nothrow void LLVMInitialize" ~ t ~ "TargetMC();").joiner.array.orEmpty);
mixin(LLVM_AsmPrinters.map!(t => "nothrow void LLVMInitialize" ~ t ~ "AsmPrinter();").joiner.array.orEmpty);
mixin(LLVM_AsmParsers.map!(t => "nothrow void LLVMInitialize" ~ t ~ "AsmParser();").joiner.array.orEmpty);
mixin(LLVM_Disassemblers.map!(t => "nothrow void LLVMInitialize" ~ t ~ "Disassembler();").joiner.array.orEmpty);

static if (LLVM_Version >= asVersion(3, 9, 0)) {
    LLVMTargetDataRef LLVMGetModuleDataLayout(LLVMModuleRef M);
}
static if (LLVM_Version >= asVersion(3, 9, 0)) {
    void LLVMSetModuleDataLayout(LLVMModuleRef M, LLVMTargetDataRef DL);
}
LLVMTargetDataRef LLVMCreateTargetData(const(char)* StringRep);
static if (LLVM_Version < asVersion(3, 9, 0)) {
    void LLVMAddTargetData(LLVMTargetDataRef TD, LLVMPassManagerRef PM);
}
void LLVMAddTargetLibraryInfo(LLVMTargetLibraryInfoRef TLI, LLVMPassManagerRef PM);
char* LLVMCopyStringRepOfTargetData(LLVMTargetDataRef TD);
LLVMByteOrdering LLVMByteOrder(LLVMTargetDataRef TD);
uint LLVMPointerSize(LLVMTargetDataRef TD);
static if (LLVM_Version >= asVersion(3, 2, 0)) {
    uint LLVMPointerSizeForAS(LLVMTargetDataRef TD, uint AS);
}
LLVMTypeRef LLVMIntPtrType(LLVMTargetDataRef TD);
static if (LLVM_Version >= asVersion(3, 2, 0)) {
    LLVMTypeRef LLVMIntPtrTypeForAS(LLVMTargetDataRef TD, uint AS);
}
static if (LLVM_Version >= asVersion(3, 4, 0)) {
    LLVMTypeRef LLVMIntPtrTypeInContext(LLVMContextRef C, LLVMTargetDataRef TD);
}
static if (LLVM_Version >= asVersion(3, 4, 0)) {
    LLVMTypeRef LLVMIntPtrTypeForASInContext(LLVMContextRef C, LLVMTargetDataRef TD, uint AS);
}
ulong LLVMSizeOfTypeInBits(LLVMTargetDataRef TD, LLVMTypeRef Ty);
ulong LLVMStoreSizeOfType(LLVMTargetDataRef TD, LLVMTypeRef Ty);
ulong LLVMABISizeOfType(LLVMTargetDataRef TD, LLVMTypeRef Ty);
uint LLVMABIAlignmentOfType(LLVMTargetDataRef TD, LLVMTypeRef Ty);
uint LLVMCallFrameAlignmentOfType(LLVMTargetDataRef TD, LLVMTypeRef Ty);
uint LLVMPreferredAlignmentOfType(LLVMTargetDataRef TD, LLVMTypeRef Ty);
uint LLVMPreferredAlignmentOfGlobal(LLVMTargetDataRef TD, LLVMValueRef GlobalVar);
uint LLVMElementAtOffset(LLVMTargetDataRef TD, LLVMTypeRef StructTy, ulong Offset);
ulong LLVMOffsetOfElement(LLVMTargetDataRef TD, LLVMTypeRef StructTy, uint Element);
void LLVMDisposeTargetData(LLVMTargetDataRef TD);

/+ Target machine +/

LLVMTargetRef LLVMGetFirstTarget();
LLVMTargetRef LLVMGetNextTarget(LLVMTargetRef T);
static if (LLVM_Version >= asVersion(3, 4, 0)) {
    LLVMTargetRef LLVMGetTargetFromName(const(char)* Name);
}
static if (LLVM_Version >= asVersion(3, 4, 0)) {
    LLVMBool LLVMGetTargetFromTriple(const(char)* Triple, LLVMTargetRef* T, char** ErrorMessage);
}
const(char)* LLVMGetTargetName(LLVMTargetRef T);
const(char)* LLVMGetTargetDescription(LLVMTargetRef T);
LLVMBool LLVMTargetHasJIT(LLVMTargetRef T);
LLVMBool LLVMTargetHasTargetMachine(LLVMTargetRef T);
LLVMBool LLVMTargetHasAsmBackend(LLVMTargetRef T);
LLVMTargetMachineRef LLVMCreateTargetMachine(LLVMTargetRef T, const(char)* Triple,  const(char)* CPU, const(char)* Features, LLVMCodeGenOptLevel Level, LLVMRelocMode Reloc, LLVMCodeModel CodeModel);
void LLVMDisposeTargetMachine(LLVMTargetMachineRef T);
LLVMTargetRef LLVMGetTargetMachineTarget(LLVMTargetMachineRef T);
char* LLVMGetTargetMachineTriple(LLVMTargetMachineRef T);
char* LLVMGetTargetMachineCPU(LLVMTargetMachineRef T);
char* LLVMGetTargetMachineFeatureString(LLVMTargetMachineRef T);
static if (LLVM_Version < asVersion(3, 7, 0)) {
    LLVMTargetDataRef LLVMGetTargetMachineData(LLVMTargetMachineRef T);
}
static if (LLVM_Version >= asVersion(3, 9, 0)) {
    LLVMTargetDataRef LLVMCreateTargetDataLayout(LLVMTargetMachineRef T);
}
static if (LLVM_Version >= asVersion(3, 4, 0)) {
    void LLVMSetTargetMachineAsmVerbosity(LLVMTargetMachineRef T, LLVMBool VerboseAsm);
}
LLVMBool LLVMTargetMachineEmitToFile(LLVMTargetMachineRef T, LLVMModuleRef M,  char* Filename, LLVMCodeGenFileType codegen, char** ErrorMessage);
static if (LLVM_Version >= asVersion(3, 3, 0)) {
    LLVMBool LLVMTargetMachineEmitToMemoryBuffer(LLVMTargetMachineRef T, LLVMModuleRef M, LLVMCodeGenFileType codegen, char** ErrorMessage, LLVMMemoryBufferRef* OutMemBuf);
}
static if (LLVM_Version >= asVersion(3, 4, 0)) {
    char* LLVMGetDefaultTargetTriple();
}
static if (LLVM_Version >= asVersion(3, 5, 0)) {
    void LLVMAddAnalysisPasses(LLVMTargetMachineRef T, LLVMPassManagerRef PM);
}

/+ Support +/
static if (LLVM_Version >= asVersion(3, 4, 0)) {
    LLVMBool LLVMLoadLibraryPermanently(const(char)* Filename);
}
static if (LLVM_Version >= asVersion(3, 6, 0)) {
    void LLVMParseCommandLineOptions(int argc, const(char*)* argv, const(char)* Overview);
}
static if (LLVM_Version >= asVersion(3, 7, 0)) {
    void* LLVMSearchForAddressOfSymbol(const(char)* symbolName);
}
static if (LLVM_Version >= asVersion(3, 7, 0)) {
    void LLVMAddSymbol(const(char) *symbolName, void *symbolValue);
}

/+ IRReader +/
static if (LLVM_Version >= asVersion(3, 4, 0)) {
    LLVMBool LLVMParseIRInContext(LLVMContextRef ContextRef, LLVMMemoryBufferRef MemBuf, LLVMModuleRef* OutM, char** OutMessage);
}

/+ JIT compilation of LLVM IR +/
static if (LLVM_Version >= asVersion(5, 0, 0) && LLVM_Version < asVersion(7, 0, 0)) {
	LLVMSharedModuleRef LLVMOrcMakeSharedModule(LLVMModuleRef Mod);
	void LLVMOrcDisposeSharedModuleRef(LLVMSharedModuleRef SharedMod);
}
static if (LLVM_Version >= asVersion(5, 0, 0) && LLVM_Version < asVersion(6, 0, 0)) {
	LLVMSharedObjectBufferRef LLVMOrcMakeSharedObjectBuffer(LLVMMemoryBufferRef ObjBuffer);
	void LLVMOrcDisposeSharedObjectBufferRef(LLVMSharedObjectBufferRef SharedObjBuffer);
}
static if (LLVM_Version >= asVersion(3, 8, 0)) {
    LLVMOrcJITStackRef LLVMOrcCreateInstance(LLVMTargetMachineRef TM);
}
static if (LLVM_Version >= asVersion(3, 9, 0)) {
    const(char)* LLVMOrcGetErrorMsg(LLVMOrcJITStackRef JITStack);
}
static if (LLVM_Version >= asVersion(3, 8, 0)) {
    void LLVMOrcGetMangledSymbol(LLVMOrcJITStackRef JITStack, char** MangledSymbol, const(char)* Symbol);
}
static if (LLVM_Version >= asVersion(3, 8, 0)) {
    void LLVMOrcDisposeMangledSymbol(char* MangledSymbol);
}

static if (LLVM_Version >= asVersion(8, 0, 0)) {
    LLVMErrorRef LLVMOrcCreateLazyCompileCallback(LLVMOrcJITStackRef JITStack, LLVMOrcTargetAddress* RetAddr, LLVMOrcLazyCompileCallbackFn Callback, void* CallbackCtx);
} else static if (LLVM_Version >= asVersion(5, 0, 0)) {
	LLVMOrcErrorCode LLVMOrcCreateLazyCompileCallback(LLVMOrcJITStackRef JITStack, LLVMOrcTargetAddress* RetAddr, LLVMOrcLazyCompileCallbackFn Callback, void* CallbackCtx);
} else static if (LLVM_Version >= asVersion(3, 8, 0)) {
    LLVMOrcTargetAddress LLVMOrcCreateLazyCompileCallback(LLVMOrcJITStackRef JITStack, LLVMOrcLazyCompileCallbackFn Callback, void* CallbackCtx);
}
static if (LLVM_Version >= asVersion(8, 0, 0)) {
    LLVMErrorRef LLVMOrcCreateIndirectStub(LLVMOrcJITStackRef JITStack, const(char)* StubName, LLVMOrcTargetAddress InitAddr);
} else static if (LLVM_Version >= asVersion(3, 8, 0)) {
    void LLVMOrcCreateIndirectStub(LLVMOrcJITStackRef JITStack, const(char)* StubName, LLVMOrcTargetAddress InitAddr);
}
static if (LLVM_Version >= asVersion(8, 0, 0)) {
    LLVMErrorRef LLVMOrcSetIndirectStubPointer(LLVMOrcJITStackRef JITStack, const(char)* StubName, LLVMOrcTargetAddress NewAddr);
} else static if (LLVM_Version >= asVersion(3, 8, 0)) {
    void LLVMOrcSetIndirectStubPointer(LLVMOrcJITStackRef JITStack, const(char)* StubName, LLVMOrcTargetAddress NewAddr);
}

static if (LLVM_Version >= asVersion(8, 0, 0)) {
    LLVMErrorRef LLVMOrcAddEagerlyCompiledIR(LLVMOrcJITStackRef JITStack,
                                             LLVMOrcModuleHandle* RetHandle,
                                             LLVMModuleRef Mod,
                                             LLVMOrcSymbolResolverFn SymbolResolver,
                                             void* SymbolResolverCtx);
} else static if (LLVM_Version >= asVersion(7, 0, 0)) {
	LLVMOrcErrorCode LLVMOrcAddEagerlyCompiledIR(LLVMOrcJITStackRef JITStack, LLVMOrcModuleHandle* RetHandle, LLVMModuleRef Mod, LLVMOrcSymbolResolverFn SymbolResolver, void* SymbolResolverCtx);
} else static if (LLVM_Version >= asVersion(5, 0, 0)) {
	LLVMOrcErrorCode LLVMOrcAddEagerlyCompiledIR(LLVMOrcJITStackRef JITStack, LLVMOrcModuleHandle* RetHandle, LLVMSharedModuleRef Mod, LLVMOrcSymbolResolverFn SymbolResolver, void* SymbolResolverCtx);
} else static if (LLVM_Version >= asVersion(3, 8, 0)) {
    LLVMOrcModuleHandle LLVMOrcAddEagerlyCompiledIR(LLVMOrcJITStackRef JITStack, LLVMModuleRef Mod, LLVMOrcSymbolResolverFn SymbolResolver, void* SymbolResolverCtx);
}


static if (LLVM_Version >= asVersion(8, 0, 0)) {
    LLVMErrorRef LLVMOrcAddLazilyCompiledIR(LLVMOrcJITStackRef JITStack,
                                            LLVMOrcModuleHandle* RetHandle,
                                            LLVMModuleRef Mod,
                                            LLVMOrcSymbolResolverFn SymbolResolver,
                                            void* SymbolResolverCtx);
} else static if (LLVM_Version >= asVersion(7, 0, 0)) {
	LLVMOrcErrorCode LLVMOrcAddLazilyCompiledIR(LLVMOrcJITStackRef JITStack, LLVMOrcModuleHandle* RetHandle, LLVMModuleRef Mod, LLVMOrcSymbolResolverFn SymbolResolver, void* SymbolResolverCtx);
} else static if (LLVM_Version >= asVersion(5, 0, 0)) {
	LLVMOrcErrorCode LLVMOrcAddLazilyCompiledIR(LLVMOrcJITStackRef JITStack, LLVMOrcModuleHandle* RetHandle, LLVMSharedModuleRef Mod, LLVMOrcSymbolResolverFn SymbolResolver, void* SymbolResolverCtx);
} else static if (LLVM_Version >= asVersion(3, 8, 0)) {
    LLVMOrcModuleHandle LLVMOrcAddLazilyCompiledIR(LLVMOrcJITStackRef JITStack, LLVMModuleRef Mod, LLVMOrcSymbolResolverFn SymbolResolver, void* SymbolResolverCtx);
}

static if (LLVM_Version >= asVersion(8, 0, 0)) {
    LLVMErrorRef LLVMOrcAddObjectFile(LLVMOrcJITStackRef JITStack, LLVMOrcModuleHandle* RetHandle, LLVMMemoryBufferRef Obj, LLVMOrcSymbolResolverFn SymbolResolver, void* SymbolResolverCtx);
} else static if (LLVM_Version >= asVersion(6, 0, 0)) {
	LLVMOrcErrorCode LLVMOrcAddObjectFile(LLVMOrcJITStackRef JITStack, LLVMOrcModuleHandle* RetHandle, LLVMMemoryBufferRef Obj, LLVMOrcSymbolResolverFn SymbolResolver, void* SymbolResolverCtx);
} else static if (LLVM_Version >= asVersion(5, 0, 0)) {
	LLVMOrcErrorCode LLVMOrcAddObjectFile(LLVMOrcJITStackRef JITStack, LLVMOrcModuleHandle* RetHandle, LLVMSharedObjectBufferRef Obj, LLVMOrcSymbolResolverFn SymbolResolver, void* SymbolResolverCtx);

} else static if (LLVM_Version >= asVersion(3, 8, 0)) {
    LLVMOrcModuleHandle LLVMOrcAddObjectFile(LLVMOrcJITStackRef JITStack, LLVMObjectFileRef Obj, LLVMOrcSymbolResolverFn SymbolResolver, void* SymbolResolverCtx);
}
static if (LLVM_Version >= asVersion(8, 0, 0)) {
    LLVMErrorRef LLVMOrcRemoveModule(LLVMOrcJITStackRef JITStack, LLVMOrcModuleHandle H);
} else static if (LLVM_Version >= asVersion(5, 0, 0)) {
	LLVMOrcErrorCode LLVMOrcRemoveModule(LLVMOrcJITStackRef JITStack, LLVMOrcModuleHandle H);
} else static if (LLVM_Version >= asVersion(3, 8, 0)) {
    void LLVMOrcRemoveModule(LLVMOrcJITStackRef JITStack, LLVMOrcModuleHandle H);
}
static if (LLVM_Version >= asVersion(8, 0, 0)) {
    LLVMErrorRef LLVMOrcGetSymbolAddress(LLVMOrcJITStackRef JITStack, LLVMOrcTargetAddress* RetAddr, const(char)* SymbolName);
} else static if (LLVM_Version >= asVersion(5, 0, 0)) {
	LLVMOrcErrorCode LLVMOrcGetSymbolAddress(LLVMOrcJITStackRef JITStack, LLVMOrcTargetAddress *RetAddr, const(char)* SymbolName);
} else static if (LLVM_Version >= asVersion(3, 8, 0)) {
    LLVMOrcTargetAddress LLVMOrcGetSymbolAddress(LLVMOrcJITStackRef JITStack, const(char)* SymbolName);
}

static if (LLVM_Version >= asVersion(8, 0, 0)) {
    LLVMErrorRef LLVMOrcGetSymbolAddressIn(LLVMOrcJITStackRef JITStack, LLVMOrcTargetAddress* RetAddr, LLVMOrcModuleHandle H, const(char)* SymbolName);
} else static if (LLVM_Version >= asVersion(7, 0, 0)) {
	LLVMOrcErrorCode LLVMOrcGetSymbolAddressIn(LLVMOrcJITStackRef JITStack, LLVMOrcTargetAddress* RetAddr, LLVMOrcModuleHandle H, const(char)* SymbolName);
}

static if (LLVM_Version >= asVersion(8, 0, 0)) {
    LLVMErrorRef LLVMOrcDisposeInstance(LLVMOrcJITStackRef JITStack);
} else static if (LLVM_Version >= asVersion(5, 0, 0)) {
	LLVMOrcErrorCode LLVMOrcDisposeInstance(LLVMOrcJITStackRef JITStack);
} else static if (LLVM_Version >= asVersion(3, 8, 0)) {
    void LLVMOrcDisposeInstance(LLVMOrcJITStackRef JITStack);
}

/+ Debug info flags +/

static if (LLVM_Version >= asVersion(6, 0, 0)) {
	uint LLVMDebugMetadataVersion();
}
static if (LLVM_Version >= asVersion(6, 0, 0)) {
	uint LLVMGetModuleDebugMetadataVersion(LLVMModuleRef Module);
}
static if (LLVM_Version >= asVersion(6, 0, 0)) {
	uint LLVMGetModuleDebugMetadataVersion(LLVMModuleRef Module);
}
static if (LLVM_Version >= asVersion(6, 0, 0)) {
	LLVMBool LLVMStripModuleDebugInfo(LLVMModuleRef Module);
}
static if (LLVM_Version >= asVersion(6, 0, 0)) {
	LLVMDIBuilderRef LLVMCreateDIBuilderDisallowUnresolved(LLVMModuleRef M);
}
static if (LLVM_Version >= asVersion(6, 0, 0)) {
	LLVMDIBuilderRef LLVMCreateDIBuilder(LLVMModuleRef M);
}
static if (LLVM_Version >= asVersion(6, 0, 0)) {
	void LLVMDisposeDIBuilder(LLVMDIBuilderRef Builder);
}
static if (LLVM_Version >= asVersion(6, 0, 0)) {
	void LLVMDIBuilderFinalize(LLVMDIBuilderRef Builder);
}
static if (LLVM_Version >= asVersion(6, 0, 0)) {
	LLVMMetadataRef LLVMDIBuilderCreateCompileUnit(LLVMDIBuilderRef Builder, LLVMDWARFSourceLanguage Lang, LLVMMetadataRef FileRef, const(char)* Producer, size_t ProducerLen, LLVMBool isOptimized, const(char)* Flags, size_t FlagsLen, uint RuntimeVer, const(char)* SplitName, size_t SplitNameLen, LLVMDWARFEmissionKind Kind, uint DWOId, LLVMBool SplitDebugInlining, LLVMBool DebugInfoForProfiling);
}
static if (LLVM_Version >= asVersion(6, 0, 0)) {
	LLVMMetadataRef LLVMDIBuilderCreateFile(LLVMDIBuilderRef Builder, const(char)* Filename, size_t FilenameLen, const(char)* Directory, size_t DirectoryLen);
}
static if (LLVM_Version >= asVersion(6, 0, 0)) {
	LLVMMetadataRef LLVMDIBuilderCreateDebugLocation(LLVMContextRef Ctx, uint Line, uint Column, LLVMMetadataRef Scope, LLVMMetadataRef InlinedAt);
}



static if (LLVM_Version >= asVersion(7, 0, 0)) {
	LLVMComdatRef LLVMGetOrInsertComdat(LLVMModuleRef M, const(char)* Name);
}

static if (LLVM_Version >= asVersion(7, 0, 0)) {
	LLVMComdatRef LLVMGetComdat(LLVMValueRef V);
}

static if (LLVM_Version >= asVersion(7, 0, 0)) {
	void LLVMSetComdat(LLVMValueRef V, LLVMComdatRef C);
}

static if (LLVM_Version >= asVersion(7, 0, 0)) {
	LLVMComdatSelectionKind LLVMGetComdatSelectionKind(LLVMComdatRef C);
}

static if (LLVM_Version >= asVersion(7, 0, 0)) {
	void LLVMSetComdatSelectionKind(LLVMComdatRef C, LLVMComdatSelectionKind Kind);
}

static if (LLVM_Version >= asVersion(7, 0, 0)) {
	const(char)* LLVMGetSourceFileName(LLVMModuleRef M, size_t* Len);
}

static if (LLVM_Version >= asVersion(7, 0, 0)) {
	void LLVMSetSourceFileName(LLVMModuleRef M, const(char)* Name, size_t Len);
}

static if (LLVM_Version >= asVersion(7, 0, 0)) {
	LLVMModuleFlagEntry* LLVMCopyModuleFlagsMetadata(LLVMModuleRef M, size_t* Len);
}

static if (LLVM_Version >= asVersion(7, 0, 0)) {
	void LLVMDisposeModuleFlagsMetadata(LLVMModuleFlagEntry* Entries);
}

static if (LLVM_Version >= asVersion(7, 0, 0)) {
	LLVMModuleFlagBehavior LLVMModuleFlagEntriesGetFlagBehavior(LLVMModuleFlagEntry* Entries, uint Index);
}

static if (LLVM_Version >= asVersion(7, 0, 0)) {
	const(char)* LLVMModuleFlagEntriesGetKey(LLVMModuleFlagEntry* Entries, uint Index, size_t* Len);
}

static if (LLVM_Version >= asVersion(7, 0, 0)) {
	LLVMMetadataRef LLVMModuleFlagEntriesGetMetadata(LLVMModuleFlagEntry* Entries, uint Index);
}

static if (LLVM_Version >= asVersion(7, 0, 0)) {
	LLVMMetadataRef LLVMGetModuleFlag(LLVMModuleRef M, const(char)* Key, size_t KeyLen);
}

static if (LLVM_Version >= asVersion(7, 0, 0)) {
	void LLVMAddModuleFlag(LLVMModuleRef M, LLVMModuleFlagBehavior Behavior, const(char)* Key, size_t KeyLen, LLVMMetadataRef Val);
}

static if (LLVM_Version >= asVersion(7, 0, 0)) {
	const(char)* LLVMGetModuleInlineAsm(LLVMModuleRef M, size_t* Len);
}

static if (LLVM_Version >= asVersion(7, 0, 0)) {
	void LLVMAppendModuleInlineAsm(LLVMModuleRef M, const(char)* Asm, size_t Len);
}


static if (LLVM_Version >= asVersion(7, 0, 0)) {
	LLVMValueRef LLVMGetNamedGlobalAlias(LLVMModuleRef M, const(char)* Name, size_t NameLen);
}

static if (LLVM_Version >= asVersion(7, 0, 0)) {
	LLVMValueRef LLVMGetFirstGlobalAlias(LLVMModuleRef M);
}

static if (LLVM_Version >= asVersion(7, 0, 0)) {
	LLVMValueRef LLVMGetLastGlobalAlias(LLVMModuleRef M);
}

static if (LLVM_Version >= asVersion(7, 0, 0)) {
	LLVMValueRef LLVMGetNextGlobalAlias(LLVMValueRef GA);
}

static if (LLVM_Version >= asVersion(7, 0, 0)) {
	LLVMValueRef LLVMGetPreviousGlobalAlias(LLVMValueRef GA);
}

static if (LLVM_Version >= asVersion(7, 0, 0)) {
	LLVMValueRef LLVMAliasGetAliasee(LLVMValueRef Alias);
}

static if (LLVM_Version >= asVersion(7, 0, 0)) {
	void LLVMAliasSetAliasee(LLVMValueRef Alias, LLVMValueRef Aliasee);
}

static if (LLVM_Version >= asVersion(7, 0, 0)) {
	LLVMValueRef LLVMBuildCleanupRet(LLVMBuilderRef B, LLVMValueRef CatchPad, LLVMBasicBlockRef BB);
}

static if (LLVM_Version >= asVersion(7, 0, 0)) {
	LLVMValueRef LLVMBuildCatchRet(LLVMBuilderRef B, LLVMValueRef CatchPad, LLVMBasicBlockRef BB);
}

static if (LLVM_Version >= asVersion(7, 0, 0)) {
	LLVMValueRef LLVMBuildCatchPad(LLVMBuilderRef B, LLVMValueRef ParentPad, LLVMValueRef* Args, uint NumArgs, const (char)* Name);
}

static if (LLVM_Version >= asVersion(7, 0, 0)) {
	LLVMValueRef LLVMBuildCleanupPad(LLVMBuilderRef B, LLVMValueRef ParentPad, LLVMValueRef* Args, uint NumArgs, const (char)* Name);
}

static if (LLVM_Version >= asVersion(7, 0, 0)) {
	LLVMValueRef LLVMBuildCatchSwitch(LLVMBuilderRef B, LLVMValueRef ParentPad, LLVMBasicBlockRef UnwindBB, uint NumHandlers, const (char)* Name);
}


static if (LLVM_Version >= asVersion(7, 0, 0)) {
	void LLVMAddHandler(LLVMValueRef CatchSwitch, LLVMBasicBlockRef Dest);
}

static if (LLVM_Version >= asVersion(7, 0, 0)) {
	uint LLVMGetNumHandlers(LLVMValueRef CatchSwitch);
}

static if (LLVM_Version >= asVersion(7, 0, 0)) {
	void LLVMGetHandlers(LLVMValueRef CatchSwitch, LLVMBasicBlockRef* Handlers);
}

static if (LLVM_Version >= asVersion(7, 0, 0)) {
	void LLVMSetArgOperand(LLVMValueRef Funclet, uint i, LLVMValueRef value);
}

static if (LLVM_Version >= asVersion(7, 0, 0)) {
	LLVMValueRef LLVMGetParentCatchSwitch(LLVMValueRef CatchPad);
}

static if (LLVM_Version >= asVersion(7, 0, 0)) {
	void LLVMSetParentCatchSwitch(LLVMValueRef CatchPad, LLVMValueRef CatchSwitch);
}


static if (LLVM_Version >= asVersion(10, 0, 0)) {
	LLVMMetadataRef LLVMDIBuilderCreateModule(LLVMDIBuilderRef Builder, LLVMMetadataRef ParentScope, const(char)* Name, size_t NameLen, const(char)* ConfigMacros, size_t ConfigMacrosLen, const(char)* IncludePath, size_t IncludePathLen, const(char)* SysRoot, size_t SysRootLen);
} else static if (LLVM_Version >= asVersion(7, 0, 0)) {
	LLVMMetadataRef LLVMDIBuilderCreateModule(LLVMDIBuilderRef Builder, LLVMMetadataRef ParentScope, const(char)* Name, size_t NameLen, const(char)* ConfigMacros, size_t ConfigMacrosLen, const(char)* IncludePath, size_t IncludePathLen, const(char)* ISysRoot, size_t ISysRootLen);
}

static if (LLVM_Version >= asVersion(7, 0, 0)) {
	LLVMMetadataRef LLVMDIBuilderCreateNameSpace(LLVMDIBuilderRef Builder, LLVMMetadataRef ParentScope, const(char)* Name, size_t NameLen, LLVMBool ExportSymbols);
}

static if (LLVM_Version >= asVersion(7, 0, 0)) {
	LLVMMetadataRef LLVMDIBuilderCreateFunction(LLVMDIBuilderRef Builder, LLVMMetadataRef Scope, const(char)* Name, size_t NameLen, const(char)* LinkageName, size_t LinkageNameLen, LLVMMetadataRef File, uint LineNo, LLVMMetadataRef Ty, LLVMBool IsLocalToUnit, LLVMBool IsDefinition, uint ScopeLine, LLVMDIFlags Flags, LLVMBool IsOptimized);
}

static if (LLVM_Version >= asVersion(7, 0, 0)) {
	LLVMMetadataRef LLVMDIBuilderCreateLexicalBlock( LLVMDIBuilderRef Builder, LLVMMetadataRef Scope, LLVMMetadataRef File, uint Line, uint Column);
}

static if (LLVM_Version >= asVersion(7, 0, 0)) {
	LLVMMetadataRef LLVMDIBuilderCreateLexicalBlockFile(LLVMDIBuilderRef Builder, LLVMMetadataRef Scope, LLVMMetadataRef File, uint Discriminator);
}

static if (LLVM_Version >= asVersion(7, 0, 0)) {
	LLVMMetadataRef LLVMDIBuilderCreateImportedModuleFromNamespace(LLVMDIBuilderRef Builder, LLVMMetadataRef Scope, LLVMMetadataRef NS, LLVMMetadataRef File, uint Line);
}

static if (LLVM_Version >= asVersion(7, 0, 0)) {
	LLVMMetadataRef LLVMDIBuilderCreateImportedModuleFromAlias(LLVMDIBuilderRef Builder, LLVMMetadataRef Scope, LLVMMetadataRef ImportedEntity, LLVMMetadataRef File, uint Line);
}

static if (LLVM_Version >= asVersion(7, 0, 0)) {
	LLVMMetadataRef LLVMDIBuilderCreateImportedModuleFromModule(LLVMDIBuilderRef Builder, LLVMMetadataRef Scope, LLVMMetadataRef M, LLVMMetadataRef File, uint Line);
}

static if (LLVM_Version >= asVersion(7, 0, 0)) {
	LLVMMetadataRef LLVMDIBuilderCreateImportedDeclaration(LLVMDIBuilderRef Builder, LLVMMetadataRef Scope, LLVMMetadataRef Decl, LLVMMetadataRef File, uint Line, const(char)* Name, size_t NameLen);
}

static if (LLVM_Version >= asVersion(7, 0, 0)) {
	uint LLVMDILocationGetLine(LLVMMetadataRef Location);
}

static if (LLVM_Version >= asVersion(7, 0, 0)) {
	uint LLVMDILocationGetColumn(LLVMMetadataRef Location);
}

static if (LLVM_Version >= asVersion(7, 0, 0)) {
	LLVMMetadataRef LLVMDILocationGetScope(LLVMMetadataRef Location);
}

static if (LLVM_Version >= asVersion(9, 0, 0)) {
	LLVMMetadataRef LLVMDILocationGetInlinedAt(LLVMMetadataRef Location);
    LLVMMetadataRef LLVMDIScopeGetFile(LLVMMetadataRef Scope);
    const(char)* LLVMDIFileGetDirectory(LLVMMetadataRef File, uint* Len);
    const(char)* LLVMDIFileGetFilename(LLVMMetadataRef File, uint* Len);
    const(char)* LLVMDIFileGetSource(LLVMMetadataRef File, uint* Len);
}

static if (LLVM_Version >= asVersion(7, 0, 0)) {
	LLVMMetadataRef LLVMDIBuilderGetOrCreateTypeArray(LLVMDIBuilderRef Builder, LLVMMetadataRef* Data, size_t NumElements);
}

static if (LLVM_Version >= asVersion(7, 0, 0)) {
	LLVMMetadataRef LLVMDIBuilderCreateSubroutineType(LLVMDIBuilderRef Builder, LLVMMetadataRef File, LLVMMetadataRef* ParameterTypes, uint NumParameterTypes, LLVMDIFlags Flags);
}

static if (LLVM_Version >= asVersion(9, 0, 0)) {
	LLVMMetadataRef LLVMDIBuilderCreateEnumerator(LLVMDIBuilderRef Builder, const(char)* Name, size_t NameLen, int64_t Value, LLVMBool IsUnsigned);
}

static if (LLVM_Version >= asVersion(7, 0, 0)) {
	LLVMMetadataRef LLVMDIBuilderCreateEnumerationType(LLVMDIBuilderRef Builder, LLVMMetadataRef Scope, const(char)* Name, size_t NameLen, LLVMMetadataRef File, uint LineNumber, uint64_t SizeInBits, uint32_t AlignInBits, LLVMMetadataRef* Elements, uint NumElements, LLVMMetadataRef ClassTy);
}

static if (LLVM_Version >= asVersion(7, 0, 0)) {
	LLVMMetadataRef LLVMDIBuilderCreateUnionType(LLVMDIBuilderRef Builder, LLVMMetadataRef Scope, const(char)* Name, size_t NameLen, LLVMMetadataRef File, uint LineNumber, uint64_t SizeInBits, uint32_t AlignInBits, LLVMDIFlags Flags, LLVMMetadataRef *Elements, uint NumElements, uint RunTimeLang, const(char)* UniqueId, size_t UniqueIdLen);
}

static if (LLVM_Version >= asVersion(7, 0, 0)) {
	LLVMMetadataRef LLVMDIBuilderCreateArrayType(LLVMDIBuilderRef Builder, uint64_t Size, uint32_t AlignInBits, LLVMMetadataRef Ty, LLVMMetadataRef* Subscripts, uint NumSubscripts);
}

static if (LLVM_Version >= asVersion(7, 0, 0)) {
	LLVMMetadataRef LLVMDIBuilderCreateVectorType(LLVMDIBuilderRef Builder, uint64_t Size, uint32_t AlignInBits, LLVMMetadataRef Ty, LLVMMetadataRef *Subscripts, uint NumSubscripts);
}

static if (LLVM_Version >= asVersion(7, 0, 0)) {
	LLVMMetadataRef LLVMDIBuilderCreateUnspecifiedType(LLVMDIBuilderRef Builder, const(char)* Name, size_t NameLen);
}

static if (LLVM_Version >= asVersion(8, 0, 0)) {
    LLVMMetadataRef LLVMDIBuilderCreateBasicType(LLVMDIBuilderRef Builder, const(char)* Name, size_t NameLen, uint64_t SizeInBits, LLVMDWARFTypeEncoding Encoding, LLVMDIFlags Flags);
}
else static if (LLVM_Version >= asVersion(7, 0, 0)) {
	LLVMMetadataRef LLVMDIBuilderCreateBasicType(LLVMDIBuilderRef Builder, const(char)* Name, size_t NameLen, uint64_t SizeInBits, LLVMDWARFTypeEncoding Encoding);
}

static if (LLVM_Version >= asVersion(7, 0, 0)) {
	LLVMMetadataRef LLVMDIBuilderCreatePointerType(LLVMDIBuilderRef Builder, LLVMMetadataRef PointeeTy, uint64_t SizeInBits, uint32_t AlignInBits, uint AddressSpace, const(char)* Name, size_t NameLen);
}

static if (LLVM_Version >= asVersion(7, 0, 0)) {
	LLVMMetadataRef LLVMDIBuilderCreateStructType( LLVMDIBuilderRef Builder, LLVMMetadataRef Scope, const(char)* Name, size_t NameLen, LLVMMetadataRef File, uint LineNumber, uint64_t SizeInBits, uint32_t AlignInBits, LLVMDIFlags Flags, LLVMMetadataRef DerivedFrom, LLVMMetadataRef* Elements, uint NumElements, uint RunTimeLang, LLVMMetadataRef VTableHolder, const(char)* UniqueId, size_t UniqueIdLen);
}

static if (LLVM_Version >= asVersion(7, 0, 0)) {
	LLVMMetadataRef LLVMDIBuilderCreateMemberType( LLVMDIBuilderRef Builder, LLVMMetadataRef Scope, const(char)* Name, size_t NameLen, LLVMMetadataRef File, uint LineNo, uint64_t SizeInBits, uint32_t AlignInBits, uint64_t OffsetInBits, LLVMDIFlags Flags, LLVMMetadataRef Ty);
}

static if (LLVM_Version >= asVersion(7, 0, 0)) {
	LLVMMetadataRef LLVMDIBuilderCreateStaticMemberType(LLVMDIBuilderRef Builder, LLVMMetadataRef Scope, const(char)* Name, size_t NameLen, LLVMMetadataRef File, uint LineNumber, LLVMMetadataRef Type, LLVMDIFlags Flags, LLVMValueRef ConstantVal, uint32_t AlignInBits);
}

static if (LLVM_Version >= asVersion(7, 0, 0)) {
	LLVMMetadataRef LLVMDIBuilderCreateMemberPointerType(LLVMDIBuilderRef Builder, LLVMMetadataRef PointeeType, LLVMMetadataRef ClassType, uint64_t SizeInBits, uint32_t AlignInBits, LLVMDIFlags Flags);
}

static if (LLVM_Version >= asVersion(7, 0, 0)) {
	LLVMMetadataRef LLVMDIBuilderCreateObjCIVar(LLVMDIBuilderRef Builder, const(char)* Name, size_t NameLen, LLVMMetadataRef File, uint LineNo, uint64_t SizeInBits, uint32_t AlignInBits, uint64_t OffsetInBits, LLVMDIFlags Flags, LLVMMetadataRef Ty, LLVMMetadataRef PropertyNode);
}

static if (LLVM_Version >= asVersion(7, 0, 0)) {
	LLVMMetadataRef LLVMDIBuilderCreateObjCProperty(LLVMDIBuilderRef Builder, const(char)* Name, size_t NameLen, LLVMMetadataRef File, uint LineNo, const(char)* GetterName, size_t GetterNameLen, const(char)* SetterName, size_t SetterNameLen, uint PropertyAttributes, LLVMMetadataRef Ty);
}

static if (LLVM_Version >= asVersion(7, 0, 0)) {
	LLVMMetadataRef LLVMDIBuilderCreateObjectPointerType(LLVMDIBuilderRef Builder, LLVMMetadataRef Type);
}

static if (LLVM_Version >= asVersion(7, 0, 0)) {
	LLVMMetadataRef LLVMDIBuilderCreateQualifiedType(LLVMDIBuilderRef Builder, uint Tag, LLVMMetadataRef Type);
}

static if (LLVM_Version >= asVersion(7, 0, 0)) {
	LLVMMetadataRef LLVMDIBuilderCreateReferenceType(LLVMDIBuilderRef Builder, uint Tag, LLVMMetadataRef Type);
}

static if (LLVM_Version >= asVersion(7, 0, 0)) {
	LLVMMetadataRef LLVMDIBuilderCreateNullPtrType(LLVMDIBuilderRef Builder);
}


static if (LLVM_Version >= asVersion(10, 0, 0)) {
	LLVMMetadataRef LLVMDIBuilderCreateTypedef(LLVMDIBuilderRef Builder, LLVMMetadataRef Type, const(char)* Name, size_t NameLen, LLVMMetadataRef File, uint LineNo, LLVMMetadataRef Scope, uint32_t AlignInBits);
} else static if (LLVM_Version >= asVersion(7, 0, 0)) {
	LLVMMetadataRef LLVMDIBuilderCreateTypedef(LLVMDIBuilderRef Builder, LLVMMetadataRef Type, const(char)* Name, size_t NameLen, LLVMMetadataRef File, uint LineNo, LLVMMetadataRef Scope);
}

static if (LLVM_Version >= asVersion(7, 0, 0)) {
	LLVMMetadataRef LLVMDIBuilderCreateInheritance(LLVMDIBuilderRef Builder, LLVMMetadataRef Ty, LLVMMetadataRef BaseTy, uint64_t BaseOffset, uint32_t VBPtrOffset, LLVMDIFlags Flags);
}

static if (LLVM_Version >= asVersion(7, 0, 0)) {
	LLVMMetadataRef LLVMDIBuilderCreateForwardDecl(LLVMDIBuilderRef Builder, uint Tag, const(char)* Name, size_t NameLen, LLVMMetadataRef Scope, LLVMMetadataRef File, uint Line, uint RuntimeLang, uint64_t SizeInBits, uint32_t AlignInBits, const(char)* UniqueIdentifier, size_t UniqueIdentifierLen);
}

static if (LLVM_Version >= asVersion(7, 0, 0)) {
	LLVMMetadataRef LLVMDIBuilderCreateReplaceableCompositeType(LLVMDIBuilderRef Builder, uint Tag, const(char)* Name, size_t NameLen, LLVMMetadataRef Scope, LLVMMetadataRef File, uint Line, uint RuntimeLang, uint64_t SizeInBits, uint32_t AlignInBits, LLVMDIFlags Flags, const(char)* UniqueIdentifier, size_t UniqueIdentifierLen);
}

static if (LLVM_Version >= asVersion(7, 0, 0)) {
	LLVMMetadataRef LLVMDIBuilderCreateBitFieldMemberType(LLVMDIBuilderRef Builder, LLVMMetadataRef Scope, const(char)* Name, size_t NameLen, LLVMMetadataRef File, uint LineNumber, uint64_t SizeInBits, uint64_t OffsetInBits, uint64_t StorageOffsetInBits, LLVMDIFlags Flags, LLVMMetadataRef Type);
}

static if (LLVM_Version >= asVersion(7, 0, 0)) {
	LLVMMetadataRef LLVMDIBuilderCreateClassType(LLVMDIBuilderRef Builder, LLVMMetadataRef Scope, const(char)* Name, size_t NameLen, LLVMMetadataRef File, uint LineNumber, uint64_t SizeInBits, uint32_t AlignInBits, uint64_t OffsetInBits, LLVMDIFlags Flags, LLVMMetadataRef DerivedFrom, LLVMMetadataRef* Elements, uint NumElements, LLVMMetadataRef VTableHolder, LLVMMetadataRef TemplateParamsNode, const(char)* UniqueIdentifier, size_t UniqueIdentifierLen);
}

static if (LLVM_Version >= asVersion(7, 0, 0)) {
	LLVMMetadataRef LLVMDIBuilderCreateArtificialType(LLVMDIBuilderRef Builder,LLVMMetadataRef Type);
}

static if (LLVM_Version >= asVersion(7, 0, 0)) {
	const(char)* LLVMDITypeGetName(LLVMMetadataRef DType, size_t* Length);
}

static if (LLVM_Version >= asVersion(7, 0, 0)) {
	uint64_t LLVMDITypeGetSizeInBits(LLVMMetadataRef DType);
}

static if (LLVM_Version >= asVersion(7, 0, 0)) {
	uint64_t LLVMDITypeGetOffsetInBits(LLVMMetadataRef DType);
}

static if (LLVM_Version >= asVersion(7, 0, 0)) {
	uint32_t LLVMDITypeGetAlignInBits(LLVMMetadataRef DType);
}

static if (LLVM_Version >= asVersion(7, 0, 0)) {
	uint LLVMDITypeGetLine(LLVMMetadataRef DType);
}

static if (LLVM_Version >= asVersion(7, 0, 0)) {
	LLVMDIFlags LLVMDITypeGetFlags(LLVMMetadataRef DType);
}

static if (LLVM_Version >= asVersion(7, 0, 0)) {
	LLVMMetadataRef LLVMDIBuilderGetOrCreateSubrange(LLVMDIBuilderRef Builder, int64_t LowerBound, int64_t Count);
}

static if (LLVM_Version >= asVersion(7, 0, 0)) {
	LLVMMetadataRef LLVMDIBuilderGetOrCreateArray(LLVMDIBuilderRef Builder, LLVMMetadataRef* Data, size_t NumElements);
}

static if (LLVM_Version >= asVersion(7, 0, 0)) {
	LLVMMetadataRef LLVMDIBuilderCreateExpression(LLVMDIBuilderRef Builder, int64_t* Addr, size_t Length);
}

static if (LLVM_Version >= asVersion(7, 0, 0)) {
	LLVMMetadataRef LLVMDIBuilderCreateConstantValueExpression(LLVMDIBuilderRef Builder, int64_t Value);
}

static if (LLVM_Version >= asVersion(7, 0, 0)) {
	LLVMMetadataRef LLVMDIBuilderCreateGlobalVariableExpression(LLVMDIBuilderRef Builder, LLVMMetadataRef Scope, const(char)* Name, size_t NameLen, const(char)* Linkage, size_t LinkLen, LLVMMetadataRef File, uint LineNo, LLVMMetadataRef Ty, LLVMBool LocalToUnit, LLVMMetadataRef Expr, LLVMMetadataRef Decl, uint32_t AlignInBits);
}

static if (LLVM_Version >= asVersion(9, 0, 0)) {
	LLVMMetadataRef LLVMDIGlobalVariableExpressionGetVariable(LLVMMetadataRef GVE);
    LLVMMetadataRef LLVMDIGlobalVariableExpressionGetExpression(LLVMMetadataRef GVE);
    LLVMMetadataRef LLVMDIVariableGetFile(LLVMMetadataRef Var);
    LLVMMetadataRef LLVMDIVariableGetScope(LLVMMetadataRef Var);
    uint LLVMDIVariableGetLine(LLVMMetadataRef Var);
}

static if (LLVM_Version >= asVersion(7, 0, 0)) {
	LLVMMetadataRef LLVMTemporaryMDNode(LLVMContextRef Ctx, LLVMMetadataRef* Data, size_t NumElements);
}

static if (LLVM_Version >= asVersion(7, 0, 0)) {
	void LLVMDisposeTemporaryMDNode(LLVMMetadataRef TempNode);
}

static if (LLVM_Version >= asVersion(7, 0, 0)) {
	void LLVMMetadataReplaceAllUsesWith(LLVMMetadataRef TempTargetMetadata, LLVMMetadataRef Replacement);
}

static if (LLVM_Version >= asVersion(7, 0, 0)) {
	LLVMMetadataRef LLVMDIBuilderCreateTempGlobalVariableFwdDecl(LLVMDIBuilderRef Builder, LLVMMetadataRef Scope, const(char)* Name, size_t NameLen, const(char)* Linkage, size_t LnkLen, LLVMMetadataRef File, uint LineNo, LLVMMetadataRef Ty, LLVMBool LocalToUnit, LLVMMetadataRef Decl, uint32_t AlignInBits);
}

static if (LLVM_Version >= asVersion(7, 0, 0)) {
	LLVMValueRef LLVMDIBuilderInsertDeclareBefore(LLVMDIBuilderRef Builder, LLVMValueRef Storage, LLVMMetadataRef VarInfo, LLVMMetadataRef Expr, LLVMMetadataRef DebugLoc, LLVMValueRef Instr);
}

static if (LLVM_Version >= asVersion(7, 0, 0)) {
	LLVMValueRef LLVMDIBuilderInsertDeclareAtEnd(LLVMDIBuilderRef Builder, LLVMValueRef Storage, LLVMMetadataRef VarInfo, LLVMMetadataRef Expr, LLVMMetadataRef DebugLoc, LLVMBasicBlockRef Block);
}

static if (LLVM_Version >= asVersion(7, 0, 0)) {
	LLVMValueRef LLVMDIBuilderInsertDbgValueBefore(LLVMDIBuilderRef Builder, LLVMValueRef Val, LLVMMetadataRef VarInfo, LLVMMetadataRef Expr, LLVMMetadataRef DebugLoc, LLVMValueRef Instr);
}

static if (LLVM_Version >= asVersion(7, 0, 0)) {
	LLVMValueRef LLVMDIBuilderInsertDbgValueAtEnd(LLVMDIBuilderRef Builder, LLVMValueRef Val, LLVMMetadataRef VarInfo, LLVMMetadataRef Expr, LLVMMetadataRef DebugLoc, LLVMBasicBlockRef Block);
}

static if (LLVM_Version >= asVersion(7, 0, 0)) {
	LLVMMetadataRef LLVMDIBuilderCreateAutoVariable(LLVMDIBuilderRef Builder, LLVMMetadataRef Scope, const(char)* Name, size_t NameLen, LLVMMetadataRef File, uint LineNo, LLVMMetadataRef Ty, LLVMBool AlwaysPreserve, LLVMDIFlags Flags, uint32_t AlignInBits);
}

static if (LLVM_Version >= asVersion(7, 0, 0)) {
	LLVMMetadataRef LLVMDIBuilderCreateParameterVariable(LLVMDIBuilderRef Builder, LLVMMetadataRef Scope, const(char)* Name, size_t NameLen, uint ArgNo, LLVMMetadataRef File, uint LineNo, LLVMMetadataRef Ty, LLVMBool AlwaysPreserve, LLVMDIFlags Flags);
}

static if (LLVM_Version >= asVersion(10, 0, 0)) {
    LLVMMetadataRef LLVMDIBuilderCreateMacro(LLVMDIBuilderRef Builder, LLVMMetadataRef ParentMacroFile, uint Line, LLVMDWARFMacinfoRecordType RecordType, const(char)* Name, size_t NameLen, const(char)* Value, size_t ValueLen);
    LLVMMetadataRef LLVMDIBuilderCreateTempMacroFile(LLVMDIBuilderRef Builder, LLVMMetadataRef ParentMacroFile, uint Line, LLVMMetadataRef File);
}

static if (LLVM_Version >= asVersion(7, 0, 0)) {
	LLVMMetadataRef LLVMGetSubprogram(LLVMValueRef Func);
}

static if (LLVM_Version >= asVersion(7, 0, 0)) {
	void LLVMSetSubprogram(LLVMValueRef Func, LLVMMetadataRef SP);
}

static if (LLVM_Version >= asVersion(9, 0, 0)) {
    uint LLVMDISubprogramGetLine(LLVMMetadataRef Subprogram);
    LLVMMetadataRef LLVMInstructionGetDebugLoc(LLVMValueRef Inst);
    void LLVMInstructionSetDebugLoc(LLVMValueRef Inst, LLVMMetadataRef Loc);
}

static if (LLVM_Version >= asVersion(8, 0, 0)) {
    LLVMMetadataKind LLVMGetMetadataKind(LLVMMetadataRef Metadata);
}

static if (LLVM_Version >= asVersion(7, 0, 0)) {
	LLVMJITEventListenerRef LLVMCreateGDBRegistrationListener();
}

static if (LLVM_Version >= asVersion(8, 0, 0)) {
    LLVMJITEventListenerRef LLVMCreateOProfileJITEventListener();
}

static if (LLVM_Version >= asVersion(7, 0, 0)) {
	LLVMJITEventListenerRef LLVMCreateIntelJITEventListener();
}

static if (LLVM_Version >= asVersion(7, 0, 0)) {
	LLVMJITEventListenerRef LLVMCreatePerfJITEventListener();
}

static if (LLVM_Version >= asVersion(7, 0, 0)) {
	void LLVMInitializeAggressiveInstCombiner(LLVMPassRegistryRef R);
}

static if (LLVM_Version >= asVersion(7, 0, 0)) {
	void LLVMOrcRegisterJITEventListener(LLVMOrcJITStackRef JITStack, LLVMJITEventListenerRef L);
}

static if (LLVM_Version >= asVersion(7, 0, 0)) {
	void LLVMOrcUnregisterJITEventListener(LLVMOrcJITStackRef JITStack, LLVMJITEventListenerRef L);
}

static if (LLVM_Version >= asVersion(7, 0, 0)) {
	char* LLVMNormalizeTargetTriple(const(char)* triple);
}

static if (LLVM_Version >= asVersion(7, 0, 0)) {
	char* LLVMGetHostCPUName();
}

static if (LLVM_Version >= asVersion(7, 0, 0)) {
	char* LLVMGetHostCPUFeatures();
}

/+ Error +/

static if (LLVM_Version >= asVersion(8, 0, 0)) {
	LLVMErrorTypeId LLVMGetErrorTypeId(LLVMErrorRef Err);

	void LLVMConsumeError(LLVMErrorRef Err);

	char* LLVMGetErrorMessage(LLVMErrorRef Err);

	void LLVMDisposeErrorMessage(char* ErrMsg);

	LLVMErrorTypeId LLVMGetStringErrorTypeId();
}

/+ Aggressive Instruction Combining transformations +/

static if (LLVM_Version >= asVersion(8, 0, 0)) {
	void LLVMAddAggressiveInstCombinerPass(LLVMPassManagerRef PM);
}

/+ Coroutine transformations +/

static if (LLVM_Version >= asVersion(8, 0, 0)) {
	void LLVMAddCoroEarlyPass(LLVMPassManagerRef PM);

	void LLVMAddCoroSplitPass(LLVMPassManagerRef PM);

	void LLVMAddCoroElidePass(LLVMPassManagerRef PM);

	void LLVMAddCoroCleanupPass(LLVMPassManagerRef PM);
}

/+ Remarks / OptRemarks +/

static if (LLVM_Version >= asVersion(9, 0, 0)) {
    const(char)* LLVMRemarkStringGetData(LLVMRemarkStringRef String);

    uint32_t LLVMRemarkStringGetLen(LLVMRemarkStringRef String);

    LLVMRemarkStringRef LLVMRemarkDebugLocGetSourceFilePath(LLVMRemarkDebugLocRef DL);

    uint32_t LLVMRemarkDebugLocGetSourceLine(LLVMRemarkDebugLocRef DL);

    uint32_t LLVMRemarkDebugLocGetSourceColumn(LLVMRemarkDebugLocRef DL);
    
    LLVMRemarkStringRef LLVMRemarkArgGetKey(LLVMRemarkArgRef Arg);

    LLVMRemarkStringRef LLVMRemarkArgGetValue(LLVMRemarkArgRef Arg);

    LLVMRemarkDebugLocRef LLVMRemarkArgGetDebugLoc(LLVMRemarkArgRef Arg);

    void LLVMRemarkEntryDispose(LLVMRemarkEntryRef Remark);
    
    LLVMRemarkType LLVMRemarkEntryGetType(LLVMRemarkEntryRef Remark);

    LLVMRemarkStringRef LLVMRemarkEntryGetPassName(LLVMRemarkEntryRef Remark);


    LLVMRemarkStringRef LLVMRemarkEntryGetRemarkName(LLVMRemarkEntryRef Remark);

    LLVMRemarkStringRef LLVMRemarkEntryGetFunctionName(LLVMRemarkEntryRef Remark);

    LLVMRemarkDebugLocRef LLVMRemarkEntryGetDebugLoc(LLVMRemarkEntryRef Remark);

    uint64_t LLVMRemarkEntryGetHotness(LLVMRemarkEntryRef Remark);

    uint32_t LLVMRemarkEntryGetNumArgs(LLVMRemarkEntryRef Remark);

    LLVMRemarkArgRef LLVMRemarkEntryGetFirstArg(LLVMRemarkEntryRef Remark);

    LLVMRemarkArgRef LLVMRemarkEntryGetNextArg(LLVMRemarkArgRef It, LLVMRemarkEntryRef Remark);


    LLVMRemarkParserRef LLVMRemarkParserCreateYAML(const(void)* Buf, uint64_t Size);

    static if (LLVM_Version >= asVersion(10, 0, 0)) {
        LLVMRemarkParserRef LLVMRemarkParserCreateBitstream(const(void)* Buf, uint64_t Size);
    }

    LLVMRemarkEntryRef LLVMRemarkParserGetNext(LLVMRemarkParserRef Parser);

    LLVMBool LLVMRemarkParserHasError(LLVMRemarkParserRef Parser);

    const(char)* LLVMRemarkParserGetErrorMessage(LLVMRemarkParserRef Parser);

    void LLVMRemarkParserDispose(LLVMRemarkParserRef Parser);

    uint32_t LLVMRemarkVersion();

} else static if (LLVM_Version >= asVersion(8, 0, 0)) {
	LLVMOptRemarkParserRef LLVMOptRemarkParserCreate(const(void)* Buf, uint64_t Size);

	LLVMOptRemarkEntry* LLVMOptRemarkParserGetNext(LLVMOptRemarkParserRef Parser);

	LLVMBool LLVMOptRemarkParserHasError(LLVMOptRemarkParserRef Parser);

	const(char)* LLVMOptRemarkParserGetErrorMessage(LLVMOptRemarkParserRef Parser);

	void LLVMOptRemarkParserDispose(LLVMOptRemarkParserRef Parser);

	uint32_t LLVMOptRemarkVersion();
}
