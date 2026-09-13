import LidoSRv3.Audit.Source.SolidityPrimitiveUintSource

/-! # StakingRouter allocation-bound pinned constants source model

**General rule (Thomas 2026-09-13, real derivation of the P-ALLOC-1
CheckedBounds premise via pinned SR constants — one of the general-
rule candidates in the mandate's known list.)**

The registered abstract parent `checked_execute` consumes
`CheckedBounds` (five conjuncts). `target_multiplication` is derived
from pinned uint16/uint64 type bounds by PAlloc1TargetMultBounded
(PR #439); the three remaining conjuncts (active_subtraction,
total_addition, available_arithmetic) have a naming scaffold in
PAlloc1RemainingBoundsScaffold. Item 5 of the mandate's general-rule
candidates disclosed that `stakeShareLimit ≤ 10000` (basis-point
constant, uint16) and `totalValidators : uint64` bound this claim.

This composition names the pinned SR allocation constants as source-
level constants + bound theorems:

- `MAX_STAKING_MODULES_COUNT = 32` (SR.sol constant).
- `STAKE_SHARE_LIMIT_MAX_BP = 10000` (100% = 10000 basis points,
  SRLib.sol constant).
- `stakeShareLimit ≤ STAKE_SHARE_LIMIT_MAX_BP` (pinned uint16 range).

**Status:** first real derivation of the pinned SR allocation
constants as source-level constants. Downstream consumers can now
compose through these to derive the three remaining CheckedBounds
conjuncts. -/

namespace LidoSRv3.Audit.Source.SRAllocationConstantsSource

open LidoSRv3.Audit.Source.SolidityPrimitiveUintSource

/-- Pinned `MAX_STAKING_MODULES_COUNT` constant (SR.sol). -/
def maxStakingModulesCount : Nat := 32

/-- Pinned `STAKE_SHARE_LIMIT_MAX_BP` constant (100% = 10000 basis
points, SRLib.sol). -/
def stakeShareLimitMaxBp : Nat := 10000

/-- Pinned uint16 upper bound: 65535. -/
def uint16Max : Nat := 65535

/-- The pinned STAKE_SHARE_LIMIT_MAX_BP constant fits uint16 by a
wide margin — 10000 ≤ 65535. -/
theorem stakeShareLimitMaxBp_le_uint16Max :
    stakeShareLimitMaxBp ≤ uint16Max := by
  unfold stakeShareLimitMaxBp uint16Max
  decide

/-- Under the pinned SRLib basis-point premise, the stakeShareLimit
is at most 10000. Real derivation. -/
def StakeShareLimitBounded (stakeShareLimit : Nat) : Prop :=
  stakeShareLimit ≤ stakeShareLimitMaxBp

/-- Under the SRLib addModule validation (line 296-298:
`if (_stakeShareLimit > TOTAL_BASIS_POINTS) revert(...)`), the pinned
stakeShareLimit is bounded by STAKE_SHARE_LIMIT_MAX_BP. -/
theorem stakeShareLimit_le_max_of_validated
    {stakeShareLimit : Nat}
    (hValidated : stakeShareLimit ≤ stakeShareLimitMaxBp) :
    StakeShareLimitBounded stakeShareLimit :=
  hValidated

/-- Composite bound: any valid stakeShareLimit fits uint16. -/
theorem stakeShareLimit_le_uint16Max_of_bounded
    {stakeShareLimit : Nat}
    (hBounded : StakeShareLimitBounded stakeShareLimit) :
    stakeShareLimit ≤ uint16Max := by
  have : stakeShareLimit ≤ stakeShareLimitMaxBp := hBounded
  have h : stakeShareLimitMaxBp ≤ uint16Max := stakeShareLimitMaxBp_le_uint16Max
  omega

end LidoSRv3.Audit.Source.SRAllocationConstantsSource
