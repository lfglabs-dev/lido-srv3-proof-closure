import LidoSRv3.Audit.Source.TrioAlloc2.ParentArraySafety

/-! Pointwise postconditions for the ordered parent conversion loops. These
state mathematical values at every index, independently of their updates. -/
namespace LidoSRv3.Audit.Source.TrioAlloc2.ParentConversion

private theorem read_some (xs : List Word) (i : Nat) (value : Word)
    (h : read xs i = .ok value) : xs[i]? = some value := by
  unfold read at h
  cases he : xs[i]? <;> simp_all

private theorem read_inside (xs : List Word) (i : Nat) (value : Word)
    (h : read xs i = .ok value) : i < xs.length :=
  (List.getElem?_eq_some_iff.mp (read_some xs i value h)).choose

/-- Successful zero-demand conversion zeroes exactly the visited allocations
and scales their original values. Entries outside the visited range are intact. -/
theorem zeroRows_values (remaining i : Nat) (unit : Word) (arrays out : Arrays)
    (executed : zeroRows remaining i unit arrays = .ok out) (j : Nat) :
    out.allocated[j]? = (if i ≤ j ∧ j < i+remaining then some zero else arrays.allocated[j]?) ∧
    (out.newAllocations[j]?).map Fin.val =
      (if i ≤ j ∧ j < i+remaining then (arrays.allocated[j]?).map (fun w => w.val*unit.val)
       else (arrays.newAllocations[j]?).map Fin.val) := by
  induction remaining generalizing i arrays with
  | zero =>
    simp only [zeroRows, Except.ok.injEq] at executed
    subst out
    have empty : ¬ (i ≤ j ∧ j < i+0) := by omega
    simp only [empty, ↓reduceIte, and_self]
  | succ remaining ih =>
    cases hr : read arrays.allocated i with
    | error reason => simp [zeroRows, hr, bind, Except.bind] at executed
    | ok previous =>
      cases hm : checkedMul previous unit with
      | error reason => simp [zeroRows, hr, hm, bind, Except.bind] at executed
      | ok scaled =>
        cases hn : read arrays.newAllocations i with
        | error reason => simp [zeroRows, hr, hm, hn, bind, Except.bind] at executed
        | ok unused =>
          have tail : zeroRows remaining (i+1) unit
              ⟨arrays.allocated.set i zero, arrays.newAllocations.set i scaled⟩ = .ok out := by
            simpa [zeroRows, hr, hm, hn, bind, Except.bind] using executed
          have h := ih (i+1) ⟨arrays.allocated.set i zero, arrays.newAllocations.set i scaled⟩ tail
          have oldInside := read_inside _ _ _ hr
          have newInside := read_inside _ _ _ hn
          have oldValue := read_some _ _ _ hr
          have scaledValue := checkedMul_value _ _ _ hm
          by_cases same : i = j
          · subst j
            have skipped : ¬ (i+1 ≤ i ∧ i < i+1+remaining) := by omega
            have visited : i ≤ i ∧ i < i+(remaining+1) := by omega
            simpa only [skipped, visited, and_self, ↓reduceIte, List.getElem?_set_self oldInside,
              List.getElem?_set_self newInside, oldValue, Option.map_some, scaledValue] using h
          · have region : (i+1 ≤ j ∧ j < i+1+remaining) ↔ (i ≤ j ∧ j < i+(remaining+1)) := by omega
            simpa only [List.getElem?_set_ne same, region] using h

/-- Successful positive conversion returns delta wei and final-allocation wei
at each visited row; subtraction uses the original pre-library allocation. -/
theorem positiveRows_values (remaining i : Nat) (unit : Word) (arrays out : Arrays)
    (executed : positiveRows remaining i unit arrays = .ok out) (j : Nat) :
    (out.allocated[j]?).map Fin.val =
      (if i ≤ j ∧ j < i+remaining then
        (arrays.newAllocations[j]?).bind fun next =>
          (arrays.allocated[j]?).map fun previous => (next.val-previous.val)*unit.val
       else (arrays.allocated[j]?).map Fin.val) ∧
    (out.newAllocations[j]?).map Fin.val =
      (if i ≤ j ∧ j < i+remaining then (arrays.newAllocations[j]?).map (fun w => w.val*unit.val)
       else (arrays.newAllocations[j]?).map Fin.val) := by
  induction remaining generalizing i arrays with
  | zero =>
    simp only [positiveRows, Except.ok.injEq] at executed
    subst out
    have empty : ¬ (i ≤ j ∧ j < i+0) := by omega
    simp only [empty, ↓reduceIte, and_self]
  | succ remaining ih =>
    cases hn : read arrays.newAllocations i with
    | error reason => simp [positiveRows, hn, bind, Except.bind] at executed
    | ok next =>
      cases hp : read arrays.allocated i with
      | error reason => simp [positiveRows, hn, hp, bind, Except.bind] at executed
      | ok previous =>
        cases hs : checkedSub next previous with
        | error reason => simp [positiveRows, hn, hp, hs, bind, Except.bind] at executed
        | ok delta =>
          cases hd : checkedMul delta unit with
          | error reason => simp [positiveRows, hn, hp, hs, hd, bind, Except.bind] at executed
          | ok scaledDelta =>
            cases hm : checkedMul next unit with
            | error reason => simp [positiveRows, hn, hp, hs, hd, hm, bind, Except.bind] at executed
            | ok scaledNext =>
              have tail : positiveRows remaining (i+1) unit
                  ⟨arrays.allocated.set i scaledDelta, arrays.newAllocations.set i scaledNext⟩ = .ok out := by
                simpa [positiveRows, hn, hp, hs, hd, hm, bind, Except.bind] using executed
              have h := ih (i+1) ⟨arrays.allocated.set i scaledDelta, arrays.newAllocations.set i scaledNext⟩ tail
              have oldInside := read_inside _ _ _ hp
              have newInside := read_inside _ _ _ hn
              have oldValue := read_some _ _ _ hp
              have newValue := read_some _ _ _ hn
              have difference := checkedSub_value _ _ _ hs
              have deltaValue := checkedMul_value _ _ _ hd
              have nextValue := checkedMul_value _ _ _ hm
              by_cases same : i = j
              · subst j
                have skipped : ¬ (i+1 ≤ i ∧ i < i+1+remaining) := by omega
                have visited : i ≤ i ∧ i < i+(remaining+1) := by omega
                simpa only [skipped, visited, and_self, ↓reduceIte, List.getElem?_set_self oldInside,
                  List.getElem?_set_self newInside, oldValue, newValue, Option.map_some,
                  Option.bind_some, deltaValue, nextValue, difference] using h
              · have region : (i+1 ≤ j ∧ j < i+1+remaining) ↔ (i ≤ j ∧ j < i+(remaining+1)) := by omega
                simpa only [List.getElem?_set_ne same, region] using h

/-- Public conversion result: total wei plus both per-row values. -/
theorem positive_values (count : Nat) (unit total : Word) (arrays : Arrays) (out : Output)
    (executed : positive count unit total arrays = .ok out) :
    out.totalAllocated.val = total.val*unit.val ∧
    ∀ j, j < count →
      (out.arrays.allocated[j]?).map Fin.val =
        ((arrays.newAllocations[j]?).bind fun next =>
          (arrays.allocated[j]?).map fun previous => (next.val-previous.val)*unit.val) ∧
      (out.arrays.newAllocations[j]?).map Fin.val =
        (arrays.newAllocations[j]?).map (fun w => w.val*unit.val) := by
  cases hm : checkedMul total unit with
  | error reason => simp [positive, hm, bind, Except.bind] at executed
  | ok scaled =>
    cases hr : positiveRows count 0 unit arrays with
    | error reason => simp [positive, hm, hr, bind, Except.bind] at executed
    | ok rows =>
      simp only [positive, hm, hr, bind, Except.bind, Except.ok.injEq] at executed
      subst out
      refine ⟨checkedMul_value _ _ _ hm, ?_⟩
      intro j inside
      simpa only [Nat.zero_le, Nat.zero_add, inside, and_self, ↓reduceIte] using
        positiveRows_values count 0 unit arrays rows hr j

theorem zeroDemand_values (count : Nat) (unit : Word) (allocated : List Word) (out : Output)
    (executed : zeroDemand count unit allocated = .ok out) :
    out.totalAllocated = zero ∧ ∀ j, j < count →
      out.arrays.allocated[j]? = some zero ∧
      (out.arrays.newAllocations[j]?).map Fin.val = (allocated[j]?).map (fun w => w.val*unit.val) := by
  cases hr : zeroRows count 0 unit ⟨allocated, List.replicate count zero⟩ with
  | error reason => simp [zeroDemand, hr, bind, Except.bind] at executed
  | ok rows =>
    simp only [zeroDemand, hr, bind, Except.bind, Except.ok.injEq] at executed
    subst out
    refine ⟨rfl, ?_⟩
    intro j inside
    simpa only [Nat.zero_le, Nat.zero_add, inside, and_self, ↓reduceIte] using
      zeroRows_values count 0 unit ⟨allocated, List.replicate count zero⟩ rows hr j

#print axioms positive_values
#print axioms zeroDemand_values

#print axioms positiveRows_values

#print axioms zeroRows_values
end LidoSRv3.Audit.Source.TrioAlloc2.ParentConversion
