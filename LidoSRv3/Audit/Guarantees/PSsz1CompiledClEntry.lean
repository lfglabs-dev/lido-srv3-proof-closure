import LidoSRv3.Audit.Guarantees.PSsz1
import LidoSRv3.Audit.Source.SszCompiledClEntry

/-! Public SSZ-1 consumer of the selected compiled CL entry
(`SszRootCallHarness.verify` → unmodified `_verifyValidator`, selector 0x2e77b4ba).
One execution on the pinned engine's `EVM.State` supplies every operand of the
final proof loop: the root is the first word of the bytes returned by the one
BEACON_ROOTS STATICCALL whose payload was read from machine memory, the index is
the typed `sourceWrapper` of this calldata's slot and validator index on the
constructor words, the leaf is the typed validator tree of the key octets,
decoded fields and calldata word 164, and the siblings are the words the cursor
loop consumed. The earlier compiled-harness theorem
(`actual_memory_validator_branch`, calldata words 68/100 as root/index) and the
typed root-call theorems are unchanged; this is the additional statement whose
index and root are produced, not supplied.

Explicit boundaries: the BEACON_ROOTS callee is the accepted `StaticCall.External`
interpreter on the typed `Live.World` (EIP-4788 history-ring authenticity is not
represented); the immutables are the typed `Configuration`'s `pack` words; SHA is
the opaque engine FFI with the inherited output-width condition; the consumed
proof words are not identified with the entire ABI-declared list; opcode gas and
compiled-bytecode correspondence remain outside. -/
namespace LidoSRv3.Audit.Guarantees.PSsz1
open EvmYul EvmYul.EVM Source Source.SszCompiledClEntry Source.SszWrapperIndex
open Source.TrioReserve1

/-- Whole-entry success derives the executed slot check, the successful root
STATICCALL and its reply guard, the typed generalized index of the executed slot
and validator-index words, the decoded key/field/credential leaf, and the
independent Merkle branch over the consumed proof words from that leaf to the
first word of the returned bytes. No index/root equality, initial memory shape,
intermediate stage success or size premise is assumed. -/
theorem actual_compiled_cl_entry_branch (fuel : Nat) (cfg : Configuration)
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
      afterState.executionEnv = context.executionEnv :=
  SszCompiledClEntry.run_success fuel cfg external world context afterState h hffi

/-- The same execution in the typed digest vocabulary of the root-call theorems:
an independently constructed SSZ validator container of this entry's key octets,
fields and credentials, authenticated under the typed index against the typed
`firstWord` of the same returned bytes, over the same consumed proof words. -/
theorem actual_compiled_cl_entry_tree (fuel : Nat) (cfg : Configuration)
    (external : StaticCall.External) (world : Live.World) (context afterState : EVM.State)
    (h : (SszCompiledClEntry.run fuel cfg external world context).outcome = .ok afterState)
    (hffi : SszProofCommitted.ShaWidth) :
    ∃ head branch slot data gi keySlice f,
      SszCompiledClEntry.header context = .ok head ∧
      SszWitnessAbi.tail context head (UInt256.ofNat 4) 32 = .ok branch ∧
      SszWitnessAbi.read64 context (UInt256.ofNat 36) = .ok slot ∧
      (SszRootCall.call external (callerOf context)
        (BitVec.ofNat 64 (context.calldataload (UInt256.ofNat 4)).toNat) world).outcome = .ok data ∧
      32 ≤ data.length ∧
      sourceWrapper cfg slot.toFin
        ⟨(context.calldataload (UInt256.ofNat 132)).toNat,
          (context.calldataload (UInt256.ofNat 132)).val.isLt⟩ = .ok gi ∧
      SszWitnessAbi.tail context head (UInt256.ofNat 36) 1 = .ok keySlice ∧ keySlice.length = 48 ∧
      SszWitnessAbi.FieldsMatch context head f ∧
      SszProofFold.Branch (fun a b => some (SszValidatorLeaf.pair SszTypedFfiBridge.ffiSha a b))
        gi.index.val
        (treeDigest (SszValidatorLeaf.pair SszTypedFfiBridge.ffiSha)
          (SszValidatorLeaf.validatorTree SszTypedFfiBridge.ffiSha
            (SszPubkeyBytes.witnessAt context keySlice.offset f)
            (SszTypedFfiBridge.toDigest (context.calldataload (UInt256.ofNat 164)))))
        ((SszProofCommitted.proofWords branch.length context.executionEnv.calldata branch.offset
          (SszProofCommitted.endOffset branch.offset branch.length)).map SszTypedFfiBridge.toDigest)
        (SszVerifierEntry.firstWord (SszRootCall.fromBytes data)) := by
  obtain ⟨head, branch, slot, _, data, gi, keySlice, f, hh, hb, hs, _, _, _, _, _, hcall, _, _,
    hlen, _, hgi, hks, hk48, fm, _, hbranch, _⟩ :=
    actual_compiled_cl_entry_branch fuel cfg external world context afterState h hffi
  refine ⟨head, branch, slot, data, gi, keySlice, f, hh, hb, hs, hcall, hlen, hgi, hks, hk48, fm, ?_⟩
  have hmap : SszProofCommitted.proofWords branch.length context.executionEnv.calldata branch.offset
      (SszProofCommitted.endOffset branch.offset branch.length) =
      ((SszProofCommitted.proofWords branch.length context.executionEnv.calldata branch.offset
        (SszProofCommitted.endOffset branch.offset branch.length)).map SszTypedFfiBridge.toDigest).map
        SszTypedFfiBridge.toWord := by
    rw [List.map_map]
    exact (List.map_id'' (fun _ => rfl) _).symm
  rw [hmap] at hbranch
  exact (SszTypedFfiBridge.branch_transport _ _ _ _).mp hbranch

#print axioms actual_compiled_cl_entry_branch
#print axioms actual_compiled_cl_entry_tree
end LidoSRv3.Audit.Guarantees.PSsz1
