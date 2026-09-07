import LidoSRv3.Audit.Source.TrioAlloc2.ParentConversion

/-! Array accesses in the post-library parent loops are safe for the count-sized
producer arrays. Arithmetic failure remains explicit. -/
namespace LidoSRv3.Audit.Source.TrioAlloc2.ParentConversion

def ArrayResultSafe (a n : Nat) : Result Arrays → Prop
  | .error reason => reason = .arithmetic
  | .ok out => out.allocated.length = a ∧ out.newAllocations.length = n

private theorem read_at (values : List Word) (i : Nat) (inside : i < values.length) :
    read values i = .ok values[i] := by
  simp [read, List.getElem?_eq_getElem inside]

theorem positiveRows_array_safe (remaining i : Nat) (unit : Word) (arrays : Arrays)
    (oldBound : i+remaining ≤ arrays.allocated.length)
    (newBound : i+remaining ≤ arrays.newAllocations.length) :
    ArrayResultSafe arrays.allocated.length arrays.newAllocations.length
      (positiveRows remaining i unit arrays) := by
  induction remaining generalizing i arrays with
  | zero => simp [positiveRows, ArrayResultSafe]
  | succ remaining ih =>
    have oldInside : i < arrays.allocated.length := by omega
    have newInside : i < arrays.newAllocations.length := by omega
    simp only [positiveRows, read_at _ _ oldInside, read_at _ _ newInside, bind, Except.bind]
    by_cases sub : arrays.allocated[i].val ≤ arrays.newAllocations[i].val
    · simp only [checkedSub, sub, ↓reduceIte, Except.bind]
      by_cases delta : (arrays.newAllocations[i].val-arrays.allocated[i].val)*unit.val < 2^256
      · simp only [checkedMul, delta, ↓reduceDIte, Except.bind, read_at _ _ newInside]
        by_cases next : arrays.newAllocations[i].val*unit.val < 2^256
        · simp only [next, ↓reduceDIte, Except.bind]
          let out : Arrays := ⟨arrays.allocated.set i ⟨_, delta⟩,
            arrays.newAllocations.set i ⟨_, next⟩⟩
          have h := ih (i+1) out (by simp only [out, List.length_set]; omega)
            (by simp only [out, List.length_set]; omega)
          simpa only [out, List.length_set] using h
        · simp [next, ArrayResultSafe]
      · simp [checkedMul, delta, ArrayResultSafe]
    · simp [checkedSub, sub, ArrayResultSafe]

theorem zeroRows_array_safe (remaining i : Nat) (unit : Word) (arrays : Arrays)
    (oldBound : i+remaining ≤ arrays.allocated.length)
    (newBound : i+remaining ≤ arrays.newAllocations.length) :
    ArrayResultSafe arrays.allocated.length arrays.newAllocations.length
      (zeroRows remaining i unit arrays) := by
  induction remaining generalizing i arrays with
  | zero => simp [zeroRows, ArrayResultSafe]
  | succ remaining ih =>
    have oldInside : i < arrays.allocated.length := by omega
    have newInside : i < arrays.newAllocations.length := by omega
    simp only [zeroRows, read_at _ _ oldInside, read_at _ _ newInside, bind, Except.bind]
    by_cases scaled : arrays.allocated[i].val*unit.val < 2^256
    · simp only [checkedMul, scaled, ↓reduceDIte, Except.bind,
        read_at _ _ oldInside, read_at _ _ newInside]
      let out : Arrays := ⟨arrays.allocated.set i zero, arrays.newAllocations.set i ⟨_, scaled⟩⟩
      have h := ih (i+1) out (by simp only [out, List.length_set]; omega)
        (by simp only [out, List.length_set]; omega)
      simpa only [out, List.length_set] using h
    · simp [checkedMul, scaled, ArrayResultSafe]

#print axioms positiveRows_array_safe
#print axioms zeroRows_array_safe
end LidoSRv3.Audit.Source.TrioAlloc2.ParentConversion
