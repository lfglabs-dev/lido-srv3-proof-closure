import LidoSRv3.Audit.Ssz
import LidoSRv3.Audit.Source.DepositDataRootCorrespondence
import LidoSRv3.Audit.Source.GIndexConcatCorrespondence
import LidoSRv3.Audit.Verity.SszAbstractDigest
import LidoSRv3.Audit.Verity.SszTxSimulation
import LidoSRv3.Audit.Verity.SszEncodingTx
import LidoSRv3.Audit.Guarantees.Registry

namespace LidoSRv3.Audit.Guarantees.PSsz1

open LidoSRv3.Audit
open LidoSRv3.Audit.Source.DepositDataRootCorrespondence
open LidoSRv3.Audit.Source.GIndexConcatCorrespondence
open LidoSRv3.Audit.Verity.SszAbstractDigest
open LidoSRv3.Audit.Verity.SszTxSimulation
open LidoSRv3.Audit.Verity.SszEncodingTx

def guarantee : Guarantee := ⟨.pSsz1, [.model, .source, .verityTx]⟩

/-! ### One-object closure for the digest / concat children

`srcInputs` and `ComposedSszInput.rhs` below let the `GIndex.concat` and
seven-call digest / root-match children read their bytes and generalized
index off the *same* `input.src` the structural-bind and deposit-data-root
children already share, instead of taking an independently supplied `Inputs`
or `GIndex`. -/

/-- Convert a pinned-source byte list into the `ByteArray` shape the digest
and transaction-simulation children consume. Every element is already `< 256`
(`SourceDepositDataRootInput`'s bounded fields), so `UInt8.ofNat` is an exact
octet cast, not a truncation. -/
def toByteArray (bytes : List Nat) : ByteArray :=
  ByteArray.mk (List.toArray (bytes.map UInt8.ofNat))

theorem toByteArray_size (bytes : List Nat) :
    (toByteArray bytes).size = bytes.length := by
  simp [toByteArray, ByteArray.size]

/-- The one-object digest input: the exact pinned public key, withdrawal
credentials, and signature bytes the deposit-data-root child discharges for
`src`, and the exact little-endian amount encoding the source's
`_toLittleEndian64` loop (`toLittleEndian64`) produces from `src.amountGwei`.
Not an independently supplied `Inputs` record for a different deposit
(closes report issues #20/#21). -/
def srcInputs (src : SourceDepositDataRootInput) : Inputs :=
  { publicKey := toByteArray src.publicKey
    withdrawalCredentials := toByteArray src.withdrawalCredentials
    signature := toByteArray src.signature
    amountLittleEndian := toByteArray (toLittleEndian64 src.amountGwei) }

theorem srcInputs_exactWidths (src : SourceDepositDataRootInput)
    (hPublicKey : src.publicKey.length = PUBKEY_LENGTH pinnedConfig)
    (hWithdrawalCredentials : src.withdrawalCredentials.length =
      WITHDRAWAL_CREDENTIALS_LENGTH pinnedConfig)
    (hSignature : src.signature.length = SIGNATURE_LENGTH pinnedConfig) :
    exactWidths (srcInputs src) := by
  refine ⟨?_, ?_, ?_, ?_⟩
  · simpa [srcInputs, toByteArray_size, PUBKEY_LENGTH, pinnedConfig] using hPublicKey
  · simpa [srcInputs, toByteArray_size, WITHDRAWAL_CREDENTIALS_LENGTH, pinnedConfig]
      using hWithdrawalCredentials
  · simpa [srcInputs, toByteArray_size, SIGNATURE_LENGTH, pinnedConfig] using hSignature
  · simp [srcInputs, toByteArray_size, toLittleEndian64]

/-- `sourceWitness src`'s generalized index is the fixed
`Ssz.operationIndex .clValidatorVerifier` slot regardless of `src`'s content,
so it always fits the `GIndex.concat` model's 248-bit bound. -/
theorem sourceWitness_index_le_maxUint248 (src : SourceDepositDataRootInput) :
    (sourceWitness src).index.value ≤ maxUint248 := by
  show (Ssz.operationIndex .clValidatorVerifier).value ≤ maxUint248
  decide

/-- One-object composition input. The four P-SSZ-1 children are gathered on a
single record: `src` is the one deposit whose derived witness
(`sourceWitness src`) and root (`sourceNode src`) the structural-bind
hypothesis below must name, and which also *derives* the `GIndex.concat`
child's validator-side operand (`rhs`) and the seven-call digest / root-match
child's byte input (`digestInput`/`txInput`). `lhs` (the state-root anchor
position) and `rhsPow`/`forkVersion`/`expectedDepositDataRoot` (chain-level
values, not deposit content) remain independently supplied. -/
structure ComposedSszInput where
  src : SourceDepositDataRootInput
  lhs : GIndex
  rhsPow : Nat
  rhsPowFits : rhsPow < 2 ^ 8
  forkVersion : ByteArray
  expectedDepositDataRoot : ByteArray

/-- The `GIndex.concat` child's validator-side operand: exactly the
generalized index `sourceWitness input.src` binds, not an independently
supplied index for an unrelated operation or validator. -/
def ComposedSszInput.rhs (input : ComposedSszInput) : GIndex :=
  ⟨(sourceWitness input.src).index.value, input.rhsPow,
    sourceWitness_index_le_maxUint248 input.src, input.rhsPowFits⟩

/-- The digest child's byte input: exactly `srcInputs input.src`, not an
independently supplied `Inputs` for a different deposit. -/
def ComposedSszInput.digestInput (input : ComposedSszInput) : Inputs :=
  srcInputs input.src

/-- The root-match child's transaction input: the same `srcInputs input.src`
bytes, plus the two chain-level values that are not deposit content. -/
def ComposedSszInput.txInput (input : ComposedSszInput) : TxInputs :=
  { toInputs := srcInputs input.src
    forkVersion := input.forkVersion
    expectedDepositDataRoot := input.expectedDepositDataRoot }

/-- Model mutant of the source-combine family used inside
`composedEncodingOkWithCombine`'s deposit-data-root traversal conjunct:
children swapped at every pairing. The registered parent's `hBind`
hypothesis mentions only `operation`, `combine`, `sourceWitness input.src`,
and `sourceNode input.src` — never `sourceCombine` — so substituting this
mutant into the conclusion predicate leaves the hypothesis satisfiable.
That is the axis `swapped_combine_kill_line_refutes_parent` refutes. -/
def sourceCombineSwapped (_input : SourceDepositDataRootInput) :
    Ssz.Node → Ssz.Node → Ssz.Node :=
  fun left right => structuralCombine right left

/-- The composed-encoding predicate, parameterized over the source-combine
family used in the deposit-data-root traversal conjunct so a model mutant
can be substituted without touching the functions `hBind` mentions. The
registered parent's conclusion predicate `composedEncodingOk` is the
specialization at the honest `sourceCombine`. Every registered conjunct is
a substantive fact, never an `rfl` accessor equality of `ComposedSszInput`'s
own derived fields:

1. the structural witness binding soundness transported out of `hBind`: the
   derived witness really is bound to the claimed `operation` and
   reconstructs `sourceNode input.src` under the claimed `combine`;
2. the same derived witness traverses to `sourceNode input.src` under the
   source-combine family `srcCombine input.src` (the non-definitional
   residue of the pinned deposit-data-root discharge: an equality between
   the generic `Ssz.traverseBranch` fold and the independently written
   pairing encoding);
3. `sourceConcat input.lhs input.rhs = specConcat input.lhs input.rhs` on the
   derived `GIndex.concat` operand — again an equality between two
   independently written artifacts (the literal pinned transcription and the
   independent append specification), not an accessor unfolding;
4. the seven-preimage count, the `runVerification` accept-iff control flow,
   and the exact pinned widths of the derived transaction input. -/
def composedEncodingOkWithCombine
    (srcCombine : SourceDepositDataRootInput → Ssz.Node → Ssz.Node → Ssz.Node)
    (operation : Ssz.Operation)
    (combine : Ssz.Node → Ssz.Node → Ssz.Node) (input : ComposedSszInput) : Prop :=
  -- Child: structural witness binding, on the SAME witness/root that the
  -- deposit-data-root child below discharges for `input.src` -- one shared
  -- object, not an independently supplied witness/expectedRoot pair.
  ((sourceWitness input.src).operation = operation ∧
    (sourceWitness input.src).index = Ssz.operationIndex operation ∧
    Ssz.HasGeneralizedIndex (sourceWitness input.src).index
      (sourceWitness input.src).pivotBoundary (sourceWitness input.src).path ∧
    (sourceWitness input.src).branch.length = (sourceWitness input.src).path.length ∧
    Ssz.traverseBranch combine
      (Ssz.validatorRoot combine (sourceWitness input.src).validator)
      (sourceWitness input.src).path (sourceWitness input.src).branch =
      sourceNode input.src) ∧
    -- Child: the SAME derived witness reconstructs the pinned
    -- deposit-data-root node under the source-combine family `srcCombine`.
    (Ssz.traverseBranch (srcCombine input.src)
        (Ssz.validatorRoot (srcCombine input.src) (sourceWitness input.src).validator)
        (sourceWitness input.src).path (sourceWitness input.src).branch =
      sourceNode input.src) ∧
    -- Child: GIndex.concat source transcription, on the SAME generalized
    -- index the structural-bind child above binds -- `input.rhs` is
    -- *derived* from `sourceWitness input.src`, not an independently
    -- supplied index for an unrelated operation or validator.
    (sourceConcat input.lhs input.rhs = specConcat input.lhs input.rhs) ∧
    -- Child: seven-call digest preimage count and root-match control flow,
    -- on the SAME pinned bytes the deposit-data-root child discharges for
    -- `input.src` -- `input.digestInput` / `input.txInput.toInputs` are
    -- *derived* from `input.src`, not an independently supplied `Inputs` for
    -- a different deposit.
    ((digestPreimages input.txInput.toInputs).length = 7 ∧
      (runVerification input.txInput = .accept ↔
        computedRoot input.txInput = input.txInput.expectedDepositDataRoot) ∧
      exactTxWidths input.txInput)

/-- The registered parent's conclusion predicate: the non-definitional
residue of the four-child one-object composition — the honest specialization
`composedEncodingOkWithCombine sourceCombine`. The wave-2 conclusion also
registered `input.rhs.index = (sourceWitness input.src).index.value`,
`input.digestInput = srcInputs input.src`,
`input.txInput.toInputs = srcInputs input.src`, the self-referential
`ExactDigestComposition input.digestInput` (`digestChain` is *defined* as
that seven-call list), the `signatureRoot input.src =
computeSignatureRoot input.src.signature` definitional unfolding
(`signatureRoot` is *defined* as that call), the pinned-config constant
equalities, the `src` field bound projections, and the hypothesis-restating
length lines; those are all definitional facts or restated hypotheses, so
they are omitted here. The derived-field definitions themselves
(`ComposedSszInput.rhs`/`digestInput`/`txInput`) remain — they are the
type-level one-object coupling, not claim conjuncts. -/
def composedEncodingOk (operation : Ssz.Operation)
    (combine : Ssz.Node → Ssz.Node → Ssz.Node) (input : ComposedSszInput) : Prop :=
  composedEncodingOkWithCombine sourceCombine operation combine input

/-- Composed on one object, not an independent `And` of four unrelated
arguments. The structural-bind hypothesis names `sourceWitness input.src` and
`sourceNode input.src` directly, so a witness bound for one deposit can no
longer be paired with the pinned deposit-data-root layout of a *different*
deposit (report issue #4's "witness for validator 1, root for validator 2"
counterexample). `GIndex.concat`'s `rhs` and the seven-call digest /
root-match child's `Inputs`/`TxInputs` are now likewise *derived* from
`input.src` (`ComposedSszInput.rhs`/`digestInput`/`txInput`), so all four
children read off the same object; only the state-root anchor (`lhs`) and the
chain-level fork version / claimed root remain independent, non-deposit
values. The conclusion is the named predicate `composedEncodingOk`, whose
conjuncts are all non-definitional (no `rfl` accessor equalities of the
record's own derived fields, no restated hypotheses). The parent kill-line
is `swapped_combine_kill_line_refutes_parent` below: it substitutes the
model mutant `sourceCombineSwapped` for `sourceCombine` — a model function
inside the conclusion predicate that `hBind` never mentions — and refutes
the mutant-substituted parent at a concrete witness where every premise and
`hBind` still hold. `crossed_witness_kill_line_refutes_parent` is the
separate conclusion-non-triviality witness (the conclusion predicate
discriminates the claimed operation). Still not `SSZ.verifyProof`
on production gindices; SHA-256 functional correctness remains
`A-SHA256-FFI`. -/
theorem composed_ssz_encoding
    {operation : Ssz.Operation} {combine : Ssz.Node → Ssz.Node → Ssz.Node}
    (input : ComposedSszInput)
    (hPublicKey : input.src.publicKey.length = PUBKEY_LENGTH pinnedConfig)
    (hWithdrawalCredentials : input.src.withdrawalCredentials.length =
      WITHDRAWAL_CREDENTIALS_LENGTH pinnedConfig)
    (hSignature : input.src.signature.length = SIGNATURE_LENGTH pinnedConfig)
    (hForkVersion : input.forkVersion.size = 4)
    (hExpectedRoot : input.expectedDepositDataRoot.size = digestBytes)
    (hBind : Ssz.bindOperation operation combine (sourceWitness input.src)
      (sourceNode input.src) = true) :
    composedEncodingOk operation combine input := by
  have hTxWidths : exactTxWidths input.txInput :=
    ⟨srcInputs_exactWidths input.src hPublicKey hWithdrawalCredentials hSignature,
      hForkVersion, hExpectedRoot⟩
  obtain ⟨-, -, -, -, -, -, -, -, -, -, -, -, -, -, hTraverse⟩ :=
    source_pinned_config_discharges_deposit_data_root input.src
      hPublicKey hWithdrawalCredentials hSignature
  unfold composedEncodingOk composedEncodingOkWithCombine
  refine ⟨Ssz.structural_witness_binding_sound hBind, hTraverse,
    encoding_uses_source_concat input.lhs input.rhs,
    digest_preimages_length input.txInput.toInputs,
    accepted_iff_root_matches input.txInput, hTxWidths⟩

/-- Conclusion-non-triviality witness (NOT the parent kill-line): the
registered conclusion predicate `composedEncodingOk` is not constantly true
— it discriminates the claimed operation. At the crossed operation
`.clProofVerifier` the predicate's first structural conjunct is false,
because `sourceWitness input.src` is bound to `.clValidatorVerifier` by
construction. Note the parent's `hBind` hypothesis also fails at this
crossed point, so the parent's implication is vacuously true there and this
theorem does NOT refute the parent; it only shows the conclusion predicate
itself has teeth. The parent kill-line — a mutant of the MODEL function
`sourceCombine` inside the predicate, refuted at a witness where `hBind`
holds — is `swapped_combine_kill_line_refutes_parent` below. The two older
kill-lines further below are `bindOperation`-level negatives:
`inconsistent_witness_kill_line` refutes only the parent's *hypothesis*
`hBind` on a crossed two-source pair that cannot even inhabit
`ComposedSszInput`, and `inconsistent_operation_index_kill_line` is a bare
`Nat` constant inequality. -/
theorem crossed_witness_kill_line_refutes_parent (input : ComposedSszInput) :
    ¬ composedEncodingOk .clProofVerifier (sourceCombine input.src) input := by
  intro h
  unfold composedEncodingOk composedEncodingOkWithCombine at h
  obtain ⟨⟨hOperation, -, -, -, -⟩, -, -, -⟩ := h
  have hWitness : (sourceWitness input.src).operation =
      Ssz.Operation.clValidatorVerifier := rfl
  rw [hWitness] at hOperation
  contradiction

/-- Kill-line: an inconsistent witness across children is rejected. Binding
`sourceWitness srcA` (child 1) against `sourceNode srcB` (child 2's root for a
*different* deposit) fails `bindOperation`, whenever the two deposits'
public-key anchors differ. This is exactly the cross-child mismatch
`composed_ssz_encoding`'s single shared `input.src` now rules out: the parent
hypothesis `hBind` can only be discharged when the structural witness and the
pinned deposit-data-root come from the same object. Note this negates the
parent's *hypothesis* on a crossed two-source pair that cannot inhabit
`ComposedSszInput`; the kill-line that refutes the mutant-substituted
parent at a hypothesis-satisfying witness is
`swapped_combine_kill_line_refutes_parent`, and
`crossed_witness_kill_line_refutes_parent` is the conclusion-non-triviality
witness. -/
theorem inconsistent_witness_kill_line
    (srcA srcB : SourceDepositDataRootInput)
    (hMismatch : sourceAnchor srcA ≠ sourceAnchor srcB) :
    Ssz.bindOperation .clValidatorVerifier (sourceCombine srcA) (sourceWitness srcA)
        (sourceNode srcB) = false := by
  have hRootNe :
      Ssz.traverseBranch (sourceCombine srcA)
          (Ssz.validatorRoot (sourceCombine srcA) (sourceWitness srcA).validator)
          (sourceWitness srcA).path (sourceWitness srcA).branch ≠ sourceNode srcB := by
    intro hEq
    have hStructural :
        structuralRoot (sourceAnchor srcA) (sourceSignatureNode srcA) (sourceLeaf srcA) =
          sourceNode srcB := by
      simpa [structuralRoot, sourceWitness, sourceCombine] using hEq
    exact hMismatch
      (sourceNode_components_injective srcB (sourceAnchor srcA) (sourceSignatureNode srcA)
        (sourceLeaf srcA) hStructural).1
  -- Restate against `sourceNode`'s unfolding, `structuralEncoding`, so this matches the
  -- shape `simp` leaves the goal in below (`sourceNode` is itself `@[simp]`).
  have hRootNe' :
      Ssz.traverseBranch (sourceCombine srcA)
          (Ssz.validatorRoot (sourceCombine srcA) (sourceWitness srcA).validator)
          (sourceWitness srcA).path (sourceWitness srcA).branch ≠
        structuralEncoding (sourceAnchor srcB) (sourceSignatureNode srcB) (sourceLeaf srcB) :=
    hRootNe
  have hBeqFalse :
      (Ssz.traverseBranch (sourceCombine srcA)
          (Ssz.validatorRoot (sourceCombine srcA) (sourceWitness srcA).validator)
          (sourceWitness srcA).path (sourceWitness srcA).branch ==
        structuralEncoding (sourceAnchor srcB) (sourceSignatureNode srcB)
          (sourceLeaf srcB)) = false := by
    simp [hRootNe']
  simp [Ssz.bindOperation, Ssz.verifyValidatorWitness, Ssz.verifyProof, hBeqFalse]

/-- Non-vacuity: `composed_ssz_encoding`'s `hBind` hypothesis is genuinely
satisfiable, not accidentally emptied by the tightened one-object coupling.
Any pinned-width `src` binds its own derived witness against its own derived
root, using exactly the arity/generalized-index/traversal facts
`source_pinned_config_discharges_deposit_data_root` already proves for that
same `src`. -/
theorem sourceWitness_binds_sourceNode (src : SourceDepositDataRootInput)
    (hPublicKey : src.publicKey.length = PUBKEY_LENGTH pinnedConfig)
    (hWithdrawalCredentials : src.withdrawalCredentials.length =
      WITHDRAWAL_CREDENTIALS_LENGTH pinnedConfig)
    (hSignature : src.signature.length = SIGNATURE_LENGTH pinnedConfig) :
    Ssz.bindOperation .clValidatorVerifier (sourceCombine src) (sourceWitness src)
        (sourceNode src) = true := by
  obtain ⟨-, -, -, -, -, -, -, -, -, -, -, -, -, hGI, hTraverse⟩ :=
    source_pinned_config_discharges_deposit_data_root src hPublicKey hWithdrawalCredentials
      hSignature
  have hOperation : (sourceWitness src).operation = Ssz.Operation.clValidatorVerifier := rfl
  have hIndex : (sourceWitness src).index = Ssz.operationIndex .clValidatorVerifier := rfl
  have hArity : (sourceWitness src).branch.length = (sourceWitness src).path.length := rfl
  simp only [Ssz.bindOperation, Ssz.verifyValidatorWitness, Ssz.verifyProof, Bool.and_eq_true,
    beq_iff_eq]
  exact ⟨⟨hOperation, hIndex⟩, ⟨⟨⟨hGI.1, hGI.2.1⟩, hGI.2.2⟩, hArity⟩, hTraverse⟩

/-! ### Model-mutant kill-line: swapped source combine

The registered parent's `hBind` hypothesis mentions only `operation`,
`combine`, `sourceWitness input.src`, and `sourceNode input.src` — never
`sourceCombine`. Mutating `sourceCombine` inside the conclusion predicate
therefore leaves the hypothesis satisfiable, and the mutant-substituted
parent is refuted below at a concrete witness where every premise and
`hBind` hold. -/

/-- Concrete pinned-width deposit for the model-mutant kill-line, with the
same 48/32/96-byte shape as `Tests/SszRegression.compositionSrc`; defined in
this module because the guarantee module cannot import the test module. -/
def swappedCombineKillSrc : SourceDepositDataRootInput := {
  withdrawalCredentials := List.replicate 32 1, publicKey := List.replicate 48 2,
  signature := List.replicate 96 3, amountGwei := 32_000_000_000
  withdrawalCredentialsBounded := by
    intro byte h
    simpa using (List.eq_of_mem_replicate h) ▸ (by decide : (1 : Nat) < 256)
  publicKeyBounded := by
    intro byte h
    simpa using (List.eq_of_mem_replicate h) ▸ (by decide : (2 : Nat) < 256)
  signatureBounded := by
    intro byte h
    simpa using (List.eq_of_mem_replicate h) ▸ (by decide : (3 : Nat) < 256)
  amountGweiBounded := by decide }

/-- The one-object composition input over `swappedCombineKillSrc`, with the
same chain-level values as `Tests/SszRegression.composedExample`. -/
def swappedCombineKillInput : ComposedSszInput :=
  { src := swappedCombineKillSrc
    lhs := ⟨2, 7, by decide, by decide⟩
    rhsPow := 11
    rhsPowFits := by decide
    forkVersion := zeros 4
    expectedDepositDataRoot := zeros digestBytes }

/-- Closed form of the swapped-combine traversal: with children swapped at
every `validatorRoot` pairing and at the final branch step, the
reconstructed root nests the value-bearing leaf on the *left* of the
outermost pair and carries the swapped signature/anchor pairing inside — a
different tree from the honest `structuralEncoding`. Definitional evaluation
of the witness's concrete `[.right]` path and singleton branch. -/
theorem traverseBranch_sourceCombineSwapped_eq (src : SourceDepositDataRootInput) :
    Ssz.traverseBranch (sourceCombineSwapped src)
        (Ssz.validatorRoot (sourceCombineSwapped src) (sourceWitness src).validator)
        (sourceWitness src).path (sourceWitness src).branch =
      Nat.pair (sourceLeaf src)
        (Nat.pair
          (Nat.pair (Nat.pair (sourceSignatureNode src) (sourceAnchor src)) (Nat.pair 0 0))
          (Nat.pair (Nat.pair 0 0) (Nat.pair 0 0))) := rfl

/-- The swapped-combine reconstruction can never equal the honestly paired
`structuralEncoding` when the public-key anchor is nonzero: by repeated
`Nat.pair` injectivity, equality would force
`Nat.pair 0 0 = Nat.pair anchor signatureNode`, hence `anchor = 0`. -/
theorem swapped_traverse_ne_structuralEncoding (anchor signatureNode leaf : Ssz.Node)
    (hAnchor : anchor ≠ 0) :
    Nat.pair leaf
        (Nat.pair
          (Nat.pair (Nat.pair signatureNode anchor) (Nat.pair 0 0))
          (Nat.pair (Nat.pair 0 0) (Nat.pair 0 0))) ≠
      structuralEncoding anchor signatureNode leaf := by
  intro h
  simp only [structuralEncoding] at h
  obtain ⟨hLeafD, hVLeaf⟩ := Nat.pair_eq_pair.mp h
  obtain ⟨-, hBF⟩ := Nat.pair_eq_pair.mp (hVLeaf.trans hLeafD)
  obtain ⟨-, h00⟩ := Nat.pair_eq_pair.mp hBF
  obtain ⟨hAnchor0, -⟩ := Nat.pair_eq_pair.mp h00
  exact hAnchor hAnchor0.symm

/-- THE parent kill-line: a mutant of the MODEL function `sourceCombine`
inside the conclusion predicate — the one model function the `hBind`
hypothesis does NOT mention — substituted for the honest `sourceCombine`
refutes the mutant-substituted parent at the honest non-vacuity witness,
where every premise and `hBind` still hold. Stated as the negation of the
mutant parent in the registered parent's own quantifier/premise/hypothesis
shape: the universal
`∀ {operation combine} input, premises → hBind →
composedEncodingOkWithCombine sourceCombineSwapped operation combine input`
is false, because at `swappedCombineKillInput` the pinned widths hold,
`hBind` is discharged by `sourceWitness_binds_sourceNode` (the same
discharge used for the honest artifact), yet the swapped-combine traversal
conjunct reduces (`traverseBranch_sourceCombineSwapped_eq`) to a `Nat.pair`
tree equality that would force `sourceAnchor swappedCombineKillSrc = 0`,
contradicting the concrete nonzero public-key fold. This is the house
kill-line shape — mutate the model inside the predicate, keep the
hypothesis satisfied — unlike `crossed_witness_kill_line_refutes_parent`'s
conclusion-non-triviality witness (where `hBind` fails and the parent
implication is vacuous) and the two `bindOperation`-level negatives. -/
theorem swapped_combine_kill_line_refutes_parent :
    ¬ (∀ {operation : Ssz.Operation} {combine : Ssz.Node → Ssz.Node → Ssz.Node}
        (input : ComposedSszInput),
      input.src.publicKey.length = PUBKEY_LENGTH pinnedConfig →
      input.src.withdrawalCredentials.length = WITHDRAWAL_CREDENTIALS_LENGTH pinnedConfig →
      input.src.signature.length = SIGNATURE_LENGTH pinnedConfig →
      input.forkVersion.size = 4 →
      input.expectedDepositDataRoot.size = digestBytes →
      Ssz.bindOperation operation combine (sourceWitness input.src) (sourceNode input.src) =
        true →
      composedEncodingOkWithCombine sourceCombineSwapped operation combine input) := by
  intro hMutantParent
  have hBind :=
    sourceWitness_binds_sourceNode swappedCombineKillSrc (by decide) (by decide) (by decide)
  have hOk :=
    hMutantParent swappedCombineKillInput
      (by decide) (by decide) (by decide) (by decide) (by decide) hBind
  obtain ⟨-, hTraverse, -, -⟩ := hOk
  rw [traverseBranch_sourceCombineSwapped_eq] at hTraverse
  have hAnchorNe : sourceAnchor swappedCombineKillInput.src ≠ 0 := by decide
  exact swapped_traverse_ne_structuralEncoding _ _ _ hAnchorNe hTraverse

/-- Kill-line: an index minted for a different named operation cannot satisfy
the new `GIndex.concat` coupling. `ComposedSszInput.rhs`'s index is pinned to
`sourceWitness input.src`'s slot (`.clValidatorVerifier`, value 2); the slot
for any other operation is a different value, so it can never equal
`(sourceWitness input.src).index.value` and the parent's `rhs`-derivation
could not have produced it from that other operation's index. This is a bare
constant inequality about the two slots; the conclusion-non-triviality
witness for the crossed operation is
`crossed_witness_kill_line_refutes_parent`, and the parent kill-line proper
is `swapped_combine_kill_line_refutes_parent`. -/
theorem inconsistent_operation_index_kill_line (src : SourceDepositDataRootInput) :
    (Ssz.operationIndex .clProofVerifier).value ≠ (sourceWitness src).index.value := by
  show (Ssz.operationIndex .clProofVerifier).value ≠
    (Ssz.operationIndex .clValidatorVerifier).value
  decide

/-- `observe` of the handwritten `encode` transaction equals `sourceView`.
A commit also re-exports the structural-witness conjunct. This is not
`SSZ.verifyProof` and does not prove SHA-256. -/
theorem verity_tx_simulates_ssz_encoding
    (input : EncodingInput) (state : Verity.ContractState) :
    observe ((encode input).run state) = sourceView input ∧
      ((observe ((encode input).run state)).status = .committed →
        structuralOk input = true ∧
          structuralWitnessConjunct input ∧
          (observe ((encode input).run state)).observables.bound = 1 ∧
          (observe ((encode input).run state)).observables.operation =
            operationWord input.operation ∧
          (observe ((encode input).run state)).observables.index =
            indexWord input.witness.index ∧
          (observe ((encode input).run state)).observables.pivotBoundary =
            nodeWord input.witness.pivotBoundary ∧
          (observe ((encode input).run state)).observables.traversedRoot =
            nodeWord (traversedRoot input) ∧
          (observe ((encode input).run state)).observables.pathLength =
            input.witness.path.length ∧
          (observe ((encode input).run state)).observables.branchLength =
            input.witness.branch.length ∧
          (observe ((encode input).run state)).observables.path =
            twoWords (input.witness.path.map siblingWord) ∧
          (observe ((encode input).run state)).observables.branch =
            twoWords (input.witness.branch.map nodeWord)) ∧
      sourceConcat input.lhs input.rhs = specConcat input.lhs input.rhs ∧
      (ExactDigestComposition input.deposit ∧
        (digestChain input.deposit).length = 7) ∧
      ∀ reason rollback,
        (encode input).run state = .revert reason rollback →
          rollback = state :=
  ⟨verity_tx_simulates_pinned_source input state,
    encoding_commits_structural_witness input state,
    encoding_uses_source_concat input.lhs input.rhs,
    encoding_uses_exact_digest input.deposit,
    fun reason rollback h =>
      revert_restores_snapshot input false state rollback reason h⟩

theorem verity_tx_two_batch_rolls_back
    (first second : EncodingInput) (state rollback : Verity.ContractState)
    (reason : String)
    (h : (encodeTwo first second true).run state = .revert reason rollback) :
    rollback = state :=
  revert_restores_snapshot_two first second true state rollback reason h

end LidoSRv3.Audit.Guarantees.PSsz1
