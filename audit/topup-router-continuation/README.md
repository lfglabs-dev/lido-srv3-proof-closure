# TOPUP guarded router continuation

This increment executes the typed post-module continuation at pinned
`StakingRouter.sol:721–758`: the ordered allocation guards and wrapped
accumulator, saved target comparison, concrete zero-seed withdrawal, current
credential reads, beacon helper, balance assertion and final router event.
The same `Live.World` carries all balances, storage, logs and attempts.

`positive_success` connects the gateway's real uint64/count bounds to the
concrete funded beacon batch accepted in PR273. It derives the exact sum,
uint256 fit, gwei alignment and uint64-gwei width from the executed guard loop.
It proves Lido's debit, restoration of arbitrary old router holdings, beacon
credit, the other-account ledger frame, count growth, every independent
branch/event step, chronological attempts and the final top-up event. No
manual credit, callee success, root-match, no-reentry or arbitrary frame
hypothesis supplies those effects.

## Executable boundary and source order

Pinned core is `17005714f151e5502c559932319a3f2f74ac2436`.

- [StakingRouter.sol:721–758](https://github.com/lidofinance/core/blob/17005714f151e5502c559932319a3f2f74ac2436/contracts/0.8.25/sr/StakingRouter.sol#L721): alignment precedes the indexed limit read, limit comparison precedes unchecked addition, and target comparison precedes withdrawal. The balance snapshot is taken after the module call. Assertion precedes `StakingRouterETHTopUp`.
- [BeaconChainDepositor.sol:66–107](https://github.com/lidofinance/core/blob/17005714f151e5502c559932319a3f2f74ac2436/contracts/0.8.25/lib/BeaconChainDepositor.sol#L66): after withdrawal, empty pubkeys return immediately; nonempty inputs check amount-list length before traversal; key width precedes zero skip, then minimum and uint64 guards precede the actual beacon call.
- [StakingRouter.sol:746–747](https://github.com/lidofinance/core/blob/17005714f151e5502c559932319a3f2f74ac2436/contracts/0.8.25/sr/StakingRouter.sol#L746) reads current credentials and the stored module type after withdrawal. `callAt`/`inputAt` read the actual resulting world. Pure storage reads are total in this typed model; their ordering relative to later helper checks has no modeled gas/memory failure effect.
- [SRStorage.sol](https://github.com/lidofinance/core/blob/17005714f151e5502c559932319a3f2f74ac2436/contracts/0.8.25/sr/SRStorage.sol), [SRTypes.sol](https://github.com/lidofinance/core/blob/17005714f151e5502c559932319a3f2f74ac2436/contracts/0.8.25/sr/SRTypes.sol) and [WithdrawalCredentials.sol](https://github.com/lidofinance/core/blob/17005714f151e5502c559932319a3f2f74ac2436/contracts/common/lib/WithdrawalCredentials.sol) supply the namespace, layout and type-byte selection. [ISRBase.sol:34](https://github.com/lidofinance/core/blob/17005714f151e5502c559932319a3f2f74ac2436/contracts/0.8.25/sr/ISRBase.sol#L34) supplies the final event fields.

`Input` contains typed uint256 allocations/limits/budget/module id and octet
public keys. Execution does not require `SourceTopupCallWellFormed` and does
not introduce that check before withdrawal. Malformed key widths and array
lengths reach their actual helper checks. Empty-helper behavior is preserved,
including a positive pull followed by the real balance assertion failure.
A zero accumulated amount preserves the post-module world and appends the
zero-amount event. The old two-element `[2^256-1,1]` wrapped-zero fixture is
rejected by this continuation's alignment guard; `zero_event` itself does not
assume no wrap or replace the executable zero domain.

The new files do not alter or replace the registered `TopupTx`, `TopupParent`,
prior funded suffix or ALLOC implementation. The source suffix starts after
the module call. Typed arrays and the saved target remain inputs; no claim
here executes the module, decodes its return ABI, proves key ownership or
establishes the earlier gateway/module preamble. In particular, the arbitrary
post-module world is the conservation/rollback baseline. It need not equal
the original transaction-entry world.

## Physical credentials adapter

`TopupRouterCredentials` reads the router's actual `readContractSlot` words:

- Namespace root `0x5648d366b9f342bdcc64be95cdcf5f05da808509be70eaa548a8795901d5d000`.
- Withdrawal credentials at root +4.
- Module configuration at `Keccak(ABI32(moduleId) ++ ABI32(root))`, mapping slot root +0.
- Type byte at offset 29 (bit 232) of the packed configuration word.

The type extraction theorem separates the lower 232 bits, the selected byte
and upper bits. Word encoding round-trips through the independent ABI decoder.
The source byte construction replaces the first WC byte and retains its tail.
No arbitrary storage-reader function supplies credentials. Mapping Keccak is
an explicit opaque hash parameter on the actual 64-byte input; no universal
Keccak/EVM proof or deployed address is inferred. The namespace literal was
checked with local `cast` against the source ERC-7201 expression. Independent
Solidity checks in [solidity/README.md](solidity/README.md) also verify it through
the unmodified source getter and compiler layout.

The adapter does not infer that a type admitted as 2 before the module call
must still be 2 later. The continuation reads the current uint8. Transporting
that earlier value across arbitrary module/callback behavior is a separate
obligation.

## Proof domain and independent specification

`guardSum_spec` derives `allocationGuards` and the actual unchecked accumulator
from successful evaluation of the concrete loop. `checked_fields` composes
that result with the gateway's evaluated limits and uint64 cardinality bound.
The guard-loop equality used by `positive_success` is a checked pure source
calculation, not a successful module/withdrawal/final-execution premise. Its
`total` is proved equal to the exact sum. The saved target comparison remains
an explicit source input condition; the earlier target/share/cap producer is
outside this continuation.

Matching helper lengths, valid key widths and minimum nonzero deposits remain
honest success-domain conditions. Router allocation guards alone do not imply
them: shorter arrays pass the allocation loop, and one gwei is aligned but
below the helper minimum. Runtime checks remain at their source positions.
The theorem derives alignment and upper amount bounds, rather than assuming
the composite `AmountsAdmitted` condition from PR273.

`Postcondition` uses independent pointwise `CallSpec.Balances`, explicit three
account equations, count growth and the existing independent `Effects` chain.
It retains the intermediate withdrawn/deposited worlds so the withdrawal
callback is not incorrectly called the last global call, and the beacon's
per-call log postconditions end before the router's final event. The assertion
is executed by `finish` against the actual final router balance; its success
follows from conservation. `postcondition_bounded` preserves an independent
initial finite-support asset invariant. Sum fit is not an initial ledger bound
or a reachability theorem; the ledger remains Nat-valued.

Concrete Pipeline admission, withdrawal arithmetic/funding, distinct physical
accounts and initial beacon count + nonzero allocations within capacity remain
explicit. No module invariant is assumed to survive arbitrary effects. SHA,
callee capacity and branch execution are reused from accepted PR271/273;
cryptographic/runtime/compiled EVM/precompile/gas guarantees remain outside
this typed result. The total opaque hash model does not model the helper's
pre-loop dummy-signature hash failure or memory allocation failures. Exact
Solidity revert/event ABI, raw calldata/memory bounds, deployed beacon identity
and reachable initial deposit-tree invariants also remain open, including
A-TOPUP-BEACON-ADDRESS.

## Validation

Executed targeted command:

```sh
lake build LidoSRv3.Tests.TopupRouterContinuationMutants
```

PASS: 1272 jobs, with the two new source modules checked through imports.
There are 15 source theorems (6 credentials, 9 continuation), 37 regression
examples, two substantive scenario proofs and one initial-balance fixture
lemma. Nine axiom queries use only `propext`, `Classical.choice`, `Quot.sound`;
no sorry, new axiom declaration or native checker is introduced. No warning
comes from the three new files; pre-existing dependency warnings are replayed.
The committed validation/axiom logs and input hashes bind this exact source.

Tests cover guard priority, overflow update, over-target before any CALL,
zero-path preservation of a prior module event, actual withdrawal failure
before helper length failure, helper key-before-zero, empty helper followed by
assertion failure, arbitrary old balances, count growth, final event placement
and finite-support mass. `late_execution` proves an actual first beacon
insertion followed by the real minimum rejection of an aligned one-gwei
second allocation. Allocation guards pass; the outer continuation rolls back
all balances/storage/logs while preserving withdrawal/first-deposit attempts.

`current_words_execute` uses a clearly marked synthetic effectful CALL
interpreter that modifies WC/type words during withdrawal. The actual beacon
payload then contains the later type 1 and tail byte 99. This detects caching
of earlier words, but does not claim that this interpreter is the delivered
router receiver or a reachable deployed callback/reentry exploit.

The separately frozen [Solidity receipt](solidity/receipt.json) reports four
passing source-layout/helper tests, including two properties with 1024 fuzz
runs each and all 256 type values. They execute actual SRStorage and
WithdrawalCredentials helpers under solc0.8.25; compiler storage layout is
included. They do not validate the complete StakingRouter continuation or a
state change during an actual withdrawal. No fresh full-router Forge result
is claimed. Independent exact-candidate review remains to be added by a
reviewer.
