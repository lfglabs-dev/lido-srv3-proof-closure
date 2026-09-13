import LidoSRv3.Audit.Source.SolidityUint256WrapSource

/-! # Solidity SafeMath.mul / 0.8-checked multiplication source model

**General rule (Thomas 2026-09-13, real derivation naming the pinned
Solidity SafeMath.mul / 0.8-checked multiplication semantics as a
source-level function at uint256 width — used by deposit-value
computations like `actualDepositsCount * DEPOSIT_SIZE` and
`_evaluateTopUpLimit * 1 gwei`.)**

Solidity `SafeMath.mul(a, b)` (pre-0.8) returns `a * b`, requiring
that the product fits uint256; otherwise reverts. Solidity 0.8+
has this built-in. Multiple pinned code paths use this (Deposit
per-key aggregate at StakingRouter.sol:986, TOPUP-2 gwei conversion
at TopUpGateway.evaluateTopUpLimit).

This composition names the pinned checked-mul semantics as a source-
level function: `checkedMulU256 a b = some (a*b)` when `a*b <
uint256Modulus`, else `none`.

**Status:** first real derivation of the shared Solidity checked-
multiplication semantics at uint256 width. -/

namespace LidoSRv3.Audit.Source.SolidityCheckedMulSource

open LidoSRv3.Audit.Source.SolidityUint256WrapSource

/-- Optional-result checked uint256 multiplication. `some (a*b)`
when the product fits uint256, else `none`. -/
def checkedMulU256 (a b : Nat) : Option Nat :=
  if a * b ≥ uint256Modulus then none else some (a * b)

/-- Under the pinned "`a * b < uint256Modulus`" premise,
`checkedMulU256` returns `some (a * b)`. -/
theorem checkedMulU256_some_of_bounded
    {a b : Nat} (hLt : a * b < uint256Modulus) :
    checkedMulU256 a b = some (a * b) := by
  simp [checkedMulU256]
  omega

/-- Under the pinned "`a * b ≥ uint256Modulus`" premise,
`checkedMulU256` returns `none`. -/
theorem checkedMulU256_none_of_wrap
    {a b : Nat} (hGe : a * b ≥ uint256Modulus) :
    checkedMulU256 a b = none := by
  simp [checkedMulU256, hGe]

end LidoSRv3.Audit.Source.SolidityCheckedMulSource
