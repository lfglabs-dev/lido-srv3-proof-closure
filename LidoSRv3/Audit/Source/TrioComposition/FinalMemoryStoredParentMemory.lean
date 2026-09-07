import LidoSRv3.Audit.Source.TrioComposition.FinalMemoryStoredProducer
import LidoSRv3.Audit.Source.TrioComposition.MemoryTransportCall
import LidoSRv3.Audit.Source.TrioComposition.MemoryTransportConversion

/-! Caller word-memory execution. Raw returned bytes are staged before allocation
checks, and the decoded array is copied from that live memory. Canonical raw
reply shape is proved by the closed producer/library composition, not assumed
of arbitrary external bytecode. Word-copy/byte-copy and omitted-buffer frame
relations remain explicit compiler boundaries. -/
namespace LidoSRv3.Audit.Source.TrioComposition.FinalMemoryStoredParentMemory
open TrioAlloc1
open MemoryTransport

structure Output where
  total : Word
  ap : Word
  rp : Word
  pointer : Word
  memory : MemoryWords

def observe (out : Output) : ParentOutput :=
  ⟨out.total,TrioAlloc2.readMemoryArray out.memory out.ap.val,
    TrioAlloc2.readMemoryArray out.memory out.rp.val⟩

def stageBytes (memory : MemoryWords) (buffer : Nat) (bytes : Bytes) : MemoryWords :=
  copyWords (fun address => decodeWord bytes address) 0 memory buffer ((bytes.length+31)/32)

def copyReturn (staged : MemoryWords) (buffer decoded : Nat) : MemoryWords :=
  let source := buffer+(staged (buffer+32)).val
  copyWordsLive staged source decoded ((staged source).val+1)

theorem stageBytes_canonical (memory : MemoryWords) (buffer : Nat) (result : TrioAlloc2.StepOutput) :
    stageBytes memory buffer (TrioAlloc2.LibraryABI.encodeReturn result) = stageReturn memory buffer result := by
  unfold stageBytes stageReturn returnWords
  have length : ((TrioAlloc2.LibraryABI.encodeReturn result).length+31)/32 = result.buckets.length+3 := by
    simp only [TrioAlloc2.LibraryABI.encodeReturn,List.length_append,encodeWord_length,encodeArray_length]
    omega
  rw [length]

theorem staged_offset (memory : MemoryWords) (buffer : Nat) (result : TrioAlloc2.StepOutput) :
    stageReturn memory buffer result (buffer+32) = word 64 := by
  have copied := copyWords_read (returnWords result) memory 0 buffer (result.buckets.length+3) ⟨1,by omega⟩
  change stageReturn memory buffer result (buffer+32) = returnWords result 32 at copied
  have offset := decodeWord_after_prefix (encodeWord result.amount) (word 64) (encodeArray result.buckets)
  simp only [encodeWord_length] at offset
  have value : returnWords result 32 = word 64 := by
    simpa only [returnWords,TrioAlloc2.LibraryABI.encodeReturn,List.append_assoc] using offset
  exact copied.trans value

theorem copyReturn_canonical (memory : MemoryWords) (buffer decoded : Nat) (result : TrioAlloc2.StepOutput) :
    copyReturn (stageBytes memory buffer (TrioAlloc2.LibraryABI.encodeReturn result)) buffer decoded =
      decodeStagedReturn memory buffer decoded result := by
  rw [stageBytes_canonical]
  simp only [copyReturn,staged_offset,show (word 64).val = 64 from rfl,decodeStagedReturn]

structure Received where
  result : TrioAlloc2.StepOutput
  decoded : Word
  pointer : Word
  memory : MemoryWords

/-- Successful raw-copy precedes finalize; canonical decode precedes array
allocation and the live forward copy. Failed call bytes bypass these operations. -/
def receive (memory : MemoryWords) (buffer : Word) (reply : Except Bytes Bytes) : Except Failure Received := do
  let bytes ← reply.mapError Failure.revertData
  let staged := stageBytes memory buffer.val bytes
  let decoded ← AllocationMemory.finalize buffer (word bytes.length)
  let result ← (TrioAlloc2.LibraryABI.decodeReturn bytes).mapError (fun _ => Failure.decoderFailure)
  let ending ← AllocationMemory.allocateArray decoded (word result.buckets.length)
  pure ⟨result,decoded,ending,copyReturn staged buffer.val decoded.val⟩

def decodedPointer (buffer count : Word) : Word := word (buffer.val+96+32*count.val)
def returnEnd (buffer count : Word) : Word := word (buffer.val+128+64*count.val)

theorem receive_canonical (memory : MemoryWords) (buffer count : Word) (result : TrioAlloc2.StepOutput)
    (lengthEq : result.buckets.length = count.val) (hc : count.val ≤ 32)
    (space : buffer.val+128+64*count.val ≤ 2^32) :
    receive memory buffer (.ok (TrioAlloc2.LibraryABI.encodeReturn result)) =
      .ok ⟨result,decodedPointer buffer count,returnEnd buffer count,
        decodeStagedReturn memory buffer.val (decodedPointer buffer count).val result⟩ := by
  have hp : buffer.val+96+32*count.val ≤ 2^32 := by omega
  have byteLength : (TrioAlloc2.LibraryABI.encodeReturn result).length = 96+32*count.val := by
    simp only [TrioAlloc2.LibraryABI.encodeReturn,List.length_append,encodeWord_length,encodeArray_length,lengthEq]
    omega
  have decoded := TrioAlloc2.LibraryABI.decodeReturn_encoded result (by omega)
  have countWord : word count.val = count := by apply Fin.ext; exact Nat.mod_eq_of_lt count.isLt
  have nextVal := FinalMemoryRows.word_small (buffer.val+96+32*count.val) hp
  have nextSmall : (word (buffer.val+96+32*count.val)).val ≤ 2^32 := by rw [nextVal]; exact hp
  have allocation : AllocationMemory.allocateArray (decodedPointer buffer count) count =
      .ok (returnEnd buffer count) := by
    simp only [decodedPointer,AllocationMemory.bounded_array_allocates _ count nextSmall hc,nextVal,returnEnd]
    exact congrArg Except.ok (congrArg word (by omega))
  have initial : AllocationMemory.finalize buffer (word (96+32*count.val)) =
      .ok (decodedPointer buffer count) := CallerMemory.canonical_finalize buffer count hp hc
  simp only [receive,Except.mapError,bind,Except.bind,byteLength,initial,decoded,
    lengthEq,countWord,allocation,copyReturn_canonical]
  rfl

/-- In-place row operations are executed before observing final array values. -/
def positive (memory : MemoryWords) (ap rp pointer count unit total : Word) : Except Failure Output := do
  let totalWei ← checked (total.val*unit.val)
  let final ← libraryResult (MemoryTransportConversion.positiveRows count.val 0 unit ap.val rp.val memory)
  pure ⟨totalWei,ap,rp,pointer,final⟩

def zero (memory : MemoryWords) (ap rp pointer count unit : Word) : Except Failure Output := do
  let final ← libraryResult (MemoryTransportConversion.zeroRows count.val 0 unit ap.val rp.val memory)
  pure ⟨word 0,ap,rp,pointer,final⟩

private theorem observed_rows (result : TrioAlloc2.Result MemoryWords) (ap rp pointer total : Word) :
    ((do let final ← libraryResult result; pure (⟨total,ap,rp,pointer,final⟩ : Output))).map observe =
      (libraryResult (result.map (MemoryTransportConversion.observe ap.val rp.val))).map
        (fun arrays => (⟨total,arrays.allocated,arrays.newAllocations⟩ : ParentOutput)) := by
  cases result with
  | error reason => cases reason <;> rfl
  | ok memory => rfl

theorem positive_projection (memory : MemoryWords) (ap rp pointer count unit total : Word)
    (xs ys : List Word) (related : MemoryTransportConversion.ArraysAt memory ap.val rp.val ⟨xs,ys⟩)
    (hx : xs.length = count.val) (hy : ys.length = count.val) :
    (positive memory ap rp pointer count unit total).map observe =
      (do let totalWei ← checked (total.val*unit.val)
          let rows ← convertPositive unit count.val xs ys
          pure (⟨totalWei,rows.1,rows.2⟩ : ParentOutput)) := by
  unfold positive
  cases product : checked (total.val*unit.val) with
  | error reason => rfl
  | ok totalWei =>
    change ((do let final ← libraryResult (MemoryTransportConversion.positiveRows count.val 0 unit ap.val rp.val memory)
                pure (⟨totalWei,ap,rp,pointer,final⟩ : Output))).map observe = _
    rw [observed_rows,MemoryTransportConversion.positive_equiv count.val unit ap.val rp.val memory xs ys related hx hy]
    cases convertPositive unit count.val xs ys <;> rfl

theorem zero_projection (memory : MemoryWords) (ap rp pointer count unit : Word)
    (xs ys : List Word) (related : MemoryTransportConversion.ArraysAt memory ap.val rp.val ⟨xs,ys⟩)
    (hx : xs.length = count.val) (hy : ys.length = count.val) :
    (zero memory ap rp pointer count unit).map observe =
      (convertZero unit count.val xs).map (fun rows => (⟨word 0,rows.1,rows.2⟩ : ParentOutput)) := by
  unfold zero
  rw [observed_rows,MemoryTransportConversion.zero_equiv count.val unit ap.val rp.val memory xs ys related hx hy]
  cases convertZero unit count.val xs <;> rfl

/-- Final output arrays are observations of the executed memory, including
its live headers, not stored ghost lists supplied as a postcondition. -/
theorem readMemoryArray_related (memory : MemoryWords) (pointer : Nat) :
    ArrayAt memory pointer (TrioAlloc2.readMemoryArray memory pointer) := by
  constructor
  · simp only [TrioAlloc2.readMemoryArray,List.length_ofFn]
  · intro i
    change memory (pointer+32*(i.val+1)) =
      (List.ofFn (fun j : Fin (memory pointer).val => memory (pointer+32*(j.val+1)))).get i
    simp

theorem observed_memory (out : Output) :
    ArrayAt out.memory out.ap.val (observe out).allocated ∧
    ArrayAt out.memory out.rp.val (observe out).newAllocations :=
  ⟨readMemoryArray_related _ _,readMemoryArray_related _ _⟩

#print axioms receive_canonical
#print axioms positive_projection
#print axioms zero_projection
#print axioms observed_memory
end LidoSRv3.Audit.Source.TrioComposition.FinalMemoryStoredParentMemory
