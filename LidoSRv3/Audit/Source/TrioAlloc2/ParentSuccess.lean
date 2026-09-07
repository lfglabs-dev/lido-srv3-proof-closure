import LidoSRv3.Audit.Source.TrioAlloc2.ParentArraySafety

namespace LidoSRv3.Audit.Source.TrioAlloc2.ParentConversion

/-- Mathematical representability of each original allocation in the range. -/
def ZeroRangeSafe (remaining i : Nat) (unit : Word) (xs : List Word) : Prop :=
  ∀ j, i ≤ j → j < i+remaining → ∃ value, xs[j]? = some value ∧ value.val*unit.val < 2^256

private theorem zeroSafe_step (n i : Nat) (unit value : Word) (xs : List Word)
    (atIndex : xs[i]? = some value) :
    ZeroRangeSafe (n+1) i unit xs ↔ value.val*unit.val < 2^256 ∧
      ZeroRangeSafe n (i+1) unit (xs.set i zero) := by
  constructor
  · intro safe
    have here := safe i (by omega) (by omega)
    have hereSafe : value.val*unit.val < 2^256 := by simpa [atIndex] using here
    refine ⟨hereSafe, ?_⟩
    intro j lo hi
    have neq : i ≠ j := by omega
    simpa only [List.getElem?_set_ne neq] using safe j (by omega) (by omega)
  · rintro ⟨here, later⟩ j lo hi
    by_cases same : i = j
    · subst j
      exact ⟨value, atIndex, here⟩
    · have tail := later j (by omega) (by omega)
      simpa only [List.getElem?_set_ne same] using tail

/-- Under the actual array bounds, zero-demand conversion succeeds exactly
when every visited original allocation remains representable in wei. -/
theorem zeroRows_success_iff (n i : Nat) (unit : Word) (arrays : Arrays)
    (oldBound : i+n ≤ arrays.allocated.length)
    (newBound : i+n ≤ arrays.newAllocations.length) :
    (∃ out, zeroRows n i unit arrays = .ok out) ↔ ZeroRangeSafe n i unit arrays.allocated := by
  induction n generalizing i arrays with
  | zero =>
    constructor
    · intro _ j lo hi; omega
    · intro _; exact ⟨arrays, rfl⟩
  | succ n ih =>
    have oldInside : i < arrays.allocated.length := by omega
    have newInside : i < arrays.newAllocations.length := by omega
    let previous := arrays.allocated[i]
    have atIndex : arrays.allocated[i]? = some previous := List.getElem?_eq_getElem oldInside
    have readOld : read arrays.allocated i = .ok previous := by simp [read, atIndex]
    have readNew : read arrays.newAllocations i = .ok arrays.newAllocations[i] := by
      simp [read, List.getElem?_eq_getElem newInside]
    rw [zeroSafe_step n i unit previous arrays.allocated atIndex]
    by_cases safe : previous.val*unit.val < 2^256
    · let next : Arrays := ⟨arrays.allocated.set i zero, arrays.newAllocations.set i ⟨_, safe⟩⟩
      have tail := ih (i+1) next (by simp only [next, List.length_set]; omega)
        (by simp only [next, List.length_set]; omega)
      simpa only [zeroRows, readOld, readNew, checkedMul, safe, ↓reduceDIte,
        bind, Except.bind, true_and, next] using tail
    · simp [zeroRows, readOld, readNew, checkedMul, safe, bind, Except.bind]

/-- A precise error condition, with no assumed arithmetic success. -/
theorem zeroRows_arithmetic_iff (n i : Nat) (unit : Word) (arrays : Arrays)
    (oldBound : i+n ≤ arrays.allocated.length)
    (newBound : i+n ≤ arrays.newAllocations.length) :
    zeroRows n i unit arrays = .error .arithmetic ↔ ¬ ZeroRangeSafe n i unit arrays.allocated := by
  have success := zeroRows_success_iff n i unit arrays oldBound newBound
  have kinds := zeroRows_array_safe n i unit arrays oldBound newBound
  cases result : zeroRows n i unit arrays with
  | error reason =>
    simp only [result, ArrayResultSafe] at kinds
    subst reason
    simp [result] at success
    simp [result, success]
  | ok out =>
    simp [result] at success
    simp [result, success]

def PositiveRangeSafe (remaining i : Nat) (unit : Word) (arrays : Arrays) : Prop :=
  ∀ j, i ≤ j → j < i+remaining → ∃ previous next,
    arrays.allocated[j]? = some previous ∧ arrays.newAllocations[j]? = some next ∧ RowSafe previous next unit

private theorem positiveSafe_step (n i : Nat) (unit previous next delta scaled : Word) (arrays : Arrays)
    (atOld : arrays.allocated[i]? = some previous) (atNew : arrays.newAllocations[i]? = some next) :
    PositiveRangeSafe (n+1) i unit arrays ↔ RowSafe previous next unit ∧
      PositiveRangeSafe n (i+1) unit ⟨arrays.allocated.set i delta, arrays.newAllocations.set i scaled⟩ := by
  constructor
  · intro safe
    have here := safe i (by omega) (by omega)
    have hereSafe : RowSafe previous next unit := by simpa [atOld, atNew] using here
    refine ⟨hereSafe, ?_⟩
    intro j lo hi
    have neq : i ≠ j := by omega
    simpa only [List.getElem?_set_ne neq] using safe j (by omega) (by omega)
  · rintro ⟨here, later⟩ j lo hi
    by_cases same : i = j
    · subst j; exact ⟨previous, next, atOld, atNew, here⟩
    · have tail := later j (by omega) (by omega)
      simpa only [List.getElem?_set_ne same] using tail

private theorem positiveRows_factor (n i : Nat) (unit previous next : Word) (arrays : Arrays)
    (atOld : read arrays.allocated i = .ok previous) (atNew : read arrays.newAllocations i = .ok next) :
    positiveRows (n+1) i unit arrays = (do
      let row ← rowArithmetic previous next unit
      positiveRows n (i+1) unit ⟨arrays.allocated.set i row.1, arrays.newAllocations.set i row.2⟩) := by
  cases hs : checkedSub next previous with
  | error e => simp [positiveRows, rowArithmetic, atOld, atNew, hs, bind, Except.bind]
  | ok delta =>
    cases hd : checkedMul delta unit with
    | error e => simp [positiveRows, rowArithmetic, atOld, atNew, hs, hd, bind, Except.bind]
    | ok scaledDelta =>
      cases hn : checkedMul next unit <;>
        simp [positiveRows, rowArithmetic, atOld, atNew, hs, hd, hn, bind, Except.bind]

theorem positiveRows_success_iff (n i : Nat) (unit : Word) (arrays : Arrays)
    (oldBound : i+n ≤ arrays.allocated.length)
    (newBound : i+n ≤ arrays.newAllocations.length) :
    (∃ out, positiveRows n i unit arrays = .ok out) ↔ PositiveRangeSafe n i unit arrays := by
  induction n generalizing i arrays with
  | zero =>
    constructor
    · intro _ j lo hi; omega
    · intro _; exact ⟨arrays, rfl⟩
  | succ n ih =>
    have oldInside : i < arrays.allocated.length := by omega
    have newInside : i < arrays.newAllocations.length := by omega
    let previous := arrays.allocated[i]
    let next := arrays.newAllocations[i]
    have atOld : arrays.allocated[i]? = some previous := List.getElem?_eq_getElem oldInside
    have atNew : arrays.newAllocations[i]? = some next := List.getElem?_eq_getElem newInside
    have factor := positiveRows_factor n i unit previous next arrays
      (by simp [read, atOld]) (by simp [read, atNew])
    rw [factor]
    cases hr : rowArithmetic previous next unit with
    | error reason =>
      have notSafe : ¬ RowSafe previous next unit := by
        intro safe
        obtain ⟨row, ok⟩ := (rowArithmetic_success_iff previous next unit).mpr safe
        rw [hr] at ok
        cases ok
      rw [positiveSafe_step n i unit previous next zero zero arrays atOld atNew]
      simp [notSafe, bind, Except.bind]
    | ok row =>
      have safe := (rowArithmetic_success_iff previous next unit).mp ⟨row, hr⟩
      rw [positiveSafe_step n i unit previous next row.1 row.2 arrays atOld atNew]
      let updated : Arrays := ⟨arrays.allocated.set i row.1, arrays.newAllocations.set i row.2⟩
      have tail := ih (i+1) updated (by simp only [updated, List.length_set]; omega)
        (by simp only [updated, List.length_set]; omega)
      simpa only [bind, Except.bind, safe, true_and, updated] using tail

theorem positiveRows_arithmetic_iff (n i : Nat) (unit : Word) (arrays : Arrays)
    (oldBound : i+n ≤ arrays.allocated.length)
    (newBound : i+n ≤ arrays.newAllocations.length) :
    positiveRows n i unit arrays = .error .arithmetic ↔ ¬ PositiveRangeSafe n i unit arrays := by
  have success := positiveRows_success_iff n i unit arrays oldBound newBound
  have kinds := positiveRows_array_safe n i unit arrays oldBound newBound
  cases result : positiveRows n i unit arrays with
  | error reason =>
    simp only [result, ArrayResultSafe] at kinds
    subst reason
    simp [result] at success
    simp [result, success]
  | ok out =>
    simp [result] at success
    simp [result, success]

/-- Exact public conversion success condition, including the first total multiplication. -/
theorem positive_success_iff (count : Nat) (unit total : Word) (arrays : Arrays)
    (oldBound : count ≤ arrays.allocated.length)
    (newBound : count ≤ arrays.newAllocations.length) :
    (∃ out, positive count unit total arrays = .ok out) ↔
      total.val*unit.val < 2^256 ∧ PositiveRangeSafe count 0 unit arrays := by
  have rows := positiveRows_success_iff count 0 unit arrays (by omega) (by omega)
  by_cases safe : total.val*unit.val < 2^256
  · cases hr : positiveRows count 0 unit arrays <;>
      simp [positive, checkedMul, safe, hr, bind, Except.bind] at rows ⊢ <;> exact rows
  · simp [positive, checkedMul, safe, bind, Except.bind]

theorem zeroDemand_success_iff (count : Nat) (unit : Word) (allocated : List Word)
    (bound : count ≤ allocated.length) :
    (∃ out, zeroDemand count unit allocated = .ok out) ↔
      ZeroRangeSafe count 0 unit allocated := by
  have rows := zeroRows_success_iff count 0 unit ⟨allocated, List.replicate count zero⟩
    (by simpa using bound) (by simp)
  cases hr : zeroRows count 0 unit ⟨allocated, List.replicate count zero⟩ <;>
    simp [zeroDemand, hr, bind, Except.bind] at rows ⊢ <;> exact rows

theorem positive_arithmetic_iff (count : Nat) (unit total : Word) (arrays : Arrays)
    (oldBound : count ≤ arrays.allocated.length)
    (newBound : count ≤ arrays.newAllocations.length) :
    positive count unit total arrays = .error .arithmetic ↔
      ¬ (total.val*unit.val < 2^256 ∧ PositiveRangeSafe count 0 unit arrays) := by
  have rows := positiveRows_arithmetic_iff count 0 unit arrays (by omega) (by omega)
  by_cases safe : total.val*unit.val < 2^256
  · cases hr : positiveRows count 0 unit arrays <;>
      simpa [positive, checkedMul, safe, hr, bind, Except.bind] using rows
  · simp [positive, checkedMul, safe, bind, Except.bind]

theorem zeroDemand_arithmetic_iff (count : Nat) (unit : Word) (allocated : List Word)
    (bound : count ≤ allocated.length) :
    zeroDemand count unit allocated = .error .arithmetic ↔
      ¬ ZeroRangeSafe count 0 unit allocated := by
  have rows := zeroRows_arithmetic_iff count 0 unit ⟨allocated, List.replicate count zero⟩
    (by simpa using bound) (by simp)
  cases hr : zeroRows count 0 unit ⟨allocated, List.replicate count zero⟩ <;>
    simpa [zeroDemand, hr, bind, Except.bind] using rows

#print axioms positive_success_iff
#print axioms positive_arithmetic_iff
#print axioms zeroDemand_success_iff
#print axioms zeroDemand_arithmetic_iff

#print axioms positiveRows_success_iff
#print axioms positiveRows_arithmetic_iff

#print axioms zeroRows_success_iff
#print axioms zeroRows_arithmetic_iff
end LidoSRv3.Audit.Source.TrioAlloc2.ParentConversion
