import audit.trio.deposit.LiveBeaconCommitted

/-! Consumer-shaped check for necessary live-beacon suffix effects.

Unlike the historical positive fixture, this test starts with a computed
successful suffix and projects the actual callee's ledger and slot-32 effects.
It intentionally supplies no funding, signature, seed, capacity, or
`maxEBType1 = DEPOSIT_SIZE` premise.
-/
namespace audit.trio.deposit.Tests.Verity.LiveBeaconCommitted

set_option autoImplicit false

open audit.trio.deposit
open audit.trio.deposit.LiveBeacon
open audit.trio.deposit.LiveBeaconCommitted
open LidoSRv3.Audit.Source
open LidoSRv3.Audit.Source.TrioAlloc1
open LidoSRv3.Audit.Source.TrioReserve1
open LidoSRv3.Audit.Source.TopupBeaconCallee

/-- The zero-key branch remains an observed no-call return, rather than an
empty artificial beacon receipt. -/
theorem zero_key_suffix_has_no_effects (callee : Live.External)
    (ctx : RouterDeposit.Context) (liveCtx : Live.Context) (credentialsWord : Word)
    (prepared : PreparedDeposit) (before : Live.World)
    (hkeys : prepared.values.actualKeys = 0) :
    suffix callee ctx liveCtx credentialsWord prepared before = ⟨.ok (), before, []⟩ :=
  zero_keys_suffix_no_actual_calls callee ctx liveCtx credentialsWord prepared before hkeys

/-- The late-failure public consumer retains root rollback over the full live
world, so an accepted earlier callee effect cannot escape the wrapper. -/
theorem late_failure_restores_full_root (callee : Live.External) (ctx : RouterDeposit.Context)
    (inputs : RouterDeposit.Inputs) (before after : World) (fault : Fault)
    (attempts : List Live.Attempt)
    (h : execute callee ctx inputs before = ⟨.error fault, after, attempts⟩) :
    after = before :=
  execute_failure_restores_root callee ctx inputs before after fault attempts h

/-- Root-executor form of the planned P-DEPOSIT-1 necessary-success consumer.
The root result, not a separately asserted suffix receipt, is its input. -/
theorem successful_execute_exposes_actual_callee (callee : Live.External)
    (ctx : RouterDeposit.Context) (inputs : RouterDeposit.Inputs) (before after : World)
    (attempts : List Live.Attempt) (credentialsWord : Word) (prepared : PreparedDeposit)
    (transcript : Transcript) (hAuth : ctx.caller = ctx.depositSecurityModule)
    (hActive : ctx.moduleActive = true) (hCred : ctx.withdrawalCredentials = some credentialsWord)
    (hPrep : prepareDepositABI inputs.layout inputs.storage inputs.oracle inputs.config
      inputs.requested before.allocationTranscript inputs.moduleId inputs.limits
      inputs.obtainDepositData DEPOSIT_SIZE = (.ok prepared, transcript))
    (hkeys : prepared.values.actualKeys ≠ 0)
    (h : execute callee ctx inputs before = ⟨.ok (), after, attempts⟩) :
    ∃ live trace,
      after = ⟨transcript, live, recordDeposit ctx prepared before.metadata⟩ ∧ attempts = trace ∧
      ∃ committed : SuffixCommitment callee ctx inputs.liveContext credentialsWord prepared
          before.live live trace,
        CallSpec.Balances committed.withdrawn.balances live.balances
          (routerContext inputs.liveContext ctx).self (beaconAddress ctx)
          (prepared.values.actualKeys * DEPOSIT_SIZE) ∧
        (live.core.readContractSlot (beaconAddress ctx).val countSlot).val =
          (committed.withdrawn.core.readContractSlot (beaconAddress ctx).val countSlot).val +
            prepared.values.actualKeys ∧
        (live.core.readContractSlot (beaconAddress ctx).val countSlot).val ≤ maxCount :=
  execute_ok_actual_beacon_effects callee ctx inputs before after attempts credentialsWord prepared
    transcript hAuth hActive hCred hPrep hkeys h

/-- Shape required by the planned P-DEPOSIT-1 consumers: effects of actual
successful execution, rather than a Boolean beacon acceptance or auxiliary
balance counter. -/
theorem successful_suffix_exposes_actual_callee (callee : Live.External)
    (ctx : RouterDeposit.Context) (liveCtx : Live.Context) (credentialsWord : Word)
    (prepared : PreparedDeposit) (before after : Live.World) (trace : List Live.Attempt)
    (hkeys : prepared.values.actualKeys ≠ 0)
    (h : suffix callee ctx liveCtx credentialsWord prepared before = ⟨.ok (), after, trace⟩) :
    ∃ committed : SuffixCommitment callee ctx liveCtx credentialsWord prepared before after trace,
      CallSpec.Balances committed.withdrawn.balances after.balances
        (routerContext liveCtx ctx).self (beaconAddress ctx)
        (prepared.values.actualKeys * DEPOSIT_SIZE) ∧
      (after.core.readContractSlot (beaconAddress ctx).val countSlot).val =
        (committed.withdrawn.core.readContractSlot (beaconAddress ctx).val countSlot).val +
          prepared.values.actualKeys ∧
      (after.core.readContractSlot (beaconAddress ctx).val countSlot).val ≤ maxCount :=
  suffix_ok_actual_beacon_effects callee ctx liveCtx credentialsWord prepared before after trace hkeys h

#print axioms successful_suffix_exposes_actual_callee
#print axioms zero_key_suffix_has_no_effects
#print axioms late_failure_restores_full_root
#print axioms successful_execute_exposes_actual_callee

end audit.trio.deposit.Tests.Verity.LiveBeaconCommitted
