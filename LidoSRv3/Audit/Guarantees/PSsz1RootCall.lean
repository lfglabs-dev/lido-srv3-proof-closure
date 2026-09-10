import LidoSRv3.Audit.Source.SszRootCall

/-! Additional typed CL source-entry consumer. The physical-world low-level
STATICCALL executes after slot checking and supplies the root used by the
subsequent validator branch. The compiled SSZ memory/ABI bridge stays separate. -/
namespace LidoSRv3.Audit.Guarantees.PSsz1
open Source Source.SszRootCall Source.SszVerifierEntry Source.SszValidatorLeaf
open Source.SszWrapperIndex Source.TrioReserve1

/-- Whole-entry success derives the real static request, successful returned
bytes and their guard, and an independent branch against the decoded root.
There is no supplied RootOracle, root correctness or intermediate-success premise. -/
theorem actual_root_staticcall_validator_branch
    (precompile : Precompile) (external : StaticCall.External)
    (caller : Live.Address) (input : Input) (world : Live.World)
    (h : (SszRootCall.run precompile external caller input world).outcome = .ok ()) :
    (request caller input.beacon.childBlockTimestamp).target.val =
      0x000F3df6D732807Ef1319fB7B8bB8522d0Beac02 ∧
    (request caller input.beacon.childBlockTimestamp).value = Live.word 0 ∧
    (request caller input.beacon.childBlockTimestamp).payload =
      toBytes (digestBytes (input.beacon.childBlockTimestamp.zeroExtend 256)) ∧
    (request caller input.beacon.childBlockTimestamp).payload.length = 32 ∧
    sourceSlot precompile input.proof input.beacon.slot input.beacon.proposerIndex = .ok () ∧
    ∃ data gi leaf,
      (SszRootCall.call external caller input.beacon.childBlockTimestamp world).outcome = .ok data ∧
      (world.core.codeSize target.val).val ≠ 0 ∧
      external (request caller input.beacon.childBlockTimestamp) world = .success data ∧
      32 ≤ data.length ∧
      sourceWrapper input.cfg input.beacon.slot.toFin input.offset = .ok gi ∧
      sourceLeaf precompile input.scratch input.witness input.credentials = .ok leaf ∧
      input.proof ≠ [] ∧
      SszProofFold.Branch (foldHash precompile) gi.index.val leaf input.proof
        (firstWord (fromBytes data)) ∧
      (SszRootCall.run precompile external caller input world).attempts =
        [⟨request caller input.beacon.childBlockTimestamp,true,true,data,1⟩] ∧
      (SszRootCall.run precompile external caller input world).world = world := by
  obtain ⟨ht,hv,hp,hn⟩ := request_shape caller input.beacon.childBlockTimestamp
  exact ⟨ht,hv,hp,hn,run_success precompile external caller input world h⟩

#print axioms actual_root_staticcall_validator_branch
end LidoSRv3.Audit.Guarantees.PSsz1
