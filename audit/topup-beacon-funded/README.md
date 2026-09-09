# TOPUP concrete withdrawal and beacon batch

This increment composes the delivered zero-seed Lido withdrawal with actual
source-byte beacon calls in one `Live.World`. It proves the StakingRouter
post-pull conservation condition for this new suffix consumer: Lido loses the
mathematical sum, the router returns to its arbitrary old balance, and the
concrete beacon callee gains the same sum. Every other account is unchanged.
Neither a manual caller projection/credit nor a successful-callee/frame/root
match hypothesis is supplied.

The old registered `TopupTx` and PR267 `TopupFundedSourceTx` remain unchanged.
This consumer is a new source suffix, not a claim that those old programs now
execute the actual callee or that the complete external `topUp` entry is proved.

## Exact source and dependencies

Pinned Lido source: `17005714f151e5502c559932319a3f2f74ac2436`.

- [StakingRouter.sol:717–757](https://github.com/lidofinance/core/blob/17005714f151e5502c559932319a3f2f74ac2436/contracts/0.8.25/sr/StakingRouter.sol#L717): the same module-returned allocations are summed with uint256 wrapping, the positive branch pulls `(amount, 0)`, sends the allocations to the beacon helper and asserts restoration of the old router balance.
- [BeaconChainDepositor.sol:70–107](https://github.com/lidofinance/core/blob/17005714f151e5502c559932319a3f2f74ac2436/contracts/0.8.25/lib/BeaconChainDepositor.sol#L70): key width precedes zero skip; nonzero values pass minimum and uint64-gwei guards, then the exact key, typed withdrawal credentials, zero signature and helper-computed root are sent with the original wei value.
- [Lido.sol:869–887](https://github.com/lidofinance/core/blob/17005714f151e5502c559932319a3f2f74ac2436/contracts/0.4.24/Lido.sol#L869): real admission/accounting, zero-seed branch, payable router callback.
- [deposit_contract.sol:101–159](https://github.com/lidofinance/core/blob/17005714f151e5502c559932319a3f2f74ac2436/contracts/0.6.11/deposit_contract.sol#L101): actual payload admission, gwei alignment, recomputed root, event, capacity, count and branch insertion.

The concrete callee dependency is accepted PR271, merge
`8ef973fa37997e55061a95fce1a41bf3cfe968e7`. Its
[receipt](https://github.com/lfglabs-dev/lido-srv3-proof-closure/blob/8ef973fa37997e55061a95fce1a41bf3cfe968e7/audit/topup-beacon-effects/receipt.json)
and [review](https://github.com/lfglabs-dev/lido-srv3-proof-closure/blob/8ef973fa37997e55061a95fce1a41bf3cfe968e7/audit/topup-beacon-effects/REVIEW.md)
remain the evidence for that callee. PR265 supplies `TopupLiveWithdrawal`;
PR260 supplies the gateway arithmetic used by `gateway_amount_exact`.
`source-check.json` verifies the consumed files against the accepted merge and
source blobs. Hash identity alone is not a semantic equivalence proof.

## Independent specification and proof

`TopupBeaconBatch.loop` executes `CallData.invoke` through the PR271 concrete
beacon dispatcher, using `sourcePayload` rather than fabricated identifiers or
independently chosen amounts. `sourceDeposits_admissible` derives field lengths,
actual key bytes, typed withdrawal credentials, zero signature and gwei amount
from `sourceDeposits call hw` and the same `call.moduleReturndata` used by the pull.

The independent aggregate specification is `CallSpec.Balances`, a pointwise
ledger equation over every address. The independent per-call `Step` additionally
requires count increment, exact semantic event append and `BranchEffect`:
the first odd quotient of old count+1 selects the one branch write, whose value
is a fold over the old branch. `Effects` retains the chain of all intermediate
steps, skipping only zero allocations. Neither predicate contains an executable
success equality.

`loop_success` derives each CALL's funds and capacity by induction. Its only
capacity input is `initial count + nonzeroCount allocations <= 2^32-1`;
there are no supplied per-call count guards or successful results. Code-size
preservation is derived from the concrete two storage writes. The theorem gives
actual execution, aggregate ledger conservation, count growth, exact requests
and the complete independent effect chain.

`positive_conservation` consumes the delivered concrete `Pipeline` withdrawal,
proves its accounting writes preserve the beacon count and code, then invokes
the lot theorem on the resulting world. The same world carries the real Lido
debit/router credit and all later beacon effects. Its single `Live.attempts`
journal is exactly the withdrawal trace (including the actual receiver callback)
followed by the filtered source deposit requests. The callback is the last
withdrawal call, not the last call after the batch. There is no separate beacon
`core.calls` journal in this consumer.

The final theorem proves success and all three balances, frames every other
account, proves count growth and preserves the per-call effect chain. These
facts discharge the source router balance assertion as a property; execution of
the final assertion and `StakingRouterETHTopUp` emission is outside this suffix.

`batch_bounded` derives a final finite-support ledger bound and exact total mass
from an independent initial `BalanceSpec.Bounded` invariant and actual batch
execution conditions. `positive_conservation` includes the corresponding final
bound/mass result for the whole funded suffix. No initial asset supply,
reachability or uint256 total balance invariant is invented. The base ledger is
Nat-valued; these conditional final bounds do not claim a proof of all EVM
intermediate ledger representations.

## Domain and open obligations

- Entry scope starts after the gateway/module preamble with a supplied actual
  `TopupCall.moduleReturndata` and `SourceTopupCallWellFormed`. Gateway dispatch,
  module call behavior, target budget acceptance, key/operator ownership and
  deployed configuration are not established by this suffix.
- `AmountsAdmitted` makes minimum, gwei alignment and uint64-gwei bounds explicit
  for nonzero source allocations. Alignment is enforced by the actual callee in
  the loop. In full StakingRouter it is also checked earlier; the late unaligned
  suffix regression intentionally bypasses that earlier gateway guard and is
  not claimed to be a reachable full `topUp` transaction.
- `loop` is an internal traversal under paired-list well-formedness. Its defensive
  length mismatch error is not claimed equivalent to all malformed helper
  inputs. In particular Solidity returns immediately on empty pubkeys before
  checking amount length; source well-formedness forces both lists empty here.
- The positive pull requires a nonzero mathematical sum fitting uint256.
  `gateway_amount_exact` derives that fit from PR260's actual uint64/cardinality
  and allocation bounds when those gateway premises are available. It does not
  bound arbitrary old router holdings. The executable wrapped-zero branch is
  preserved, including nonzero mathematical sums that wrap to zero.
- Physical withdrawal admission is explicit: locator/consensus links and code,
  bunker/active/auth, queue amount, accounting capacity, successful checked
  frame arithmetic, timestamp conversion, Lido ETH funds and authentic receiver
  identity. Lido, router and beacon are distinct in the positive theorem; the
  router and beacon have code. No no-reentry or unknown-callee balance frame is
  introduced; this callee's body has no external calls.
- SHA is the existing opaque source hash model. Its EVM/precompile execution,
  failure mode, gas, compiler refinement, exhaustive malformed ABI behavior,
  `Error(string)` returndata and LOG topics/data remain outside this Lean result.
  Exact full event ABI has prior per-callee Solidity tests, not a new Lean proof.
- Arbitrary initial count/branch storage is admitted within capacity. A reachable
  initial deposit tree invariant and deployed runtime/immutable identity remain
  open, including **open A-TOPUP-BEACON-ADDRESS**.

## Validation

Targeted command actually executed:

```sh
lake build LidoSRv3.Tests.TopupBeaconFundedMutants
```

PASS, 1270 jobs; the imported new source modules compiled on the same unchanged
inputs. There are 11 source theorems, 22 regression examples plus the substantive
`late_execution` proof and four fixture lemmas. Nine axiom queries report only
`propext`, `Classical.choice`, `Quot.sound`; there is no sorry, native checker
axiom or new trusted assumption. No warnings arise from the three new files;
pre-existing dependency warnings are replayed. Logs and exact hashes are in the
receipt and `validated-inputs.sha256`.

The positive fixture uses the opaque source SHA, distinct keys, amounts
`[1 ETH, 0, 2 ETH]`, old router balance7 and old beacon balance11. It checks all
balances, count, actual calldata key bytes and the chronology of callback and
beacon calls. Mutants cover omitted/doubled beacon credit, full wrapped-zero
behavior, Lido underfunding, key-before-zero/min/max guards and internal length
mismatch. `late_execution` derives a real successful first beacon call followed
by actual callee alignment rejection and proves full initial-world rollback
while retaining callback/accepted/rejected attempts. A finite-support fixture
checks final bound and exact total mass.

**No fresh Solidity/Forge execution was performed for this composed suffix.**
The inherited PR271 actual unmodified solc0.6.11 callee validation remains four
passing tests including1024 fuzz runs, all32 carry heights and late rollback;
it does not certify this new withdrawal-plus-batch integration. Independent
review of the exact new candidate must be recorded separately in `REVIEW.md`.
