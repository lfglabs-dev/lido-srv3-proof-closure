# P-SSZ-1

> GPT-5.6 Pro round 1 (ChatGPT UI, 2026-08-20). Voice of the auditor. No em dashes. P-ETH-1 and P-TOPUP-1 notes are missing from this round (ChatGPT UI auth on those slots). P-ALLOC-1 was already written by the owner and is not restated here.

## Auditor note

P-SSZ-1 proves one precise property: the composed SSZ encoding traversal under sourceCombine returns exactly sourceNode. The parent guarantee was stripped to this single conjunct, so it makes no broader Merkle or cryptographic claim.

On the Verity plane, encode.run is observed to equal sourceView for every modeled input. If execution commits, the modeled structural fields also match the source specification.

## Proof issues and recommendations

The abstract theorem is intentionally narrow. It does not prove SHA-256 correctness, production generalized indices, or imported-to-deployed Yul. Pin the SHA-256 engine and prove its use end to end, or keep SHA correctness documented as an assumption.


Theorems: `PSsz1.composed_ssz_encoding` (registered parent; concludes the named predicate `PSsz1.composedEncodingOk`, stripped in wave 6 to the single mutant-exercised traversal conjunct), `PSsz1.swapped_combine_kill_line_refutes_parent` (parent kill-line: negates the `sourceCombineSwapped` model-mutant-substituted parent at a concrete witness where every premise and `hBind` hold), `PSsz1.composedEncodingOkFull_not_trivial_crossed_witness` (conclusion-non-triviality witness on the unregistered full bundle `PSsz1.composedEncodingOkFull`: the bundle discriminates the claimed operation; renamed in wave 6 from `crossed_witness_kill_line_refutes_parent`), `PSsz1.composed_ssz_encoding_full` (unregistered demoted bundle, not registered claim content), `PSsz1.verity_tx_simulates_ssz_encoding`.
Assumptions: `A-SHA256-FFI`, `A-MULTI-NODE-TRANSPORT`, `A-SOLC-TRUSTED`, `A-YUL-INTERFACE`.

## Wave 6 changes (2026-08-19)

**The wave-4 strip was incomplete; the registered conclusion is now the
mutant-exercised core only.** Wave-6 review found that the wave-4 strip
(PR #140) left five conjuncts registered that are definitional facts or
restated premises, while this report and the YAML row claimed every
registered conjunct was "non-definitional" — false. The registered
predicate `composedEncodingOk` (via `composedEncodingOkWithCombine`) is now
stripped to the single substantive conjunct: the derived witness's
traversal to `sourceNode input.src` under the source-combine family
(`Ssz.traverseBranch (srcCombine input.src) … = sourceNode input.src`),
the one conjunct the `sourceCombineSwapped` model mutant breaks. The
registered parent's statement shape — binders, the five width/size
premises, and `hBind` — is unchanged; its proof projects the registered
conjunct out of the full bundle, so every premise remains consumed.

**Demotions (still proved, still available, explicitly unregistered).**
The stripped conjuncts remain as independent lemmas and are re-bundled on
the same one-object input as the unregistered `composedEncodingOkFull`
(proved by `composed_ssz_encoding_full`), which consumers may use but which
is not registered claim content:

1. the structural witness binding — `Ssz.structural_witness_binding_sound`
   is the Bool→Prop unpacking of the parent's own `hBind` premise (a
   restated hypothesis);
2. `sourceConcat input.lhs input.rhs = specConcat input.lhs input.rhs` —
   `rfl` (`source_concat_matches_spec`, re-exported as
   `encoding_uses_source_concat`);
3. `(digestPreimages …).length = 7` — a list-literal length
   (`digest_preimages_length`, by `simp [digestPreimages]`);
4. the `runVerification` accept-iff — `runVerification` IS the
   root-match `if`, so the iff is `simp [runVerification]`
   (`accepted_iff_root_matches`);
5. `exactTxWidths input.txInput` — assembled from the parent's own width
   premises (`srcInputs_exactWidths`), the amount width being definitional
   (`toLittleEndian64`'s fixed `List.range 8`).

**Kill-line repair.** `swapped_combine_kill_line_refutes_parent` is
unchanged in statement — it already negated the mutant-substituted parent
in the registered parent's exact quantifier/premise/`hBind` shape — and its
proof simplifies: after the strip the mutant-substituted conclusion IS the
traversal conjunct, so the refutation uses it directly (no `obtain`
projection), still closing via `traverseBranch_sourceCombineSwapped_eq` and
the nonzero public-key anchor (`swapped_traverse_ne_structuralEncoding`) at
the hypothesis-satisfying witness `swappedCombineKillInput`.

**Rename.** `crossed_witness_kill_line_refutes_parent` is renamed to
`composedEncodingOkFull_not_trivial_crossed_witness` and retargeted at the
unregistered full bundle: after the strip the registered predicate mentions
neither `operation` nor `combine` (the honest traversal is
hypothesis-free), so no statement of the form `¬ composedEncodingOk …` is
provable and the crossed-operation discrimination lives only in the
bundle's first structural conjunct. The theorem remains honestly labeled as
NOT a parent kill-line (`hBind` fails at the crossed point, so the parent
implication is vacuously true there). References in
`LidoSRv3/Audit/Trust.lean` (`#print axioms`), the YAML row, and this
report are updated.

**Metadata honesty.** The YAML `summary`, `fidelity.covered`, and
`reproduction.expected` now describe the stripped registered conclusion and
name the demoted unregistered children; `A-YUL-INTERFACE` is added to this
report's Assumptions header (it was already on the YAML row and in
STATUS.md — issue #23's body, which says "not on this row", is superseded;
its resolution-table row already records the attachment). The wave-4
sections below that describe the six-conjunct predicate as the registered
conclusion, and any claim that its conjuncts are "all non-definitional",
are superseded in that respect.

## Wave 4 changes (2026-08-19)

**Definitional conjuncts stripped from the registered conclusion.** The
wave-2 `composed_ssz_encoding` conclusion registered several conjuncts that
were `rfl` accessor equalities of `ComposedSszInput`'s own derived fields, or
restated hypotheses: `input.rhs.index = (sourceWitness input.src).index.value`
(`rhs` is *defined* as that value), `input.digestInput = srcInputs input.src`
and `input.txInput.toInputs = srcInputs input.src` (the fields are *defined*
as `srcInputs input.src`), `ExactDigestComposition input.digestInput`
(`digestChain` is *defined* as that seven-call list, so `digest_composition`
is `rfl`), `signatureRoot input.src = computeSignatureRoot input.src.signature`
(`signatureRoot` is *defined* as that call), the five pinned-config constant
equalities, the three `src` field bound projections, and the three length
lines that restated `hPublicKey`/`hWithdrawalCredentials`/`hSignature` via
`simpa`. The conclusion is now the named predicate `composedEncodingOk`,
whose conjuncts are all non-definitional: the `hBind`-transported structural
binding soundness; the derived witness's traversal to `sourceNode input.src`
under `sourceCombine input.src` (an equality between the generic
`Ssz.traverseBranch` fold and the independently written pairing encoding);
`sourceConcat input.lhs input.rhs = specConcat input.lhs input.rhs` (two
independently written artifacts); the seven-preimage count; the
`runVerification` accept-iff; and `exactTxWidths input.txInput`. The
derived-field definitions stay — they are the type-level one-object coupling
— but their `rfl` equalities are no longer registered as claim conjuncts.
The wave-2 notes below that describe those equalities as proved conclusion
conjuncts are superseded in that respect. (Wave 6 amendment: the claim here
that the six wave-4 conjuncts are "all non-definitional" was false — the
`hBind` unpacking restates a premise, the concat equality is `rfl`, the
preimage count is a list-literal length, the accept-iff unfolds
`runVerification`'s definition, and the widths reassemble the premises.
Wave 6 strips the registered predicate to the traversal conjunct only and
demotes the other five to the unregistered `composedEncodingOkFull`; see
the Wave 6 section above.)

**The parent kill-line is a model mutant with `hBind` satisfied.** The
wave-2 kill-lines did not refute the registered parent's conclusion:
`inconsistent_witness_kill_line` negates the parent's *hypothesis* `hBind` on
a crossed two-source pair that cannot even inhabit `ComposedSszInput`, and
`inconsistent_operation_index_kill_line` is a bare `Nat` constant inequality.
The first wave-4 attempt, `crossed_witness_kill_line_refutes_parent`, proves
`¬ composedEncodingOk .clProofVerifier (sourceCombine input.src) input` — but
at that crossed operation `hBind` itself fails (the witness is bound to
`.clValidatorVerifier` by construction), so the parent's implication is
vacuously true there. It is kept, honestly labeled, as a
conclusion-non-triviality witness: the conclusion predicate is not constantly
true and discriminates the claimed operation. The parent kill-line is
`swapped_combine_kill_line_refutes_parent`: the conclusion predicate is
parameterized as `composedEncodingOkWithCombine` over the source-combine
family used in its deposit-data-root traversal conjunct (the honest
`composedEncodingOk` is the specialization at `sourceCombine`), and the
theorem negates the mutant-substituted parent stated in the registered
parent's own quantifier/premise/`hBind` shape. At the concrete witness
`swappedCombineKillInput` every premise holds and `hBind` is discharged by
the same `sourceWitness_binds_sourceNode` used for the honest artifact —
`hBind` never mentions `sourceCombine` — yet the swapped-combine traversal
conjunct reduces definitionally (`traverseBranch_sourceCombineSwapped_eq`)
to a `Nat.pair` tree equality that would force
`sourceAnchor swappedCombineKillSrc = 0`, contradicting the concrete nonzero
public-key fold (`swapped_traverse_ne_structuralEncoding`). A crossed
witness/root pair *inside* `ComposedSszInput` remains uninhabitable — witness
and root are both derived from the single `src`, which is the type-level
coupling doing its job — so the model-function axis is the residual mutant
shape that keeps the hypothesis satisfied. (Wave 6 amendment:
`crossed_witness_kill_line_refutes_parent` is renamed
`composedEncodingOkFull_not_trivial_crossed_witness` and retargeted at the
unregistered full bundle `composedEncodingOkFull` — after the wave-6 strip
the registered predicate no longer mentions the operation, so
`¬ composedEncodingOk .clProofVerifier …` is no longer provable. The
kill-line's statement is unchanged; its proof simplifies because the
mutant-substituted conclusion is now exactly the traversal conjunct. See
the Wave 6 section above.)

**Verity plane coupling disclosure.** The executable `EncodingInput` plane
keeps `deposit`, `rhs`, `witness`, and `expectedWitnessRoot` independent
(e.g. `Tests/SszEncodingTxMutants.matching` pairs a witness at index 2 with
`rhs := gindex 3 11`), so it does not inherit the abstract one-object
coupling; this is now listed in `fidelity.missing` rather than implied by the
covered list.

## Wave 2 changes (2026-08-19)

**Full four-child composition, not two of four.** Issue #4 below documented
that `composed_ssz_encoding` And-introduced four independently typed
arguments: a witness/root pair (children 1–2), a `GIndex.concat` pair
(child 3), and a digest/tx input pair (child 4). Nothing tied the concat
operand or the digest bytes to the same deposit the witness/root pair named,
so the parent still typechecked for a witness for validator 1, a `GIndex`
for an unrelated operation, and digest bytes for validator 3.

This wave closes that gap by deriving the remaining two children from the
same `src` field, instead of taking them as independent record fields:

- `ComposedSszInput.rhs : GIndex` is now `⟨(sourceWitness input.src).index.value,
  input.rhsPow, …⟩` — the concat operand's *index* component is exactly the
  generalized index `sourceWitness input.src` binds (`sourceWitness_index_le_maxUint248`
  proves it always fits the 248-bit bound). Only `rhsPow` (the concat
  model's separate `uint8` power metadata, not deposit content) stays an
  independent field.
- `srcInputs : SourceDepositDataRootInput → Inputs` converts the pinned
  `List Nat` pubkey/WC/signature bytes to the `ByteArray` shape the digest
  child consumes (`toByteArray`, an exact octet cast since every byte is
  already `< 256`), and computes the amount bytes via the *same*
  `toLittleEndian64` the deposit-data-root layout already uses
  (`DepositDataRootCorrespondence.lean:128,144`). `ComposedSszInput.digestInput`
  and `.txInput` are now `srcInputs input.src` plus the tx child's two
  chain-level fields (`forkVersion`, `expectedDepositDataRoot`), instead of
  independently supplied `Inputs`/`TxInputs` records.

This closes issue #4's full four-child counterexample (not just the
witness/root pair it was previously restricted to) and, as a consequence,
issues #20 and #21 (the `List Nat`/`ByteArray` type mismatch and the
unconstrained amount encoding between children), since `digestInput` and
`txInput.toInputs` are now *defined as* `srcInputs input.src` rather
than left as separate arguments that could describe a different deposit.
(Wave 4 amendment: the equality is a definitional accessor fact — the
coupling is the type-level derivation itself, and it is no longer registered
as a proved conclusion conjunct.)

**New kill-line.** `inconsistent_operation_index_kill_line` shows the
`.clProofVerifier` operation slot's index can never equal the
`.clValidatorVerifier` slot `sourceWitness` always binds, so a `GIndex.concat`
operand minted for a different named operation could not have come from the
derivation `ComposedSszInput.rhs` performs. `inconsistent_witness_kill_line`
(unchanged) remains the witness/root rejection. Both are stated directly
against the registered parent's shared vocabulary (`sourceWitness`,
`Ssz.operationIndex`). (Wave 4 amendment: these two negate only the parent's
*hypothesis* `hBind` and a constant index pair respectively — neither negates
the parent's *conclusion*. The parent kill-line is now
`swapped_combine_kill_line_refutes_parent`, a `sourceCombine` model mutant
refuted at a witness where `hBind` holds;
`crossed_witness_kill_line_refutes_parent` is a conclusion-non-triviality
witness only; see the Wave 4 section above.)

**Non-vacuity.** `sourceWitness_binds_sourceNode` proves the tightened
`hBind` hypothesis is genuinely satisfiable — any pinned-width `src` binds
its own derived witness against its own derived root. `Tests/SszRegression.composedExample`
instantiates a concrete pinned-width `ComposedSszInput` and
`composedExample_satisfies_composed_ssz_encoding` discharges every
hypothesis of `composed_ssz_encoding` against it, so the fully coupled
parent is invokable, not accidentally emptied by the new equalities.

`lhs` (the state-root anchor position), `rhsPow` (the concat power byte),
and the tx child's `forkVersion`/`expectedDepositDataRoot` remain
independent fields: they are chain-level values, not deposit content, so
there is no `src`-derived value to tie them to.

## Intent

SRv3 verifies consensus-layer validator records (top-up, consolidation target WC, deposit-data) with SSZ Merkle proofs: a generalized-index path, a branch of sibling hashes, SHA-256 `hash_tree_root`, and a deposit-data root layout (`pubkey ‖ wc ‖ amount ‖ signature`). If this is wrong, the gateway can top up or consolidate against a fabricated validator. The intended guarantee is that a bound witness really is a witness of the claimed validator under the claimed operation, with the pinned deposit-data layout, `GIndex.concat`, and the seven-call digest / root check.

## Modeling

- `Ssz.Node := Nat`. `combine : Node → Node → Node` is an **arbitrary** function, not SHA-256. The module header (`Ssz.lean:1–9`) says it establishes neither SSZ serialization nor SHA-256.
- `A-SHA256-FFI`: digest value claims fail if the host SHA-256 differs. Severity HIGH.
- `A-MULTI-NODE-TRANSPORT`, `A-SOLC-TRUSTED`: imported Yul / precompile / compiler are trusted, not proved. YAML fidelity still lists the seven-call digest as covered.
- `Operation` is three tags (`clValidatorVerifier`, `clProofVerifier`, `consolidationGateway`) mapped to toy generalized indices 2, 3, 4 — “not a claim that the numbers are production source constants.”
- `composed_ssz_encoding` takes one `ComposedSszInput` record and concludes the named predicate `composedEncodingOk operation combine input`. The structural-bind hypothesis and the deposit-data-root child both name `sourceWitness input.src` / `sourceNode input.src` directly — they are proved about the **same** `src`, not independently typed arguments. `GIndex.concat`'s validator-side operand (`ComposedSszInput.rhs`) and the seven-call digest / root-match child's byte input (`ComposedSszInput.digestInput`/`.txInput`) are *derived* from `input.src` (via `sourceWitness input.src`'s index and `srcInputs input.src` respectively), so all four children read off the same object; since Wave 4 those derivations are the type-level coupling only, not registered conclusion conjuncts, and since Wave 6 the registered predicate is stripped to the single mutant-exercised traversal conjunct (the other wave-4 conjuncts demoted to the unregistered `composedEncodingOkFull`). Only `input.lhs` (the state-root anchor position), `input.rhsPow` (the concat model's separate power byte), and `input.forkVersion`/`input.expectedDepositDataRoot` (chain-level, not deposit content) remain independently supplied.
- Verity `encode` persists those four pieces through `writeSlot` / `writeMapUint`. `structuralOk input` *is* `Ssz.bindOperation` on the same input. The outcome observable's digest field (`Observables.digest`) is now read back from `digestMapSlot` storage via `readObs`, not the pre-write local `chain` list.

## Proof

**Abstract `composed_ssz_encoding`.** Since wave 6, proves `composedEncodingOk operation combine input` — the named conclusion predicate stripped to the single mutant-exercised conjunct — by projecting it out of the unregistered full bundle: `(composed_ssz_encoding_full input … hBind).2.1` over one `input : ComposedSszInput` (with `input.rhs`, `input.digestInput`, `input.txInput` themselves defined as functions of `input.src`). The registered conjunct (wave-4 conjunct 2) is the residue of `source_pinned_config_discharges_deposit_data_root input.src`: the same `sourceWitness input.src` traverses to `sourceNode input.src` under `sourceCombine input.src`. (The discharge's pinned-constant equalities, `src` bound projections, `rfl` signature-root unfolding, and hypothesis-restating length lines are *not* registered as conjuncts.) The unregistered bundle `composed_ssz_encoding_full` additionally proves, on the same premises, the demoted wave-4 conjuncts:

- Conjunct 1: `Ssz.structural_witness_binding_sound hBind` — unfold `bindOperation` / `verifyProof` (`&&` of five bools) and restate them as a Prop, applied to `sourceWitness input.src` / `sourceNode input.src`. No tree induction. (Wave 6: demoted — this restates the `hBind` premise.)
- Conjunct 3: `encoding_uses_source_concat input.lhs input.rhs` — `sourceConcat = specConcat` by transcription, on the operand `sourceWitness input.src` binds. (Wave 6: demoted — `rfl`.)
- Conjunct 4: `digest_preimages_length input.txInput.toInputs` — the digest preimage count is seven. (Wave 6: demoted — list-literal length.)
- Conjunct 5: `accepted_iff_root_matches input.txInput` — `runVerification` accepts iff the computed root equals the expected root. (Wave 6: demoted — `simp [runVerification]`.)
- Conjunct 6: `exactTxWidths input.txInput` via `srcInputs_exactWidths` — the derived transaction input has the pinned widths. (Wave 6: demoted — reassembled from the premises.)

(The wave-4 version of this paragraph described all six as the registered,
"non-definitional" conjuncts proved by `refine ⟨t1, …, t6⟩`; that claim was
incorrect about conjuncts 1 and 3–6 and is superseded by the Wave 6
section.)

**Kill-line.** `swapped_combine_kill_line_refutes_parent` negates the mutant-substituted parent `∀ {operation combine} input, premises → hBind → composedEncodingOkWithCombine sourceCombineSwapped operation combine input`: the conclusion predicate is parameterized over the source-combine family (`composedEncodingOk` is the honest specialization at `sourceCombine`), and `sourceCombine` is the one model function inside the predicate that `hBind` never mentions. At the concrete witness `swappedCombineKillInput` every premise holds (`by decide`) and `hBind` is discharged by the same `sourceWitness_binds_sourceNode` used for the honest artifact, but the swapped-combine traversal conjunct reduces definitionally (`traverseBranch_sourceCombineSwapped_eq`) to a `Nat.pair` tree equality forcing `sourceAnchor swappedCombineKillSrc = 0` — impossible by `Nat.pair` injectivity since the concrete public-key fold is nonzero (`swapped_traverse_ne_structuralEncoding`). Because the mutant parent is refuted at a hypothesis-satisfying witness, this refutes the parent shape itself, not a vacuous point of it. (Wave 6: after the strip, the mutant-substituted conclusion is exactly the traversal conjunct, so the proof uses it directly instead of projecting it out of the six-conjunct bundle.) Separately, `composedEncodingOkFull_not_trivial_crossed_witness input` (renamed in wave 6 from `crossed_witness_kill_line_refutes_parent`) proves `¬ composedEncodingOkFull .clProofVerifier (sourceCombine input.src) input` — a conclusion-non-triviality witness (the unregistered full bundle discriminates the claimed operation via its first structural conjunct), NOT a parent kill-line: at the crossed operation `hBind` fails, so the parent implication is vacuously true there. The stripped registered predicate `composedEncodingOk` mentions neither `operation` nor `combine`, so no negation of it is provable and the discrimination is witnessed on the bundle. `inconsistent_witness_kill_line` (binding `sourceWitness srcA` against `sourceNode srcB` for a *different* deposit, `sourceAnchor srcA ≠ sourceAnchor srcB`, fails `bindOperation`: a negation of the parent's *hypothesis* on a pair that cannot inhabit `ComposedSszInput`) and `inconsistent_operation_index_kill_line` (`Ssz.operationIndex .clProofVerifier`'s value never equals `(sourceWitness src).index.value`: a bare constant inequality) remain as `bindOperation`-level negative results for the cross-child mismatches the one-object `ComposedSszInput.src` rules out by construction — `composed_ssz_encoding`'s hypotheses can only be discharged when the structural witness, the pinned deposit-data-root, the concat operand, and the digest bytes all name the same object. `sourceWitness_binds_sourceNode` (used by `Tests/SszRegression.composedExample_satisfies_composed_ssz_encoding`) shows those hypotheses remain jointly satisfiable.

**VERITY `verity_tx_simulates_ssz_encoding`.** `observe (encode input).run = sourceView input`, and if the status is committed then `structuralOk` (i.e. the same `bindOperation`) plus the persisted words equal the input’s operation/index/path/branch. Concat and digest children are included as the same abstract facts, not re-executed as hash. Revert restores snapshot, including two-batch.

`structuralOk_implies_conjunct` is again `structural_witness_binding_sound`.

## Issues

## Resolution

**Restated Lean/English.** Parent composes all four children — structural-bind, deposit-data-root, `GIndex.concat`'s operand, and the seven-call digest / root-match bytes — on one shared `ComposedSszInput.src`, not an independent `And` of four unrelated arguments, and concludes the named predicate `composedEncodingOk`, stripped in wave 6 to the single mutant-exercised traversal conjunct (no `rfl` derived-accessor equalities, no restated hypotheses, no definitional facts as registered conjuncts; the demoted wave-4 conjuncts remain proved as the unregistered `composedEncodingOkFull`). The parent kill-line `swapped_combine_kill_line_refutes_parent` negates the `sourceCombineSwapped` model-mutant-substituted parent at a concrete witness where every premise and `hBind` hold; `composedEncodingOkFull_not_trivial_crossed_witness` (renamed from `crossed_witness_kill_line_refutes_parent`) separately witnesses that the unregistered full bundle is not constantly true (it discriminates the claimed operation). Only the state-root anchor (`lhs`), the concat power byte (`rhsPow`), and the tx child's chain-level fork version / claimed root remain independent, non-deposit fields. SHA-256 stays `A-SHA256-FFI`.

Closed in the 2026-08-18 honesty + encoding repair; issue 4's witness/root
pairing fixed plus a digest storage reread added in the 2026-08-19 one-object
composition repair; and issue 4 fully closed to all four children (plus
issues 20/21) with two new kill-lines and a non-vacuity witness in the
Wave 2 (2026-08-19) four-child composition repair. Wave 4 (2026-08-19)
stripped the definitional (`rfl` derived-accessor / self-referential digest
composition / hypothesis-restating) conjuncts from the registered conclusion
into the named predicate `composedEncodingOk` and added the parent kill-line
`swapped_combine_kill_line_refutes_parent` (a `sourceCombine` model mutant
inside the predicate — a function `hBind` never mentions — negated at a
concrete witness where every premise and `hBind` hold), keeping
`crossed_witness_kill_line_refutes_parent` as an honestly labeled
conclusion-non-triviality witness; the
Verity `EncodingInput` plane's independence of `deposit`/`rhs`/`witness`/
`expectedWitnessRoot` is now an explicit `fidelity.missing` entry. Wave 6
(2026-08-19) completed the strip: the registered predicate
`composedEncodingOk` is now only the mutant-exercised traversal conjunct;
the premise-restating / definitional wave-4 conjuncts are demoted to the
unregistered `composedEncodingOkFull` (`composed_ssz_encoding_full`); the
kill-line statement is unchanged with a simplified proof; and
`crossed_witness_kill_line_refutes_parent` is renamed
`composedEncodingOkFull_not_trivial_crossed_witness`, retargeted at the
unregistered bundle. Lean
theorems stay CHECKED on their (now honest) statements. No pinned-core
counterexample was found.
`A` = YAML/`fidelity.missing`/assumption.
`B`/`C` = Lean premise or encoding repair that keeps the existing proof. `D` = register
an already-proved sibling. `scope` = accepted as an explicit fidelity gap; not expanded
to full Lido.

| # | Close | Note |
| --- | --- | --- |
| 1–3, 5–14, 16, 18, 19, 22–26 | A | SHA-256/witness abstraction, toy indices, invented observables; `A-SHA256-FFI` + `A-YUL-INTERFACE`; Yul binding stays OPEN. |
| 4 | B | `ComposedSszInput` bundles `src` once; the structural-bind hypothesis, the deposit-data-root child, `GIndex.concat`'s operand (`ComposedSszInput.rhs`), and the digest/tx child's bytes (`ComposedSszInput.digestInput`/`.txInput`, via `srcInputs`) all name or are derived from `sourceWitness input.src` / `sourceNode input.src`, closing the "witness for validator 1, root for validator 2" counterexample across all four children, not just the witness/root pair. `inconsistent_witness_kill_line` and `inconsistent_operation_index_kill_line` prove the two `bindOperation`-level rejection shapes; `Tests/SszEncodingTxMutants.lean`'s `crossedWitness` is the executable analogue of the first. Wave 4: the registered conclusion is now the named non-definitional predicate `composedEncodingOk`; the parent kill-line `swapped_combine_kill_line_refutes_parent` negates the `sourceCombineSwapped` model-mutant-substituted parent at a concrete witness where every premise and `hBind` hold, and `crossed_witness_kill_line_refutes_parent` is a conclusion-non-triviality witness (the predicate discriminates the claimed operation). Only `lhs` (state-root anchor), `rhsPow` (concat power byte), and the tx child's fork version / claimed root remain independent, non-deposit fields (tracked in `fidelity.missing`). `sourceWitness_binds_sourceNode` / `Tests/SszRegression.composedExample` show the tightened parent is non-vacuous. Wave 6: the registered conclusion is stripped to the single mutant-exercised traversal conjunct; the other wave-4 conjuncts are demoted to the unregistered `composedEncodingOkFull`, and the non-triviality witness is renamed `composedEncodingOkFull_not_trivial_crossed_witness`. |
| 15, 17 | A | `nodeWord` / `packConcat` wrap documented, not expanded to a new SSZ proof. |
| 20, 21 | B | `srcInputs` converts `src`'s pinned `List Nat` pubkey/WC/signature to `ByteArray` via `toByteArray` (an exact octet cast, since every byte is `< 256`) and computes the amount bytes via the source's own `toLittleEndian64`. `ComposedSszInput.digestInput` and `ComposedSszInput.txInput.toInputs` are *defined* as `srcInputs input.src`, so the digest/tx child's bytes are identical to, and correctly derived from, the same `src` the deposit-data-root child discharges — closing both the cross-type identity gap (20) and the unconstrained-amount gap (21) for the composed parent. (Wave 4: the defining equalities are `rfl` accessor facts, so they are no longer registered as conclusion conjuncts; the coupling holds at the type level.) |
| 23 | A | `A-YUL-INTERFACE` attached to the row. |

Issue 19's outcome-readback gap is narrowed, not closed, by the same repair:
`Observables.digest` is now reread from `digestMapSlot` storage (`readObs`)
instead of the pre-write local `chain` list. `structuralOk`'s commit decision
still reads the *input* witness, not the persisted words, and the `path` /
`branch` / `operation` residues (issues 13, 15) are unchanged.


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

   *Closed (Wave 2).* `ComposedSszInput.rhs`/`digestInput`/`txInput` are now *functions* of `input.src`, not independent record fields, so the scenario above no longer typechecks: there is exactly one `input.src` in scope, and the concat operand and digest bytes are computed from it, not separately supplied. `inconsistent_witness_kill_line` / `inconsistent_operation_index_kill_line` prove the two mismatch shapes are rejected at the `bindOperation` level, and `Tests/SszRegression.composedExample_satisfies_composed_ssz_encoding` shows the tightened parent is still invokable on a genuine pinned-width deposit. Remaining independent fields (`lhs`, `rhsPow`, `forkVersion`, `expectedDepositDataRoot`) are chain-level values with no deposit-derived counterpart to tie them to, not an unclosed instance of this issue.

   *Wave 4 amendment.* The registered conclusion no longer carries the `rfl` derived-accessor equalities as conjuncts; it is the named predicate `composedEncodingOk`. The parent kill-line is `swapped_combine_kill_line_refutes_parent` (a `sourceCombine` model mutant inside the predicate, negated at a witness where `hBind` holds); `crossed_witness_kill_line_refutes_parent` only witnesses conclusion non-triviality, and the two wave-2 kill-lines negate only the parent's hypothesis / a constant index pair, not its conclusion.

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

    *Closed (Wave 2).* `srcInputs : SourceDepositDataRootInput → Inputs` (`PSsz1.lean`) converts `src`'s `List Nat` pubkey/WC/signature to `ByteArray` via `toByteArray := ByteArray.mk ∘ List.toArray ∘ List.map UInt8.ofNat`, an exact octet cast because every element is already `< 256` (`toByteArray_size` proves the length is preserved). `ComposedSszInput.digestInput := srcInputs input.src` and `ComposedSszInput.txInput.toInputs := srcInputs input.src` by definition, so the parent identifies the digest child's preimage with child 2's own bytes, not a separately supplied `ByteArray`. (Wave 4: those defining equalities are `rfl` accessor facts and are no longer registered as conclusion conjuncts; the identification holds at the type level.)

21. **Amount is a `Nat` gwei in child 2 and an 8-byte LE `ByteArray` in the Verity tx.**
    Child 2: `amountGwei : Nat` with `amountGwei < 2^256`, hashed via `_toLittleEndian64` in the source-shaped layout. `SszAbstractDigest.Inputs.amountLittleEndian` is 8 bytes (`widthsOk`). Nothing says those 8 bytes are the little-endian encoding of `src.amountGwei`.

    *Counterexample.* Child 2 `amountGwei = 32e9`. Verity `amountLittleEndian` is 8 zero bytes. `composed_ssz_encoding` still holds (separate arguments). `encode` commits a deposit-data root for amount 0. Live `_toLittleEndian64(32e9)` is not 8 zeros. The CHECKED parent does not identify the amount.

    *Closed (Wave 2).* `srcInputs src` sets `amountLittleEndian := toByteArray (toLittleEndian64 src.amountGwei)` — the *same* `toLittleEndian64` function (`DepositDataRootCorrespondence.lean:128`) child 2's own `sourceNode`/`signatureRoot` layout already applies to `src.amountGwei` (`:144`), just cast to `ByteArray`. Since `input.digestInput` is *defined* as `srcInputs input.src`, the counterexample's "8 zero bytes for amount 32e9" cannot inhabit `ComposedSszInput`: the derived `amountLittleEndian` is by construction the little-endian encoding of the same `input.src.amountGwei` child 2 hashes, not an independently chosen witness. (Wave 4: stated as the type-level derivation, not as a registered `rfl` conjunct.)

22. **`SszVerifierProgram` is an unused interface for the mapped SSZ spans.**
    `Source/SszVerifierProgram.lean` records observations for `SSZ.hashTreeRoot` 89–175, `verifyProof` 179–248, and `BeaconChainDepositor` 110–153, and “does not import or alias `Audit.Ssz`.” `composed_ssz_encoding` / `verity_tx_simulates_ssz_encoding` do not mention it.

    *Scenario.* Change `SszVerifierProgram.shaAddress` from 2 to 3 (wrong precompile). Both CHECKED theorems still hold. The file that names the mapped SSZ spans is not an input of the CHECKED parent. Combined with issue 16 (Yul OPEN), the CHECKED row is not the verifier-program interface either.

23. **`A-YUL-INTERFACE` exists and is not on this row.**
    `audit/assumptions.yaml` accepts `A-YUL-INTERFACE` (MEDIUM): handwritten Yul needs an explicit interface, not a fabricated projection. P-SSZ-1 lists `A-SHA256-FFI`, `A-MULTI-NODE-TRANSPORT`, `A-SOLC-TRUSTED`. YAML summary last sentence: imported-to-deployed SSZ Yul stays OPEN (issue 16).

    *Scenario.* A reader of CHECKED Verity plus empty `fidelity.missing` would think the Yul interface was discharged. The campaign already has a named assumption for that hole and did not attach it to the row. Promoting the parent to CHECKED did not add `A-YUL-INTERFACE`; it left Yul OPEN in prose and CHECKED in the status field.

    *Superseded (Wave 6).* The body's "not on this row" predates the fix the resolution table already records: `A-YUL-INTERFACE` is attached to the YAML row's `assumptions` (and therefore to STATUS.md), and as of wave 6 it is also on this report's Assumptions header — the header omission was the remaining body-vs-table mismatch, now repaired.

24. **`persistCommit` writes invented `verified = 1` / `bound = 1` flags.**
    `SszEncodingTx.lean:160–161`. No pinned function SSTOREs those bits. Live `SSZ.verifyProof` / `BeaconChainDepositor` return a bool or revert; they do not persist a “bound” flag. `readObs` includes both words. `sourceView` sets them to 1 on the success arm (`committedObs`).

    *Scenario.* Mutate `persistCommit` to write `verified = 2`. `verity_tx_simulates_ssz_encoding` fails only because `sourceView` also uses 1. Production SSZ is unchanged. Combined with `digestXor` (issue 14), the CHECKED success View is a bundle of invented slots plus two-word path/branch windows.

25. **`encodeAt` writes path/branch/digest *before* `structuralOk` / root-match.**
    `SszEncodingTx.lean:247–265`: `persistChildren` runs, then `structuralOk` / `rootBytes = expectedRoot` decide commit vs `WITNESS_BIND` / `DepositDataRootMismatch` with the *dirty* state. `Contract.run` rolls it back. Live `SSZ.verifyProof` is a pure view: a failing proof writes nothing.

    *Scenario.* `structuralOk = false` (wrong toy index). Lean still SSTOREs `twoWords` of the path, `digestXor`, `concat`, `traversedRoot` before reverting. The mutants file’s “dropped-snapshot” pattern (P-ACCOUNT-1 issue 14) applies: a caller of `encodeAt` without `.run` sees a written “proof” that failed to bind. The CHECKED `verity_tx_simulates_ssz_encoding` uses `.run`, so the View is clean. Atomicity is the interpreter wrapper, not the body.

26. **`traverseBranch` ignores leftover path when the branch runs out.**
    `Ssz.lean:91–97`: `| _ :: sides, [] => traverseBranch combine leaf sides []` drops remaining sides and returns the current leaf. `verifyProof` requires `branch.length == path.length`, so this arm is dead *through* `bindOperation`. A direct `traverseBranch` call with a long path and a short branch still “succeeds.”

    *Counterexample.* Path length 5, branch length 2, `combine := fun _ _ => 0`, expected root 0. `verifyProof` is false (arity). `traverseBranch` returns 0. Nothing in the CHECKED parent uses the extra-path arm, and production `SSZ.verifyProof` would not silently drop gindex bits. Combined with issue 1 (constant `combine`), a mismatched witness can still look like a root if someone calls the folder directly. The CHECKED bind uses the arity check; the folder itself does not.
