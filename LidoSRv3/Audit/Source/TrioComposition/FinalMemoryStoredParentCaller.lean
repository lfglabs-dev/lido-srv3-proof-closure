import LidoSRv3.Audit.Source.TrioComposition.FinalMemoryStoredParentMemory

namespace LidoSRv3.Audit.Source.TrioComposition.FinalMemoryStoredParentCaller
open TrioAlloc1
open MemoryTransport
open FinalMemoryStoredParentMemory

/-- Zero-demand allocation precedes every in-place conversion operation. -/
def zeroReply (memory : MemoryWords) (ap buffer count unit : Word) : Except Failure Output := do
  let ending ← AllocationMemory.allocateArray buffer count
  zero (zeroArray memory buffer.val count.val) ap buffer ending count unit

/-- Copy/allocate the actual raw response before total and row conversions. -/
def positiveReply (memory : MemoryWords) (ap buffer count unit : Word) (reply : Except Bytes Bytes) :
    Except Failure Output := do
  let copied ← receive memory buffer reply
  positive copied.memory ap copied.decoded copied.pointer count unit copied.result.amount

theorem zeroReply_projection (memory : MemoryWords) (ap buffer count unit : Word) (xs : List Word)
    (related : ArrayAt memory ap.val xs) (hx : xs.length = count.val)
    (separate : ap.val+32*(count.val+1) ≤ buffer.val)
    (small : buffer.val ≤ 2^32) (hc : count.val ≤ 32) :
    (zeroReply memory ap buffer count unit).map observe =
      (convertZero unit count.val xs).map (fun rows => (⟨word 0,rows.1,rows.2⟩ : ParentOutput)) := by
  let ys := List.replicate count.val (word 0)
  have newAt := zeroArray_related memory buffer.val count.val (by omega)
  have oldAt : ArrayAt (zeroArray memory buffer.val count.val) ap.val xs := by
    apply storeArray_frame memory buffer.val ap.val ys xs
    · apply Or.inr
      simpa only [hx] using separate
    · exact related
  have arrays : MemoryTransportConversion.ArraysAt (zeroArray memory buffer.val count.val) ap.val buffer.val ⟨xs,ys⟩ :=
    ⟨oldAt,newAt,Or.inl (by simpa only [hx] using separate)⟩
  simp only [zeroReply,AllocationMemory.bounded_array_allocates buffer count small hc,bind,Except.bind]
  exact zero_projection _ ap buffer _ count unit xs ys arrays hx (List.length_replicate ..)

theorem positiveReply_projection (memory : MemoryWords) (ap buffer count unit : Word)
    (xs : List Word) (result : TrioAlloc2.StepOutput)
    (related : ArrayAt memory ap.val xs) (hx : xs.length = count.val)
    (hy : result.buckets.length = count.val)
    (beforeBuffer : ap.val+32*(count.val+1) ≤ buffer.val)
    (space : buffer.val+128+64*count.val ≤ 2^32) (hc : count.val ≤ 32) :
    (positiveReply memory ap buffer count unit (.ok (TrioAlloc2.LibraryABI.encodeReturn result))).map observe =
      (do let total ← checked (result.amount.val*unit.val)
          let rows ← convertPositive unit count.val xs result.buckets
          pure (⟨total,rows.1,rows.2⟩ : ParentOutput)) := by
  have decodedVal : (decodedPointer buffer count).val = buffer.val+96+32*count.val :=
    FinalMemoryRows.word_small _ (by omega)
  have fresh : buffer.val+32*(result.buckets.length+3) ≤ (decodedPointer buffer count).val := by
    rw [decodedVal,hy]; omega
  have extent : (decodedPointer buffer count).val+32*(result.buckets.length+1) ≤ 2^64 := by
    rw [decodedVal,hy]; omega
  have arrays := staged_return_arrays memory ap.val buffer.val (decodedPointer buffer count).val result xs
    related (by simpa only [hx] using beforeBuffer) fresh extent
  have paired : MemoryTransportConversion.ArraysAt
      (decodeStagedReturn memory buffer.val (decodedPointer buffer count).val result)
      ap.val (decodedPointer buffer count).val ⟨xs,result.buckets⟩ :=
    ⟨arrays.2.1,arrays.1,Or.inl (by rw [hx,decodedVal]; omega)⟩
  simp only [positiveReply,receive_canonical memory buffer count result hy hc space,bind,Except.bind]
  exact positive_projection _ ap _ _ count unit result.amount xs result.buckets paired hx hy

/-- Empty output owns two separately allocated empty arrays. -/
def empty (memory : MemoryWords) (pointer : Word) : Except Failure Output := do
  let rp ← AllocationMemory.allocateArray pointer (word 0)
  let first := zeroArray memory pointer.val 0
  let ending ← AllocationMemory.allocateArray rp (word 0)
  pure ⟨word 0,pointer,rp,ending,zeroArray first rp.val 0⟩

theorem empty_projection (memory : MemoryWords) (pointer : Word) (space : pointer.val+64 ≤ 2^32) :
    (empty memory pointer).map observe = .ok ⟨word 0,[],[]⟩ := by
  have small : pointer.val ≤ 2^32 := by omega
  have nextVal := FinalMemoryRows.word_small (pointer.val+32) (by omega)
  have nextSmall : (word (pointer.val+32)).val ≤ 2^32 := by rw [nextVal]; omega
  have first := zeroArray_related memory pointer.val 0 (by decide)
  have last := zeroArray_related (zeroArray memory pointer.val 0) (word (pointer.val+32)).val 0 (by decide)
  have kept : ArrayAt (zeroArray (zeroArray memory pointer.val 0) (word (pointer.val+32)).val 0) pointer.val [] := by
    apply storeArray_frame _ (word (pointer.val+32)).val pointer.val [] []
    · apply Or.inr
      rw [nextVal]; simp
    · exact first
  simp only [empty,AllocationMemory.bounded_array_allocates pointer (word 0) small (by decide),
    show (word 0).val = 0 from rfl,Nat.mul_zero,Nat.add_zero,bind,Except.bind,
    AllocationMemory.bounded_array_allocates _ (word 0) nextSmall (by decide)]
  change Except.ok (observe ⟨word 0,pointer,word (pointer.val+32),_,_⟩) = _
  simp only [observe,TrioAlloc2.readMemoryArray_eq _ pointer.val [] kept,
    TrioAlloc2.readMemoryArray_eq _ (word (pointer.val+32)).val [] last]

/-- The observed library call receives arrays read from the executed producer's
memory. Its raw reply is passed directly to caller copy/allocation/conversion. -/
def afterProducer (target : Address) (out : FinalMemoryStoredProducer.Output) (count unit demand : Word) :
    MemoryTransportCall.Action Output := do
  if demand.val > 0 then
    let reply ← MemoryTransportCall.closedCall target out.memory out.allocationPointer.val out.capacityPointer.val demand
    fun trace => (positiveReply out.memory out.allocationPointer out.pointer count unit reply,trace)
  else
    fun trace => (zeroReply out.memory out.allocationPointer out.pointer count unit,trace)

def decodedAfter (count : Nat) (config : Config) (demand : Word) (produced : CapacityOutput) : Except Failure ParentOutput := do
  if demand.val > 0 then
    let result ← libraryThroughABI produced demand
    let total ← checked (result.amount.val*config.maxEBType1.val)
    let rows ← convertPositive config.maxEBType1 count produced.allocations result.buckets
    pure ⟨total,rows.1,rows.2⟩
  else
    (convertZero config.maxEBType1 count produced.allocations).map (fun rows => ⟨word 0,rows.1,rows.2⟩)

/-- A later failure retains the delegate event; zero demand does not create it. -/
theorem afterProducer_trace (target : Address) (out : FinalMemoryStoredProducer.Output)
    (count unit demand : Word) (trace : MemoryTransportCall.Trace) :
    (afterProducer target out count unit demand trace).2 =
      if demand.val > 0 then trace ++ [MemoryTransportCall.event target out.memory
        out.allocationPointer.val out.capacityPointer.val demand] else trace := by
  by_cases positive : demand.val > 0 <;>
    simp [afterProducer,positive,bind,MemoryTransportCall.bindAction,MemoryTransportCall.closedCall]

/-- The reached producer execution supplies all array, raw-return, and allocator
premises. No library or conversion success is a hypothesis of the parent proof. -/
theorem afterProducer_projection (target : Address) (memory : MemoryWords) (pointer : Word)
    (l : Layout) (s : Storage) (oracle : StaticOracle) (input : CapacityInput)
    (before after : Transcript) (out : FinalMemoryStoredProducer.Output)
    (executed : CallTree.evaluate oracle (FinalMemoryStoredProducer.producer memory pointer l s input) before = (.ok out,after))
    (hc : (s (countSlot l)).val ≤ 32)
    (space : pointer.val+1184*(s (countSlot l)).val+576 ≤ 2^32)
    (trace : MemoryTransportCall.Trace) :
    (afterProducer target out (s (countSlot l)) input.config.maxEBType1 input.depositsToAllocate trace).1.map observe =
      decodedAfter (s (countSlot l)).val input.config input.depositsToAllocate out.produced := by
  have producerSpace : pointer.val+1120*(s (countSlot l)).val+448 ≤ 2^32 := by omega
  obtain ⟨source,related,apEq,cpEq,endEq⟩ := FinalMemoryStoredProducer.success memory pointer l s oracle input before after out executed hc producerSpace
  have lengths := producer_length_from_storage l s oracle input before after out.produced source
  have geometry := FinalMemoryStoredProducer.bounds pointer l s producerSpace
  have endBound := FinalMemoryStoredProducer.finalPointer_bound pointer l s producerSpace
  have callerSpace : out.pointer.val+128+64*(s (countSlot l)).val ≤ 2^32 := by rw [endEq]; omega
  have endValue : out.pointer.val = out.capacityPointer.val+32*(s (countSlot l)).val+32 := by
    rw [endEq,cpEq]
    apply FinalMemoryRows.word_small
    have := geometry.capacity_end
    omega
  have beforeBuffer : out.allocationPointer.val+32*((s (countSlot l)).val+1) ≤ out.pointer.val := by
    rw [apEq,endValue,cpEq]
    have := geometry.separate
    omega
  by_cases pos : input.depositsToAllocate.val > 0
  · obtain ⟨result,ran,decoded,len,_⟩ := FinalMemoryCaller.producer_canonical_shape l s oracle input before after out.produced source hc
    have arguments : argumentsFromMemory out.memory out.allocationPointer.val out.capacityPointer.val input.depositsToAllocate =
        TrioAlloc2.producerArguments out.produced input.depositsToAllocate := by
      simp only [argumentsFromMemory,TrioAlloc2.producerArguments,
        TrioAlloc2.readMemoryArray_eq _ _ _ related.1,TrioAlloc2.readMemoryArray_eq _ _ _ related.2.1]
    have raw : libraryFromMemory out.memory out.allocationPointer.val out.capacityPointer.val input.depositsToAllocate =
        .ok (TrioAlloc2.LibraryABI.encodeReturn result) := by rw [libraryFromMemory,arguments]; exact ran
    have library : libraryThroughABI out.produced input.depositsToAllocate = .ok result := by
      unfold libraryThroughABI
      simp only [ran,decoded]
    simp only [afterProducer,pos,↓reduceIte,bind,MemoryTransportCall.bindAction,MemoryTransportCall.closedCall,raw,
      decodedAfter,library,Except.bind]
    exact positiveReply_projection out.memory out.allocationPointer out.pointer (s (countSlot l))
      input.config.maxEBType1 out.produced.allocations result related.1 lengths.1 len beforeBuffer callerSpace hc
  · simp only [afterProducer,pos,↓reduceIte,decodedAfter]
    exact zeroReply_projection out.memory out.allocationPointer out.pointer (s (countSlot l))
      input.config.maxEBType1 out.produced.allocations related.1 lengths.1 beforeBuffer (by omega) hc

#print axioms zeroReply_projection
#print axioms positiveReply_projection
#print axioms empty_projection
#print axioms afterProducer_projection
#print axioms afterProducer_trace
end LidoSRv3.Audit.Source.TrioComposition.FinalMemoryStoredParentCaller
