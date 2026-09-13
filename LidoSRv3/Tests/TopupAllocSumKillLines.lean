import LidoSRv3.Audit.Source.TopupCorrespondence

/-! # Kill-lines for `TopupCorrespondence.allocSum` and `allocSumUnchecked`

**Chantier 1 (Piste A, Thomas 2026-09-13) mutant kill-lines pinning
the pinned `StakingRouter.sol:722-732` per-index `amount +=
allocations[i]` accumulation in both exact (`allocSum`) and
unchecked-block modular (`allocSumUnchecked`) forms. -/

namespace LidoSRv3.Tests.TopupAllocSumKillLines

open LidoSRv3.Audit.SolidityTopup

/-- **Kill-line: empty list sums to zero.** -/
theorem allocSum_empty : allocSum [] = 0 := rfl

/-- **Kill-line: singleton list sums to the element.** -/
theorem allocSum_singleton : allocSum [42] = 42 := rfl

/-- **Kill-line: two-element sum.** -/
theorem allocSum_two : allocSum [3, 4] = 7 := rfl

/-- **Kill-line: three-element sum.** -/
theorem allocSum_three : allocSum [100, 200, 50] = 350 := rfl

/-- **Kill-line: `uint256Modulus = 2^256`.** -/
theorem uint256Modulus_pinned : uint256Modulus = 2 ^ 256 := rfl

/-- **Kill-line: `allocSumUnchecked` empty = 0.** -/
theorem allocSumUnchecked_empty : allocSumUnchecked [] = 0 := rfl

/-- **Kill-line: `allocSumUnchecked` on small sums matches allocSum.** -/
theorem allocSumUnchecked_small :
    allocSumUnchecked [3, 4] = 7 := by decide

/-- **Kill-line: `allocSumUnchecked_eq_mod` universal identity.**

`allocSumUnchecked as = allocSum as % 2^256`. -/
theorem allocSumUnchecked_universal_mod (as : List Nat) :
    allocSumUnchecked as = allocSum as % uint256Modulus :=
  allocSumUnchecked_eq_mod as

#print axioms allocSum_empty
#print axioms allocSum_singleton
#print axioms allocSum_two
#print axioms uint256Modulus_pinned
#print axioms allocSumUnchecked_small
#print axioms allocSumUnchecked_universal_mod

end LidoSRv3.Tests.TopupAllocSumKillLines
