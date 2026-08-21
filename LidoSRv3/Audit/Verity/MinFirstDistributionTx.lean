import LidoSRv3.Audit.Source.MinFirstAmountCorrespondence
import Verity.Core.Model.Denote

/-!
# P-ALLOC-2 faithful memory-array transaction

This transaction models `MinFirstAllocationStrategy.allocate` /
`allocateToBestCandidate` from
`lidofinance/core@af095e48bbc1c3841c2c9936219c8461af01056b`, lines 30--107.
Unlike the earlier selected-row slice, both input arrays are read through the
compilation-model denotation of memory-backed `uint256[]` values.  The loop
is the source `while (allocated < allocationSize)` over
`allocateToBestCandidate`: scan, count, bound, `ceilDiv`, then
`buckets[bestCandidateIndex] += allocated`.  Successful buckets persist
through `writeArray`; totals use `writeSlot`.
-/

namespace LidoSRv3.Audit.Verity.MinFirstDistributionTx

open _root_.Verity
open Compiler.CompilationModel
open Compiler.CompilationModel.Denote
open LidoSRv3.Audit.MinFirstAllocation

abbrev Word := Source.Word

def bucketsBase : Nat := 0x1000
def capacitiesBase : Nat := 0x2000
def bucketsSlot : Nat := 20
def allocatedSlot : Nat := 21
def remainingSlot : Nat := 22

private def oracle : DenoteOracle where
  mappingSlot := fun _ _ => 0
  keccakMemorySlice := fun _ _ _ => 0

def arrayState (state : ContractState) (name : String) (base length : Nat) : DenoteState :=
  { world := state
    bindings := [(name ++ "_data_offset", base), (name ++ "_length", length)] }

def readWord (state : ContractState) (name : String) (base length index : Nat) : Option Word :=
  (evalExpr oracle [] (arrayState state name base length)
    (.memoryArrayElement name (.literal index))).map Verity.Core.Uint256.ofNat

def readArray (state : ContractState) (name : String) (base length : Nat) : Option (List Word) :=
  (List.range length).mapM (readWord state name base length)

def memoryFor (buckets capacities : List Word) : Nat → Word := fun offset =>
  if bucketsBase ≤ offset ∧ offset < bucketsBase + 32 * buckets.length ∧
      (offset - bucketsBase) % 32 = 0 then
    buckets.getD ((offset - bucketsBase) / 32) 0
  else if capacitiesBase ≤ offset ∧ offset < capacitiesBase + 32 * capacities.length ∧
      (offset - capacitiesBase) % 32 = 0 then
    capacities.getD ((offset - capacitiesBase) / 32) 0
  else 0

def stateFor (buckets capacities : List Word) (base : ContractState) : ContractState :=
  { base with memory := memoryFor buckets capacities }

/-- `buckets[bestCandidateIndex] += allocated` (source line 106). -/
def setAllocation (rows : List Source.Row) (i : Nat) (newAlloc : Word) :
    List Source.Row :=
  match rows[i]? with
  | none => rows
  | some r => rows.set i { r with allocation := newAlloc }

/-- One `allocateToBestCandidate` step: scan, compute the share, then mutate
the best index. A zero amount is the Solidity `break`. -/
def allocateToBestCandidate (rows : List Source.Row) (remaining : Word) :
    Option (List Source.Row × Word) :=
  match Source.candidate? rows with
  | none => some (rows, 0)
  | some best => do
      let amount ← Source.checkedAmount rows remaining best
      if amount = 0 then some (rows, 0) else
      let updated ← Verity.Stdlib.Math.safeAdd best.allocation amount
      match rows.idxOf? best with
      | none => none
      | some i => some (setAllocation rows i updated, amount)

/-- `while (allocated < allocationSize)` over `allocateToBestCandidate`.
`fuel` is the initial demand value: positivity of every successful amount
makes it a sufficient structural bound. -/
def allocateLoop : Nat → List Source.Row → Word → Word →
    Option (List Source.Row × Word × Word)
  | 0, rows, remaining, total => if remaining = 0 then some (rows, total, remaining) else none
  | fuel + 1, rows, remaining, total =>
      if remaining = 0 then some (rows, total, remaining) else
      match allocateToBestCandidate rows remaining with
      | none => none
      | some (after, amount) =>
          if amount = 0 then some (rows, total, remaining) else do
            let newTotal ← Verity.Stdlib.Math.safeAdd total amount
            let newRemaining ← Verity.Stdlib.Math.safeSub remaining amount
            allocateLoop fuel after newRemaining newTotal

/-- Independently stated source-side loop.  This deliberately copies the
pinned equations instead of aliasing `allocateLoop`, so transaction/source
agreement is a proved equation rather than definitional sharing. -/
def sourceAllocateLoop : Nat → List Source.Row → Word → Word →
    Option (List Source.Row × Word × Word)
  | 0, rows, remaining, total =>
      if remaining = 0 then some (rows, total, remaining) else none
  | fuel + 1, rows, remaining, total =>
      if remaining = 0 then some (rows, total, remaining) else
      match allocateToBestCandidate rows remaining with
      | none => none
      | some (after, amount) =>
          if amount = 0 then some (rows, total, remaining) else do
            let newTotal ← Verity.Stdlib.Math.safeAdd total amount
            let newRemaining ← Verity.Stdlib.Math.safeSub remaining amount
            sourceAllocateLoop fuel after newRemaining newTotal

theorem sourceAllocateLoop_eq_allocateLoop :
    ∀ fuel rows remaining total,
      sourceAllocateLoop fuel rows remaining total =
        allocateLoop fuel rows remaining total
  | 0, _, _, _ => rfl
  | fuel + 1, rows, remaining, total => by
      simp only [sourceAllocateLoop, allocateLoop]
      split
      · rfl
      · cases hStep : allocateToBestCandidate rows remaining with
        | none => rfl
        | some step =>
            rcases step with ⟨after, amount⟩
            simp only
            split
            · rfl
            · simp [sourceAllocateLoop_eq_allocateLoop fuel]

private theorem safeAdd_val {a b c : Word}
    (h : Verity.Stdlib.Math.safeAdd a b = some c) :
    c.val = a.val + b.val := by
  by_cases hOverflow : a.val + b.val > Verity.Core.MAX_UINT256
  · have hNone : Verity.Stdlib.Math.safeAdd a b = none := by
      simp [Verity.Stdlib.Math.safeAdd, hOverflow]
    rw [hNone] at h
    cases h
  · have hSome : Verity.Stdlib.Math.safeAdd a b = some (a + b) := by
      simp [Verity.Stdlib.Math.safeAdd, hOverflow]
    rw [hSome] at h
    obtain rfl := Option.some.inj h
    apply Verity.Core.Uint256.add_eq_of_lt
    rw [← Verity.Core.Uint256.max_uint256_succ_eq_modulus]
    omega

private theorem safeSub_val {a b c : Word}
    (h : Verity.Stdlib.Math.safeSub a b = some c) :
    c.val = a.val - b.val ∧ b.val ≤ a.val := by
  unfold Verity.Stdlib.Math.safeSub at h
  split at h
  · cases h
  · rename_i hLe
    obtain rfl := Option.some.inj h
    have hLe' : b.val ≤ a.val := by omega
    exact ⟨Verity.Core.Uint256.sub_eq_of_le hLe', hLe'⟩

/-- Every successful fuel-bounded execution of the full proportional allocation
loop conserves demand: the final allocated total plus the final remainder is the
initial total plus the initial remainder.  This covers every number of
successful mutation steps, as well as the zero-demand and zero-amount exits. -/
theorem allocateLoop_conserves_total :
    ∀ fuel rows remaining total after finalTotal finalRemaining,
      allocateLoop fuel rows remaining total =
        some (after, finalTotal, finalRemaining) →
      finalTotal.val + finalRemaining.val = total.val + remaining.val
  | 0, rows, remaining, total, after, finalTotal, finalRemaining => by
      simp only [allocateLoop]
      split
      · intro h
        simp only [Option.some.injEq, Prod.mk.injEq] at h
        rcases h with ⟨rfl, rfl, rfl⟩
        rfl
      · simp
  | fuel + 1, rows, remaining, total, after, finalTotal, finalRemaining => by
      simp only [allocateLoop]
      split
      · intro h
        simp only [Option.some.injEq, Prod.mk.injEq] at h
        rcases h with ⟨rfl, rfl, rfl⟩
        rfl
      · cases hStep : allocateToBestCandidate rows remaining with
        | none => simp
        | some step =>
            rcases step with ⟨nextRows, amount⟩
            simp only
            split
            · intro h
              simp only [Option.some.injEq, Prod.mk.injEq] at h
              rcases h with ⟨rfl, rfl, rfl⟩
              rfl
            · cases hAdd : Verity.Stdlib.Math.safeAdd total amount with
              | none => simp
              | some newTotal =>
                  cases hSub : Verity.Stdlib.Math.safeSub remaining amount with
                  | none => simp
                  | some newRemaining =>
                      simp only [Option.bind_eq_bind, Option.bind_some]
                      intro hRun
                      have hConserve := allocateLoop_conserves_total fuel nextRows
                        newRemaining newTotal after finalTotal finalRemaining hRun
                      have hAddVal := safeAdd_val hAdd
                      have hSubVal := safeSub_val hSub
                      omega

/-- Persist allocated buckets as a `uint256[]`-shaped storage array. -/
def persistBuckets (buckets : List Word) (state : ContractState) : ContractState :=
  state.writeArray bucketsSlot buckets

structure Result where
  buckets : List Word
  allocated : Word
  remaining : Word
  deriving DecidableEq, Repr

/-- Executable transaction. A length mismatch or checked-arithmetic failure
reverts. `failAfterWrites` is a test hook placed after all bucket writes; it
proves rollback even after intermediate effects. -/
def allocate (bucketCount capacityCount : Nat) (allocationSize : Word)
    (failAfterWrites : Bool := false) : Contract Result := fun snapshot =>
  if bucketCount != capacityCount then .revert "ARRAY_LENGTH_MISMATCH" snapshot else
  match readArray snapshot "buckets" bucketsBase bucketCount,
      readArray snapshot "capacities" capacitiesBase capacityCount with
  | some buckets, some capacities =>
      let rows := (buckets.zip capacities).map fun p => Source.Row.mk p.1 p.2
      match allocateLoop allocationSize.val rows allocationSize 0 with
      | none => .revert "MIN_FIRST_ARITHMETIC" snapshot
      | some (afterRows, total, remaining) =>
          let after := afterRows.map Source.Row.allocation
          let dirty := persistBuckets after snapshot
          let dirty := (dirty.writeSlot allocatedSlot total).writeSlot remainingSlot remaining
          if failAfterWrites then .revert "INJECTED_AFTER_WRITES" dirty
          else .success ⟨after, total, remaining⟩ dirty
  | _, _ => .revert "MEMORY_ARRAY_DECODE" snapshot

inductive Status where | committed | reverted deriving DecidableEq, Repr

structure View where
  status : Status
  buckets : List Word
  allocated : Word
  remaining : Word
  deriving DecidableEq, Repr

def observe (before : List Word) : ContractResult Result → View
  | .success _ state =>
      ⟨.committed, state.readArray bucketsSlot, state.readSlot allocatedSlot,
        state.readSlot remainingSlot⟩
  | .revert _ _ => ⟨.reverted, before, 0, 0⟩

def sourceView (buckets capacities : List Word) (allocationSize : Word) : View :=
  if buckets.length != capacities.length then ⟨.reverted, buckets, 0, 0⟩ else
  let rows := (buckets.zip capacities).map fun p => Source.Row.mk p.1 p.2
  match sourceAllocateLoop allocationSize.val rows allocationSize 0 with
  | none => ⟨.reverted, buckets, 0, 0⟩
  | some (after, total, remaining) =>
      ⟨.committed, after.map Source.Row.allocation, total, remaining⟩

/-- Composed faithful-plane theorem: the real memory-array transaction has the
same outcome observables as the independently stated pinned-source loop. -/
theorem verity_tx_simulates_pinned_source
    (buckets capacities : List Word) (allocationSize : Word) (state : ContractState)
    (hBuckets : readArray state "buckets" bucketsBase buckets.length = some buckets)
    (hCapacities : readArray state "capacities" capacitiesBase capacities.length = some capacities) :
    observe buckets ((allocate buckets.length capacities.length allocationSize).run
      state) = sourceView buckets capacities allocationSize := by
  by_cases hLen : buckets.length = capacities.length
  · have hBne : (buckets.length != capacities.length) = false := by simp [hLen]
    unfold Contract.run allocate sourceView
    simp only [hBne, Bool.false_eq_true, ↓reduceIte, hBuckets, hCapacities]
    rw [sourceAllocateLoop_eq_allocateLoop]
    cases hRun : allocateLoop allocationSize.val
        (List.map (fun p => Source.Row.mk p.1 p.2) (buckets.zip capacities))
        allocationSize 0 <;>
      simp [observe, persistBuckets, allocatedSlot, remainingSlot,
        ContractState.readArray, ContractState.writeArray,
        ContractState.readSlot_writeSlot_same,
        ContractState.readSlot_writeSlot_other,
        ContractState.storageArray_writeSlot]
  · unfold Contract.run allocate sourceView
    simp [hLen, observe]

/-- Any failure, including the injected failure after all intermediate writes,
returns the exact pre-transaction snapshot. -/
theorem revert_restores_snapshot
    (bucketCount capacityCount : Nat) (allocationSize : Word) (inject : Bool)
    (state rollback : ContractState) (reason : String)
    (h : (allocate bucketCount capacityCount allocationSize inject).run state =
      .revert reason rollback) : rollback = state := by
  unfold Contract.run at h
  split at h <;> simp_all

end LidoSRv3.Audit.Verity.MinFirstDistributionTx
