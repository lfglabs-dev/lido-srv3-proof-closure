# Consolidation Live CALL validation packet

> Historical packet of the `33b6053` increment (PR #281, merged as
> `7db9187e`; independent review in `review-281/`). Four of its residuals
> were internal obligations and are closed on this branch by
> `LOW-LEVEL-CALL.md`: the CALL primitive is now `lowLevelCall` (no
> target-code guard), the fee is read by an actual `staticcall("")`, the
> callee frame is derived from the concrete predeploy body, and the
> gateway→vault ABI hop is composed. Theorem names below that changed:
> `callAdd_no_code` (revert on a code-less target) now states acceptance
> (`callAdd_no_code_accepted`, same name kept as an alias); `CallData.invoke`
> rows now read `lowLevelCall`. Everything else in this packet is unchanged.

Pin: `lidofinance/core@17005714f151e5502c559932319a3f2f74ac2436`.
PR: #281 (`p-consolidation-pubkey-octets`).
Parent held: `d2983de830161b9317d43c12269f88591d392144`.
Codec head: `605b88290d5353eb9760686b5dce3a02a67a7b8b`.
Producer head before this increment: `2bbddb6659e460f05e7617aedd114a77d2832a2b`.
P-CONSOLIDATION remains OPEN. #263 inadmissible. #276 fee-only. No merge.

Live CALL of the vault hop only. The callee is an arbitrary `External`;
the EIP-7251 predeploy body, the fee `STATICCALL`, and the gateway→vault
ABI hop remain OPEN. Codec and producer lemmas are reused, not reopened.

## What is consumed

`vaultCallPayload pair = source ++ target` (producer increment) is the
payload of an actual `Live.CallData.invoke` with value `fee` in the
existing physical `Live.World` (Verity storage lenses, balances, logs,
attempted calls). The root transaction runs under `Live.run`.

`WithdrawalVaultEIP7685.sol:113-121` (`_callAddConsolidationRequest`):

| Source | Model |
| --- | --- |
| 114 `abi.encodePacked(sourcePubkey, targetPubkey)` | `(hopRequest ..).payload = source ++ target` (`hopRequest_payload`, `hopRequest_is_packed`) |
| 115 `CONSOLIDATION_REQUEST.call{value: fee}(request)` | `lowLevelCall callee ctx inbox (vaultCallPayload pair) fee` (was `CallData.invoke`; see `LOW-LEVEL-CALL.md`) |
| 116-118 `revert RequestAdditionFailed(request)` | `Fault.reason "RequestAdditionFailed"`, world restored (`callAdd_fault`, `callAdd_error_restores`) |
| 120 `emit ConsolidationRequestAdded(request)` | `requestAddedEvent` appended to the callee world (`callAdd_success`, `callAdd_accepted`) |

`WithdrawalVaultEIP7685.sol:56-73` and `WithdrawalVault.sol:81-85, 199-208`:

| Source | Model |
| --- | --- |
| 203-205 `NotConsolidationGateway` | `Live.require (ctx.sender = gateway)` |
| 60-63 `ZeroArgument`, `ArraysLengthMismatch` | `Live.require` on `sources.length` |
| 66 / 123-126 checked `requestsCount * fee`, `IncorrectFee` | `Live.require` on the product and `msgValue` |
| 68-72 per-pair `_validatePublicKey`, hop | `addConsolidationRequestsLoop` |
| 81-85 `preservesEthBalance` | `selfBalance` at entry, `require (exit = entry - msg.value)` |
| whole-entrypoint revert | `Live.run` (`executeVault_failure_restores`) |

`ConsolidationGateway.sol:295-307` (`_refundFee`):

| Source | Model |
| --- | --- |
| 296 `if (refund > 0)` | `refund_zero`: no CALL, no change |
| 298-300 `address(0)` → `msg.sender` | `resolveAddress`, `resolveAddress_val` (= `resolveRecipient`) |
| 302 `recipient.call{value: refund}("")` | `refundRequest`: empty payload, value `refund` (`refund_attempt_request`) |
| 303-305 `FeeRefundFailed` | `refund_error_restores`, `refund_rejected` |
| 212-213 / 302 value split | `refund_value_split` (reuses `checkFee_additive`) |

## Claims

| Claim | Theorem |
| --- | --- |
| Hop payload is the packed encoder output | `hopRequest_is_packed` |
| Every hop attempt is the line-115 request (any outcome) | `callAdd_attempt_request` |
| Failed hop is the vault's own error, world restored, no event | `callAdd_fault`, `callAdd_error_restores` |
| Successful hop: one accepted attempt, event appended | `callAdd_success` |
| Successful hop needs code and funds | `callAdd_success_funded` |
| Concrete arms: no code (accepted) / unfunded / rejected / accepted | `callAdd_no_code_accepted` (= `callAdd_no_code`), `callAdd_unfunded`, `callAdd_rejected`, `callAdd_accepted` |
| Provisional `fee` transfer is the CALL ledger rule | `callAdd_credited_balances` |
| Committed loop: all widths 48, one accepted request per pair in order | `loop_success` |
| Any loop attempt is a request for a pair of the batch | `loop_attempt_request` |
| Committed loop under callee frame: events in order, ledger `n * fee` | `loop_success_frame` |
| Root revert restores the entire entry world | `executeVault_failure_restores` |
| Committed entrypoint: guards held, requests per zipped pair, exit balance = entry − `msg.value` | `executeVault_success` |
| Committed entrypoint under callee frame: events, ledger moved `msg.value` | `executeVault_success_frame` |
| Refund: zero / attempt request / failure restores / rejected / accepted | `refund_*` |
| Refund CALL is the reviewed `RefundHop` | `refund_request_is_hop` |

`LogFrame`, `BalanceFrame`, `Untraced` are explicit premises on the callee
where used. They are not asserted about the predeploy.

## Residuals (stated, not claimed)

* ~~Solidity low-level `.call` does not check callee code; `CallData.invoke`
  fails with `Fault.empty` on a code-less target.~~ Closed on this branch:
  `lowLevelCall` has no target-code guard (`LOW-LEVEL-CALL.md`).
* `RequestAdditionFailed(request)` / `InvalidPublicKeyLength(pubkey)` are
  `Fault.reason` names; the failed request octets remain in the attempt
  trace.
* ~~`_getFeeFromContract` (STATICCALL) is a supplied word. `FeeReadFailed`,
  `FeeInvalidData` are not modeled.~~ Closed on this branch:
  `getConsolidationRequestFee` is an actual `lowLevelStaticCall` with the
  source ladder (`LOW-LEVEL-CALL.md`).
* Checked-multiplication overflow and the modifier `assert` are
  `Fault.reason "Panic(0x11)"` / `"Panic(0x01)"`, not ABI panic data.
* ~~Gateway→vault ABI hop (`bytes[]` pairs, line 220) and the EIP-7251
  callee body remain OPEN.~~ Composed / given a concrete body on this branch
  (`Composition.lean`, `Predeploy.lean`): the hop is the Solidity ABI
  framing of `(bytes[], bytes[])` (offset tables and 32-octet padding; the
  first revision of this branch, head `94ef159c`, lacked both and was found
  NOT CLEAN by review 3bb8da69; repaired), and the vault entrypoint on the
  raw calldata is `executeVault` on the committed arrays
  (`executeVaultCalldata_gateway`). The EIP-7251 fee-update rule, the
  selector keccak, the correspondence of the simplified `predeployBody` to
  the deployed predeploy, the untraced fee STATICCALL attempt and the
  precompile exclusion of the code-less CALL arm remain OPEN / recorded
  (`LOW-LEVEL-CALL.md`).

## Tests

`LidoSRv3/Tests/TrioConsolidation/LiveCall.lean` (`native_decide` on
projections of `Live.run` results). Inbox doubles are acceptance-shape
(96 octets, `value ≥ fee`, one count write, no logs), not the predeploy.

* committed 2-pair batch: requests, accepted bits, balances `0 / 14`,
  count `2`, two `ConsolidationRequestAdded` events with all 96 octets,
  exit balance = entry − `msg.value`;
* all rejected: `RequestAdditionFailed`, balances restored, no logs,
  failed attempt retains the request octets;
* first accepted then rejected: root rollback restores the first hop's
  count write, event and value transfer; attempts `[true, false]`;
* `NotConsolidationGateway`, `ZeroArgument`, `ArraysLengthMismatch`,
  `IncorrectFee` (no attempt), 47-octet target after one hop;
* refund: zero, accepted (balances `0 / 5`), `address(0)` → sender,
  rejected (`FeeRefundFailed`, restored), value split.

## Targeted compile / axiom inspection

`lake build +audit.trio.consolidation.LiveCall`
`lake build +LidoSRv3.Tests.TrioConsolidation.LiveCall`
`lake build +audit.trio.consolidation.InspectAxioms`
True compiler exit (no `tee`). Lean 4.31.0.

| Theorem | Axioms |
| --- | --- |
| `hopRequest_is_packed` | `propext`, `Quot.sound` |
| `callAdd_attempt_request` | `propext`, `Quot.sound` |
| `callAdd_fault` | `propext`, `Quot.sound` |
| `callAdd_error_restores` | `propext`, `Quot.sound` |
| `callAdd_success` | `propext`, `Quot.sound` |
| `callAdd_success_funded` | `propext`, `Quot.sound` |
| `callAdd_no_code` (now the acceptance arm, = `callAdd_no_code_accepted`) | `propext` |
| `callAdd_unfunded` | `propext` |
| `callAdd_rejected` | `propext` |
| `callAdd_accepted` | `propext` |
| `callAdd_credited_balances` | `propext`, `Quot.sound` |
| `loop_success` | `propext`, `Quot.sound` |
| `loop_attempt_request` | `propext`, `Quot.sound` |
| `loop_success_frame` | `propext`, `Quot.sound` |
| `executeVault_failure_restores` | `propext` |
| `executeVault_success_body` | `propext` |
| `executeVault_success` | `propext`, `Quot.sound` |
| `executeVault_success_frame` | `propext`, `Quot.sound` |
| `resolveAddress_val` | `propext` |
| `refund_zero` | `propext` |
| `refund_attempt_request` | `propext`, `Quot.sound` |
| `refund_error_restores` | `propext`, `Quot.sound` |
| `refund_rejected` | `propext` |
| `refund_accepted` | `propext` |
| `refund_value_split` | `propext` |
| `refund_request_is_hop` | `propext` |

No `Classical.choice` on any theorem of this increment.
P-CONSOLIDATION remains OPEN.
