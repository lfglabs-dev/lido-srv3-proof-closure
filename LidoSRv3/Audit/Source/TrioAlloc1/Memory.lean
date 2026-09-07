import LidoSRv3.Audit.Source.TrioAlloc1.Properties
import LidoSRv3.Audit.Source.TrioAlloc1.Bytes

/-!
Constructive word-memory bridge for the v0 interface. The compiler-byte-memory
refinement is a separate gate: this construction alone does not certify solc.
-/
namespace LidoSRv3.Audit.Source.TrioAlloc1

/-- Length-prefixed, byte-addressed word array. Values outside element slots are zero. -/
def arrayWords (pointer : Nat) (values : List Word) : MemoryWords := fun address =>
  if address = pointer then word values.length
  else if pointer < address ∧ (address-pointer) % 32 = 0 then
    values[(address-pointer)/32-1]?.getD (word 0)
  else word 0

theorem arrayWords_related (pointer : Nat) (values : List Word)
    (bound : values.length < 2^256) : ArrayAt (arrayWords pointer values) pointer values := by
  constructor
  · simp [arrayWords, word, Nat.mod_eq_of_lt bound]
  · intro i
    have lt : pointer < pointer + 32 * (i.val+1) := by omega
    simp [arrayWords, lt, Nat.add_sub_cancel_left]

/-- Two fresh regions retain all elements, including capacities below allocation. -/
def arraysMemory (output : CapacityOutput) (ap cp : Nat) : MemoryWords := fun address =>
  if address < cp then arrayWords ap output.allocations address
  else arrayWords cp output.capacities address

theorem arraysMemory_related (output : CapacityOutput) (ap cp : Nat)
    (separated : ap + 32*(output.allocations.length+1) ≤ cp)
    (endBound : cp + 32*(output.capacities.length+1) ≤ 2^256) :
    MemoryArraysRelated (arraysMemory output ap cp) ap cp output := by
  have hlen := output_lengths_equal output
  have ab : output.allocations.length < 2^256 := by omega
  have cb : output.capacities.length < 2^256 := by omega
  have ar := arrayWords_related ap output.allocations ab
  have cr := arrayWords_related cp output.capacities cb
  have apcp : ap < cp := by omega
  refine ⟨⟨?_, ?_⟩, ⟨?_, ?_⟩, ?_, endBound, Or.inl separated⟩
  · simpa only [arraysMemory, if_pos apcp] using ar.1
  · intro i
    have before : ap + 32*(i.val+1) < cp := by have hi := i.isLt; omega
    simpa only [arraysMemory, if_pos before] using ar.2 i
  · simpa only [arraysMemory, Nat.lt_irrefl, ↓reduceIte] using cr.1
  · intro i
    have after : ¬ cp + 32*(i.val+1) < cp := by omega
    simpa only [arraysMemory, if_neg after] using cr.2 i
  · omega

/-- Successful producer lengths are the stored count, including paused rows. -/
theorem producer_length_from_storage (l : Layout) (s : Storage) (oracle : StaticOracle)
    (input : CapacityInput) (before after : Transcript) (output : CapacityOutput)
    (h : produce l s oracle input before = (.ok output, after)) :
    output.allocations.length = (s (countSlot l)).val ∧
    output.capacities.length = (s (countSlot l)).val := by
  have order := producer_router_order l s oracle input before after output h
  change output.identities = routerOrder l s at order
  have lengths := congrArg List.length order
  simp only [routerOrder, List.length_map, List.length_range] at lengths
  exact ⟨output.allocations_length.trans lengths, output.capacities_length.trans lengths⟩

/-- Explicit bytes for the two arrays with arbitrary intervening cache memory. -/
def outputBytes (output : CapacityOutput) (pre gap : Bytes) : Bytes :=
  pre ++ encodeArray output.allocations ++ gap ++ encodeArray output.capacities

theorem outputBytes_related (output : CapacityOutput) (pre gap : Bytes)
    (bound : (outputBytes output pre gap).length ≤ 2^256) :
    MemoryArraysRelated (fun address => decodeWord (outputBytes output pre gap) address)
      pre.length (pre ++ encodeArray output.allocations ++ gap).length output := by
  have hb := bound
  simp only [outputBytes, List.length_append, encodeArray_length] at hb
  have ab : output.allocations.length < 2^256 := by omega
  have cb : output.capacities.length < 2^256 := by omega
  have ar := encodedArray_related output.allocations pre
    (gap ++ encodeArray output.capacities) ab
  have cr := encodedArray_related output.capacities
    (pre ++ encodeArray output.allocations ++ gap) [] cb
  refine ⟨?_, ?_, ?_, ?_, Or.inl ?_⟩
  · simpa only [outputBytes, List.append_assoc] using ar
  · simpa only [outputBytes, List.append_nil] using cr
  · omega
  · simpa only [List.length_append, encodeArray_length] using hb
  · simp only [List.length_append, encodeArray_length]
    omega

end LidoSRv3.Audit.Source.TrioAlloc1
