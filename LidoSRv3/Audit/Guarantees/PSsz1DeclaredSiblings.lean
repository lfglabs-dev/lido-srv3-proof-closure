import LidoSRv3.Audit.Source.SszDeclaredSiblings
/-! Same actual compiled330 success and inherited ShaWidth, now authenticating
all ABI-declared indexed siblings. The complete prior public consequence is
retained before the added conjunction; no new fit/frame/canonicality premise. -/
set_option autoImplicit false
namespace LidoSRv3.Audit.Guarantees.PSsz1
open EvmYul EvmYul.EVM Source Source.SszCompiledClEntry Source.SszWrapperIndex
open Source.TrioReserve1

theorem actual_compiled_cl_entry_complete_declared_branch (fuel : Nat) (cfg : Configuration)
    (external : StaticCall.External) (world : Live.World) (context afterState : EVM.State)
    (h : (SszCompiledClEntry.run fuel cfg external world context).outcome = .ok afterState)
    (hffi : SszProofCommitted.ShaWidth) :
    ∃ head branch slot proposer data gi keySlice f,
      SszCompiledClEntry.header context = .ok head ∧
      SszWitnessAbi.tail context head (UInt256.ofNat 4) 32 = .ok branch ∧
      SszWitnessAbi.read64 context (UInt256.ofNat 36) = .ok slot ∧
      SszWitnessAbi.read64 context (UInt256.ofNat 68) = .ok proposer ∧
      2 ≤ branch.length ∧ branch.length ≤ 2 ^ 64 - 1 ∧
      context.calldataload (branch.offset + UInt256.ofNat ((branch.length - 2) * 32)) =
        SszBlsComposition.pairDigest (SszBlsComposition.chunk slot) (SszBlsComposition.chunk proposer) ∧
      SszWitnessAbi.read64 context (UInt256.ofNat 4) =
        .ok (BitVec.ofNat 64 (context.calldataload (UInt256.ofNat 4)).toNat) ∧
      (SszRootCall.call external (callerOf context)
        (BitVec.ofNat 64 (context.calldataload (UInt256.ofNat 4)).toNat) world).outcome = .ok data ∧
      (world.core.codeSize SszRootCall.target.val).val ≠ 0 ∧
      external (SszRootCall.request (callerOf context)
        (BitVec.ofNat 64 (context.calldataload (UInt256.ofNat 4)).toNat)) world = .success data ∧
      32 ≤ data.length ∧
      (SszCompiledClEntry.run fuel cfg external world context).attempts =
        [⟨SszRootCall.request (callerOf context)
          (BitVec.ofNat 64 (context.calldataload (UInt256.ofNat 4)).toNat), true, true, data, 1⟩] ∧
      sourceWrapper cfg slot.toFin
        ⟨(context.calldataload (UInt256.ofNat 132)).toNat,
          (context.calldataload (UInt256.ofNat 132)).val.isLt⟩ = .ok gi ∧
      SszWitnessAbi.tail context head (UInt256.ofNat 36) 1 = .ok keySlice ∧ keySlice.length = 48 ∧
      SszWitnessAbi.FieldsMatch context head f ∧
      SszProofCommitted.proofWords branch.length context.executionEnv.calldata branch.offset
        (SszProofCommitted.endOffset branch.offset branch.length) ≠ [] ∧
      SszProofFold.Branch SszProofCalldataStep.ffiPair gi.index.val
        (validatorLeaf context keySlice.offset f)
        (SszProofCommitted.proofWords branch.length context.executionEnv.calldata branch.offset
          (SszProofCommitted.endOffset branch.offset branch.length))
        (SszTypedFfiBridge.toWord (SszVerifierEntry.firstWord (SszRootCall.fromBytes data))) ∧
      afterState.executionEnv = context.executionEnv ∧
      SszProofCommitted.proofWords branch.length context.executionEnv.calldata branch.offset
        (SszProofCommitted.endOffset branch.offset branch.length) =
        SszDeclaredSiblings.declaredWords context.executionEnv.calldata branch.offset branch.length ∧
      (SszDeclaredSiblings.declaredWords context.executionEnv.calldata branch.offset branch.length).length = branch.length ∧
      branch.length = gi.index.val.log2 ∧ 3 ≤ branch.length ∧ branch.length ≤ 247 ∧
      (SszDeclaredSiblings.declaredWords context.executionEnv.calldata branch.offset branch.length)[branch.length-2]? =
        some (SszBlsComposition.pairDigest (SszBlsComposition.chunk slot) (SszBlsComposition.chunk proposer)) ∧
      SszProofFold.Branch SszProofCalldataStep.ffiPair gi.index.val
        (validatorLeaf context keySlice.offset f)
        (SszDeclaredSiblings.declaredWords context.executionEnv.calldata branch.offset branch.length)
        (SszTypedFfiBridge.toWord (SszVerifierEntry.firstWord (SszRootCall.fromBytes data))) ∧
      SszProofFold.Branch (fun a b => some (SszValidatorLeaf.pair SszTypedFfiBridge.ffiSha a b))
        gi.index.val
        (treeDigest (SszValidatorLeaf.pair SszTypedFfiBridge.ffiSha)
          (SszValidatorLeaf.validatorTree SszTypedFfiBridge.ffiSha
            (SszPubkeyBytes.witnessAt context keySlice.offset f)
            (SszTypedFfiBridge.toDigest (context.calldataload (UInt256.ofNat 164)))))
        ((SszDeclaredSiblings.declaredWords context.executionEnv.calldata branch.offset branch.length).map SszTypedFfiBridge.toDigest)
        (SszVerifierEntry.firstWord (SszRootCall.fromBytes data)) := by
  obtain ⟨head,branch,slot,proposer,data,gi,keySlice,f,hh,hb,hs,hp,hn,h64,hpen,htime,
    hcall,hcode,hext,hlen,htrace,hgi,hks,h48,hfields,hne,hbranch,henv⟩ :=
    actual_compiled_cl_entry_branch fuel cfg external world context afterState h hffi
  obtain ⟨hfull,hdepth,hmin,hmax⟩ := SszDeclaredSiblings.complete_of_branch
    context.executionEnv.calldata branch.offset branch.length cfg slot.toFin _ gi _ _ hn h64 hgi hbranch
  have hdeclared := hbranch
  rw [hfull] at hdeclared
  refine ⟨head,branch,slot,proposer,data,gi,keySlice,f,hh,hb,hs,hp,hn,h64,hpen,htime,
    hcall,hcode,hext,hlen,htrace,hgi,hks,h48,hfields,hne,hbranch,henv,hfull,
    SszDeclaredSiblings.declared_length _ _ _,hdepth,hmin,hmax,
    SszDeclaredSiblings.penultimate context branch.offset branch.length _ hn hpen,hdeclared,?_⟩
  have hmap : SszDeclaredSiblings.declaredWords context.executionEnv.calldata branch.offset branch.length =
      ((SszDeclaredSiblings.declaredWords context.executionEnv.calldata branch.offset branch.length).map SszTypedFfiBridge.toDigest).map
        SszTypedFfiBridge.toWord := by
    rw [List.map_map]
    exact (List.map_id'' (fun _ => rfl) _).symm
  rw [hmap] at hdeclared
  exact (SszTypedFfiBridge.branch_transport _ _ _ _).mp hdeclared

#print axioms actual_compiled_cl_entry_complete_declared_branch
end LidoSRv3.Audit.Guarantees.PSsz1
