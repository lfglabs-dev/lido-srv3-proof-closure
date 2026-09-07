import LidoSRv3.Audit.Source.TrioComposition.MemoryTransportReturn
import LidoSRv3.Audit.Source.TrioComposition.ProducerStores
import LidoSRv3.Audit.Source.TrioComposition.FinalMemoryCaller

/-! Observed source-level closed-library boundary. The configured library target
is recorded, not proved deployed. The local compiler relation must identify this
DELEGATECALL, its selector/arguments, separate callee memory, and return-copy
primitives. No bytecode, gas, deployment, or cryptographic fidelity is asserted.
The library executes its real byte decoder and allocation algorithm; arbitrary
input memory can produce ABI rejection or source panic, with raw bytes retained.
-/
namespace LidoSRv3.Audit.Source.TrioComposition.MemoryTransportCall
open TrioAlloc1
open MemoryTransport

inductive Kind where
  | staticCall
  | delegateCall
  deriving DecidableEq, Repr

structure Request where
  kind : Kind
  target : Address
  /-- No ETH is transferred by this DELEGATECALL. Inherited msg.value is not modeled. -/
  transferredValue : Word
  payload : Bytes
  deriving DecidableEq, Repr

structure Event where
  request : Request
  response : CallResponse
  deriving DecidableEq, Repr

abbrev Trace := List Event
abbrev Action (α : Type) := Trace → Except Failure α × Trace

def pureAction (value : α) : Action α := fun trace => (.ok value,trace)
def bindAction (first : Action α) (next : α → Action β) : Action β := fun trace =>
  match first trace with
  | (.error reason,after) => (.error reason,after)
  | (.ok value,after) => next value after

instance : Monad Action where
  pure := pureAction
  bind := bindAction

def selector : Bytes := [byte 0x25,byte 0x29,byte 0xfb,byte 0xc9]

def request (target : Address) (memory : MemoryWords) (ap cp : Nat) (demand : Word) : Request :=
  ⟨.delegateCall,target,word 0,
    selector ++ TrioAlloc2.LibraryABI.encodeArguments (argumentsFromMemory memory ap cp demand)⟩

def response : Except Bytes Bytes → CallResponse
  | .ok bytes => .returned bytes
  | .error bytes => .reverted bytes

def event (target : Address) (memory : MemoryWords) (ap cp : Nat) (demand : Word) : Event :=
  ⟨request target memory ap cp demand,response (libraryFromMemory memory ap cp demand)⟩

/-- The attempted call and its raw successful/reverting response are appended
before any caller return decoding or allocation checks execute. -/
def closedCall (target : Address) (memory : MemoryWords) (ap cp : Nat) (demand : Word) :
    Action (Except Bytes Bytes) := fun trace =>
  (.ok (libraryFromMemory memory ap cp demand),trace ++ [event target memory ap cp demand])

def finish (pointer : Word) (reply : Except Bytes Bytes) : Action TrioAlloc2.StepOutput :=
  fun trace => (FinalMemoryCaller.canonicalReply pointer reply,trace)

def callAndDecode (target : Address) (memory : MemoryWords) (ap cp : Nat)
    (demand pointer : Word) : Action TrioAlloc2.StepOutput := do
  let reply ← closedCall target memory ap cp demand
  finish pointer reply

theorem closedCall_projection (target : Address) (memory : MemoryWords) (ap cp : Nat)
    (demand : Word) (trace : Trace) :
    (closedCall target memory ap cp demand trace).1 = .ok
      (TrioAlloc2.LibraryABI.run
        (TrioAlloc2.LibraryABI.encodeArguments (argumentsFromMemory memory ap cp demand))) := rfl

theorem callAndDecode_exact (target : Address) (memory : MemoryWords) (ap cp : Nat)
    (demand pointer : Word) (trace : Trace) :
    callAndDecode target memory ap cp demand pointer trace =
      (FinalMemoryCaller.canonicalReply pointer (libraryFromMemory memory ap cp demand),
       trace ++ [event target memory ap cp demand]) := rfl

/-- Exact prefix extension is independent of success, revert, decoder failure,
and return allocation panic. The event cannot disappear on a later failure. -/
theorem attempted_trace (target : Address) (memory : MemoryWords) (ap cp : Nat)
    (demand pointer : Word) (trace : Trace) :
    (callAndDecode target memory ap cp demand pointer trace).2 =
      trace ++ [event target memory ap cp demand] := rfl

theorem reverting_call (target : Address) (memory : MemoryWords) (ap cp : Nat)
    (demand pointer : Word) (trace : Trace) (bytes : Bytes)
    (reverted : libraryFromMemory memory ap cp demand = .error bytes) :
    callAndDecode target memory ap cp demand pointer trace =
      (.error (.revertData bytes), trace ++
        [⟨request target memory ap cp demand,.reverted bytes⟩]) := by
  rw [callAndDecode_exact, reverted, FinalMemoryCaller.library_failure]
  simp only [event, reverted, response]

theorem decode_failure_retains_call (target : Address) (memory : MemoryWords) (ap cp : Nat)
    (demand pointer : Word) (trace : Trace) (reason : Failure)
    (failed : FinalMemoryCaller.canonicalReply pointer
      (libraryFromMemory memory ap cp demand) = .error reason) :
    callAndDecode target memory ap cp demand pointer trace =
      (.error reason,trace ++ [event target memory ap cp demand]) := by
  rw [callAndDecode_exact,failed]

def staticEvent (observation : CallObservation) : Event :=
  ⟨⟨.staticCall,observation.request.target,word 0,observation.request.payload⟩,observation.response⟩

/-- Evaluation always extends the transcript, including failed source executions.
Thus removing the initial prefix cannot discard any newly attempted call. -/
theorem evaluate_extends (oracle : StaticOracle) (program : CallTree.Program α)
    (before : Transcript) :
    ∃ suffix, (CallTree.evaluate oracle program before).2 = before ++ suffix := by
  induction program generalizing before with
  | done result => exact ⟨[],(List.append_nil before).symm⟩
  | call request next ih =>
    obtain ⟨suffix,extended⟩ := ih (oracle before request)
      (before ++ [⟨request,oracle before request⟩])
    refine ⟨⟨request,oracle before request⟩ :: suffix, ?_⟩
    simpa only [CallTree.evaluate,List.append_assoc,List.cons_append,List.nil_append] using extended

theorem evaluate_prefix_drop (oracle : StaticOracle) (program : CallTree.Program α)
    (before : Transcript) :
    (CallTree.evaluate oracle program before).2 =
      before ++ ((CallTree.evaluate oracle program before).2.drop before.length) := by
  obtain ⟨suffix,extended⟩ := evaluate_extends oracle program before
  rw [extended]
  simp

/-- Source producer writes first; its static-call observations remain in order,
then the distinct configured library call is observed. The supplied full trace
already contains prior observations, so only this invocation's suffix is appended. -/
def producerThenCall (target : Address) (memory : MemoryWords) (ap cp : Nat)
    (l : Layout) (s : Storage) (oracle : StaticOracle) (input : CapacityInput)
    (pointer : Word) (before : Transcript) : Action TrioAlloc2.StepOutput := fun trace =>
  match CallTree.evaluate oracle (ProducerStores.producer memory ap cp l s input) before with
  | (.error reason,after) => (.error reason,trace ++ (after.drop before.length).map staticEvent)
  | (.ok (_,final),after) =>
    callAndDecode target final ap cp input.depositsToAllocate pointer
      (trace ++ (after.drop before.length).map staticEvent)

/-- Nonempty-prefix regression: a zero-count producer performs no static calls;
its preexisting observation appears once, immediately before the library event. -/
theorem nonempty_before_no_duplication (target : Address) (memory : MemoryWords) (ap cp : Nat)
    (l : Layout) (oracle : StaticOracle) (input : CapacityInput) (pointer : Word)
    (prior : CallObservation) :
    producerThenCall target memory ap cp l (fun _ => word 0) oracle input pointer
      [prior] [staticEvent prior] =
      callAndDecode target (zeroArray (zeroArray memory ap 0) cp 0) ap cp
        input.depositsToAllocate pointer [staticEvent prior] := by
  rfl

/-- No final MemoryArraysRelated or library success is assumed. Per-row producer
stores derive the memory relation, and the allocation specification proves
success of the closed library invoked from those actual memory reads. -/
theorem producer_observed_library_distributes
    (target : Address) (memory : MemoryWords) (ap cp : Nat)
    (l : Layout) (s : Storage) (oracle : StaticOracle) (input : CapacityInput)
    (before after : Transcript) (output : CapacityOutput) (final : MemoryWords)
    (executed : CallTree.evaluate oracle (ProducerStores.producer memory ap cp l s input) before =
      (.ok (output,final),after))
    (separate : Disjoint ap (s (countSlot l)).val cp (s (countSlot l)).val)
    (aend : ap+32*((s (countSlot l)).val+1) ≤ 2^256)
    (cend : cp+32*((s (countSlot l)).val+1) ≤ 2^256)
    (countBound : (s (countSlot l)).val ≤ 32)
    (pointer : Word) (space : pointer.val+96+32*(s (countSlot l)).val ≤ 2^32)
    (trace : Trace) :
    ∃ result,
      producerThenCall target memory ap cp l s oracle input pointer before trace =
        (.ok result,trace ++ (after.drop before.length).map staticEvent ++
          [⟨request target final ap cp input.depositsToAllocate,
            .returned (TrioAlloc2.LibraryABI.encodeReturn result)⟩]) ∧
      TrioAlloc2.Spec.Distributes (TrioAlloc2.decodedRows output.allocations output.capacities)
        input.depositsToAllocate.val result.amount.val
        (TrioAlloc2.decodedRows result.buckets output.capacities) ∧
      result.buckets.length = (s (countSlot l)).val := by
  obtain ⟨source,related⟩ := ProducerStores.success memory ap cp l s oracle input before after
    output final executed separate aend cend
  have lengths := producer_length_from_storage l s oracle input before after output source
  have args : argumentsFromMemory final ap cp input.depositsToAllocate =
      TrioAlloc2.producerArguments output input.depositsToAllocate := by
    simp only [argumentsFromMemory,TrioAlloc2.producerArguments,
      TrioAlloc2.readMemoryArray_eq final ap output.allocations related.1,
      TrioAlloc2.readMemoryArray_eq final cp output.capacities related.2.1]
  have argumentBound : (TrioAlloc2.LibraryABI.encodeArguments
      (argumentsFromMemory final ap cp input.depositsToAllocate)).length < 2^64 := by
    rw [args]
    exact FinalMemoryCaller.producer_extent l s oracle input before after output source countBound
  obtain ⟨result,ran,distributes⟩ := TrioAlloc2.producer_then_memory_consumer_distributes
    l s oracle input before after output source final ap cp related
  have ordinary := ran
  rw [TrioAlloc2.allocateMemory_eq final ap cp output input.depositsToAllocate related] at ordinary
  have resultLength : result.buckets.length = (s (countSlot l)).val :=
    (TrioAlloc2.allocate_preserves_length _ _ _ _ ordinary).trans lengths.1
  have raw : libraryFromMemory final ap cp input.depositsToAllocate =
      .ok (TrioAlloc2.LibraryABI.encodeReturn result) := by
    rw [libraryFromMemory_exact final ap cp input.depositsToAllocate argumentBound,ran]
    rfl
  refine ⟨result,?_,distributes,resultLength⟩
  simp only [producerThenCall,executed,callAndDecode_exact,raw,
    FinalMemoryCaller.canonicalReply_exact pointer (s (countSlot l)) result resultLength space countBound,
    event,response]
/-- For the returned canonical bytes the source transport performs raw-buffer
stores and a live decoder copy; both retain the actual producer allocation array. -/
theorem observed_return_preserves_original
    (target : Address) (memory : MemoryWords) (ap cp decoded : Nat) (demand pointer : Word)
    (trace : Trace) (result : TrioAlloc2.StepOutput) (original : List Word)
    (raw : libraryFromMemory memory ap cp demand = .ok (TrioAlloc2.LibraryABI.encodeReturn result))
    (related : ArrayAt memory ap original)
    (beforeBuffer : ap+32*(original.length+1) ≤ pointer.val)
    (fresh : pointer.val+32*(result.buckets.length+3) ≤ decoded)
    (extent : decoded+32*(result.buckets.length+1) ≤ 2^64) :
    (closedCall target memory ap cp demand trace).2 = trace ++
      [⟨request target memory ap cp demand,.returned (TrioAlloc2.LibraryABI.encodeReturn result)⟩] ∧
    ArrayAt (decodeStagedReturn memory pointer.val decoded result) decoded result.buckets ∧
    ArrayAt (decodeStagedReturn memory pointer.val decoded result) ap original ∧
    TrioAlloc2.readMemoryArray (decodeStagedReturn memory pointer.val decoded result) ap = original := by
  refine ⟨?_,staged_return_arrays memory ap pointer.val decoded result original
    related beforeBuffer fresh extent⟩
  simp only [closedCall,event,raw,response]

#print axioms attempted_trace
#print axioms evaluate_prefix_drop
#print axioms nonempty_before_no_duplication
#print axioms reverting_call
#print axioms producer_observed_library_distributes
#print axioms observed_return_preserves_original
end LidoSRv3.Audit.Source.TrioComposition.MemoryTransportCall
