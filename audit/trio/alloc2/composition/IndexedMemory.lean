import audit.trio.alloc2.composition.MemoryWrite

/-! Pinned MinFirstAllocationStrategy.sol:64–116, 30–44 at
17005714f151e5502c559932319a3f2f74ac2436. The plan retains the selected index
and the single checked update. Execution writes that slot into existing memory,
then the loop reads the resulting arrays again. Byte-store semantics remain a
separate relation; this module uses the agreed byte-addressed word map. -/
namespace LidoSRv3.Audit.Source.TrioAlloc2.IndexedMemory
open _root_.LidoSRv3.Audit.Source.TrioAlloc1 (MemoryWords ArrayAt)
open MemoryWrite (store ArraysAt readArray readArray_eq)

structure Plan where
  amount : Word
  update : Option (Nat × Word)

def applyPlan (buckets : List Word) (p : Plan) : StepOutput :=
  ⟨p.amount, match p.update with | none => buckets | some (i, value) => buckets.set i value⟩

def plan (buckets capacities : List Word) (demand : Word) : Result Plan := do
  if demand.val = 0 then return ⟨zero, none⟩
  let candidate ← firstScan buckets capacities 0
    { index := buckets.length, allocation := maxWord, count := zero }
  if candidate.count.val = 0 then return ⟨zero, none⟩
  let upper ← secondScan buckets capacities candidate.allocation maxWord
  let share ← if candidate.count.val > 1 then ceilDiv demand candidate.count else pure demand
  let capacity ← match capacities[candidate.index]? with
    | none => .error .arrayBounds
    | some capacity => .ok capacity
  let space ← checkedSub (minWord upper capacity) candidate.allocation
  let amount := minWord share space
  let previous ← match buckets[candidate.index]? with
    | none => .error .arrayBounds
    | some previous => .ok previous
  let updated ← checkedAdd previous amount
  return ⟨amount, some (candidate.index, updated)⟩

theorem plan_matches_step (buckets capacities : List Word) (demand : Word) :
    (plan buckets capacities demand).map (applyPlan buckets) = step buckets capacities demand := by
  cases hp : plan buckets capacities demand
  all_goals simp only [Except.map]
  all_goals simp only [plan, bind, Except.bind, pure, Except.pure] at hp
  all_goals repeat' split at hp
  all_goals simp_all [step, bind, Except.bind, pure, Except.pure, applyPlan]
  all_goals try cases hp
  all_goals try dsimp only
  all_goals first | (exact ⟨rfl, rfl⟩) | (intro impossible; omega) | (rw [if_neg (by omega)])

def Valid (buckets : List Word) (p : Plan) : Prop :=
  match p.update with | none => True | some (i, _) => i < buckets.length

theorem plan_valid (buckets capacities : List Word) (demand : Word) (p : Plan)
    (executed : plan buckets capacities demand = .ok p) : Valid buckets p := by
  by_cases hz : demand.val = 0
  · simp [plan, hz, pure, Except.pure] at executed
    cases executed
    trivial
  · cases hf : firstScan buckets capacities 0
        { index := buckets.length, allocation := maxWord, count := zero } with
    | error e => simp [plan, hz, hf, bind, Except.bind, pure, Except.pure] at executed
    | ok candidate =>
      by_cases hc : candidate.count.val = 0
      · simp [plan, hz, hf, hc, bind, Except.bind, pure, Except.pure] at executed
        cases executed
        trivial
      · have inside := initialScan_index_bound buckets capacities candidate hf hc
        simp only [plan, hz, hf, hc, ↓reduceIte, bind, Except.bind, pure, Except.pure] at executed
        repeat' split at executed
        all_goals cases executed
        all_goals exact inside

theorem store_array (memory : MemoryWords) (pointer : Nat) (buckets : List Word)
    (index : Fin buckets.length) (value : Word) (related : ArrayAt memory pointer buckets) :
    ArrayAt (store memory (pointer+32*(index.val+1)) value) pointer (buckets.set index.val value) := by
  constructor
  · simp only [store, show pointer ≠ pointer+32*(index.val+1) by omega, ↓reduceIte,
      List.length_set]
    exact related.1
  · intro i
    have inside : i.val < buckets.length := by simpa using i.isLt
    by_cases same : i.val = index.val
    · simp [store, same]
    · have distinct : pointer+32*(i.val+1) ≠ pointer+32*(index.val+1) := by omega
      simp only [store, distinct, ↓reduceIte]
      simpa [same, Ne.symm same] using related.2 ⟨i.val, inside⟩

theorem store_preserves (memory : MemoryWords) (ap cp : Nat) (buckets capacities : List Word)
    (index : Fin buckets.length) (value : Word) (related : ArraysAt memory ap cp buckets capacities) :
    ArraysAt (store memory (ap+32*(index.val+1)) value) ap cp (buckets.set index.val value) capacities := by
  have frame : ∀ address, cp ≤ address → address < cp+32*(capacities.length+1) →
      store memory (ap+32*(index.val+1)) value address = memory address := by
    intro address lo hi
    have distinct : address ≠ ap+32*(index.val+1) := by
      have bound := index.isLt
      rcases related.2.2 with left | right <;> omega
    simp [store, distinct]
  refine ⟨store_array memory ap buckets index value related.1, ⟨?_, ?_⟩, ?_⟩
  · rw [frame cp (by omega) (by omega)]
    exact related.2.1.1
  · intro i
    rw [frame _ (by omega) (by have := i.isLt; omega)]
    exact related.2.1.2 i
  · simpa using related.2.2

def applyMemory (memory : MemoryWords) (ap : Nat) (p : Plan) : MemoryWords :=
  match p.update with
  | none => memory
  | some (i, value) => store memory (ap+32*(i+1)) value

theorem applyMemory_related (memory : MemoryWords) (ap cp : Nat) (buckets capacities : List Word)
    (p : Plan) (valid : Valid buckets p) (related : ArraysAt memory ap cp buckets capacities) :
    ArraysAt (applyMemory memory ap p) ap cp (applyPlan buckets p).buckets capacities := by
  rcases p with ⟨amount, update⟩
  cases update with
  | none => exact related
  | some update => exact store_preserves memory ap cp buckets capacities ⟨update.1, valid⟩ update.2 related

/-- Every address except the selected element slot retains its prior word. -/
theorem applyMemory_frame (memory : MemoryWords) (ap : Nat) (buckets : List Word)
    (p : Plan) (valid : Valid buckets p) (address : Nat)
    (outside : ∀ i : Fin buckets.length, address ≠ ap+32*(i.val+1)) :
    applyMemory memory ap p address = memory address := by
  rcases p with ⟨amount, update⟩
  cases update with
  | none => rfl
  | some entry =>
    exact if_neg (outside ⟨entry.1, valid⟩)

/-- A fixed-index store violates the exact indexed array postcondition. -/
theorem wrong_index_refutes_postcondition :
    ¬ (∀ (memory : MemoryWords) (pointer : Nat) (buckets : List Word)
      (index : Fin buckets.length) (value : Word), ArrayAt memory pointer buckets →
      ArrayAt (store memory (pointer+32) value) pointer (buckets.set index.val value)) := by
  intro claimed
  let memory : MemoryWords := fun address => if address = 128 then TrioAlloc1.word 2 else zero
  have before : ArrayAt memory 128 [zero, zero] := by
    constructor
    · rfl
    · intro i
      have cases : i.val = 0 ∨ i.val = 1 := by have := i.isLt; simp only [List.length_cons, List.length_nil] at this; omega
      rcases cases with h | h <;> simp [memory, h]
  have after := (claimed memory 128 [zero, zero] ⟨1, by decide⟩ one before).2 ⟨1, by decide⟩
  have impossible : zero = one := by simpa [store, memory] using after
  exact (by decide : zero ≠ one) impossible

#print axioms wrong_index_refutes_postcondition
#print axioms applyMemory_frame

/-- At most one memory word is written per source step, at its selected index. -/
def memoryStep (memory : MemoryWords) (ap cp : Nat) (demand : Word) : Result (Word × MemoryWords) := do
  let p ← plan (readArray memory ap) (readArray memory cp) demand
  pure (p.amount, applyMemory memory ap p)

def Related (ap cp : Nat) (capacities : List Word) : Result StepOutput → Result (Word × MemoryWords) → Prop
  | .error source, .error actual => source = actual
  | .ok source, .ok (amount, memory) => source.amount = amount ∧ ArraysAt memory ap cp source.buckets capacities
  | _, _ => False

theorem step_related (memory : MemoryWords) (ap cp : Nat) (buckets capacities : List Word)
    (demand : Word) (related : ArraysAt memory ap cp buckets capacities) :
    Related ap cp capacities (step buckets capacities demand) (memoryStep memory ap cp demand) := by
  rw [← plan_matches_step]
  simp only [memoryStep, readArray_eq _ _ _ related.1, readArray_eq _ _ _ related.2.1]
  cases hp : plan buckets capacities demand with
  | error e => simp [Related, Except.map, bind, Except.bind]
  | ok p =>
    exact ⟨rfl, applyMemory_related memory ap cp buckets capacities p (plan_valid buckets capacities demand p hp) related⟩

theorem step_frame (memory : MemoryWords) (ap cp : Nat) (buckets capacities : List Word)
    (demand amount : Word) (next : MemoryWords) (related : ArraysAt memory ap cp buckets capacities)
    (executed : memoryStep memory ap cp demand = .ok (amount, next)) (address : Nat)
    (outside : ∀ i : Fin buckets.length, address ≠ ap+32*(i.val+1)) :
    next address = memory address := by
  simp only [memoryStep, readArray_eq _ _ _ related.1, readArray_eq _ _ _ related.2.1] at executed
  cases hp : plan buckets capacities demand with
  | error e => simp [hp, bind, Except.bind] at executed
  | ok p =>
    have equal : p.amount = amount ∧ applyMemory memory ap p = next := by
      simpa [hp, bind, Except.bind, pure, Except.pure] using executed
    rw [← equal.2]
    exact applyMemory_frame memory ap buckets p (plan_valid _ _ _ _ hp) address outside

def memoryLoop (memory : MemoryWords) (ap cp : Nat) (demand allocated : Word) : Result (Word × MemoryWords) :=
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

theorem loop_related (memory : MemoryWords) (ap cp : Nat) (buckets capacities : List Word)
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

def run (memory : MemoryWords) (ap cp : Nat) (demand : Word) : Result (Word × MemoryWords) :=
  memoryLoop memory ap cp demand zero

theorem loop_frame (memory : MemoryWords) (ap cp : Nat) (buckets capacities : List Word)
    (demand allocated amount : Word) (final : MemoryWords)
    (related : ArraysAt memory ap cp buckets capacities)
    (executed : memoryLoop memory ap cp demand allocated = .ok (amount, final))
    (address : Nat) (outside : ∀ i : Fin buckets.length, address ≠ ap+32*(i.val+1)) :
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

/-- No fuel, memory reset, or assumed successful consumer outcome. -/
theorem run_success (memory : MemoryWords) (ap cp : Nat) (buckets capacities : List Word)
    (demand : Word) (related : ArraysAt memory ap cp buckets capacities)
    (lengths : buckets.length ≤ capacities.length) :
    ∃ out next,
      allocate buckets capacities demand = .ok out ∧
      run memory ap cp demand = .ok (out.amount, next) ∧
      ArraysAt next ap cp out.buckets capacities ∧
      Spec.Distributes (decodedRows buckets capacities) demand.val out.amount.val
        (decodedRows out.buckets capacities) := by
  have bound : buckets.length < 2^256 := related.1.1 ▸ (memory ap).isLt
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
theorem run_short_error (memory : MemoryWords) (ap cp : Nat) (buckets capacities : List Word)
    (demand : Word) (related : ArraysAt memory ap cp buckets capacities)
    (positive : demand.val ≠ 0) (short : capacities.length < buckets.length) :
    run memory ap cp demand = .error .arrayBounds := by
  have bound : buckets.length < 2^256 := related.1.1 ▸ (memory ap).isLt
  have correspondence := loop_related memory ap cp buckets capacities demand zero related
  change Related ap cp capacities (allocate buckets capacities demand) (run memory ap cp demand) at correspondence
  rw [allocate_short_error buckets capacities demand positive short bound] at correspondence
  cases actual : run memory ap cp demand with
  | error e =>
    have same : Panic.arrayBounds = e := by simpa [actual, Related] using correspondence
    simp [same]
  | ok pair => simp [actual, Related] at correspondence

#print axioms run_short_error

#print axioms loop_related
#print axioms run_success

#print axioms plan_matches_step
#print axioms store_preserves
#print axioms applyMemory_related
end LidoSRv3.Audit.Source.TrioAlloc2.IndexedMemory
