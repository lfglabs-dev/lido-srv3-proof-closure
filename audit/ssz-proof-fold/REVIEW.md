# Independent review — SSZ computed-digest proof fold

Verdict: **CLEAN for the bounded increment** at exact candidate `f71fbcab599118c5e66484824bcee0e2c5a42f90`, against `42210924cd58ff751d2472f5ea998383fed4be7f`. No blocking or nonblocking finding requiring a change was identified. This is not full SSZ-1 acceptance, authentication of arbitrary beacon data, or a Lean-to-EVM refinement certificate.

Reviewer: independent site_audit agent; neither source/test nor Solidity-harness author. Read-only project review. No Lean/Forge/Next build, project write, commit, push or merge performed. Concurrent untracked TOPUP files excluded. This report is the sole reviewer write.

## Exact candidate and validation integrity

The candidate adds exactly nine files: Lean source/tests, six audit artifacts and the actual Solidity harness. Source commit `72ec48c97160180c2aa767d8738d4ac4f1903900` has parent 42210924; final f71fbcab adds only the two previously ignored validation logs. No source or configuration changed in that final log-preservation commit.

All 19 receipt SHA256 entries were independently recomputed against exact candidate Git blobs or immutable submodule blobs. All match, and the current corresponding file bytes also match. The core gitlink is exactly `17005714f151e5502c559932319a3f2f74ac2436`. Wrapper/endian source, manifests, toolchain, Lake configuration, Foundry configuration and core pin are unchanged from the reviewed base.

`check_source.py` was read and independently executed. Its three whole-file comparisons and 21 textual anchors pass and reproduce the committed source-check JSON exactly. These checks establish immutable source identity and reviewed anchors, not semantic equivalence by themselves.

Retained Lean log: targeted source/tests build succeeds, 788 jobs. Source contains 17 theorems, tests contain 26 regression declarations; six requested axiom queries all report only propext, Classical.choice and Quot.sound. No sorry, new axiom, native_decide or bv_decide shortcut appears in this increment. The log reports the source built and then tests built; no warning/error is shown. These are inspected author build receipts, not independently repeated compiler execution.

Retained Forge log: solc0.8.25 compiles five files; six tests pass, including three fuzz groups with 1024 runs each. The recorded command supplies seed0x20260909 and isolated output/cache paths. The harness imports actual pinned SSZ.verifyProof and pack, uses typed ABI arguments, and compares with a high-level SHA256/reference computed from bits of the original index. It exercises no full CLValidatorVerifier flow, forced SHA failure, malformed return data or raw calldata-pointer wrap. Those limitations are accurately recorded.

## Proof and source assessment

`Source/SszProofFold.lean:21` selects parity from the current index before shifting. An odd current index puts the sibling before the accumulator; an even index puts the accumulator before the sibling, matching SSZ.sol scratch placement. Parent zero rejects before attempting SHA. Every successful hash returns the next accumulator; no root-match Boolean or separately supplied computed digest bypasses that calculation.

Line34 faithfully places empty-proof InvalidProof before the loop. After a successful typed fold, lastIndex!=1 produces MissingItem before digest/root comparison. The model distinguishes ExtraItem, hashFailure and InvalidProof consistently with the source classifications. Error constructors classify outcomes; they do not prove ABI selector bytes. The Solidity loop has no returndatasize guard, and the model does not invent one.

Line47 `Branch` is an independent finite Merkle relation rooted at index1, extending with arithmetic children2*n and2*n+1 plus ordered parent-hash equations. It does not call sourceFold/sourceVerify, duplicate loop control, or embed successful executor equality. Lines80/96 prove both directions between structural construction and the digest-carrying fold. Line137 then gives exact success iff nonempty independent Branch. These are substantive correspondence results, not a projection of an assumed final result.

Line176 derives proof.length=log2(index), positivity and length<=247 from successful execution and the actual decoded uint248 input type. There is no artificial input bound on the proof list, no separately assumed no-wrap/depth condition, and index0/index1 remain admitted inputs that the verifier itself rejects when appropriate.

Lines191/220/228/266 connect arithmetic grafting, independent root-to-leaf tree position, leaf traversal and sibling extraction to the same Branch relation and tree digest. The tree proof permits stopping at an internal subtree, as expected for generalized indices. No hash injectivity is used.

Lines346/366 compose the previous checked wrapper and endian results with the new digest loop. The successful wrapper derives offset<2^40. The explicitly supplied input selection link `treeIndex path = 150*2^40 + offset` then derives path length47 and the correct header-relative index1430*2^40+offset. The consumer obtains one 50-element proof from one header tree, derives the leaf from that state's path, and uses that identical proof for both sourceVerify and sourceVerifySlotArithmetic with the same slot/proposer values. Its root is the digest of that same independently constructed header, not an independently supplied root-match conclusion.

## Regression quality

All 26 Lean witnesses were read. Empty-first, extra-before-hash, hash failure before later structural errors, missing-before-root, original parity, noncommutative operand order, accumulator updates, sibling order, wrong header index, both depth247 boundaries and missing/extra neighboring lengths are distinguished. The deterministic arithmetic hash is explicitly a witness, not SHA; commutative addition is confined to depth tests.

The six Solidity tests execute the actual imported verifier. Three fuzz properties cover valid/wrong roots, missing/extra proofs with structural-error precedence, and the pinned depth50 header-relative index versus the omitted depth47 prefix. Fixed tests include root/zero indices and empty proofs, both uint248 depth247 extremes, and independently computed parity-after-shift/sibling-order mutants that the actual verifier rejects. These finite differential checks support the reviewed transcription but do not establish universal compiler/EVM correspondence.

## Required residual boundaries

- Typed lists replace calldata pointers, byte lengths/loads, scratch writes and wrapped end arithmetic. Successful source operations are not yet a proof over arbitrary EVM calldata/memory or gas.
- Hash is a deterministic partial pair function. A repeated pair cannot model different outcomes caused solely by a changing gas schedule. Its some digest case represents a normal successful precompile writing all32 bytes; short successful returndata and scratch residue are outside the model, with no invented source guard. The tree consumer uses a total pair and does not prove gas sufficiency.
- `hs` remains a real input-selection premise. The actual BeaconState/validator-list layout, selected validator fields, pubkey padding and leaf generation are not derived by this consumer. Neither are EIP4788 root retrieval, complete wrapper failure ordering, fls assembly correspondence or deployed configuration identity.
- Canonical construction correctness and calculated-root agreement do not establish unique contents, collision resistance, or authenticity of all arbitrary accepted witnesses.

README states these limits explicitly. Appropriate site wording is: the typed verifier now calculates each ordered hash and matches an independent Merkle path, with depth derived from uint248; an admitted pinned-header consumer uses one tree/proof for the slot check and digest loop, under an explicit state-path selection link. The validator/container and root-lookup obligations remain open. Do not describe this increment as complete SSZ-1 closure.
