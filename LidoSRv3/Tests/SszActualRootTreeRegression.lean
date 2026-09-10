import LidoSRv3.Audit.Guarantees.PSsz1ActualRootTree

namespace LidoSRv3.Tests.SszActualRootTreeRegression
open Audit.Source Audit.Source.SszRootCall Audit.Source.SszVerifierEntry
open Audit.Source.SszValidatorLeaf Audit.Source.SszWrapperIndex Audit.Source.TrioReserve1
open Audit.Source.SszActualLeafTree
set_option maxRecDepth 4096
set_option maxHeartbeats 4000000

private def partialSha : Precompile := fun bytes =>
  if bytes.length = 64 then ⟨true,32,0⟩ else ⟨false,0,17⟩
private def input : Input := {
  scratch := fun _ => 255
  cfg := pinnedConfiguration ⟨0,by decide⟩
  beacon := ⟨0x0102030405060708,0,0⟩
  witness := ⟨List.replicate 48 0,0,false,0,0,0,0⟩
  proof := List.replicate 50 0
  offset := ⟨0,by decide⟩
  credentials := 0 }
private def caller : Live.Address := ⟨17,by decide⟩
private def world : Live.World :=
  ⟨{Verity.defaultState with codeSize := fun _ => Live.word 1},fun _ => 0,[]⟩
private def external : StaticCall.External := fun _ _ => .success (List.replicate 32 0)

/-- The complete typed entry succeeds although the SHA interpretation is not
globally successful and does not globally return 32 bytes. -/
theorem partial_entry_succeeds :
    (SszRootCall.run partialSha external caller input world).outcome = .ok () ∧
    (partialSha []).success = false ∧ (partialSha []).returndataSize = 0 := by
  decide +kernel

/-- Consume the universal result on that actual execution; no successful-SHA
adapter is inserted between its root reply and independent tree. -/
theorem partial_entry_has_tree :
    ∃ data gi,
      (SszRootCall.call external caller input.beacon.childBlockTimestamp world).outcome = .ok data ∧
      32 ≤ data.length ∧
      sourceWrapper input.cfg input.beacon.slot.toFin input.offset = .ok gi ∧
      input.proof ≠ [] ∧
      SszProofFold.Branch (fun a b => some (pair (outputSha partialSha) a b)) gi.index.val
        (treeDigest (pair (outputSha partialSha))
          (validatorTree (outputSha partialSha) input.witness input.credentials))
        input.proof (firstWord (fromBytes data)) ∧
      (SszRootCall.run partialSha external caller input world).attempts =
        [⟨request caller input.beacon.childBlockTimestamp,true,true,data,1⟩] ∧
      (SszRootCall.run partialSha external caller input world).world = world :=
  (Audit.Guarantees.PSsz1.actual_root_staticcall_validator_tree
    partialSha external caller input world partial_entry_succeeds.1).2

#print axioms partial_entry_succeeds
#print axioms partial_entry_has_tree
end LidoSRv3.Tests.SszActualRootTreeRegression
