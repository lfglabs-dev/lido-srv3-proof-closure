import LidoSRv3.Audit.Model.AllocCapacity

/-! # Conditional bound for ALLOC target multiplication

[SRLib](https://github.com/lidofinance/core/blob/17005714f151e5502c559932319a3f2f74ac2436/contracts/0.8.25/sr/SRLib.sol#L506-L552)
uses a uint256 total accumulator. Its uint64 bound below is a caller premise,
not a Solidity field width. The stored share is uint16; using 10000 as a
divisor does not itself establish a bound on arbitrary stored share values.

The arithmetic theorem is retained unchanged: supplied uint16 share and uint64
total bounds imply the uint256 target product bound. `checked_execute` still
requires all five CheckedBounds fields. Supported summaries, total accumulation
and input/configuration bounds must be derived from actual producers/writers.
-/

namespace LidoSRv3.Audit.Guarantees.PAlloc1TargetMultBounded

open Verity
open Verity.Stdlib.Math
open LidoSRv3.Audit.AllocCapacity

/-- Numeric upper bound for the stored uint16 share field. -/
def uint16Max : Nat := 2 ^ 16 - 1

/-- Numeric bound used by the explicit total-accumulator premise below.
The source total accumulator itself is uint256. -/
def uint64Max : Nat := 2 ^ 64 - 1

/-- Conditional bounds on the share field and the
`totalValidators` accumulator: `shareLimit ≤ 2^16 - 1` and
`totalValidators cfg modules deposits ≤ 2^64 - 1`. -/
structure PinnedStakingModuleTypeBounds
    (cfg : Config) (modules : List Module) (depositsToAllocate : Uint256) : Prop where
  shareLimit_uint16 : ∀ m ∈ modules, (m.shareLimit : Nat) ≤ uint16Max
  totalValidators_uint64 :
    MathView.totalValidators cfg modules depositsToAllocate ≤ uint64Max

/-- Under the pinned type-bound premise,
`shareLimit * totalValidators ≤ uint16Max * uint64Max
≈ 1.2 * 10^24 << MAX_UINT256 = 2^256 - 1`. This is the
`target_multiplication` conjunct of `CheckedBounds`. -/
theorem target_multiplication_under_pinned_type_bounds
    {cfg : Config} {modules : List Module} {depositsToAllocate : Uint256}
    (hPinned : PinnedStakingModuleTypeBounds cfg modules depositsToAllocate) :
    ∀ m ∈ modules, m.isActive = true →
      (m.shareLimit : Nat) * MathView.totalValidators cfg modules depositsToAllocate
        ≤ Verity.Core.MAX_UINT256 := by
  intro m hMem _hActive
  have hShare : (m.shareLimit : Nat) ≤ uint16Max :=
    hPinned.shareLimit_uint16 m hMem
  have hTotal : MathView.totalValidators cfg modules depositsToAllocate ≤ uint64Max :=
    hPinned.totalValidators_uint64
  have hProduct : (m.shareLimit : Nat)
        * MathView.totalValidators cfg modules depositsToAllocate ≤
      uint16Max * uint64Max :=
    Nat.mul_le_mul hShare hTotal
  have hSmall : uint16Max * uint64Max ≤ Verity.Core.MAX_UINT256 := by
    unfold uint16Max uint64Max Verity.Core.MAX_UINT256
    decide
  exact Nat.le_trans hProduct hSmall

end LidoSRv3.Audit.Guarantees.PAlloc1TargetMultBounded
