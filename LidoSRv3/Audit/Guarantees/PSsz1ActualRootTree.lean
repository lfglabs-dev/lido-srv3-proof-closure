import LidoSRv3.Audit.Guarantees.PSsz1RootCall
import LidoSRv3.Audit.Source.SszActualLeafTree

namespace LidoSRv3.Audit.Guarantees.PSsz1
open Source Source.SszRootCall Source.SszVerifierEntry Source.SszValidatorLeaf
open Source.SszActualLeafTree Source.SszWrapperIndex Source.TrioReserve1

/-- The actual returned EIP4788 root binds an independently constructed SSZ
validator container, with exactly the semantic fields and byte encodings of
this typed entry. Hash outputs come from the same interpreted calls; no global
SHA-success/width or precomputed-leaf premise is introduced. This result keeps
the existing typed-entry boundary and does not assert compiled ABI linkage. -/
theorem actual_root_staticcall_validator_tree
    (precompile : Precompile) (external : StaticCall.External)
    (caller : Live.Address) (input : Input) (world : Live.World)
    (h : (SszRootCall.run precompile external caller input world).outcome = .ok ()) :
    input.witness.pubkey.length = 48 ∧
    ∃ data gi,
      (SszRootCall.call external caller input.beacon.childBlockTimestamp world).outcome = .ok data ∧
      32 ≤ data.length ∧
      sourceWrapper input.cfg input.beacon.slot.toFin input.offset = .ok gi ∧
      input.proof ≠ [] ∧
      SszProofFold.Branch (fun a b => some (pair (outputSha precompile) a b)) gi.index.val
        (treeDigest (pair (outputSha precompile))
          (validatorTree (outputSha precompile) input.witness input.credentials))
        input.proof (firstWord (fromBytes data)) ∧
      (SszRootCall.run precompile external caller input world).attempts =
        [⟨request caller input.beacon.childBlockTimestamp,true,true,data,1⟩] ∧
      (SszRootCall.run precompile external caller input world).world = world := by
  obtain ⟨_,_,_,_,_,data,gi,leaf,hcall,_,_,hdata,hgi,hleaf,hproof,hbranch,hattempts,hworld⟩ :=
    actual_root_staticcall_validator_branch precompile external caller input world h
  obtain ⟨hlen,htree⟩ := leaf_success_tree precompile input.scratch input.witness
    input.credentials leaf hleaf
  refine ⟨hlen,data,gi,hcall,hdata,hgi,hproof,?_,hattempts,hworld⟩
  rw [htree]
  exact branch_output_tree precompile gi.index.val leaf _ input.proof hbranch

#print axioms actual_root_staticcall_validator_tree
end LidoSRv3.Audit.Guarantees.PSsz1
