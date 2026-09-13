import LidoSRv3.Audit.Source.KeccakMappingStorageSource

/-! # Kill-lines for `KeccakMappingStorageSource`

**Chantier 2 (Piste A, Thomas 2026-09-13) mutant kill-lines pinning
mapping-storage and packed-slot-decoder projection semantics.** -/

namespace LidoSRv3.Tests.KeccakMappingStorageKillLines

open LidoSRv3.Audit.Source.KeccakMappingStorageSource

/-- **Kill-line: `read` projects `slotAt`.** -/
theorem read_projection (m : MappingStorage) (k : Nat) :
    read m k = m.slotAt k := rfl

/-- **Kill-line: `read` distinguishes distinct keys under a witness mapping.** -/
theorem read_distinguishes_keys :
    read { slotAt := fun k => if k = 5 then 42 else 100 } 5 ≠
      read { slotAt := fun k => if k = 5 then 42 else 100 } 7 := by
  decide

/-- **Kill-line: `read` returns the constant for constant mapping.** -/
theorem read_constant_at_witness :
    read { slotAt := fun _ => 99 } 42 = 99 := rfl

/-- **Kill-line: `decodeField` projects `extract`.** -/
theorem decodeField_projection (d : PackedSlotDecoder) (offset width : Nat) :
    decodeField d offset width = d.extract offset width := rfl

/-- **Kill-line: `decodeField` distinguishes distinct offsets.** -/
theorem decodeField_distinguishes_offsets :
    decodeField { slotWord := 0
                  extract := fun o _ => if o = 8 then 42 else 100 } 8 1 ≠
      decodeField { slotWord := 0
                    extract := fun o _ => if o = 8 then 42 else 100 } 16 1 := by
  decide

#print axioms read_projection
#print axioms read_distinguishes_keys
#print axioms read_constant_at_witness
#print axioms decodeField_projection
#print axioms decodeField_distinguishes_offsets

end LidoSRv3.Tests.KeccakMappingStorageKillLines
