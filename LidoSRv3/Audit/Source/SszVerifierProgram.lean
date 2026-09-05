/-!
# SSZ verifier program preparation interface

This component records the concrete observations an official Verity program
must expose before the pinned SSZ verifier and deposit-data-root routines can
be refined.  It is deliberately not an interpreter and does not import or
alias `Audit.Ssz` or `DepositDataRootCorrespondence`.

Source anchors are `lidofinance/core@17005714f151e5502c559932319a3f2f74ac2436`:

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

/-! ## Raw revert selectors of `SSZ.verifyProof` (SSZ.sol:179-248)

The Yul body reverts with a 4-byte selector written to scratch
(`mstore(0x00, <selector>)` then `revert(0x1c, 0x04)`). Recorded here as
annotated constants; `RevertObservation` names the same outcomes. -/

/-- `SSZ.sol:187  mstore(0x00, 0x09bde339)` (empty proof) and
`SSZ.sol:244  mstore(0x00, 0x09bde339)` (`leaf != root`): `InvalidProof()`. -/
def invalidProofSelector : Nat := 0x09bde339

/-- `SSZ.sol:203  mstore(0x00, 0x5849603f)`: `BranchHasExtraItem()` when
`index` reaches zero before the proof is exhausted. -/
def branchHasExtraItemSelector : Nat := 0x5849603f

/-- `SSZ.sol:238  mstore(0x00, 0x1b6661c3)`: `BranchHasMissingItem()` when
the proof is exhausted with `index != 1`. -/
def branchHasMissingItemSelector : Nat := 0x1b6661c3

/-- Outcome tags. `invalidProof`, `branchHasExtraItem`, `branchHasMissingItem`
correspond to the three selectors above; `shaCallFailed` is the bare
`revert(0, 0)` of `SSZ.sol:223-226`; the others are harness gates. -/
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

/-! ## SSZ.verifyProof (SSZ.sol:179-248), control-flow observation -/

/--
Loop body `SSZ.sol:195-233  for { } 1 { } { ... }` of `verifyProof`.
First-failure-wins control flow of `SSZ.sol` lines 179--248.  Digest values and
memory effects are intentionally absent: official Verity must later provide
those semantics and connect them to this observation interface.
-/
def observeVerifierControlAux : Nat → Nat → List Bool → List ShaCallSpec → ProgramObservation
  | _, _, [], calls => .reverted .shaCallFailed calls
  | step, index, ok :: rest, calls =>
      -- SSZ.sol:200  index := shr(1, index)
      let shifted := index / 2
      -- SSZ.sol:201-205  if iszero(index) { mstore(0x00, 0x5849603f); revert(0x1c, 0x04) }  (BranchHasExtraItem)
      if shifted = 0 then .reverted .branchHasExtraItem calls
      else
        -- SSZ.sol:209-221  mstore(scratch, leaf); mstore(xor(scratch, 0x20), calldataload(offset)); staticcall(gas(), 0x02, ...)
        let call := verifierShaCall step index
        -- SSZ.sol:223-226  if iszero(result) { revert(0, 0) }
        if !ok then .reverted .shaCallFailed calls
        -- SSZ.sol:230-233  offset := add(offset, 0x20); if iszero(lt(offset, end)) { break }
        else if rest.isEmpty then .verified (calls ++ [call])
        else observeVerifierControlAux (step + 1) shifted rest (calls ++ [call])

/-- `SSZ.sol:179-248 verifyProof(bytes32[] calldata proof, bytes32 root, bytes32 leaf, GIndex gI)`,
control-flow observation. Records which revert selector fires and how many
SHA-256 boundaries were crossed; digests are not computed.

Not transcribed: the scratch-memory contents, `calldataload(offset)`, the
SHA-256 output (`leaf := mload(0x00)`, 229), and the final root comparison
value (`finalRootMatches` is an input). Added by the model: the
`officialSemanticsReady` gate, the `2^256` index bound (`invalidIndex`), and
the `shaSucceeded` length check.

The abstract-plane model of the same span is `LidoSRv3.Audit.Ssz.verifyProof`
(pure checks on supplied pivot/path data with an opaque `combine`). The two
are independent by design: neither module imports the other. -/
def observeVerifierControl (caps : OfficialVerityCapabilities)
    (input : VerifierControlInput) : ProgramObservation :=
  gateOfficialSemantics caps <|
    -- SSZ.sol:180  uint256 index = gI.index();  (word-sized; bound added by the model)
    if input.generalizedIndex >= 2 ^ 256 then .reverted .invalidIndex []
    -- SSZ.sol:185-189  if iszero(proof.length) { mstore(0x00, 0x09bde339); revert(0x1c, 0x04) }  (InvalidProof)
    else if input.proofLength = 0 then .reverted .invalidProof []
    -- (model consistency: one SHA-256 outcome per proof element)
    else if input.shaSucceeded.length != input.proofLength then
      .reverted .shaCallFailed []
    else
      -- SSZ.sol:195-233  the for loop
      match observeVerifierControlAux 0 input.generalizedIndex input.shaSucceeded [] with
      | .verified calls =>
          let finalIndex := input.generalizedIndex / (2 ^ input.proofLength)
          -- SSZ.sol:236-240  if iszero(eq(index, 1)) { mstore(0x00, 0x1b6661c3); revert(0x1c, 0x04) }  (BranchHasMissingItem)
          if finalIndex != 1 then .reverted .branchHasMissingItem calls
          -- SSZ.sol:242-246  if iszero(eq(leaf, root)) { mstore(0x00, 0x09bde339); revert(0x1c, 0x04) }  (InvalidProof)
          else if !input.finalRootMatches then .reverted .invalidProof calls
          else .verified calls
      | failure => failure

/-- Solidity-facing name, `SSZ.sol:179` (control-flow observation only). -/
abbrev verifyProof := observeVerifierControl

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
