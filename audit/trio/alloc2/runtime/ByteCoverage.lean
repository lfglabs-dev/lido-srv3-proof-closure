import audit.trio.alloc2.runtime.ByteInitialize

namespace LidoSRv3.Audit.Source.TrioAlloc2.ByteRuntime
open _root_.Compiler.CompilationModel
open _root_.LidoSRv3.Audit.Source.TrioAlloc1 (word)
open IndexedMemory (Plan Valid plan plan_valid)

abbrev Covers (memory : DenoteMemory.Memory) (ap cp : Nat) (buckets capacities : List Word) : Prop :=
  ap+32*(buckets.length+1) ≤ memory.size ∧ cp+32*(capacities.length+1) ≤ memory.size

theorem writeWords_size_ge (memory : DenoteMemory.Memory) (start : Nat) (values : List Word) :
    memory.size ≤ (writeWords memory start values).size := by
  induction values generalizing memory start with
  | nil => exact Nat.le_refl _
  | cons value rest ih =>
    exact Nat.le_trans (Nat.le_max_left _ _) (ih (memory.writeWord start (encode value)) (start+32))

theorem writeWords_extent (memory : DenoteMemory.Memory) (start : Nat) (values : List Word)
    (nonempty : values ≠ []) : start+32*values.length ≤ (writeWords memory start values).size := by
  induction values generalizing memory start with
  | nil => exact False.elim (nonempty rfl)
  | cons value rest ih =>
    by_cases empty : rest = []
    · subst rest
      exact Nat.le_trans (expandedLength_ge (start+32)) (Nat.le_max_right _ _)
    · have h := ih (memory.writeWord start (encode value)) (start+32) empty
      simpa only [writeWords, List.length_cons, Nat.mul_add, Nat.mul_one, Nat.add_assoc,
        Nat.add_left_comm, Nat.add_comm] using h

theorem writeWords_aligned (memory : DenoteMemory.Memory) (start : Nat) (values : List Word)
    (aligned : memory.size % 32 = 0) : (writeWords memory start values).size % 32 = 0 := by
  induction values generalizing memory start with
  | nil => exact aligned
  | cons value rest ih =>
    apply ih
    change (max memory.size (DenoteMemory.expandedLength (start+32))) % 32 = 0
    rcases Nat.le_total memory.size (DenoteMemory.expandedLength (start+32)) with left | right
    · simpa only [Nat.max_eq_right left] using DenoteMemory.expandedLength_aligned (start+32)
    · simpa only [Nat.max_eq_left right] using aligned

theorem constructArrays_covers (memory : DenoteMemory.Memory) (ap cp : Nat) (buckets capacities : List Word) :
    Covers (constructArrays memory ap cp buckets capacities) ap cp buckets capacities := by
  have first := writeWords_extent memory ap (word buckets.length :: buckets) (by simp)
  have grows := writeWords_size_ge (writeWords memory ap (word buckets.length :: buckets)) cp
    (word capacities.length :: capacities)
  have second := writeWords_extent (writeWords memory ap (word buckets.length :: buckets)) cp
    (word capacities.length :: capacities) (by simp)
  constructor
  · exact Nat.le_trans first grows
  · exact second

theorem constructArrays_aligned (memory : DenoteMemory.Memory) (ap cp : Nat) (buckets capacities : List Word)
    (aligned : memory.size % 32 = 0) : (constructArrays memory ap cp buckets capacities).size % 32 = 0 :=
  writeWords_aligned _ cp _ (writeWords_aligned memory ap _ aligned)

theorem mload_array_element (memory : DenoteMemory.Memory) (pointer : Nat) (values : List Word)
    (aligned : memory.size % 32 = 0) (covered : pointer+32*(values.length+1) ≤ memory.size)
    (index : Fin values.length) :
    DenoteMemory.denoteMemoryOp (.mload (pointer+32*(index.val+1))) memory =
      .word (memory.readWord (pointer+32*(index.val+1))) memory :=
  mload_covered memory _ aligned (by have := index.isLt; omega)

theorem applyMemory_size (memory : DenoteMemory.Memory) (ap : Nat) (buckets : List Word)
    (p : Plan) (valid : Valid buckets p) (aligned : memory.size % 32 = 0)
    (covered : ap+32*(buckets.length+1) ≤ memory.size) :
    (applyMemory memory ap p).size = memory.size := by
  rcases p with ⟨amount, update⟩
  cases update with
  | none => rfl
  | some entry =>
    change (memory.expand (ap+32*(entry.1+1)+32)).size = memory.size
    exact congrArg DenoteMemory.Memory.size
      (expand_eq_of_covered memory (ap+32*(entry.1+1)) aligned (by
        have inside : entry.1 < buckets.length := valid
        omega))

theorem step_size (memory : DenoteMemory.Memory) (ap cp : Nat) (buckets capacities : List Word)
    (demand amount : Word) (next : DenoteMemory.Memory) (related : ArraysAt memory ap cp buckets capacities)
    (aligned : memory.size % 32 = 0) (covered : Covers memory ap cp buckets capacities)
    (executed : memoryStep memory ap cp demand = .ok (amount, next)) : next.size = memory.size := by
  simp only [memoryStep, readArray_view, MemoryWrite.readArray_eq _ _ _ related.1,
    MemoryWrite.readArray_eq _ _ _ related.2.1] at executed
  cases hp : plan buckets capacities demand with
  | error e => simp [hp, bind, Except.bind] at executed
  | ok p =>
    have equal : p.amount = amount ∧ applyMemory memory ap p = next := by
      simpa [hp, bind, Except.bind, pure, Except.pure] using executed
    rw [← equal.2]
    exact applyMemory_size memory ap buckets p (plan_valid _ _ _ _ hp) aligned covered.1

theorem loop_size (memory : DenoteMemory.Memory) (ap cp : Nat) (buckets capacities : List Word)
    (demand allocated amount : Word) (final : DenoteMemory.Memory)
    (related : ArraysAt memory ap cp buckets capacities)
    (executed : memoryLoop memory ap cp demand allocated = .ok (amount, final))
    (aligned : memory.size % 32 = 0) (covered : Covers memory ap cp buckets capacities) :
    final.size = memory.size := by
  rw [memoryLoop] at executed
  by_cases more : allocated.val < demand.val
  · simp only [more, ↓reduceIte] at executed
    cases sub : checkedSub demand allocated with
    | error e => simp [sub] at executed
    | ok remaining =>
      simp only [sub] at executed
      cases actual : memoryStep memory ap cp remaining with
      | error e => simp [actual] at executed
      | ok pair =>
        rcases pair with ⟨stepAmount, next⟩
        simp only [actual] at executed
        have firstFrame := step_size memory ap cp buckets capacities remaining stepAmount next related aligned covered actual
        have correspondence := step_related memory ap cp buckets capacities remaining related
        cases source : step buckets capacities remaining with
        | error e => simp [source, actual, Related] at correspondence
        | ok result =>
          have facts : result.amount = stepAmount ∧ ArraysAt next ap cp result.buckets capacities := by
            simpa [source, actual, Related] using correspondence
          have length := (step_invariants buckets capacities remaining result source).2
          by_cases stop : stepAmount.val = 0
          · simp only [stop, ↓reduceIte] at executed
            cases executed
            exact firstFrame
          · simp only [stop, ↓reduceIte] at executed
            split at executed
            · cases executed
            · rename_i total added
              have decrease : 2^256-total.val < 2^256-allocated.val := by
                have value := checkedAdd_value allocated stepAmount total added
                have := total.isLt
                omega
              have secondFrame := loop_size next ap cp result.buckets capacities demand total amount final facts.2
                executed (by simpa only [firstFrame] using aligned)
                (by simpa only [Covers, firstFrame, length] using covered)
              exact secondFrame.trans firstFrame
  · simp only [more, ↓reduceIte] at executed
    cases executed
    rfl
termination_by 2^256-allocated.val
decreasing_by exact decrease

theorem run_size (memory : DenoteMemory.Memory) (ap cp : Nat) (buckets capacities : List Word)
    (demand amount : Word) (final : DenoteMemory.Memory)
    (related : ArraysAt memory ap cp buckets capacities)
    (executed : run memory ap cp demand = .ok (amount, final))
    (aligned : memory.size % 32 = 0) (covered : Covers memory ap cp buckets capacities) :
    final.size = memory.size :=
  loop_size memory ap cp buckets capacities demand zero amount final related executed aligned covered

/-- Every successful run preserves the initialized regions and word alignment. -/
theorem run_coverage (memory : DenoteMemory.Memory) (ap cp : Nat) (buckets capacities : List Word)
    (demand amount : Word) (final : DenoteMemory.Memory)
    (related : ArraysAt memory ap cp buckets capacities)
    (executed : run memory ap cp demand = .ok (amount, final))
    (aligned : memory.size % 32 = 0) (covered : Covers memory ap cp buckets capacities) :
    final.size % 32 = 0 ∧ Covers final ap cp buckets capacities := by
  have same := run_size memory ap cp buckets capacities demand amount final related executed aligned covered
  simpa only [Covers, same] using And.intro aligned covered

theorem mload_array_header (memory : DenoteMemory.Memory) (pointer : Nat) (values : List Word)
    (aligned : memory.size % 32 = 0) (covered : pointer+32*(values.length+1) ≤ memory.size) :
    DenoteMemory.denoteMemoryOp (.mload pointer) memory = .word (memory.readWord pointer) memory :=
  mload_covered memory pointer aligned (by omega)

#print axioms run_coverage
#print axioms mload_array_header
#print axioms loop_size
#print axioms run_size
#print axioms constructArrays_covers
#print axioms constructArrays_aligned
#print axioms mload_array_element
#print axioms applyMemory_size
#print axioms step_size
end LidoSRv3.Audit.Source.TrioAlloc2.ByteRuntime
