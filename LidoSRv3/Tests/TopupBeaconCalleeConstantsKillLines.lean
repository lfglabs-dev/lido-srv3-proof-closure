import LidoSRv3.Audit.Source.TopupBeaconCallee

/-! # Kill-lines for `TopupBeaconCallee` selector + constants

**Chantier 1 (Piste A, Thomas 2026-09-13) mutant kill-lines pinning
the pinned deposit-contract `deposit(bytes,bytes,bytes,bytes32)`
selector, the count-slot storage position, and the uint32 depositor
count cap. -/

namespace LidoSRv3.Tests.TopupBeaconCalleeConstantsKillLines

open LidoSRv3.Audit.Source.TopupBeaconCallee

/-- **Kill-line: pinned deposit contract `deposit` selector.**

bytes4(keccak256("deposit(bytes,bytes,bytes,bytes32)")) = 0x22895118. -/
theorem selector_pinned : selector = 0x22895118 := rfl

/-- **Kill-line: pinned `deposit_count` storage slot.**

The deposit contract's `deposit_count` field sits at slot 32 per
the pinned 0.6.11 layout. -/
theorem countSlot_pinned : countSlot = 32 := rfl

/-- **Kill-line: pinned uint32 maxCount.**

The deposit contract caps the count at 2^32 - 1. -/
theorem maxCount_pinned : maxCount = 2 ^ 32 - 1 := rfl

/-- **Kill-line: maxCount fits uint32.** -/
theorem maxCount_fits_uint32 : maxCount < 2 ^ 32 := by decide

/-- **Kill-line: maxCount = 4294967295 (concrete decimal).** -/
theorem maxCount_decimal : maxCount = 4294967295 := by decide

/-- **Kill-line: selector fits uint32 (bytes4).** -/
theorem selector_fits_uint32 : selector < 2 ^ 32 := by decide

/-- **Kill-line: selector is non-zero.** -/
theorem selector_nonzero : selector ≠ 0 := by decide

#print axioms selector_pinned
#print axioms countSlot_pinned
#print axioms maxCount_pinned
#print axioms maxCount_fits_uint32
#print axioms maxCount_decimal
#print axioms selector_fits_uint32
#print axioms selector_nonzero

end LidoSRv3.Tests.TopupBeaconCalleeConstantsKillLines
