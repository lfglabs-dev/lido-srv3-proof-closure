import LidoSRv3.Audit.Model.AllocCapacity

/-! # SRStorage `_updateExitedCounters` / `addValidators` write-discipline model

**Chantier 3 (Piste A, Thomas 2026-09-13) source model for the
`active_subtraction` CheckedBounds invariant.**

The `active_subtraction` conjunct of `CheckedBounds` requires
`∀ m ∈ modules, wordMax m.summaryExitedCount m.accountingExitedCount
≤ m.depositedCount`.  This invariant is not a type-width bound (all
three fields fit in uint64); it is a WRITE-DISCIPLINE invariant of the
pinned SRStorage `_updateExitedCounters` and `addValidators` operations:

- `addValidators n` at SRLib.sol increments `depositedCount` by `n`
  unconditionally; the invariant is preserved because
  `depositedCount' = depositedCount + n ≥ depositedCount ≥ wordMax
  summaryExited accountingExited`.
- `_updateExitedCounters newSummary newAccounting` at SRLib.sol
  REQUIRES `max(newSummary, newAccounting) ≤ depositedCount` before
  writing (SRLib.sol reverts if not); the invariant is preserved
  by the admission check.

This module captures those two operations as a small state machine
over `Module`.  A `Module` reachable from a genesis (all-zero) state
via a finite sequence of admitted operations SATISFIES the invariant
by structural induction on the operation history.

**Real derivation, not a naming scaffold** — the invariant is proven
from the write-discipline, not asserted as a premise.  The bridge
theorem `active_subtraction_from_write_history` in `PAlloc1` composes
this with the other CheckedBounds conjuncts.  Residual: connecting
this source-model write history to LIVE EVM SRStorage writes remains a
follow-up (would require STATICCALL-plane observations of the pinned
`addValidators` / `_updateExitedCounters` call frames). -/

namespace LidoSRv3.Audit.Source.SRStorageExitedMonotonicity

open Verity
open Verity.Stdlib.Math
open LidoSRv3.Audit.AllocCapacity

/-- The three counter fields on a `Module` whose invariant we track:
`depositedCount ≥ max(summaryExitedCount, accountingExitedCount)`. -/
structure ExitedCounters where
  depositedCount : Uint256
  summaryExitedCount : Uint256
  accountingExitedCount : Uint256
  deriving Repr, DecidableEq

/-- The pinned `addValidators` / `_updateExitedCounters` operations. -/
inductive Operation
  /-- `addValidators n` at SRLib.sol: increment `depositedCount` by `n`. -/
  | addValidators (increment : Uint256)
  /-- `_updateExitedCounters s a` at SRLib.sol: set summary=s, accounting=a
  IF `max(s, a) ≤ depositedCount`; else abort.  The abort branch is captured
  by returning `none` in `applyOperation`. -/
  | updateExitedCounters (newSummary newAccounting : Uint256)
  deriving Repr

/-- The invariant preserved by the pinned write discipline. -/
def ExitedMonotone (c : ExitedCounters) : Prop :=
  (wordMax c.summaryExitedCount c.accountingExitedCount : Nat) ≤
    (c.depositedCount : Nat)

/-- Genesis state: all counters zero.  The invariant holds trivially. -/
def genesis : ExitedCounters := ⟨(0 : Uint256), (0 : Uint256), (0 : Uint256)⟩

theorem genesis_monotone : ExitedMonotone genesis := by
  unfold ExitedMonotone genesis
  rw [wordMax_coe]
  simp

/-- Apply one operation.  `addValidators n` mirrors the pinned SafeMath /
checked-add: the operation succeeds only if `depositedCount + n` fits in
uint256; else it aborts (reverts on-chain).  `_updateExitedCounters s a`
succeeds only if its admission check `max(s, a) ≤ depositedCount` holds. -/
def applyOperation (c : ExitedCounters) (op : Operation) : Option ExitedCounters :=
  match op with
  | .addValidators n =>
      if (c.depositedCount : Nat) + (n : Nat) ≤ Verity.Core.MAX_UINT256 then
        some ⟨c.depositedCount + n, c.summaryExitedCount, c.accountingExitedCount⟩
      else
        none
  | .updateExitedCounters s a =>
      if (wordMax s a : Nat) ≤ (c.depositedCount : Nat) then
        some ⟨c.depositedCount, s, a⟩
      else
        none

/-- If the pre-state satisfies the invariant and `applyOperation` succeeds,
the post-state satisfies the invariant.  Real derivation from the pinned
write discipline. -/
theorem applyOperation_preserves_monotone
    (c c' : ExitedCounters) (op : Operation)
    (hPre : ExitedMonotone c) (h : applyOperation c op = some c') :
    ExitedMonotone c' := by
  cases op with
  | addValidators n =>
      simp only [applyOperation] at h
      by_cases hFit : (c.depositedCount : Nat) + (n : Nat) ≤ Verity.Core.MAX_UINT256
      · rw [if_pos hFit] at h
        injection h with heq
        rw [← heq]
        unfold ExitedMonotone
        have hCurrent : (wordMax c.summaryExitedCount c.accountingExitedCount : Nat)
            ≤ (c.depositedCount : Nat) := hPre
        have hAdd : ((c.depositedCount + n : Uint256) : Nat) =
            (c.depositedCount : Nat) + (n : Nat) := by
          exact Verity.Core.Uint256.add_eq_of_lt (Nat.lt_of_le_of_lt hFit
            (by unfold Verity.Core.MAX_UINT256; decide))
        show (wordMax c.summaryExitedCount c.accountingExitedCount : Nat) ≤
          ((c.depositedCount + n : Uint256) : Nat)
        rw [hAdd]
        exact Nat.le_trans hCurrent (Nat.le_add_right _ _)
      · rw [if_neg hFit] at h; exact absurd h (by simp)
  | updateExitedCounters s a =>
      simp only [applyOperation] at h
      by_cases hCheck : (wordMax s a : Nat) ≤ (c.depositedCount : Nat)
      · rw [if_pos hCheck] at h
        injection h with heq
        rw [← heq]
        exact hCheck
      · rw [if_neg hCheck] at h; exact absurd h (by simp)

/-- Reduce a list of operations from an initial state.  Aborts (returns none)
on the first admission failure. -/
def applyOperations : ExitedCounters → List Operation → Option ExitedCounters
  | c, [] => some c
  | c, op :: rest =>
      match applyOperation c op with
      | some c' => applyOperations c' rest
      | none => none

/-- The invariant is preserved along ANY successful operation history. -/
theorem applyOperations_preserves_monotone :
    ∀ (c : ExitedCounters) (ops : List Operation) (c' : ExitedCounters),
      ExitedMonotone c →
      applyOperations c ops = some c' →
      ExitedMonotone c'
  | _, [], _, hPre, h => by
      simp [applyOperations] at h
      subst h
      exact hPre
  | c, op :: rest, c', hPre, h => by
      simp only [applyOperations] at h
      match hOp : applyOperation c op with
      | some c1 =>
          rw [hOp] at h
          have hMono := applyOperation_preserves_monotone c c1 op hPre hOp
          exact applyOperations_preserves_monotone c1 rest c' hMono h
      | none =>
          rw [hOp] at h
          exact absurd h (by simp)

/-- Every state reachable from `genesis` via a successful operation history
satisfies the monotonicity invariant. -/
theorem reachable_state_is_monotone
    (ops : List Operation) (c : ExitedCounters)
    (h : applyOperations genesis ops = some c) :
    ExitedMonotone c :=
  applyOperations_preserves_monotone genesis ops c genesis_monotone h

/-- Project a Module's exited counters. -/
def ofModule (m : LidoSRv3.Audit.AllocCapacity.Module) : ExitedCounters :=
  ⟨m.depositedCount, m.summaryExitedCount, m.accountingExitedCount⟩

theorem ofModule_monotone_iff (m : LidoSRv3.Audit.AllocCapacity.Module) :
    ExitedMonotone (ofModule m) ↔
    (wordMax m.summaryExitedCount m.accountingExitedCount : Nat) ≤
      (m.depositedCount : Nat) := by
  unfold ExitedMonotone ofModule
  rfl

end LidoSRv3.Audit.Source.SRStorageExitedMonotonicity
