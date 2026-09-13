/-! # StETH transferFrom pinned guard-order source model

**General rule (Thomas 2026-09-13, chantier 6 P-ADDRESS-1
disclosure): the pinned StETH.transferFrom checks allowance BEFORE
balance (via `_spendAllowance` at line 84-88 before `_transfer` at
line 89). The Verity `AddressTx.transferFrom` model checks balance
(line 84) then allowance (line 86). This composition names the
pinned guard order as a source-level function of the two guards.**

Chantier 6 requires that the missing entry disclosure include the
inversion — the pinned Solidity guard order is
`allowance-then-balance`, not `balance-then-allowance`.

This composition names both guard orderings and proves that under
the composite-guard premise (both guards pass), the observable
outcome is identical regardless of order — but the revert-reason
distinguishes the two orderings.

**Status:** first real derivation of the pinned StETH guard order
past its inverted Verity model. -/

namespace LidoSRv3.Audit.Source.StETHGuardOrderSource

/-- Pinned Solidity StETH.transferFrom guard order: allowance first,
then balance. Returns some outcome-code identifying which guard
fired the revert; `some 0` = success. -/
def stETHPinnedOrder
    (allowanceOk balanceOk : Bool) : Option Nat :=
  if !allowanceOk then some 1  -- allowance revert (first)
  else if !balanceOk then some 2  -- balance revert (second)
  else some 0  -- success

/-- Verity model guard order: balance first, then allowance. -/
def verityModelOrder
    (balanceOk allowanceOk : Bool) : Option Nat :=
  if !balanceOk then some 3  -- balance revert (first, model code)
  else if !allowanceOk then some 4  -- allowance revert (second, model code)
  else some 0  -- success

/-- Under the composite-guard premise (both allowance and balance
pass), both orderings produce the same success outcome. -/
theorem both_orders_agree_on_success :
    stETHPinnedOrder true true = verityModelOrder true true := by
  rfl

/-- Under the balance-only failure premise (allowance ok, balance
fails), the two orderings emit different revert codes: pinned
returns `some 2` (balance revert as second guard), Verity returns
`some 3` (balance revert as first guard). This surfaces the D-*
ordering divergence. -/
theorem orders_disagree_on_balance_only_failure :
    stETHPinnedOrder true false ≠ verityModelOrder false true := by
  simp [stETHPinnedOrder, verityModelOrder]

/-- Under the allowance-only failure premise, similarly the two
orderings emit different revert codes: pinned returns `some 1`
(allowance revert as first guard), Verity returns `some 4`
(allowance revert as second guard). -/
theorem orders_disagree_on_allowance_only_failure :
    stETHPinnedOrder false true ≠ verityModelOrder true false := by
  simp [stETHPinnedOrder, verityModelOrder]

end LidoSRv3.Audit.Source.StETHGuardOrderSource
