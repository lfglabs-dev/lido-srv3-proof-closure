# Independent review of final additive components

2026-09-07. Integrated checkpoint observed: `3310ad388656599f8963a137dfcfe01e235d4690`. Component source reviews are pinned to ALLOC2 `53c063bf553bc47a83429e410b97d64e1b237921` and RESERVE `f02806079748e7b55d0ae92e005cce94c876727a`. The source files listed below are byte-identical at that integration checkpoint. Final staged-module registration and integrated validation are still pending; this report does not certify a future clean SHA.

ALLOC2 reviewer: `/root/independent_composition_review`. Requested configuration was GPT-6 Astra; the supplied session identifies GPT-6 without an independently verifiable runtime model ID. No actual Astra assignment is attested. The latest RESERVE review is explicitly attributed below to `/root/memory_transport`, whose exposed session metadata likewise does not independently establish a configured runtime model identity.

This report consolidates source/archive reviews already performed. No production edits, local Lean builds, new remote jobs, push, merge or external comments were performed by this reviewer. Only this review artifact was written. Earlier review artifacts remain unchanged.

## Decision

**No source integration blocker was found in these additive components within their stated scope. Final merge recommendation remains conditional on the exact integrated candidate passing the required gates.**

These additions strengthen the previously accepted explicit memory/callee boundaries. They do not invalidate the earlier frozen stored-parent correspondence or require full deployed-bytecode, gas, DSL-migration or all-protocol-writer proofs.

## ALLOC2 — independent source and archive inspection

`IndexedMemory.plan` preserves the source's two scans, ceil division, next-level/capacity clamps and checked arithmetic. `plan_matches_step` identifies the prior source step; `plan_valid` derives the selected index bound. The executable writes only the selected element and reads the resulting arrays at the next iteration. `loop_related` covers success and errors without fuel, while `loop_frame` preserves all other observed word slots.

`ByteMemory.store` changes 32 consecutive bytes. Its disjoint-read lemmas and overlapping-read regression avoid the earlier invalid interpretation that all arbitrary MLOAD windows are independent word slots. `ByteIndexed` propagates array relations through selected physical byte stores, and `ByteFrame.run_frame` proves preservation outside the bucket-element byte region. `ByteInitialize.constructArrays_related` derives entry arrays from executed header/element stores into arbitrary prior memory. `ByteProducer.producer_output_store_bridge` consumes an actual successful producer result, derives header bounds from storage count and derives consumer execution/distribution; neither ArrayAt nor consumer success is supplied as a premise.

The ByteProducer adapter serializes adjacent arrays after the producer result. It does not execute the compiler's interleaved producer layout or the frozen integration parent's physical store/copy schedule. Nat addresses, allocation extent, compiler scheduling and gas remain explicit boundaries. The byte model is not a byte-backed Verity runtime. These exclusions are documented honestly and are not missing obligations for the previously accepted conditional composition.

`Runtime.indexedMemoryExecute` does execute the selected-word loop in Verity ContractState.memory. `indexed_after_prefix_reverts` derives a positive-demand short-capacity indexing failure and then whole-entry-state rollback after an arbitrary successful enclosing prefix. This is not an assumption of failure or of the final rollback state, nor a theorem about every possible later transaction sequence. Its result reason is the source runtime representation; the Solidity harness separately checks exact ABI panic bytes.

I independently verified the exact 41-file physical-byte and 52-file indexed-runtime source identities against the successful archived source-bundle receipts, including their pinned producer sources. Runner, dependency lock, compiler-input source and harness hashes match. I decoded all five stored sequential ABI result pairs against the corresponding actually executed model logs. The sixth indexed-runtime/Solidity case records panic 0x32, failed transaction status, no committed logs and restored marker; the runtime vector checks restored storage, balance and memory. Both reset-mutant source/log hashes match and both fail the intended `two-calls exact bytes` comparison.

The public Solidity library receives separate ABI-copied arrays. Its second call uses the first returned array. Reverse-region address placement is a model-side case, and the 129-row case is unrestricted library coverage rather than a reachable 129-module router state. Physical-byte sequence execution and word-memory Verity sequence execution remain distinct evidence planes.

| Archive | SHA-256 |
|---|---|
| Byte receipt `3f3d1147-45f4-4140-a493-ae09c0d0c3ca` | `d4319fb825efafaa321ba1d0b6736afc363513d3c30ec342b86a941bd8c44805` |
| Indexed-runtime receipt `25bab09b-edbd-47a0-b8af-071531fe598c` | `5f9ed000409db08bb031994c9e3d0438ade00ddc78edfda7b854abeefa027f8d` |
| `audit/trio/alloc2/byte-sequence-execution.json` | `b3a7d2104e0244984ccd8ac110aac724e56de12fa6e2808fa4fb7a2398480a15` |
| `audit/trio/alloc2/memory-sequence-execution.json` | `3609985ff3a52944f9bef1413c4b2c07eb049beff8a281f81a884e2a045e2f8d` |

## RESERVE — attributed independent review

The following findings are supplied by `/root/memory_transport`, which reviewed the complete `649b81ea..f0280607` delta read-only. This report does not present that latest source review as a second independent rereading by the ALLOC2 reviewer. The earlier CallSpec/CallFlow/WithdrawalCalls delta through 649b81ea was separately accepted by this reviewer.

The RESERVE reviewer found all 17 new production modules additive, with no existing TrioReserve1 production source changed and no source integration blocker. It compared `Report.collect`/`afterCalls` against pinned Lido.sol lines 1072–1132 at `17005714f151e5502c559932319a3f2f74ac2436`: saved locator, authorization and call order, mandatory uint256 reward-return decoding, post-call accounting, low-128-bit stored values versus full-value events, reserve increase and failure rollback match.

The reviewer recomputed all 95 current-head source hashes in the component evidence, with no mismatches. It also recomputed 23 runtime artifact hashes, six runtime-source hashes and 16 decompressed trace hashes/lengths, and compared all 16 Lean/Solidity result records exactly. No mismatches were found. The component proof-check source remains `2d357ae43ee340d38aa5189f6cab0e40604ab05e`; the runtime source remains `4f2b6867518337bc12acd8806fb1b463ff19c516`. These are preserved component records, not a new build or run at f0280607 or the integrated checkpoint.

The balance results retain an incoming finite aggregate-support bound and balance-preserving unhandled/delegated callees. Report callees in execution evidence are fixtures, not deployed vault/queue implementations. Raw external callback, resource and world bindings remain explicit. No arbitrary-successful-callback reserve guarantee, general protocol-history claim or clean/full-build claim follows from these records.

The attributed review's complete manifests are `audit/trio/reserve1/receipts/report-primitives-summary.json` (four new plus 91 reused source checks), its `component-checks/2d357ae43ee340d38aa5189f6cab0e40604ab05e/receipt.json`, and `report-execution-summary.json` with the `report-execution-4f2b6867518337bc12acd8806fb1b463ff19c516/` directory. I separately fingerprinted the two summary artifacts:

| Manifest | SHA-256 |
|---|---|
| `report-primitives-summary.json` | `9d6728240900bdc93b6ee28ccb9b4154e7461d01f5abbe321974a90257ac6369` |
| `report-execution-summary.json` | `c40eef488eef24ea2770517977973cef5a445700d28c7edbb573703515164ef4` |

## Remaining integrated validation

Component receipts and attributed source reviews do not replace exact integrated production/test/Trust checks, make prove/test, metadata/provenance/escape checks, or aligned generated views. The root reports that the bounded local ByteVectors run reached its 30-second limit on the 129-row physical-byte evaluation; this is neither a theorem failure nor a full-gate pass. It was excluded only from that bounded local checker and remains required in the full remote TrioIntegrationChecks registration. The prior successful byte-package receipt remains separately identified above.

A final clean-SHA review must confirm the component bytes and integration/registration changes, actual gate receipts, and honest delivery metadata. This artifact is ready to support that verdict, not substitute for it.

## Source fingerprints

ALLOC2 files below were directly reviewed. RESERVE files below are representative source fingerprints supplied by the attributed reviewer and independently matched against the published and integrated Git objects; the full 95-source manifest is identified above.

| File | SHA-256 |
|---|---|
| `audit/trio/alloc2/composition/IndexedMemory.lean` | `e797794d01ab9788e88a96aa7f79bc4870e744701231c8692e3c5ae24b1a1c0d` |
| `audit/trio/alloc2/composition/ByteMemory.lean` | `168c37a5020ae94233e553129de54bbe98c65aaedb8f0cfdd6c3082196b6e2bc` |
| `audit/trio/alloc2/composition/ByteIndexed.lean` | `f889aeefb24f175fb3c2ce36943e79f989d8def0261d3cd132a591e7315cd02c` |
| `audit/trio/alloc2/composition/ByteFrame.lean` | `4f3ac88486022647fadecd53a15c4c0c33f3e9508aa2660f1ef2b9d459af0320` |
| `audit/trio/alloc2/composition/ByteInitialize.lean` | `d3a3f008169bce351d94a26c56cbbe4e13992fde711f63806a2a36849154c308` |
| `audit/trio/alloc2/composition/ByteProducer.lean` | `0832c9b75a4ee1330108acfbd487d1a0e74936ee839d20e4c910b596e6d3ae34` |
| `audit/trio/alloc2/composition/ByteVectors.lean` | `f7fc3a462f3b3273c53fec850ab63b5f1e40137010f6a39ab598134bf8825011` |
| `audit/trio/alloc2/runtime/Library.lean` | `db7d308d1594d65a7a3959f4c87ba7f404d0cada487b7bc18067f49c1c6621aa` |
| `audit/trio/alloc2/runtime/Vectors.lean` | `100f4cb6ae1b340bc613f1c3f099a211ed87ccbe86716445beb59618cae78967` |
| `LidoSRv3/Audit/Source/TrioReserve1/Report.lean` | `a4e8e4feb5740819a87cb8d12553fe76fed13c0d251faaa80ff28f986db2745b` |
| `LidoSRv3/Audit/Source/TrioReserve1/CallData.lean` | `182787dda65d6cc315048e89212e1ef1bdb9d4c6a2084dad5413c303485d65eb` |
| `LidoSRv3/Audit/Source/TrioReserve1/CallDataFlow.lean` | `1a15f0a863475bcc7dac4786b936c3d7d407a376b69c69be8699ac872c4fcdb0` |
| `LidoSRv3/Audit/Source/TrioReserve1/ReportLookup.lean` | `51aebca4d341069b4bb37b1c5ab52b83c167726d743e35d64e448749c71d9f6d` |
| `LidoSRv3/Audit/Source/TrioReserve1/ReportRules.lean` | `8f6a74f1392344e90f8658069aedc1e28b063e6040ca176b9318883b551a3878` |
