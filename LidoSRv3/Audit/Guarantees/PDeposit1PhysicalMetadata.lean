import audit.trio.deposit.PhysicalMetadata

namespace LidoSRv3.Audit.Guarantees.PDeposit1
open audit.trio.deposit audit.trio.deposit.PhysicalMetadata
open LidoSRv3.Audit.Source LidoSRv3.Audit.Source.TrioReserve1
open TopupRouterCredentials (Keccak)

/-- The computed preparation updates the physical module word and source event
before the actual withdrawal/beacon continuation. The prefix world is consumed
by that continuation, including the zero-key case. This does not replace the
open allocation/module CALL or deployment/configuration composition. -/
theorem actual_physical_metadata_before_calls (hash : Keccak) (callee : Live.External) (ctx : RouterDeposit.Context)
    (inputs : RouterDeposit.Inputs) (before after : World) (attempts : List Live.Attempt)
    (h : execute hash callee ctx inputs before = ⟨.ok (),after,attempts⟩) :
    ∃ credentials prepared transcript,
      prepareDepositABI inputs.layout inputs.storage inputs.oracle inputs.config
        inputs.requested before.allocationTranscript inputs.moduleId inputs.limits
        inputs.obtainDepositData DEPOSIT_SIZE = (.ok prepared,transcript) ∧
      after.allocationTranscript = transcript ∧
      let updated := update hash ctx inputs.liveContext.sender prepared before.live
      let key := moduleDepositSlot hash prepared.moduleId
      let packed := (updated.core.readContractSlot inputs.liveContext.sender.val key).val
      (packed % 2^64 = before.live.core.blockTimestamp.val % 2^64 ∧
       packed / 2^64 % 2^64 = before.live.core.blockNumber.val % 2^64 ∧
       packed / 2^128 = (before.live.core.readContractSlot inputs.liveContext.sender.val key).val / 2^128) ∧
      updated.balances = before.live.balances ∧
      updated.logs = before.live.logs ++ [routerEvent inputs.liveContext.sender prepared] ∧
      ((prepared.values.actualKeys = 0 ∧ after.live = updated ∧ attempts = []) ∨
       (prepared.values.actualKeys ≠ 0 ∧ Nonempty
         (LiveBeaconCommitted.SuffixCommitment callee ctx inputs.liveContext credentials prepared
           updated after.live attempts))) :=
  PhysicalMetadata.success_effects hash callee ctx inputs before after attempts h

/-- A failing execution restores this physical metadata together with the
whole live world, using the existing declared root rollback semantics. -/
theorem actual_physical_metadata_failure_restores (hash : Keccak) (callee : Live.External) (ctx : RouterDeposit.Context)
    (inputs : RouterDeposit.Inputs) (before after : World) (fault : LiveBeacon.Fault)
    (attempts : List Live.Attempt)
    (h : execute hash callee ctx inputs before = ⟨.error fault,after,attempts⟩) :
    after = before :=
  PhysicalMetadata.failure_restores hash callee ctx inputs before after fault attempts h

#print axioms actual_physical_metadata_before_calls
#print axioms actual_physical_metadata_failure_restores
end LidoSRv3.Audit.Guarantees.PDeposit1
