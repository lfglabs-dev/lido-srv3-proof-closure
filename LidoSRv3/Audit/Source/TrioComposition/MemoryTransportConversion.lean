import LidoSRv3.Audit.Source.TrioComposition.MemoryTransport
import LidoSRv3.Audit.Source.TrioComposition.ConversionBridge

/-! Parent conversion executes ordered indexed memory reads and writes. The two
array regions must be disjoint; no post-state memory relation is assumed.
Reverted internal memory is unobservable. The word-memory/byte-memory compiler
refinement and bounded allocator pointers remain separate local obligations. -/
namespace LidoSRv3.Audit.Source.TrioComposition.MemoryTransportConversion
open TrioAlloc1
open MemoryTransport
open TrioAlloc2 (Result)
open TrioAlloc2.ParentConversion (Arrays)

def read (memory : MemoryWords) (pointer index : Nat) : Result Word :=
  if index < (memory pointer).val then .ok (memory (pointer+32*(index+1)))
  else .error .arrayBounds

theorem read_related (memory : MemoryWords) (pointer index : Nat) (values : List Word)
    (related : ArrayAt memory pointer values) :
    read memory pointer index = TrioAlloc2.ParentConversion.read values index := by
  unfold read TrioAlloc2.ParentConversion.read
  rw [related.1]
  by_cases bound : index < values.length
  · rw [if_pos bound, List.getElem?_eq_getElem bound, related.2 ⟨index,bound⟩]
    rfl
  · rw [if_neg bound,List.getElem?_eq_none (by omega)]

def ArraysAt (memory : MemoryWords) (ap rp : Nat) (arrays : Arrays) : Prop :=
  ArrayAt memory ap arrays.allocated ∧ ArrayAt memory rp arrays.newAllocations ∧
  Disjoint ap arrays.allocated.length rp arrays.newAllocations.length

def Relates (ap rp : Nat) : Result MemoryWords → Result Arrays → Prop
  | .error left, .error right => left = right
  | .ok memory, .ok arrays => ArraysAt memory ap rp arrays
  | _, _ => False

def positiveRow (memory : MemoryWords) (ap rp index : Nat) (unit : Word) : Result MemoryWords := do
  let next ← read memory rp index
  let previous ← read memory ap index
  let delta ← TrioAlloc2.checkedSub next previous
  let scaledDelta ← TrioAlloc2.checkedMul delta unit
  let afterDelta := storeElement memory ap index scaledDelta
  let nextAgain ← read afterDelta rp index
  let scaledNext ← TrioAlloc2.checkedMul nextAgain unit
  .ok (storeElement afterDelta rp index scaledNext)

def zeroRow (memory : MemoryWords) (ap rp index : Nat) (unit : Word) : Result MemoryWords := do
  let previous ← read memory ap index
  let scaled ← TrioAlloc2.checkedMul previous unit
  let _ ← read memory rp index
  let afterNext := storeElement memory rp index scaled
  let _ ← read afterNext ap index
  .ok (storeElement afterNext ap index TrioAlloc2.zero)

def positiveStep (index : Nat) (unit : Word) (arrays : Arrays) : Result Arrays := do
  let next ← TrioAlloc2.ParentConversion.read arrays.newAllocations index
  let previous ← TrioAlloc2.ParentConversion.read arrays.allocated index
  let delta ← TrioAlloc2.checkedSub next previous
  let scaledDelta ← TrioAlloc2.checkedMul delta unit
  let afterDelta := { arrays with allocated := arrays.allocated.set index scaledDelta }
  let nextAgain ← TrioAlloc2.ParentConversion.read afterDelta.newAllocations index
  let scaledNext ← TrioAlloc2.checkedMul nextAgain unit
  .ok { afterDelta with newAllocations := afterDelta.newAllocations.set index scaledNext }

def zeroStep (index : Nat) (unit : Word) (arrays : Arrays) : Result Arrays := do
  let previous ← TrioAlloc2.ParentConversion.read arrays.allocated index
  let scaled ← TrioAlloc2.checkedMul previous unit
  let _ ← TrioAlloc2.ParentConversion.read arrays.newAllocations index
  let afterNext := { arrays with newAllocations := arrays.newAllocations.set index scaled }
  let _ ← TrioAlloc2.ParentConversion.read afterNext.allocated index
  .ok { afterNext with allocated := afterNext.allocated.set index TrioAlloc2.zero }

theorem store_old (memory : MemoryWords) (ap rp : Nat) (arrays : Arrays)
    (related : ArraysAt memory ap rp arrays) (index : Fin arrays.allocated.length) (value : Word) :
    ArraysAt (storeElement memory ap index.val value) ap rp
      {arrays with allocated := arrays.allocated.set index.val value} := by
  refine ⟨storeElement_related memory ap arrays.allocated index value related.1,
    storeElement_frame memory ap arrays.allocated.length rp arrays.newAllocations index value
      related.2.2 related.2.1, ?_⟩
  simpa only [List.length_set] using related.2.2

theorem store_new (memory : MemoryWords) (ap rp : Nat) (arrays : Arrays)
    (related : ArraysAt memory ap rp arrays) (index : Fin arrays.newAllocations.length) (value : Word) :
    ArraysAt (storeElement memory rp index.val value) ap rp
      {arrays with newAllocations := arrays.newAllocations.set index.val value} := by
  refine ⟨storeElement_frame memory rp arrays.newAllocations.length ap arrays.allocated index value
      (Or.symm related.2.2) related.1,
    storeElement_related memory rp arrays.newAllocations index value related.2.1, ?_⟩
  simpa only [List.length_set] using related.2.2

theorem positiveRow_related (memory : MemoryWords) (ap rp index : Nat) (unit : Word)
    (arrays : Arrays) (related : ArraysAt memory ap rp arrays) :
    Relates ap rp (positiveRow memory ap rp index unit) (positiveStep index unit arrays) := by
  unfold positiveRow positiveStep
  rw [read_related memory rp index arrays.newAllocations related.2.1,
    read_related memory ap index arrays.allocated related.1]
  by_cases nextBound : index < arrays.newAllocations.length
  · simp only [TrioAlloc2.ParentConversion.read, List.getElem?_eq_getElem nextBound,
      bind,Except.bind]
    by_cases oldBound : index < arrays.allocated.length
    · simp only [List.getElem?_eq_getElem oldBound]
      cases sub : TrioAlloc2.checkedSub arrays.newAllocations[index] arrays.allocated[index] with
      | error reason => simp [Relates]
      | ok delta =>
        simp only []
        cases mul : TrioAlloc2.checkedMul delta unit with
        | error reason => simp [Relates]
        | ok scaledDelta =>
          simp only []
          have afterDelta := store_old memory ap rp arrays related ⟨index,oldBound⟩ scaledDelta
          rw [read_related _ rp index arrays.newAllocations afterDelta.2.1]
          simp only [TrioAlloc2.ParentConversion.read,List.getElem?_eq_getElem nextBound]
          cases nextMul : TrioAlloc2.checkedMul arrays.newAllocations[index] unit with
          | error reason => simp [Relates]
          | ok scaledNext =>
            exact store_new _ ap rp _ afterDelta ⟨index,nextBound⟩ scaledNext
    · simp only [List.getElem?_eq_none (by omega : arrays.allocated.length ≤ index)]
      rfl
  · simp only [TrioAlloc2.ParentConversion.read,
      List.getElem?_eq_none (by omega : arrays.newAllocations.length ≤ index), bind,Except.bind]
    rfl

theorem zeroRow_related (memory : MemoryWords) (ap rp index : Nat) (unit : Word)
    (arrays : Arrays) (related : ArraysAt memory ap rp arrays) :
    Relates ap rp (zeroRow memory ap rp index unit) (zeroStep index unit arrays) := by
  unfold zeroRow zeroStep
  rw [read_related memory ap index arrays.allocated related.1,
    read_related memory rp index arrays.newAllocations related.2.1]
  by_cases oldBound : index < arrays.allocated.length
  · simp only [TrioAlloc2.ParentConversion.read,List.getElem?_eq_getElem oldBound,bind,Except.bind]
    cases mul : TrioAlloc2.checkedMul arrays.allocated[index] unit with
    | error reason => simp [Relates]
    | ok scaled =>
      simp only []
      by_cases nextBound : index < arrays.newAllocations.length
      · simp only [List.getElem?_eq_getElem nextBound]
        have afterNext := store_new memory ap rp arrays related ⟨index,nextBound⟩ scaled
        rw [read_related _ ap index arrays.allocated afterNext.1]
        simp only [TrioAlloc2.ParentConversion.read,List.getElem?_eq_getElem oldBound]
        exact store_old _ ap rp _ afterNext ⟨index,oldBound⟩ TrioAlloc2.zero
      · simp only [List.getElem?_eq_none (by omega : arrays.newAllocations.length ≤ index)]
        rfl
  · simp only [TrioAlloc2.ParentConversion.read,
      List.getElem?_eq_none (by omega : arrays.allocated.length ≤ index),bind,Except.bind]
    rfl

theorem relates_bind (ap rp : Nat) (left : Result MemoryWords) (right : Result Arrays)
    (nextLeft : MemoryWords → Result MemoryWords) (nextRight : Arrays → Result Arrays)
    (related : Relates ap rp left right)
    (next : ∀ memory arrays, ArraysAt memory ap rp arrays →
      Relates ap rp (nextLeft memory) (nextRight arrays)) :
    Relates ap rp (left >>= nextLeft) (right >>= nextRight) := by
  cases left with
  | error reason =>
    cases right with
    | error other => exact related
    | ok arrays => exact False.elim related
  | ok memory =>
    cases right with
    | error reason => exact False.elim related
    | ok arrays => exact next memory arrays related

def positiveRows : Nat → Nat → Word → Nat → Nat → MemoryWords → Result MemoryWords
  | 0, _, _, _, _, memory => .ok memory
  | remaining+1, index, unit, ap, rp, memory => do
    let after ← positiveRow memory ap rp index unit
    positiveRows remaining (index+1) unit ap rp after

def zeroRows : Nat → Nat → Word → Nat → Nat → MemoryWords → Result MemoryWords
  | 0, _, _, _, _, memory => .ok memory
  | remaining+1, index, unit, ap, rp, memory => do
    let after ← zeroRow memory ap rp index unit
    zeroRows remaining (index+1) unit ap rp after

private theorem bind_assoc (value : Except ε α) (f : α → Except ε β) (g : β → Except ε γ) :
    ((value >>= f) >>= g) = (value >>= fun x => f x >>= g) := by cases value <;> rfl

private theorem ok_bind (value : α) (f : α → Except ε β) :
    (Except.ok value >>= f) = f value := rfl

theorem positive_step (n index : Nat) (unit : Word) (arrays : Arrays) :
    TrioAlloc2.ParentConversion.positiveRows (n+1) index unit arrays =
      (positiveStep index unit arrays >>= TrioAlloc2.ParentConversion.positiveRows n (index+1) unit) := by
  simp only [positiveStep,bind_assoc,ok_bind,TrioAlloc2.ParentConversion.positiveRows]

theorem zero_step (n index : Nat) (unit : Word) (arrays : Arrays) :
    TrioAlloc2.ParentConversion.zeroRows (n+1) index unit arrays =
      (zeroStep index unit arrays >>= TrioAlloc2.ParentConversion.zeroRows n (index+1) unit) := by
  simp only [zeroStep,bind_assoc,ok_bind,TrioAlloc2.ParentConversion.zeroRows]

/-- Every success and failure agrees, including late errors after earlier
in-place writes. Successful cases derive both final arrays from those writes. -/
theorem positiveRows_related (n index : Nat) (unit : Word) (ap rp : Nat)
    (memory : MemoryWords) (arrays : Arrays) (related : ArraysAt memory ap rp arrays) :
    Relates ap rp (positiveRows n index unit ap rp memory)
      (TrioAlloc2.ParentConversion.positiveRows n index unit arrays) := by
  induction n generalizing index memory arrays with
  | zero => exact related
  | succ n ih =>
    rw [positiveRows,positive_step]
    exact relates_bind ap rp _ _ _ _ (positiveRow_related memory ap rp index unit arrays related)
      (fun nextMemory nextArrays nextRelated => ih (index+1) nextMemory nextArrays nextRelated)

theorem zeroRows_related (n index : Nat) (unit : Word) (ap rp : Nat)
    (memory : MemoryWords) (arrays : Arrays) (related : ArraysAt memory ap rp arrays) :
    Relates ap rp (zeroRows n index unit ap rp memory)
      (TrioAlloc2.ParentConversion.zeroRows n index unit arrays) := by
  induction n generalizing index memory arrays with
  | zero => exact related
  | succ n ih =>
    rw [zeroRows,zero_step]
    exact relates_bind ap rp _ _ _ _ (zeroRow_related memory ap rp index unit arrays related)
      (fun nextMemory nextArrays nextRelated => ih (index+1) nextMemory nextArrays nextRelated)

def observe (ap rp : Nat) (memory : MemoryWords) : Arrays :=
  ⟨TrioAlloc2.readMemoryArray memory ap,TrioAlloc2.readMemoryArray memory rp⟩

theorem observe_related (ap rp : Nat) (memory : MemoryWords) (arrays : Arrays)
    (related : ArraysAt memory ap rp arrays) : observe ap rp memory = arrays := by
  simp only [observe,TrioAlloc2.readMemoryArray_eq memory ap arrays.allocated related.1,
    TrioAlloc2.readMemoryArray_eq memory rp arrays.newAllocations related.2.1]

theorem relates_projection (ap rp : Nat) (left : Result MemoryWords) (right : Result Arrays)
    (related : Relates ap rp left right) : left.map (observe ap rp) = right := by
  cases left with
  | error reason =>
    cases right with
    | error other => exact congrArg Except.error related
    | ok arrays => exact False.elim related
  | ok memory =>
    cases right with
    | error reason => exact False.elim related
    | ok arrays => exact congrArg Except.ok (observe_related ap rp memory arrays related)

theorem positive_projection (n index : Nat) (unit : Word) (ap rp : Nat)
    (memory : MemoryWords) (arrays : Arrays) (related : ArraysAt memory ap rp arrays) :
    (positiveRows n index unit ap rp memory).map (observe ap rp) =
      TrioAlloc2.ParentConversion.positiveRows n index unit arrays :=
  relates_projection ap rp _ _ (positiveRows_related n index unit ap rp memory arrays related)

theorem zero_projection (n index : Nat) (unit : Word) (ap rp : Nat)
    (memory : MemoryWords) (arrays : Arrays) (related : ArraysAt memory ap rp arrays) :
    (zeroRows n index unit ap rp memory).map (observe ap rp) =
      TrioAlloc2.ParentConversion.zeroRows n index unit arrays :=
  relates_projection ap rp _ _ (zeroRows_related n index unit ap rp memory arrays related)

theorem relates_success (ap rp : Nat) (final : MemoryWords) (right : Result Arrays)
    (related : Relates ap rp (.ok final) right) :
    ∃ arrays, right = .ok arrays ∧ ArraysAt final ap rp arrays := by
  cases right with
  | error reason => exact False.elim related
  | ok arrays => exact ⟨arrays,rfl,related⟩

theorem positive_success (n index : Nat) (unit : Word) (ap rp : Nat)
    (memory final : MemoryWords) (arrays : Arrays) (related : ArraysAt memory ap rp arrays)
    (executed : positiveRows n index unit ap rp memory = .ok final) :
    ∃ out, TrioAlloc2.ParentConversion.positiveRows n index unit arrays = .ok out ∧
      ArraysAt final ap rp out := by
  have simulation := positiveRows_related n index unit ap rp memory arrays related
  rw [executed] at simulation
  exact relates_success ap rp final _ simulation

theorem zero_success (n index : Nat) (unit : Word) (ap rp : Nat)
    (memory final : MemoryWords) (arrays : Arrays) (related : ArraysAt memory ap rp arrays)
    (executed : zeroRows n index unit ap rp memory = .ok final) :
    ∃ out, TrioAlloc2.ParentConversion.zeroRows n index unit arrays = .ok out ∧
      ArraysAt final ap rp out := by
  have simulation := zeroRows_related n index unit ap rp memory arrays related
  rw [executed] at simulation
  exact relates_success ap rp final _ simulation

/-- ConversionBridge now receives the result of actual memory operations,
including arithmetic and bounds failures in source order. -/
theorem positive_equiv (n : Nat) (unit : Word) (ap rp : Nat) (memory : MemoryWords)
    (xs ys : List Word) (related : ArraysAt memory ap rp ⟨xs,ys⟩)
    (hx : xs.length = n) (hy : ys.length = n) :
    libraryResult ((positiveRows n 0 unit ap rp memory).map (observe ap rp)) =
      (convertPositive unit n xs ys).map ConversionBridge.arrays := by
  rw [positive_projection n 0 unit ap rp memory ⟨xs,ys⟩ related]
  exact ConversionBridge.positive_equiv n unit xs ys hx hy

theorem zero_equiv (n : Nat) (unit : Word) (ap rp : Nat) (memory : MemoryWords)
    (xs ys : List Word) (related : ArraysAt memory ap rp ⟨xs,ys⟩)
    (hx : xs.length = n) (hy : ys.length = n) :
    libraryResult ((zeroRows n 0 unit ap rp memory).map (observe ap rp)) =
      (convertZero unit n xs).map ConversionBridge.arrays := by
  rw [zero_projection n 0 unit ap rp memory ⟨xs,ys⟩ related]
  exact ConversionBridge.zero_equiv n unit xs ys hx hy

#print axioms positiveRows_related
#print axioms zeroRows_related
#print axioms positive_success
#print axioms zero_success
#print axioms positive_equiv
#print axioms zero_equiv
end LidoSRv3.Audit.Source.TrioComposition.MemoryTransportConversion
