import LidoSRv3.Audit.Source.MinFirstAmountCorrespondence
import Verity.Core
import Verity.Macro
import Contracts.Common

/-!
# P-ALLOC-2 amounts: Verity transaction plane

`MinFirstAllocationStrategy.allocateToBestCandidate` at
`lidofinance/core@17005714f151e5502c559932319a3f2f74ac2436`, lines 102--106,
once the best candidate has been selected:

```solidity
allocated = Math256.min(
    bestCandidatesCount > 1 ? Math256.ceilDiv(allocationSize, bestCandidatesCount) : allocationSize,
    Math256.min(allocationSizeUpperBound, capacities[bestCandidateIndex]) - bestCandidateAllocation
);
buckets[bestCandidateIndex] += allocated;
```

together with the two accumulator updates of the calling `allocate` loop at
lines 30--44:

```solidity
allocatedToBestCandidate = allocateToBestCandidate(buckets, capacities, allocationSize - allocated); // 37
allocated += allocatedToBestCandidate;                                                               // 41
```

The typed contract below executes those statements with `Verity.Contract.run`,
using Verity's Solidity-0.8 panic arithmetic for the subtraction at line 104,
the compound assignment at line 106, and the outer loop's line 41 accumulator
and line 37 remaining-demand arithmetic.  Storage slots 0 and 1 hold the best
candidate's `buckets[bestCandidateIndex]` and `capacities[bestCandidateIndex]`,
slot 2 the outer loop's `allocated`, and slot 3 its `allocationSize -
allocated`.  The candidate search, the best-candidate count and
`allocationSizeUpperBound` remain source-plane facts, supplied here as the two
word arguments; they are tied back to the pinned source by
`LidoSRv3.Audit.Source.MinFirstAmountCorrespondence`.

This is a transaction-plane claim about one contract's storage under
`Contract.run`.  Generated Yul, runtime bytecode and the memory-array layout of
`buckets`/`capacities` remain open.
-/

namespace LidoSRv3.Audit.Verity.MinFirstAmountTx

open _root_.Verity
open _root_.Contracts
open _root_.Verity.Stdlib.Math
open LidoSRv3.Audit.MinFirstAllocation

verity_contract MinFirstAllocationTx where
  storage
    bucket : Uint256 := slot 0
    capacity : Uint256 := slot 1
    allocatedActual : Uint256 := slot 2
    remaining : Uint256 := slot 3

  function allocateToBestCandidate (share : Uint256, upperBound : Uint256) : Uint256 := do
    let b ← getStorage bucket
    let c ← getStorage capacity
    let bound := min upperBound c
    let headroom ← subPanic bound b
    let amount := min share headroom
    let newBucket ← addPanic b amount
    setStorage bucket newBucket
    let total ← getStorage allocatedActual
    let newTotal ← addPanic total amount
    setStorage allocatedActual newTotal
    let size ← getStorage remaining
    let newRemaining ← subPanic size amount
    setStorage remaining newRemaining
    return amount

/-! ## Bridging the typed program to the pinned source words -/

/-- `Contracts.min`, which the macro emits for `min`, is the same word operation
as the source plane's `Source.minWord`. -/
theorem contracts_min_eq_minWord (a b : Source.Word) :
    _root_.Contracts.min a b = Source.minWord a b := rfl

/-- The storage a single `allocateToBestCandidate` step runs against: the best
candidate's row in slots 0/1, the accumulator in slot 2, the outer loop's
remaining `allocationSize` in slot 3. -/
def stateFor (best : Source.Row) (total remaining : Source.Word)
    (base : ContractState) : ContractState :=
  (((base.writeSlot 0 best.allocation
        ).writeSlot 1 best.capacity
        ).writeSlot 2 total
        ).writeSlot 3 remaining

inductive TxStatus where
  | committed
  | reverted
  deriving DecidableEq, Repr

structure TxView where
  status : TxStatus
  allocated : Source.Word
  bucket : Source.Word
  total : Source.Word
  remaining : Source.Word
  deriving DecidableEq, Repr

/-- Transaction-plane observation: the returned word plus the three mutated
slots, read off whatever state `Contract.run` settles on. -/
def observe (result : ContractResult Uint256) : TxView :=
  match result with
  | .success a s => ⟨.committed, a, s.storage 0, s.storage 2, s.storage 3⟩
  | .revert _ s => ⟨.reverted, 0, s.storage 0, s.storage 2, s.storage 3⟩

/-- The same observation predicted independently by the pinned source words. -/
def sourceView (rs : List Source.Row) (allocationSize : Source.Word)
    (best : Source.Row) (total : Source.Word) : TxView :=
  match Source.checkedAmount rs allocationSize best with
  | some w => ⟨.committed, w, best.allocation + w, total + w, allocationSize - w⟩
  | none => ⟨.reverted, 0, best.allocation, total, allocationSize⟩

/-- Headline transaction-plane theorem for P-ALLOC-2 amounts.

Running the typed contract on a best-candidate row, fed the two source-plane
words (`sourceShare` for line 103's `bestCandidatesCount > 1 ? ceilDiv(...) :
allocationSize`, and `upperBound` for the `allocationSizeUpperBound` computed at
lines 93--100), commits and produces exactly the word and the three storage
mutations that `Source.checkedAmount`, source line 106 and the outer loop's
lines 41 and 37 predict.

The candidate premise binds this row to the result of the pinned candidate
scan. The remaining premises are honest word-size side conditions: `hLen` bounds the
candidate array by the word size (so `bestCandidatesCount` is representable),
and `hTotal` says the accumulator plus the remaining demand fits in one word. -/
theorem tx_observes_source
    (rs : List Source.Row) (allocationSize : Source.Word) (best : Source.Row)
    (total : Source.Word) (base : ContractState)
    (_hSelected : Source.candidate? rs = some best)
    (hOpen : Source.hasFreeSpace best = true)
    (hLen : rs.length < Core.Uint256.modulus)
    (hTotal : total.val + allocationSize.val ≤ Core.MAX_UINT256) :
    observe ((MinFirstAllocationTx.allocateToBestCandidate
        (sourceShare rs allocationSize best) (upperBound rs best)).run
      (stateFor best total allocationSize base)) =
      sourceView rs allocationSize best total := by
  set w := Source.minWord (sourceShare rs allocationSize best)
    (Source.minWord (upperBound rs best) best.capacity - best.allocation) with hw
  have hAmount : Source.checkedAmount rs allocationSize best = some w :=
    checkedAmount_isSome rs allocationSize hOpen
  have hHead : safeSub (Source.minWord (upperBound rs best) best.capacity) best.allocation =
      some (Source.minWord (upperBound rs best) best.capacity - best.allocation) :=
    safeSub_isSome_of_le (allocation_le_minUpper hOpen)
  have hBucket : safeAdd best.allocation w = some (best.allocation + w) :=
    checkedAmount_safeAdd hOpen hAmount
  have hSize : w.val ≤ allocationSize.val := checkedAmount_le_size hOpen hLen hAmount
  have hAcc : safeAdd total w = some (total + w) := by
    have hle : total.val + w.val ≤ Verity.Stdlib.Math.MAX_UINT256 := by
      show total.val + w.val ≤ Core.MAX_UINT256
      omega
    simp [safeAdd, Nat.not_lt.mpr hle]
  have hRem : safeSub allocationSize w = some (allocationSize - w) :=
    safeSub_isSome_of_le hSize
  simp [observe, sourceView, hAmount, stateFor,
    MinFirstAllocationTx.allocateToBestCandidate,
    MinFirstAllocationTx.bucket, MinFirstAllocationTx.capacity,
    MinFirstAllocationTx.allocatedActual, MinFirstAllocationTx.remaining,
    _root_.Verity.Contract.run, _root_.Verity.getStorage, _root_.Verity.setStorage,
    ContractState.readSlot,
    ContractState.storage_writeSlot_same, ContractState.storage_writeSlot_other,
    _root_.Verity.bind, _root_.Verity.pure, Bind.bind, Pure.pure,
    _root_.Verity.Stdlib.Math.subPanic, _root_.Verity.Stdlib.Math.addPanic,
    _root_.Verity.Stdlib.Math.requireSomeUint,
    contracts_min_eq_minWord, hHead, hBucket, hAcc, hRem, ← hw]

/-- Transaction-plane restatement of the source-plane invariants: the step is
strictly progressing, never breaches the candidate's capacity, and never
underflows the outer loop's remaining demand. -/
theorem tx_step_is_safe
    (rs : List Source.Row) (allocationSize : Source.Word) (best : Source.Row)
    (total : Source.Word) (base : ContractState)
    (hSelected : Source.candidate? rs = some best)
    (hOpen : Source.hasFreeSpace best = true)
    (hLen : rs.length < Core.Uint256.modulus)
    (hSize : allocationSize.val ≠ 0)
    (hTotal : total.val + allocationSize.val ≤ Core.MAX_UINT256) :
    let tx := observe ((MinFirstAllocationTx.allocateToBestCandidate
        (sourceShare rs allocationSize best) (upperBound rs best)).run
      (stateFor best total allocationSize base))
    tx.status = .committed ∧
      0 < tx.allocated.val ∧
      tx.allocated.val ≤ allocationSize.val ∧
      tx.bucket.val = best.allocation.val + tx.allocated.val ∧
      tx.bucket.val ≤ best.capacity.val ∧
      tx.total.val = total.val + tx.allocated.val ∧
      tx.remaining.val + tx.allocated.val = allocationSize.val := by
  have hobs := tx_observes_source rs allocationSize best total base hSelected hOpen hLen hTotal
  have hAmount : Source.checkedAmount rs allocationSize best =
      some (Source.minWord (sourceShare rs allocationSize best)
        (Source.minWord (upperBound rs best) best.capacity - best.allocation)) :=
    checkedAmount_isSome rs allocationSize hOpen
  have hpos := checkedAmount_pos hOpen hLen hSize hAmount
  have hle := checkedAmount_le_size hOpen hLen hAmount
  have hhead := checkedAmount_le_headroom hOpen hAmount
  have hcap : best.capacity.val < Core.Uint256.modulus := best.capacity.isLt
  have hmax : Core.MAX_UINT256 + 1 = Core.Uint256.modulus :=
    Core.Uint256.max_uint256_succ_eq_modulus
  have hbucket := val_add_of_lt (a := best.allocation)
    (b := Source.minWord (sourceShare rs allocationSize best)
      (Source.minWord (upperBound rs best) best.capacity - best.allocation))
    (by omega)
  have hacc := val_add_of_lt (a := total)
    (b := Source.minWord (sourceShare rs allocationSize best)
      (Source.minWord (upperBound rs best) best.capacity - best.allocation))
    (by omega)
  simp only [hobs, sourceView, hAmount]
  refine ⟨trivial, hpos, hle, hbucket, ?_, hacc, ?_⟩
  · rw [hbucket]; omega
  · rw [val_sub_of_le hle]; omega

/-- The checked subtraction at source line 104 is the only revert in this slice,
and `Contract.run` rolls the transaction back to the exact pre-state. -/
theorem tx_underflow_reverts_to_snapshot
    (share upperBoundArg : Source.Word) (best : Source.Row)
    (total remaining : Source.Word) (base : ContractState)
    (h : (Source.minWord upperBoundArg best.capacity).val < best.allocation.val) :
    (MinFirstAllocationTx.allocateToBestCandidate share upperBoundArg).run
        (stateFor best total remaining base) =
      .revert "Panic(0x11): arithmetic underflow" (stateFor best total remaining base) := by
  simp [stateFor, MinFirstAllocationTx.allocateToBestCandidate,
    MinFirstAllocationTx.bucket, MinFirstAllocationTx.capacity,
    _root_.Verity.Contract.run, _root_.Verity.getStorage,
    ContractState.readSlot,
    ContractState.storage_writeSlot_same, ContractState.storage_writeSlot_other,
    _root_.Verity.bind, Bind.bind, Pure.pure,
    _root_.Verity.Stdlib.Math.subPanic, _root_.Verity.Stdlib.Math.requireSomeUint,
    _root_.Verity.require, contracts_min_eq_minWord, safeSub, h]

/-- Every revert of this transaction restores the snapshot, stated directly on
`Contract.run` rather than on the observation. -/
theorem tx_revert_restores_snapshot
    (share upperBoundArg : Source.Word) (state rollback : ContractState) (reason : String)
    (h : (MinFirstAllocationTx.allocateToBestCandidate share upperBoundArg).run state =
      .revert reason rollback) : rollback = state := by
  unfold Contract.run at h
  split at h <;> simp_all

end LidoSRv3.Audit.Verity.MinFirstAmountTx
