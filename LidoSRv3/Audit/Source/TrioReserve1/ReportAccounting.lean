import LidoSRv3.Audit.Source.TrioReserve1.ReportAccountingSpec
import LidoSRv3.Audit.Source.TrioReserve1.Report

namespace LidoSRv3.Audit.Source.TrioReserve1.ReportAccounting
open Live

def buffer (ctx : Context) (before : World) : Nat :=
  (before.core.readContractSlot ctx.self.val bufferSlot).val % width

/-- Pure physical post-state projection: low128 buffer narrowing, preservation
of the packed companion, then conditional reserve increase and ordered events. -/
def committed (ctx : Context) (input : Report.Inputs) (before : World) (post : Nat) : World :=
  let packed := before.core.readContractSlot ctx.self.val bufferSlot
  let target := before.core.readContractSlot ctx.self.val targetSlot
  let reserve := before.core.readContractSlot ctx.self.val reserveSlot
  let written := {before with core := before.core.writeContractSlot ctx.self.val bufferSlot (pack post (packed.val / width))}
  let rebalanced := if reserve.val < target.val then
    {written with
      core := written.core.writeContractSlot ctx.self.val reserveSlot target
      logs := written.logs ++ [⟨ctx.self, "DepositsReserveSet", [target]⟩]}
    else written
  {rebalanced with logs := rebalanced.logs ++ [⟨ctx.self, "ETHDistributed",
    [input.timestamp, input.principal, input.clBalance, input.withdrawals, input.rewards, word post]⟩]}

def result (ctx : Context) (input : Report.Inputs) (before : World) : ReportAccountingSpec.Outcome → Result Unit
  | .rewards_overflow => ⟨.error (.reason "MATH_ADD_OVERFLOW"), before, []⟩
  | .withdrawals_overflow => ⟨.error (.reason "MATH_ADD_OVERFLOW"), before, []⟩
  | .underflow => ⟨.error (.reason "MATH_SUB_UNDERFLOW"), before, []⟩
  | .value post => ⟨.ok (), committed ctx input before post, []⟩

def Describes (ctx : Context) (input : Report.Inputs) (before : World) (observed : Result Unit) : Prop :=
  ∃ outcome, ReportAccountingSpec.Computes Verity.Core.UINT256_MODULUS (buffer ctx before)
    input.rewards.val input.withdrawals.val input.lockAmount.val outcome ∧ observed = result ctx input before outcome

private theorem add_ok (a b : Nat) (h : a + b < Verity.Core.UINT256_MODULUS) :
    checkedAdd a b = pureExec (a + b) := by
  funext w
  simp [checkedAdd, require, h, bind, bindExec, pure, pureExec]

private theorem add_error (a b : Nat) (h : ¬a + b < Verity.Core.UINT256_MODULUS) :
    checkedAdd a b = fail (.reason "MATH_ADD_OVERFLOW") := by
  funext w
  simp [checkedAdd, require, h, bind, bindExec, fail]

private theorem sub_ok (a b : Nat) (h : b ≤ a) : checkedSub a b = pureExec (a - b) := by
  funext w
  simp [checkedSub, require, h, bind, bindExec, pure, pureExec]

private theorem sub_error (a b : Nat) (h : ¬b ≤ a) : checkedSub a b = fail (.reason "MATH_SUB_UNDERFLOW") := by
  funext w
  simp [checkedSub, require, h, bind, bindExec, fail]

theorem of_spec (ctx : Context) (input : Report.Inputs) (before : World) (outcome : ReportAccountingSpec.Outcome)
    (h : ReportAccountingSpec.Computes Verity.Core.UINT256_MODULUS (buffer ctx before)
      input.rewards.val input.withdrawals.val input.lockAmount.val outcome) :
    Report.afterCalls ctx input before = result ctx input before outcome := by
  simp only [buffer] at h
  cases h with
  | rewards_overflow hr =>
    have hn : ¬(before.core.readContractSlot ctx.self.val bufferSlot).val % width + input.rewards.val <
        Verity.Core.UINT256_MODULUS := by omega
    simp [Report.afterCalls, Live.read, bind, bindExec, add_error _ _ hn, fail, result]
  | withdrawals_overflow hr hw =>
    have hn : ¬(before.core.readContractSlot ctx.self.val bufferSlot).val % width + input.rewards.val +
        input.withdrawals.val < Verity.Core.UINT256_MODULUS := by omega
    simp [Report.afterCalls, Live.read, bind, bindExec, add_ok _ _ hr, add_error _ _ hn, pureExec, fail, result]
  | underflow hr hw hl =>
    have hn : ¬input.lockAmount.val ≤ (before.core.readContractSlot ctx.self.val bufferSlot).val % width +
        input.rewards.val + input.withdrawals.val := by omega
    simp [Report.afterCalls, Live.read, bind, bindExec, add_ok _ _ hr, add_ok _ _ hw,
      sub_error _ _ hn, pureExec, fail, result]
  | value hr hw hl =>
    have hbt : targetSlot ≠ bufferSlot := by decide
    have hbr : reserveSlot ≠ bufferSlot := by decide
    by_cases hreserve : (before.core.readContractSlot ctx.self.val reserveSlot).val <
        (before.core.readContractSlot ctx.self.val targetSlot).val
    all_goals simp [Report.afterCalls, Live.read, bind, bindExec, add_ok _ _ hr, add_ok _ _ hw,
      sub_ok _ _ hl, pure, pureExec, Live.write, emit, result, committed,
      updateBufferedEtherAllocation, setDepositsReserve, Writers.read_write_other, hbt, hbr, hreserve]

theorem exists_spec (ctx : Context) (input : Report.Inputs) (before : World) :
    ∃ observed, Describes ctx input before observed := by
  obtain ⟨outcome, h⟩ := ReportAccountingSpec.total Verity.Core.UINT256_MODULUS (buffer ctx before)
    input.rewards.val input.withdrawals.val input.lockAmount.val
  exact ⟨result ctx input before outcome, outcome, h, rfl⟩

theorem corresponds (ctx : Context) (input : Report.Inputs) (before : World) (observed : Result Unit) :
    Describes ctx input before observed ↔ Report.afterCalls ctx input before = observed := by
  constructor
  · rintro ⟨outcome, h, rfl⟩
    exact of_spec ctx input before outcome h
  · intro he
    obtain ⟨candidate, outcome, h, rfl⟩ := exists_spec ctx input before
    have hs := of_spec ctx input before outcome h
    exact ⟨outcome, h, he.symm.trans hs⟩

theorem complete (ctx : Context) (input : Report.Inputs) (before : World) :
    Describes ctx input before (Report.afterCalls ctx input before) :=
  (corresponds ctx input before _).mpr rfl

/-- Arithmetic failure occurs before any report-tail write/event or CALL attempt. -/
theorem failure_restores (ctx : Context) (input : Report.Inputs) (before after : World)
    (fault : Fault) (attempts : List Attempt)
    (h : Describes ctx input before ⟨.error fault, after, attempts⟩) :
    after = before ∧ attempts = [] := by
  obtain ⟨outcome, _, he⟩ := h
  cases outcome <;> simp_all [result, Live.Result.mk.injEq]

theorem committed_balances (ctx : Context) (input : Report.Inputs) (before : World) (post : Nat) :
    (committed ctx input before post).balances = before.balances := by
  unfold committed
  dsimp only
  split <;> rfl

end LidoSRv3.Audit.Source.TrioReserve1.ReportAccounting
