import LidoSRv3.Audit.Verity.TopupTx

/-! # Kill-lines for `Verity.TopupTx` beaconDeposit + allocateDeposits selectors

**Chantier 1 (Piste A, Thomas 2026-09-13) mutant kill-lines pinning
the two pinned Verity-plane ABI selectors and the fixed 96-byte
dummy signature. -/

namespace LidoSRv3.Tests.VerityTopupTxSelectorsKillLines

open LidoSRv3.Audit.Verity.TopupTx

/-- **Kill-line: pinned `deposit(bytes,bytes,bytes,bytes32)` selector.** -/
theorem beaconDepositSelector_pinned :
    beaconDepositSelector.val = 0x22895118 := by decide

/-- **Kill-line: pinned `allocateDeposits(uint256,bytes[],uint256[],
uint256[],uint256[])` selector.** -/
theorem allocateDepositsSelector_pinned :
    allocateDepositsSelector.val = 0x783b8a65 := by decide

/-- **Kill-line: both selectors fit uint32.** -/
theorem beaconDepositSelector_fits_uint32 :
    beaconDepositSelector.val < 2 ^ 32 := by decide
theorem allocateDepositsSelector_fits_uint32 :
    allocateDepositsSelector.val < 2 ^ 32 := by decide

/-- **Kill-line: both selectors are non-zero.** -/
theorem beaconDepositSelector_nonzero :
    beaconDepositSelector.val ≠ 0 := by decide
theorem allocateDepositsSelector_nonzero :
    allocateDepositsSelector.val ≠ 0 := by decide

/-- **Kill-line: the two selectors are distinct.** -/
theorem selectors_distinct :
    beaconDepositSelector.val ≠ allocateDepositsSelector.val := by decide

/-- **Kill-line: dummySignature has exactly 96 bytes.**

BeaconChainDepositor.sol:76 constructs a 96-byte `new bytes(SIGNATURE_LENGTH)`
buffer of zeros; a mutant would refute the length. -/
theorem dummySignature_length : dummySignature.length = 96 := by decide

/-- **Kill-line: every byte of dummySignature is zero.** -/
theorem dummySignature_all_zero : ∀ b ∈ dummySignature, b = 0 := by
  intro b hb
  have := List.mem_replicate.mp hb
  exact this.2

/-- **Kill-line: model module address is 0x5140.** -/
theorem moduleAddress_pinned :
    moduleAddress.toNat = 0x5140 := rfl

#print axioms beaconDepositSelector_pinned
#print axioms allocateDepositsSelector_pinned
#print axioms selectors_distinct
#print axioms dummySignature_length
#print axioms dummySignature_all_zero
#print axioms moduleAddress_pinned

end LidoSRv3.Tests.VerityTopupTxSelectorsKillLines
