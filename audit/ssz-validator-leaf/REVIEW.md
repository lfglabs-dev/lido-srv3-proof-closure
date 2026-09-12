# Independent exact-candidate review — SSZ validator leaf

Candidate: `c82b0d81d6574cac7d862b42ac705a282a5b0925`.
Direct parent: `9f1bc6dce3a76e31c31a398d72ea67ebfecfd965`.
Core Solidity pin: `17005714f151e5502c559932319a3f2f74ac2436`.

**CLEAN for the declared typed validator-leaf and successful header-consumer increment. No blocking source, proof, evidence or scope finding. This is not acceptance of full SSZ-1 or whole-wrapper/EVM correspondence.**

The reviewer did not author the source, tests, harness or dossier. Read the complete 247-line new Lean module, 89-line test module, 122-line Solidity harness, complete dossier, and the full delivered fold/wrapper/endian proof dependencies. Compared the actual pinned CLValidatorVerifier leaf and wrapper, BLS calldata pubkey and pair helpers, ValidatorWitness struct and SSZ conversion with their interpretations. No Lean/Forge build was rerun.

## Source and independent specification

| Location | Independent review |
|---|---|
| `Source/SszValidatorLeaf.lean:45-64` | `digestBytes` represents a bytes32/mstore word high byte first. Clearing scratch bytes 32–63, then copying exactly the 48 admitted pubkey bytes, leaves bytes 48–63 zero. The padding theorem is universal over arbitrary initial lower scratch and length-48 pubkeys; it preserves all 48 bytes. This is an explicit typed memory interpretation, not a raw calldata-copy proof. |
| `Source/SszValidatorLeaf.lean:68-82` | `checkedSha` requires **both** successful staticcall and returndata size exactly 32, and consumes the returned output word. The length guard precedes this call. This matches BLS.sol:525-532 and 538-556. It correctly differs from the existing SSZ.verifyProof fold, whose Solidity source has no returndata-size guard. Failed or malformed-size calls cannot supply a successful digest here. |
| `Source/SszValidatorLeaf.lean:85-109` | `sourceSlashed` follows the actual integer overload `slashed ? uint64(1) : 0`, widened to uint256, rather than substituting the separate Boolean source overload. All five uint64 fields use the delivered exact little-endian conversion. The selected eight leaves and seven ordered pair calls match CLValidatorVerifier.sol:65-85. Credentials come from the separate expected-credentials argument, not an invented witness field. |
| `Source/SszValidatorLeaf.lean:112-124,164-192` | The reference tree is independently constructed from semantic witness fields and credentials. Its pubkey digest is calculated from raw 48-byte input plus 16 zero bytes; its integer and Boolean chunks use independent serialization specifications. `source_leaf_eq_tree` derives equality for every abstract SHA function and every typed witness under `standardSha`; invalid lengths are rejected. No encoded-fields equality, supplied pubkey digest, computed-leaf equality or desired final root is assumed. The small finite `source_merkle_pure` proof is legitimately definitional control-flow composition; endian and padding correspondence remain separate, nontrivial inputs. |
| `Source/SszValidatorLeaf.lean:195-245` | `subtreeAt` selects a tree structurally without hashes. `subtree_digest` derives the digest relation needed by the older fold consumer. `validator_header_consumer` obtains its leaf from `sourceLeaf` and feeds it to the same extracted 50-sibling header proof used by the slot/proposer check. The final root is computed from that same tree. `hplace` specifies actual structural placement of the independently calculated validator tree; `hi` still supplies the state-path/index relationship. Neither is a hidden final-root-match flag or supplied leaf-digest equation. |

The new module proves 12 theorems. The successful adapter's total SHA interpretation is visible in the signatures and documentation: general precompile success is not derived from gas or EVM semantics. The arbitrary-precompile length theorem and checked-SHA equivalence remain meaningful without that total adapter.

## Regression and execution evidence

The 26 Lean regressions inspect dirty scratch, the nonzero pubkey tail and 16 zero bytes; invalid lengths 0/47/49/256 and length-before-call-failure priority; unsuccessful SHA and returndata sizes 0/31/32/33; ordered pair serialization; actual slashed integer encoding and little-endian epoch bytes; semantic positions; and distinct results for credentials, slashed and swapped epochs under a deliberately noncommutative finite test hash. These are useful concrete mutation/boundary witnesses. The finite hash is explicitly not SHA-256 and its differing outputs are not a cryptographic uniqueness proof.

The Solidity harness inherits the **actual** pinned CLValidatorVerifier and exposes `_validatorHashTreeRoot`, plus the actual BLS calldata `pubkeyRoot`. Its reference uses independent byte serialization and generic balanced level reduction. Six tests execute the real helpers with solc 0.8.25; three fuzz properties run 1,024 inputs each. The supplied log records six passes, no failures or skips. Deterministic cases cover uint64 endpoints, both Boolean values, credentials, epoch order, pubkey byte 47, missing/dirty padding and independence from `proofValidator`. Altering the input fields is a discrimination regression, not exhaustive mutation testing of every source operation. The dossier does not overstate it. This suite does not force precompile failure/short returndata or execute the complete validator wrapper.

The committed Lean validation log is explicitly a **targeted cache replay** after successful source/test compilation: 789 jobs, six principal axiom outputs. Padding and checked-SHA equivalence use `propext` and `Quot.sound`; the other four inspected theorems additionally use `Classical.choice`. No native-checker axiom appears. The new sources introduce no `sorry`, custom axiom, `native_decide` or `bv_decide`. No full repository build is claimed. The reviewer inspected and reused these exact receipts; this is not a second independent compilation.

## Exact identity checks

The candidate directly extends the stated parent and changes exactly nine files: the new Lean source/tests, Solidity harness and six audit files. No TOPUP or other concurrent untracked files enter the candidate. `git diff --check` passes.

Independently recomputed **all 21 SHA-256 entries** from candidate Git blobs or core submodule Git objects at the recorded pin. All match `audit/ssz-validator-leaf/receipt.json`. The seven declared unchanged dependency/configuration files are byte-identical to the parent. Every checked candidate blob also matches the source/dossier actually read in the checkout. The committed Solidity log is byte-identical to the integrator's `/tmp/lido-ssz-leaf-solidity-20260909.log`.

Principal source identities:

- `LidoSRv3/Audit/Source/SszValidatorLeaf.lean`: `a2b5fa2b0f8b5955e0d4d27a5052e0d19bb08058b5e734dd48d55cc121d3170f`.
- `LidoSRv3/Tests/SszValidatorLeafMutants.lean`: `868f0ab7c7f82e3c76e909e1cef2645a8557d2ac9142dc8bd6aa071ae24bd539`.
- `solidity/test/SszValidatorLeaf.t.sol`: `9398ff5e80b4cb4f8dd6ba75023082075793fec8aa7140d34fbd82f2617df9a3`.

Independently reran the lightweight source checker: four complete pinned source-file identities and 29 textual anchors pass. Its stated role is identity/transcription support only; it is not semantic equivalence or compiler verification.

## Boundaries that remain required and honestly stated

The consumer is a sufficient-condition construction for one structurally placed validator tree and its canonical proof. It does not prove that arbitrary accepted proofs uniquely identify validator contents. State-list layout/length/placement, the `150 * 2^40 + offset` selection link, fork/deployed configuration, trusted root provenance and cryptographic collision resistance remain open.

The typed octet lists and ShaReply are not raw EVM calldata/memory semantics. Offset arithmetic, aliasing/copying, extraction of returndata into scratch memory, gas/resource sufficiency, changing failure schedules and compiler/runtime identity remain outside the proof. The successful SHA adapter is explicit rather than an established precompile-refinement result.

The new theorem composes successful leaf, slot and digest checks. It does not execute `_verifyValidator` in its actual order (slot SHA/check, EIP-4788 call and decode, index selection, leaf, proof loop), nor prove its competing-failure priority. The dossier names these gaps and proposes a bounded next consumer. They must remain visible in any site summary; this result must not be described as full validator authentication or closure of SSZ-1.

Read-only project review; only this temporary report was written. No source edits, builds, commits, pushes, merges or deployments were performed by the reviewer.

VERDICT: CLEAN
