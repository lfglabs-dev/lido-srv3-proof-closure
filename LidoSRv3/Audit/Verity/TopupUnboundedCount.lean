import LidoSRv3.Audit.Guarantees.PTopup2
import LidoSRv3.Audit.Guarantees.PTopup2Verity
import LidoSRv3.Audit.Source.Topup2Correspondence
import LidoSRv3.Audit.Verity.Topup2DistributionTx
import Verity.Core.Model.Denote

/-!
# P-TOPUP-2 unbounded count consumer

The registered Verity parent `verity_tx_simulates_topup2_spec` assumes
`requested.length ≤ maxValidatorsPerTopUp` with
`Topup2DistributionTx.maxValidatorsPerTopUp := 32`.  That 32 is a **model
freeze**, not a StakingRouter / StakingModule constant.

Pinned `lidofinance/core@17005714f151e5502c559932319a3f2f74ac2436`:

* `StakingRouter.sol:761-782` `_validateTopUpInputs` — empty / length /
  pubkey guards only.  No `count ≤ 32`.
* `StakingRouter.sol:679-759` `topUp` — share, `maxTopUpPerBlockWei`,
  module `allocateDeposits`, sum ≤ target.  No key-count cap.
* `IStakingModuleV2.sol:21-27` `allocateDeposits` — no count bound.
* `TopUpGateway.sol:174-176` —
  `if (validatorsCount > $.maxValidatorsPerTopUp) revert MaxValidatorsPerTopUpExceeded();`
  The right-hand side is a packed `uint64` storage word
  (`TopUpGateway.sol:42`), settable to any value in `1 .. 2^64-1`
  (`:355-360`).  It is not the literal 32.

The leftover walk (`consumeBudget` / `sourceRun`) is already total on every
`List`.  This module states that consumer, proves the sum bound by induction
on the key list, proves lockstep of `allocateAnyCount` (no frozen-32 guard)
against `sourceView` for every count, and registers the existing parent as
the instance `count ≤ 32`.

The parent files are not edited.
-/

namespace LidoSRv3.Audit.Verity.TopupUnboundedCount

open _root_.Verity
open LidoSRv3.Audit.Guarantees.PTopup2
open LidoSRv3.Audit.Source.Topup2
open LidoSRv3.Audit.Verity.Topup2DistributionTx

/-! ## Induction on the key list

`consumeBudget` in `PTopup2` is already defined on every `List Nat`.  The
private lemmas `consumeBudget_sum_le` / `consumeBudget_sum_le_sum` are not
visible here; the public parent `aggregate_bounded_by_block_cap` is the
instance of the first at `transitionBudget`.  Restate both by induction so
the unbounded consumer does not depend on a hidden finite-count premise. -/

theorem leftover_walk_sum_le_budget :
    ∀ (budget : Nat) (keys : List Nat),
      (consumeBudget budget keys).sum ≤ budget
  | _, [] => by simp [consumeBudget]
  | budget, amount :: amounts => by
      simp only [consumeBudget, List.sum_cons]
      have hmin : min amount budget ≤ budget := Nat.min_le_right _ _
      have htail := leftover_walk_sum_le_budget (budget - min amount budget) amounts
      exact Nat.le_trans (Nat.add_le_add_left htail _)
        (Nat.le_of_eq (Nat.add_sub_of_le hmin))

theorem leftover_walk_sum_le_keys :
    ∀ (budget : Nat) (keys : List Nat),
      (consumeBudget budget keys).sum ≤ keys.sum
  | _, [] => by simp [consumeBudget]
  | budget, amount :: amounts => by
      simp only [consumeBudget, List.sum_cons]
      exact Nat.add_le_add (Nat.min_le_left _ _)
        (leftover_walk_sum_le_keys (budget - min amount budget) amounts)

/-- The registered abstract parent is the leftover-walk instance at
`transitionBudget = min(valueGwei, min(moduleLimit, maxTopUpPerBlockGwei))`.
No `count ≤ 32` hypothesis. -/
theorem parent_block_cap_is_unbounded_instance
    (b : TopupBatch) (cfg : TopupConfig) :
    (transition b cfg).sum ≤ cfg.maxTopUpPerBlockGwei :=
  Nat.le_trans (leftover_walk_sum_le_budget (transitionBudget b cfg) (candidates b cfg))
    (Nat.le_trans (Nat.min_le_right _ _) (Nat.min_le_right _ _))

/-- Same inhabitant type as the registered abstract parent; the 32-guard is
not among its hypotheses. -/
theorem parent_block_cap_instance_eq
    (b : TopupBatch) (cfg : TopupConfig) :
    (transition b cfg).sum ≤ cfg.maxTopUpPerBlockGwei :=
  parent_block_cap_is_unbounded_instance b cfg

/-! ## Independent source walk, any length

`sourceConsumeIndependent_eq_sourceConsume` / `sourceRunIndependent_eq_sourceRun`
are already quantified over every list.  Restate them here as the derived
consumer so the unbounded lot names its own induction. -/

theorem sourceConsume_any_count :
    ∀ remaining candidates,
      sourceConsume remaining candidates = sourceConsumeIndependent remaining candidates
  | _, [] => rfl
  | remaining, cand :: rest => by
      simp [sourceConsume, sourceConsumeIndependent, sourceConsume_any_count]

theorem sourceLimits_any_count :
    ∀ effective pending target minTopUp,
      sourceLimits effective pending target minTopUp =
        sourceLimitsIndependent effective pending target minTopUp
  | [], [], _, _ => rfl
  | e :: es, p :: ps, target, minTopUp => by
      simp [sourceLimits, sourceLimitsIndependent, sourceLimits_any_count]
  | [], _ :: _, _, _ => rfl
  | _ :: _, [], _, _ => rfl

theorem sourceCandidates_any_count :
    ∀ requested topUpLimits,
      sourceCandidates requested topUpLimits =
        sourceCandidatesIndependent requested topUpLimits
  | [], [] => rfl
  | r :: rs, limit :: limits => by
      simp [sourceCandidates, sourceCandidatesIndependent, sourceCandidates_any_count]
  | [], _ :: _ => rfl
  | _ :: _, [] => rfl

theorem sourceRun_any_count
    (effective pending requested topUpLimits : List Word)
    (target minTopUp remainingCap moduleLimit valueGwei : Word) :
    sourceRun effective pending requested topUpLimits target minTopUp remainingCap
        moduleLimit valueGwei =
      sourceRunIndependent effective pending requested topUpLimits target minTopUp
        remainingCap moduleLimit valueGwei := by
  unfold sourceRun sourceRunIndependent
  simp only [sourceLimits_any_count, sourceCandidates_any_count, sourceConsume_any_count]
  rfl

/-! ## `allocate` without the frozen-32 guard

Identical to `Topup2DistributionTx.allocate` except the
`count > maxValidatorsPerTopUp` revert is omitted.  StakingRouter /
IStakingModuleV2 have no such guard.  TopUpGateway's guard is the stored
word, not this literal. -/

def allocateAnyCount (count : Nat)
    (target minTopUp remainingCap moduleLimit valueGwei : Word)
    (failAfterWrites : Bool := false) : Contract Result := fun snapshot =>
  -- TopUpGateway.sol:164  if (validatorsCount == 0) revert WrongArrayLength();
  if count == 0 then .revert "WrongArrayLength" snapshot else
  match readArray snapshot "effective" effectiveBase count,
      readArray snapshot "pending" pendingBase count,
      readArray snapshot "requested" requestedBase count,
      readArray snapshot "topUpLimits" limitsBase count with
  | some effective, some pending, some requested, some topUpLimits =>
      match sourceRun effective pending requested topUpLimits target minTopUp remainingCap
          moduleLimit valueGwei with
      | none => .revert "TOPUP_ARITHMETIC" snapshot
      | some (allocs, remaining, used) =>
          let dirty := persistAllocs allocs snapshot
          let dirty := (dirty.writeSlot remainingSlot remaining).writeSlot allocatedSlot used
          if failAfterWrites then .revert "INJECTED_AFTER_WRITES" dirty
          else .success ⟨allocs, remaining, used⟩ dirty
  | _, _, _, _ => .revert "MEMORY_ARRAY_DECODE" snapshot

theorem allocate_eq_any_of_le
    (count : Nat) (target minTopUp remainingCap moduleLimit valueGwei : Word)
    (failAfterWrites : Bool)
    (h : count ≤ maxValidatorsPerTopUp) :
    allocate count target minTopUp remainingCap moduleLimit valueGwei failAfterWrites =
      allocateAnyCount count target minTopUp remainingCap moduleLimit valueGwei
        failAfterWrites := by
  funext snapshot
  unfold allocate allocateAnyCount
  by_cases hz : count = 0
  · simp [hz]
  · have hbeq : (count == 0) = false := by simp [hz]
    have hNotOver : ¬ maxValidatorsPerTopUp < count := Nat.not_lt.mpr h
    simp [hbeq, hNotOver]

/-- Lockstep of the unbounded transaction against the independent source
view, for **every** decoded count.  No `count ≤ 32` premise. -/
theorem verity_tx_simulates_pinned_source_any_count
    (effective pending requested topUpLimits : List Word)
    (target minTopUp remainingCap moduleLimit valueGwei : Word)
    (state : ContractState)
    (hEff : readArray state "effective" effectiveBase effective.length = some effective)
    (hPend : readArray state "pending" pendingBase pending.length = some pending)
    (hReq : readArray state "requested" requestedBase requested.length = some requested)
    (hLimits : readArray state "topUpLimits" limitsBase topUpLimits.length = some topUpLimits)
    (hLen : effective.length = pending.length ∧ pending.length = requested.length ∧
      requested.length = topUpLimits.length) :
    observe (List.replicate requested.length 0) remainingCap
        ((allocateAnyCount requested.length target minTopUp remainingCap moduleLimit
          valueGwei).run state) =
      sourceView effective pending requested topUpLimits target minTopUp remainingCap
        moduleLimit valueGwei := by
  have hER : effective.length = requested.length := hLen.1.trans hLen.2.1
  have hPR : pending.length = requested.length := hLen.2.1
  have hLR : topUpLimits.length = requested.length := hLen.2.2.symm
  have hEff' : readArray state "effective" effectiveBase requested.length = some effective := by
    simpa [hER] using hEff
  have hPend' : readArray state "pending" pendingBase requested.length = some pending := by
    simpa [hPR] using hPend
  have hLimits' : readArray state "topUpLimits" limitsBase requested.length =
      some topUpLimits := by
    simpa [hLR] using hLimits
  by_cases hZero : requested.length = 0
  · have hEffZ : effective.length = 0 := hER.trans hZero
    unfold Contract.run allocateAnyCount sourceView
    simp [hZero, hEffZ, observe, sourceRunIndependent]
  · have hZ : (requested.length == 0) = false := by simp [hZero]
    unfold Contract.run allocateAnyCount sourceView
    simp only [hZ, Bool.false_eq_true, ↓reduceIte, hEff', hPend', hReq, hLimits']
    rw [sourceRun_any_count]
    cases hRun : sourceRunIndependent effective pending requested topUpLimits target minTopUp
        remainingCap moduleLimit valueGwei with
    | none =>
        simp [observe]
    | some trip =>
        rcases trip with ⟨allocs, remaining, used⟩
        simp [observe, persistAllocs, remainingSlot, allocatedSlot,
          ContractState.readArray, ContractState.writeArray,
          ContractState.readSlot_writeSlot_same,
          ContractState.readSlot_writeSlot_other,
          ContractState.storageArray_writeSlot]

/-- The registered Verity parent is the unbounded lockstep instantiated at
`count ≤ 32`, where `allocate` and `allocateAnyCount` agree. -/
theorem parent_verity_is_unbounded_instance
    (effective pending requested topUpLimits : List Word)
    (target minTopUp remainingCap moduleLimit valueGwei : Word)
    (state : ContractState)
    (hEff : readArray state "effective" effectiveBase effective.length = some effective)
    (hPend : readArray state "pending" pendingBase pending.length = some pending)
    (hReq : readArray state "requested" requestedBase requested.length = some requested)
    (hLimits : readArray state "topUpLimits" limitsBase topUpLimits.length = some topUpLimits)
    (hLen : effective.length = pending.length ∧ pending.length = requested.length ∧
      requested.length = topUpLimits.length)
    (hMax : requested.length ≤ maxValidatorsPerTopUp) :
    observe (List.replicate requested.length 0) remainingCap
        ((allocate requested.length target minTopUp remainingCap moduleLimit valueGwei).run
          state) =
      sourceView effective pending requested topUpLimits target minTopUp remainingCap
        moduleLimit valueGwei := by
  have heq := allocate_eq_any_of_le requested.length target minTopUp remainingCap
    moduleLimit valueGwei false hMax
  rw [heq]
  exact verity_tx_simulates_pinned_source_any_count
    effective pending requested topUpLimits target minTopUp remainingCap moduleLimit
    valueGwei state hEff hPend hReq hLimits hLen

/-- Same statement as `verity_tx_simulates_topup2_spec`, derived from the
unbounded consumer plus `allocate_eq_any_of_le`. -/
theorem parent_verity_instance_matches_registered
    (effective pending requested topUpLimits : List Word)
    (target minTopUp remainingCap moduleLimit valueGwei : Word)
    (state : ContractState)
    (hEff : readArray state "effective" effectiveBase effective.length = some effective)
    (hPend : readArray state "pending" pendingBase pending.length = some pending)
    (hReq : readArray state "requested" requestedBase requested.length = some requested)
    (hLimits : readArray state "topUpLimits" limitsBase topUpLimits.length = some topUpLimits)
    (hLen : effective.length = pending.length ∧ pending.length = requested.length ∧
      requested.length = topUpLimits.length)
    (hMax : requested.length ≤ maxValidatorsPerTopUp) :
    observe (List.replicate requested.length 0) remainingCap
        ((allocate requested.length target minTopUp remainingCap moduleLimit valueGwei).run
          state) =
      sourceView effective pending requested topUpLimits target minTopUp remainingCap
        moduleLimit valueGwei :=
  parent_verity_is_unbounded_instance
    effective pending requested topUpLimits target minTopUp remainingCap moduleLimit
    valueGwei state hEff hPend hReq hLimits hLen hMax

#print axioms leftover_walk_sum_le_budget
#print axioms leftover_walk_sum_le_keys
#print axioms parent_block_cap_is_unbounded_instance
#print axioms parent_block_cap_instance_eq
#print axioms sourceConsume_any_count
#print axioms sourceLimits_any_count
#print axioms sourceCandidates_any_count
#print axioms sourceRun_any_count
#print axioms allocate_eq_any_of_le
#print axioms verity_tx_simulates_pinned_source_any_count
#print axioms parent_verity_is_unbounded_instance
#print axioms parent_verity_instance_matches_registered

end LidoSRv3.Audit.Verity.TopupUnboundedCount
