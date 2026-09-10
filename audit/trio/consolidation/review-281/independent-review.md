# Independent exact-head review — PR #281 head 33b6053794ac96251a9f0713dbee7ec8b5c9612e

Scope: read-only review of the Live CALL increment (commit 33b60537, "consolidation: Live CALL of the vault hop") on top of producer 2bbddb66. writer=false. No merge, push, comments, or source edits performed; working tree left clean (`git status --porcelain` empty).

## Identity and toolchain

- Repo: lfglabs-dev/lido-srv3-proof-closure, fetched `refs/pull/281/head`.
- HEAD verified: `33b6053794ac96251a9f0713dbee7ec8b5c9612e`; parent chain shows producer `2bbddb66` immediately below, as stated.
- `lean-toolchain`: `leanprover/lean4:v4.31.0`; elan installed and used exactly that (Lean 4.31.0, commit 68218e87).
- Solidity pin: submodule `lido-core` checked out at `17005714f151e5502c559932319a3f2f74ac2436` and verified by `git rev-parse`.
- Increment diff: 4 files, +1201 (`audit/trio/consolidation/LiveCall.lean` 838, `LidoSRv3/Tests/TrioConsolidation/LiveCall.lean` 191, `audit/trio/consolidation/InspectAxioms.lean` 27, `audit/trio/consolidation/LIVE-CALL.md` 145). No other tracked files touched.

## Compiler verification (not a self-report)

Ran, as a durable job at the exact head:

`lake build +audit.trio.consolidation.LiveCall +LidoSRv3.Tests.TrioConsolidation.LiveCall +audit.trio.consolidation.InspectAxioms`

Result: exit code 0, "Build completed successfully (1277 jobs)". All 191 lines of tests (`native_decide` vectors) elaborated; `audit.trio.consolidation.LiveCall` and `InspectAxioms` built cleanly (no warnings on the new modules).

### Axioms (compiler `#print axioms` output, InspectAxioms.lean:38-63)

Every theorem of this increment depends on subsets of {propext, Quot.sound} only, exactly matching the packet table LIVE-CALL.md:117-142:

- [propext, Quot.sound]: hopRequest_is_packed, callAdd_attempt_request, callAdd_fault, callAdd_error_restores, callAdd_success, callAdd_success_funded, callAdd_credited_balances, loop_success, loop_attempt_request, loop_success_frame, executeVault_success, executeVault_success_frame, refund_attempt_request, refund_error_restores
- [propext] only: callAdd_no_code, callAdd_unfunded, callAdd_rejected, callAdd_accepted, executeVault_failure_restores, executeVault_success_body, resolveAddress_val, refund_zero, refund_rejected, refund_accepted, refund_value_split, refund_request_is_hop

No `Classical.choice`, no `sorryAx`, no `Lean.ofReduceBool` on any theorem of the increment. `Classical.choice` appears only on pre-existing lanes (`leading_zero_mutant`, `decode_encode_bytes_element`, and the two Verity `TrioConsolidation.Memory` theorems) — outside this increment and within the allowed axiom set regardless.

## Source correspondence vs pin 17005714 (checked line by line)

WithdrawalVaultEIP7685.sol (pin verified):
- 114 `abi.encodePacked(sourcePubkey, targetPubkey)` ↔ `hopRequest.payload = vaultCallPayload pair = source ++ target` (Producer.lean:193); `hopRequest_is_packed` reuses `vaultCallPayload_is_packed`/`encodePackedRequest_of_bytes`; 96 octets under `widthOk` (`hopRequest_length`).
- 115 `CONSOLIDATION_REQUEST.call{value: fee}(request)` ↔ `CallData.invoke callee ctx inbox (vaultCallPayload pair) fee` — callee `inbox`, caller `ctx.self`, value `fee`, verbatim payload (`callAdd_attempt_request`, `hopRequest_payload`).
- 116-118 `revert RequestAdditionFailed(request)` ↔ `Fault.reason "RequestAdditionFailed"`, world restored (`callAdd_fault`, `callAdd_error_restores`; invoke failure paths all return the incoming world — CallData.lean:11-19).
- 120 `emit ConsolidationRequestAdded(request)` ↔ `requestAddedEvent ctx.self request` appended to the callee-returned world on success only (`callAdd_success`). Per-octet word encoding is explicitly disclaimed as not a LOG-topic/ABI claim (LiveCall.lean:72-76).

WithdrawalVault.sol / EIP7685 guards:
- 203-205 `NotConsolidationGateway`, 60-61 `ZeroArgument`, 62-63 `ArraysLengthMismatch`, 66 checked `requestsCount * fee` (modeled as `< UINT256_MODULUS` else `Panic(0x11)`), 123-126 `IncorrectFee` — modeled in source order in `addConsolidationRequestsVault` (LiveCall.lean:540-559).
- 68-72 per-pair `_validatePublicKey` source then target, then hop — `addConsolidationRequestsLoop` matches, including short-circuit on first invalid width (`loop_cons_invalid`).
- 81-85 `preservesEthBalance`: entry balance read before the body; model's entry world is the post-payable-credit world, and success concludes `balances self = entry - msgValue` (line 84 `assert`), enforced via `Panic(0x01)` (`executeVault_success`).
- Root rollback: `Live.run` restores the entire entry world on error; `executeVault_failure_restores` proves `world = before` — matches EVM root-revert semantics, with attempts retained as audit observations.

ConsolidationGateway.sol (pin verified):
- 295-307 `_refundFee`: `refund > 0` gate (`refund_zero`), `address(0)` → `msg.sender` (`resolveAddress`, `resolveAddress_val` = `resolveRecipient`), 302 `recipient.call{value: refund}("")` (empty payload, exact remainder — `refund_attempt_request`), 303-305 `FeeRefundFailed` with restore (`refund_error_restores`, `refund_rejected`).
- 212-213/302 value split: `refund_value_split` reuses `checkFee_additive` (Gateway.lean:237); `refund_request_is_hop` ties the Live request to the reviewed `RefundHop` (same recipient word, same value).

Live primitive audit (LidoSRv3/Audit/Source/TrioReserve1): `CallData.invoke` (code check → funds check → provisional `transfer` → callee reply; rejection restores incoming world), `Live.run` (root restore), `transfer` (alias-safe debit/credit), `CallSpec.Invokes`/`CallDataFlow.to_spec` (relational spec used by `callAdd_success_funded`) all read and consistent with their use here.

## Honestly stated residuals (confirmed in code/docs, not hidden)

- `CallData.invoke` checks callee code; Solidity low-level `.call` does not. Model reverts where source would succeed on a code-less target; success theorems are stated on funded, code-present paths (LiveCall.lean:48-51, LIVE-CALL.md:76-79).
- Error payloads are `Fault.reason` names; failed request octets remain in the attempt trace.
- `_getFeeFromContract` STATICCALL is a supplied word; `FeeReadFailed`/`FeeInvalidData` unmodeled.
- Panics are `Fault.reason "Panic(0x11)"/"Panic(0x01)"`, not ABI panic data.
- `LogFrame`/`BalanceFrame`/`Untraced` are explicit premises on the arbitrary `External` callee, never asserted about the EIP-7251 predeploy.
- Gateway→vault ABI hop (line 220) and the EIP-7251 callee body remain OPEN.
- Tests' inbox doubles are acceptance-shape, documented as not the predeploy; `native_decide` trust is confined to `example`s, not the inspected theorems.

## Guarantee scope

P-CONSOLIDATION stays OPEN — nothing in this increment closes it; `InspectAxioms` is lane-local and not wired into global Trust. ALLOC-1/ALLOC-2/RESERVE-1 untouched (out of scope). `#263 remains inadmissible`, `#276 fee-only` — consistent with the diff (no changes outside the consolidation lane).

## Findings

No defects found. Correspondence of live callee, payload, value, root rollback, ConsolidationRequestAdded log, and gateway refund hop to the pinned Solidity is exact as claimed; the build and compiler axiom report corroborate the packet.

VERDICT: CLEAN
