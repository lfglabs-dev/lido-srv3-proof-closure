# Consolidation low-level CALL / fee STATICCALL / predeploy body / ABI hop packet

Pin: `lidofinance/core@17005714f151e5502c559932319a3f2f74ac2436`.
Branch: `p-consolidation-lowlevel-call`, on `origin/main` after the merge
`7db9187e` of PR #281 (exact head `33b6053794ac96251a9f0713dbee7ec8b5c9612e`).
Historical packets: `CODEC-VALIDATION.md`, `PRODUCER-PAYLOAD.md`,
`LIVE-CALL.md`. Independent review of #281: `review-281/`.
P-CONSOLIDATION remains OPEN. No guarantee is credited. No merge.

The #281 review (`review-281/independent-review.md`, "Honestly stated
residuals") named four internal obligations of the Live CALL increment.
This branch closes exactly those four inside the consolidation lane and
nothing else:

| # | Obligation | Where |
| --- | --- | --- |
| 1 | Low-level `.call` has no target-code guard; the model reverted on a code-less target where the source succeeds | `LowLevel.lean` (`lowLevelCall`), `LiveCall.lean` (`callAdd_no_code_accepted`, `refund_no_code_accepted`) |
| 2 | `_getFeeFromContract` was a supplied word; `FeeReadFailed` / `FeeInvalidData` were not modeled | `LowLevel.lean` (`lowLevelStaticCall`), `LiveCall.lean` (`getConsolidationRequestFee`, `feeRead_ok`) |
| 3 | `LogFrame` / `BalanceFrame` / `Untraced` were premises on an arbitrary callee | `Predeploy.lean` (`predeployBody`, `predeployBody_logFrame`, `predeployBody_balanceFrame`, `predeployBody_untraced`, `executeVault_success_frame_predeploy`) |
| 4 | The gateway→vault ABI hop (`bytes[]` pairs, line 220) was OPEN | `Composition.lean` (`gatewayVaultArgs`, `decodeVaultArgs`, `decodeVaultArgs_gatewayVaultArgs`, `hop_payloads`) |

Files of this increment: `audit/trio/consolidation/{LowLevel,Predeploy,Composition}.lean`
(new), `audit/trio/consolidation/{LiveCall,InspectAxioms}.lean` (changed),
`LidoSRv3/Tests/TrioConsolidation/{Predeploy,Composition}.lean` (new),
`LidoSRv3/Tests/TrioConsolidation/LiveCall.lean` (changed). No file of the
ALLOC / RESERVE / SSZ / TOPUP / DEPOSIT / ACCOUNT / ADDRESS lanes is touched;
no registry, guarantee, or public identifier changes.

## 1. Low-level CALL (`LowLevel.lean`)

`lowLevelCall external ctx target payload value` is the EVM CALL rule as
Solidity's low-level `<address>.call{value}(payload)` issues it:

| Arm | Rule |
| --- | --- |
| caller balance `< value` | failed attempt, no callee run, world unchanged |
| target has no code | **accepted**, empty return data, world = value transfer (EOA arm) |
| target has code | callee runs on the credited world; rejection restores the incoming world |

The existing `CallData.invoke` / `StaticCall.call` (typed, code-guarded
high-level calls) are untouched; they remain correct for the interface calls
that use them elsewhere. `lowLevelCall_shape` is the exhaustive case split;
`lowLevelCall_success_funded` is the only precondition of success (funds, not
code).

Consumers:

| Source | Model |
| --- | --- |
| `WithdrawalVaultEIP7685.sol:115` `CONSOLIDATION_REQUEST.call{value: fee}(request)` | `callAddConsolidationRequest` = `lowLevelCall callee ctx inbox (vaultCallPayload pair) fee` |
| `ConsolidationGateway.sol:302` `recipient.call{value: refund}("")` | `refundFee` = `lowLevelCall callee ctx (resolveAddress recipient sender) [] refund` |

`callAdd_no_code_accepted` (also under the stable name `callAdd_no_code`
that #281 inspected): a code-less, funded hop target accepts, the
value moves, `ConsolidationRequestAdded` is emitted, the callee double never
runs. `refund_no_code_accepted`: an EOA refund recipient is the valid path
the code-guarded primitive rejected. Every #281 theorem
(`callAdd_*`, `loop_*`, `executeVault_*`, `refund_*`) is re-proved on the
new primitive with the same statement, except that the no-code arm is now
acceptance and `executeVault_*` take the STATICCALL body (below).

## 2. Fee STATICCALL (`LowLevel.lean`, `LiveCall.lean`)

`lowLevelStaticCall external caller target payload w` is the STATICCALL rule
without a target-code guard: a code-less target answers success with empty
return data; a coded target runs the read-only external. It never moves value
or state (`lowLevelStaticCall_shape`).

`getConsolidationRequestFee sexternal ctx inbox` is
`_getConsolidationRequestFee` / `_getFeeFromContract(CONSOLIDATION_REQUEST)`:

| Source (`WithdrawalVaultEIP7685.sol`) | Model |
| --- | --- |
| 84 `contractAddress.staticcall("")` | `lowLevelStaticCall sexternal ctx.self inbox []` |
| 86-88 `revert FeeReadFailed()` | `Fault.reason "FeeReadFailed"` on a failed STATICCALL |
| 90-92 `revert FeeInvalidData()` | `Fault.reason "FeeInvalidData"` on returndata length ≠ 32 (a code-less target lands here: empty success) |
| 94 `abi.decode(feeData, (uint256))` | `Live.word (decode feeData)` (`feeRead_ok`) |
| 65-66 `fee = _getConsolidationRequestFee(); _requireExactFee(requestsCount * fee)` | `addConsolidationRequestsVault` reads the fee after the `ZeroArgument` / `ArraysLengthMismatch` guards and before the checked exact-fee requirement, in source order |

`executeVault_success` now states that a committed entrypoint actually read
a 32-byte STATICCALL reply and that the exact-fee check held for the decoded
word. The fee is read, not supplied. (`Gateway.lean`'s gateway-side
`getConsolidationRequestFee()` read of line 211 is still a supplied word;
that call is the gateway's typed interface call to the vault and is outside
this packet.)

## 3. Predeploy body, frame derived (`Predeploy.lean`)

`predeployBody : External` is a concrete callee for the EIP-7251
consolidation-request predeploy (`0x0000BBdDc7CE488642fb579F8B00f3a590007251`):
reject unless the request is exactly 96 octets; reject when `msg.value <`
the fee slot of the credited world; otherwise write the count and three
queue words retaining all 96 octets, return empty data, touch no logs and no
balances. `predeployStaticBody : StaticCall.External` answers
`staticcall("")` with the 32-byte encoding of the fee slot.

| Claim | Theorem |
| --- | --- |
| Acceptance / underpayment / malformed arms | `predeployBody_accepted`, `predeployBody_underpaid`, `predeployBody_malformed` |
| `LogFrame predeployBody` — derived, not assumed | `predeployBody_logFrame` |
| `BalanceFrame predeployBody` — derived, not assumed | `predeployBody_balanceFrame` |
| `Untraced predeployBody` — derived, not assumed | `predeployBody_untraced` |
| Line-87 `staticcall("")` against the body returns the fee slot | `predeploy_fee_read` |
| Committed entrypoint against the body: events per pair in order, ledger moved `msg.value`, **no frame premise** | `executeVault_success_frame_predeploy` |

`executeVault_success_frame` (generic callee, explicit frame premises) is
kept; the predeploy theorem instantiates it with the derived frames.

## 4. Gateway→vault ABI hop (`Composition.lean`)

`ConsolidationGateway.sol:220`
`withdrawalVault.addConsolidationRequests{value: totalFee}(sourcePubkeys, targetPubkeys)`.

| Claim | Theorem |
| --- | --- |
| `bytes[]` tail = count word ++ framed elements (`encodeBytesElement`) | `framedBytesArray`, `framedBytesArray_length` |
| Argument block = head offsets `64`, `64 + |sources tail|`, then the two tails | `gatewayVaultArgs`; `gatewayVaultCalldata` prefixes the solc-0.8.25 selector `0xa75ac640` |
| Framed element decodes with any suffix; dropping it leaves the suffix | `decodeBytesElement_append`, `drop_encodeBytesElement_append` |
| Framed sequence / tail decode back to the blobs, consuming exactly the framing | `decodeFramedSeq_flatten`, `decodeBytesArray_framed` |
| Decoding the encoded hop returns exactly `(sources, targets)` | `decodeVaultArgs_gatewayVaultArgs` |
| Hop arrays from the committed gateway pairs are 48-octet blobs | `hopSources_length`, `hopTargets_length` |
| Zipping the hop arrays is the vault's `pairsOf` input | `pairsOf_hopArrays` |
| Every zipped pair passes `_validatePublicKey` width | `widthOk_hopArrays` |
| Gateway packed payloads = per-pair `integerBE` concatenations | `packedPayloads_eq_map` |
| Vault's re-packed line-114 payloads = gateway's packed payloads (same 96 octets) | `hop_payloads` |

## Residuals (stated, not claimed)

* EIP-7251 fake-exponential per-block fee update, excess accounting, queue
  head/tail ring positions and the source's exact revert data are not
  modeled; the fee is a slot and rejection is empty returndata.
* The line-220 selector is the concrete solc-0.8.25 ABI value `0xa75ac640`;
  deriving that value from keccak256 remains outside this model. Solidity's
  ABI decoder additionally bounds-checks
  head/tail lengths against calldata size; `decodeVaultArgs` refuses short
  heads and unframed elements and the round trip is stated for the
  encoder's output.
* `RequestAdditionFailed(request)` / `InvalidPublicKeyLength(pubkey)` /
  panics remain `Fault.reason` names; request octets remain in the attempt
  trace.
* The gateway-side line-211 `withdrawalVault.getConsolidationRequestFee()`
  in `Gateway.lean` is still a supplied word (typed interface call, not the
  low-level STATICCALL of this packet).
* Nothing here binds to deployed bytecode, a runtime codehash or a chain
  address. Test doubles are not the predeploy; `predeployBody` is a model
  body, not the EIP-7251 implementation.

## Tests

`LidoSRv3/Tests/TrioConsolidation/LiveCall.lean` (changed): the #281
vectors on the new primitive (fee doubles answer `staticcall("")`), plus the
fee ladder (`FeeReadFailed`, 16-byte `FeeInvalidData`, code-less target
`FeeInvalidData`), the code-less hop target accepted with the value moved,
and the EOA refund recipient accepted.

`LidoSRv3/Tests/TrioConsolidation/Predeploy.lean` (new): fee `7` read from
the predeploy slot; committed 2-pair batch with no frame premise (requests
at the read fee, balances `0 / 14`, count `2`, six queue words retaining all
96 octets per request, fee slot untouched, exactly the vault's two events);
`IncorrectFee` against the read fee; code-less predeploy address →
`FeeInvalidData`; body arms (48-octet request, underpayment, slot `8`).

`LidoSRv3/Tests/TrioConsolidation/Composition.lean` (new): head offsets,
count words, first framed element, round trip, truncated / mis-headed blocks
refused, unequal arrays decode (the vault guard is downstream), hop arrays
equal the producer blobs, zip = `pairsOf`, re-packed payloads = gateway
packed payloads.

All vectors are `native_decide` on projections of `Live.run` results and
of the decoders. This adds `native_decide` sites under `LidoSRv3/Tests/`;
the `scripts/check_proof_escapes.py` inventory baseline (218) already
differs from `origin/main` (291) before this branch, so that guard is not
re-pinned here.

## Targeted compile / axiom inspection

```
lake build +audit.trio.consolidation.LowLevel +audit.trio.consolidation.LiveCall \
  +audit.trio.consolidation.Predeploy +audit.trio.consolidation.Composition \
  +LidoSRv3.Tests.TrioConsolidation.LiveCall +LidoSRv3.Tests.TrioConsolidation.Predeploy \
  +LidoSRv3.Tests.TrioConsolidation.Composition +audit.trio.consolidation.InspectAxioms
```

True compiler exit (`set -o pipefail`, no `tee` shim). Lean 4.31.0
(commit 68218e87), Lake 5.0.0. Base `222f1870` (`origin/main`). Result:
`Build completed successfully`, exit 0. The receipt for the exact pushed
head is in the PR body.

`#print axioms` of `InspectAxioms.lean` (compiler output, this increment):

| Theorem | Axioms |
| --- | --- |
| `lowLevelCall_shape` | `propext` |
| `lowLevelCall_success_funded` | `propext` |
| `lowLevelStaticCall_shape` | `propext` |
| `callAdd_attempt_request` | `propext` |
| `callAdd_fault` | `propext` |
| `callAdd_error_restores` | `propext` |
| `callAdd_success` | `propext` |
| `callAdd_success_funded` | `propext` |
| `callAdd_no_code_accepted` | `propext`, `Quot.sound` |
| `callAdd_no_code` (stable name, = the acceptance arm) | `propext`, `Quot.sound` |
| `callAdd_unfunded` | `propext` |
| `callAdd_rejected` | `propext` |
| `callAdd_accepted` | `propext` |
| `callAdd_credited_balances` | `propext`, `Quot.sound` |
| `loop_success` | `propext`, `Quot.sound` |
| `loop_attempt_request` | `propext` |
| `loop_success_frame` | `propext`, `Quot.sound` |
| `executeVault_failure_restores` | `propext` |
| `executeVault_success_body` | `propext` |
| `executeVault_success` | `propext`, `Quot.sound` |
| `executeVault_success_frame` | `propext`, `Quot.sound` |
| `feeRead_ok` | `propext` |
| `predeployBody_accepted` | `propext` |
| `predeployBody_underpaid` | `propext` |
| `predeployBody_malformed` | `propext` |
| `predeployBody_logFrame` | `propext` |
| `predeployBody_balanceFrame` | `propext` |
| `predeployBody_untraced` | `propext` |
| `predeploy_fee_read` | `propext`, `Classical.choice`, `Quot.sound` |
| `executeVault_success_frame_predeploy` | `propext`, `Quot.sound` |
| `decodeBytesElement_append` | `propext`, `Classical.choice`, `Quot.sound` |
| `drop_encodeBytesElement_append` | `propext` |
| `decodeFramedSeq_flatten` | `propext`, `Classical.choice`, `Quot.sound` |
| `decodeBytesArray_framed` | `propext`, `Classical.choice`, `Quot.sound` |
| `decodeVaultArgs_gatewayVaultArgs` | `propext`, `Classical.choice`, `Quot.sound` |
| `pairsOf_hopArrays` | `propext` |
| `widthOk_hopArrays` | `propext`, `Quot.sound` |
| `packedPayloads_eq_map` | `propext` |
| `hop_payloads` | `propext`, `Quot.sound` |
| `refund_zero` | `propext` |
| `refund_attempt_request` | `propext` |
| `refund_error_restores` | `propext` |
| `refund_rejected` | `propext` |
| `refund_accepted` | `propext` |
| `refund_no_code_accepted` | `propext` |
| `refund_value_split` | `propext` |
| `refund_request_is_hop` | `propext` |

`Classical.choice` appears on exactly the five theorems that reuse the
existing `ABI.decode_encode` / `ABI.decode_encode_bounded` round trip
(`#print axioms` of those two: `propext`, `Classical.choice`, `Quot.sound`),
as the existing `decode_encode_bytes_element` already did. No `sorryAx`, no
`Lean.ofReduceBool` on any theorem of the lane. The `InspectAxioms` module is
lane-local and not wired into global Trust.

## Repository checks

Run on this tree: `check_source_annotations.py` (814 citations, 0 false),
`check_report_theorem_inventory.py`, `check_diagram_taxonomy.py`,
`check_assumption_presentation.py`, `check_python_quality.py` pass.
`check_proof_escapes.py` (native_decide baseline), `check_import_dag.py`
(`TopupBeaconFundedTx`, `TopupFundedSourceTx` globs),
`check_public_claim_surfaces.py` (`PTopup1.lean`), `audit_metadata.py check`
and `generate_ux2.py check` (`P-TOPUP-1`) fail identically on a clean
`origin/main` extraction; they belong to the TOPUP lane and are not touched
here.

P-CONSOLIDATION remains OPEN.
