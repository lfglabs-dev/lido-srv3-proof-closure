import LidoSRv3.Audit.Source.TrioReserve1.StatusSpec
import LidoSRv3.Audit.Source.TrioReserve1.WithdrawalParent

namespace LidoSRv3.Audit.Source.TrioReserve1.Status
open Live

/-- Physical/ABI projection of the independent status rules. Lookup and CALL
observations remain explicit source boundaries; no `canDeposit` result is assumed. -/
def Describes (external : External) (ctx : Context) (before : World) :
    Except Fault Bool → World → List Attempt → Prop :=
  StatusSpec.Evaluates .empty List.length (fun data => (word (decode (data.take 32))).val)
    (fun w => (w.core.readContractSlot ctx.self.val activeSlot).val)
    (fun w outcome after trace => withdrawalQueue external ctx w = ⟨outcome, after, trace⟩)
    (fun queue w outcome after trace => call external ctx queue 0x2b95b781 (word 0) w = ⟨outcome, after, trace⟩)
    before

theorem of_spec (external : External) (ctx : Context) (before after : World)
    (outcome : Except Fault Bool) (trace : List Attempt)
    (h : Describes external ctx before outcome after trace) :
    canDeposit external ctx before = ⟨outcome, after, trace⟩ := by
  cases h <;>
    simp_all [canDeposit, decodeWord, bind, bindExec, require, pure, pureExec, fail, Live.read,
      Nat.not_le.mpr]

theorem exists_spec (external : External) (ctx : Context) (before : World) :
    ∃ outcome after trace, Describes external ctx before outcome after trace := by
  generalize hl : withdrawalQueue external ctx before = lookupResult
  rcases lookupResult with ⟨lookupOutcome, found, left⟩
  cases lookupOutcome with
  | error fault => exact ⟨_, _, _, .lookup_error hl⟩
  | ok queue =>
    generalize hc : call external ctx queue 0x2b95b781 (word 0) found = callResult
    rcases callResult with ⟨callOutcome, after, right⟩
    cases callOutcome with
    | error fault => exact ⟨_, _, _, .call_error hl hc⟩
    | ok data =>
      by_cases hn : 32 ≤ data.length
      · by_cases hb : (word (decode (data.take 32))).val = 0
        · by_cases ha : (after.core.readContractSlot ctx.self.val activeSlot).val = 0
          · exact ⟨_, _, _, .paused hl hc hn hb ha⟩
          · exact ⟨_, _, _, .allowed hl hc hn hb ha⟩
        · exact ⟨_, _, _, .bunker hl hc hn hb⟩
      · exact ⟨_, _, _, .malformed hl hc (by omega)⟩

theorem to_spec (external : External) (ctx : Context) (before after : World)
    (outcome : Except Fault Bool) (trace : List Attempt)
    (h : canDeposit external ctx before = ⟨outcome, after, trace⟩) :
    Describes external ctx before outcome after trace := by
  obtain ⟨otherOutcome, otherWorld, otherTrace, hd⟩ := exists_spec external ctx before
  have he := of_spec external ctx before otherWorld otherOutcome otherTrace hd
  have hi : otherOutcome = outcome ∧ otherWorld = after ∧ otherTrace = trace := by
    simpa only [Result.mk.injEq] using he.symm.trans h
  obtain ⟨rfl, rfl, rfl⟩ := hi
  exact hd

theorem corresponds (external : External) (ctx : Context) (before after : World)
    (outcome : Except Fault Bool) (trace : List Attempt) :
    Describes external ctx before outcome after trace ↔ canDeposit external ctx before = ⟨outcome, after, trace⟩ :=
  ⟨of_spec external ctx before after outcome trace, to_spec external ctx before after outcome trace⟩

/-- Independent status denial reaches the parent rollback with its exact trace. -/
theorem withdrawal_denied (external : External) (ctx : Context) (amount seeds : Word)
    (before after : World) (trace : List Attempt) (h : Describes external ctx before (.ok false) after trace) :
    run (withdrawDepositableEther external ctx amount seeds) before =
      ⟨.error (.reason "CAN_NOT_DEPOSIT"), before, trace⟩ :=
  WithdrawalParent.of_spec external ctx amount seeds before before _ trace
    (.status_denied (of_spec external ctx before after (.ok false) trace h))

/-- Every independent status failure propagates through the parent, restoring
all transaction state while preserving the lookup/bunker attempts. -/
theorem withdrawal_failure (external : External) (ctx : Context) (amount seeds : Word)
    (before after : World) (fault : Fault) (trace : List Attempt)
    (h : Describes external ctx before (.error fault) after trace) :
    run (withdrawDepositableEther external ctx amount seeds) before = ⟨.error fault, before, trace⟩ :=
  WithdrawalParent.of_spec external ctx amount seeds before before _ trace
    (.status_error (of_spec external ctx before after (.error fault) trace h))

/-- Parent relation with the status-stage interface replaced by independent
lookup/CALL/ABI/pause rules. Router, spending and tail are still explicit source
stage boundaries awaiting analogous complete substitution. -/
def Withdrawal (external : External) (ctx : Context) (amount seeds : Word) (before : World) :
    Except Fault Unit → World → List Attempt → Prop :=
  WithdrawalSpec.Executes (.reason "CAN_NOT_DEPOSIT") (.reason "APP_AUTH_FAILED") (.reason "ZERO_AMOUNT")
    ctx.sender (amount.val ≠ 0)
    (fun w outcome after trace => Describes external ctx w outcome after trace)
    (fun w outcome after trace => stakingRouter external ctx w = ⟨outcome, after, trace⟩)
    (fun w outcome after trace => spendDepositableEther external ctx amount w = ⟨outcome, after, trace⟩)
    (fun target w outcome after trace => WithdrawalTail.finish external ctx target amount seeds w = ⟨outcome, after, trace⟩)
    before

theorem withdrawal_corresponds (external : External) (ctx : Context) (amount seeds : Word)
    (before after : World) (outcome : Except Fault Unit) (trace : List Attempt) :
    Withdrawal external ctx amount seeds before outcome after trace ↔
      run (withdrawDepositableEther external ctx amount seeds) before = ⟨outcome, after, trace⟩ := by
  have he : (fun w outcome after trace => Describes external ctx w outcome after trace) =
      (fun w outcome after trace => canDeposit external ctx w = ⟨outcome, after, trace⟩) := by
    funext w outcome after trace
    exact propext (corresponds external ctx w after outcome trace)
  unfold Withdrawal
  rw [he]
  exact WithdrawalParent.corresponds external ctx amount seeds before after outcome trace

end LidoSRv3.Audit.Source.TrioReserve1.Status
