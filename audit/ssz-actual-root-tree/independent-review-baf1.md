# Independent actual-root validator-tree review

**CLEAN at exact candidate `baf166d7c96e9b6104b8c515cdb5020f2a7ddbc9`**, base `14a96a3180ac9fb81f853db36af3b630c1d5891f`, in `/tmp/lido-ssz-memory-consumer`. Frozen clean checkout confirmed; root writer stopped. No proof, source-correspondence, hidden-premise, reachability or evidence defect blocks this scoped increment. I authored none of the candidate and performed no repository edit or duplicate build.

## Public improvement and nonvacuity

`PSsz1.actual_root_staticcall_validator_tree` strengthens the existing typed actual-root-call consumer: its branch leaf is the digest of an independently constructed eight-field validator container, not merely an existential value returned by sourceLeaf. The same actual STATICCALL reply remains the root, and the same actual request/attempt and unchanged World conclusions remain present. Its only propositional input is success of the unchanged SszRootCall.run.

This is a real consumed connection. The existing independent-tree equality applied to standardSha, a globally successful 32-byte adapter. The new leaf_success_tree instead inverts actual successful leaf execution and derives equality using the output fields of that very precompile interpretation. The public theorem substitutes the resulting independent tree into the previously proved branch, then transports only its successful hash edges. It does not pass a payload beside an unrelated result, assume the desired leaf/root or add a successful-stage or globally successful/width premise.

The independent validatorTree is not defined by running sourceLeaf: it is the existing separate Tree constructor from semantic witness fields and credentials, with independent uint64/bool chunks and pubkey padding. outputSha projects each existing reply's output field; it does not modify the executed interpreter or force success. Functional determinism is inherited from the existing Precompile type, not introduced as a new hypothesis.

The regression executes the full typed entry with an interpretation that succeeds only on 64-byte inputs and fails with width0 on other inputs. Kernel evaluation proves both actual whole-entry success and the failing empty-input behavior. The second theorem instantiates the new public consumer on that exact success. This witnesses a nonempty admitted domain without a globally successful adapter. It is not a cryptographic SHA test; the successful fixture deliberately returns zero digests, and no stronger claim is attributed to it.

## Complete source and transitive audit

Read all three new Lean files, full proofs, regression definitions, the public facade changes and the complete dossier/validator. Re-read existing SszValidatorLeaf executable definitions and independent tree specification, including checkedSha, sourcePubkeyRoot, sourceMerkle, sourceLeaf, pair, validatorTree, sourceSlashed and the field/padding equalities. Existing SszRootCall, SszVerifierEntry, SszProofFold, SszWrapperIndex and low-level STATICCALL correspondence was fully reviewed independently for PR311; these executable sources are unchanged. That exact review is reused within its original typed source/scratch-output boundary.

- **Pubkey and padding:** actual leaf success derives length48. source_pubkey_padding proves clearing/copying yields those 48 bytes followed by16 zeros, independently of old scratch contents. checked_sha_output obtains the output from the actual checked reply. No arbitrary precomputed pubkey hash enters the tree.
- **Container fields:** credentials come from the separate actual expected-credentials argument. Effective balance and four epochs are the same uint64 fields; source uint256 little-endian conversion of their zero-extension equals the independent chunks. The source slashed uint64 cast is matched to the bool chunk. Seven pair calls are consumed in four-bottom/two-middle/one-root source order.
- **Successful hashes:** merkle_success's local soundness parameter is discharged from checked_sha_output for actual sourcePair; it is not a public assumption. Each BLS success derives its existing success-and-width check. No failed or short reply at an unused input needs exclusion.
- **Branch:** branch_output_tree inducts over the independently defined Branch. Its edge implication follows from actual foldHash success, so only the output of successful edges is projected. The pinned SSZ proof loop checks CALL success, not return width; the new proof correctly does not invent a width guard or require one globally.
- **Actual root composition:** the public proof obtains the actual call, data guard, wrapper result, source leaf and independent Branch from actual_root_staticcall_validator_branch. It consumes leaf_success_tree and rewrites that very branch leaf, preserving the actual reply root, original proof, single root attempt and unchanged World. Request construction/order/no-code behavior remain those of the reviewed executor.

Compared with pinned core `17005714f151e5502c559932319a3f2f74ac2436`: CLValidatorVerifier source fields and slot/root/index/leaf/proof sequence; BLS full-word SHA inputs, 48-byte key copy and width checks; SSZ left/right proof hashing and success-only guard. All six actual compiler-input core source bodies still match the pin. No change is made to the Solidity transcription or its pre-existing errors/order.

## Exact validation and integration

Independently recomputed all **14 receipt SHA256 values**, all **792 source hashes**, and compared all 792 source bodies to actual Git blobs. Checked **11 package HEAD pins** and package source bodies against those exact pins. All match. The only existing source changes are additive AllGuarantees/Trust registration; no inherited executable or theorem was modified.

Read the retained **807-job targeted build**, **1,650-job AllGuarantees/Trust build**, kernel-regression log, five independently queried axiom sets and unchanged **29-exact-axiom** trust-check receipt. Public tree, leaf equality and instantiated consumer use only the established foundations; branch_output_tree has no axioms; kernel execution uses propext/Quot.sound. No new production axiom, native-decision exception, unsafe/admitted proof mechanism or hidden stage-success premise is introduced. These are identity-valid retained checks, not fresh reviewer compilation.

AllGuarantees directly imports the new public module. Trust imports its regression, which imports the public theorem, and explicitly queries the new theorem's axioms. Existing SSZ, settlement and ledger public imports/queries are preserved. The new statement is reachable from the real public facade and checked environment.

The nine PR311 Solidity tests are honestly reused, not described as a new run. Independently checked all **seven compiler-input SHA256 identities** and all six pinned core Git bodies; the fixture and inherited executable sources are unchanged. Those finite tests support the existing complete pinned verifier fixture correspondence; the new semantic-tree implication is established by the new Lean proof, not misrepresented as a new compiled execution test.

## Boundary and publication advice

The useful additional statement is: successful execution of the existing ordered typed validator entry binds the independently constructed SSZ validator container tree, under the same interpreted hash outputs, to the root actually returned by its timestamp STATICCALL.

SHA output still denotes the modeled scratch digest. This result does not newly prove raw return-data copying, deployed SHA semantics, cryptographic collision resistance or authenticity/freshness of an EIP-4788 root. The typed entry is not joined to PR310's initialized compiled-memory harness. Full raw ABI admission, complete declared-proof-list equality, opcode/gas equivalence and complete SHA/nested-call trace remain outside the increment. Calling the static target an EIP-4788 root source must not be presented as authenticating the returned bytes.

No accepted boundary is strengthened. No existing public claim is narrowed, and ALLOC-1/ALLOC-2/RESERVE-1 are untouched. This exact increment is suitable for integration and later additive site wording under the scope above. An artifact-only successor can reuse this source/build review after exact delta and receipt-identity confirmation.
