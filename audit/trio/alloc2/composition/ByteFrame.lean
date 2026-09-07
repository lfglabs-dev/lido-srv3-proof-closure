import audit.trio.alloc2.composition.ByteIndexed

/-! Physical-byte frame for the complete proportional loop. A byte is preserved
when it lies outside every 32-byte bucket element; overlapping reads are not
incorrectly treated as independent words. -/
namespace LidoSRv3.Audit.Source.TrioAlloc2.ByteIndexed
open ByteMemory (Memory load)
open IndexedMemory (Plan Valid plan plan_valid)
open MemoryWrite (readArray_eq)

theorem applyMemory_frame (memory : Memory) (ap : Nat) (buckets : List Word)
    (p : Plan) (valid : Valid buckets p) (address : Nat)
    (outside : ∀ i : Fin buckets.length, address < ap+32*(i.val+1) ∨ ap+32*(i.val+1)+32 ≤ address) :
    applyMemory memory ap p address = memory address := by
  rcases p with ⟨amount, update⟩
  cases update with
  | none => rfl
  | some entry =>
    exact ByteMemory.store_outside memory _ address entry.2 (outside ⟨entry.1, valid⟩)

theorem step_frame (memory : Memory) (ap cp : Nat) (buckets capacities : List Word)
    (demand amount : Word) (next : Memory) (related : ArraysAt memory ap cp buckets capacities)
    (executed : memoryStep memory ap cp demand = .ok (amount, next)) (address : Nat)
    (outside : ∀ i : Fin buckets.length, address < ap+32*(i.val+1) ∨ ap+32*(i.val+1)+32 ≤ address) :
    next address = memory address := by
  simp only [memoryStep, readArray_eq _ _ _ related.1, readArray_eq _ _ _ related.2.1] at executed
  cases hp : plan buckets capacities demand with
  | error e => simp [hp, bind, Except.bind] at executed
  | ok p =>
    have equal : p.amount = amount ∧ applyMemory memory ap p = next := by
      simpa [hp, bind, Except.bind, pure, Except.pure] using executed
    rw [← equal.2]
    exact applyMemory_frame memory ap buckets p (plan_valid _ _ _ _ hp) address outside

theorem loop_frame (memory : Memory) (ap cp : Nat) (buckets capacities : List Word)
    (demand allocated amount : Word) (final : Memory)
    (related : ArraysAt memory ap cp buckets capacities)
    (executed : memoryLoop memory ap cp demand allocated = .ok (amount, final))
    (address : Nat) (outside : ∀ i : Fin buckets.length, address < ap+32*(i.val+1) ∨ ap+32*(i.val+1)+32 ≤ address) :
    final address = memory address := by
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
        have firstFrame := step_frame memory ap cp buckets capacities remaining stepAmount next related actual address outside
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
              have secondFrame := loop_frame next ap cp result.buckets capacities demand total amount final facts.2
                executed address (by intro i; exact outside ⟨i.val, by have := i.isLt; omega⟩)
              exact secondFrame.trans firstFrame
  · simp only [more, ↓reduceIte] at executed
    cases executed
    rfl
termination_by 2^256-allocated.val
decreasing_by exact decrease

#print axioms loop_frame


/-- One contiguous physical region covers every selected bucket store. -/
theorem run_frame (memory : Memory) (ap cp : Nat) (buckets capacities : List Word)
    (demand amount : Word) (final : Memory)
    (related : ArraysAt memory ap cp buckets capacities)
    (executed : run memory ap cp demand = .ok (amount, final))
    (address : Nat) (outside : address < ap+32 ∨ ap+32*(buckets.length+1) ≤ address) :
    final address = memory address := by
  apply loop_frame memory ap cp buckets capacities demand zero amount final related executed address
  intro i
  have := i.isLt
  omega

#print axioms applyMemory_frame
#print axioms step_frame
#print axioms run_frame
end LidoSRv3.Audit.Source.TrioAlloc2.ByteIndexed
