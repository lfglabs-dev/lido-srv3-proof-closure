# ALLOC-2 completion audit (not a completion claim)

The active objective remains the complete ALLOC-2 source/producer/consumer task.
These entries separate proved boundaries from missing integration evidence.

| Requirement | Current evidence | Remaining work |
| --- | --- | --- |
| Proportional source loop | TrioAlloc2 Step, LoopTotality, LoopCorrespondence and Errors prove the well-founded executor against independent Spec.Distributes, including short capacities and zero demand. | The canonical parent now adds the exact well-founded success domain, independent distribution, and short-capacity error. Final signature passed production/test/trust-import build c54d0852 (1529 jobs), with all 258 canonical source inputs checked against the receipt. |
| Actual ALLOC-1 output establishes premises | Composition.producer_success_establishes_consumer_premises derives equal lengths and the word-width count bound from actual produce success and producer_router_order. ProducerMemory derives ABI extent from executed guards. | Connect the complete enclosing entrypoint and its source-memory/ABI schedule to the registered consumer. |
| Physical memory | ByteMemory/ByteIndexed/ByteFrame prove indexed consecutive-byte stores, overlap behavior, whole-loop array and byte preservation. ByteInitialize/ByteProducer construct entry arrays from actual output. | The adjacent serialization adapter is not yet the complete compiler allocation/write/copy schedule. |
| Verity memory | Indexed ContractState execution and rollback passed 62 jobs and six Solidity cases. ByteRuntime directly bridges pinned DenoteMemory readWord/writeWord to the physical loop; Final 48-file package e47f752f passed 74 jobs, including derived initializer coverage and whole-loop size preservation, followed by six exact Solidity comparisons and rejection of the reset mutant. | ByteABI/ByteABIProducer now prove exact argument/return copying and distribution from successful interleaved producer execution; ByteABIFrame proves separated caller-array preservation. The 58-file package passed 69 jobs in 4862113d, with 14 Solidity comparisons and a rejected shifted-copy mutant. Account for every compiler read/copy and derive separation from its allocation schedule when connecting canonical execution. |
| Lifecycle | DecodedConsumerPremises is proved for arbitrary Layout, Storage, StaticOracle, CapacityInput and Transcript, conditional only on actual producer success. It has no 32-cap, migration, uniqueness, active-row, or global arithmetic-success premise. | This discharges the need for those lifecycle assumptions at that specific consumer-premise boundary. It does not certify every router lifecycle operation. The canonical/enclosing claim must be checked against this boundary before broader lifecycle closure is asserted. |
| +1 algorithm | Kept separate; no +1 model changes in this work. | Preserve separation in canonical registration and prose. |
| UX2 | Generated artifacts pass consistency checks against the existing registered declarations. | Parent, assurance-detail digest, immutable report input basis, source map and generated surfaces are updated together. Metadata, claim-surface and inventory regressions passed; the Python size check passed after shortening a comment. Native full UX2 remains unverified. |
| Differential evidence | Pinned Solidity compilation/deployed bytes, exact outputs and behaviorally rejected reset mutants are committed for byte and indexed word-memory paths. | The DenoteMemory overlap/msize suite is refreshed against successful exact-source receipt e47f752f. |
| Full gates | Canonical production/test/trust-import build c54d0852 passed 1529 jobs on fixed base924891 plus the exact final canonical amendment. Source admission verifies all258 current canonical inputs. Scoped byte proofs passed74 jobs. | Final immutable-head full prove/test/UX2/trust remains unverified. Current remote-only protocol does not support the complete verification commands; do not use the trust script's internal local-execution override. |

Compiler/linking provenance assumptions remain explicit. Deployment binding,
gas equivalence and full consensus/primitive-crypto claims are not silently
introduced into this task. A source/model result is not a deployed-bytecode
refinement. Conversely, a scope exclusion must not hide a required source,
producer-entry or canonical integration gap.

## Decoder test continuation (2026-09-07)

`solidity/trio-alloc2/parent/decoder-copy-reference.cjs` independently compiles
and executes `DecoderCopy.sol` with solc 0.8.25, via IR, Shanghai semantics.
Six successful return-byte comparisons cover zero, one, multiple, unaligned,
and 129-word copies. Four additional cases check exact short-source, checked
multiply/add overflow, and truncated-ABI revert bytes. The destination-stride
mutant compiles, deploys, passes zero/one-word cases, and fails the two-word
return-byte comparison. `word-copy-reference.json` records inputs, expected
and actual bytes, compiler settings, deployed code, and source/harness hashes.
Durable job `3911faed-064f-47fb-8a16-e642d1708ac2` completed with exit 0.

The previously untracked `ByteWordCopyVectors.lean`, `DecoderCopy.sol` and
`decoder-copy.cjs` are now retained as test sources. The vector module is
included in the 60-file byte-ABI preparation manifest and Lake target list.
The Lean/Solidity runner requires the matching successful vector target receipt
and independently checks its Lean outputs against byte slicing before EVM
comparison. No successful receipt exists for this new target yet; the updated
manifest does not validate against the older 59-file receipt. The independent
Solidity result does not discharge the pending Lean differential gate.

The previous goal turn made progress by committing and pushing the decoder
proof. This continuation adds executed independent test/mutant evidence, but
the full goal remains incomplete. Rechecking durable admission job
`c5928cd0-419e-4db2-ac3c-b5b044501caa` confirms terminal failure, exit 1;
there is no admitted remote job to poll. No new submission was made against
the known 16 MiB complete-source rejection. Full-source admission, complete
compiler schedule and canonical entrypoint composition, and immutable-head
full Lean/prove/test/native UX2/trust validation remain outstanding.
