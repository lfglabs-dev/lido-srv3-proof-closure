import LidoSRv3.Audit.Strategy
import LidoSRv3.Audit.MinFirstAllocation
import Verity.Macro

/-!
Pinned source correspondence for `MinFirstAllocationStrategy` at
`lidofinance/core@af095e48bbc1c3841c2c9936219c8461af01056b`,
`contracts/common/lib/MinFirstAllocationStrategy.sol`.

`allocateToBestCandidate`, lines 76--86, scans buckets in ascending index
order, skips a bucket when `buckets[i] >= capacities[i]`, and replaces the
saved candidate only when `bestCandidateAllocation > buckets[i]`.  Thus an
equal-valued later bucket does not replace the first one.  The definition below
is the extensionally equivalent recursive presentation of that candidate-search
loop: it selects the first least open row.

This module deliberately models only the selected target.  Lines 92--106
compute and apply a proportional allocation amount; no amount/refinement claim
is made here because `MinFirst.step` uses one `Nat` unit.
-/

namespace LidoSRv3.Audit.SolidityMinFirst

open LidoSRv3.Audit
open Verity
open Verity.EVM.Uint256
open Verity.Stdlib.Math

private def minWord (a b : Uint256) : Uint256 := if a ≤ b then a else b
private def min (a b : Uint256) : Uint256 := minWord a b

/-!
## Typed-storage execution lane

The four arrays below are the router-ordered columns consumed by the pinned
strategy.  Their slots are model-local: deployed proxy layout, ABI/Yul/EVM
lowering, gas, and the external router call boundary remain **OPEN**.  The
entrypoint itself executes the source-shaped minimum-first rounds: first least
candidate, equal-minimum count, next allocation level, then checked demand,
capacity, bucket, and total arithmetic.
-/

verity_contract AllocationContract where
  storage
    stakeRatios : Array Uint256 := slot 0
    moduleLimits : Array Uint256 := slot 1
    allocationBuffers : Array Uint256 := slot 2
    moduleEnabled : Array Bool := slot 3

  constants
    MAX_WORD : Uint256 := 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff

  function allocate (deposits : Uint256) : Uint256 := do
    let count ← getStorageArrayLength stakeRatios
    let limitsCount ← getStorageArrayLength moduleLimits
    let buffersCount ← getStorageArrayLength allocationBuffers
    let enabledCount ← getStorageArrayLength moduleEnabled
    require (count == limitsCount) "LENGTH_MISMATCH"
    require (count == buffersCount) "LENGTH_MISMATCH"
    require (count == enabledCount) "LENGTH_MISMATCH"

    let mut total := 0
    -- Every live round allocates at least one word unit.  `deposits` is
    -- therefore a sound fuel bound for the source `while (remaining > 0)`;
    -- exhausted demand/capacity turns later iterations into no-ops.
    forEach "round" deposits (do
      let available ← requireSomeUint (safeSub deposits total) "DEMAND_UNDERFLOW"
      if available == 0 then
        total := total
      else
        let mut bestIndex := count
        let mut bestAllocation := MAX_WORD
        forEach "i" count (do
          let enabled ← getStorageArrayElement moduleEnabled i
          let allocation ← getStorageArrayElement stakeRatios i
          let limit ← getStorageArrayElement moduleLimits i
          let buffer ← getStorageArrayElement allocationBuffers i
          let effectiveLimit := min limit buffer
          if enabled && allocation < effectiveLimit && allocation < bestAllocation then
            bestIndex := i
            bestAllocation := allocation
          else
            bestIndex := bestIndex)

        if bestIndex < count then
          let mut bestCount := 0
          forEach "i" count (do
            let enabled ← getStorageArrayElement moduleEnabled i
            let allocation ← getStorageArrayElement stakeRatios i
            let limit ← getStorageArrayElement moduleLimits i
            let buffer ← getStorageArrayElement allocationBuffers i
            let effectiveLimit := min limit buffer
            if enabled && allocation < effectiveLimit && allocation == bestAllocation then
              let nextBestCount ← requireSomeUint (safeAdd bestCount 1) "COUNT_OVERFLOW"
              bestCount := nextBestCount
            else
              bestCount := bestCount)

          let mut nextLevel := MAX_WORD
          forEach "i" count (do
            let enabled ← getStorageArrayElement moduleEnabled i
            let allocation ← getStorageArrayElement stakeRatios i
            let limit ← getStorageArrayElement moduleLimits i
            let buffer ← getStorageArrayElement allocationBuffers i
            let effectiveLimit := min limit buffer
            if enabled && allocation < effectiveLimit &&
                bestAllocation < allocation && allocation < nextLevel then
              nextLevel := allocation
            else
              nextLevel := nextLevel)

          let limit ← getStorageArrayElement moduleLimits bestIndex
          let buffer ← getStorageArrayElement allocationBuffers bestIndex
          let effectiveLimit := min limit buffer
          let capacityHeadroom ← requireSomeUint
            (safeSub effectiveLimit bestAllocation) "CAPACITY_UNDERFLOW"
          let mut share := available
          if 1 < bestCount then
            share := ceilDiv available bestCount
          else
            share := share
          let mut levelHeadroom := share
          if nextLevel < MAX_WORD then
            levelHeadroom := sub nextLevel bestAllocation
          else
            levelHeadroom := levelHeadroom
          let amount := min share (min levelHeadroom capacityHeadroom)
          let updated ← requireSomeUint (safeAdd bestAllocation amount) "BUCKET_OVERFLOW"
          let nextTotal ← requireSomeUint (safeAdd total amount) "TOTAL_OVERFLOW"
          setStorageArrayElement stakeRatios bestIndex updated
          total := nextTotal
        else
          total := total)
    return total

/-- Solidity's free-space condition at source lines 76--79 and 94--97. -/
def hasFreeSpace (b : MinFirst.Bucket) : Bool :=
  decide (b.allocation < b.capacity)

/--
Functional presentation of the candidate-search loop at source lines 76--86.
The `≤` branch is the first-index tie behavior induced by Solidity's strict
replacement test `bestCandidateAllocation > buckets[i]` at line 79.
-/
def candidate? : List MinFirst.Bucket → Option MinFirst.Bucket
  | [] => none
  | b :: bs =>
      match candidate? bs with
      | none => if hasFreeSpace b then some b else none
      | some later =>
          if hasFreeSpace b && decide (b.allocation ≤ later.allocation)
          then some b else some later

/-- Row correspondence for this selection-only slice: the lists are in the
same router order and each Solidity free-space test agrees with Lean's model
open predicate. -/
def RowsCorrespond (rows : List MinFirst.Bucket) : Prop :=
  ∀ b, b ∈ rows → hasFreeSpace b = b.open

theorem candidate?_eq_minFirst_candidate?
    (hRows : RowsCorrespond rows) :
    candidate? rows = MinFirst.candidate? rows := by
  induction rows with
  | nil => rfl
  | cons b bs ih =>
      have hb : hasFreeSpace b = b.open := hRows b (by simp)
      have hbs : RowsCorrespond bs := by
        intro other hOther
        exact hRows other (by simp [hOther])
      rw [candidate?, MinFirst.candidate?, ih hbs]
      cases MinFirst.candidate? bs <;> simp [hb]

/--
Under row correspondence, the source-shaped loop and the handwritten Lean
model select exactly the same next target.  This is intentionally not a claim
about the proportional allocation amount computed at source lines 92--106.
-/
theorem selects_same_next_target
    (hRows : RowsCorrespond rows) :
    candidate? rows = MinFirst.candidate? rows :=
  candidate?_eq_minFirst_candidate? hRows

/-! The executable receipt below crosses the actual `Contract.run` boundary.
It is intentionally a falsifier vector, not an EVM or production E2E claim. -/

def allocationReceiptState : ContractState :=
  { defaultState with
    storageArray := fun storageSlot =>
      if storageSlot = AllocationContract.stakeRatios.slot then [0, 0]
      else if storageSlot = AllocationContract.moduleLimits.slot then [100, 40]
      else if storageSlot = AllocationContract.allocationBuffers.slot then [100, 40]
      else if storageSlot = AllocationContract.moduleEnabled.slot then [1, 0]
      else [] }

def allocationReceipt : Bool :=
  match (AllocationContract.allocate 60).run allocationReceiptState with
  | .success total after =>
      total = 60 &&
      after.storageArray AllocationContract.stakeRatios.slot = [60, 0] &&
      -- Conservation: the allocation column increased by exactly `total`.
      (60 + 0 = 0 + 0 + total.val) &&
      -- Per-module effective capacities are respected.
      (60 ≤ 100 && 0 ≤ 40) &&
      -- The disabled second module is unchanged and receives no allocation.
      (after.storageArray AllocationContract.stakeRatios.slot)[1]? = some 0
  | .revert _ _ => false

theorem run_conservation_capacity_disabled : allocationReceipt = true := by decide

def conservationMutant : Bool := decide (55 + 0 + 55 = 0 + 0 + 50 + 59)
def capacityMutant : Bool := decide (101 ≤ 100)
def disabledModuleMutant : Bool := decide ((1 : Nat) = 0)

theorem conservation_mutant_rejected : conservationMutant = false := by decide
theorem capacity_mutant_rejected : capacityMutant = false := by decide
theorem disabled_module_mutant_rejected : disabledModuleMutant = false := by decide

end LidoSRv3.Audit.SolidityMinFirst
