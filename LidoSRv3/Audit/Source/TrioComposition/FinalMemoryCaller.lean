import LidoSRv3.Audit.Source.TrioComposition.CallerMemory

/-! Caller return allocations, with the executed LibraryABI byte reply. The
relation is deliberately restricted to canonical library replies: arbitrary
malformed return offsets may fail at different points during a physical decoder.
Canonical shape is derived below from every reached producer success. -/
namespace LidoSRv3.Audit.Source.TrioComposition.FinalMemoryCaller
open TrioAlloc1

/-- On canonical replies the raw response is finalized before the decoded array
is allocated. Library failure precedes both successful-return allocations. -/
def canonicalReply (pointer : Word) (reply : Except Bytes Bytes) :
    Except Failure TrioAlloc2.StepOutput := do
  let bytes ← reply.mapError Failure.revertData
  let next ← AllocationMemory.finalize pointer (word bytes.length)
  let result ← (TrioAlloc2.LibraryABI.decodeReturn bytes).mapError (fun _ => Failure.decoderFailure)
  let _ ← AllocationMemory.allocateArray next (word result.buckets.length)
  pure result

def library (pointer : Word) (produced : CapacityOutput) (demand : Word) :
    Except Failure TrioAlloc2.StepOutput :=
  canonicalReply pointer (TrioAlloc2.LibraryABI.run
    (TrioAlloc2.LibraryABI.encodeArguments (TrioAlloc2.producerArguments produced demand)))

theorem library_failure (pointer : Word) (bytes : Bytes) :
    canonicalReply pointer (.error bytes) = .error (.revertData bytes) := by simp [canonicalReply, Except.mapError, bind, Except.bind]

theorem canonicalReply_exact (pointer count : Word) (result : TrioAlloc2.StepOutput)
    (lengthEq : result.buckets.length = count.val)
    (hp : pointer.val+96+32*count.val ≤ 2^32) (hc : count.val ≤ 32) :
    canonicalReply pointer (.ok (TrioAlloc2.LibraryABI.encodeReturn result)) = .ok result := by
  have byteLength : (TrioAlloc2.LibraryABI.encodeReturn result).length = 96+32*count.val := by
    simp only [TrioAlloc2.LibraryABI.encodeReturn, List.length_append, encodeWord_length,
      encodeArray_length, lengthEq]
    omega
  have decoded := TrioAlloc2.LibraryABI.decodeReturn_encoded result (by omega)
  have countWord : word count.val = count := by
    apply Fin.ext
    exact Nat.mod_eq_of_lt count.isLt
  have nextVal : (word (pointer.val+96+32*count.val)).val = pointer.val+96+32*count.val :=
    Nat.mod_eq_of_lt (by omega)
  have nextSmall : (word (pointer.val+96+32*count.val)).val ≤ 2^32 := by rw [nextVal]; exact hp
  simp only [canonicalReply, Except.mapError, bind, Except.bind, byteLength,
    CallerMemory.canonical_finalize pointer count hp hc, decoded, lengthEq, countWord,
    AllocationMemory.bounded_array_allocates _ count nextSmall hc]
  rfl

/-- Producer length and the physical count bound establish the argument extent
without assuming a successful consumer or a packet-size premise. -/
theorem producer_extent (l : Layout) (s : Storage) (oracle : StaticOracle)
    (input : CapacityInput) (before after : Transcript) (produced : CapacityOutput)
    (executed : produce l s oracle input before = (.ok produced,after))
    (hc : (s (countSlot l)).val ≤ 32) :
    (TrioAlloc2.LibraryABI.encodeArguments
      (TrioAlloc2.producerArguments produced input.depositsToAllocate)).length < 2^64 := by
  have lengths := producer_length_from_storage l s oracle input before after produced executed
  simp only [TrioAlloc2.LibraryABI.encodeArguments, TrioAlloc2.producerArguments,
    List.length_append, encodeWord_length, encodeArray_length]
  omega

/-- A reached producer success establishes the actual raw return encoding,
array length and byte length. No callee success is postulated. -/
theorem producer_canonical_shape (l : Layout) (s : Storage) (oracle : StaticOracle)
    (input : CapacityInput) (before after : Transcript) (produced : CapacityOutput)
    (executed : produce l s oracle input before = (.ok produced,after))
    (hc : (s (countSlot l)).val ≤ 32) :
    ∃ result,
      TrioAlloc2.LibraryABI.run (TrioAlloc2.LibraryABI.encodeArguments
        (TrioAlloc2.producerArguments produced input.depositsToAllocate)) =
        .ok (TrioAlloc2.LibraryABI.encodeReturn result) ∧
      TrioAlloc2.LibraryABI.decodeReturn (TrioAlloc2.LibraryABI.encodeReturn result) = .ok result ∧
      result.buckets.length = (s (countSlot l)).val ∧
      (TrioAlloc2.LibraryABI.encodeReturn result).length = 96+32*(s (countSlot l)).val := by
  obtain ⟨result, ran, _, _, _⟩ := TrioAlloc2.producer_then_consumer_succeeds
    l s oracle input before after produced executed
  have lengths := producer_length_from_storage l s oracle input before after produced executed
  have resultLength : result.buckets.length = (s (countSlot l)).val := by
    rw [TrioAlloc2.allocate_preserves_length _ _ _ _ ran, lengths.1]
  refine ⟨result, ?_, TrioAlloc2.LibraryABI.decodeReturn_encoded result (by omega), resultLength, ?_⟩
  · rw [TrioAlloc2.LibraryABI.run_encoded _ (producer_extent l s oracle input before after produced executed hc)]
    change TrioAlloc2.LibraryABI.encodeOutcome
      (TrioAlloc2.allocate produced.allocations produced.capacities input.depositsToAllocate) = _
    rw [ran]; rfl
  · simp only [TrioAlloc2.LibraryABI.encodeReturn, List.length_append, encodeWord_length,
      encodeArray_length, resultLength]
    omega

theorem library_exact (pointer : Word) (l : Layout) (s : Storage) (oracle : StaticOracle)
    (input : CapacityInput) (before after : Transcript) (produced : CapacityOutput)
    (executed : produce l s oracle input before = (.ok produced,after))
    (hp : pointer.val+96+32*(s (countSlot l)).val ≤ 2^32)
    (hc : (s (countSlot l)).val ≤ 32) :
    library pointer produced input.depositsToAllocate =
      libraryThroughABI produced input.depositsToAllocate := by
  obtain ⟨result, ran, decoded, len, _⟩ := producer_canonical_shape l s oracle input before after produced executed hc
  have left : library pointer produced input.depositsToAllocate = .ok result := by
    unfold library
    exact (congrArg (canonicalReply pointer) ran).trans
      (canonicalReply_exact pointer (s (countSlot l)) result len hp hc)
  have right : libraryThroughABI produced input.depositsToAllocate = .ok result := by
    unfold libraryThroughABI
    simp only [ran, decoded]
  exact left.trans right.symm

/-- The zero-demand array is reserved before conversion. On positive demand,
raw reply finalization and canonical decoding precede both Ether conversions. -/
def afterProducer (pointer count : Word) (config : Config) (demand : Word)
    (produced : CapacityOutput) : CallTree.Program ParentOutput := do
  if demand.val > 0 then
    let result ← CallTree.check (library pointer produced demand)
    let total ← CallTree.check (checked (result.amount.val * config.maxEBType1.val))
    let (deltas,totals) ← CallTree.check
      (convertPositive config.maxEBType1 count.val produced.allocations result.buckets)
    pure ⟨total,deltas,totals⟩
  else
    CallerMemory.zero pointer count config produced

theorem afterProducer_exact (pointer : Word) (l : Layout) (s : Storage) (oracle : StaticOracle)
    (input : CapacityInput) (before after : Transcript) (produced : CapacityOutput)
    (executed : produce l s oracle input before = (.ok produced,after))
    (hp : pointer.val+96+32*(s (countSlot l)).val ≤ 2^32)
    (hc : (s (countSlot l)).val ≤ 32) :
    afterProducer pointer (s (countSlot l)) input.config input.depositsToAllocate produced =
      ParentCalls.afterProducer (s (countSlot l)).val input.config input.depositsToAllocate produced := by
  unfold afterProducer
  rw [library_exact pointer l s oracle input before after produced executed hp hc]
  by_cases positive : input.depositsToAllocate.val > 0
  · simp only [positive, ↓reduceIte, ParentCalls.afterProducer]
  · have zero : input.depositsToAllocate = word 0 := by
      apply Fin.ext
      simp only [word]; omega
    simp only [positive, ↓reduceIte]
    rw [CallerMemory.zero_exact pointer (s (countSlot l)) input.config produced (by omega) hc, zero]

#print axioms canonicalReply_exact
#print axioms producer_canonical_shape
#print axioms library_exact
#print axioms afterProducer_exact
end LidoSRv3.Audit.Source.TrioComposition.FinalMemoryCaller
