import audit.trio.alloc2.composition.ProducerMemory
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

#print axioms run_exact
#print axioms state_preserved
#print axioms canonical_outcome
end LidoSRv3.Audit.Source.TrioAlloc2.Runtime
