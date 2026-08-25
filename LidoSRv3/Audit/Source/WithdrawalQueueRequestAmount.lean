/-!
# WithdrawalQueue single-request amount predicate

This is a deliberately narrow, source-shaped reading of
`WithdrawalQueue.requestWithdrawals` at
`lidofinance/core@af095e48bbc1c3841c2c9936219c8461af01056b`,
`contracts/0.8.9/WithdrawalQueue.sol:125-135`, together with its internal
`_checkWithdrawalRequestAmount` predicate at lines 395-402.

For one `stETH` list item, the Solidity predicate commits exactly when
`100 <= amount <= 1000 * 10^18`. This module models only that predicate and
its direct success/revert result. It does **not** model the surrounding
pause check, owner fallback, ERC-20 approve/transfer/redeem completeness, share
conversion, enqueue/mint, ERC-721 transfer, permit, WstETH, claiming,
finalization, ETH, oracle, allocation, D1, or V1 surfaces. In particular it
is not a `P-TOKEN` parent and is intentionally not registered in the public
guarantee facade.
-/

namespace LidoSRv3.Audit.Source.WithdrawalQueueRequestAmount

/-- `MIN_STETH_WITHDRAWAL_AMOUNT` in the pinned Solidity source, line 52. -/
def minStethWithdrawalAmount : Nat := 100

/-- `MAX_STETH_WITHDRAWAL_AMOUNT` in the pinned Solidity source, line 57. -/
def maxStethWithdrawalAmount : Nat := 1000 * 10 ^ 18

/-- The two ordered guards in `_checkWithdrawalRequestAmount` (lines 395-402).
Unlike a free Boolean input, this is computed from the request amount. -/
def checkedWithdrawalRequestAmount (amount : Nat) : Bool :=
  decide (minStethWithdrawalAmount ≤ amount) &&
    decide (amount ≤ maxStethWithdrawalAmount)

inductive Outcome where
  | reverted
  | committed
  deriving DecidableEq, Repr

/-- The single-item projection of `requestWithdrawals`' amount check. -/
def requestWithdrawalsSingle (amount : Nat) : Outcome :=
  if checkedWithdrawalRequestAmount amount then .committed else .reverted

/-- Exact narrow parent shape: every committed single-item amount is within
the two constants from the pinned Solidity predicate. -/
def SingleRequestAmountBound (run : Nat → Outcome) : Prop :=
  ∀ amount, run amount = .committed →
    minStethWithdrawalAmount ≤ amount ∧ amount ≤ maxStethWithdrawalAmount

/-- The honest source-shaped single-item transition satisfies its amount bound.
The conclusion is non-tautological: `amount` is universally quantified and
the bound is recovered from the computed guard, not assumed as an input flag. -/
theorem requestWithdrawals_single_request_amount_bound :
    SingleRequestAmountBound requestWithdrawalsSingle := by
  intro amount h
  unfold requestWithdrawalsSingle at h
  split at h
  · simp_all [checkedWithdrawalRequestAmount]
  · cases h

/-- Concrete lower and upper boundary regressions for the pinned predicate. -/
theorem pinned_amount_boundaries :
    requestWithdrawalsSingle (minStethWithdrawalAmount - 1) = .reverted ∧
    requestWithdrawalsSingle minStethWithdrawalAmount = .committed ∧
    requestWithdrawalsSingle maxStethWithdrawalAmount = .committed ∧
    requestWithdrawalsSingle (maxStethWithdrawalAmount + 1) = .reverted := by
  decide

end LidoSRv3.Audit.Source.WithdrawalQueueRequestAmount
