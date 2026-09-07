import audit.trio.alloc2.composition.ProducerMemory
import audit.trio.alloc2.composition.MemoryWrite
import audit.trio.alloc2.composition.IndexedMemory
import Verity.Core

/-! Execution in the pinned Verity contract runtime. Bytes are already dispatched
library arguments; compiler dispatch and physical byte-memory remain separate.
Verity represents a revert reason as String, so the observation uses exact hex.
No storage observation slots are introduced for this pure library. -/
namespace LidoSRv3.Audit.Source.TrioAlloc2.Runtime
open _root_.LidoSRv3.Audit.Source.TrioAlloc1 (Bytes)

def hex (bytes : Bytes) : String :=
  "0x" ++ String.ofList (bytes.flatMap fun b =>
    [("0123456789abcdef".toList)[b.val / 16]!, ("0123456789abcdef".toList)[b.val % 16]!])

def execute (arguments : Bytes) : _root_.Verity.Contract Bytes := fun state =>
  match LibraryABI.run arguments with
  | .ok data => .success data state
  | .error data => .revert (hex data) state

/-- Outcome relation includes all state, rather than selected storage probes. -/
theorem run_exact (arguments : Bytes) (state : _root_.Verity.ContractState) :
    (execute arguments).run state = match LibraryABI.run arguments with
      | .ok data => .success data state
      | .error data => .revert (hex data) state := by
  unfold execute _root_.Verity.Contract.run
  cases LibraryABI.run arguments <;> rfl

theorem state_preserved (arguments : Bytes) (state : _root_.Verity.ContractState) :
    ((execute arguments).run state).getState = state := by
  rw [run_exact]
  cases LibraryABI.run arguments <;> rfl

theorem canonical_outcome (a : LibraryABI.Arguments)
    (bound : (LibraryABI.encodeArguments a).length < 2^64)
    (state : _root_.Verity.ContractState) :
    (execute (LibraryABI.encodeArguments a)).run state =
      match LibraryABI.encodeOutcome (allocate a.buckets a.capacities a.demand) with
      | .ok data => .success data state
      | .error data => .revert (hex data) state := by
  rw [run_exact, LibraryABI.run_encoded a bound]

/-- Successful executed producer guards establish the ABI bound and decoded
consumer premises needed by the pinned Verity runtime; no separate length or
consumer-success premise is supplied by the caller. -/
theorem producer_success_runtime (l : TrioAlloc1.Layout) (storage : TrioAlloc1.Storage)
    (oracle : TrioAlloc1.StaticOracle) (input : TrioAlloc1.CapacityInput)
    (before after : ProducerMemory.State) (out : TrioAlloc1.CapacityOutput)
    (executed : ProducerMemory.produceM l storage oracle input before = (.ok out, after))
    (state : _root_.Verity.ContractState) :
    (execute (LibraryABI.encodeArguments ⟨out.allocations, out.capacities, input.depositsToAllocate⟩)).run state =
      match LibraryABI.encodeOutcome (allocate out.allocations out.capacities input.depositsToAllocate) with
      | .ok data => .success data state
      | .error data => .revert (hex data) state := by
  rw [run_exact, ProducerMemory.success_byte_execution l storage oracle input before after out executed]

#print axioms producer_success_runtime

def wordMemory (state : _root_.Verity.ContractState) : TrioAlloc1.MemoryWords :=
  fun address => ⟨(state.memory address).val, (state.memory address).isLt⟩

def installMemory (state : _root_.Verity.ContractState) (memory : TrioAlloc1.MemoryWords) :
    _root_.Verity.ContractState :=
  { state with memory := fun address => ⟨(memory address).val, (memory address).isLt⟩ }

theorem wordMemory_install (state : _root_.Verity.ContractState) (memory : TrioAlloc1.MemoryWords) :
    wordMemory (installMemory state memory) = memory := by rfl

/-- Word-memory execution updates the runtime's existing memory field. The
public delegatecall ABI copy boundary is separate from this internal memory view. -/
def memoryExecute (ap cp : Nat) (demand : Word) : _root_.Verity.Contract Word := fun state =>
  match MemoryWrite.run (wordMemory state) ap cp demand with
  | .ok (amount, memory) => .success amount (installMemory state memory)
  | .error reason => .revert (reprStr reason) state

/-- The entire returned ContractState is fixed, including storage, events,
value and calls. Only the proved bucket writeback changes its memory field. -/
theorem memory_run_success (state : _root_.Verity.ContractState) (ap cp : Nat)
    (buckets capacities : List Word) (demand : Word)
    (related : MemoryWrite.ArraysAt (wordMemory state) ap cp buckets capacities)
    (lengths : buckets.length ≤ capacities.length) :
    ∃ out : StepOutput,
      (memoryExecute ap cp demand).run state = .success out.amount
        (installMemory state (MemoryWrite.writeArray (wordMemory state) ap out.buckets)) ∧
      MemoryWrite.ArraysAt (wordMemory (installMemory state
        (MemoryWrite.writeArray (wordMemory state) ap out.buckets))) ap cp out.buckets capacities ∧
      Spec.Distributes (decodedRows buckets capacities) demand.val out.amount.val
        (decodedRows out.buckets capacities) := by
  obtain ⟨out, _, executed, preserved, _, specification⟩ :=
    MemoryWrite.run_success (wordMemory state) ap cp buckets capacities demand related lengths
  refine ⟨out, ?_, preserved, specification⟩
  simp [memoryExecute, _root_.Verity.Contract.run, executed]

/-- The indexed source loop performs a single selected-element store per step. -/
def indexedMemoryExecute (ap cp : Nat) (demand : Word) : _root_.Verity.Contract Word := fun state =>
  match IndexedMemory.run (wordMemory state) ap cp demand with
  | .ok (amount, memory) => .success amount (installMemory state memory)
  | .error reason => .revert (reprStr reason) state

theorem indexed_memory_run_success (state : _root_.Verity.ContractState) (ap cp : Nat)
    (buckets capacities : List Word) (demand : Word)
    (related : MemoryWrite.ArraysAt (wordMemory state) ap cp buckets capacities)
    (lengths : buckets.length ≤ capacities.length) :
    ∃ (out : StepOutput) (next : TrioAlloc1.MemoryWords),
      (indexedMemoryExecute ap cp demand).run state = .success out.amount (installMemory state next) ∧
      MemoryWrite.ArraysAt next ap cp out.buckets capacities ∧
      (∀ address, (∀ i : Fin buckets.length, address ≠ ap+32*(i.val+1)) → next address = wordMemory state address) ∧
      Spec.Distributes (decodedRows buckets capacities) demand.val out.amount.val
        (decodedRows out.buckets capacities) := by
  obtain ⟨out, next, _, executed, preserved, specification⟩ :=
    IndexedMemory.run_success (wordMemory state) ap cp buckets capacities demand related lengths
  refine ⟨out, next, ?_, preserved, ?_, specification⟩
  · simp [indexedMemoryExecute, _root_.Verity.Contract.run, executed]
  · intro address outside
    exact IndexedMemory.loop_frame (wordMemory state) ap cp buckets capacities demand zero out.amount next
      related executed address outside

/-- A proved indexing failure rolls back all effects of an executed enclosing
enclosing, including arbitrary changes to storage, balances, events and memory. -/
theorem indexed_after_prefix_reverts (enclosing : _root_.Verity.Contract Unit)
    (entry intermediate : _root_.Verity.ContractState) (ap cp : Nat)
    (buckets capacities : List Word) (demand : Word)
    (prefixExecuted : enclosing entry = .success () intermediate)
    (related : MemoryWrite.ArraysAt (wordMemory intermediate) ap cp buckets capacities)
    (positive : demand.val ≠ 0) (short : capacities.length < buckets.length) :
    (_root_.Verity.bind enclosing (fun _ => indexedMemoryExecute ap cp demand)).run entry =
      .revert (reprStr Panic.arrayBounds) entry := by
  have failed := IndexedMemory.run_short_error (wordMemory intermediate) ap cp buckets capacities demand
    related positive short
  simp [_root_.Verity.bind, _root_.Verity.Contract.run, prefixExecuted, indexedMemoryExecute, failed]

#print axioms indexed_after_prefix_reverts

#print axioms indexed_memory_run_success

#print axioms memory_run_success

#print axioms run_exact
#print axioms state_preserved
#print axioms canonical_outcome
end LidoSRv3.Audit.Source.TrioAlloc2.Runtime
