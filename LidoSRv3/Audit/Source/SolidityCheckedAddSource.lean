import LidoSRv3.Audit.Source.SolidityUint256WrapSource
import LidoSRv3.Audit.Source.SolidityUint128WrapSource

/-! # Solidity SafeMath.add / 0.8-checked addition source model

**General rule (Thomas 2026-09-13, real derivation naming the pinned
Solidity SafeMath.add / 0.8-checked addition semantics as source-
level functions at uint256 and uint128 widths.)**

Solidity `SafeMath.add(a, b)` (pre-0.8) returns `a + b`, requiring
that the sum fits the target uint width; otherwise reverts. Solidity
0.8+ has this built-in. Chained with the SolidityUint256WrapSource
(`checkedAddOverflow`), this composition returns an optional-typed
result.

**Status:** first real derivation of the shared Solidity checked-
add semantics at uint256 and uint128 widths, paired with the
existing wrap models. -/

namespace LidoSRv3.Audit.Source.SolidityCheckedAddSource

open LidoSRv3.Audit.Source.SolidityUint256WrapSource
open LidoSRv3.Audit.Source.SolidityUint128WrapSource

/-- Optional-result checked uint256 add. `some (a+b)` when the sum
fits uint256, else `none`. -/
def checkedAddU256 (a b : Nat) : Option Nat :=
  if a + b ≥ uint256Modulus then none else some (a + b)

/-- Optional-result checked uint128 add. `some (a+b)` when the sum
fits uint128, else `none`. -/
def checkedAddU128 (a b : Nat) : Option Nat :=
  if a + b ≥ uint128Modulus then none else some (a + b)

/-- Under the pinned "`a + b < uint256Modulus`" premise,
`checkedAddU256` returns `some (a + b)`. -/
theorem checkedAddU256_some_of_bounded
    {a b : Nat} (hLt : a + b < uint256Modulus) :
    checkedAddU256 a b = some (a + b) := by
  simp [checkedAddU256]
  omega

/-- Under the pinned "`a + b ≥ uint256Modulus`" premise,
`checkedAddU256` returns `none`. -/
theorem checkedAddU256_none_of_wrap
    {a b : Nat} (hGe : a + b ≥ uint256Modulus) :
    checkedAddU256 a b = none := by
  simp [checkedAddU256, hGe]

/-- Under the pinned "`a + b < uint128Modulus`" premise,
`checkedAddU128` returns `some (a + b)`. -/
theorem checkedAddU128_some_of_bounded
    {a b : Nat} (hLt : a + b < uint128Modulus) :
    checkedAddU128 a b = some (a + b) := by
  simp [checkedAddU128]
  omega

/-- Under the pinned "`a + b ≥ uint128Modulus`" premise,
`checkedAddU128` returns `none`. -/
theorem checkedAddU128_none_of_wrap
    {a b : Nat} (hGe : a + b ≥ uint128Modulus) :
    checkedAddU128 a b = none := by
  simp [checkedAddU128, hGe]

end LidoSRv3.Audit.Source.SolidityCheckedAddSource
