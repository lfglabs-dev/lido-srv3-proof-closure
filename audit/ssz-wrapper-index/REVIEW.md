# Independent review — SSZ wrapper index / slot consumer

Verdict: **CLEAN for this explicitly bounded increment** at exact candidate `b74ccaa9b3d2409acd19f463ae59ceb8cda2d7d8`, against base `ee5f7f63c958a80edcf6265072ef84613f4369e2`. This is not certification or closure of SSZ-1, the complete Solidity wrapper, or a deployed instance.

Reviewer: independent site_audit agent; source authored by topup_units and Solidity harness by root. Read-only project review; this report is the sole reviewer write. No rebuild, commit, push, merge or deployment performed. Concurrent untracked TopupLiveWithdrawal files excluded.

## Exact candidate and evidence

The diff adds exactly nine files: new Lean source and tests, six audit artifacts, and the Solidity harness. Existing registered guarantees, metadata, endian proof, dependency manifests and core gitlink are unchanged. The gitlink remains `17005714f151e5502c559932319a3f2f74ac2436`.

All 20 SHA256 entries in committed `audit/ssz-wrapper-index/receipt.json` were independently checked against candidate git blobs, or immutable core blobs at that gitlink. They all match. Source and tests match the final reviewed working files and the receipt; no change after the recorded build was found. The committed Solidity log is byte-identical to `/tmp/lido-ssz-wrapper-solidity-20260909.log`.

`check_source.py` was read and independently executed successfully. Its four full-file identity checks and 21 literal anchors support source review; they are explicitly not semantic equivalence proofs. Seven core files covered by the receipt also match the immutable pin. Relevant core CLValidatorVerifier, GIndex, SSZ, configuration and type definitions were examined, including BLS.sha256Pair call/return-data behavior.

The final retained Lean log reports the targeted source/test build complete, 787 jobs, including rebuilt unchanged endian dependency, with no warnings/errors. The four queried numeric/index results depend only on propext and Quot.sound; slot_sibling_of_header_branch and encoded_slot_accepts_header_branch also depend on Classical.choice. No native_decide, bv_decide, sorry or new axiom appears in the source/tests. The log is evidence of the author's build, not an independently rerun build.

The retained Forge log reports solc 0.8.25, eight tests passing, including five fuzz properties with 1024 runs each. The harness imports and inherits actual pinned CLValidatorVerifier and invokes actual GIndex concat/fls; independent expected values use division, arithmetic append, and explicit byte serialization. It does not execute full _verifyValidator. No finite test is a universal proof.

## Substantive review

- `Source/SszWrapperIndex.lean:40`: checked neighbor preserves Solidity guard order, remainder-plus-offset overflow, width rejection, later index addition and uint248 pack rejection. Input widths are actual decoded uint248/uint8 and uint256 offset widths.
- Lines 50–65 and 118: concat models fixed-width shifts plus XOR/OR. The separate append specification uses multiplication and leading-pivot subtraction. The proof establishes XOR removal and disjoint OR/add correspondence, then derives shift safety and uint248 fit from the source depth guard. These are not circular no-wrap or result-fit premises.
- Lines 192, 257 and 285: generic wrapper retains arbitrary previous/current constructor values and strict slot<pivot selection. Successful execution derives the offset bound. For the repository's equal bases 150*2^40, the iff theorem proves exact offset admission below 2^40 and non-vacuity; the full index is 1430*2^40+offset, depth 50, metadata power 40. The configuration file supplies equal previous/current bases and pivot zero; quantifying an arbitrary pivot for those equal bases is harmless. These are configuration-artifact facts, not deployed immutable identification.
- Lines 303 and 352: actual numeric final parent steps 11/5/2 are proved separately. The independent eight-field header tree places slot/proposer at sibling node 4 and canonical branch extraction yields the source's length-minus-two element. The premise is treeBranch construction, not an assumed sibling equality. This is useful structural correspondence, with the composition limit below.
- Lines 376 and 388: the consumer computes slot/proposer encodings from concrete uint64 values through sourceUint256, then compares the selected sibling to the pair. The reference header uses independent uint64 octet chunks. No externally supplied expected digest or root-match flag is substituted for computation; the total pair function is universally quantified.
- Tests distinguish omitted/incorrect header prefix, offset change, strict pivot with distinct synthetic layouts, zero/depth/pack/overflow boundaries, wrong sibling positions, changed proposer and raw big-endian chunks. The artificial testPair is clearly not represented as SHA256 or a general injectivity assumption. Solidity adds actual fls fuzzing and all 256 one-hot cases, actual slot hashing, range errors and short-proof Panic(0x11).

## Explicit limits that must remain visible

1. `fls` is Nat.log2 with zero sentinel 256. Universal equivalence to Solady's actual assembly remains unproved; actual execution tests are finite. Raw packed bytes32 decoding/packing is also a representation boundary.
2. The canonical tree proof and integer index steps are not yet formally composed through generalized-index bit decoding into the actual digest-carrying SSZ.verifyProof loop. A constructed branch is not a theorem authenticating every arbitrary accepted witness.
3. Slot arithmetic assumes successful total pair computation. BLS.sha256Pair may fail on call status or non-32-byte return data before index subtraction; those errors and complete wrapper error order remain outside this slice.
4. Validator field writes, withdrawal-credential provenance, pubkey padding and leaf composition, EIP-4788 call/ABI behavior, memory/compiler/EVM linkage, SHA properties, deployed identity and consensus authenticity remain unresolved.

These limits are accurately described in README lines 57–87. The minor provisional README axiom wording was corrected before this exact candidate: both tree and encoding theorems list Classical.choice. No remaining blocking finding or wording correction is required for this scoped increment. The next useful proof is the stated index-path/accumulator loop bridge; no parent guarantee status should be promoted solely from this review.
