import LidoSRv3.Audit.Source.TrioReserve1.Live
import LidoSRv3.Audit.Source.TrioReserve1.WriterSpec
import Lean.Elab.Tactic.Omega

namespace LidoSRv3.Audit.Source.TrioReserve1.Writers
open Live

/-- Independent scalar state is tied to physical storage, not a supplied validity flag. -/
def StateRel (ctx : Context) (w : World) (s : WriterSpec.State) : Prop :=
  s.buffer = (w.core.readContractSlot ctx.self.val bufferSlot).val % width ∧
  s.reserve = (w.core.readContractSlot ctx.self.val reserveSlot).val ∧
  s.target = (w.core.readContractSlot ctx.self.val targetSlot).val

def project (ctx : Context) (w : World) : WriterSpec.State :=
  ⟨(w.core.readContractSlot ctx.self.val bufferSlot).val % width,
   (w.core.readContractSlot ctx.self.val reserveSlot).val,
   (w.core.readContractSlot ctx.self.val targetSlot).val⟩

theorem project_related (ctx : Context) (w : World) : StateRel ctx w (project ctx w) :=
  ⟨rfl, rfl, rfl⟩

@[simp] theorem word_val (x : Word) : word x.val = x := by
  apply Verity.Core.Uint256.ext
  exact Nat.mod_eq_of_lt x.isLt

/-- Supplement the pinned lens library's same-slot theorem with a same-account
other-slot theorem. Covers address zero's legacy storage channel too. -/
theorem read_write_other (core : Verity.ContractState) (account written slot : Nat)
    (value : Word) (h : slot ≠ written) :
    (core.writeContractSlot account written value).readContractSlot account slot =
      core.readContractSlot account slot := by
  by_cases ha : account = 0
  · subst account
    simp [Verity.ContractState.writeContractSlot, Verity.ContractState.readContractSlot,
      Verity.ContractState.writeSlot, Verity.ContractState.readSlot,
      Verity.ContractState.storage, h]
  · simp [Verity.ContractState.writeContractSlot, Verity.ContractState.readContractSlot,
      Verity.ContractState.contractStorage, ha, h]

/-- The internal target writer satisfies the independent scalar specification.
This theorem does not claim the external ACL admission or report-parent behavior. -/
theorem target_corresponds (ctx : Context) (before : World) (requested : Word) :
    WriterSpec.Target (project ctx before) requested.val
      (project ctx (run (setDepositsReserveTarget ctx requested) before).world) := by
  by_cases h : requested.val < (before.core.readContractSlot ctx.self.val reserveSlot).val
  all_goals
    simp only [reserveSlot] at h
    simp [run, setDepositsReserveTarget, setDepositsReserve, Live.write, emit, Live.read,
    Bind.bind, Pure.pure, bindExec, pureExec, project, WriterSpec.Target,
    read_write_other, Verity.ContractState.readContractSlot_writeContractSlot_same,
      targetSlot, reserveSlot, bufferSlot, h]
    omega

/-- Rebalance may exceed buffer. Its scalar relation is max(reserve,target). -/
theorem rebalance_corresponds (ctx : Context) (before : World) :
    WriterSpec.Rebalance (project ctx before)
      (project ctx (run (updateBufferedEtherAllocation ctx) before).world) := by
  by_cases h : (before.core.readContractSlot ctx.self.val reserveSlot).val <
      (before.core.readContractSlot ctx.self.val targetSlot).val
  all_goals
    simp only [reserveSlot, targetSlot] at h
    simp [run, updateBufferedEtherAllocation, setDepositsReserve, Live.write, emit,
      Live.read, Bind.bind, Pure.pure, bindExec, pureExec, project, WriterSpec.Rebalance,
      read_write_other, Verity.ContractState.readContractSlot_writeContractSlot_same,
      targetSlot, reserveSlot, bufferSlot, h]
    omega

/-- All target-writer calls return, issue no external calls, preserve balances,
and append the target event before the optional reserve event. -/
theorem target_observations (ctx : Context) (before : World) (requested : Word) :
    let r := run (setDepositsReserveTarget ctx requested) before
    r.outcome = .ok () ∧ r.attempts = [] ∧ r.world.balances = before.balances ∧
    r.world.logs = before.logs ++ [⟨ctx.self, "DepositsReserveTargetSet", [requested]⟩] ++
      (if requested.val < (before.core.readContractSlot ctx.self.val reserveSlot).val
       then [⟨ctx.self, "DepositsReserveSet", [requested]⟩] else []) := by
  by_cases h : requested.val < (before.core.readContractSlot ctx.self.val reserveSlot).val
  all_goals
    simp only [reserveSlot] at h
    simp [run, setDepositsReserveTarget, setDepositsReserve, Live.write, emit,
      Live.read, Bind.bind, Pure.pure, bindExec, pureExec, read_write_other,
      targetSlot, reserveSlot, h]

/-- Rebalance has no external calls or balance movement, and emits just the
reserve event when raising reserve. -/
theorem rebalance_observations (ctx : Context) (before : World) :
    let r := run (updateBufferedEtherAllocation ctx) before
    r.outcome = .ok () ∧ r.attempts = [] ∧ r.world.balances = before.balances ∧
    r.world.logs = before.logs ++
      (if (before.core.readContractSlot ctx.self.val reserveSlot).val <
          (before.core.readContractSlot ctx.self.val targetSlot).val
       then [⟨ctx.self, "DepositsReserveSet", [before.core.readContractSlot ctx.self.val targetSlot]⟩]
       else []) := by
  by_cases h : (before.core.readContractSlot ctx.self.val reserveSlot).val <
      (before.core.readContractSlot ctx.self.val targetSlot).val
  all_goals
    simp [run, updateBufferedEtherAllocation, setDepositsReserve, Live.write, emit,
      Live.read, Bind.bind, Pure.pure, bindExec, pureExec, h]

end LidoSRv3.Audit.Source.TrioReserve1.Writers
