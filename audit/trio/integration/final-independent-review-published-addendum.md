# Independent review addendum — published memory sequences and reserve leaves

2026-09-07. This supplements, and does not change, `final-independent-review-round4.md` (SHA-256 `ed3ac12ac52c2d70bba53768218ccf82f31d153337c889bf59309f48f584f06a`). Checkout HEAD observed during review: `6db8ae21f076abe37436bb1a0d9d967da1be4565`. Review reads were pinned with `git show` to ALLOC2 `37d36ab07d7546f3fec5089529a27a2e93f5210a` and RESERVE `a7b7c16cc1bb283d08a3c42719a8c4f94a3eace2`; the mutable checkout and unfinished stored parent are not certified here. Solidity pin remains `17005714f151e5502c559932319a3f2f74ac2436`.

Reviewer configuration requested: GPT-6 Astra. Supplied session identifies GPT-6 without an independently verifiable runtime model ID; this is not an attestation of actual Astra assignment. Read-only source/archive inspection plus independent offline JSON/hash/ABI checks; no new Lean builds, chain executions or remote jobs. Only this addendum was written.

## Findings and recommendation

**Accept these published deltas within their documented scope. No new source blocker was found. Final trio completion/merge recommendation still awaits the combined stored parent and exact-candidate gates from round 4.**

1. **RESERVE independent leaf closure is supported.** `FrameReadSpec.Reads` enumerates locator failure, raw oracle failure, a short two-word tuple and decoded success, preserving returned world and ordered attempted calls. `AllocationFlowSpec.Evaluates` separately enumerates locator/queue/decode failures; success uses saved pre-call buffer/reserve and independent `AllocationSpec.Describes`, not the computed allocation as an assumed result. `AllocationFlow.allocation_unique` bridges that specification to the executable result; `AllocationFlow.withdrawal_corresponds` substitutes both independent leaf rules into the public withdrawal parent. Raw adversarial CALL outcome equalities are legitimate primitive boundaries. This independently reaches the same source-level leaf closure as the reviewed root ReserveLeaf modules. Real pinned getter/receiver claims still use the concrete pipeline binding and the already stated world/balance assumptions. No larger protocol history claim follows.

2. **ALLOC2 successive use of written memory is real within the source word-memory semantics.** `MemoryWrite.run_success` derives the post-array relation and allocation property. `MemoryWrite.sequential` feeds the first written memory into the second execution, with cumulative conservation and unchanged capacities. The runtime wrapper actually calls `Verity.Contract.run` twice using the first returned state. The dropped-write theorem and reset mutant detect losing the first update. There is no assumed final array relation in these closures.

   This executable writes the complete computed bucket array back to the existing region. It does not itself trace every internal compiler store. Its successful well-shaped sequence theorem is not a theorem of sequential later-revert rollback or arbitrary malformed-memory error priority. The separate byte-runtime vectors exercise their stated errors; the five new successful sequence records must not be advertised as error-sequence coverage. These boundaries are explicit and do not introduce a new full-bytecode obligation.

3. **The archived two-call Solidity observations match the actual model records.** I independently decoded all five stored ABI returns and compared both amounts and both result arrays with the actual Verity-run log and MemoryWrite vector log: two-calls, reverse-regions, below-capacity, zero-first, and 129-rows. The receipt archive hashes to its recorded digest, reports success/exit 0 and a 61-job build. Compiler-input source hashes and runner hash match; the reset-mutant log hash matches and its failure is the expected `two-calls exact bytes` assertion after execution.

   The Solidity harness invokes the pinned public library twice, passing the first returned array into the second call. Its two private callee memories are related through ABI copies; it does not share the Verity wrapper's physical memory. Original caller arrays are also returned for copy-semantics comparison. The reverse-regions case tests region ordering in the word-memory model; its Solidity input is identical to two-calls, so it is not a distinct reverse-address placement test of compiled Solidity. The 129-row case is unrestricted library coverage, not a reachable 129-module router state.

The archived receipt is job `9170d429-ad2f-4995-8fff-166651d51bea`, SHA-256 `52a0dc92ea348e20da55d0a1e286008ef14410f8e98d9fc4e595993d6d8d2366`, source overlay `4fec7c31886364c097ba2b25b2ae18eab1f6fb34adbe6cd32b825eddbac53164`. These checks corroborate that frozen archive and inspected harness; they are not a receipt for the concurrently edited final stored/copy parent. Round-4 local compiler-memory/frame boundaries, lifecycle writer scope and candidate validation requirements remain in force.

## Pinned source fingerprints

Each file was read from the corresponding immutable published commit above.

| File | SHA-256 |
|---|---|
| `audit/trio/alloc2/composition/MemoryWrite.lean` | `af353bf2995c212fde257c43f402de10b5eae1fb651b2791b611a8b49963d4b1` |
| `audit/trio/alloc2/composition/MemoryWriteVectors.lean` | `62fb8050f1d42e9f87645ccc0739e010a79270d4d37e1ddac999d300a140370a` |
| `audit/trio/alloc2/runtime/Library.lean` | `fcde6f592d2d96821edbc957bfef9c21d1e60e99d10398fd5e40d881bd850388` |
| `audit/trio/alloc2/runtime/Vectors.lean` | `1aa16f7159bc336f37ada29169d8055f4bc3adac85cfb9dd6ee4bf2430a7d813` |
| `solidity/trio-alloc2/MemorySequence.sol` | `b16b8a588928d15dc1ecfdd64512ab2f933e9ef11a4855dd29124f78e5ec7442` |
| `solidity/trio-alloc2/memory-sequence.mjs` | `63658422458fb8c10d14aaa77692d45d3125450030c96e50b5a8976b09dc1fbc` |
| `audit/trio/alloc2/memory-sequence-execution.json` | `abbd110a4fb52f02432eb5a19e286d61e1e95037e8755908049a8085cb9a0cac` |
| `audit/trio/alloc2/memory-sequence-mutant.json` | `8fe2400408f62e989e38fe8e361e66cf0bd2773598974b90fd5bea3d652a28ec` |
| `LidoSRv3/Audit/Source/TrioReserve1/FrameReadSpec.lean` | `66a122d0c0ad3b804820141720d58d4f332ed21b380a551334520276743902f3` |
| `LidoSRv3/Audit/Source/TrioReserve1/FrameRead.lean` | `c5ee90958ab5045ae2f5204913331a50610f1c8f9941787f08e980cae8e6d0e5` |
| `LidoSRv3/Audit/Source/TrioReserve1/AllocationFlowSpec.lean` | `2ab14bbcc8bc114eb00a1c63c55adfbb42ff749af781481eaf072077c5109e72` |
| `LidoSRv3/Audit/Source/TrioReserve1/AllocationFlow.lean` | `cb5d67055e515e193d2cd64207967df0e2a937cd95b05a901af2e7119f56682b` |
