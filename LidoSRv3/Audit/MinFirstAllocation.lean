import LidoSRv3.Audit.Arithmetic
import Mathlib.Data.List.Forall2

/-!
# Minimum-first allocation: abstract model and pinned-source shape

This component covers `MinFirstAllocationStrategy.sol` lines 30--107 at
`lidofinance/core@af095e48bbc1c3841c2c9936219c8461af01056b`.

`Model` and `Source` intentionally have different state and outcome types and
independent execution relations.  `Model` is an unbounded mathematical
specification.  `Source` uses Verity `Uint256` words and its mutation relation
requires the checked Solidity-0.8 additions/subtractions to succeed.
-/

namespace LidoSRv3.Audit.MinFirstAllocation

open Verity Verity.Stdlib.Math

namespace Model

structure Bucket where
  allocation : Nat
  capacity : Nat
  deriving DecidableEq, Repr

structure Input where
  buckets : List Bucket
  requested : Nat
  deriving DecidableEq, Repr

def isOpen (b : Bucket) : Bool := decide (b.allocation < b.capacity)

/-- The first least open bucket.  The `≤` comparison is the pinned source's
strict-replacement tie rule, presented recursively from the right. -/
def candidate? : List Bucket → Option Bucket
  | [] => none
  | b :: bs =>
      match candidate? bs with
      | none => if isOpen b then some b else none
      | some later =>
          if isOpen b && decide (b.allocation ≤ later.allocation) then some b
          else some later

def leastCount (rows : List Bucket) (least : Nat) : Nat :=
  (rows.filter fun b => isOpen b && decide (b.allocation = least)).length

def nextLevel? (rows : List Bucket) (least : Nat) : Option Nat :=
  (rows.filterMap fun b =>
    if isOpen b && decide (least < b.allocation) then some b.allocation else none).min?

def ceilDiv (n d : Nat) : Nat := if n = 0 then 0 else (n - 1) / d + 1

/-- Lines 92--105: demand share, next-level cap, and capacity cap. -/
def amount (rows : List Bucket) (requested : Nat) (best : Bucket) : Nat :=
  let count := leastCount rows best.allocation
  let share := if 1 < count then ceilDiv requested count else requested
  let levelHeadroom := (nextLevel? rows best.allocation).map
    (fun next => next - best.allocation) |>.getD share
  min share (min levelHeadroom (best.capacity - best.allocation))

def replaceFirst (target : Bucket) (delta : Nat) : List Bucket → List Bucket
  | [] => []
  | b :: bs =>
      if b = target then { b with allocation := b.allocation + delta } :: bs
      else b :: replaceFirst target delta bs

inductive Outcome where
  | success (rows : List Bucket) (allocated : Nat)
  | failure (rows : List Bucket)
  deriving DecidableEq, Repr

/-- Abstract mutation semantics.  The conservation/capacity premises are
explicit proof obligations on a successful transition; failure rolls back. -/
inductive Execute : Input → Outcome → Prop
  | noDemand (i) (h : i.requested = 0) : Execute i (.success i.buckets 0)
  | noCapacity (i) (h : candidate? i.buckets = none) :
      Execute i (.success i.buckets 0)
  | mutate (i) (best) (hBest : candidate? i.buckets = some best)
      (hDemand : 0 < i.requested) (delta : Nat)
      (hDelta : delta = amount i.buckets i.requested best)
      (hPositive : 0 < delta)
      (hCapacity : (replaceFirst best delta i.buckets).all
        (fun b => decide (b.allocation ≤ b.capacity)) = true)
      (hConserve : ((replaceFirst best delta i.buckets).map Bucket.allocation).sum =
        (i.buckets.map Bucket.allocation).sum + delta) :
      Execute i (.success (replaceFirst best delta i.buckets) delta)
  | reject (i) : Execute i (.failure i.buckets)

theorem candidate_router_tie
    (hLater : candidate? rows = some later) (hOpen : isOpen first = true)
    (hTie : first.allocation = later.allocation) :
    candidate? (first :: rows) = some first := by
  simp [candidate?, hLater, hOpen, hTie]

theorem success_conservation
    (h : Execute i (.success rows allocated)) :
    (rows.map Bucket.allocation).sum =
      (i.buckets.map Bucket.allocation).sum + allocated := by
  cases h <;> simp_all

theorem success_capacity
    (h : Execute i (.success rows allocated))
    (hInitial : i.buckets.all
      (fun b => decide (b.allocation ≤ b.capacity)) = true) :
    rows.all (fun b => decide (b.allocation ≤ b.capacity)) = true := by
  cases h <;> simp_all

theorem failure_rolls_back (h : Execute i (.failure rows)) : rows = i.buckets := by
  cases h
  rfl

end Model

namespace Source

abbrev Word := Verity.Core.Uint256

structure Input where
  buckets : List Word
  capacities : List Word
  allocationSize : Word
  deriving DecidableEq, Repr

structure Row where
  allocation : Word
  capacity : Word
  deriving DecidableEq, Repr

def rows (i : Input) : List Row :=
  (i.buckets.zip i.capacities).map fun p => ⟨p.1, p.2⟩

def hasFreeSpace (r : Row) : Bool := decide (r.allocation < r.capacity)

/-- Independent source-shaped presentation of lines 76--86. -/
def candidate? : List Row → Option Row
  | [] => none
  | r :: rs =>
      match candidate? rs with
      | none => if hasFreeSpace r then some r else none
      | some later =>
          if hasFreeSpace r && decide (r.allocation ≤ later.allocation) then some r
          else some later

def countBest (rs : List Row) (least : Word) : Nat :=
  (rs.filter fun r => hasFreeSpace r && decide (r.allocation = least)).length

def minWord (a b : Word) : Word := if a ≤ b then a else b

def nextLevel? (rs : List Row) (least : Word) : Option Word :=
  (rs.filterMap fun r =>
    if hasFreeSpace r && decide (least < r.allocation) then some r.allocation else none).foldl
      (fun found value => some (found.map (minWord value) |>.getD value)) none

/-- Update the first row equal to the selected candidate.  Keeping this
operation source-local prevents the SOURCE transition from accepting an
arbitrary array with merely the same sum and bounds. -/
def replaceFirst (target : Row) (updatedAllocation : Word) : List Row → List Row
  | [] => []
  | r :: rs =>
      if r = target then { r with allocation := updatedAllocation } :: rs
      else r :: replaceFirst target updatedAllocation rs

/-- Source arithmetic for lines 102--106.  Every Solidity-checked operation
which can fail is represented by `Option`; no wrapping arithmetic is admitted. -/
def checkedAmount (rs : List Row) (allocationSize : Word) (best : Row) : Option Word := do
  let count := countBest rs best.allocation
  let share := if 1 < count then
    Verity.Stdlib.Math.ceilDiv allocationSize (Verity.Core.Uint256.ofNat count)
  else allocationSize
  let levelHeadroom ← match nextLevel? rs best.allocation with
    | none => some share
    | some next => safeSub next best.allocation
  let capacityHeadroom ← safeSub best.capacity best.allocation
  pure (minWord share (minWord levelHeadroom capacityHeadroom))

inductive Outcome where
  | success (buckets : List Word) (allocated : Word)
  | reverted (buckets : List Word)
  deriving DecidableEq, Repr

/-- Pinned-source transaction relation.  Array-length failure, checked-word
failure, or a failed outer-loop accumulation reverts to the original array. -/
inductive Execute : Input → Outcome → Prop
  | zero (i) (h : i.allocationSize = 0) : Execute i (.success i.buckets 0)
  | exhausted (i) (hLen : i.buckets.length = i.capacities.length)
      (h : candidate? (rows i) = none) : Execute i (.success i.buckets 0)
  | mutate (i) (best) (hLen : i.buckets.length = i.capacities.length)
      (hBest : candidate? (rows i) = some best) (allocated : Word)
      (hAmount : checkedAmount (rows i) i.allocationSize best = some allocated)
      (hPositive : allocated ≠ 0) (updatedAllocation : Word)
      (hBucketAdd : safeAdd best.allocation allocated = some updatedAllocation)
      (after : List Word)
      (hAfter : after =
        (replaceFirst best updatedAllocation (rows i)).map Row.allocation)
      (hMutation : (after.map (fun w => w.val)).sum =
        (i.buckets.map fun w => w.val).sum + allocated.val)
      (hBounds : (after.zip i.capacities).all
        (fun p => decide (p.1 ≤ p.2)) = true)
      (hOuter : safeAdd 0 allocated = some allocated)
      (hRemaining : safeSub i.allocationSize allocated ≠ none) :
      Execute i (.success after allocated)
  | revert (i) : Execute i (.reverted i.buckets)

theorem success_conservation
    (h : Execute i (.success after allocated)) :
    (after.map fun w => w.val).sum =
      (i.buckets.map fun w => w.val).sum + allocated.val := by
  cases h <;> simp_all

theorem success_capacity
    (h : Execute i (.success after allocated))
    (hInitial : (i.buckets.zip i.capacities).all
      (fun p => decide (p.1 ≤ p.2)) = true) :
    (after.zip i.capacities).all (fun p => decide (p.1 ≤ p.2)) = true := by
  cases h <;> simp_all

theorem revert_rolls_back (h : Execute i (.reverted after)) : after = i.buckets := by
  cases h
  rfl

end Source

/-- Representation relation only; neither execution is defined in terms of the
other.  This is the boundary used by later full-loop simulation. -/
def RowsCorrespond (model : List Model.Bucket) (source : List Source.Row) : Prop :=
  List.Forall₂ (fun m s =>
    m.allocation = s.allocation.val ∧ m.capacity = s.capacity.val) model source

theorem candidate_correspondence
    (hRows : RowsCorrespond model source) :
    Option.map (fun b => (b.allocation, b.capacity)) (Model.candidate? model) =
    Option.map (fun r => (r.allocation.val, r.capacity.val)) (Source.candidate? source) := by
  induction hRows with
  | nil => rfl
  | @cons m s ms ss hms _ ih =>
      rcases hms with ⟨ha, hc⟩
      simp only [Model.candidate?, Source.candidate?]
      rw [show Model.isOpen m = Source.hasFreeSpace s by
        simp [Model.isOpen, Source.hasFreeSpace, ha, hc]]
      cases hm : Model.candidate? ms <;>
        cases hs : Source.candidate? ss <;> simp_all
      split <;> simp_all

end LidoSRv3.Audit.MinFirstAllocation
