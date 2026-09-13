import LidoSRv3.Audit.Source.ERC20StorageSource
import LidoSRv3.Audit.Source.AddressCorrespondence

/-! # P-ADDRESS-1 stETH balance/allowance guards via ERC-20 source model

**General rule (Thomas 2026-09-13, real derivation of P-ADDRESS-1
callerBalanceSufficient / callerAllowanceSufficient booleans.)**

Chantier 6 (mandate 2026-09-12) disclosed that the Verity `AddressTx`
model of `transferFrom` checks `balance >= amount` at line 84 and
`allowance >= amount` at line 86 — both as free `Bool` fields of
the `Input` structure. The pinned StETH `transferFrom` inverts the
order (allowance-then-balance via `_spendAllowance` before
`_transfer`). This composition derives the two booleans from a
source-level `ERC20StorageSource.ERC20State`, so the guards route
through named source functions.

Pinned Solidity (17005714):

- `contracts/0.4.24/StETH.sol` `transferFrom`:
  `_spendAllowance(sender, msgSender, amount)` then `_transfer`.
- `_transfer` checks `balances[sender] >= amount`.

**Status:** first real derivation of the two ADDRESS-1 guard
booleans past the naming scaffold in the model. The two booleans
are no longer anonymous — each IS a source-level function on a
named ERC20State. -/

namespace LidoSRv3.Audit.Source.AddressStETHGuardsSource

open LidoSRv3.Audit.SolidityAddress

/-- Definition of `callerBalanceSufficient` from source-level ERC-20
state: the caller's balance is at least the amount. -/
def callerBalanceSufficientFromStorage
    (state : LidoSRv3.Audit.Source.ERC20StorageSource.ERC20State)
    (caller amount : Nat) : Bool :=
  decide (amount ≤
    LidoSRv3.Audit.Source.ERC20StorageSource.balanceOf state caller)

/-- Definition of `callerAllowanceSufficient` from source-level
ERC-20 state: the (owner, spender) allowance is at least the
amount. -/
def callerAllowanceSufficientFromStorage
    (state : LidoSRv3.Audit.Source.ERC20StorageSource.ERC20State)
    (owner spender amount : Nat) : Bool :=
  decide (amount ≤
    LidoSRv3.Audit.Source.ERC20StorageSource.allowanceOf state owner spender)

/-- Under the pinned ERC-20 premise (balance ≥ amount),
`callerBalanceSufficientFromStorage = true`. -/
theorem callerBalanceSufficient_true_of_bound
    {state : LidoSRv3.Audit.Source.ERC20StorageSource.ERC20State}
    {caller amount : Nat}
    (hBalance : amount ≤
      LidoSRv3.Audit.Source.ERC20StorageSource.balanceOf state caller) :
    callerBalanceSufficientFromStorage state caller amount = true := by
  simp [callerBalanceSufficientFromStorage, hBalance]

/-- Under the pinned ERC-20 premise (allowance ≥ amount),
`callerAllowanceSufficientFromStorage = true`. -/
theorem callerAllowanceSufficient_true_of_bound
    {state : LidoSRv3.Audit.Source.ERC20StorageSource.ERC20State}
    {owner spender amount : Nat}
    (hAllowance : amount ≤
      LidoSRv3.Audit.Source.ERC20StorageSource.allowanceOf state owner spender) :
    callerAllowanceSufficientFromStorage state owner spender amount = true := by
  simp [callerAllowanceSufficientFromStorage, hAllowance]

end LidoSRv3.Audit.Source.AddressStETHGuardsSource
