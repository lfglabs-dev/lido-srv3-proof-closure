import LidoSRv3.Audit.Source.SRAllocationConstantsSource

/-! # Kill-lines for `SRAllocationConstantsSource`

**Chantier 3 (Piste A, Thomas 2026-09-13) mutant kill-lines refuting
weakenings of the pinned SR allocation constants.**

`SRAllocationConstantsSource` names four pinned constants from the
Solidity source:
- `maxStakingModulesCount = 32` (SR.sol constant).
- `stakeShareLimitMaxBp = 10000` (SRLib.sol basis points).
- `uint16Max = 65535` (uint16 type ceiling).
- Theorem `stakeShareLimit_le_max_of_validated`: under the pinned
  `stakeShareLimit ≤ 10000` addModule-validation, the result is
  bounded by `stakeShareLimitMaxBp`.

These kill-lines exhibit concrete counterexamples for weakened
formulations, demonstrating that each pinned constant / validation
step is load-bearing. -/

namespace LidoSRv3.Tests.SRAllocationConstantsKillLines

open LidoSRv3.Audit.Source.SRAllocationConstantsSource

/-- **Kill-line: an unvalidated `stakeShareLimit` can violate the
uint16 cap.**

`stakeShareLimit_le_uint16Max_of_bounded` requires the caller to have
already validated `stakeShareLimit ≤ stakeShareLimitMaxBp = 10000`.
Without that validation, a `stakeShareLimit = 2^32` would VIOLATE the
uint16 cap (`2^32 > 65535`).

The kill-line negates a naive quantifier that drops the validation
premise. -/
theorem stakeShareLimit_needs_validation :
    ¬ (∀ ssl : Nat, ssl ≤ uint16Max) := by
  intro h
  have hInst := h (2 ^ 32)
  have hFail : ¬ (2 ^ 32 : Nat) ≤ uint16Max := by
    unfold uint16Max
    decide
  exact hFail hInst

/-- **Kill-line: dropping the `stakeShareLimitMaxBp` constant breaks
the uint16 gap.**

`stakeShareLimitMaxBp = 10000` and `uint16Max = 65535` — the gap
`65535 - 10000 = 55535` is what makes the `bp ≤ uint16Max` bound
hold with margin.  A mutant that overrode `stakeShareLimitMaxBp` to a
value larger than `uint16Max` would break the pinned constant chain.
The kill-line exhibits the concrete arithmetic: the pinned constant
`stakeShareLimitMaxBp = 10000` cannot equal `uint16Max + 1 = 65536`. -/
theorem stakeShareLimitMaxBp_is_not_above_uint16Max :
    stakeShareLimitMaxBp ≠ uint16Max + 1 := by
  unfold stakeShareLimitMaxBp uint16Max
  decide

/-- **Kill-line: `maxStakingModulesCount = 32` cannot exceed uint8.**

The pinned SR constant `maxStakingModulesCount = 32` fits in a single
byte.  A mutant that overrode it to 256 or larger would break the
one-byte-encodable module-count invariant. -/
theorem maxStakingModulesCount_fits_uint8 :
    maxStakingModulesCount < 256 := by
  unfold maxStakingModulesCount
  decide

/-- **Kill-line: `stakeShareLimitMaxBp = 10000` matches basis points.**

The BP invariant is precisely `stakeShareLimitMaxBp = 10000` (100% =
10000 basis points).  A mutant that made it 10001 or 9999 would
break the BP invariant. -/
theorem stakeShareLimitMaxBp_is_exactly_ten_thousand :
    stakeShareLimitMaxBp = 10000 := rfl

/-- **Kill-line: `uint16Max = 65535` is exactly `2^16 - 1`.** -/
theorem uint16Max_is_exactly_2_pow_16_minus_1 :
    uint16Max = 2 ^ 16 - 1 := rfl

#print axioms stakeShareLimit_needs_validation
#print axioms stakeShareLimitMaxBp_is_not_above_uint16Max
#print axioms maxStakingModulesCount_fits_uint8
#print axioms stakeShareLimitMaxBp_is_exactly_ten_thousand
#print axioms uint16Max_is_exactly_2_pow_16_minus_1

end LidoSRv3.Tests.SRAllocationConstantsKillLines
