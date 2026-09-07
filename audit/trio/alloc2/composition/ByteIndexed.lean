import audit.trio.alloc2.composition.ByteMemory
import audit.trio.alloc2.composition.IndexedMemory

/-! The proportional source loop over physical byte stores. Array observations
are related at each recursive call; no equality of all overlapping word reads
is assumed. This is not a proof of compiler dispatch, allocation gas or copying. -/
namespace LidoSRv3.Audit.Source.TrioAlloc2.ByteIndexed
open ByteMemory (Memory load store)
open MemoryWrite (readArray readArray_eq)
open IndexedMemory (Plan Valid plan plan_valid applyPlan plan_matches_step)

abbrev ArraysAt (memory : Memory) (ap cp : Nat) (buckets capacities : List Word) : Prop :=
  MemoryWrite.ArraysAt (load memory) ap cp buckets capacities

def applyMemory (memory : Memory) (ap : Nat) (p : Plan) : Memory :=
  match p.update with
  | none => memory
  | some (index, value) => store memory (ap+32*(index+1)) value

theorem applyMemory_related (memory : Memory) (ap cp : Nat) (buckets capacities : List Word)
    (p : Plan) (valid : Valid buckets p) (related : ArraysAt memory ap cp buckets capacities) :
    ArraysAt (applyMemory memory ap p) ap cp (applyPlan buckets p).buckets capacities := by
  cases p with
  | mk amount update =>
    cases update with
    | none => exact related
    | some update =>
      rcases update with ⟨index, value⟩
      have inside : index < buckets.length := valid
      refine ⟨ByteMemory.store_array memory ap buckets ⟨index, inside⟩ value related.1, ?_, ?_⟩
      · exact ByteMemory.store_other_array memory (ap+32*(index+1)) cp value capacities
          related.2.1 (by rcases related.2.2 with left | right <;> omega)
      · simpa [applyPlan] using related.2.2

def memoryStep (memory : Memory) (ap cp : Nat) (demand : Word) : Result (Word × Memory) := do
  let p ← plan (readArray (load memory) ap) (readArray (load memory) cp) demand
  pure (p.amount, applyMemory memory ap p)

def Related (ap cp : Nat) (capacities : List Word) : Result StepOutput → Result (Word × Memory) → Prop
  | .error source, .error actual => source = actual
  | .ok source, .ok (amount, memory) => source.amount = amount ∧ ArraysAt memory ap cp source.buckets capacities
  | _, _ => False

theorem step_related (memory : Memory) (ap cp : Nat) (buckets capacities : List Word)
    (demand : Word) (related : ArraysAt memory ap cp buckets capacities) :
    Related ap cp capacities (step buckets capacities demand) (memoryStep memory ap cp demand) := by
  rw [← plan_matches_step]
  simp only [memoryStep, readArray_eq _ _ _ related.1, readArray_eq _ _ _ related.2.1]
  cases hp : plan buckets capacities demand with
  | error e => simp [Related, Except.map, bind, Except.bind]
  | ok p =>
    exact ⟨rfl, applyMemory_related memory ap cp buckets capacities p (plan_valid buckets capacities demand p hp) related⟩

def memoryLoop (memory : Memory) (ap cp : Nat) (demand allocated : Word) : Result (Word × Memory) :=
  if allocated.val < demand.val then
    match checkedSub demand allocated with
    | .error e => .error e
    | .ok remaining =>
      match memoryStep memory ap cp remaining with
      | .error e => .error e
      | .ok (amount, next) =>
        if amount.val = 0 then .ok (allocated, next)
        else match added : checkedAdd allocated amount with
          | .error e => .error e
          | .ok total => memoryLoop next ap cp demand total
  else .ok (allocated, memory)
termination_by 2^256-allocated.val
decreasing_by
  have value := checkedAdd_value allocated amount total added
  have := total.isLt
  omega

theorem loop_related (memory : Memory) (ap cp : Nat) (buckets capacities : List Word)
    (demand allocated : Word) (related : ArraysAt memory ap cp buckets capacities) :
    Related ap cp capacities (allocateLoop buckets capacities demand allocated)
      (memoryLoop memory ap cp demand allocated) := by
  rw [allocateLoop, memoryLoop]
  by_cases more : allocated.val < demand.val
  · simp only [more, ↓reduceIte]
    cases sub : checkedSub demand allocated with
    | error e => simp [sub, Related]
    | ok remaining =>
      simp only [sub]
      have stepRelation := step_related memory ap cp buckets capacities remaining related
      cases source : step buckets capacities remaining with
      | error e =>
        cases actual : memoryStep memory ap cp remaining with
        | error actualError => simpa [source, actual, Related] using stepRelation
        | ok actualResult => simp [source, actual, Related] at stepRelation
      | ok result =>
        cases actual : memoryStep memory ap cp remaining with
        | error actualError => simp [source, actual, Related] at stepRelation
        | ok actualResult =>
          rcases actualResult with ⟨amount, next⟩
          have pair : result.amount = amount ∧ ArraysAt next ap cp result.buckets capacities := by
            simpa [source, actual, Related] using stepRelation
          rcases pair with ⟨amountEq, nextRelated⟩
          subst amount
          simp only [source, actual]
          by_cases stop : result.amount.val = 0
          · simp only [stop, ↓reduceIte]
            exact ⟨rfl, nextRelated⟩
          · simp only [stop, ↓reduceIte]
            cases added : checkedAdd allocated result.amount with
            | error e => simp [added, Related]
            | ok total =>
              simp only [added]
              exact loop_related next ap cp result.buckets capacities demand total nextRelated
  · simp only [more, ↓reduceIte]
    exact ⟨rfl, related⟩
termination_by 2^256-allocated.val
decreasing_by
  have value := checkedAdd_value allocated result.amount total added
  have := total.isLt
  omega

def run (memory : Memory) (ap cp : Nat) (demand : Word) : Result (Word × Memory) :=
  memoryLoop memory ap cp demand zero


theorem run_success (memory : Memory) (ap cp : Nat) (buckets capacities : List Word)
    (demand : Word) (related : ArraysAt memory ap cp buckets capacities)
    (lengths : buckets.length ≤ capacities.length) :
    ∃ out next,
      allocate buckets capacities demand = .ok out ∧
      run memory ap cp demand = .ok (out.amount, next) ∧
      ArraysAt next ap cp out.buckets capacities ∧
      Spec.Distributes (decodedRows buckets capacities) demand.val out.amount.val
        (decodedRows out.buckets capacities) := by
  have bound : buckets.length < 2^256 := related.1.1 ▸ (load memory ap).isLt
  obtain ⟨out, executed⟩ := allocate_success buckets capacities demand lengths bound
  have correspondence := loop_related memory ap cp buckets capacities demand zero related
  change Related ap cp capacities (allocate buckets capacities demand) (run memory ap cp demand) at correspondence
  rw [executed] at correspondence
  cases actual : run memory ap cp demand with
  | error e => simp [actual, Related] at correspondence
  | ok pair =>
    rcases pair with ⟨amount, next⟩
    have facts : out.amount = amount ∧ ArraysAt next ap cp out.buckets capacities := by
      simpa [actual, Related] using correspondence
    exact ⟨out, next, executed, by simp [facts.1], facts.2, allocate_refines _ _ _ _ executed⟩

/-- The short-capacity failure follows from actual scans and the memory header,
not from a supplied failure result or an eager ABI-level length guard. -/
theorem run_short_error (memory : Memory) (ap cp : Nat) (buckets capacities : List Word)
    (demand : Word) (related : ArraysAt memory ap cp buckets capacities)
    (positive : demand.val ≠ 0) (short : capacities.length < buckets.length) :
    run memory ap cp demand = .error .arrayBounds := by
  have bound : buckets.length < 2^256 := related.1.1 ▸ (load memory ap).isLt
  have correspondence := loop_related memory ap cp buckets capacities demand zero related
  change Related ap cp capacities (allocate buckets capacities demand) (run memory ap cp demand) at correspondence
  rw [allocate_short_error buckets capacities demand positive short bound] at correspondence
  cases actual : run memory ap cp demand with
  | error e =>
    have same : Panic.arrayBounds = e := by simpa [actual, Related] using correspondence
    simp [same]
  | ok pair => simp [actual, Related] at correspondence


#print axioms run_success
#print axioms run_short_error
#print axioms applyMemory_related
#print axioms step_related
#print axioms loop_related
end LidoSRv3.Audit.Source.TrioAlloc2.ByteIndexed
