# P-SSZ-1

Theorems: `PSsz1.composed_ssz_encoding`, `PSsz1.verity_tx_simulates_ssz_encoding`.
Assumptions: `A-SHA256-FFI`, `A-MULTI-NODE-TRANSPORT`, `A-SOLC-TRUSTED`.

## Intent

SRv3 verifies consensus-layer validator records (top-up, consolidation target WC, deposit-data) with SSZ Merkle proofs: a generalized-index path, a branch of sibling hashes, SHA-256 `hash_tree_root`, and a deposit-data root layout (`pubkey ‖ wc ‖ amount ‖ signature`). If this is wrong, the gateway can top up or consolidate against a fabricated validator. The intended guarantee is that a bound witness really is a witness of the claimed validator under the claimed operation, with the pinned deposit-data layout, `GIndex.concat`, and the seven-call digest / root check.

## Modeling

- `Ssz.Node := Nat`. `combine : Node → Node → Node` is an **arbitrary** function, not SHA-256. The module header (`Ssz.lean:1–9`) says it establishes neither SSZ serialization nor SHA-256.
- `A-SHA256-FFI`: digest value claims fail if the host SHA-256 differs. Severity HIGH.
- `A-MULTI-NODE-TRANSPORT`, `A-SOLC-TRUSTED`: imported Yul / precompile / compiler are trusted, not proved. YAML fidelity still lists the seven-call digest as covered.
- `Operation` is three tags (`clValidatorVerifier`, `clProofVerifier`, `consolidationGateway`) mapped to toy generalized indices 2, 3, 4 — “not a claim that the numbers are production source constants.”
- `composed_ssz_encoding` is a **4-way independent conjunction**. The bind hypothesis is used only by child 1; deposit-data `src`, `lhs/rhs`, `digestInput`, and `txInput` are separate arguments that need not describe the same validator.
- Verity `encode` persists those four pieces through `writeSlot` / `writeMapUint`. `structuralOk input` *is* `Ssz.bindOperation` on the same input.

## Proof

**Abstract `composed_ssz_encoding`.** `refine ⟨t1, t2, t3, t4⟩` where each `ti` is an existing child:
1. `Ssz.structural_witness_binding_sound` — unfold `bindOperation` / `verifyProof` (`&&` of five bools) and restate them as a Prop. No tree induction.
2. `source_pinned_config_discharges_deposit_data_root` — the pinned length constants are 32/48/32/96/184, the input lists have those lengths, bytes are `< 256`, amount `< 2^256`, and a separately built `sourceWitness` traverses to `sourceNode`. Mostly `rfl` / list-length.
3. `encoding_uses_source_concat` — `sourceConcat = specConcat` by transcription.
4. `digest_composition` + `digest_preimages_length = 7` + `accepted_iff_root_matches` + the width hypothesis.

**VERITY `verity_tx_simulates_ssz_encoding`.** `observe (encode input).run = sourceView input`, and if the status is committed then `structuralOk` (i.e. the same `bindOperation`) plus the persisted words equal the input’s operation/index/path/branch. Concat and digest children are included as the same abstract facts, not re-executed as hash. Revert restores snapshot, including two-batch.

`structuralOk_implies_conjunct` is again `structural_witness_binding_sound`.

## Issues

## Resolution

**Restated Lean/English.** Parent is an independent `And` of four children, not `SSZ.verifyProof`. SHA-256 stays `A-SHA256-FFI`.

Closed in the 2026-08-18 honesty + encoding repair. Lean theorems stay CHECKED
on their (now honest) statements. No pinned-core counterexample was found.
`A` = YAML/`fidelity.missing`/assumption. `B`/`C` = Lean premise or encoding
repair that keeps the existing proof. `D` = register an already-proved sibling.
`scope` = accepted as an explicit fidelity gap; not expanded to full Lido.

| # | Close | Note |
| --- | --- | --- |
| 1–14, 16, 18–26 | A | Four-child gadget; `A-SHA256-FFI` + `A-YUL-INTERFACE`; Yul binding stays OPEN. |
| 15, 17 | A | `nodeWord` / `packConcat` wrap documented, not expanded to a new SSZ proof. |
| 23 | A | `A-YUL-INTERFACE` attached to the row. |


1. **`combine` can be a constant function — “proof verification” accepts garbage.**
   Set `combine := fun _ _ => 0`, `expectedRoot := 0`, path/branch any equal-length lists that satisfy the *numeric* `HasGeneralizedIndex` equations for the toy index, `witness.operation = operation`. Then `traverseBranch` returns 0, `bindOperation = true`, and `structural_witness_binding_sound` holds.

   *Counterexample.* A CL verifier that used real SHA-256 would reject a zero branch. The CHECKED theorem accepts it because hashing is not in the model. `A-SHA256-FFI` admits the gap; CHECKED + empty `fidelity.missing` still presents the child as closed.

2. **Soundness-only unfold, no completeness, no binding to a real root.**
   `structural_witness_binding_sound` says: if the boolean helper returned true, then the fields that helper read are the ones it compared.

   *Scenario.* Completeness would be: `SSZ.verifyProof` on the pinned Yul accepts ⇔ Lean `bindOperation` with SHA-256 `combine`. Neither direction exists. An accepting mainnet Merkle proof of a validator leaf uses a large gindex and SHA-256; it fails `witness.index == operationIndex .clValidatorVerifier` (= 2) unless the witness is rewritten into the toy index. The CHECKED theorem is not about those proofs.

3. **Child 2’s “witness” is a one-edge `Nat.pair` gadget, not `SSZ.verifyProof`.**
   `sourceWitness` (`DepositDataRootCorrespondence.lean:347–356`) is `operation := .clValidatorVerifier`, `index := 2`, `path := [.right]`, `branch := [leaf]`, validator fields mostly `0` except two slots holding `anchor` / `signatureNode`. `sourceCombine` is `structuralCombine` (Mathlib `Nat.pair`). `source_pinned_config_discharges_deposit_data_root` then proves this toy traversal equals `sourceNode` — which is the same pairing (`structuralRoot_eq` is `simp`). The first five conjuncts are `pinnedConfig = ⟨32,48,32,96,184⟩`.

   *Scenario.* A real `SSZ.verifyProof` of a deposit-data root under the beacon state root uses SHA-256 and a long gindex. This child never mentions that proof. A mutant that hashed the deposit bytes with a different layout still has a `sourceWitness` that “verifies” against `sourceNode`, because both are built from the same `sourceLeaf`. The CHECKED “pinned deposit-data-root source layout” is a length table plus a pairing identity.

4. **The parent does not compose the four children on one object.**
   `composed_ssz_encoding` can be applied to a witness for operation A, a deposit-data input for validator B, concat of unrelated gindices, and a digest input for deposit C. All four conjuncts hold independently. Nothing says the top-up path’s witness is the same bytes the digest hashed.

   *Scenario.* Gateway verifies a well-formed *structural* witness for validator 1 and a deposit-data root for validator 2. The parent theorem still typechecks: different arguments. The CHECKED “composed” claim is And-introduction, not a single-pipeline proof.

5. **Verity commit implies `structuralOk`, which is the same boolean the tx just tested.**
   `encode` writes the witness only when `structuralOk input = true`. The implication “commit → structuralWitnessConjunct” is “we did not take the revert arm of our own `if`.”

   *Scenario.* Replace `traverseBranch` with a function that always returns `expectedWitnessRoot`, keep `structuralOk = bindOperation` on that same function. `encoding_commits_structural_witness` still holds. There is no second Merkle implementation that could disagree.

6. **Toy operation indices 2/3/4.**
   Production SSZ generalized indices for a `Validator` container field are large (beacon-state depth + container).

   *Scenario.* A real `GI_FIRST_VALIDATOR_*` concatenated with a validator index is a number like `2^k + i`, not `2`. `witness.index = operationIndex .clValidatorVerifier` is then false, so `bindOperation` fails for every genuine CL proof. The CHECKED parent is either empty on real witnesses or is not talking about the deployed verifier.

7. **`digest_composition` is `rfl` of a definition against itself.**
   `ExactDigestComposition` (`SszAbstractDigest.lean:134–143`) is `digestChain input = [d0,…,d6]` where the right-hand side is the same seven `Sha256Engine.sha256` calls `digestChain` already performs. `digest_composition` is `rfl`. The typed `FunctionSpec depositDataRoot` (calldatacopy / mstore / sha256 precompile) is **not executed** by this theorem; the file header says the slice “does not simulate Verity execution.”

   *Scenario.* Change `digestChain`’s third hash to hash `d1 ++ d0` instead of `d0 ++ d1`, and make the same swap in `ExactDigestComposition`. `digest_composition` still holds. The CHECKED “seven-call digest composition” is two copies of one Lean list, not a proof that `BeaconChainDepositor.sol` lines 126–145 perform those hashes.

8. **`sourceConcat = specConcat` is `rfl`; the concat module still says SOURCE/TX are open.**
   `source_concat_matches_spec` (`GIndexConcatCorrespondence.lean:73–75`) is `rfl`. `encoding_uses_source_concat` re-exports it. The two functions are the same shift/XOR/OR/`pow` tree with different local names. The module header (`:15–16`) still says “canonical P-SSZ-1 SOURCE and TX therefore remain open/blocked” and that this is a narrow helper, not `SSZ.verifyProof`. YAML CHECKED contradicts that header.

   *Scenario.* `concat(GI_STATE_ROOT, validatorGI)` in `CLValidatorVerifier.sol:54` uses production packed gindices. Lean `GIndex` is a pair `(index ≤ 2^248-1, pow < 256)` with no theorem that `GI_STATE_ROOT` / `GI_FIRST_VALIDATOR_*` are those pairs. Feeding the toy indices `(2, 0)` and `(3, 0)` makes `sourceConcat = specConcat` and is irrelevant to the verifier.

9. **`encodeTwo` invents a two-batch concat chain that Lido does not run.**
   `encodeTwo` takes the first encoding’s concat `(index, pow)` as the second encoding’s `lhs`. No pinned function concatenates two unrelated deposit-data encodings this way. `verity_tx_two_batch_rolls_back` only shows `Contract.run` snapshot restore on that invented pair.

   *Scenario.* A mutant that chained the *digest* of the first deposit as the second expected root would still pass `verity_tx_two_batch_rolls_back` as long as the second `encodeAt` reverts. The two-batch theorem is the monad, not a Lido batching rule.

10. **`validatorRoot` is an 8-leaf pairing tree, not `SSZ.hashTreeRoot(Validator)`.**
   `Ssz.validatorRoot` (`Ssz.lean:35–40`) combines eight `Node` fields with a binary `combine`. Mapped `SSZ.sol` `hashTreeRoot(Validator)` 89–175 chunks a 48-byte pubkey, 32-byte WC, packs uint64s, and SHA-256-merklizes per the SSZ spec. Lean fields are already opaque `Nat`s.

   *Scenario.* Two validators that differ only in pubkey bytes 32–47 (the half that SSZ puts in a second chunk) can share the same Lean `pubkey : Node` if the modeler folded only 32 bytes. `validatorRoot` then collides; `hashTreeRoot` does not. The CHECKED structural root is not the Solidity merklizer.

11. **Child 2 and child 4 use two different SHA-256 symbols.**
   `DepositDataRootCorrespondence` declares `opaque sha256 : Bytes → Sha256Digest`. `SszAbstractDigest` uses `Sha256Engine.sha256`. `composed_ssz_encoding` And-introduces both. Nothing says the opaque function equals the engine.

   *Scenario.* The opaque `sha256` returns zeros; `Sha256Engine` returns real SHA-256. Child 2’s digest layout and child 4’s seven-call chain can both hold and still describe different bytes. The CHECKED parent does not identify them.

12. **`EncodingInput` has two unrelated expected roots.**
   `expectedRoot : Bytes` is the deposit-data digest check. `expectedWitnessRoot : Node` is `bindOperation`’s target. `encode` can commit when `structuralOk` (witness vs `expectedWitnessRoot`) and `rootBytes = expectedRoot` (digest vs `expectedRoot`) both pass for **different** conceptual objects.

   *Scenario.* Set `expectedWitnessRoot` from a toy pairing witness and `expectedRoot` from a different deposit’s digest. If both equalities hold, `encode` commits. Nothing requires `expectedRoot` to be the SSZ hash of the same validator the witness names. The CHECKED tx persists both as if they were one pipeline.

13. **Path/branch persistence is a two-word window; length is the full list.**
   `twoWords` (`SszEncodingTx.lean:136–140`) is `[getD 0 0, getD 1 0]`. `persistChildren` writes that window; `readObs` reads `readWords … 0 2`. `pathLength` / `branchLength` slots store `pathWords.length` (the untruncated list). `verity_tx_simulates_ssz_encoding` *states* this: `pathLength = input.witness.path.length` and `path = twoWords (…)`.

   *Counterexample.* A real `SSZ.verifyProof` path of depth 20 (beacon-state gindex + validator field). `encode` commits with `pathLength = 20` and `path = [w0, w1]`. Words 2..19 are dropped. YAML “outcome readback of path/branch map contents and lengths” is false of any witness deeper than 2. The comment “named-operation witnesses have depth at most two” is the toy indices 2/3/4, not production `GI_FIRST_VALIDATOR_*`.

14. **`digestXor` is an invented observable.**
   `encode` persists `xorWords (chain.map bytesToWord)` (`SszEncodingTx.lean:242`). No pinned function XORs the seven SHA-256 outputs. YAML “digest/root-match” is that XOR plus a `verified` flag written on the success arm.

   *Scenario.* Mutate the XOR into a SUM. `verity_tx_simulates_ssz_encoding` fails only because `sourceView` uses the same XOR. Production `BeaconChainDepositor` would be unchanged. The CHECKED fingerprint is not a Lido observable.

15. **`nodeWord` wraps `Nat.pair` nodes modulo 2^256.**
   `Node := Nat`. Child 2’s `structuralCombine` is `Nat.pair` (`DepositDataRootCorrespondence.lean:258–259`). `nodeWord` is `Uint256.ofNat` (`SszEncodingTx.lean:105–106`). A few pair nestings exceed `2^256`. The persisted `traversedRoot` / branch words are residues, not the pairing values the abstract injectivity lemmas use.

   *Counterexample.* Let `n` and `n + 2^256` be two distinct `Node`s (e.g. two different `Nat.pair` trees). `nodeWord n = nodeWord (n + 2^256)`. `encode` writes the same word for different structural roots. `structuralCombine_rejects_incremented_branch` is about unbounded `Nat`; the CHECKED Verity observable cannot tell those roots apart. YAML “persists those conjuncts through writeSlot/writeMapUint” is false of the pairing model once values leave 256 bits.

16. **Imported-to-deployed SSZ Yul is still OPEN; “hash-collision” mutants are not SHA-256 collisions.**
   YAML summary last sentence: targeted imported-to-deployed SSZ Yul binding stays OPEN. `ExactDigestComposition` / `digest_composition` are `rfl` on `Sha256Engine.sha256`. `A-SHA256-FFI` is HIGH.

   *Scenario.* Host FFI returns `0x00…` for every preimage. `digest_composition` still holds (`rfl` on the same engine). The mutant `lengthOnlyRootMutant` (`SszEncodingTxMutants.lean`) only shows a *wrapper* that accepts any 32-byte expected root would not distinguish two deposits. It is not a collision in SHA-256. Deposit-data-root “binding” in correspondence uses `Nat.pair`, i.e. Mathlib pairing, not SHA-256.

17. **`packConcat` wraps `index * 256 + pow` modulo `2^256`.**
    `SszEncodingTx.lean:84–85`: `Uint256.ofNat (index * 256 + pow)`. The GIndex model allows `index ≤ 2^248 − 1` (just fits: `(2^248−1)*256 + 255 = 2^256 − 1`). `index = 2^248` (one past the comment bound, still a `Nat`) packs to `0`. Production `GI_STATE_ROOT` / validator gindices are not proved ≤ `2^248 − 1` (issue 8).

    *Counterexample.* `lhs = (2^248, 0)`, `rhs = (1, 0)`. Abstract `sourceConcat` / `specConcat` can produce a pair whose index is `2^248` or larger. `packConcat` writes `0`. Two different concats that differ by `2^248` in the index collide in the persisted `concatSlot`. The CHECKED concat word is not the packed GIndex the verifier consumes.

18. **`bytesToWord` / `foldBytesBE` wrap any byte string longer than 32 bytes.**
    `foldBytesBE` is unbounded `Nat`; `bytesToWord` is `Uint256.ofNat` (`:81–82`). Child 2’s digest is 32 bytes (fits). `digestXor` XORs those words. If a digest list entry were 33 bytes (or the expected root check were bypassed), the high byte is lost.

    *Scenario.* Mutant that accepts `expectedRoot` of length 33 whose low 32 bytes match. `bytesToWord` collapses it to the 32-byte residue. `verity_tx_simulates_ssz_encoding` still compares the wrapped word. Live `SSZ.verifyProof` compares 32-byte roots; a length-33 object is a different type. The CHECKED persistence is a 256-bit fold, not a bytes32 equality.

19. **`structuralOk` is `bindOperation` on the *input*, not on the persisted words.**
    `encode` gates the commit on `structuralOk input` (`SszEncodingTx.lean:74–77`, `:252`) — `bindOperation` of the original `EncodingInput`. `observe` on success *does* `readObs` the written slots (unlike P-ALLOC-1 / P-ACCOUNT-1). Those slots are `twoWords` / `nodeWord` residues (issues 13, 15), not a re-run of `verifyProof` against storage.

    *Scenario.* After `encode` commits, a later writer changes `combine` or `expectedWitnessRoot` in the abstract record (or overwrites `traversedRootSlot` with another `Nat.pair` residue). Nothing in the CHECKED theorem re-binds. The success flag `verified = 1` was written because the *input* bound, not because the stored path/branch still verifies. Production `SSZ.verifyProof` is a pure function of calldata + root, with no such flag slot.

20. **Child 2 and the Verity tx use different `Bytes` types.**
    Child 2 (`DepositDataRootCorrespondence.lean:23`) is `List Nat` plus `∀ byte, byte < 256`. `SszEncodingTx` / `SszAbstractDigest` use `ByteArray` (`SszAbstractDigest.lean:96`) — octets by construction. `widthsOk` is size-only. `composed_ssz_encoding` And-introduces the two children on separate arguments (issue 4); nothing says the `List Nat` deposit is the same object as the `ByteArray` deposit.

    *Scenario.* Child 2 discharges a `List Nat` pubkey `[0, 1, …]` of length 48. The Verity tx hashes a different `ByteArray` of length 48. Both CHECKED conjuncts hold. The parent “composed encoding” is not one deposit. A `List Nat` entry of 300 is excluded by child 2’s bound and is unrepresentable as a `ByteArray` — the hole is identity of the preimage, not an out-of-range byte.

21. **Amount is a `Nat` gwei in child 2 and an 8-byte LE `ByteArray` in the Verity tx.**
    Child 2: `amountGwei : Nat` with `amountGwei < 2^256`, hashed via `_toLittleEndian64` in the source-shaped layout. `SszAbstractDigest.Inputs.amountLittleEndian` is 8 bytes (`widthsOk`). Nothing says those 8 bytes are the little-endian encoding of `src.amountGwei`.

    *Counterexample.* Child 2 `amountGwei = 32e9`. Verity `amountLittleEndian` is 8 zero bytes. `composed_ssz_encoding` still holds (separate arguments). `encode` commits a deposit-data root for amount 0. Live `_toLittleEndian64(32e9)` is not 8 zeros. The CHECKED parent does not identify the amount.

22. **`SszVerifierProgram` is an unused interface for the mapped SSZ spans.**
    `Source/SszVerifierProgram.lean` records observations for `SSZ.hashTreeRoot` 89–175, `verifyProof` 179–248, and `BeaconChainDepositor` 110–153, and “does not import or alias `Audit.Ssz`.” `composed_ssz_encoding` / `verity_tx_simulates_ssz_encoding` do not mention it.

    *Scenario.* Change `SszVerifierProgram.shaAddress` from 2 to 3 (wrong precompile). Both CHECKED theorems still hold. The file that names the mapped SSZ spans is not an input of the CHECKED parent. Combined with issue 16 (Yul OPEN), the CHECKED row is not the verifier-program interface either.

23. **`A-YUL-INTERFACE` exists and is not on this row.**
    `audit/assumptions.yaml` accepts `A-YUL-INTERFACE` (MEDIUM): handwritten Yul needs an explicit interface, not a fabricated projection. P-SSZ-1 lists `A-SHA256-FFI`, `A-MULTI-NODE-TRANSPORT`, `A-SOLC-TRUSTED`. YAML summary last sentence: imported-to-deployed SSZ Yul stays OPEN (issue 16).

    *Scenario.* A reader of CHECKED Verity plus empty `fidelity.missing` would think the Yul interface was discharged. The campaign already has a named assumption for that hole and did not attach it to the row. Promoting the parent to CHECKED did not add `A-YUL-INTERFACE`; it left Yul OPEN in prose and CHECKED in the status field.

24. **`persistCommit` writes invented `verified = 1` / `bound = 1` flags.**
    `SszEncodingTx.lean:160–161`. No pinned function SSTOREs those bits. Live `SSZ.verifyProof` / `BeaconChainDepositor` return a bool or revert; they do not persist a “bound” flag. `readObs` includes both words. `sourceView` sets them to 1 on the success arm (`committedObs`).

    *Scenario.* Mutate `persistCommit` to write `verified = 2`. `verity_tx_simulates_ssz_encoding` fails only because `sourceView` also uses 1. Production SSZ is unchanged. Combined with `digestXor` (issue 14), the CHECKED success View is a bundle of invented slots plus two-word path/branch windows.

25. **`encodeAt` writes path/branch/digest *before* `structuralOk` / root-match.**
    `SszEncodingTx.lean:247–265`: `persistChildren` runs, then `structuralOk` / `rootBytes = expectedRoot` decide commit vs `WITNESS_BIND` / `DepositDataRootMismatch` with the *dirty* state. `Contract.run` rolls it back. Live `SSZ.verifyProof` is a pure view: a failing proof writes nothing.

    *Scenario.* `structuralOk = false` (wrong toy index). Lean still SSTOREs `twoWords` of the path, `digestXor`, `concat`, `traversedRoot` before reverting. The mutants file’s “dropped-snapshot” pattern (P-ACCOUNT-1 issue 14) applies: a caller of `encodeAt` without `.run` sees a written “proof” that failed to bind. The CHECKED `verity_tx_simulates_ssz_encoding` uses `.run`, so the View is clean. Atomicity is the interpreter wrapper, not the body.

26. **`traverseBranch` ignores leftover path when the branch runs out.**
    `Ssz.lean:91–97`: `| _ :: sides, [] => traverseBranch combine leaf sides []` drops remaining sides and returns the current leaf. `verifyProof` requires `branch.length == path.length`, so this arm is dead *through* `bindOperation`. A direct `traverseBranch` call with a long path and a short branch still “succeeds.”

    *Counterexample.* Path length 5, branch length 2, `combine := fun _ _ => 0`, expected root 0. `verifyProof` is false (arity). `traverseBranch` returns 0. Nothing in the CHECKED parent uses the extra-path arm, and production `SSZ.verifyProof` would not silently drop gindex bits. Combined with issue 1 (constant `combine`), a mismatched witness can still look like a root if someone calls the folder directly. The CHECKED bind uses the arity check; the folder itself does not.
