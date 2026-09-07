import LidoSRv3.Audit.Source.TrioReserve1.SpendSpec
import LidoSRv3.Audit.Source.TrioReserve1.Tail

namespace LidoSRv3.Audit.Source.TrioReserve1.Spend
open Live

def committed (ctx : Context) (amount : Word) (a : Live.Allocation) (allocated : World)
    (frame : Nat × Nat) (framed : World) : World :=
  Spending.afterFrame ctx amount
    (WithdrawalComposition.adjustedNext ctx (Spending.beforeFrame ctx a amount allocated) frame.1) frame.1 framed

/-- Physical saved-locals/write projection of independent ordered spending rules.
Allocation and current-frame semantics remain explicit stage boundaries. -/
def Describes (external : External) (ctx : Context) (amount : Word) (before : World) :
    Except Fault Unit → World → List Attempt → Prop :=
  SpendSpec.Executes (.reason "NOT_ENOUGH_ETHER") amount.val (fun a : Live.Allocation => a.deposits + a.unreserved)
    (fun a w => Spending.beforeFrame ctx a amount w) (committed ctx amount)
    (fun w outcome after trace => getBufferedEtherAllocation external ctx w = ⟨outcome, after, trace⟩)
    (fun w outcome after trace => getCurrentFrame external ctx w = ⟨outcome, after, trace⟩) before

/-- Exact failed stage world, before the enclosing transaction rolls it back.
Physical allocation bounds rule out intermediate uint256 arithmetic failures. -/
theorem frame_failed (external : External) (ctx : Context) (amount : Word)
    (before allocated failed : World) (a : Live.Allocation) (fault : Fault)
    (left right : List Attempt)
    (ha : getBufferedEtherAllocation external ctx before = ⟨.ok a, allocated, left⟩)
    (hn : amount.val ≤ a.deposits + a.unreserved)
    (hf : getCurrentFrame external ctx (Spending.beforeFrame ctx a amount allocated) = ⟨.error fault, failed, right⟩) :
    spendDepositableEther external ctx amount before = ⟨.error fault, failed, left ++ right⟩ := by
  obtain ⟨htotal, hsum, hword⟩ := Spending.allocation_bounds external ctx before a (by rw [ha])
  have hsmall : amount.val < width := by omega
  have hsub : amount.val ≤ a.total := by omega
  have hpost := (Spending.accounting_add_bound (allocated.core.readContractSlot ctx.self.val bufferSlot)
    amount.val hsmall).1
  have hadjust : getDepositedNextReportAdjusted external ctx (Spending.beforeFrame ctx a amount allocated) =
      ⟨.error fault, failed, right⟩ := by
    simp [getDepositedNextReportAdjusted, Live.read, bind, bindExec, hf]
  simp only [Spending.beforeFrame] at hadjust
  simp [spendDepositableEther, bind, bindExec, ha, hword, hn, Live.read,
    checkedAdd, checkedSub, require, hpost, hsub, pure, pureExec, write, emit, hadjust, List.append_assoc]

theorem of_spec (external : External) (ctx : Context) (amount : Word) (before after : World)
    (outcome : Except Fault Unit) (trace : List Attempt) (h : Describes external ctx amount before outcome after trace) :
    spendDepositableEther external ctx amount before = ⟨outcome, after, trace⟩ := by
  cases h with
  | allocation_error ha => simp [spendDepositableEther, bind, bindExec, ha]
  | insufficient ha hn =>
    have hw := (Spending.allocation_bounds external ctx before _ (by rw [ha])).2.2
    simp [spendDepositableEther, bind, bindExec, ha, hw, require, Nat.not_le.mpr hn, fail]
  | frame_error ha hn hf => exact frame_failed external ctx amount before _ _ _ _ _ _ ha hn hf
  | success ha hn hf =>
    rename_i a allocated framed left right value
    rcases value with ⟨nonce, time⟩
    have hadjust := CallResults.adjusted_frame external ctx _ framed nonce time right hf
    exact Spending.success_world external ctx amount before allocated framed a _ nonce left right ha hn hadjust

theorem exists_spec (external : External) (ctx : Context) (amount : Word) (before : World) :
    ∃ outcome after trace, Describes external ctx amount before outcome after trace := by
  generalize ha : getBufferedEtherAllocation external ctx before = allocationResult
  rcases allocationResult with ⟨allocationOutcome, allocated, left⟩
  cases allocationOutcome with
  | error fault => exact ⟨_, _, _, .allocation_error ha⟩
  | ok a =>
    by_cases hn : amount.val ≤ a.deposits + a.unreserved
    · generalize hf : getCurrentFrame external ctx (Spending.beforeFrame ctx a amount allocated) = frameResult
      rcases frameResult with ⟨frameOutcome, framed, right⟩
      cases frameOutcome with
      | error fault => exact ⟨_, _, _, .frame_error ha hn hf⟩
      | ok value => exact ⟨_, _, _, .success ha hn hf⟩
    · exact ⟨_, _, _, .insufficient ha (by omega)⟩

theorem to_spec (external : External) (ctx : Context) (amount : Word) (before after : World)
    (outcome : Except Fault Unit) (trace : List Attempt)
    (h : spendDepositableEther external ctx amount before = ⟨outcome, after, trace⟩) :
    Describes external ctx amount before outcome after trace := by
  obtain ⟨otherOutcome, otherWorld, otherTrace, hd⟩ := exists_spec external ctx amount before
  have he := of_spec external ctx amount before otherWorld otherOutcome otherTrace hd
  have hi : otherOutcome = outcome ∧ otherWorld = after ∧ otherTrace = trace := by
    simpa only [Result.mk.injEq] using he.symm.trans h
  obtain ⟨rfl, rfl, rfl⟩ := hi
  exact hd

theorem corresponds (external : External) (ctx : Context) (amount : Word) (before after : World)
    (outcome : Except Fault Unit) (trace : List Attempt) :
    Describes external ctx amount before outcome after trace ↔
      spendDepositableEther external ctx amount before = ⟨outcome, after, trace⟩ :=
  ⟨of_spec external ctx amount before after outcome trace, to_spec external ctx amount before after outcome trace⟩

def Withdrawal (external : External) (ctx : Context) (amount seeds : Word) (before : World) :
    Except Fault Unit → World → List Attempt → Prop :=
  WithdrawalSpec.Executes (.reason "CAN_NOT_DEPOSIT") (.reason "APP_AUTH_FAILED") (.reason "ZERO_AMOUNT")
    ctx.sender (amount.val ≠ 0)
    (fun w outcome after trace => Lookup.Status external ctx w outcome after trace)
    (fun w outcome after trace => Lookup.Describes external ctx 0xef6c064c w outcome after trace)
    (fun w outcome after trace => Describes external ctx amount w outcome after trace)
    (fun router w outcome after trace => Tail.Describes external ctx router amount seeds w outcome after trace) before

/-- Complete spending control replaces the parent's final opaque major stage.
Allocation/current-frame and CALL/deployed interpretation remain explicit lower
interfaces; this is not a claim that every primitive binding is discharged. -/
theorem withdrawal_corresponds (external : External) (ctx : Context) (amount seeds : Word)
    (before after : World) (outcome : Except Fault Unit) (trace : List Attempt) :
    Withdrawal external ctx amount seeds before outcome after trace ↔
      run (withdrawDepositableEther external ctx amount seeds) before = ⟨outcome, after, trace⟩ := by
  have he : (fun w outcome after trace => Describes external ctx amount w outcome after trace) =
      (fun w outcome after trace => spendDepositableEther external ctx amount w = ⟨outcome, after, trace⟩) := by
    funext w outcome after trace
    exact propext (corresponds external ctx amount w after outcome trace)
  unfold Withdrawal
  rw [he]
  exact Tail.withdrawal_corresponds external ctx amount seeds before after outcome trace

end LidoSRv3.Audit.Source.TrioReserve1.Spend
