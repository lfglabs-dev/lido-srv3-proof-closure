import LidoSRv3.Audit.Source.SolidityPrimitiveUintSource

/-! # P-TOPUP-2 pinned uint64 bounds source model (chantier 4bis)

**General rule (Thomas 2026-09-13, chantier 4bis composition
premise): under the TopUpGateway construction of limits at
TopUpGateway.sol:226 (`topUpLimits[i] = _evaluateTopUpLimit(...) * 1
gwei`), the evaluator is bounded by `targetBalanceGwei : uint64` and
the number of keys by `maxValidatorsPerTopUp : uint64`. Each
admitted allocation at line 729 is ≤ 2^64 * 10^9, so the sum over
≤ 2^64 keys is < 2^256 — no wrap.

This composition names the pinned uint64 bounds and derives the
per-allocation cap via the primitive `toUint64`. -/

namespace LidoSRv3.Audit.Source.Topup2Uint64BoundsSource

open LidoSRv3.Audit.Source.SolidityPrimitiveUintSource

/-- Pinned uint64 upper bound: 2^64 - 1. -/
def uint64Max : Nat := 2 ^ 64 - 1

/-- Pinned uint64 modulus: 2^64. -/
def uint64Modulus : Nat := 2 ^ 64

/-- Pinned wei-per-gwei: 10^9. -/
def gweiToWeiFactor : Nat := 10 ^ 9

/-- Pinned "targetBalanceGwei" is a uint64 field. -/
def TargetBalanceGweiBounded (targetBalanceGwei : Nat) : Prop :=
  targetBalanceGwei ≤ uint64Max

/-- Pinned "maxValidatorsPerTopUp" is a uint64 field. -/
def MaxValidatorsPerTopUpBounded (maxValidatorsPerTopUp : Nat) : Prop :=
  maxValidatorsPerTopUp ≤ uint64Max

/-- Per-allocation cap: each admitted allocation is ≤
`uint64Max * 10^9` (2^64 * gwei). -/
def allocationCap : Nat := uint64Max * gweiToWeiFactor

/-- Under the pinned uint64 targetBalanceGwei bound, the per-
allocation limit is bounded by allocationCap. Real derivation from
the pinned uint64 type + gwei conversion. -/
theorem allocationLimit_le_cap
    {targetBalanceGwei : Nat}
    (hBounded : TargetBalanceGweiBounded targetBalanceGwei) :
    targetBalanceGwei * gweiToWeiFactor ≤ allocationCap := by
  unfold allocationCap
  have h1 : targetBalanceGwei ≤ uint64Max := hBounded
  exact Nat.mul_le_mul_right gweiToWeiFactor h1

end LidoSRv3.Audit.Source.Topup2Uint64BoundsSource
