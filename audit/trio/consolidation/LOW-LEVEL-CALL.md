# Consolidation low-level CALL / fee STATICCALL / predeploy body / ABI hop packet

Pin: `lidofinance/core@17005714f151e5502c559932319a3f2f74ac2436`.
Branch: `p-consolidation-lowlevel-call`, on `origin/main` after the merge
`7db9187e` of PR #281 (exact head `33b6053794ac96251a9f0713dbee7ec8b5c9612e`).
Historical packets: `CODEC-VALIDATION.md`, `PRODUCER-PAYLOAD.md`,
`LIVE-CALL.md`. Independent review of #281: `review-281/`.
P-CONSOLIDATION remains OPEN. No guarantee is credited. No merge.

> Revision after the independent review of head `94ef159c` (review
> 3bb8da69, verdict NOT CLEAN). That review confirmed one defect: the
> `Composition.lean` encoder omitted the per-element offset table and the
> 32-octet padding the Solidity ABI requires for `bytes[]`, so its 448-octet
> two-pair block was not the 640-octet block the gateway's line-220 call
> puts on the wire and its decoder would have refused real calldata. This
> revision repairs the framing (§4) and records, without closing them, the
> three fidelity residuals that review named: the fee STATICCALL attempt is
> not in the trace (§2), the predeploy body is a simplified stand-in (§3),
> and the code-less CALL acceptance arm does not exclude precompiles (§1).
> Obligations 1-3 remain closed relative to the model with those residuals
> stated; obligation 4 is now closed for the ABI framing and the payload
> identity, with the residuals of §4.

The #281 review (`review-281/independent-review.md`, "Honestly stated
residuals") named four internal obligations of the Live CALL increment.
This branch closes exactly those four inside the consolidation lane and
nothing else:

| # | Obligation | Where |
| --- | --- | --- |
| 1 | Low-level `.call` has no target-code guard; the model reverted on a code-less target where the source succeeds | `LowLevel.lean` (`lowLevelCall`), `LiveCall.lean` (`callAdd_no_code_accepted`, `refund_no_code_accepted`) |
| 2 | `_getFeeFromContract` was a supplied word; `FeeReadFailed` / `FeeInvalidData` were not modeled | `LowLevel.lean` (`lowLevelStaticCall`), `LiveCall.lean` (`getConsolidationRequestFee`, `feeRead_ok`) |
| 3 | `LogFrame` / `BalanceFrame` / `Untraced` were premises on an arbitrary callee | `Predeploy.lean` (`predeployBody`, `predeployBody_logFrame`, `predeployBody_balanceFrame`, `predeployBody_untraced`, `executeVault_success_frame_predeploy`) |
| 4 | The gateway→vault ABI hop (`bytes[]` pairs, line 220) was OPEN | `Composition.lean` (`abiBytesArray`, `gatewayVaultArgs`, `decodeVaultArgs`, `decodeVaultArgs_gatewayVaultArgs`, `executeVaultCalldata`, `executeVaultCalldata_gateway`, `executeVaultCalldata_success_payloads`, `hop_payloads`) |

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

Residual of the code-less arm (review 3bb8da69, not closed here): the EVM
treats precompile addresses (`0x01`-`0x0a` and later additions) as code-less
yet executing accounts; `lowLevelCall` / `lowLevelStaticCall` answer
"accepted, empty return data" for every code-less target, which is exact
for EOAs and undeployed addresses but not for precompiles (an empty payload
to `0x09` blake2f or `0x0a` KZG point evaluation fails on chain). The
theorems below are therefore stated for targets that are not precompiles;
the practical exposure is nil (the refund recipient is chosen by the role
holder; `CONSOLIDATION_REQUEST` has code), but the premise is now written
into the docstrings rather than implied.

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

Residual of the fee read (review 3bb8da69, not closed here): the STATICCALL
attempt record is dropped. `getConsolidationRequestFee` returns
`attempts := []` on every branch because `Result.attempts : List Attempt`
carries CALL attempts, while `lowLevelStaticCall` reports a
`List NestedAttempt`; the fee read is therefore invisible in the
`executeVault` trace. `executeVault_success` exhibits the STATICCALL reply
by re-running `lowLevelStaticCall` on the entry world, not by reading the
trace. Lifting static attempts into the trace (as `Oracle.frame` does with
`*WithTrace`) is left OPEN.

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
| Line-84 `staticcall("")` against the body returns the fee slot | `predeploy_fee_read` |
| Committed entrypoint against the body: events per pair in order, ledger moved `msg.value`, **no frame premise** | `executeVault_success_frame_predeploy` |

`executeVault_success_frame` (generic callee, explicit frame premises) is
kept; the predeploy theorem instantiates it with the derived frames.

Residual of the body (review 3bb8da69, not closed here): `predeployBody` is
a simplified stand-in of EIP-7251 shape, not the deployed predeploy. Beyond
the fee-update and excess accounting already listed, the real contract
records the *source address* (`msg.sender`) with each request and stores
four words per queue entry (source address, source pubkey, target pubkey
split over the words), whereas the model stores three words of the 96
request octets and no address; a CALL with empty calldata returns the fee
on chain but is rejected (`≠ 96`) by the model (unobservable from the vault,
which never CALLs with empty calldata); the system-call dequeue path is not
modeled. What the frame theorems close is the assumption on an *arbitrary*
callee; what remains OPEN is the correspondence of `predeployBody` to the
EIP-7251 bytecode. "Concrete EIP-7251 body" in this packet means "concrete
model body of EIP-7251 shape".

## 4. Gateway→vault ABI hop (`Composition.lean`)

`ConsolidationGateway.sol:220`
`withdrawalVault.addConsolidationRequests{value: totalFee}(sourcePubkeys, targetPubkeys)`.

The framing is the Solidity ABI encoding of `(bytes[], bytes[])`: two head
offset words; each tail is a count word, one offset word per element
(relative to the octet after the count word), then each element as a length
word, its payload, and zero padding to a multiple of 32 octets. For two
48-octet keys per array: element `96` octets, tail `288` octets, second
head offset `0x160`, argument block `640` octets. The encoder output for
that vector was compared octet for octet with ethers v6
`AbiCoder.defaultAbiCoder().encode(["bytes[]","bytes[]"], ...)` (640 octets,
identical; SHA-256 of the block
`0e67339e7c83a75539118ec18735760d407d33677891e9f29d4def4be1449f65`). That
comparison is an external check recorded here, not a Lean theorem.

The decoder follows offsets the way Solidity's calldata accessors for
`bytes[] calldata` do: head offset word, count word, per-element offset word,
length word, payload; missing words, offsets past the calldata, an offset
table that does not fit, and a length past the calldata are refused. Padding
octets and offset canonicity are not inspected (neither does Solidity).

| Claim | Theorem |
| --- | --- |
| ABI element = length word ++ payload ++ zero padding to 32; 48-octet key → 96 octets | `abiBytesElement`, `abiBytesElement_length`, `abiBytesElement_length_48` |
| Element offset table: one word per element, every offset inside the element area | `elementOffsets`, `offsetWords_length`, `elementOffsets_le` |
| `bytes[]` tail = count word ++ offset table ++ padded elements; `32 + 128·n` octets for `n` keys | `abiBytesArray`, `abiBytesArray_length`, `abiBytesArray_length_48` |
| Argument block = head offsets `64`, `64 + |sources tail|`, then the two tails; `640` octets for two pairs | `gatewayVaultArgs`, `gatewayVaultArgs_length`, `gatewayVaultArgs_hop_length`; `gatewayVaultCalldata` prefixes a selector parameter |
| Padded element decodes with any suffix; dropping it leaves the suffix | `decodeBytesElement_abi_append`, `drop_abiBytesElement_append` |
| Following the encoder's offset table over its element area returns the blobs | `decodeOffsetSeq_encoded` |
| Tail decodes back to the blobs, with any suffix | `decodeBytesArray_abi`, `decodeBytesArray_abi_nil` |
| Decoding the encoded hop returns exactly `(sources, targets)` | `decodeVaultArgs_gatewayVaultArgs` |
| Hop arrays from the committed gateway pairs are 48-octet blobs | `hopSources_length`, `hopTargets_length` |
| Zipping the hop arrays is the vault's `pairsOf` input | `pairsOf_hopArrays` |
| Every zipped pair passes `_validatePublicKey` width | `widthOk_hopArrays` |
| Gateway packed payloads = per-pair `integerBE` concatenations | `packedPayloads_eq_map` |
| Vault's re-packed line-114 payloads = gateway's packed payloads (same 96 octets) | `hop_payloads` |
| The committed hop, ABI-encoded, decodes back to its own arrays | `decodeVaultArgs_hop` |
| The vault entrypoint **on the raw calldata** (selector check, ABI decode, then `executeVault`) applied to the gateway's line-220 calldata *is* `executeVault` on the committed hop arrays | `executeVaultCalldata`, `executeVaultCalldata_gateway` |
| Committed success on that calldata: guards held, fee read by the line-84 STATICCALL, exact fee, and the attempted line-115 requests carry the gateway's packed payloads pair by pair | `executeVaultCalldata_success_payloads` |

Residuals of the hop (stated, not claimed): the selector is a parameter
(keccak256 outside the model; ethers gives `0xa75ac640` for the signature,
recorded here, not proved); Solidity validates each `bytes[] calldata`
element lazily at its access in the line-68 loop, after the fee read and
exact-fee check, while the model decodes everything before the body runs —
both revert the whole call so the committed state is identical, but the
fault name and the pre-revert attempt trace on malformed calldata differ;
the decoder accepts some non-canonical layouts Solidity also accepts
(swapped or reordered offsets, non-zero padding) and no claim is made about
them beyond "decodes to some arrays".

## Residuals (stated, not claimed)

* EIP-7251 fake-exponential per-block fee update, excess accounting, queue
  head/tail ring positions and the source's exact revert data are not
  modeled; the fee is a slot and rejection is empty returndata.
* The 4-octet selector of the line-220 hop is a parameter (keccak256 is
  outside this model). `decodeVaultArgs` refuses what Solidity's calldata
  decoder refuses (missing words, offsets or lengths past the calldata) and
  accepts every canonical encoding; element validation is eager here and
  lazy (per access in the loop) in Solidity; non-canonical layouts are not
  characterised (§4).
* The fee STATICCALL attempt is not recorded in the `executeVault` trace
  (`getConsolidationRequestFee` returns `attempts := []`); the read is
  exhibited by re-running `lowLevelStaticCall` on the entry world (§2).
* `predeployBody` is a simplified stand-in: no source-address field, three
  queue words per request instead of EIP-7251's four-word entries, no
  empty-calldata fee read via CALL, no dequeue path (§3).
* The code-less acceptance arm of `lowLevelCall` / `lowLevelStaticCall` is
  exact for EOAs and undeployed addresses, not for precompiles; the no-code
  theorems are read with "target is not a precompile" as a premise (§1).
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

`LidoSRv3/Tests/TrioConsolidation/Composition.lean`: the 640-octet
two-pair argument block spelled out word by word against the ABI
specification (heads `0x40` / `0x160`, counts, per-element offsets `0x40` /
`0xa0`, length words, 48 key octets, 16 zero padding octets); head, count,
offset, length and payload positions; round trip on two pairs, one pair, no
pairs, and 33- / 32-octet elements; refusals (truncated heads, truncated
payload, truncated first tail, head offset / element offset / element length
past the calldata, oversized count); Solidity-matching leniency (missing
padding octets, swapped heads decode swapped, reordered element offsets
decode reordered); unequal arrays decode (the vault guard is downstream);
hop arrays equal the producer blobs, zip = `pairsOf`, re-packed payloads =
gateway packed payloads; and the vault entrypoint on the raw calldata
against the predeploy bodies: same attempts, logs and balances as the array
entry, packed payloads on the wire, `UnknownSelector` / `AbiDecodingFailed`
reverts with no attempt, and `executeVaultCalldata_gateway` instantiated.

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
(commit 68218e87), Lake 5.0.0. Base `222f1870` (`origin/main`); submodule
`lido-core` initialised and verified at the pin in the build checkout.
Result on the revision-2 tree: `Build completed successfully (1275 jobs)`,
exit 0, no warnings on any `consolidation` / `TrioConsolidation` module;
97 `#print axioms` lines, none with `sorryAx` or `Lean.ofReduceBool`. The
receipt for the exact pushed head is in the PR body.

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
| `abiBytesElement_length` | `propext` |
| `elementOffsets_le` | `propext`, `Quot.sound` |
| `offsetWords_length` | `propext`, `Quot.sound` |
| `abiBytesArray_length` | `propext`, `Quot.sound` |
| `abiBytesArray_length_48` | `propext`, `Quot.sound` |
| `gatewayVaultArgs_length` | `propext` |
| `decodeBytesElement_append` | `propext`, `Classical.choice`, `Quot.sound` |
| `drop_encodeBytesElement_append` | `propext` |
| `decodeBytesElement_abi_append` | `propext`, `Classical.choice`, `Quot.sound` |
| `drop_abiBytesElement_append` | (none) |
| `decodeOffsetSeq_encoded` | `propext`, `Classical.choice`, `Quot.sound` |
| `decodeBytesArray_abi` | `propext`, `Classical.choice`, `Quot.sound` |
| `decodeBytesArray_abi_nil` | `propext`, `Classical.choice`, `Quot.sound` |
| `decodeVaultArgs_gatewayVaultArgs` | `propext`, `Classical.choice`, `Quot.sound` |
| `pairsOf_hopArrays` | `propext` |
| `widthOk_hopArrays` | `propext`, `Quot.sound` |
| `packedPayloads_eq_map` | `propext` |
| `hop_payloads` | `propext`, `Quot.sound` |
| `gatewayVaultArgs_hop_length` | `propext`, `Quot.sound` |
| `decodeVaultArgs_hop` | `propext`, `Classical.choice`, `Quot.sound` |
| `executeVaultCalldata_gateway` | `propext`, `Classical.choice`, `Quot.sound` |
| `executeVaultCalldata_success_payloads` | `propext`, `Classical.choice`, `Quot.sound` |
| `refund_zero` | `propext` |
| `refund_attempt_request` | `propext` |
| `refund_error_restores` | `propext` |
| `refund_rejected` | `propext` |
| `refund_accepted` | `propext` |
| `refund_no_code_accepted` | `propext` |
| `refund_value_split` | `propext` |
| `refund_request_is_hop` | `propext` |

`Classical.choice` appears exactly on the theorems that reuse the existing
`ABI.decode_encode` / `ABI.decode_encode_bounded` round trip (`#print
axioms` of those two: `propext`, `Classical.choice`, `Quot.sound`), as the
existing `decode_encode_bytes_element` already did: `predeploy_fee_read`
and the decode chain `decodeBytesElement_append` →
`decodeBytesElement_abi_append` → `decodeOffsetSeq_encoded` →
`decodeBytesArray_abi(_nil)` → `decodeVaultArgs_gatewayVaultArgs` →
`decodeVaultArgs_hop` → `executeVaultCalldata_gateway` →
`executeVaultCalldata_success_payloads`. No `sorryAx`, no
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
