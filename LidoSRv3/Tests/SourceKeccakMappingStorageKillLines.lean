import LidoSRv3.Audit.Source.KeccakMappingStorageSource

/-!
Kill-lines pinning `KeccakMappingStorageSource` — the abstract
key-value storage type + packed-slot decoder used by RESERVE-1,
TOPUP-1, and ADDRESS-1 consumers.
-/

namespace LidoSRv3.Tests.SourceKeccakMappingStorageKillLines

open LidoSRv3.Audit.Source.KeccakMappingStorageSource

/-! ## `MappingStorage.slotAt` is a `Nat → Nat` function. -/

private def constant42 : MappingStorage := { slotAt := fun _ => 42 }

theorem mapping_slotAt_constant :
    constant42.slotAt 5 = 42 := rfl

/-! ## `read` = `slotAt` (definitional). -/

theorem read_eq_slotAt (m : MappingStorage) (k : Nat) :
    read m k = m.slotAt k :=
  read_eq m k

/-! ## Different keys can share a value in the abstract model. -/

theorem read_constant_witness :
    read constant42 0 = read constant42 999 := by decide

/-! ## `PackedSlotDecoder` — bit-range extraction. -/

private def extractZero : PackedSlotDecoder :=
  { slotWord := 0, extract := fun _ _ => 0 }

private def constAt5 : PackedSlotDecoder :=
  { slotWord := 0, extract := fun _ _ => 5 }

theorem decoder_slotWord : extractZero.slotWord = 0 := rfl

theorem decoder_extract_reduces
    (d : PackedSlotDecoder) (o w : Nat) :
    decodeField d o w = d.extract o w :=
  decodeField_eq d o w

theorem decoder_zero_extract :
    decodeField extractZero 0 8 = 0 := rfl

theorem decoder_constant_extract :
    decodeField constAt5 12 4 = 5 := rfl

/-! ## Determinism-like identity: same key ⇒ same value. -/

theorem read_same_key_same_value
    (m : MappingStorage) (k₁ k₂ : Nat) (h : k₁ = k₂) :
    read m k₁ = read m k₂ := by
  subst h; rfl

theorem decodeField_same_range_same_value
    (d : PackedSlotDecoder) (o₁ o₂ w₁ w₂ : Nat)
    (ho : o₁ = o₂) (hw : w₁ = w₂) :
    decodeField d o₁ w₁ = decodeField d o₂ w₂ := by
  subst ho; subst hw; rfl

end LidoSRv3.Tests.SourceKeccakMappingStorageKillLines
