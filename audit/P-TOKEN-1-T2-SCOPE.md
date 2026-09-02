# P-TOKEN-1 — bounded WithdrawalQueue request-ownership custody scope

This file supersedes the earlier T2 note. T2 described the one-item
`requestWithdrawals` control prefix while broad `P-TOKEN-1` was unregistered.
`P-TOKEN-1` is now registered as a **subordinate, bounded** row, not as a
canonical guarantee and not as a token guarantee. The canonical public surface
is unchanged at eleven guarantees.

## Exact source anchors

Pinned upstream source is
[`lidofinance/core@af095e48bbc1c3841c2c9936219c8461af01056b`](https://github.com/lidofinance/core/tree/af095e48bbc1c3841c2c9936219c8461af01056b).

Creation leg, `contracts/0.8.9/WithdrawalQueue.sol`:

- `requestWithdrawals`, lines 125–135: `_owner == address(0)` selects
  `msg.sender` at line 130, then each amount is checked at line 133 before
  `_requestWithdrawal` at line 134.
- `_checkWithdrawalRequestAmount`, lines 395–402: rejects amounts below
  `MIN_STETH_WITHDRAWAL_AMOUNT` and above `MAX_STETH_WITHDRAWAL_AMOUNT`.
- constants at lines 52 and 57: `100` and `1000 * 10^18`.

Custody leg, `contracts/0.8.9/WithdrawalQueueERC721.sol`:

- `transferFrom` and the owner-operated `_transfer` branch, lines 218–253:
  the zero-recipient guard at line 231, the self-transfer guard at line 232,
  the owner check at line 238, the caller authorization at lines 241–245, the
  approval deletion at line 247, and the request-owner handoff at line 248.

## The registered parent

`LidoSRv3.Audit.Guarantees.PToken1.request_owner_custody_invariant` proves
`RequestOwnerCustodyInvariant requestWithdrawalsSingleControl sourceTransfer`.

The predicate is universal over an unmodeled minting function `mint`, the
request inputs, and an **arbitrary-length** list of later custody hops. When
the creation prefix proceeds with owner `o` and a hop chain executes to a
final state, the single named conclusion is:

1. the amount lies inside the two-sided source range;
2. `o` is exactly the line-130 fallback result;
3. the final request owner is not `address(0)`, for any number of hops; and
4. every hop that executed was operated by the then-current owner, to a
   recipient distinct from that owner and from `address(0)`.

Conjuncts 3 and 4 are genuinely stronger than the conjunction of the two
pre-existing one-step slices: they are multi-step reachability statements that
neither slice implies.

### The `mint` argument is a caller obligation, not an assumption

`_enqueue` and `_emitTransfer` (lines 378 and 380) are not modeled. Rather than
silently assuming their effect, the parent quantifies over every `mint` and
carries the single named hypothesis `∀ o, (mint o).owner = o`. Nothing else
about `mint` is used; in particular `(mint o).approved` stays unconstrained.
Discharging that hypothesis from real storage writes is the declared next gate.

### Exact-parent kill-lines

Each mutant deletes exactly one source guard and refutes the **same**
`RequestOwnerCustodyInvariant` predicate, in
`LidoSRv3/Tests/WithdrawalQueueRequestCustodyMutants.lean`:

| Mutant | Deleted line | Refutes |
| --- | --- | --- |
| `zero_recipient_drop_kill_line_refutes_exact_parent` | `WithdrawalQueueERC721.sol:231` | conjunct 3 — a live request is burned to `address(0)` |
| `caller_authorization_drop_kill_line_refutes_exact_parent` | `WithdrawalQueueERC721.sol:241-245` | conjunct 4 — account 9 moves account 7's request |
| `owner_fallback_drop_kill_line_refutes_exact_parent` | `WithdrawalQueue.sol:130` | conjunct 3 — the request is created ownerless |

Non-vacuity is separate and explicit:
`custody_premises_inhabited` and `supplied_owner_premises_inhabited` exhibit
concrete successful chains at both pinned amount boundaries, for the
zero-owner fallback and for an explicitly supplied owner.

## Explicit unsupported surfaces

| Surface | Status | Exact gap |
| --- | --- | --- |
| `approve` / allowance | Unsupported | No ERC-20 allowance state or `approve` execution is represented. |
| `STETH.transferFrom` | Unsupported | The line-134 external token call, its return/revert behaviour, balances, and allowances are not modeled. |
| shares | Unsupported | `getSharesByPooledEth` at line 376 is outside the slice. |
| queue writes | Unsupported | `_enqueue`, request IDs, and queue storage at line 378 are outside the slice; the owner binding is the named `mint` hypothesis instead. |
| redeem / claim | Unsupported | No finalization, `claimWithdrawals*`, or redemption path is represented. |
| ERC-721 operator branches | Unsupported | Only the owner-operated branch of `_transfer` is modeled; the approved-operator and `isApprovedForAll` branches at line 242 are excluded. |
| request validity | Unsupported | The request-id validity and claimed checks at lines 233 and 236 are excluded. |
| owner index | Unsupported | The `EnumerableSet` owner-index updates at lines 250–251 are excluded. |
| events | Unsupported | `_emitTransfer` at line 380 and line 253 is not modeled. |
| WstETH | Unsupported | `requestWithdrawalsWstETH`, unwrap, and permit are excluded. |
| pause and rollback | Unsupported | `_checkResumed` at line 129 and whole-transaction rollback are not represented. |
| batching | Unsupported | Exactly one request list item is modeled. |
| executable contract | Unsupported | No Verity Executable Contract exists for this surface, so the registry `verity` plane stays `PARTIAL`. |

## Limitation and downstream consequence

This is bounded evidence for request-ownership custody only. It does **not**
establish ERC-20 movement, token transferability in the ERC-20 sense,
redeemability, balance correctness, or the full request transaction. Broad
ERC-20/ERC-721/WstETH token semantics remain **NOT YET** and are neither
registered nor implied. A future parent needs an executable Verity
WithdrawalQueue model that composes the external token call, share conversion,
enqueue/storage writes, and the approve/transfer/redeem paths under matching
domains.

## Focused verification

```sh
lake build LidoSRv3.Audit.Guarantees.PToken1 \
  LidoSRv3.Tests.WithdrawalQueueRequestCustodyMutants
```

## Address width

`Address` in `LidoSRv3/Audit/Source/WithdrawalQueueRequestCustody.lean` is an
unbounded `Nat`. The 160-bit Solidity address domain is not enforced, so a
modeled hop may name a recipient such as `2^160` that no Solidity address can,
and the parent's `final.owner ≠ 0` conjunct is stated on that wider domain.
The registry row records this as an open fidelity gap; a width-bounded
admission or an address correspondence proof would close it.
