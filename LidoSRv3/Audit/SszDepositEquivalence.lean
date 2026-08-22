import LidoSRv3.Audit.Ssz
import LidoSRv3.Audit.Source.DepositDataRootCorrespondence

/-!
# Bidirectional P-SSZ-1 deposit-root equivalence

Structural model only: `Node = Nat`, `structuralCombine = Nat.pair`, and `sha256`
remains opaque in `DepositDataRootCorrespondence`. This module packages the
construction and determination directions of deposit-root binding at the
`.clValidatorVerifier` slot.

`PerfectDepositEncoding` records the `A-PERFECT-HASH` hypothesis: on
well-formed deposits (pinned 48/32/96-byte widths) the encoding
`sourceNode` is injective. SHA-256 correctness is not proved here.
-/

namespace LidoSRv3.Audit.SszDepositEquivalence

open LidoSRv3.Audit
open LidoSRv3.Audit.Source.DepositDataRootCorrespondence

/-- Pinned-width well-formed deposit: the 48/32/96-byte ABI the source overload
consumes. -/
def wellFormedDeposit (src : SourceDepositDataRootInput) : Prop :=
  src.publicKey.length = PUBKEY_LENGTH pinnedConfig ∧
    src.withdrawalCredentials.length = WITHDRAWAL_CREDENTIALS_LENGTH pinnedConfig ∧
      src.signature.length = SIGNATURE_LENGTH pinnedConfig

/-- `A-PERFECT-HASH`: on well-formed deposits the structural root encoding is
injective. This is the explicit hypothesis that closes determination uniqueness;
it does not assert SHA-256 correctness. -/
def PerfectDepositEncoding : Prop :=
  ∀ (srcA srcB : SourceDepositDataRootInput),
    wellFormedDeposit srcA → wellFormedDeposit srcB →
      sourceNode srcA = sourceNode srcB → srcA = srcB

/-- Structural verification at the `.clValidatorVerifier` slot using the pinned
source combiner. -/
def depositVerified (witness : Ssz.ValidatorWitness) (root : Ssz.Node) : Prop :=
  Ssz.bindOperation .clValidatorVerifier structuralCombine witness root = true

theorem wellFormedDeposit_of_lengths (src : SourceDepositDataRootInput)
    (hPublicKey : src.publicKey.length = PUBKEY_LENGTH pinnedConfig)
    (hWithdrawalCredentials : src.withdrawalCredentials.length =
      WITHDRAWAL_CREDENTIALS_LENGTH pinnedConfig)
    (hSignature : src.signature.length = SIGNATURE_LENGTH pinnedConfig) :
    wellFormedDeposit src :=
  ⟨hPublicKey, hWithdrawalCredentials, hSignature⟩

/-- At the pinned `.clValidatorVerifier` index, `HasGeneralizedIndex` fixes the
pivot boundary and the unique sibling path. -/
theorem clValidatorVerifier_index_forces_path
    (pivotBoundary : Nat) (path : List Ssz.SiblingSide)
    (hGI : Ssz.HasGeneralizedIndex (Ssz.operationIndex .clValidatorVerifier)
      pivotBoundary path) :
    pivotBoundary = 2 ∧ path = [.right] := by
  rcases hGI with ⟨hPivot, hLen, hValue⟩
  have hIndex : (Ssz.operationIndex .clValidatorVerifier).value = 2 := rfl
  rw [hIndex] at hValue
  have hPivot' : pivotBoundary = 2 := hPivot
  have hLen' : path.length = 1 := by simpa [hPivot'] using hLen
  cases path with
  | nil => simp at hLen'
  | cons side rest =>
    have hRest : rest = [] := by
      cases rest with
      | nil => rfl
      | cons _ _ => simp at hLen'
    subst hRest
    cases side
    · exfalso
      simp [hPivot', Ssz.indexFromPivotPath, Ssz.pathOffset] at hValue
    · exact ⟨hPivot', rfl⟩

/-- One-step right traversal factors as a `Nat.pair` with the validator root. -/
theorem traverseBranch_right_eq_pair_validator (validator : Ssz.Validator) (leaf : Ssz.Node) :
    Ssz.traverseBranch structuralCombine
        (Ssz.validatorRoot structuralCombine validator) [.right] [leaf] =
      Nat.pair (Ssz.validatorRoot structuralCombine validator) leaf := by
  simp [Ssz.traverseBranch, structuralCombine]

/-- `structuralRoot` agrees with right-step `Nat.pair` traversal. -/
theorem structuralRoot_eq_pair (anchor signatureNode leaf : Ssz.Node) :
    structuralRoot anchor signatureNode leaf =
      Nat.pair
        (Ssz.validatorRoot structuralCombine
          (structuralWitness anchor signatureNode leaf).validator)
        leaf := by
  rw [structuralRoot_eq]
  simp [structuralEncoding, structuralWitness, structuralCombine, Ssz.validatorRoot,
    Ssz.traverseBranch]

/-- The validator-root half of `structuralEncoding` before pairing with the leaf. -/
def structuralEncodingInner (anchor signatureNode : Ssz.Node) : Ssz.Node :=
  Nat.pair
    (Nat.pair (Nat.pair 0 0) (Nat.pair 0 0))
    (Nat.pair (Nat.pair 0 0) (Nat.pair anchor signatureNode))

/-- Matching the inner encoding pins the exit / withdrawable validator slots. -/
theorem validator_fields_of_root_eq_inner
    (validator : Ssz.Validator) (anchor signatureNode : Ssz.Node)
    (h :
      Ssz.validatorRoot structuralCombine validator = structuralEncodingInner anchor signatureNode) :
    validator.pubkey = 0 ∧
      validator.withdrawalCredentials = 0 ∧
        validator.effectiveBalance = 0 ∧
          validator.slashed = 0 ∧
            validator.activationEligibilityEpoch = 0 ∧
              validator.activationEpoch = 0 ∧
                validator.exitEpoch = anchor ∧
                  validator.withdrawableEpoch = signatureNode := by
  unfold structuralEncodingInner at h
  simp only [Ssz.validatorRoot, structuralCombine] at h
  rcases Nat.pair_eq_pair.mp h with ⟨hLeft, hRight⟩
  rcases Nat.pair_eq_pair.mp hLeft with ⟨hPubkeyPair, hBalancePair⟩
  rcases Nat.pair_eq_pair.mp hPubkeyPair with ⟨hPubkey, hWithdrawal⟩
  rcases Nat.pair_eq_pair.mp hBalancePair with ⟨hEffective, hSlashed⟩
  rcases Nat.pair_eq_pair.mp hRight with ⟨hEpochPair, hExitPair⟩
  rcases Nat.pair_eq_pair.mp hEpochPair with ⟨hAee, hAct⟩
  rcases Nat.pair_eq_pair.mp hExitPair with ⟨hExit, hWithdrawable⟩
  exact ⟨hPubkey, hWithdrawal, hEffective, hSlashed, hAee, hAct, hExit, hWithdrawable⟩

/-- Verified witnesses at the validator slot use the pinned path and arity. -/
theorem deposit_verified_has_clValidator_path
    (witness : Ssz.ValidatorWitness) (root : Ssz.Node)
    (hVerified : depositVerified witness root) :
    witness.operation = .clValidatorVerifier ∧
      witness.index = Ssz.operationIndex .clValidatorVerifier ∧
      witness.pivotBoundary = 2 ∧
      witness.path = [.right] ∧
      witness.branch.length = 1 := by
  rcases Ssz.structural_witness_binding_sound hVerified with
    ⟨hOperation, hIndex, hGI, hArity, -⟩
  rw [hIndex] at hGI
  rcases clValidatorVerifier_index_forces_path witness.pivotBoundary witness.path hGI with
    ⟨hPivot, hPath⟩
  refine ⟨hOperation, hIndex, hPivot, hPath, ?_⟩
  simpa [hPath] using hArity

/-- When traversal reaches `sourceNode src`, the witness validator slots and
branch leaf match the source-derived components. -/
theorem deposit_verified_pins_components
    (src : SourceDepositDataRootInput) (witness : Ssz.ValidatorWitness)
    (root : Ssz.Node) (hVerified : depositVerified witness root)
    (hRoot : root = sourceNode src) :
    witness.validator.exitEpoch = sourceAnchor src ∧
      witness.validator.withdrawableEpoch = sourceSignatureNode src ∧
        ∃ leaf, witness.branch = [leaf] ∧ leaf = sourceLeaf src := by
  rcases deposit_verified_has_clValidator_path witness root hVerified with
    ⟨-, -, -, hPath, hArity⟩
  rcases Ssz.structural_witness_binding_sound hVerified with ⟨_, _, _, _, hTraverse⟩
  rcases List.length_eq_one_iff.mp hArity with ⟨leaf, hBranch⟩
  rw [hPath, hBranch] at hTraverse
  rw [traverseBranch_right_eq_pair_validator, hRoot] at hTraverse
  rcases Nat.pair_eq_pair.mp hTraverse with ⟨hValidatorRoot, hLeafEq⟩
  have hInner :
      Ssz.validatorRoot structuralCombine witness.validator =
        structuralEncodingInner (sourceAnchor src) (sourceSignatureNode src) := by
    unfold structuralEncodingInner
    simpa [sourceNode, structuralEncoding] using hValidatorRoot
  have hFields :=
    validator_fields_of_root_eq_inner witness.validator (sourceAnchor src)
      (sourceSignatureNode src) hInner
  exact ⟨hFields.2.2.2.2.2.2.1, hFields.2.2.2.2.2.2.2, leaf, hBranch, hLeafEq⟩

theorem ValidatorWitness_eq_of_components
    (w w' : Ssz.ValidatorWitness)
    (hOp : w.operation = w'.operation)
    (hVal : w.validator = w'.validator)
    (hIdx : w.index = w'.index)
    (hPivot : w.pivotBoundary = w'.pivotBoundary)
    (hPath : w.path = w'.path)
    (hBranch : w.branch = w'.branch) :
    w = w' := by
  cases w
  cases w'
  simp at hOp hVal hIdx hPivot hPath hBranch
  subst hOp hVal hIdx hPivot hPath hBranch
  rfl

/-- Determination: a verified witness against `sourceNode src` equals
`sourceWitness src`. -/
theorem deposit_verified_witness_eq_sourceWitness
    (src : SourceDepositDataRootInput) (witness : Ssz.ValidatorWitness)
    (root : Ssz.Node) (hVerified : depositVerified witness root)
    (hRoot : root = sourceNode src) :
    witness = sourceWitness src := by
  rcases deposit_verified_pins_components src witness root hVerified hRoot with
    ⟨hExit, hWithdraw, leaf, hBranch, hLeafEq⟩
  rcases deposit_verified_has_clValidator_path witness root hVerified with
    ⟨hOperation, hIndex, hPivot, hPath, -⟩
  rcases Ssz.structural_witness_binding_sound hVerified with ⟨_, _, _, _, hTraverse⟩
  have hFields :=
    validator_fields_of_root_eq_inner witness.validator (sourceAnchor src)
      (sourceSignatureNode src)
      (by
        rw [hPath, hBranch, traverseBranch_right_eq_pair_validator, hRoot, sourceNode,
          structuralEncoding] at hTraverse
        unfold structuralEncodingInner
        exact (Nat.pair_eq_pair.mp hTraverse).1)
  cases witness with | mk op val idx piv path branch =>
  have hValidator :
      val = (structuralWitness (sourceAnchor src) (sourceSignatureNode src) 0).validator := by
    cases val with | mk p wc eb s aee ae ex wd =>
    rcases hFields with ⟨rfl, rfl, rfl, rfl, rfl, rfl, rfl, rfl⟩
    rfl
  have hValidator' : val = (sourceWitness src).validator := by
    simpa [sourceWitness, structuralWitness] using hValidator
  have hBranch' : branch = (sourceWitness src).branch :=
    show branch = [sourceLeaf src] from hLeafEq ▸ hBranch |>.trans (by
      simp [sourceWitness, structuralWitness])
  exact ValidatorWitness_eq_of_components
    { operation := op, validator := val, index := idx, pivotBoundary := piv, path := path,
      branch := branch } (sourceWitness src) hOperation hValidator' hIndex hPivot hPath hBranch'

/-- Determination uniqueness under `PerfectDepositEncoding`. -/
theorem deposit_verified_source_unique
    (src src' : SourceDepositDataRootInput)
    (hWellFormed : wellFormedDeposit src)
    (hWellFormed' : wellFormedDeposit src')
    (hPerfect : PerfectDepositEncoding) :
    sourceNode src' = sourceNode src → src' = src :=
  fun hEq => hPerfect src' src hWellFormed' hWellFormed hEq

/-- Construction direction: a well-formed deposit binds its derived witness. -/
theorem wellFormed_deposit_binds_sourceWitness (src : SourceDepositDataRootInput)
    (hWellFormed : wellFormedDeposit src) :
    depositVerified (sourceWitness src) (sourceNode src) := by
  rcases hWellFormed with ⟨hPublicKey, hWithdrawalCredentials, hSignature⟩
  simpa [depositVerified] using
    sourceWitness_binds_sourceNode src hPublicKey hWithdrawalCredentials hSignature

/-- Bidirectional deposit-root equivalence at the structural layer. -/
theorem deposit_root_iff (src : SourceDepositDataRootInput)
    (hWellFormed : wellFormedDeposit src) (hPerfect : PerfectDepositEncoding) :
    depositVerified (sourceWitness src) (sourceNode src) ∧
      (∀ witness root,
        depositVerified witness root →
          root = sourceNode src →
            witness = sourceWitness src ∧
              ∀ src', wellFormedDeposit src' →
                sourceNode src' = sourceNode src → src' = src) := by
  refine ⟨wellFormed_deposit_binds_sourceWitness src hWellFormed, ?_⟩
  intro witness root hVerified hRoot
  refine ⟨deposit_verified_witness_eq_sourceWitness src witness root hVerified hRoot, ?_⟩
  intro src' hWellFormed' hEq
  exact deposit_verified_source_unique src src' hWellFormed hWellFormed' hPerfect hEq

end LidoSRv3.Audit.SszDepositEquivalence
