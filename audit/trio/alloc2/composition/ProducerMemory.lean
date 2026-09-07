import audit.trio.alloc2.composition.AllocationMemoryBridge
import audit.trio.alloc2.composition.Composition
import audit.trio.alloc2.composition.MemoryExtent

/-! Ordered allocation guards interleaved with the pinned producer's storage,
static calls and arithmetic. Byte stores, call-copy gas and full compiler
refinement remain separate; this is an executable guard-level extension. -/
namespace LidoSRv3.Audit.Source.TrioAlloc2.ProducerMemory
open _root_.LidoSRv3.Audit.Source.TrioAlloc1

structure State where
  pointer : Word
  trace : Transcript

abbrev Exec (α : Type) := State → Except Failure α × State

def pureM (a : α) : Exec α := fun s => (.ok a, s)
def bindM (a : Exec α) (f : α → Exec β) : Exec β := fun s =>
  match a s with
  | (.error e, next) => (.error e, next)
  | (.ok value, next) => f value next
instance : Monad Exec where
  pure := pureM
  bind := bindM

def lift (a : Execution α) : Exec α := fun s =>
  let (result, trace) := a s.trace
  (result, ⟨s.pointer, trace⟩)

def advance (f : Word → MemoryPrefix.AllocResult) : Exec Unit := fun s =>
  match f s.pointer with
  | .error _ => (.error (.panic (word 0x41)), s)
  | .ok pointer => (.ok (), ⟨pointer, s.trace⟩)

def reserveM (size : Nat) : Exec Unit := advance (fun p => MemoryPrefix.reserve p size)
def arrayM (count : Word) : Exec Unit := advance (fun p => MemoryPrefix.array p count)
/-- Each runtime ERC-7201 constant evaluation emits two 64-byte ABI allocations.
The keccak value is fixed by the pinned source; this models its allocation guards. -/
def slotM : Exec Unit := do
  reserveM 64
  reserveM 64

def prefixM (count : Word) : Exec Unit := advance (fun p => MemoryPrefix.execute p count)

/-- The compiler reserves only the copied static result prefix, rounded to words,
before decoding. Reverted or exceptional calls do not reach this finalization. -/
def staticCallM (oracle : StaticOracle) (request : CallRequest) (width : Nat) : Exec Bytes := do
  let bytes ← lift (staticCall oracle request)
  reserveM (((min width bytes.length + 31) / 32) * 32)
  pure bytes

def firstRowM (l : Layout) (storage : Storage) (oracle : StaticOracle)
    (input : CapacityInput) (i : Nat) (total : Word) : Exec (CachedRow × Word) := do
  slotM
  slotM
  reserveM 224
  let stored := readModule l storage i
  if stored.status.val ≥ 3 then
    lift (failExec (.panic (word 0x21)))
  else
    slotM
    let bytes ← staticCallM oracle { target := stored.identity.moduleAddress, payload := summaryPayload } 96
    let summary ← lift (liftChecked (decodeSummary bytes))
    let active ← lift (liftChecked (TrioAlloc1.checkedSub summary.deposited.val
      (max summary.exited.val stored.accountingExited.val)))
    let allocation ← if stored.wcType.val = 2 then do
      slotM
      let bytes ← staticCallM oracle { target := stored.identity.moduleAddress, payload := stakePayload } 32
      let stake ← lift (liftChecked (decodeStake bytes))
      lift (liftChecked (checkedCeilDiv stake input.config.maxEBType1))
      else pure active
    let total' ← lift (liftChecked (checked (total.val + allocation.val)))
    pure ({ stored, summary, active, allocation }, total')

def firstLoopM (l : Layout) (storage : Storage) (oracle : StaticOracle)
    (input : CapacityInput) : Nat → Nat → Word → Exec (List CachedRow × Word)
  | 0, _, total => pure ([], total)
  | n+1, i, total => do
    let (row, total') ← firstRowM l storage oracle input i total
    let (rows, finalTotal) ← firstLoopM l storage oracle input n (i+1) total'
    pure (row :: rows, finalTotal)

def produceM (l : Layout) (storage : Storage) (oracle : StaticOracle)
    (input : CapacityInput) : Exec CapacityOutput := do
  slotM
  let count := storage (countSlot l)
  prefixM count
  reserveM 224
  let (rows, total) ← firstLoopM l storage oracle input count.val 0 input.depositsToAllocate
  arrayM count
  let buckets ← lift (liftChecked (secondLoop input total rows))
  pure (outputOfBuckets buckets)

def project (r : Except Failure α × State) : Except Failure α × Transcript := (r.1, r.2.trace)

/-- Guard failures are explicit; every other result must be exactly the original
producer result and attempted-call transcript. -/
def Refines (instrumented : Exec α) (original : Execution α) : Prop :=
  ∀ s, (instrumented s).1 = .error (.panic (word 0x41)) ∨ project (instrumented s) = original s.trace

theorem pure_refines (a : α) : Refines (pureM a) (pureExec a) := by
  intro s; exact Or.inr rfl

theorem lift_refines (a : Execution α) : Refines (lift a) a := by
  intro s
  cases h : a s.trace
  exact Or.inr (by simp [lift, project, h])

theorem advance_refines (f : Word → MemoryPrefix.AllocResult) : Refines (advance f) (pureExec ()) := by
  intro s
  cases h : f s.pointer with
  | error e => exact Or.inl (by simp [advance, h])
  | ok p => exact Or.inr (by simp [advance, h, project, pureExec])

theorem bind_refines (a : Exec α) (b : Execution α) (f : α → Exec β) (g : α → Execution β)
    (first : Refines a b) (later : ∀ value, Refines (f value) (g value)) :
    Refines (bindM a f) (bindExec b g) := by
  intro s
  cases actual : a s with
  | mk result next =>
    have h := first s
    rw [actual] at h
    rcases h with memory | same
    · change result = .error (.panic (word 0x41)) at memory
      subst result
      exact Or.inl (by simp [bindM, actual])
    · have old : b s.trace = (result, next.trace) := same.symm
      cases result with
      | error e => exact Or.inr (by simp [bindM, bindExec, actual, old, project])
      | ok value => simpa only [bindM, actual, bindExec, old] using later value next

theorem guard_then_refines (f : Word → MemoryPrefix.AllocResult) (next : Exec α)
    (original : Execution α) (h : Refines next original) :
    Refines (bindM (advance f) (fun _ => next)) original := by
  have proof := bind_refines (advance f) (pureExec ())
    (fun _ => next) (fun _ => original) (advance_refines f) (fun _ => h)
  have eq : bindExec (pureExec ()) (fun _ => original) = original := by funext t; rfl
  rw [eq] at proof
  exact proof

theorem slot_then_refines (next : Exec α) (original : Execution α)
    (h : Refines next original) :
    Refines (bindM slotM (fun _ => next)) original := by
  have slot : Refines slotM (pureExec ()) := by
    unfold slotM reserveM
    apply guard_then_refines
    exact advance_refines _
  have proof := bind_refines slotM (pureExec ())
    (fun _ => next) (fun _ => original) slot (fun _ => h)
  have eq : bindExec (pureExec ()) (fun _ => original) = original := by funext t; rfl
  rw [eq] at proof
  exact proof

private theorem bind_pure (a : Execution α) : bindExec a pureExec = a := by
  funext t
  cases h : a t with
  | mk result trace => cases result <;> simp [bindExec, pureExec, h]

theorem staticCall_refines (oracle : StaticOracle) (request : CallRequest) (width : Nat) :
    Refines (staticCallM oracle request width) (staticCall oracle request) := by
  have h : Refines (staticCallM oracle request width) (bindExec (staticCall oracle request) pureExec) := by
    unfold staticCallM
    apply bind_refines _ _ _ _ (lift_refines _)
    intro bytes
    exact guard_then_refines _ _ _ (pure_refines bytes)
  simpa only [bind_pure] using h

theorem firstRow_refines (l : Layout) (storage : Storage) (oracle : StaticOracle)
    (input : CapacityInput) (i : Nat) (total : Word) :
    Refines (firstRowM l storage oracle input i total) (firstRow l storage oracle input i total) := by
  unfold firstRowM reserveM
  apply slot_then_refines
  apply slot_then_refines
  apply guard_then_refines
  unfold firstRow
  dsimp only
  by_cases status : (readModule l storage i).status.val ≥ 3
  · simp only [status, ↓reduceIte]
    exact lift_refines _
  · simp only [status, ↓reduceIte]
    apply slot_then_refines
    apply bind_refines _ _ _ _ (staticCall_refines _ _ _)
    intro bytes
    apply bind_refines _ _ _ _ (lift_refines _)
    intro summary
    apply bind_refines _ _ _ _ (lift_refines _)
    intro active
    by_cases wc : (readModule l storage i).wcType.val = 2
    · simp only [wc, ↓reduceIte]
      apply slot_then_refines
      apply bind_refines _ _ _ _ (staticCall_refines _ _ _)
      intro stakeBytes
      apply bind_refines _ _ _ _ (lift_refines _)
      intro stake
      apply bind_refines _ _ _ _ (lift_refines _)
      intro allocation
      apply bind_refines _ _ _ _ (lift_refines _)
      intro total'
      exact pure_refines _
    · simp only [wc, ↓reduceIte]
      apply bind_refines _ _ _ _ (pure_refines active)
      intro allocation
      apply bind_refines _ _ _ _ (lift_refines _)
      intro total'
      exact pure_refines _

theorem firstLoop_refines (l : Layout) (storage : Storage) (oracle : StaticOracle)
    (input : CapacityInput) (n i : Nat) (total : Word) :
    Refines (firstLoopM l storage oracle input n i total) (firstLoop l storage oracle input n i total) := by
  induction n generalizing i total with
  | zero => exact pure_refines _
  | succ n ih =>
    unfold firstLoopM firstLoop
    apply bind_refines _ _ _ _ (firstRow_refines _ _ _ _ _ _)
    rintro ⟨row, total'⟩
    apply bind_refines _ _ _ _ (ih (i+1) total')
    rintro ⟨rows, finalTotal⟩
    exact pure_refines _

theorem produce_refines (l : Layout) (storage : Storage) (oracle : StaticOracle) (input : CapacityInput) :
    Refines (produceM l storage oracle input) (produce l storage oracle input) := by
  unfold produceM prefixM
  apply slot_then_refines
  apply guard_then_refines
  unfold reserveM
  apply guard_then_refines
  unfold produce
  apply bind_refines _ _ _ _ (firstLoop_refines _ _ _ _ _ _ _)
  rintro ⟨rows, total⟩
  unfold arrayM
  apply guard_then_refines
  apply bind_refines _ _ _ _ (lift_refines _)
  intro buckets
  exact pure_refines _

/-- Successful memory-guard execution establishes the actual producer execution,
so its consumer premises follow without assuming a decoded producer result. -/
theorem success_establishes_premises (l : Layout) (storage : Storage) (oracle : StaticOracle)
    (input : CapacityInput) (before after : State) (out : CapacityOutput)
    (executed : produceM l storage oracle input before = (.ok out, after)) :
    produce l storage oracle input before.trace = (.ok out, after.trace) ∧ DecodedConsumerPremises out := by
  have h := produce_refines l storage oracle input before
  rw [executed] at h
  rcases h with bad | same
  · cases bad
  · have original : produce l storage oracle input before.trace = (.ok out, after.trace) := same.symm
    exact ⟨original, producer_success_establishes_consumer_premises
      l storage oracle input before.trace after.trace out original⟩

theorem success_prefix (l : Layout) (storage : Storage) (oracle : StaticOracle)
    (input : CapacityInput) (before after : State) (out : CapacityOutput)
    (executed : produceM l storage oracle input before = (.ok out, after)) :
    ∃ start next, MemoryPrefix.producerPrefix start (storage (countSlot l)) = .ok next := by
  cases first : MemoryPrefix.reserve before.pointer 64 with
  | error e => simp [produceM, slotM, reserveM, advance, first, bind, bindM] at executed
  | ok p =>
    cases second : MemoryPrefix.reserve p 64 with
    | error e => simp [produceM, slotM, reserveM, advance, first, second, bind, bindM] at executed
    | ok start =>
      cases prefixResult : MemoryPrefix.execute start (storage (countSlot l)) with
      | error reason =>
        simp [produceM, slotM, reserveM, prefixM, advance, first, second, prefixResult, bind, bindM] at executed
      | ok next =>
        exact ⟨start, next, by simp [MemoryPrefix.prefix_eq_producer, MemoryPrefix.toProducer, prefixResult, Except.mapError]⟩

/-- The byte execution bound now follows from successful interleaved execution,
not a separate allocation-prefix-success premise. -/
theorem success_byte_execution (l : Layout) (storage : Storage) (oracle : StaticOracle)
    (input : CapacityInput) (before after : State) (out : CapacityOutput)
    (executed : produceM l storage oracle input before = (.ok out, after)) :
    LibraryABI.run (LibraryABI.encodeArguments ⟨out.allocations, out.capacities, input.depositsToAllocate⟩) =
      LibraryABI.encodeOutcome (allocate out.allocations out.capacities input.depositsToAllocate) := by
  have original := (success_establishes_premises l storage oracle input before after out executed).1
  obtain ⟨start, next, memory⟩ := success_prefix l storage oracle input before after out executed
  exact producer_memory_byte_execution l storage oracle input before.trace after.trace out
    start next original memory

#print axioms success_prefix
#print axioms success_byte_execution

#print axioms produce_refines
#print axioms success_establishes_premises

#print axioms bind_refines
end LidoSRv3.Audit.Source.TrioAlloc2.ProducerMemory
