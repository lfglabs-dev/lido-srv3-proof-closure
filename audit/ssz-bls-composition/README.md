# Actual BLS leaf and SSZ verifier composition

This increment closes a missing connection in SSZ-1: the pubkey copied from
the same raw calldata is hashed by the actual EvmYul SHA primitive; its result
feeds seven actual BLS pair calls; their final digest and resulting state feed
the already integrated raw-calldata proof verifier. The independent typed
validator tree supplies the specification, not a digest-equality premise.
SSZ-1 and the other seven unfinished guarantees remain OPEN.

The pinned source is `lidofinance/core@17005714f151e5502c559932319a3f2f74ac2436`.
`BLS.sol:516–561` supplies the pubkey preparation, pair preparation and exact
success/returndata-size guards. `CLValidatorVerifier.sol:60–85` supplies field
order, expected credentials, uint64 encodings and the seven ordered pairs.
Its lines 55–57 pass the computed leaf into `SSZ.verifyProof`, whose calldata
loop is `SSZ.sol:179–254`. This increment models that leaf/verifier suffix.

## Proof and consumer

`SszBlsComposition.lean` contains 16 theorems:

- `prepared_memory`, `prepared_words`, `prepared_read` derive the actual two
  ordered mstores, preserved memory tail and scratch extent.
- `finish_failed_flag`, `finish_wrong_size`, `pubkey_wrong_length` retain
  the BLS error guards. `finish` reads the actual returned machine memory.
- `pair_success`, `pair_budget` and `pubkey_success` establish actual primitive
  execution, computed digest, unchanged execution environment and derived
  remaining gas/memory. Each subsequent call's admission follows from the
  previous result; no per-call success or returned digest is assumed.
- `merkle_success` threads one state through the seven literal source pairs.
  `pair_digest_typed`, `merkle_digest_typed`, `bytes_typed` and
  `pubkey_digest_typed` connect the executed words/bytes with the independent
  tree, using the accepted typed/FFI bridge from #282.
- `leaf_success` derives the validator leaf from the raw pubkey and typed
  fields. `verify_leaf_success` proves success equivalence with independent
  typed branch verification by invoking the accepted actual calldata loop
  on that leaf's digest AND state. `verifyLeaf` is the concrete consumer.

The proof derives intermediate depth, calldata identity, memory extent and
CALL budgets. A sufficient initial CALL-only budget is `2684*(8+n)+1`, where
`n` is proof length: eight BLS calls plus the verifier calls. The strict `+1`
comes from the interpreter's CALL admission. It is not transaction gas or a
bound for surrounding compiled instructions. For `n=50` it is 155673.

## Transitive assumptions and remaining work

These obligations are not closed by moving them into a boundary:

| Kind | Remaining condition | Verification performed and its scope |
|---|---|---|
| Internal, OPEN | Raw ABI decoding must derive key length/offset, typed uint64/Bool fields, proof layout and count. The initial key extent and calldata size bound are supplied. | Kernel tests select an asymmetric raw 48-byte key at offset 3, reject offset 4, check its last byte and zero padding. Actual Solidity fuzz executes ABI-decoded fields. Neither establishes a universal decoder theorem. |
| Internal, OPEN | Entry initialization/reachability must derive initial memory `<2^251`, depth `<1024` and sufficient resources, with surrounding opcode gas included. | Actual primitive proofs derive every subsequent bound. Invalid-depth regressions execute the actual CALL rejection. Source-level fixtures do not prove compiled initialization or gas. |
| Internal, OPEN | Slot/proposer check, actual EIP-4788 root call and generalized-index construction must feed this suffix in the full entry; their earlier typed results are not yet raw-state composition. | The full pinned wrapper was read, including call order. The new harness deliberately exposes only its leaf/verifier suffix. Earlier entry receipts remain separate evidence. |
| Internal, OPEN | Source-to-compiled execution, full account/storage/balance frame, observable logs, revert encoding and rollback must justify the useful consumer promise. | One actual interpreter state is threaded; exact BLS guards and the verifier's distinct failure path are tested on pinned Solidity. This does not prove a full EVM World frame or rollback. |
| External/model trust | `shaOutput` is the actual opaque FFI, with 32-byte output assumed for the key block and all pair inputs. Cryptographic SHA correctness/collision resistance is not proved. | Standard SHA tests run real precompile 2. Separate synthetic 31/33-byte and failed-call injections check BLS guards; they are not cryptographic validation or a universal fault model. |
| External provenance | Authentic root, deployed runtime/configuration and consensus assumptions remain necessary for the delivered promise. | Git-pinned source identities are checked against compiler metadata; this is source identity, not deployed-runtime or consensus authentication. |

## Validation

Fresh direct Lean source and test checks use the existing imported caches,
with source/config hashes before and after, and separate temporary outputs.
The earlier targeted 1133-job build is retained for context; it is not a full
dependency rebuild. There are 31 kernel regression examples and nine axiom
queries. The transitive query results contain only `propext`,
`Classical.choice`, `Quot.sound`; no `sorry`, added axiom, `native_decide` or
`bv_decide` occurs in the new Lean files.

Five new Forge tests use solc 0.8.25, optimizer 200, via IR, Cancun. The harness
inherits the unmodified pinned validator leaf and calls the unmodified
calldata SSZ verifier with its result. A 1024-run fuzz test compares a generic
independent tree reduction and branch fold with real SHA, varying every
validator field, key, credentials, path, depth 1–12 and metadata. It checks
root and last-sibling mutants. Finite tests check field/credential mutations,
key-length priority, each of eight distinct BLS call inputs with short/long
reply and failure injections, and the final verifier's separate empty revert.
The empty-proof control returns `InvalidProof`, as the source specifies.

The initial test mistakenly expected `BranchHasMissingItem` for an empty
proof. A targeted execution trace identified the actual `InvalidProof` guard;
only the test expectation was corrected. All 24 BLS fault injections had
already passed before that control failed. Diagnostic failures are retained
separately and are not counted as successful validation.

`check_receipt.py` replays file/package-pin/compiler-source identities only.
The complete source and exact candidate still require independent review
before integration. Compilation and this receipt do not close SSZ-1.
