import LidoSRv3.Audit.Guarantees.PTopup2Verity
import LidoSRv3.Tests.Topup2DistributionTxMutants

/-! Audit probe (temporary, not evidence).

Two questions about the registered P-TOPUP-2 Verity parent
`PTopup2.verity_tx_simulates_topup2_spec`:

1. Does the `maxValidatorsPerTopUp` kill-line mutant `allocateNoMaxCheck`
   refute it?  No: under the parent's own `hMax` hypothesis the honest
   transaction and the guard-free mutant are the same function, so the
   mutant-substituted parent is still provable, directly from the parent.

2. How much of the pinned source interpreter does the parent use?  Only
   "an empty batch is `none`".  `verity_tx_simulates_any_run` below proves
   the parent's shape for an arbitrary run function with that one property,
   and instantiates it at a limit-blind mutant that tops up a validator
   already at its target balance. -/

namespace LidoSRv3.Tests.Topup2AuditProbe

open Verity
open LidoSRv3.Audit.Verity.Topup2DistributionTx
open LidoSRv3.Audit.Source.Topup2 (minWord sourceConsume sourceRun)
open Verity.Stdlib.Math (safeSub)
open LidoSRv3.Tests.Topup2DistributionTxMutants

/-! ## 1. The `maxValidatorsPerTopUp` guard is inert inside the parent -/

theorem allocate_eq_noMaxCheck_of_le
    (count : Nat) (target minTopUp remainingCap moduleLimit valueGwei : Word)
    (inject : Bool) (state : ContractState)
    (h : count ≤ maxValidatorsPerTopUp) :
    (allocate count target minTopUp remainingCap moduleLimit valueGwei inject).run state =
      (allocateNoMaxCheck count target minTopUp remainingCap moduleLimit valueGwei inject).run
        state := by
  have hnot : ¬ (count > maxValidatorsPerTopUp) := Nat.not_lt.mpr h
  unfold Contract.run allocate allocateNoMaxCheck
  rw [if_neg hnot]
  rfl

theorem no_max_check_mutant_survives_registered_verity_parent
    (effective pending requested : List Word)
    (target minTopUp remainingCap moduleLimit valueGwei : Word)
    (state : ContractState)
    (hEff : readArray state "effective" effectiveBase effective.length = some effective)
    (hPend : readArray state "pending" pendingBase pending.length = some pending)
    (hReq : readArray state "requested" requestedBase requested.length = some requested)
    (hLen : effective.length = pending.length ∧ pending.length = requested.length)
    (hMax : requested.length ≤ maxValidatorsPerTopUp) :
    observe (List.replicate requested.length 0) remainingCap
        ((allocateNoMaxCheck requested.length target minTopUp remainingCap moduleLimit
          valueGwei).run state) =
      sourceView effective pending requested target minTopUp remainingCap moduleLimit
        valueGwei := by
  rw [← allocate_eq_noMaxCheck_of_le requested.length target minTopUp remainingCap moduleLimit
    valueGwei false state hMax]
  exact LidoSRv3.Audit.Guarantees.PTopup2.verity_tx_simulates_topup2_spec
    effective pending requested target minTopUp remainingCap moduleLimit valueGwei state
    hEff hPend hReq hLen hMax

/-! ## 2. The parent holds for any run function that reverts on an empty batch -/

abbrev RunFn := List Word → List Word → List Word → Word → Word → Word → Word → Word →
  Option (List Word × Word × Word)

def allocateGen (run : RunFn) (count : Nat)
    (target minTopUp remainingCap moduleLimit valueGwei : Word)
    (failAfterWrites : Bool := false) : Contract Result := fun snapshot =>
  if count == 0 then .revert "WrongArrayLength" snapshot else
  if count > maxValidatorsPerTopUp then .revert "MaxValidatorsPerTopUpExceeded" snapshot else
  match readArray snapshot "effective" effectiveBase count,
      readArray snapshot "pending" pendingBase count,
      readArray snapshot "requested" requestedBase count with
  | some effective, some pending, some requested =>
      match run effective pending requested target minTopUp remainingCap moduleLimit valueGwei with
      | none => .revert "TOPUP_ARITHMETIC" snapshot
      | some (allocs, remaining, used) =>
          let dirty := persistAllocs allocs snapshot
          let dirty := (dirty.writeSlot remainingSlot remaining).writeSlot allocatedSlot used
          if failAfterWrites then .revert "INJECTED_AFTER_WRITES" dirty
          else .success ⟨allocs, remaining, used⟩ dirty
  | _, _, _ => .revert "MEMORY_ARRAY_DECODE" snapshot

def sourceViewGen (run : RunFn) (effective pending requested : List Word)
    (target minTopUp remainingCap moduleLimit valueGwei : Word) : View :=
  match run effective pending requested target minTopUp remainingCap moduleLimit valueGwei with
  | none => ⟨.reverted, List.replicate requested.length 0, remainingCap, 0⟩
  | some (allocs, remaining, used) => ⟨.committed, allocs, remaining, used⟩

theorem verity_tx_simulates_any_run (run : RunFn)
    (hEmpty : ∀ e p r t m rc ml v, e.length = 0 → run e p r t m rc ml v = none)
    (effective pending requested : List Word)
    (target minTopUp remainingCap moduleLimit valueGwei : Word)
    (state : ContractState)
    (hEff : readArray state "effective" effectiveBase effective.length = some effective)
    (hPend : readArray state "pending" pendingBase pending.length = some pending)
    (hReq : readArray state "requested" requestedBase requested.length = some requested)
    (hLen : effective.length = pending.length ∧ pending.length = requested.length)
    (hMax : requested.length ≤ maxValidatorsPerTopUp) :
    observe (List.replicate requested.length 0) remainingCap
        ((allocateGen run requested.length target minTopUp remainingCap moduleLimit
          valueGwei).run state) =
      sourceViewGen run effective pending requested target minTopUp remainingCap moduleLimit
        valueGwei := by
  have hER : effective.length = requested.length := hLen.1.trans hLen.2
  have hPR : pending.length = requested.length := hLen.2
  have hEff' : readArray state "effective" effectiveBase requested.length = some effective := by
    simpa [hER] using hEff
  have hPend' : readArray state "pending" pendingBase requested.length = some pending := by
    simpa [hPR] using hPend
  have hNotOver : ¬ maxValidatorsPerTopUp < requested.length := Nat.not_lt.mpr hMax
  by_cases hZero : requested.length = 0
  · have hEffZ : effective.length = 0 := hER.trans hZero
    have hnone := hEmpty effective pending requested target minTopUp remainingCap moduleLimit
      valueGwei hEffZ
    unfold Contract.run allocateGen sourceViewGen
    simp [hZero, observe, hnone]
  · have hZ : (requested.length == 0) = false := by simp [hZero]
    unfold Contract.run allocateGen sourceViewGen
    simp only [hZ, hNotOver, Bool.false_eq_true, ↓reduceIte, hEff', hPend', hReq]
    cases hRun : run effective pending requested target minTopUp remainingCap moduleLimit
        valueGwei with
    | none => simp [observe]
    | some trip =>
        rcases trip with ⟨allocs, remaining, used⟩
        simp [observe, persistAllocs, remainingSlot, allocatedSlot,
          ContractState.readArray, ContractState.writeArray,
          ContractState.readSlot_writeSlot_same,
          ContractState.readSlot_writeSlot_other,
          ContractState.storageArray_writeSlot]

/-- Limit-blind mutant: the evaluated per-validator headroom is dropped and the
requested amounts are consumed directly. Everything else, including the empty
batch revert and the budget, is the pinned `sourceRun`. -/
def mutantRunNoLimit (effective _pending requested : List Word)
    (_target _minTopUp remainingCap moduleLimit valueGwei : Word) :
    Option (List Word × Word × Word) :=
  if effective.length == 0 then none
  else
    let budget := minWord valueGwei (minWord moduleLimit remainingCap)
    match sourceConsume budget requested with
    | none => none
    | some (allocs, leftover) =>
        match safeSub budget leftover with
        | none => none
        | some used =>
            match safeSub remainingCap used with
            | none => none
            | some remaining => some (allocs, remaining, used)

theorem mutantRunNoLimit_empty (e p r : List Word) (t m rc ml v : Word) (h : e.length = 0) :
    mutantRunNoLimit e p r t m rc ml v = none := by
  simp [mutantRunNoLimit, h]

/-- The limit-blind mutant satisfies the registered parent's exact shape. -/
theorem no_limit_mutant_survives_registered_verity_shape
    (effective pending requested : List Word)
    (target minTopUp remainingCap moduleLimit valueGwei : Word)
    (state : ContractState)
    (hEff : readArray state "effective" effectiveBase effective.length = some effective)
    (hPend : readArray state "pending" pendingBase pending.length = some pending)
    (hReq : readArray state "requested" requestedBase requested.length = some requested)
    (hLen : effective.length = pending.length ∧ pending.length = requested.length)
    (hMax : requested.length ≤ maxValidatorsPerTopUp) :
    observe (List.replicate requested.length 0) remainingCap
        ((allocateGen mutantRunNoLimit requested.length target minTopUp remainingCap moduleLimit
          valueGwei).run state) =
      sourceViewGen mutantRunNoLimit effective pending requested target minTopUp remainingCap
        moduleLimit valueGwei :=
  verity_tx_simulates_any_run mutantRunNoLimit
    (fun e p r t m rc ml v h => mutantRunNoLimit_empty e p r t m rc ml v h)
    effective pending requested target minTopUp remainingCap moduleLimit valueGwei state
    hEff hPend hReq hLen hMax

private def w (n : Nat) : Word := Verity.Core.Uint256.ofNat n

/-- The mutant is a real bug: a validator already at its 64-gwei target is
topped up by 10 gwei, where the pinned interpreter allocates 0. -/
example : sourceRun [w 64] [w 0] [w 10] (w 64) (w 1) (w 100) (w 100) (w 100) =
    some ([w 0], w 100, w 0) := by native_decide

example : mutantRunNoLimit [w 64] [w 0] [w 10] (w 64) (w 1) (w 100) (w 100) (w 100) =
    some ([w 10], w 90, w 10) := by native_decide

/-! ## 3. The missing per-key bound, and how cheap it is

The registered abstract parent bounds only the aggregate, so it is satisfied by
an allocator that ignores `evaluated_topup_limit` entirely. The router's actual
per-key `require` is `allocations[i] <= limits[i]`. That bound is available from
the same `consumeBudget` induction. -/

open LidoSRv3.Audit.Guarantees.PTopup2

theorem consumeBudget_pointwise_le (budget : Nat) (amounts : List Nat) (i : Nat) :
    (consumeBudget budget amounts).getD i 0 ≤ amounts.getD i 0 := by
  induction amounts generalizing budget i with
  | nil => simp [consumeBudget]
  | cons a as ih =>
      cases i with
      | zero => simpa [consumeBudget] using Nat.min_le_left a budget
      | succ n => simpa [consumeBudget] using ih (budget - min a budget) n

theorem zipWith_min_getD_le_right (xs ys : List Nat) (i : Nat) :
    (List.zipWith min xs ys).getD i 0 ≤ ys.getD i 0 := by
  induction xs generalizing ys i with
  | nil => simp
  | cons x xs ih =>
      cases ys with
      | nil => simp
      | cons y ys =>
          cases i with
          | zero => simpa using Nat.min_le_right x y
          | succ n => simpa using ih ys n

/-- The per-validator headroom bound the registry does not register. -/
theorem transition_pointwise_le_limit (b : TopupBatch) (cfg : TopupConfig) (i : Nat) :
    (transition b cfg).getD i 0 ≤
      (b.validators.map (fun v => evaluated_topup_limit v cfg)).getD i 0 :=
  Nat.le_trans (consumeBudget_pointwise_le _ _ i)
    (zipWith_min_getD_le_right _ _ i)

end LidoSRv3.Tests.Topup2AuditProbe
