module llvm.constants;

import llvm.config;
import llvm.types;

/+ Analysis +/

enum : LLVMVerifierFailureAction
{
	LLVMAbortProcessAction,
	LLVMPrintMessageAction,
	LLVMReturnStatusAction
}

/+ Core +/

/++ Types and Enumerations ++/

static if (LLVM_Version < asVersion(4, 0, 0))
{
	enum : LLVMAttribute
	{
		LLVMZExtAttribute = 1<<0,
		LLVMSExtAttribute = 1<<1,
		LLVMNoReturnAttribute = 1<<2,
		LLVMInRegAttribute = 1<<3,
		LLVMStructRetAttribute = 1<<4,
		LLVMNoUnwindAttribute = 1<<5,
		LLVMNoAliasAttribute = 1<<6,
		LLVMByValAttribute = 1<<7,
		LLVMNestAttribute = 1<<8,
		LLVMReadNoneAttribute = 1<<9,
		LLVMReadOnlyAttribute = 1<<10,
		LLVMNoInlineAttribute = 1<<11,
		LLVMAlwaysInlineAttribute = 1<<12,
		LLVMOptimizeForSizeAttribute = 1<<13,
		LLVMStackProtectAttribute = 1<<14,
		LLVMStackProtectReqAttribute = 1<<15,
		LLVMAlignment = 31<<16,
		LLVMNoCaptureAttribute = 1<<21,
		LLVMNoRedZoneAttribute = 1<<22,
		LLVMNoImplicitFloatAttribute = 1<<23,
		LLVMNakedAttribute = 1<<24,
		LLVMInlineHintAttribute = 1<<25,
		LLVMStackAlignment = 7<<26,
		LLVMReturnsTwice = 1<<29,
		LLVMUWTable = 1<<30,
		LLVMNonLazyBind = 1<<31
	}
}

enum : LLVMOpcode
{
	LLVMRet            = 1,
	LLVMBr             = 2,
	LLVMSwitch         = 3,
	LLVMIndirectBr     = 4,
	LLVMInvoke         = 5,
	LLVMUnreachable    = 7,
	LLVMAdd            = 8,
	LLVMFAdd           = 9,
	LLVMSub            = 10,
	LLVMFSub           = 11,
	LLVMMul            = 12,
	LLVMFMul           = 13,
	LLVMUDiv           = 14,
	LLVMSDiv           = 15,
	LLVMFDiv           = 16,
	LLVMURem           = 17,
	LLVMSRem           = 18,
	LLVMFRem           = 19,
	LLVMShl            = 20,
	LLVMLShr           = 21,
	LLVMAShr           = 22,
	LLVMAnd            = 23,
	LLVMOr             = 24,
	LLVMXor            = 25,
	LLVMAlloca         = 26,
	LLVMLoad           = 27,
	LLVMStore          = 28,
	LLVMGetElementPtr  = 29,
	LLVMTrunc          = 30,
	LLVMZExt           = 31,
	LLVMSExt           = 32,
	LLVMFPToUI         = 33,
	LLVMFPToSI         = 34,
	LLVMUIToFP         = 35,
	LLVMSIToFP         = 36,
	LLVMFPTrunc        = 37,
	LLVMFPExt          = 38,
	LLVMPtrToInt       = 39,
	LLVMIntToPtr       = 40,
	LLVMBitCast        = 41,
	LLVMICmp           = 42,
	LLVMFCmp           = 43,
	LLVMPHI            = 44,
	LLVMCall           = 45,
	LLVMSelect         = 46,
	LLVMUserOp1        = 47,
	LLVMUserOp2        = 48,
	LLVMVAArg          = 49,
	LLVMExtractElement = 50,
	LLVMInsertElement  = 51,
	LLVMShuffleVector  = 52,
	LLVMExtractValue   = 53,
	LLVMInsertValue    = 54,
	LLVMFence          = 55,
	LLVMAtomicCmpXchg  = 56,
	LLVMAtomicRMW      = 57,
	LLVMResume         = 58,
	LLVMLandingPad     = 59,
}
static if (LLVM_Version >= asVersion(3, 4, 0))
{
	enum : LLVMOpcode
	{
		LLVMAddrSpaceCast  = 60
	}
}
static if (LLVM_Version >= asVersion(3, 8, 0))
{
	enum : LLVMOpcode
	{
		LLVMCleanupRet     = 61,
		LLVMCatchRet       = 62,
		LLVMCatchPad       = 63,
		LLVMCleanupPad     = 64,
		LLVMCatchSwitch    = 65
	}
}
static if (LLVM_Version >= asVersion(8, 0, 0))
{
	enum : LLVMOpcode
	{
		LLVMFNeg  = 66
	}
}
static if (LLVM_Version >= asVersion(9, 0, 0))
{
	enum : LLVMOpcode
	{
		LLVMCallBr  = 67
	}
}
static if (LLVM_Version >= asVersion(10, 0, 0))
{
	enum : LLVMOpcode
	{
		LLVMFreeze  = 68
	}
}

static if (LLVM_Version >= asVersion(3, 9, 0))
{
	enum : LLVMValueKind
	{
		LLVMArgumentValueKind,
		LLVMBasicBlockValueKind,
		LLVMMemoryUseValueKind,
		LLVMMemoryDefValueKind,
		LLVMMemoryPhiValueKind,
		LLVMFunctionValueKind,
		LLVMGlobalAliasValueKind,
		LLVMGlobalIFuncValueKind,
		LLVMGlobalVariableValueKind,
		LLVMBlockAddressValueKind,
		LLVMConstantExprValueKind,
		LLVMConstantArrayValueKind,
		LLVMConstantStructValueKind,
		LLVMConstantVectorValueKind,
		LLVMUndefValueValueKind,
		LLVMConstantAggregateZeroValueKind,
		LLVMConstantDataArrayValueKind,
		LLVMConstantDataVectorValueKind,
		LLVMConstantIntValueKind,
		LLVMConstantFPValueKind,
		LLVMConstantPointerNullValueKind,
		LLVMConstantTokenNoneValueKind,
		LLVMMetadataAsValueValueKind,
		LLVMInlineAsmValueKind,
		LLVMInstructionValueKind,
	}

	enum : LLVMAttributeIndex
	{
		LLVMAttributeReturnIndex = 0U,
		LLVMAttributeFunctionIndex = -1,
	}
}

static if (LLVM_Version >= asVersion(3, 8, 0)) {
	enum : LLVMTypeKind
	{
		LLVMVoidTypeKind,
		LLVMHalfTypeKind,
		LLVMFloatTypeKind,
		LLVMDoubleTypeKind,
		LLVMX86_FP80TypeKind,
		LLVMFP128TypeKind,
		LLVMPPC_FP128TypeKind,
		LLVMLabelTypeKind,
		LLVMIntegerTypeKind,
		LLVMFunctionTypeKind,
		LLVMStructTypeKind,
		LLVMArrayTypeKind,
		LLVMPointerTypeKind,
		LLVMVectorTypeKind,
		LLVMMetadataTypeKind,
		LLVMX86_MMXTypeKind,
		LLVMTokenTypeKind
	}
} else {
	enum : LLVMTypeKind
	{
		LLVMVoidTypeKind,
		LLVMHalfTypeKind,
		LLVMFloatTypeKind,
		LLVMDoubleTypeKind,
		LLVMX86_FP80TypeKind,
		LLVMFP128TypeKind,
		LLVMPPC_FP128TypeKind,
		LLVMLabelTypeKind,
		LLVMIntegerTypeKind,
		LLVMFunctionTypeKind,
		LLVMStructTypeKind,
		LLVMArrayTypeKind,
		LLVMPointerTypeKind,
		LLVMVectorTypeKind,
		LLVMMetadataTypeKind,
		LLVMX86_MMXTypeKind,
		LLVMTokenTypeKind
	}
}

static if (LLVM_Version >= asVersion(3, 2, 0)) {
	enum : LLVMLinkage
	{
		LLVMExternalLinkage,
		LLVMAvailableExternallyLinkage,
		LLVMLinkOnceAnyLinkage,
		LLVMLinkOnceODRLinkage,
		LLVMLinkOnceODRAutoHideLinkage,
		LLVMWeakAnyLinkage,
		LLVMWeakODRLinkage,
		LLVMAppendingLinkage,
		LLVMInternalLinkage,
		LLVMPrivateLinkage,
		LLVMDLLImportLinkage,
		LLVMDLLExportLinkage,
		LLVMExternalWeakLinkage,
		LLVMGhostLinkage,
		LLVMCommonLinkage,
		LLVMLinkerPrivateLinkage,
		LLVMLinkerPrivateWeakLinkage,
	}
} else {
	enum : LLVMLinkage
	{
		LLVMExternalLinkage,
		LLVMAvailableExternallyLinkage,
		LLVMLinkOnceAnyLinkage,
		LLVMLinkOnceODRLinkage,
		LLVMWeakAnyLinkage,
		LLVMWeakODRLinkage,
		LLVMAppendingLinkage,
		LLVMInternalLinkage,
		LLVMPrivateLinkage,
		LLVMDLLImportLinkage,
		LLVMDLLExportLinkage,
		LLVMExternalWeakLinkage,
		LLVMGhostLinkage,
		LLVMCommonLinkage,
		LLVMLinkerPrivateLinkage,
		LLVMLinkerPrivateWeakLinkage,
		LLVMLinkerPrivateWeakDefAutoLinkage
	}
}

enum : LLVMVisibility
{
	LLVMDefaultVisibility,
	LLVMHiddenVisibility,
	LLVMProtectedVisibility
}

static if (LLVM_Version >= asVersion(3, 5, 0))
{
	enum : LLVMDLLStorageClass {
		LLVMDefaultStorageClass = 0,
		LLVMDLLImportStorageClass = 1,
		LLVMDLLExportStorageClass = 2
	}
}

static if (LLVM_Version >= asVersion(7, 0, 0))
{
	enum : LLVMCallConv {
		LLVMCCallConv             = 0,
		LLVMFastCallConv          = 8,
		LLVMColdCallConv          = 9,
		LLVMGHCCallConv           = 10,
		LLVMHiPECallConv          = 11,
		LLVMWebKitJSCallConv      = 12,
		LLVMAnyRegCallConv        = 13,
		LLVMPreserveMostCallConv  = 14,
		LLVMPreserveAllCallConv   = 15,
		LLVMSwiftCallConv         = 16,
		LLVMCXXFASTTLSCallConv    = 17,
		LLVMX86StdcallCallConv    = 64,
		LLVMX86FastcallCallConv   = 65,
		LLVMARMAPCSCallConv       = 66,
		LLVMARMAAPCSCallConv      = 67,
		LLVMARMAAPCSVFPCallConv   = 68,
		LLVMMSP430INTRCallConv    = 69,
		LLVMX86ThisCallCallConv   = 70,
		LLVMPTXKernelCallConv     = 71,
		LLVMPTXDeviceCallConv     = 72,
		LLVMSPIRFUNCCallConv      = 75,
		LLVMSPIRKERNELCallConv    = 76,
		LLVMIntelOCLBICallConv    = 77,
		LLVMX8664SysVCallConv     = 78,
		LLVMWin64CallConv         = 79,
		LLVMX86VectorCallCallConv = 80,
		LLVMHHVMCallConv          = 81,
		LLVMHHVMCCallConv         = 82,
		LLVMX86INTRCallConv       = 83,
		LLVMAVRINTRCallConv       = 84,
		LLVMAVRSIGNALCallConv     = 85,
		LLVMAVRBUILTINCallConv    = 86,
		LLVMAMDGPUVSCallConv      = 87,
		LLVMAMDGPUGSCallConv      = 88,
		LLVMAMDGPUPSCallConv      = 89,
		LLVMAMDGPUCSCallConv      = 90,
		LLVMAMDGPUKERNELCallConv  = 91,
		LLVMX86RegCallCallConv    = 92,
		LLVMAMDGPUHSCallConv      = 93,
		LLVMMSP430BUILTINCallConv = 94,
		LLVMAMDGPULSCallConv      = 95,
		LLVMAMDGPUESCallConv      = 96
	}
}
else static if (LLVM_Version >= asVersion(3, 4, 0))
{
	enum : LLVMCallConv {
		LLVMCCallConv           = 0,
		LLVMFastCallConv        = 8,
		LLVMColdCallConv        = 9,
		LLVMWebKitJSCallConv    = 12,
		LLVMAnyRegCallConv      = 13,
		LLVMX86StdcallCallConv  = 64,
		LLVMX86FastcallCallConv = 65
	}
} else {
	enum : LLVMCallConv {
		LLVMCCallConv           = 0,
		LLVMFastCallConv        = 8,
		LLVMColdCallConv        = 9,
		LLVMX86StdcallCallConv  = 64,
		LLVMX86FastcallCallConv = 65
	}
}

enum : LLVMIntPredicate
{
	LLVMIntEQ = 32,
	LLVMIntNE,
	LLVMIntUGT,
	LLVMIntUGE,
	LLVMIntULT,
	LLVMIntULE,
	LLVMIntSGT,
	LLVMIntSGE,
	LLVMIntSLT,
	LLVMIntSLE
}

enum : LLVMRealPredicate
{
	LLVMRealPredicateFalse,
	LLVMRealOEQ,
	LLVMRealOGT,
	LLVMRealOGE,
	LLVMRealOLT,
	LLVMRealOLE,
	LLVMRealONE,
	LLVMRealORD,
	LLVMRealUNO,
	LLVMRealUEQ,
	LLVMRealUGT,
	LLVMRealUGE,
	LLVMRealULT,
	LLVMRealULE,
	LLVMRealUNE,
	LLVMRealPredicateTrue
}

enum : LLVMLandingPadClauseTy
{
	LLVMLandingPadCatch,
	LLVMLandingPadFilter
}

static if (LLVM_Version >= asVersion(3, 3, 0))
{
	enum : LLVMThreadLocalMode
	{
		LLVMNotThreadLocal = 0,
		LLVMGeneralDynamicTLSModel,
		LLVMLocalDynamicTLSModel,
		LLVMInitialExecTLSModel,
		LLVMLocalExecTLSModel
	}

	enum : LLVMAtomicOrdering
	{
		LLVMAtomicOrderingNotAtomic = 0,
		LLVMAtomicOrderingUnordered = 1,
		LLVMAtomicOrderingMonotonic = 2,
		LLVMAtomicOrderingAcquire = 4,
		LLVMAtomicOrderingRelease = 5,
		LLVMAtomicOrderingAcquireRelease = 6,
		LLVMAtomicOrderingSequentiallyConsistent = 7
	}

	static if (LLVM_Version >= asVersion(10, 0, 0))
	{
		enum : LLVMAtomicRMWBinOp
		{
			LLVMAtomicRMWBinOpXchg,
			LLVMAtomicRMWBinOpAdd,
			LLVMAtomicRMWBinOpSub,
			LLVMAtomicRMWBinOpAnd,
			LLVMAtomicRMWBinOpNand,
			LLVMAtomicRMWBinOpOr,
			LLVMAtomicRMWBinOpXor,
			LLVMAtomicRMWBinOpMax,
			LLVMAtomicRMWBinOpMin,
			LLVMAtomicRMWBinOpUMax,
			LLVMAtomicRMWBinOpUMin,
			LLVMAtomicRMWBinOpFAdd,
			LLVMAtomicRMWBinOpFSub
		}
	}
	else
	{
		enum : LLVMAtomicRMWBinOp
		{
			LLVMAtomicRMWBinOpXchg,
			LLVMAtomicRMWBinOpAdd,
			LLVMAtomicRMWBinOpSub,
			LLVMAtomicRMWBinOpAnd,
			LLVMAtomicRMWBinOpNand,
			LLVMAtomicRMWBinOpOr,
			LLVMAtomicRMWBinOpXor,
			LLVMAtomicRMWBinOpMax,
			LLVMAtomicRMWBinOpMin,
			LLVMAtomicRMWBinOpUMax,
			LLVMAtomicRMWBinOpUMin
		}
	}
}
static if (LLVM_Version >= asVersion(3, 5, 0))
{
	enum : LLVMDiagnosticSeverity {
		LLVMDSError,
		LLVMDSWarning,
		LLVMDSRemark,
		LLVMDSNote
	}
}

/+ Disassembler +/

//TODO: replace const with enum?
const
{
	uint LLVMDisassembler_VariantKind_None = 0;
	uint LLVMDisassembler_VariantKind_ARM_HI16 = 1;
	uint LLVMDisassembler_VariantKind_ARM_LO16 = 2;
	static if (LLVM_Version >= asVersion(3, 5, 0))
	{
		uint LLVMDisassembler_VariantKind_ARM64_PAGE = 1;
		uint LLVMDisassembler_VariantKind_ARM64_PAGEOFF = 2;
		uint LLVMDisassembler_VariantKind_ARM64_GOTPAGE = 3;
		uint LLVMDisassembler_VariantKind_ARM64_GOTPAGEOFF = 4;
		uint LLVMDisassembler_VariantKind_ARM64_TLVP = 5;
		uint LLVMDisassembler_VariantKind_ARM64_TLVOFF = 6;
	}
	uint LLVMDisassembler_ReferenceType_InOut_None = 0;
	uint LLVMDisassembler_ReferenceType_In_Branch = 1;
	uint LLVMDisassembler_ReferenceType_In_PCrel_Load = 2;
	static if (LLVM_Version >= asVersion(3, 5, 0))
	{
		ulong LLVMDisassembler_ReferenceType_In_ARM64_ADRP = 0x100000001;
		ulong LLVMDisassembler_ReferenceType_In_ARM64_ADDXri = 0x100000002;
		ulong LLVMDisassembler_ReferenceType_In_ARM64_LDRXui = 0x100000003;
		ulong LLVMDisassembler_ReferenceType_In_ARM64_LDRXl = 0x100000004;
		ulong LLVMDisassembler_ReferenceType_In_ARM64_ADR = 0x100000005;
	}
	uint LLVMDisassembler_ReferenceType_Out_SymbolStub = 1;
	uint LLVMDisassembler_ReferenceType_Out_LitPool_SymAddr = 2;
	uint LLVMDisassembler_ReferenceType_Out_LitPool_CstrAddr = 3;
	static if (LLVM_Version >= asVersion(3, 2, 0))
	{
		uint LLVMDisassembler_Option_UseMarkup = 1;
	}
	static if (LLVM_Version >= asVersion(3, 3, 0))
	{
		uint LLVMDisassembler_Option_PrintImmHex = 2;
		uint LLVMDisassembler_Option_AsmPrinterVariant = 4;
	}
	static if (LLVM_Version >= asVersion(3, 4, 0))
	{
		uint LLVMDisassembler_ReferenceType_Out_Objc_CFString_Ref = 4;
		uint LLVMDisassembler_ReferenceType_Out_Objc_Message = 5;
		uint LLVMDisassembler_ReferenceType_Out_Objc_Message_Ref = 6;
		uint LLVMDisassembler_ReferenceType_Out_Objc_Selector_Ref = 7;
		uint LLVMDisassembler_ReferenceType_Out_Objc_Class_Ref = 8;
		uint LLVMDisassembler_Option_SetInstrComments = 8;
		uint LLVMDisassembler_Option_PrintLatency = 16;
	}
	static if (LLVM_Version >= asVersion(3, 5, 0))
	{
		uint LLVMDisassembler_ReferenceType_DeMangled_Name = 9;
	}
}

static if (LLVM_Version < asVersion(3, 3, 0))
{
	/+ Enhanced Disassembly +/

	enum : EDAssemblySyntax_t
	{
		kEDAssemblySyntaxX86Intel = 0,
		kEDAssemblySyntaxX86ATT = 1,
		kEDAssemblySyntaxARMUAL = 2
	}
}

/+ Linker +/
static if (LLVM_Version >= asVersion(3, 2, 0))
{
	enum : LLVMLinkerMode
	{
		LLVMLinkerDestroySource  = 0
	}

	static if (LLVM_Version < asVersion(3, 7, 0))
	{
		enum : LLVMLinkerMode
		{
			LLVMLinkerPreserveSource  = 1
		}
	}
}

/+ Link Time Optimization +/

enum : llvm_lto_status
{
	LLVM_LTO_UNKNOWN,
	LLVM_LTO_OPT_SUCCESS,
	LLVM_LTO_READ_SUCCESS,
	LLVM_LTO_READ_FAILURE,
	LLVM_LTO_WRITE_FAILURE,
	LLVM_LTO_NO_TARGET,
	LLVM_LTO_NO_WORK,
	LLVM_LTO_MODULE_MERGE_FAILURE,
	LLVM_LTO_ASM_FAILURE,
	LLVM_LTO_NULL_OBJECT
}

/+ LTO +/
static if (LLVM_Version >= asVersion(10, 0, 0))
{
	const uint LTO_API_VERSION = 26;
}
else static if (LLVM_Version >= asVersion(9, 0, 0))
{
	const uint LTO_API_VERSION = 24;
}
else static if (LLVM_Version >= asVersion(8, 0, 0))
{
	const uint LTO_API_VERSION = 23;
}
else static if (LLVM_Version >= asVersion(7, 0, 0))
{
	const uint LTO_API_VERSION = 22;
}
else static if (LLVM_Version >= asVersion(4, 0, 0))
{
	const uint LTO_API_VERSION = 21;
}
else static if (LLVM_Version >= asVersion(3, 9, 0))
{
	const uint LTO_API_VERSION = 20;
}
else static if (LLVM_Version >= asVersion(3, 7, 0))
{
	const uint LTO_API_VERSION = 17;
}
else static if (LLVM_Version >= asVersion(3, 6, 0))
{
	const uint LTO_API_VERSION = 11;
}
else static if (LLVM_Version >= asVersion(3, 5, 0))
{
	const uint LTO_API_VERSION = 10;
}
else static if (LLVM_Version >= asVersion(3, 4, 0))
{
	const uint LTO_API_VERSION = 5;
}
else
{
	const uint LTO_API_VERSION = 4;
}

enum : lto_symbol_attributes
{
	LTO_SYMBOL_ALIGNMENT_MASK              = 0x0000001F,
	LTO_SYMBOL_PERMISSIONS_MASK            = 0x000000E0,
	LTO_SYMBOL_PERMISSIONS_CODE            = 0x000000A0,
	LTO_SYMBOL_PERMISSIONS_DATA            = 0x000000C0,
	LTO_SYMBOL_PERMISSIONS_RODATA          = 0x00000080,
	LTO_SYMBOL_DEFINITION_MASK             = 0x00000700,
	LTO_SYMBOL_DEFINITION_REGULAR          = 0x00000100,
	LTO_SYMBOL_DEFINITION_TENTATIVE        = 0x00000200,
	LTO_SYMBOL_DEFINITION_WEAK             = 0x00000300,
	LTO_SYMBOL_DEFINITION_UNDEFINED        = 0x00000400,
	LTO_SYMBOL_DEFINITION_WEAKUNDEF        = 0x00000500,
	LTO_SYMBOL_SCOPE_MASK                  = 0x00003800,
	LTO_SYMBOL_SCOPE_INTERNAL              = 0x00000800,
	LTO_SYMBOL_SCOPE_HIDDEN                = 0x00001000,
	LTO_SYMBOL_SCOPE_PROTECTED             = 0x00002000,
	LTO_SYMBOL_SCOPE_DEFAULT               = 0x00001800,
	LTO_SYMBOL_SCOPE_DEFAULT_CAN_BE_HIDDEN = 0x00002800,
}
static if (LLVM_Version >= asVersion(3, 7, 0))
{
	enum : lto_symbol_attributes
	{
		LTO_SYMBOL_COMDAT                  = 0x00004000,
		LTO_SYMBOL_ALIAS                   = 0x00008000
	}
}

enum : lto_debug_model
{
	LTO_DEBUG_MODEL_NONE = 0,
	LTO_DEBUG_MODEL_DWARF = 1
}

enum : lto_codegen_model
{
	LTO_CODEGEN_PIC_MODEL_STATIC = 0,
	LTO_CODEGEN_PIC_MODEL_DYNAMIC = 1,
	LTO_CODEGEN_PIC_MODEL_DYNAMIC_NO_PIC = 2,
	LTO_CODEGEN_PIC_MODEL_DEFAULT = 3
}

static if (LLVM_Version >= asVersion(3, 5, 0))
{
	enum : lto_codegen_diagnostic_severity_t
	{
		LTO_DS_ERROR = 0,
		LTO_DS_WARNING = 1,
	   	LTO_DS_REMARK = 3,
		LTO_DS_NOTE = 2
	}
}

/+ Object file reading and writing +/

static if (LLVM_Version >= asVersion(9, 0, 0))
{
	enum : LLVMBinaryType
	{
		LLVMBinaryTypeArchive,
		LLVMBinaryTypeMachOUniversalBinary,
		LLVMBinaryTypeCOFFImportFile,
		LLVMBinaryTypeIR,
		LLVMBinaryTypeWinRes,
		LLVMBinaryTypeCOFF,
		LLVMBinaryTypeELF32L,
		LLVMBinaryTypeELF32B,
		LLVMBinaryTypeELF64L,
		LLVMBinaryTypeELF64B,
		LLVMBinaryTypeMachO32L,
		LLVMBinaryTypeMachO32B,
		LLVMBinaryTypeMachO64L,
		LLVMBinaryTypeMachO64B,
		LLVMBinaryTypeWasm
	}
}

/+ Target information +/

enum : LLVMByteOrdering
{
	LLVMBigEndian,
	LLVMLittleEndian
}

/+ Target machine +/

enum : LLVMCodeGenOptLevel
{
	LLVMCodeGenLevelNone,
	LLVMCodeGenLevelLess,
	LLVMCodeGenLevelDefault,
	LLVMCodeGenLevelAggressive
}

static if (LLVM_Version >= asVersion(8, 0, 0)) {
	enum : LLVMRelocMode
	{
		LLVMRelocDefault,
		LLVMRelocStatic,
		LLVMRelocPIC,
      LLVMRelocDynamicNoPic,
      LLVMRelocROPI,
      LLVMRelocRWPI,
      LLVMRelocROPI_RWPI
	}
} else {
	enum : LLVMRelocMode
	{
		LLVMRelocDefault,
		LLVMRelocStatic,
		LLVMRelocPIC,
		LLVMRelocDynamicNoPic
	}
}

static if (LLVM_Version >= asVersion(8, 0, 0)) {
	enum : LLVMCodeModel
	{
		LLVMCodeModelDefault,
		LLVMCodeModelJITDefault,
		LLVMCodeModelTiny,
		LLVMCodeModelSmall,
		LLVMCodeModelKernel,
		LLVMCodeModelMedium,
		LLVMCodeModelLarge
	}
} else {
	enum : LLVMCodeModel
	{
		LLVMCodeModelDefault,
		LLVMCodeModelJITDefault,
		LLVMCodeModelSmall,
		LLVMCodeModelKernel,
		LLVMCodeModelMedium,
		LLVMCodeModelLarge
	}
}

enum : LLVMCodeGenFileType
{
	LLVMAssemblyFile,
	LLVMObjectFile
}

/+ Orc +/

static if (LLVM_Version >= asVersion(3, 9, 0) && LLVM_Version < asVersion(8, 0, 0))
{
	enum : LLVMOrcErrorCode
	{
		LLVMOrcErrSuccess = 0,
		LLVMOrcErrGeneric,
	}
}

/+ Debug info flags +/

static if (LLVM_Version >= asVersion(10, 0, 0))
{
	enum : LLVMDIFlags {
		LLVMDIFlagZero = 0,
		LLVMDIFlagPrivate = 1,
		LLVMDIFlagProtected = 2,
		LLVMDIFlagPublic = 3,
		LLVMDIFlagFwdDecl = 1 << 2,
		LLVMDIFlagAppleBlock = 1 << 3,
		LLVMDIFlagReservedBit4 = 1 << 4,
		LLVMDIFlagVirtual = 1 << 5,
		LLVMDIFlagArtificial = 1 << 6,
		LLVMDIFlagExplicit = 1 << 7,
		LLVMDIFlagPrototyped = 1 << 8,
		LLVMDIFlagObjcClassComplete = 1 << 9,
		LLVMDIFlagObjectPointer = 1 << 10,
		LLVMDIFlagVector = 1 << 11,
		LLVMDIFlagStaticMember = 1 << 12,
		LLVMDIFlagLValueReference = 1 << 13,
		LLVMDIFlagRValueReference = 1 << 14,
		LLVMDIFlagReserved = 1 << 15,
		LLVMDIFlagSingleInheritance = 1 << 16,
		LLVMDIFlagMultipleInheritance = 2 << 16,
		LLVMDIFlagVirtualInheritance = 3 << 16,
		LLVMDIFlagIntroducedVirtual = 1 << 18,
		LLVMDIFlagBitField = 1 << 19,
		LLVMDIFlagNoReturn = 1 << 20,
		LLVMDIFlagTypePassByValue = 1 << 22,
		LLVMDIFlagTypePassByReference = 1 << 23,
		LLVMDIFlagEnumClass = 1 << 24,
		LLVMDIFlagFixedEnum = LLVMDIFlagEnumClass,
		LLVMDIFlagThunk = 1 << 25,
		LLVMDIFlagNonTrivial = 1 << 26,
		LLVMDIFlagBigEndian = 1 << 27,
		LLVMDIFlagLittleEndian = 1 << 28,
		LLVMDIFlagIndirectVirtualBase = (1 << 2) | (1 << 5),
		LLVMDIFlagAccessibility = LLVMDIFlagPrivate | LLVMDIFlagProtected | LLVMDIFlagPublic,
		LLVMDIFlagPtrToMemberRep = LLVMDIFlagSingleInheritance | LLVMDIFlagMultipleInheritance | LLVMDIFlagVirtualInheritance
	}
}
else static if (LLVM_Version >= asVersion(9, 0, 0))
{
	enum : LLVMDIFlags {
		LLVMDIFlagZero = 0,
		LLVMDIFlagPrivate = 1,
		LLVMDIFlagProtected = 2,
		LLVMDIFlagPublic = 3,
		LLVMDIFlagFwdDecl = 1 << 2,
		LLVMDIFlagAppleBlock = 1 << 3,
		LLVMDIFlagBlockByrefStruct = 1 << 4,
		LLVMDIFlagVirtual = 1 << 5,
		LLVMDIFlagArtificial = 1 << 6,
		LLVMDIFlagExplicit = 1 << 7,
		LLVMDIFlagPrototyped = 1 << 8,
		LLVMDIFlagObjcClassComplete = 1 << 9,
		LLVMDIFlagObjectPointer = 1 << 10,
		LLVMDIFlagVector = 1 << 11,
		LLVMDIFlagStaticMember = 1 << 12,
		LLVMDIFlagLValueReference = 1 << 13,
		LLVMDIFlagRValueReference = 1 << 14,
		LLVMDIFlagReserved = 1 << 15,
		LLVMDIFlagSingleInheritance = 1 << 16,
		LLVMDIFlagMultipleInheritance = 2 << 16,
		LLVMDIFlagVirtualInheritance = 3 << 16,
		LLVMDIFlagIntroducedVirtual = 1 << 18,
		LLVMDIFlagBitField = 1 << 19,
		LLVMDIFlagNoReturn = 1 << 20,
		LLVMDIFlagTypePassByValue = 1 << 22,
		LLVMDIFlagTypePassByReference = 1 << 23,
		LLVMDIFlagEnumClass = 1 << 24,
		LLVMDIFlagFixedEnum = LLVMDIFlagEnumClass,
		LLVMDIFlagThunk = 1 << 25,
		LLVMDIFlagNonTrivial = 1 << 26,
		LLVMDIFlagBigEndian = 1 << 27,
		LLVMDIFlagLittleEndian = 1 << 28,
		LLVMDIFlagIndirectVirtualBase = (1 << 2) | (1 << 5),
		LLVMDIFlagAccessibility = LLVMDIFlagPrivate | LLVMDIFlagProtected | LLVMDIFlagPublic,
		LLVMDIFlagPtrToMemberRep = LLVMDIFlagSingleInheritance | LLVMDIFlagMultipleInheritance | LLVMDIFlagVirtualInheritance
	}
}
else static if (LLVM_Version >= asVersion(8, 0, 0))
{
	enum : LLVMDIFlags {
		LLVMDIFlagZero = 0,
		LLVMDIFlagPrivate = 1,
		LLVMDIFlagProtected = 2,
		LLVMDIFlagPublic = 3,
		LLVMDIFlagFwdDecl = 1 << 2,
		LLVMDIFlagAppleBlock = 1 << 3,
		LLVMDIFlagBlockByrefStruct = 1 << 4,
		LLVMDIFlagVirtual = 1 << 5,
		LLVMDIFlagArtificial = 1 << 6,
		LLVMDIFlagExplicit = 1 << 7,
		LLVMDIFlagPrototyped = 1 << 8,
		LLVMDIFlagObjcClassComplete = 1 << 9,
		LLVMDIFlagObjectPointer = 1 << 10,
		LLVMDIFlagVector = 1 << 11,
		LLVMDIFlagStaticMember = 1 << 12,
		LLVMDIFlagLValueReference = 1 << 13,
		LLVMDIFlagRValueReference = 1 << 14,
		LLVMDIFlagReserved = 1 << 15,
		LLVMDIFlagSingleInheritance = 1 << 16,
		LLVMDIFlagMultipleInheritance = 2 << 16,
		LLVMDIFlagVirtualInheritance = 3 << 16,
		LLVMDIFlagIntroducedVirtual = 1 << 18,
		LLVMDIFlagBitField = 1 << 19,
		LLVMDIFlagNoReturn = 1 << 20,
		LLVMDIFlagMainSubprogram = 1 << 21,
		LLVMDIFlagTypePassByValue = 1 << 22,
		LLVMDIFlagTypePassByReference = 1 << 23,
		LLVMDIFlagEnumClass = 1 << 24,
		LLVMDIFlagFixedEnum = LLVMDIFlagEnumClass,
		LLVMDIFlagThunk = 1 << 25,
		LLVMDIFlagTrivial = 1 << 26,
		LLVMDIFlagBigEndian = 1 << 27,
		LLVMDIFlagLittleEndian = 1 << 28,
		LLVMDIFlagIndirectVirtualBase = (1 << 2) | (1 << 5),
		LLVMDIFlagAccessibility = LLVMDIFlagPrivate | LLVMDIFlagProtected | LLVMDIFlagPublic,
		LLVMDIFlagPtrToMemberRep = LLVMDIFlagSingleInheritance | LLVMDIFlagMultipleInheritance | LLVMDIFlagVirtualInheritance
	}
}
else static if (LLVM_Version >= asVersion(7, 0, 0))
{
	enum : LLVMDIFlags {
		LLVMDIFlagZero = 0,
		LLVMDIFlagPrivate = 1,
		LLVMDIFlagProtected = 2,
		LLVMDIFlagPublic = 3,
		LLVMDIFlagFwdDecl = 1 << 2,
		LLVMDIFlagAppleBlock = 1 << 3,
		LLVMDIFlagBlockByrefStruct = 1 << 4,
		LLVMDIFlagVirtual = 1 << 5,
		LLVMDIFlagArtificial = 1 << 6,
		LLVMDIFlagExplicit = 1 << 7,
		LLVMDIFlagPrototyped = 1 << 8,
		LLVMDIFlagObjcClassComplete = 1 << 9,
		LLVMDIFlagObjectPointer = 1 << 10,
		LLVMDIFlagVector = 1 << 11,
		LLVMDIFlagStaticMember = 1 << 12,
		LLVMDIFlagLValueReference = 1 << 13,
		LLVMDIFlagRValueReference = 1 << 14,
		LLVMDIFlagReserved = 1 << 15,
		LLVMDIFlagSingleInheritance = 1 << 16,
		LLVMDIFlagMultipleInheritance = 2 << 16,
		LLVMDIFlagVirtualInheritance = 3 << 16,
		LLVMDIFlagIntroducedVirtual = 1 << 18,
		LLVMDIFlagBitField = 1 << 19,
		LLVMDIFlagNoReturn = 1 << 20,
		LLVMDIFlagMainSubprogram = 1 << 21,
		LLVMDIFlagTypePassByValue = 1 << 22,
		LLVMDIFlagTypePassByReference = 1 << 23,
		LLVMDIFlagFixedEnum = 1 << 24,
		LLVMDIFlagThunk = 1 << 25,
		LLVMDIFlagTrivial = 1 << 26,
		LLVMDIFlagIndirectVirtualBase = (1 << 2) | (1 << 5),
		LLVMDIFlagAccessibility = LLVMDIFlagPrivate | LLVMDIFlagProtected | LLVMDIFlagPublic,
		LLVMDIFlagPtrToMemberRep = LLVMDIFlagSingleInheritance | LLVMDIFlagMultipleInheritance | LLVMDIFlagVirtualInheritance
	}
}
else static if (LLVM_Version >= asVersion(6, 0, 0))
{
	enum : LLVMDIFlags {
		LLVMDIFlagZero = 0,
		LLVMDIFlagPrivate = 1,
		LLVMDIFlagProtected = 2,
		LLVMDIFlagPublic = 3,
		LLVMDIFlagFwdDecl = 1 << 2,
		LLVMDIFlagAppleBlock = 1 << 3,
		LLVMDIFlagBlockByrefStruct = 1 << 4,
		LLVMDIFlagVirtual = 1 << 5,
		LLVMDIFlagArtificial = 1 << 6,
		LLVMDIFlagExplicit = 1 << 7,
		LLVMDIFlagPrototyped = 1 << 8,
		LLVMDIFlagObjcClassComplete = 1 << 9,
		LLVMDIFlagObjectPointer = 1 << 10,
		LLVMDIFlagVector = 1 << 11,
		LLVMDIFlagStaticMember = 1 << 12,
		LLVMDIFlagLValueReference = 1 << 13,
		LLVMDIFlagRValueReference = 1 << 14,
		LLVMDIFlagReserved = 1 << 15,
		LLVMDIFlagSingleInheritance = 1 << 16,
		LLVMDIFlagMultipleInheritance = 2 << 16,
		LLVMDIFlagVirtualInheritance = 3 << 16,
		LLVMDIFlagIntroducedVirtual = 1 << 18,
		LLVMDIFlagBitField = 1 << 19,
		LLVMDIFlagNoReturn = 1 << 20,
		LLVMDIFlagMainSubprogram = 1 << 21,
		LLVMDIFlagIndirectVirtualBase = (1 << 2) | (1 << 5),
		LLVMDIFlagAccessibility = LLVMDIFlagPrivate | LLVMDIFlagProtected |
		                          LLVMDIFlagPublic,
		LLVMDIFlagPtrToMemberRep = LLVMDIFlagSingleInheritance |
		                           LLVMDIFlagMultipleInheritance |
		                           LLVMDIFlagVirtualInheritance
	}
}

static if (LLVM_Version >= asVersion(6, 0, 0))
{
	enum : LLVMDWARFSourceLanguage {
		LLVMDWARFSourceLanguageC89,
		LLVMDWARFSourceLanguageC,
		LLVMDWARFSourceLanguageAda83,
		LLVMDWARFSourceLanguageC_plus_plus,
		LLVMDWARFSourceLanguageCobol74,
		LLVMDWARFSourceLanguageCobol85,
		LLVMDWARFSourceLanguageFortran77,
		LLVMDWARFSourceLanguageFortran90,
		LLVMDWARFSourceLanguagePascal83,
		LLVMDWARFSourceLanguageModula2,
		// New in DWARF v3:
		LLVMDWARFSourceLanguageJava,
		LLVMDWARFSourceLanguageC99,
		LLVMDWARFSourceLanguageAda95,
		LLVMDWARFSourceLanguageFortran95,
		LLVMDWARFSourceLanguagePLI,
		LLVMDWARFSourceLanguageObjC,
		LLVMDWARFSourceLanguageObjC_plus_plus,
		LLVMDWARFSourceLanguageUPC,
		LLVMDWARFSourceLanguageD,
		// New in DWARF v4:
		LLVMDWARFSourceLanguagePython,
		// New in DWARF v5:
		LLVMDWARFSourceLanguageOpenCL,
		LLVMDWARFSourceLanguageGo,
		LLVMDWARFSourceLanguageModula3,
		LLVMDWARFSourceLanguageHaskell,
		LLVMDWARFSourceLanguageC_plus_plus_03,
		LLVMDWARFSourceLanguageC_plus_plus_11,
		LLVMDWARFSourceLanguageOCaml,
		LLVMDWARFSourceLanguageRust,
		LLVMDWARFSourceLanguageC11,
		LLVMDWARFSourceLanguageSwift,
		LLVMDWARFSourceLanguageJulia,
		LLVMDWARFSourceLanguageDylan,
		LLVMDWARFSourceLanguageC_plus_plus_14,
		LLVMDWARFSourceLanguageFortran03,
		LLVMDWARFSourceLanguageFortran08,
		LLVMDWARFSourceLanguageRenderScript,
		LLVMDWARFSourceLanguageBLISS,
		// Vendor extensions:
		LLVMDWARFSourceLanguageMips_Assembler,
		LLVMDWARFSourceLanguageGOOGLE_RenderScript,
		LLVMDWARFSourceLanguageBORLAND_Delphi
	}
}

static if (LLVM_Version >= asVersion(6, 0, 0))
{
	enum : LLVMDWARFEmissionKind {
		LLVMDWARFEmissionNone = 0,
		LLVMDWARFEmissionFull,
		LLVMDWARFEmissionLineTablesOnly
	}

}

static if (LLVM_Version >= asVersion(9, 0, 0))
{
	enum : LLVMMetadataKind {
		LLVMMDStringMetadataKind,
		LLVMConstantAsMetadataMetadataKind,
		LLVMLocalAsMetadataMetadataKind,
		LLVMDistinctMDOperandPlaceholderMetadataKind,
		LLVMMDTupleMetadataKind,
		LLVMDILocationMetadataKind,
		LLVMDIExpressionMetadataKind,
		LLVMDIGlobalVariableExpressionMetadataKind,
		LLVMGenericDINodeMetadataKind,
		LLVMDISubrangeMetadataKind,
		LLVMDIEnumeratorMetadataKind,
		LLVMDIBasicTypeMetadataKind,
		LLVMDIDerivedTypeMetadataKind,
		LLVMDICompositeTypeMetadataKind,
		LLVMDISubroutineTypeMetadataKind,
		LLVMDIFileMetadataKind,
		LLVMDICompileUnitMetadataKind,
		LLVMDISubprogramMetadataKind,
		LLVMDILexicalBlockMetadataKind,
		LLVMDILexicalBlockFileMetadataKind,
		LLVMDINamespaceMetadataKind,
		LLVMDIModuleMetadataKind,
		LLVMDITemplateTypeParameterMetadataKind,
		LLVMDITemplateValueParameterMetadataKind,
		LLVMDIGlobalVariableMetadataKind,
		LLVMDILocalVariableMetadataKind,
		LLVMDILabelMetadataKind,
		LLVMDIObjCPropertyMetadataKind,
		LLVMDIImportedEntityMetadataKind,
		LLVMDIMacroMetadataKind,
		LLVMDIMacroFileMetadataKind,
		LLVMDICommonBlockMetadataKind
	}
}
else static if (LLVM_Version >= asVersion(8, 0, 0)) {
	enum : LLVMMetadataKind {
		LLVMMDStringMetadataKind,
		LLVMConstantAsMetadataMetadataKind,
		LLVMLocalAsMetadataMetadataKind,
		LLVMDistinctMDOperandPlaceholderMetadataKind,
		LLVMMDTupleMetadataKind,
		LLVMDILocationMetadataKind,
		LLVMDIExpressionMetadataKind,
		LLVMDIGlobalVariableExpressionMetadataKind,
		LLVMGenericDINodeMetadataKind,
		LLVMDISubrangeMetadataKind,
		LLVMDIEnumeratorMetadataKind,
		LLVMDIBasicTypeMetadataKind,
		LLVMDIDerivedTypeMetadataKind,
		LLVMDICompositeTypeMetadataKind,
		LLVMDISubroutineTypeMetadataKind,
		LLVMDIFileMetadataKind,
		LLVMDICompileUnitMetadataKind,
		LLVMDISubprogramMetadataKind,
		LLVMDILexicalBlockMetadataKind,
		LLVMDILexicalBlockFileMetadataKind,
		LLVMDINamespaceMetadataKind,
		LLVMDIModuleMetadataKind,
		LLVMDITemplateTypeParameterMetadataKind,
		LLVMDITemplateValueParameterMetadataKind,
		LLVMDIGlobalVariableMetadataKind,
		LLVMDILocalVariableMetadataKind,
		LLVMDILabelMetadataKind,
		LLVMDIObjCPropertyMetadataKind,
		LLVMDIImportedEntityMetadataKind,
		LLVMDIMacroMetadataKind,
		LLVMDIMacroFileMetadataKind
	}
}

static if (LLVM_Version >= asVersion(7, 0, 0))
{
	enum : LLVMComdatSelectionKind {
		LLVMAnyComdatSelectionKind,
		LLVMExactMatchComdatSelectionKind,
		LLVMLargestComdatSelectionKind,
		LLVMNoDuplicatesComdatSelectionKind,
		LLVMSameSizeComdatSelectionKind
	}
}

static if (LLVM_Version >= asVersion(7, 0, 0))
{
	enum : LLVMUnnamedAddr {
		  LLVMNoUnnamedAddr,
		  LLVMLocalUnnamedAddr,
		  LLVMGlobalUnnamedAddr
	}
}


static if (LLVM_Version >= asVersion(7, 0, 0))
{
	enum : LLVMInlineAsmDialect {
		LLVMInlineAsmDialectATT,
		LLVMInlineAsmDialectIntel
	}
}

static if (LLVM_Version >= asVersion(7, 0, 0))
{
	enum : LLVMModuleFlagBehavior {
		LLVMModuleFlagBehaviorError,
		LLVMModuleFlagBehaviorWarning,
		LLVMModuleFlagBehaviorRequire,
		LLVMModuleFlagBehaviorOverride,
		LLVMModuleFlagBehaviorAppend,
		LLVMModuleFlagBehaviorAppendUnique,
	}
}

static if (LLVM_Version >= asVersion(10, 0, 0))
{
	enum : LLVMDWARFMacinfoRecordType {
		LLVMDWARFMacinfoRecordTypeDefine    = 0x01,
		LLVMDWARFMacinfoRecordTypeMacro     = 0x02,
		LLVMDWARFMacinfoRecordTypeStartFile = 0x03,
		LLVMDWARFMacinfoRecordTypeEndFile   = 0x04,
		LLVMDWARFMacinfoRecordTypeVendorExt = 0xff
	}
}


/+ Error +/

static if (LLVM_Version >= asVersion(8, 0, 0)) {
	enum LLVMErrorSuccess = 0;
}

/+ Remarks / OptRemarks +/

static if (LLVM_Version >= asVersion(9, 0, 0)) {

	static if (LLVM_Version >= asVersion(10, 0, 0)) {
		enum REMARKS_API_VERSION = 1;
	}
	else {
		enum REMARKS_API_VERSION = 0;
	}

	enum : LLVMRemarkType {
		LLVMRemarkTypeUnknown,
		LLVMRemarkTypePassed,
		LLVMRemarkTypeMissed,
		LLVMRemarkTypeAnalysis,
		LLVMRemarkTypeAnalysisFPCommute,
		LLVMRemarkTypeAnalysisAliasing,
		LLVMRemarkTypeFailure
	}
} else static if (LLVM_Version >= asVersion(8, 0, 0)) {
	enum OPT_REMARKS_API_VERSION = 0;
}
