import LidoSRv3.Audit.Source.MinFirstAmountCorrespondence
import Verity.Core.Model.Denote

/-!
# P-ALLOC-2 faithful memory-array transaction

This transaction models `MinFirstAllocationStrategy.allocate` from
`lidofinance/core@af095e48bbc1c3841c2c9936219c8461af01056b`, lines 30--107.
Unlike the earlier selected-row slice, both input arrays are read through the
compilation-model denotation of memory-backed `uint256[]` values.  The loop
recomputes the pinned candidate, equal-minimum count, next-level bound and
floor-sensitive `ceilDiv` amount on every iteration.  Successful buckets are
persisted through `writeMapUint`; totals use `writeSlot`.
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

/-- One source-shaped iteration. `fuel` is the initial demand value: positivity
of every successful amount makes it a sufficient structural bound. -/
def sourceDistribute : Nat → List Source.Row → Word → Word →
    Option (List Source.Row × Word × Word)
  | 0, rows, remaining, total => if remaining = 0 then some (rows, total, remaining) else none
  | fuel + 1, rows, remaining, total =>
      if remaining = 0 then some (rows, total, remaining) else
      match Source.candidate? rows with
      | none => some (rows, total, remaining)
      | some best => do
          let amount ← Source.checkedAmount rows remaining best
          if amount = 0 then none else
          let updated ← Verity.Stdlib.Math.safeAdd best.allocation amount
          let newTotal ← Verity.Stdlib.Math.safeAdd total amount
          let newRemaining ← Verity.Stdlib.Math.safeSub remaining amount
          sourceDistribute fuel (Source.replaceFirst best updated rows) newRemaining newTotal

/-- Transaction-side implementation.  This is deliberately separate from
`sourceDistribute`: the correspondence theorem below, rather than a shared
definition, is the boundary tying executable transaction control flow to the
pinned-source presentation. -/
def txDistribute : Nat → List Source.Row → Word → Word →
    Option (List Source.Row × Word × Word)
  | 0, rows, remaining, total => if remaining = 0 then some (rows, total, remaining) else none
  | fuel + 1, rows, remaining, total =>
      if remaining = 0 then some (rows, total, remaining) else
      match Source.candidate? rows with
      | none => some (rows, total, remaining)
      | some best => do
          let amount ← Source.checkedAmount rows remaining best
          if amount = 0 then none else
          let updated ← Verity.Stdlib.Math.safeAdd best.allocation amount
          let newTotal ← Verity.Stdlib.Math.safeAdd total amount
          let newRemaining ← Verity.Stdlib.Math.safeSub remaining amount
          txDistribute fuel (Source.replaceFirst best updated rows) newRemaining newTotal

theorem txDistribute_eq_sourceDistribute
    (fuel : Nat) (rows : List Source.Row) (remaining total : Word) :
    txDistribute fuel rows remaining total =
      sourceDistribute fuel rows remaining total := by
  induction fuel generalizing rows remaining total with
  | zero => simp [txDistribute, sourceDistribute]
  | succ fuel ih => simp [txDistribute, sourceDistribute, ih]

def writeBucketsState : Nat → List Word → ContractState → ContractState
  | _, [], state => state
  | index, value :: rest, state =>
      writeBucketsState (index + 1) rest (state.writeMapUint bucketsSlot index value)

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
      match txDistribute allocationSize.val rows allocationSize 0 with
      | none => .revert "MIN_FIRST_ARITHMETIC" snapshot
      | some (afterRows, total, remaining) =>
          let after := afterRows.map Source.Row.allocation
          let dirty := writeBucketsState 0 after snapshot
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
  | .success result state =>
      ⟨.committed, result.buckets, state.readSlot allocatedSlot,
        state.readSlot remainingSlot⟩
  | .revert _ _ => ⟨.reverted, before, 0, 0⟩

def sourceView (buckets capacities : List Word) (allocationSize : Word) : View :=
  if buckets.length != capacities.length then ⟨.reverted, buckets, 0, 0⟩ else
  let rows := (buckets.zip capacities).map fun p => Source.Row.mk p.1 p.2
  match sourceDistribute allocationSize.val rows allocationSize 0 with
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
    rw [txDistribute_eq_sourceDistribute]
    cases hRun : sourceDistribute allocationSize.val
        (List.map (fun p => Source.Row.mk p.1 p.2) (buckets.zip capacities))
        allocationSize 0 <;>
      simp [observe, allocatedSlot, remainingSlot,
        ContractState.readSlot_writeSlot_same,
        ContractState.readSlot_writeSlot_other]
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
