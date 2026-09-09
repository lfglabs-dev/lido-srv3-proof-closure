# TOPUP-1: concrete Lido withdrawal consumer

This increment replaces a manually credited balance **in a new TOPUP suffix
consumer**, by running the delivered Lido withdrawal and its concrete router
receiver in one `TrioReserve1.Live.World`. It does not replace the registered
`TopupTx` executor or claim closure of TOPUP-1.

Source pin: `lidofinance/core@17005714f151e5502c559932319a3f2f74ac2436`.
Delivered proof baseline: `ee5f7f63c958a80edcf6265072ef84613f4369e2`.
No DEPOSIT/shared foundation file is changed or copied.

## Source correspondence

| Pinned source | New consumer |
|---|---|
| [StakingRouter.sol:741-744](https://github.com/lidofinance/core/blob/17005714f151e5502c559932319a3f2f74ac2436/contracts/0.8.25/sr/StakingRouter.sol#L741-L744) | `suffix` skips zero; positive amount calls `Live.withdrawDepositableEther external ctx amount (word 0)`. |
| [Lido.sol:869-885](https://github.com/lidofinance/core/blob/17005714f151e5502c559932319a3f2f74ac2436/contracts/0.4.24/Lido.sol#L869-L885) | `positive_success` consumes `TrioReserve1.Pipeline.success`: concrete status/locator/queue/oracle/consensus, accounting writes, actual ETH transfer, source receiver. Zero seed guard is derived; `zero_seed_tail` preserves its input world without calls or events. |
| [StakingRouter.sol:665-669](https://github.com/lidofinance/core/blob/17005714f151e5502c559932319a3f2f74ac2436/contracts/0.8.25/sr/StakingRouter.sol#L665-L669) | Callback caller/target/value/selector, successful empty return and final committed `DepositableEthReceived` event are observed. Receiver authorization is executed, not supplied as an external success reply. |

## Independent result and domain

`Balances` is a source-level pointwise specification, independent of the
executor: Lido's remaining balance plus amount equals its old balance; router
balance equals its old balance plus amount; every other account is unchanged.
Old router balances are arbitrary, including nonzero. `transfer_balances`
derives these equations from the delivered CALL accounting relation with
funding and distinct-address premises. `positive_success` composes them with
the actual pipeline and its proved balance frames. `Callback` states the exact
final callback and event without naming or assuming the executor's post-world.
It permits the preceding getter/accounting observations; it does not claim the
entire log contains only that one event.

The successful-path theorem keeps these real conditions explicit:

- Actual locator/consensus slot bindings, address separation required by the
  dispatcher, and code presence in `Pipeline.Bound`.
- Queue not in bunker mode, Lido active, sender equal to the looked-up router,
  positive uint256 amount, computed queue demand, admitted physical buffer
  allocation, valid consensus-frame computation and oracle timestamp.
- Actual Lido funds, immutable Lido identity, router code presence and distinct
  Lido/router addresses.

No successful getter/callback response, post-state equality, credit equation,
or generic callee preservation law is assumed. Fallback interpreters are
arbitrary; every call on this admitted path is handled by the concrete
dispatch. The zero branch needs none of those conditions and performs no call.

## Boundary

This consumer takes the source uint256 amount; it does not derive that amount
from an allocation list, gateway bounds, or module return. It does not alter
`TopupTx.creditPull`, prove its simulation by this consumer, bridge the outer
routeur-to-Lido ABI CALL, or compose `sourcePushLoop`. Root TOPUP rollback,
beacon callee/storage/credits, constructor and deployed-code correspondence,
and physical entry/module provenance remain outside this increment.

`Live.World.balances` is not automatically the old `ContractState.selfBalance`.
A later consumer must prove that representation link and the source-byte loop
debit, rather than inserting the balance conclusion as an assumption.
The DEPOSIT-specific `LinksSource` and `actualKeys` seed count are neither
imported nor discharged. Existing RESERVE acceptance is consumed unchanged.

## Validation

See `validation.log`, `axioms.log`, `receipt.json`, `source-check.json` and
`validated-inputs.sha256` for the exact local validation and file hashes.
The tests exercise the complete concrete withdrawal with rejecting fallbacks,
a nonzero old router balance, untouched third-account funds and seed storage;
they distinguish zero from positive admission, missing Lido funds and a wrong
immutable Lido, and reject omitted/doubled-credit specification mutants.
The nonzero-seed mutation changes the physical seed count, making the TOPUP
second argument load-bearing. These are Lean execution regressions, not Forge
or deployed EVM tests. No fresh Solidity suite or full repository build is
claimed. Independent review of the final candidate is still required.
