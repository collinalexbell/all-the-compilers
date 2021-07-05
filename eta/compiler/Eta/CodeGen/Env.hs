module Eta.CodeGen.Env where

import Eta.BasicTypes.Id
import Eta.StgSyn.StgSyn
import Eta.Types.TyCon

import Codec.JVM

import Eta.Utils.Util

import Eta.CodeGen.Types
import Eta.CodeGen.Closure
import Eta.CodeGen.Monad
import Eta.CodeGen.Utils
import Eta.CodeGen.ArgRep
import Eta.CodeGen.Name

import Control.Monad (liftM)

getArgLoadCode :: NonVoid StgArg -> CodeGen Code
getArgLoadCode (NonVoid (StgVarArg var)) = liftM idInfoLoadCode $ getCgIdInfo var
getArgLoadCode (NonVoid (StgLitArg literal)) = return . snd $ cgLit literal

getNonVoidArgCodes :: [StgArg] -> CodeGen [Code]
getNonVoidArgCodes [] = return []
getNonVoidArgCodes (arg:args)
  | isVoidRep (argPrimRep arg) = getNonVoidArgCodes args
  | otherwise = do
      code <- getArgLoadCode (NonVoid arg)
      codes <- getNonVoidArgCodes args
      return (code:codes)

getNonVoidArgFtCodes :: [StgArg] -> CodeGen [(FieldType, Code)]
getNonVoidArgFtCodes [] = return []
getNonVoidArgFtCodes (arg:args)
  | isVoidRep (argPrimRep arg) = getNonVoidArgFtCodes args
  | otherwise = do
      code <- getArgLoadCode (NonVoid arg)
      ftCodes <- getNonVoidArgFtCodes args
      return ((ft, code) : ftCodes)
  where primRep = argPrimRep arg
        ft = expectJust "getNonVoidArgFtCodes" . primRepFieldType_maybe $ primRep

getNonVoidArgRepCodes :: [StgArg] -> CodeGen [(PrimRep, Code)]
getNonVoidArgRepCodes [] = return []
getNonVoidArgRepCodes (arg:args)
  | isVoidRep rep = getNonVoidArgRepCodes args
  | otherwise = do
      code <- getArgLoadCode (NonVoid arg)
      repCodes <- getNonVoidArgRepCodes args
      return ((rep, code) : repCodes)
  where rep = argPrimRep arg

idInfoLoadCode :: CgIdInfo -> Code
idInfoLoadCode CgIdInfo { cgLocation } = loadLoc cgLocation

rebindId :: NonVoid Id -> CgLoc -> CodeGen ()
rebindId nvId@(NonVoid id) cgLoc = do
  info <- getCgIdInfo id
  bindId nvId (cgLambdaForm info) cgLoc

bindId :: NonVoid Id -> LambdaFormInfo -> CgLoc -> CodeGen ()
bindId (NonVoid id) lfInfo cgLoc =
  addBinding (mkCgIdInfoWithLoc id lfInfo cgLoc)

bindArg :: NonVoid Id -> CgLoc -> CodeGen ()
bindArg nvid@(NonVoid id) = bindId nvid (mkLFArgument id)

bindArgs :: [(NonVoid Id, CgLoc)] -> CodeGen ()
bindArgs = mapM_ (\(nvId, cgLoc) -> bindArg nvId cgLoc)

rhsIdInfo :: Id -> LambdaFormInfo -> CodeGen (CgIdInfo, CgLoc)
rhsIdInfo id lfInfo = do
  dflags <- getDynFlags
  modClass <- getModClass
  let qualifiedClass = qualifiedName modClass (idNameText dflags id)
  rhsGenIdInfo id lfInfo (obj qualifiedClass)

-- TODO: getJavaInfo generalize to unify rhsIdInfo and rhsConIdInfo
rhsConIdInfo :: Id -> LambdaFormInfo -> CodeGen (CgIdInfo, CgLoc)
rhsConIdInfo id lfInfo@(LFCon dataCon) = do
  dflags <- getDynFlags
  let dataClass = dataConClass dflags dataCon
  rhsGenIdInfo id lfInfo (obj dataClass)

rhsConIdInfo _ _ = error "rhsConIdInfo: bad arguments"

rhsGenIdInfo :: Id -> LambdaFormInfo -> FieldType -> CodeGen (CgIdInfo, CgLoc)
rhsGenIdInfo id lfInfo ft = do
  cgLoc <- newTemp True ft
  return (mkCgIdInfoWithLoc id lfInfo cgLoc, cgLoc)

mkRhsInit :: CgLoc -> Code -> Code
mkRhsInit = storeLoc
