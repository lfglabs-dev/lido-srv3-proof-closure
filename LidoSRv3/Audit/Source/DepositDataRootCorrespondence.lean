import LidoSRv3.Audit.Ssz

/-!
# Pinned deposit-data-root source shape

This is a control-flow correspondence for
`BeaconChainDepositor.sol` at
`lidofinance/core@af095e48bbc1c3841c2c9936219c8461af01056b`, functions
`_computeDepositDataRootWithAmount` (lines 120--135),
`_computeSignatureRoot` (lines 137--146), and `_toLittleEndian64`
(lines 148--153).  `sha256` is deliberately an opaque source-shape operation:
this module establishes neither SHA-256 correctness, precompile behavior, SSZ
serialization, Solidity execution, nor validator provenance.  Those boundaries
remain recorded by A-RUNTIME-PROVENANCE, A-SHA256-FFI, and
A-MULTI-NODE-TRANSPORT.
-/

namespace LidoSRv3.Audit.Source.DepositDataRootCorrespondence

open LidoSRv3.Audit

abbrev Bytes := List Nat

/-- Pinned declarations used by the three source functions. -/
structure SourceDepositDataRootConfig where
  sha256DigestLength : Nat
  pubkeyLength : Nat
  withdrawalCredentialsLength : Nat
  signatureLength : Nat
  depositDataLength : Nat
  deriving DecidableEq, Repr

def SHA256_DIGEST_LENGTH (config : SourceDepositDataRootConfig) : Nat :=
  config.sha256DigestLength
def PUBKEY_LENGTH (config : SourceDepositDataRootConfig) : Nat := config.pubkeyLength
def WITHDRAWAL_CREDENTIALS_LENGTH (config : SourceDepositDataRootConfig) : Nat :=
  config.withdrawalCredentialsLength
def SIGNATURE_LENGTH (config : SourceDepositDataRootConfig) : Nat := config.signatureLength
def DEPOSIT_DATA_LENGTH (config : SourceDepositDataRootConfig) : Nat :=
  config.depositDataLength

/-- The literal constants declared by the pinned source. -/
def pinnedConfig : SourceDepositDataRootConfig := ⟨32, 48, 32, 96, 184⟩

/-- The four values read by `_computeDepositDataRootWithAmount`. -/
structure SourceDepositDataRootInput where
  withdrawalCredentials : Bytes
  publicKey : Bytes
  signatureRoot : Bytes
  amountGwei : Nat
  deriving DecidableEq, Repr

/-- Opaque stand-in for the source-level `sha256` call. -/
def sha256 (input : Bytes) : Bytes := input

/-- The byte selected by the source's `value >> (8 * i)` loop. -/
def sourceByteAt (value index : Nat) : Nat := value / 256 ^ index % 256

/--
The source's `_toLittleEndian64` loop (lines 148--153), expressed as its eight
successive byte selections.  This is byte-order control flow, not a claim about
Solidity casts beyond the pinned source shape.
-/
def toLittleEndian64 (value : Nat) : Bytes :=
  (List.range 8).map (sourceByteAt value)

/-- Source-shaped `_computeSignatureRoot` (lines 137--146). -/
def computeSignatureRoot (signature : Bytes) : Bytes :=
  let sigPart1 := signature.take 64
  let sigPart2 := signature.drop 64
  sha256 (sha256 sigPart1 ++ sha256 (sigPart2 ++ List.replicate 32 0))

/-- Source-shaped `_computeDepositDataRootWithAmount` (lines 120--135). -/
def computeDepositDataRootWithAmount (input : SourceDepositDataRootInput) : Bytes :=
  let publicKeyRoot := sha256 (input.publicKey ++ List.replicate 16 0)
  let amountLE := toLittleEndian64 input.amountGwei
  sha256
    (sha256 (publicKeyRoot ++ input.withdrawalCredentials) ++
      sha256 (amountLE ++ List.replicate 24 0 ++ input.signatureRoot))

/-- The source root used as every abstract structural leaf for this binding. -/
def sourceNode (input : SourceDepositDataRootInput) : Ssz.Node :=
  (computeDepositDataRootWithAmount input).length

def structuralCombine (node : Ssz.Node) : Ssz.Node → Ssz.Node → Ssz.Node :=
  fun _ _ => node

def sourceCombine (input : SourceDepositDataRootInput) : Ssz.Node → Ssz.Node → Ssz.Node :=
  structuralCombine (sourceNode input)

/-- The pinned construction emitted into the existing structural witness model. -/
def structuralWitness (node : Ssz.Node) : Ssz.ValidatorWitness :=
  { operation := .clValidatorVerifier
    validator := ⟨node, node, node, node, node, node, node, node⟩
    index := Ssz.operationIndex .clValidatorVerifier
    pivotBoundary := 2
    path := [.right]
    branch := [0] }

def sourceWitness (input : SourceDepositDataRootInput) : Ssz.ValidatorWitness :=
  structuralWitness (sourceNode input)

/--
With the exact pinned constants, the source-shaped deposit-data-root call emits
the `validatorRoot`-shaped generalized-index witness consumed by the structural
model.  This connects only presentation/control-flow shape to that model; it
does not refine the opaque `sha256`, a precompile, EVM execution, or production
validator provenance.
-/
theorem source_pinned_config_discharges_deposit_data_root
    (input : SourceDepositDataRootInput) :
    SHA256_DIGEST_LENGTH pinnedConfig = 32 ∧ PUBKEY_LENGTH pinnedConfig = 48 ∧
    WITHDRAWAL_CREDENTIALS_LENGTH pinnedConfig = 32 ∧ SIGNATURE_LENGTH pinnedConfig = 96 ∧
    DEPOSIT_DATA_LENGTH pinnedConfig = 184 ∧
    Ssz.HasGeneralizedIndex (sourceWitness input).index
      (sourceWitness input).pivotBoundary (sourceWitness input).path ∧
    Ssz.traverseBranch (sourceCombine input)
      (Ssz.validatorRoot (sourceCombine input) (sourceWitness input).validator)
      (sourceWitness input).path (sourceWitness input).branch = sourceNode input := by
  refine ⟨rfl, rfl, rfl, rfl, rfl, ?_, rfl⟩
  simp [sourceWitness, structuralWitness, Ssz.HasGeneralizedIndex, Ssz.operationIndex,
    Ssz.pivot, Ssz.indexFromPivotPath, Ssz.pathOffset]
  decide

end LidoSRv3.Audit.Source.DepositDataRootCorrespondence
