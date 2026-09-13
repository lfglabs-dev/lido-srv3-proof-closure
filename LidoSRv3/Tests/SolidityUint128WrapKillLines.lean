import LidoSRv3.Audit.Source.SolidityUint128WrapSource

/-! # Kill-lines for `SolidityUint128WrapSource`

**Chantier 2 (Piste A, Thomas 2026-09-13) mutant kill-lines pinning
the pinned uint128 wrap semantics.**

The pinned Solidity 0.4.24 helpers use raw `remaining -=` (unchecked
wrap) on uint128 fields.  `SolidityUint128WrapSource` names:
- `uint128Modulus = 2^128`.
- `uint128Max = 2^128 - 1`.
- `toUint128 x = x % uint128Modulus`.
- `wrappedAdd a b = (a + b) % uint128Modulus`.
- `checkedAddOverflow a b = a + b ≥ uint128Modulus`.

These kill-lines exhibit concrete counterexamples for weakened
formulations of `toUint128_idem`, `wrappedAdd`-truncation, and
`checkedAddOverflow` boundary cases — demonstrating that each pinned
wrap-semantics definition is load-bearing. -/

namespace LidoSRv3.Tests.SolidityUint128WrapKillLines

open LidoSRv3.Audit.Source.SolidityUint128WrapSource

/-- **Kill-line: `toUint128` truncates non-trivially at the boundary.**

Applied to `x = uint128Modulus`, `toUint128 x = 0` — the truncation
maps the exact boundary value to zero.  A mutant that identity-mapped
`toUint128` would break this. -/
theorem toUint128_at_boundary_is_zero :
    toUint128 uint128Modulus = 0 := by
  unfold toUint128 uint128Modulus
  decide

/-- **Kill-line: `toUint128` is not the identity on values ≥ modulus.**

The pinned truncation maps `2^128 + 1 → 1`.  A mutant that identity-
mapped `toUint128` would fail to produce `1`. -/
theorem toUint128_wraps_above_modulus :
    toUint128 (uint128Modulus + 1) = 1 := by
  unfold toUint128 uint128Modulus
  decide

/-- **Kill-line: `wrappedAdd` wraps at the boundary.**

`wrappedAdd uint128Max 1 = 0` — the checked-add boundary.  A mutant
that used mathematical `+` without mod would produce `uint128Modulus`
instead. -/
theorem wrappedAdd_at_boundary_is_zero :
    wrappedAdd uint128Max 1 = 0 := by
  unfold wrappedAdd uint128Max uint128Modulus
  decide

/-- **Kill-line: `checkedAddOverflow` fires at the boundary.**

`checkedAddOverflow uint128Max 1 = true` — exactly at the wrap
boundary.  A mutant that returned `false` here would fail to detect
overflow. -/
theorem checkedAddOverflow_fires_at_boundary :
    checkedAddOverflow uint128Max 1 = true := by
  unfold checkedAddOverflow uint128Max uint128Modulus
  decide

/-- **Kill-line: `checkedAddOverflow` is false strictly under
modulus.**

`checkedAddOverflow (uint128Max - 1) 1 = false` — just under the
wrap boundary.  A mutant that flagged overflow one step early would
fail this. -/
theorem checkedAddOverflow_stays_false_under_boundary :
    checkedAddOverflow (uint128Max - 1) 1 = false := by
  unfold checkedAddOverflow uint128Max uint128Modulus
  decide

/-- **Kill-line: uint128Modulus is exactly `2^128`.** -/
theorem uint128Modulus_is_2_pow_128 :
    uint128Modulus = 2 ^ 128 := rfl

/-- **Kill-line: uint128Max is exactly `2^128 - 1`.** -/
theorem uint128Max_is_2_pow_128_minus_1 :
    uint128Max = 2 ^ 128 - 1 := rfl

#print axioms toUint128_at_boundary_is_zero
#print axioms toUint128_wraps_above_modulus
#print axioms wrappedAdd_at_boundary_is_zero
#print axioms checkedAddOverflow_fires_at_boundary
#print axioms checkedAddOverflow_stays_false_under_boundary
#print axioms uint128Modulus_is_2_pow_128
#print axioms uint128Max_is_2_pow_128_minus_1

end LidoSRv3.Tests.SolidityUint128WrapKillLines
