import audit.trio.deposit.LiveBeacon
import audit.trio.deposit.WithdrawalLedger
import LidoSRv3.Audit.Source.TopupBeaconCommitted

/-! Necessary consequences of a successful `LiveBeacon` suffix.

This is intentionally an inversion theorem: it takes the computed result of
the actual suffix, rather than the sufficient premises used to construct one.
It exposes the real withdrawal execution, every actual beacon CALL, the
line-996 router-balance assertion, and the physical callee ledger/count
effects for later P-DEPOSIT-1 composition.
-/
namespace audit.trio.deposit.LiveBeaconCommitted

set_option autoImplicit false

open audit.trio.deposit
open audit.trio.deposit.LiveBeacon
open audit.trio.deposit.RouterDeposit (batchLengthsOk)
open LidoSRv3.Audit.Source
open LidoSRv3.Audit.Source.TrioAlloc1
open LidoSRv3.Audit.Source.TrioReserve1
open LidoSRv3.Audit.Source.TopupBeaconBatch
open LidoSRv3.Audit.Source.TopupBeaconCallee
open LidoSRv3.Audit.Source.TopupBeaconCommitted
open LidoSRv3.Audit.SolidityTopup (allocSum)

structure SuffixCommitment (callee : Live.External) (ctx : RouterDeposit.Context)
    (liveCtx : Live.Context) (credentialsWord : Word) (prepared : PreparedDeposit)
    (before after : Live.World) (trace : List Live.Attempt) where
  withdrawn : Live.World
  withdrawalTrace : List Live.Attempt
  loopTrace : List Live.Attempt
  withdrawal_ok : withdrawal callee liveCtx prepared before = ⟨.ok (), withdrawn, withdrawalTrace⟩
  lengths_ok : batchLengthsOk prepared = .ok ()
  loop_ok : TopupBeaconBatch.loop (routerContext liveCtx ctx) (beaconAddress ctx)
    (keyInputs (encodeWord credentialsWord) prepared prepared.values.actualKeys 0)
    (amounts prepared.values.actualKeys) withdrawn = ⟨.ok (), after, loopTrace⟩
  router_restored : after.balances liveCtx.sender = before.balances liveCtx.sender
  journal : trace = withdrawalTrace ++ loopTrace

/-- The source line-978 early return is a necessary zero-key outcome: no Lido
withdrawal or beacon CALL is available to be mistaken for a zero-value commit.
-/
theorem zero_keys_suffix_no_actual_calls (callee : Live.External) (ctx : RouterDeposit.Context)
    (liveCtx : Live.Context) (credentialsWord : Word) (prepared : PreparedDeposit)
    (before : Live.World) (hkeys : prepared.values.actualKeys = 0) :
    suffix callee ctx liveCtx credentialsWord prepared before = ⟨.ok (), before, []⟩ :=
  zero_keys_no_calls callee ctx liveCtx credentialsWord prepared before hkeys

/-- Any late failure of the root transaction restores the allocation
transcript, the same live ledger/callee state, and metadata together.  Attempts
remain observations only; they are not a substitute for committed effects. -/
theorem execute_failure_restores_root (callee : Live.External) (ctx : RouterDeposit.Context)
    (inputs : RouterDeposit.Inputs) (before after : World) (fault : Fault)
    (attempts : List Live.Attempt)
    (h : execute callee ctx inputs before = ⟨.error fault, after, attempts⟩) :
    after = before :=
  failure_restores callee ctx inputs before after fault attempts h

/-- Connect the public root executor to the suffix consumer.  The authorization
and prefix equations select the executed source branch; the successful result,
not a supplied withdrawal or beacon receipt, then exposes the suffix result in
the very same live world. -/
theorem execute_ok_exposes_actual_suffix (callee : Live.External) (ctx : RouterDeposit.Context)
    (inputs : RouterDeposit.Inputs) (before after : World) (attempts : List Live.Attempt)
    (credentialsWord : Word) (prepared : PreparedDeposit) (transcript : Transcript)
    (hAuth : ctx.caller = ctx.depositSecurityModule) (hActive : ctx.moduleActive = true)
    (hCred : ctx.withdrawalCredentials = some credentialsWord)
    (hPrep : prepareDepositABI inputs.layout inputs.storage inputs.oracle inputs.config
      inputs.requested before.allocationTranscript inputs.moduleId inputs.limits
      inputs.obtainDepositData DEPOSIT_SIZE = (.ok prepared, transcript))
    (h : execute callee ctx inputs before = ⟨.ok (), after, attempts⟩) :
    ∃ live trace,
      suffix callee ctx inputs.liveContext credentialsWord prepared before.live = ⟨.ok (), live, trace⟩ ∧
      after = ⟨transcript, live, recordDeposit ctx prepared before.metadata⟩ ∧ attempts = trace := by
  cases hsuffix : suffix callee ctx inputs.liveContext credentialsWord prepared before.live with
  | mk suffixOutcome live trace =>
    cases suffixOutcome with
    | «error» fault => simp [execute, executeRaw, hAuth, hActive, hCred, hPrep, hsuffix, liftOutcome] at h
    | ok unit =>
      cases unit
      simp only [execute, executeRaw, hAuth, bne_self_eq_false, Bool.false_eq_true, if_false,
        hActive, Bool.not_true, hCred, hPrep, hsuffix, liftOutcome, Result.mk.injEq, true_and] at h
      rcases h with ⟨hafter, hattempts⟩
      exact ⟨live, trace, rfl, hafter.symm, hattempts.symm⟩

/-- Invert a nonempty successful suffix.  In particular, the Lido result and
the callee-loop result below are computed subexecutions, not supplied receipts.
-/
theorem suffix_ok_commitment (callee : Live.External) (ctx : RouterDeposit.Context)
    (liveCtx : Live.Context) (credentialsWord : Word) (prepared : PreparedDeposit)
    (before after : Live.World) (trace : List Live.Attempt)
    (hkeys : prepared.values.actualKeys ≠ 0)
    (h : suffix callee ctx liveCtx credentialsWord prepared before = ⟨.ok (), after, trace⟩) :
    Nonempty (SuffixCommitment callee ctx liveCtx credentialsWord prepared before after trace) := by
  unfold suffix at h
  rw [if_neg hkeys] at h
  cases hwithdrawal : withdrawal callee liveCtx prepared before with
  | mk withdrawalOutcome withdrawn withdrawalTrace =>
    cases withdrawalOutcome with
    | «error» fault => simp [Live.bindExec, hwithdrawal] at h
    | ok unit =>
      cases unit
      cases hlengths : batchLengthsOk prepared with
      | «error» fault => cases fault <;> simp [Live.bindExec, lengthGuard, hwithdrawal, hlengths, Live.fail] at h
      | ok unit =>
        cases unit
        cases hloop : TopupBeaconBatch.loop (routerContext liveCtx ctx) (beaconAddress ctx)
            (keyInputs (encodeWord credentialsWord) prepared prepared.values.actualKeys 0)
            (amounts prepared.values.actualKeys) withdrawn with
        | mk loopOutcome loopWorld loopTrace =>
          cases loopOutcome with
          | «error» fault => simp [Live.bindExec, lengthGuard, beaconLoop, hwithdrawal,
              hlengths, hloop, Live.pureExec] at h
          | ok unit =>
            cases unit
            unfold finish at h
            simp only [Live.bindExec, lengthGuard, Live.pureExec, beaconLoop,
              hwithdrawal, hlengths, hloop, List.append_nil] at h
            split at h
            · simp [Live.fail] at h
            · rename_i hrestored
              simp only [Live.pureExec, Live.Result.mk.injEq, true_and, List.nil_append, List.append_nil] at h
              rcases h with ⟨hworld, hjournal⟩
              subst loopWorld
              exact ⟨⟨withdrawn, withdrawalTrace, loopTrace, hwithdrawal, hlengths,
                hloop, by simpa using hrestored, hjournal.symm⟩⟩

/-- A nonempty successful suffix necessarily performed the accepted beacon
callee loop and therefore has its exact live-ledger and physical-count effects.
The withdrawal is exposed by `SuffixCommitment.withdrawal_ok`; deriving its
ledger delta still requires a necessary-success theorem for the RESERVE-1
executor, not an extra caller receipt. -/
theorem suffix_ok_actual_beacon_effects (callee : Live.External) (ctx : RouterDeposit.Context)
    (liveCtx : Live.Context) (credentialsWord : Word) (prepared : PreparedDeposit)
    (before after : Live.World) (trace : List Live.Attempt)
    (hkeys : prepared.values.actualKeys ≠ 0)
    (h : suffix callee ctx liveCtx credentialsWord prepared before = ⟨.ok (), after, trace⟩) :
    ∃ committed : SuffixCommitment callee ctx liveCtx credentialsWord prepared before after trace,
      CallSpec.Balances committed.withdrawn.balances after.balances
        (routerContext liveCtx ctx).self (beaconAddress ctx)
        (prepared.values.actualKeys * DEPOSIT_SIZE) ∧
      (after.core.readContractSlot (beaconAddress ctx).val countSlot).val =
        (committed.withdrawn.core.readContractSlot (beaconAddress ctx).val countSlot).val +
          prepared.values.actualKeys ∧
      (after.core.readContractSlot (beaconAddress ctx).val countSlot).val ≤ maxCount := by
  obtain ⟨committed⟩ := suffix_ok_commitment callee ctx liveCtx credentialsWord prepared before after trace hkeys h
  refine ⟨committed, ?_, ?_, ?_⟩
  · rw [← allocSum_amounts]
    exact loop_success_balances (routerContext liveCtx ctx) (beaconAddress ctx)
      (keyInputs (encodeWord credentialsWord) prepared prepared.values.actualKeys 0)
      (amounts prepared.values.actualKeys) committed.withdrawn after committed.loopTrace
      committed.loop_ok
  · have hcount := loop_success_count (routerContext liveCtx ctx) (beaconAddress ctx)
      (keyInputs (encodeWord credentialsWord) prepared prepared.values.actualKeys 0)
      (amounts prepared.values.actualKeys) committed.withdrawn after committed.loopTrace
      committed.loop_ok
    simpa only [nonzeroCount_amounts] using hcount.1
  · have hcount := loop_success_count (routerContext liveCtx ctx) (beaconAddress ctx)
      (keyInputs (encodeWord credentialsWord) prepared prepared.values.actualKeys 0)
      (amounts prepared.values.actualKeys) committed.withdrawn after committed.loopTrace
      committed.loop_ok
    apply hcount.2
    rw [nonzeroCount_amounts]
    exact Nat.pos_of_ne_zero hkeys

/-- Public necessary-success consumer for the root `LiveBeacon.execute` path.
It threads the computed root result into the actual callee ledger/count facts;
none of the resulting withdrawal, beacon, or balance effects is caller input. -/
theorem execute_ok_actual_beacon_effects (callee : Live.External) (ctx : RouterDeposit.Context)
    (inputs : RouterDeposit.Inputs) (before after : World) (attempts : List Live.Attempt)
    (credentialsWord : Word) (prepared : PreparedDeposit) (transcript : Transcript)
    (hAuth : ctx.caller = ctx.depositSecurityModule) (hActive : ctx.moduleActive = true)
    (hCred : ctx.withdrawalCredentials = some credentialsWord)
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
        (live.core.readContractSlot (beaconAddress ctx).val countSlot).val ≤ maxCount := by
  obtain ⟨live, trace, hsuffix, hafter, hattempts⟩ :=
    execute_ok_exposes_actual_suffix callee ctx inputs before after attempts credentialsWord prepared
      transcript hAuth hActive hCred hPrep h
  obtain ⟨committed, hbalances, hcount, hcap⟩ :=
    suffix_ok_actual_beacon_effects callee ctx inputs.liveContext credentialsWord prepared before.live
      live trace hkeys hsuffix
  exact ⟨live, trace, hafter, hattempts, committed, hbalances, hcount, hcap⟩

/-- Every successful root run supplies its own authorized, active preparation.
No guard or prepared transcript is supplied by the caller of this theorem. -/
theorem execute_ok_derives_preparation (callee : Live.External)
    (ctx : RouterDeposit.Context) (inputs : RouterDeposit.Inputs)
    (before after : World) (attempts : List Live.Attempt)
    (h : execute callee ctx inputs before = ⟨.ok (), after, attempts⟩) :
    ∃ credentialsWord prepared transcript,
      ctx.caller = ctx.depositSecurityModule ∧ ctx.moduleActive = true ∧
      ctx.withdrawalCredentials = some credentialsWord ∧
      prepareDepositABI inputs.layout inputs.storage inputs.oracle inputs.config
        inputs.requested before.allocationTranscript inputs.moduleId inputs.limits
        inputs.obtainDepositData DEPOSIT_SIZE = (.ok prepared, transcript) := by
  by_cases hAuth : ctx.caller = ctx.depositSecurityModule
  · by_cases hActive : ctx.moduleActive = true
    · cases hCred : ctx.withdrawalCredentials with
      | none => simp [execute, executeRaw, hAuth, hActive, hCred] at h
      | some credentialsWord =>
        generalize hPrep : prepareDepositABI inputs.layout inputs.storage inputs.oracle inputs.config
          inputs.requested before.allocationTranscript inputs.moduleId inputs.limits
          inputs.obtainDepositData DEPOSIT_SIZE = preparedResult at h
        rcases preparedResult with ⟨outcome, transcript⟩
        cases outcome with
        | «error» reason => simp [execute, executeRaw, hAuth, hActive, hCred, hPrep] at h
        | ok prepared => exact ⟨credentialsWord, prepared, transcript, hAuth, hActive, rfl, rfl⟩
    · simp [execute, executeRaw, hAuth, hActive] at h
  · simp [execute, executeRaw, hAuth] at h

/-- Necessary successful-root facts, including the zero-key branch, consumed
from the same execution. The nonzero branch derives actual beacon ledger and
physical count effects without caller funding/capacity/signature premises. -/
theorem execute_ok_derives_actual_effects (callee : Live.External)
    (ctx : RouterDeposit.Context) (inputs : RouterDeposit.Inputs)
    (before after : World) (attempts : List Live.Attempt)
    (h : execute callee ctx inputs before = ⟨.ok (), after, attempts⟩) :
    ∃ credentialsWord prepared transcript live trace,
      prepareDepositABI inputs.layout inputs.storage inputs.oracle inputs.config
        inputs.requested before.allocationTranscript inputs.moduleId inputs.limits
        inputs.obtainDepositData DEPOSIT_SIZE = (.ok prepared, transcript) ∧
      after = ⟨transcript, live, recordDeposit ctx prepared before.metadata⟩ ∧
      attempts = trace ∧
      ((prepared.values.actualKeys = 0 ∧ live = before.live ∧ trace = []) ∨
        (prepared.values.actualKeys ≠ 0 ∧
          ∃ committed : SuffixCommitment callee ctx inputs.liveContext credentialsWord prepared
              before.live live trace,
            CallSpec.Balances committed.withdrawn.balances live.balances
              (routerContext inputs.liveContext ctx).self (beaconAddress ctx)
              (prepared.values.actualKeys * DEPOSIT_SIZE) ∧
            (live.core.readContractSlot (beaconAddress ctx).val countSlot).val =
              (committed.withdrawn.core.readContractSlot (beaconAddress ctx).val countSlot).val +
                prepared.values.actualKeys ∧
            (live.core.readContractSlot (beaconAddress ctx).val countSlot).val ≤ maxCount)) := by
  obtain ⟨credentialsWord, prepared, transcript, hAuth, hActive, hCred, hPrep⟩ :=
    execute_ok_derives_preparation callee ctx inputs before after attempts h
  obtain ⟨live, trace, hsuffix, hafter, htrace⟩ :=
    execute_ok_exposes_actual_suffix callee ctx inputs before after attempts credentialsWord prepared
      transcript hAuth hActive hCred hPrep h
  refine ⟨credentialsWord, prepared, transcript, live, trace, hPrep, hafter, htrace, ?_⟩
  by_cases hz : prepared.values.actualKeys = 0
  · left
    have he := zero_keys_suffix_no_actual_calls callee ctx inputs.liveContext credentialsWord prepared before.live hz
    have hi := Live.Result.mk.inj (hsuffix.symm.trans he)
    exact ⟨hz, hi.2.1, hi.2.2⟩
  · exact Or.inr ⟨hz, suffix_ok_actual_beacon_effects callee ctx inputs.liveContext credentialsWord
      prepared before.live live trace hz hsuffix⟩

/-- The executed root now consumes the necessary Lido ledger theorem and the
actual beacon CALL ledger in one world. Neither funding nor `maxEBType1 = 32
ether` is a premise: a nonempty successful execution and its final router
assertion derive that equality. The existing pipeline configuration binding
and distinct Lido/router/beacon roles remain explicit. -/
theorem execute_pipeline_success_conservation (k : Queue.Keccak) (config : Pipeline.Config)
    (staticOther : StaticCall.External) (other : Live.External)
    (ctx : RouterDeposit.Context) (inputs : RouterDeposit.Inputs)
    (before after : World) (attempts : List Live.Attempt)
    (bound : Pipeline.Bound config inputs.liveContext before.live)
    (lido_ne_router : inputs.liveContext.self ≠ inputs.liveContext.sender)
    (router_ne_beacon : inputs.liveContext.sender ≠ beaconAddress ctx)
    (h : execute (Pipeline.external k config staticOther other) ctx inputs before =
      ⟨.ok (), after, attempts⟩) :
    ∃ prepared transcript,
      prepareDepositABI inputs.layout inputs.storage inputs.oracle inputs.config
        inputs.requested before.allocationTranscript inputs.moduleId inputs.limits
        inputs.obtainDepositData DEPOSIT_SIZE = (.ok prepared, transcript) ∧
      CallSpec.Balances before.live.balances after.live.balances
        inputs.liveContext.self (beaconAddress ctx) (prepared.values.actualKeys * DEPOSIT_SIZE) ∧
      (prepared.values.actualKeys = 0 ∨ inputs.config.maxEBType1.val = DEPOSIT_SIZE) := by
  obtain ⟨credentials, prepared, transcript, live, trace, hprep, hafter, htrace, cases⟩ :=
    execute_ok_derives_actual_effects (Pipeline.external k config staticOther other)
      ctx inputs before after attempts h
  subst after
  refine ⟨prepared, transcript, hprep, ?_⟩
  rcases cases with ⟨hz, hw, ht⟩ | ⟨hn, committed, hbeacon, hcount, hcapacity⟩
  · subst live
    exact ⟨by simp [CallSpec.Balances, hz], Or.inl hz⟩
  · have values := prepareDepositABI_composes_beacon_values inputs.layout inputs.storage inputs.oracle
      inputs.config inputs.requested before.allocationTranscript transcript inputs.moduleId inputs.limits
      inputs.obtainDepositData DEPOSIT_SIZE prepared hprep
    have hword : (Live.word prepared.values.lidoPullWei).val = prepared.values.lidoPullWei :=
      Nat.mod_eq_of_lt values.2.2.2.2.1
    have hw := WithdrawalLedger.pipeline_withdrawal_success_ledger k config staticOther other
      inputs.liveContext (Live.word prepared.values.lidoPullWei) (Live.word prepared.values.actualKeys)
      before.live committed.withdrawn committed.withdrawalTrace bound committed.withdrawal_ok
    rw [hword] at hw
    obtain ⟨hfunds, hledger⟩ := hw
    have hwithdraw := CallFlow.transfer_balances before.live inputs.liveContext.self
      inputs.liveContext.sender prepared.values.lidoPullWei hfunds
    rw [← hledger] at hwithdraw
    have hwr := hwithdraw inputs.liveContext.sender
    have hbr := hbeacon inputs.liveContext.sender
    simp only [routerContext] at hbr
    simp only [Ne.symm lido_ne_router, if_false, ite_true, Nat.add_zero] at hwr
    simp only [router_ne_beacon, if_false, ite_true, Nat.add_zero] at hbr
    have restored := committed.router_restored
    have hamount : prepared.values.lidoPullWei = prepared.values.actualKeys * DEPOSIT_SIZE := by omega
    have hmax : inputs.config.maxEBType1.val = DEPOSIT_SIZE := by
      have hp := values.2.2.2.1.symm.trans hamount
      exact Nat.eq_of_mul_eq_mul_left (Nat.pos_of_ne_zero hn) hp
    refine ⟨?_, Or.inr hmax⟩
    intro account
    have hw := hwithdraw account
    have hb := hbeacon account
    simp only [routerContext] at hb
    rw [hamount] at hw
    dsimp only
    by_cases hl : account = inputs.liveContext.self <;>
      by_cases hr : account = inputs.liveContext.sender <;>
      by_cases hbcn : account = beaconAddress ctx <;>
      simp only [hl, hr, hbcn, if_pos, if_neg] at hw hb ⊢ <;> omega

#print axioms execute_pipeline_success_conservation

#print axioms execute_ok_derives_preparation
#print axioms execute_ok_derives_actual_effects

/-
The new pipeline consumer closes the necessary withdrawal/beacon ledger
connection and derives the 32-ether configured amount on nonempty success.
It does not connect the supplied allocation/module transcript to physical
router storage or repair the metadata/event ordering of LiveBeacon.execute.
Those source obligations and the registered public facade remain open.
-/
end audit.trio.deposit.LiveBeaconCommitted
