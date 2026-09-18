import LidoSRv3.Audit.Guarantees.PTopup2
import Verity.Core

/-!
# P-TOPUP-2 live wei conversion and module-selected `allocateDeposits`

Additive consumer beside the registered parent
`PTopup2.aggregate_bounded_by_block_cap`, which still walks leftover
budget in gwei (`consumeBudget` / `transition`).  This module does
**not** edit that walk and does **not** compose with P-TOPUP-1.

It records the pinned live unit conversions and the router's admission
of a **module-selected** `allocateDeposits` return.

Pinned `lidofinance/core@17005714f151e5502c559932319a3f2f74ac2436`:

* `TopUpGateway.sol:226` `topUpLimits[i] = _evaluateTopUpLimit(...) * 1 gwei`
* `StakingRouter.sol:696` `maxTopUpPerBlockWei = maxTopUpPerBlockGwei * 1 gwei`
* `StakingRouter.sol:700` `min(moduleAlloc, maxTopUpPerBlockWei)`
* `StakingRouter.sol:706` `smDepositableEthAmountRounded = amount - amount % 1 gwei`
* `StakingRouter.sol:717-718` `IStakingModuleV2.allocateDeposits(...)`
* `StakingRouter.sol:724` `allocations[i] % 1 gwei != 0` → `AmountNotAlignedToGwei`
* `StakingRouter.sol:728` `allocations[i] > _topUpLimits[i]` → `AllocationExceedsLimit`
* `StakingRouter.sol:737` `amount > rounded` → `ModuleReturnExceedTarget`

`IStakingModuleV2.allocateDeposits` (`IStakingModuleV2.sol:17-19`) may
return zeros and any sum `≤ depositAmount`.  The module picks the
vector; the router only checks alignment, per-key limits, and the
rounded target.  That is not `consumeBudget`.
-/

namespace LidoSRv3.Audit.Source.TopupWeiAlloc

open LidoSRv3.Audit.Guarantees.PTopup2

abbrev GWEI : Nat := LidoSRv3.Audit.Guarantees.PTopup2.GWEI

/-! ## Live wei conversion -/

/-- `TopUpGateway.sol:226` / `StakingRouter.sol:696` — `* 1 gwei`. -/
def mulGwei (gwei : Nat) : Nat :=
  gwei * GWEI

/-- Inverse read `amount / 1 gwei` (BeaconChainDepositor.sol:96 style). -/
def divGwei (wei : Nat) : Nat :=
  wei / GWEI

/-- `StakingRouter.sol:706` / `:724` remainder. -/
def remGwei (wei : Nat) : Nat :=
  wei % GWEI

def aligned (wei : Nat) : Prop :=
  remGwei wei = 0

/-- `StakingRouter.sol:706` `amount - (amount % 1 gwei)`. -/
def floorGwei (wei : Nat) : Nat :=
  wei - remGwei wei

/-- `StakingRouter.sol:696`. -/
def liveMaxTopUpPerBlockWei (maxTopUpPerBlockGwei : Nat) : Nat :=
  mulGwei maxTopUpPerBlockGwei

/-- `StakingRouter.sol:700` then `:706`. -/
def liveRoundedTarget (moduleAllocWei maxTopUpPerBlockGwei : Nat) : Nat :=
  floorGwei (min moduleAllocWei (liveMaxTopUpPerBlockWei maxTopUpPerBlockGwei))

/-- `TopUpGateway.sol:226` applied pointwise. -/
def liveLimitsWei (limitsGwei : List Nat) : List Nat :=
  limitsGwei.map mulGwei

theorem gwei_pos : 0 < GWEI := by decide

theorem mulGwei_divGwei (gwei : Nat) :
    divGwei (mulGwei gwei) = gwei :=
  Nat.mul_div_cancel gwei gwei_pos

theorem remGwei_mulGwei (gwei : Nat) :
    remGwei (mulGwei gwei) = 0 := by
  unfold remGwei mulGwei
  rw [Nat.mul_comm]
  exact Nat.mul_mod_right GWEI gwei

theorem mulGwei_aligned (gwei : Nat) : aligned (mulGwei gwei) :=
  remGwei_mulGwei gwei

theorem floorGwei_eq (wei : Nat) : floorGwei wei = GWEI * (wei / GWEI) := by
  unfold floorGwei remGwei
  have h := Nat.div_add_mod wei GWEI
  calc
    wei - wei % GWEI
        = (GWEI * (wei / GWEI) + wei % GWEI) - wei % GWEI := by rw [h]
    _ = GWEI * (wei / GWEI) := Nat.add_sub_cancel _ _

theorem floorGwei_aligned (wei : Nat) : aligned (floorGwei wei) := by
  unfold aligned remGwei
  rw [floorGwei_eq]
  exact Nat.mul_mod_right GWEI (wei / GWEI)

theorem liveRoundedTarget_aligned (moduleAllocWei maxTopUpPerBlockGwei : Nat) :
    aligned (liveRoundedTarget moduleAllocWei maxTopUpPerBlockGwei) :=
  floorGwei_aligned _

theorem liveRoundedTarget_le_block (moduleAllocWei maxTopUpPerBlockGwei : Nat) :
    liveRoundedTarget moduleAllocWei maxTopUpPerBlockGwei ≤
      liveMaxTopUpPerBlockWei maxTopUpPerBlockGwei := by
  unfold liveRoundedTarget floorGwei remGwei
  have hmin : min moduleAllocWei (liveMaxTopUpPerBlockWei maxTopUpPerBlockGwei) ≤
      liveMaxTopUpPerBlockWei maxTopUpPerBlockGwei := Nat.min_le_right _ _
  exact Nat.le_trans (Nat.sub_le _ _) hmin

/-! ## Module-selected `allocateDeposits` return -/

/-- Observation of `IStakingModuleV2.allocateDeposits` (`:717-718`).
    Allocations are wei.  The vector is module-chosen, not
    `consumeBudget`. -/
structure AllocateDepositsReturn where
  allocations : List Nat
  deriving Repr, DecidableEq

/-- Pairwise `StakingRouter.sol:724` and `:728`.  Arity mismatch fails
    closed (`_validateTopUpInputs` already required matching lengths;
    a short/long module return is not admitted). -/
def pairwiseOk : List Nat → List Nat → Bool
  | [], [] => true
  | limit :: limits, alloc :: allocs =>
      (alloc % GWEI == 0) && decide (alloc ≤ limit) && pairwiseOk limits allocs
  | _, _ => false

/-- Router admission of the module return: pairwise checks plus
    `StakingRouter.sol:737` `amount ≤ rounded`. -/
def routerAdmits (limitsWei : List Nat) (rounded : Nat)
    (allocs : List Nat) : Bool :=
  pairwiseOk limitsWei allocs && decide (allocs.sum ≤ rounded)

/-- Fail-closed consumer: `none` on misaligned wei, over-limit, arity
    mismatch, or sum above the rounded target.  Not an always-success
    stub and not `consumeBudget`. -/
def admittedAllocations (limitsWei : List Nat) (rounded : Nat)
    (obs : AllocateDepositsReturn) : Option (List Nat) :=
  if routerAdmits limitsWei rounded obs.allocations then
    some obs.allocations
  else
    none

theorem pairwiseOk_nil : pairwiseOk [] [] = true := rfl

theorem pairwiseOk_cons {limit alloc : Nat} {limits allocs : List Nat}
    (hAlign : alloc % GWEI = 0) (hLe : alloc ≤ limit)
    (hTail : pairwiseOk limits allocs = true) :
    pairwiseOk (limit :: limits) (alloc :: allocs) = true := by
  simp [pairwiseOk, hAlign, hLe, hTail]

theorem pairwiseOk_aligned {limits allocs : List Nat}
    (h : pairwiseOk limits allocs = true) :
    ∀ a ∈ allocs, a % GWEI = 0 := by
  induction limits generalizing allocs with
  | nil =>
      cases allocs with
      | nil => intro a ha; cases ha
      | cons _ _ => simp [pairwiseOk] at h
  | cons limit limits ih =>
      cases allocs with
      | nil => simp [pairwiseOk] at h
      | cons alloc allocs =>
          simp [pairwiseOk] at h
          intro a ha
          have hmem : a = alloc ∨ a ∈ allocs := by
            simpa using ha
          rcases hmem with rfl | hIn
          · exact h.1.1
          · exact ih h.2 a hIn

theorem pairwiseOk_le {limits allocs : List Nat}
    (h : pairwiseOk limits allocs = true) :
    List.Forall₂ (fun alloc limit => alloc ≤ limit) allocs limits := by
  induction limits generalizing allocs with
  | nil =>
      cases allocs with
      | nil => exact List.Forall₂.nil
      | cons _ _ => simp [pairwiseOk] at h
  | cons limit limits ih =>
      cases allocs with
      | nil => simp [pairwiseOk] at h
      | cons alloc allocs =>
          simp [pairwiseOk] at h
          exact List.Forall₂.cons h.1.2 (ih h.2)

theorem pairwiseOk_length {limits allocs : List Nat}
    (h : pairwiseOk limits allocs = true) :
    allocs.length = limits.length := by
  induction limits generalizing allocs with
  | nil =>
      cases allocs with
      | nil => rfl
      | cons _ _ => simp [pairwiseOk] at h
  | cons limit limits ih =>
      cases allocs with
      | nil => simp [pairwiseOk] at h
      | cons alloc allocs =>
          simp [pairwiseOk] at h
          simp [ih h.2]

theorem admitted_spec {limitsWei : List Nat} {rounded : Nat}
    {obs : AllocateDepositsReturn} {allocs : List Nat}
    (h : admittedAllocations limitsWei rounded obs = some allocs) :
    allocs = obs.allocations ∧
      pairwiseOk limitsWei allocs = true ∧
      allocs.sum ≤ rounded := by
  unfold admittedAllocations at h
  by_cases hAd : routerAdmits limitsWei rounded obs.allocations
  · rw [if_pos hAd] at h
    have hEq : allocs = obs.allocations := (Option.some.inj h).symm
    unfold routerAdmits at hAd
    cases hPair : pairwiseOk limitsWei obs.allocations
    · simp [hPair] at hAd
    cases hDec : decide (obs.allocations.sum ≤ rounded)
    · simp [hPair, hDec] at hAd
    refine ⟨hEq, ?_, ?_⟩
    · simpa [hEq] using hPair
    · have hSum : obs.allocations.sum ≤ rounded := of_decide_eq_true hDec
      simpa [hEq] using hSum
  · rw [if_neg hAd] at h
    cases h

theorem admitted_aligned {limitsWei : List Nat} {rounded : Nat}
    {obs : AllocateDepositsReturn} {allocs : List Nat}
    (h : admittedAllocations limitsWei rounded obs = some allocs) :
    ∀ a ∈ allocs, aligned a := by
  have ⟨hEq, hPair, _⟩ := admitted_spec h
  intro a ha
  exact pairwiseOk_aligned hPair a ha

theorem admitted_le_limit {limitsWei : List Nat} {rounded : Nat}
    {obs : AllocateDepositsReturn} {allocs : List Nat}
    (h : admittedAllocations limitsWei rounded obs = some allocs) :
    List.Forall₂ (fun alloc limit => alloc ≤ limit) allocs limitsWei :=
  pairwiseOk_le (admitted_spec h).2.1

theorem admitted_sum_le_rounded {limitsWei : List Nat} {rounded : Nat}
    {obs : AllocateDepositsReturn} {allocs : List Nat}
    (h : admittedAllocations limitsWei rounded obs = some allocs) :
    allocs.sum ≤ rounded :=
  (admitted_spec h).2.2

/-- Admitted module wei cannot exceed the live block-cap word
    (`StakingRouter.sol:696-706`, then `:737`).  This cites the live
    conversion, not `consumeBudget`. -/
theorem admitted_sum_le_block_cap
    {limitsGwei : List Nat} {moduleAllocWei maxTopUpPerBlockGwei : Nat}
    {obs : AllocateDepositsReturn} {allocs : List Nat}
    (h : admittedAllocations (liveLimitsWei limitsGwei)
      (liveRoundedTarget moduleAllocWei maxTopUpPerBlockGwei) obs = some allocs) :
    allocs.sum ≤ liveMaxTopUpPerBlockWei maxTopUpPerBlockGwei :=
  Nat.le_trans (admitted_sum_le_rounded h)
    (liveRoundedTarget_le_block moduleAllocWei maxTopUpPerBlockGwei)

/-! ## Fail-closed rejects -/

theorem misaligned_rejected (limit rounded : Nat) :
    admittedAllocations [limit] rounded ⟨[1]⟩ = none := by
  have hMis : (1 % GWEI == 0) = false := by decide
  simp [admittedAllocations, routerAdmits, pairwiseOk, hMis]

theorem over_limit_rejected :
    admittedAllocations [mulGwei 1] (mulGwei 2) ⟨[mulGwei 2]⟩ = none := by
  decide

theorem over_target_rejected :
    admittedAllocations [mulGwei 20, mulGwei 20] (mulGwei 10)
      ⟨[mulGwei 10, mulGwei 10]⟩ = none := by
  decide

/-! ## Module policy is not `consumeBudget` -/

/-- Two independently eligible 20-gwei keys, block/module cap 20 gwei.
    Live limits are `[20e9, 20e9]` wei; rounded target is `20e9`.
    A module may return `[0, 20e9]` (`IStakingModuleV2.sol:17-18`).
    `consumeBudget 20 [20, 20]` is `[20, 0]`. -/
def twoKeyLimitsGwei : List Nat := [20, 20]
def twoKeyCandidatesGwei : List Nat := [20, 20]
def moduleRight : AllocateDepositsReturn := ⟨[0, mulGwei 20]⟩
def consumeLeft : List Nat := consumeBudget 20 twoKeyCandidatesGwei

theorem consumeLeft_eq : consumeLeft = [20, 0] := by
  simp [consumeLeft, consumeBudget, twoKeyCandidatesGwei]

theorem moduleRight_admitted :
    admittedAllocations (liveLimitsWei twoKeyLimitsGwei) (mulGwei 20)
      moduleRight = some [0, mulGwei 20] := by
  decide

theorem module_policy_not_consumeBudget :
    admittedAllocations (liveLimitsWei twoKeyLimitsGwei) (mulGwei 20)
        moduleRight =
      some [0, mulGwei 20] ∧
      consumeLeft = [20, 0] ∧
      (moduleRight.allocations.map divGwei) ≠ consumeLeft := by
  refine ⟨moduleRight_admitted, consumeLeft_eq, ?_⟩
  simp [moduleRight, consumeLeft, consumeBudget, twoKeyCandidatesGwei, divGwei,
    mulGwei, GWEI, LidoSRv3.Audit.Guarantees.PTopup2.GWEI]

end LidoSRv3.Audit.Source.TopupWeiAlloc
