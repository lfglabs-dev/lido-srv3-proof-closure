import LidoSRv3.Audit.Source.TrioAlloc1.Initialization

/-! # Kill-lines for `TrioAlloc1.Initialization.slot` + `versionWord`

**Chantier 3 (Piste A, Thomas 2026-09-13) mutant kill-lines pinning
the pinned OZ Initializable ERC-7201 slot and packed
version/flag update semantics. -/

namespace LidoSRv3.Tests.TrioAlloc1InitializationSlotKillLines

open LidoSRv3.Audit.Source.TrioAlloc1
open LidoSRv3.Audit.Source.TrioAlloc1.Initialization

/-- **Kill-line: pinned OZ Initializable ERC-7201 slot.**

`keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.Initializable"))
 - 1)) & ~bytes32(uint256(0xff))` = 0xf0c57e16...6a00. -/
theorem slot_pinned :
    slot = word 0xf0c57e16840df040f15088dc2f81fe391c3923bec73e23a9662efc9c229c6a00 :=
  rfl

/-- **Kill-line: slot's low byte is 0 (ERC-7201 zero-page requirement).** -/
theorem slot_zero_lowbyte :
    slot.val % 256 = 0 := by decide

/-- **Kill-line: slot fits uint256.** -/
theorem slot_fits_uint256 :
    slot.val < 2 ^ 256 := by decide

/-- **Kill-line: `versionWord` composition.**

`versionWord original version = word (original / 2^64 * 2^64 + version)`. -/
theorem versionWord_composition (orig : Word) (version : Fin (2^64)) :
    versionWord orig version =
      word (orig.val / 2 ^ 64 * 2 ^ 64 + version.val) := rfl

/-- **Kill-line: `versionWord` clears the low 64 bits before writing.**

`versionWord ⟨0, _⟩ 42 = word 42`. -/
theorem versionWord_zero_orig :
    versionWord (word 0) ⟨42, by decide⟩ = word 42 := by decide

/-- **Kill-line: `flagWord` composition.**

`flagWord original flag = word (original % 2^64 + flag*2^64 + original / 2^72 * 2^72)`. -/
theorem flagWord_composition (orig : Word) (flag : Bool) :
    flagWord orig flag =
      word (orig.val % 2 ^ 64 +
            (if flag then 1 else 0) * 2 ^ 64 +
            orig.val / 2 ^ 72 * 2 ^ 72) := rfl

/-- **Kill-line: `flagWord (word 0) true` sets the low bit at offset 64.** -/
theorem flagWord_zero_true :
    flagWord (word 0) true = word (2 ^ 64) := by decide

/-- **Kill-line: `flagWord (word 0) false` = word 0.** -/
theorem flagWord_zero_false :
    flagWord (word 0) false = word 0 := by decide

#print axioms slot_pinned
#print axioms slot_zero_lowbyte
#print axioms versionWord_composition
#print axioms versionWord_zero_orig
#print axioms flagWord_composition
#print axioms flagWord_zero_true
#print axioms flagWord_zero_false

end LidoSRv3.Tests.TrioAlloc1InitializationSlotKillLines
