# P-TOKEN-1 T2 — one-item WithdrawalQueue request control prefix

## Exact source anchor

Pinned upstream source is
[`lidofinance/core@17005714f151e5502c559932319a3f2f74ac2436`](https://github.com/lidofinance/core/blob/17005714f151e5502c559932319a3f2f74ac2436/contracts/0.8.9/WithdrawalQueue.sol):

- `WithdrawalQueue.requestWithdrawals`, lines 125–135: `_owner == address(0)`
  selects `msg.sender` at line 130, then each amount is checked at line 133
  before `_requestWithdrawal` at line 134.
- `_checkWithdrawalRequestAmount`, lines 395–402: rejects amounts below
  `MIN_STETH_WITHDRAWAL_AMOUNT` and above `MAX_STETH_WITHDRAWAL_AMOUNT`.
- constants at lines 52 and 57: `100` and `1000 * 10^18`.

`LidoSRv3.Audit.Source.WithdrawalQueueSingleRequestControl` is an executable
Lean projection for exactly one list item.  Its result `proceeds owner` means
only that the source-local prefix reaches the line-134 call site with `owner`.
It does not assert that the external call succeeds.

The exact parent is `SingleRequestControlInvariant`: for every nonzero caller,
when the projection proceeds, the amount is in the two-sided source range and
the selected owner is precisely the source line-130 fallback result.  The
regression mutant deletes only the fallback assignment, retains the amount
check, and falsifies that same parent at `(caller, suppliedOwner, amount) =
(7, 0, 100)`.

## Explicit unsupported surfaces

| Surface | T2 status | Exact gap |
| --- | --- | --- |
| `approve` | Unsupported | No ERC-20 allowance state or `approve` execution is represented. |
| `STETH.transferFrom` | Unsupported | The line-134 external token call, return/revert behavior, balances, and allowances are not modeled. |
| redeem / claim | Unsupported | No redemption or `claimWithdrawals*` source path is represented. |
| shares and queue writes | Unsupported | `getSharesByPooledEth`, `_enqueue`, request IDs, and storage are beyond the control prefix. |
| ERC-721 / WstETH | Unsupported | `_emitTransfer`, ERC-721 transfers, `requestWithdrawalsWstETH`, unwrap, and permit are excluded. |
| pause and rollback | Unsupported | `_checkResumed` and whole-transaction rollback are not in this one-item control projection. |

## Limitation and downstream consequence

This is bounded evidence for one request entrypoint control prefix only.  It
does **not** establish ERC-20 movement, queue creation, request ownership in
storage, transferability, redeemability, or the full request transaction.
Therefore broad `P-TOKEN-1` remains **NOT YET** and is neither registered nor
implied by this slice.  A future parent needs an executable Solidity/Verity
model that composes the external token call, share conversion, enqueue/storage
writes, and the relevant approve/transfer/redeem paths under matching domains.

## Focused verification

```sh
lake build LidoSRv3.Audit.Source.WithdrawalQueueSingleRequestControl \
  LidoSRv3.Tests.WithdrawalQueueSingleRequestControlMutants
```
