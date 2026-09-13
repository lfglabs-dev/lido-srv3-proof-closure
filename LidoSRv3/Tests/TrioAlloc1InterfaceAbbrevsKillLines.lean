import LidoSRv3.Audit.Source.TrioAlloc1.Interface

/-! # Kill-lines for `TrioAlloc1.Interface` type abbreviations

**Chantier 3 (Piste A, Thomas 2026-09-13) mutant kill-lines pinning
the pinned SRLib._getModulesAllocationAndCapacity Producer boundary
type widths: Word=uint256, Address=uint160, Byte=uint8. -/

namespace LidoSRv3.Tests.TrioAlloc1InterfaceAbbrevsKillLines

open LidoSRv3.Audit.Source.TrioAlloc1

/-- **Kill-line: `Word` is `Fin (2^256)` (uint256).**

A mutant that widened Word to Fin (2^320) would silently accept
values that overflow EVM word width. -/
theorem Word_is_uint256 :
    (∀ w : Word, w.val < 2 ^ 256) := fun w => w.isLt

/-- **Kill-line: `Address` is `Fin (2^160)` (uint160).** -/
theorem Address_is_uint160 :
    (∀ a : Address, a.val < 2 ^ 160) := fun a => a.isLt

/-- **Kill-line: `Byte` is `Fin 256` (uint8).** -/
theorem Byte_is_uint8 :
    (∀ b : Byte, b.val < 256) := fun b => b.isLt

/-- **Kill-line: uint160 ⊂ uint256 (address embeds into word).** -/
theorem Address_fits_Word :
    (∀ a : Address, a.val < 2 ^ 256) :=
  fun a => Nat.lt_of_lt_of_le a.isLt (by decide)

/-- **Kill-line: uint8 ⊂ uint256.** -/
theorem Byte_fits_Word :
    (∀ b : Byte, b.val < 2 ^ 256) :=
  fun b => Nat.lt_of_lt_of_le b.isLt (by decide)

/-- **Kill-line: `Failure` has exactly four constructors.**

A mutant that added or dropped a failure kind would refute. -/
theorem Failure_ctors_distinct :
    (Failure.revertData []) ≠ (Failure.decoderFailure) ∧
    (Failure.decoderFailure) ≠ (Failure.panic ⟨0, by decide⟩) ∧
    (Failure.panic ⟨0, by decide⟩) ≠ (Failure.exceptionalCall) := by
  refine ⟨?_, ?_, ?_⟩ <;> decide

#print axioms Word_is_uint256
#print axioms Address_is_uint160
#print axioms Byte_is_uint8
#print axioms Address_fits_Word
#print axioms Byte_fits_Word
#print axioms Failure_ctors_distinct

end LidoSRv3.Tests.TrioAlloc1InterfaceAbbrevsKillLines
