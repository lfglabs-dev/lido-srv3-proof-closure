/-!
# SSZ verifier program preparation interface

This component records the concrete observations an official Verity program
must expose before the pinned SSZ verifier and deposit-data-root routines can
be refined.  It is deliberately not an interpreter and does not import or
alias `Audit.Ssz` or `DepositDataRootCorrespondence`.

Source anchors are `lidofinance/core@af095e48bbc1c3841c2c9936219c8461af01056b`:

* `SSZ.sol` lines 89--175 (`hashTreeRoot`) and 179--248 (`verifyProof`);
* `BeaconChainDepositor.sol` lines 110--153 (deposit-data/signature roots);
* `BeaconTypes.sol` lines 8--17 (validator field order).

The SHA observations below constrain call boundaries and composition only.
They assume neither SHA-256 functional correctness nor precompile correctness.
-/

namespace LidoSRv3.Audit.Source.SszVerifierProgram

abbrev Bytes := List Nat

def digestBytes : Nat := 32
def shaAddress : Nat := 2
def scratchOffset : Nat := 0
def rightScratchOffset : Nat := 32
def shaPairInputBytes : Nat := 64
def shaOutputBytes : Nat := 32
def publicKeyBytes : Nat := 48
def withdrawalCredentialsBytes : Nat := 32
def signatureBytes : Nat := 96
def amountBytes : Nat := 8
def depositDataBytes : Nat := 184

/-- Field order at `SSZ.sol` lines 110--119 / `BeaconTypes.sol` lines 8--17. -/
inductive ValidatorField
  | publicKey | withdrawalCredentials | effectiveBalance | slashed
  | activationEligibilityEpoch | activationEpoch | exitEpoch | withdrawableEpoch
  deriving DecidableEq, Repr

/-- Byte sources are names, offsets, and lengths, not byte contents. -/
inductive SliceSource
  | publicKey | withdrawalCredentials | signature | amountLittleEndian
  | zeroPadding | digest (call : Nat) | validatorField (field : ValidatorField)
  | verifierLeaf | proofElement (step : Nat)
  deriving DecidableEq, Repr

structure Piece where
  source : SliceSource
  sourceOffset : Nat
  length : Nat
  deriving DecidableEq, Repr

structure ShaCallBoundary where
  address : Nat := shaAddress
  inputOffset : Nat := scratchOffset
  inputLength : Nat
  outputOffset : Nat := scratchOffset
  outputLength : Nat := shaOutputBytes
  deriving DecidableEq, Repr

structure ShaCallSpec where
  ordinal : Nat
  preimage : List Piece
  boundary : ShaCallBoundary
  deriving DecidableEq, Repr

def piece (source : SliceSource) (sourceOffset length : Nat) : Piece :=
  { source, sourceOffset, length }

def pairBoundary : ShaCallBoundary := { inputLength := shaPairInputBytes }

/-- Exact seven-call schedule for lines 110--146, in execution order. -/
def depositDataRootCalls : List ShaCallSpec := [
  ⟨0, [piece .signature 0 64], pairBoundary⟩,
  ⟨1, [piece .signature 64 32, piece .zeroPadding 0 32], pairBoundary⟩,
  ⟨2, [piece (.digest 0) 0 32, piece (.digest 1) 0 32], pairBoundary⟩,
  ⟨3, [piece .publicKey 0 48, piece .zeroPadding 0 16], pairBoundary⟩,
  ⟨4, [piece (.digest 3) 0 32, piece .withdrawalCredentials 0 32], pairBoundary⟩,
  ⟨5, [piece .amountLittleEndian 0 8, piece .zeroPadding 0 24,
        piece (.digest 2) 0 32], pairBoundary⟩,
  ⟨6, [piece (.digest 4) 0 32, piece (.digest 5) 0 32], pairBoundary⟩
]

def preimageLength (call : ShaCallSpec) : Nat :=
  (call.preimage.map Piece.length).sum

theorem deposit_call_ordinals : depositDataRootCalls.map ShaCallSpec.ordinal =
    [0, 1, 2, 3, 4, 5, 6] := by decide

theorem deposit_call_preimages_exact :
    depositDataRootCalls.map preimageLength = [64, 64, 64, 64, 64, 64, 64] := by decide

theorem deposit_call_boundaries_exact :
    ∀ call ∈ depositDataRootCalls,
      call.boundary = pairBoundary := by decide

def validatorFieldOrder : List ValidatorField := [
  .publicKey, .withdrawalCredentials, .effectiveBalance, .slashed,
  .activationEligibilityEpoch, .activationEpoch, .exitEpoch, .withdrawableEpoch
]

theorem validator_has_eight_ordered_fields : validatorFieldOrder.length = 8 := by decide

/--
Exact validator-root composition: pubkey padding, four bottom pairs, two middle
pairs, and the root pair. Each source carries its semantic `ValidatorField`;
the public-key field is replaced by call 0's padded pubkey digest.
-/
def validatorRootCalls : List ShaCallSpec := [
  ⟨0, [piece .publicKey 0 48, piece .zeroPadding 0 16], pairBoundary⟩,
  ⟨1, [piece (.digest 0) 0 32, piece (.validatorField .withdrawalCredentials) 0 32], pairBoundary⟩,
  ⟨2, [piece (.validatorField .effectiveBalance) 0 32,
        piece (.validatorField .slashed) 0 32], pairBoundary⟩,
  ⟨3, [piece (.validatorField .activationEligibilityEpoch) 0 32,
        piece (.validatorField .activationEpoch) 0 32], pairBoundary⟩,
  ⟨4, [piece (.validatorField .exitEpoch) 0 32,
        piece (.validatorField .withdrawableEpoch) 0 32], pairBoundary⟩,
  ⟨5, [piece (.digest 1) 0 32, piece (.digest 2) 0 32], pairBoundary⟩,
  ⟨6, [piece (.digest 3) 0 32, piece (.digest 4) 0 32], pairBoundary⟩,
  ⟨7, [piece (.digest 5) 0 32, piece (.digest 6) 0 32], pairBoundary⟩
]

theorem validator_root_has_eight_sha_calls : validatorRootCalls.length = 8 := by decide

theorem validator_root_preimages_exact :
    validatorRootCalls.map preimageLength = [64, 64, 64, 64, 64, 64, 64, 64] := by decide

/-- The value carried in `leaf`: the input leaf initially, then the prior digest. -/
def verifierAccumulator (step : Nat) : SliceSource :=
  if step = 0 then .verifierLeaf else .digest (step - 1)

/-- The verifier scratch ordering selected before `index := index >> 1`. -/
def verifierPair (index step : Nat) : List Piece :=
  if index % 2 = 0 then
    [piece (verifierAccumulator step) 0 32, piece (.proofElement step) 0 32]
  else
    [piece (.proofElement step) 0 32, piece (verifierAccumulator step) 0 32]

theorem verifier_pair_preimage_exact (index step : Nat) :
    ((verifierPair index step).map Piece.length).sum = 64 := by
  simp only [verifierPair]
  split <;> simp [piece]

inductive RevertObservation
  | invalidAbi | invalidRoot | invalidIndex | invalidProof
  | branchHasExtraItem | branchHasMissingItem | shaCallFailed
  | officialSemanticsUnavailable
  deriving DecidableEq, Repr

inductive ProgramObservation
  | returnedDepositRoot (root : Bytes) (calls : List ShaCallSpec)
  | verified (calls : List ShaCallSpec)
  | reverted (reason : RevertObservation) (completedCalls : List ShaCallSpec)
  deriving DecidableEq, Repr

/-- Capabilities that must come from official Verity, never a local substitute. -/
structure OfficialVerityCapabilities where
  byteAddressedMemory : Bool
  dynamicBytesAbi : Bool
  sha256CallSemantics : Bool
  deriving DecidableEq, Repr

def officialSemanticsReady (caps : OfficialVerityCapabilities) : Bool :=
  caps.byteAddressedMemory && caps.dynamicBytesAbi && caps.sha256CallSemantics

/-- Fail-closed gate shared by future verifier and deposit-root programs. -/
def gateOfficialSemantics (caps : OfficialVerityCapabilities)
    (onReady : ProgramObservation) : ProgramObservation :=
  if officialSemanticsReady caps then onReady
  else .reverted .officialSemanticsUnavailable []

/-- Concrete ABI lengths consumed by the deposit-root overload. -/
structure DepositAbiObservation where
  publicKeyLength : Nat
  withdrawalCredentialsLength : Nat
  signatureLength : Nat
  encodedFieldBytes : Nat
  deriving DecidableEq, Repr

def depositAbiExact (abi : DepositAbiObservation) : Bool :=
  abi.publicKeyLength == publicKeyBytes &&
  abi.withdrawalCredentialsLength == withdrawalCredentialsBytes &&
  abi.signatureLength == signatureBytes &&
  abi.encodedFieldBytes == depositDataBytes

/-- Solidity `bytes32` output shape: exactly 32 octets. -/
def digestExact (bytes : Bytes) : Bool :=
  bytes.length == digestBytes && bytes.all (fun byte => byte < 256)

/--
Program-facing deposit observation.  `candidateRoot` is an observation to be
provided by future official SHA semantics; this interface does not compute or
validate its cryptographic contents.
-/
def observeDepositDataRoot (caps : OfficialVerityCapabilities)
    (abi : DepositAbiObservation) (candidateRoot : Bytes) : ProgramObservation :=
  gateOfficialSemantics caps <|
    if !depositAbiExact abi then .reverted .invalidAbi []
    else if digestExact candidateRoot then
      .returnedDepositRoot candidateRoot depositDataRootCalls
    else .reverted .invalidRoot []

def verifierShaCall (step index : Nat) : ShaCallSpec :=
  ⟨step, verifierPair index step, pairBoundary⟩

/-- Inputs observable at the pinned `verifyProof` control-flow boundary. -/
structure VerifierControlInput where
  proofLength : Nat
  generalizedIndex : Nat
  shaSucceeded : List Bool
  finalRootMatches : Bool
  deriving DecidableEq, Repr

/--
First-failure-wins control flow of `SSZ.sol` lines 179--248.  Digest values and
memory effects are intentionally absent: official Verity must later provide
those semantics and connect them to this observation interface.
-/
def observeVerifierControlAux : Nat → Nat → List Bool → List ShaCallSpec → ProgramObservation
  | _, _, [], calls => .reverted .shaCallFailed calls
  | step, index, ok :: rest, calls =>
      let shifted := index / 2
      if shifted = 0 then .reverted .branchHasExtraItem calls
      else
        let call := verifierShaCall step index
        if !ok then .reverted .shaCallFailed calls
        else if rest.isEmpty then .verified (calls ++ [call])
        else observeVerifierControlAux (step + 1) shifted rest (calls ++ [call])

def observeVerifierControl (caps : OfficialVerityCapabilities)
    (input : VerifierControlInput) : ProgramObservation :=
  gateOfficialSemantics caps <|
    if input.generalizedIndex >= 2 ^ 256 then .reverted .invalidIndex []
    else if input.proofLength = 0 then .reverted .invalidProof []
    else if input.shaSucceeded.length != input.proofLength then
      .reverted .shaCallFailed []
    else
      match observeVerifierControlAux 0 input.generalizedIndex input.shaSucceeded [] with
      | .verified calls =>
          let finalIndex := input.generalizedIndex / (2 ^ input.proofLength)
          if finalIndex != 1 then .reverted .branchHasMissingItem calls
          else if !input.finalRootMatches then .reverted .invalidProof calls
          else .verified calls
      | failure => failure

theorem missing_memory_fails_closed (caps : OfficialVerityCapabilities)
    (h : caps.byteAddressedMemory = false) (candidate : ProgramObservation) :
    gateOfficialSemantics caps candidate =
      .reverted .officialSemanticsUnavailable [] := by
  simp [gateOfficialSemantics, officialSemanticsReady, h]

theorem missing_abi_fails_closed (caps : OfficialVerityCapabilities)
    (h : caps.dynamicBytesAbi = false) (candidate : ProgramObservation) :
    gateOfficialSemantics caps candidate =
      .reverted .officialSemanticsUnavailable [] := by
  simp [gateOfficialSemantics, officialSemanticsReady, h]

theorem missing_sha_fails_closed (caps : OfficialVerityCapabilities)
    (h : caps.sha256CallSemantics = false) (candidate : ProgramObservation) :
    gateOfficialSemantics caps candidate =
      .reverted .officialSemanticsUnavailable [] := by
  simp [gateOfficialSemantics, officialSemanticsReady, h]

end LidoSRv3.Audit.Source.SszVerifierProgram
