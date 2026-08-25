import LidoSRv3.Audit.Source.WithdrawalQueueRequestAmount

/-!
# WithdrawalQueue one-item request control projection (T2)

This is an executable, deliberately bounded control-flow projection of
`WithdrawalQueue.requestWithdrawals` at
`lidofinance/core@af095e48bbc1c3841c2c9936219c8461af01056b`,
`contracts/0.8.9/WithdrawalQueue.sol:125-135`.

For exactly one `stETH` amount it executes the two source decisions which are
local to that entrypoint before `_requestWithdrawal`: the zero-owner fallback
at line 130 and the amount predicate invoked at line 133 (whose body is at
lines 395-402).  Its domain deliberately excludes a zero `msg.sender`, which
is not an EVM-callable sender.  The projection stops before the line-134
external token and queue work; it does not pretend to model `STETH.transferFrom`,
share conversion, `_enqueue`, or `_emitTransfer`.

This is not a `P-TOKEN-1` parent and is intentionally not registered in the
public guarantee facade.  Approve, transfer, redeem, WstETH unwrap, ERC-721
transfer, permit, claims, finalization, ETH, oracle, allocation, D1, and V1
remain unsupported by this slice.
-/

namespace LidoSRv3.Audit.Source.WithdrawalQueueSingleRequestControl

open WithdrawalQueueRequestAmount

/-- Minimal address domain for the source-level `address(0)` branch. -/
abbrev Address := Nat

/-- The observable result of the source-local, one-item control prefix. -/
inductive Outcome where
  | revertedAmount
  | proceeds (owner : Address)
  deriving DecidableEq, Repr

/-- Solidity line 130: replace `address(0)` owner with `msg.sender`. -/
def resolvedOwner (caller suppliedOwner : Address) : Address :=
  if suppliedOwner = 0 then caller else suppliedOwner

/-- Executable one-item projection of lines 130 and 133.

`proceeds owner` says only that control reaches the line-134 call with that
owner.  It is not a claim that the call returns successfully. -/
def requestWithdrawalsSingleControl
    (caller suppliedOwner amount : Nat) : Outcome :=
  if checkedWithdrawalRequestAmount amount then
    .proceeds (resolvedOwner caller suppliedOwner)
  else
    .revertedAmount

/-- Exact bounded parent: on the EVM-callable caller domain, every control
prefix which reaches the line-134 call has passed both amount guards and uses
the owner selected by line 130. -/
def SingleRequestControlInvariant
    (run : Address → Address → Nat → Outcome) : Prop :=
  ∀ caller suppliedOwner amount owner,
    caller ≠ 0 →
    run caller suppliedOwner amount = .proceeds owner →
      minStethWithdrawalAmount ≤ amount ∧
      amount ≤ maxStethWithdrawalAmount ∧
      owner = resolvedOwner caller suppliedOwner

/-- The source-local control prefix satisfies the exact bounded parent. -/
theorem request_withdrawals_single_control_invariant :
    SingleRequestControlInvariant requestWithdrawalsSingleControl := by
  intro caller suppliedOwner amount owner _ h
  unfold requestWithdrawalsSingleControl at h
  split at h
  · have hBounds : minStethWithdrawalAmount ≤ amount ∧
        amount ≤ maxStethWithdrawalAmount := by
      simpa [checkedWithdrawalRequestAmount] using ‹checkedWithdrawalRequestAmount amount = true›
    cases h
    exact ⟨hBounds.1, hBounds.2, rfl⟩
  · cases h

/-- Concrete source-boundary and zero-owner regression: the line-134 call is
reached with `msg.sender` as owner only for an in-range amount. -/
theorem pinned_zero_owner_boundary :
    requestWithdrawalsSingleControl 7 0 minStethWithdrawalAmount = .proceeds 7 ∧
    requestWithdrawalsSingleControl 7 0 (minStethWithdrawalAmount - 1) =
      .revertedAmount := by
  decide

end LidoSRv3.Audit.Source.WithdrawalQueueSingleRequestControl
