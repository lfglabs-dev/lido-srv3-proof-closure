import LidoSRv3.Audit.Ssz

/-!
# Pinned deposit-data-root source shape

This is a control-flow correspondence for
`BeaconChainDepositor.sol` at
`lidofinance/core@af095e48bbc1c3841c2c9936219c8461af01056b`, functions
`_computeDepositDataRootWithAmount` (lines 110--135),
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

/--
Source constants and source-shaped byte-layout literals.  `pubkeyLength` and
`signatureLength` are pinned declarations; digest, withdrawal, and aggregate
deposit lengths are documented source-layout assumptions pinned to the hash
chain span below, not Solidity constant declarations.
-/
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

/-- Pinned declarations plus documented source-layout literals. -/
def pinnedConfig : SourceDepositDataRootConfig := ⟨32, 48, 32, 96, 184⟩

/-- The raw values consumed by the public deposit-data-root overload. -/
structure SourceDepositDataRootInput where
  withdrawalCredentials : Bytes
  publicKey : Bytes
  signature : Bytes
  amountGwei : Nat
  deriving DecidableEq, Repr

/--
A pinned-source SHA-256 result.  The cryptographic contents stay unmodelled;
what is pinned here is only the ABI shape the Solidity source guarantees: the
`sha256` precompile returns a `bytes32`, i.e. exactly
`SHA256_DIGEST_LENGTH pinnedConfig` byte-valued elements.  Carrying that shape
in the type is what makes the nested `abi.encodePacked` concatenations below
have the source's byte layout rather than an arbitrary one.
-/
structure Sha256Digest where
  bytes : Bytes
  widthPinned : bytes.length = SHA256_DIGEST_LENGTH pinnedConfig
  bytesBounded : ∀ b ∈ bytes, b < 256

instance : Inhabited Sha256Digest where
  default :=
    { bytes := List.replicate (SHA256_DIGEST_LENGTH pinnedConfig) 0
      widthPinned := by simp
      bytesBounded := by
        intro b hb
        simpa using (List.eq_of_mem_replicate hb) ▸ (by decide : (0 : Nat) < 256) }

/--
The SHA-256/precompile boundary is intentionally opaque.  This declaration
preserves the source hash-chain data flow, and now its pinned digest width,
without asserting a cryptographic or precompile implementation; that residual is
recorded as `STRETCH_OPAQUE_FFI`.
-/
opaque sha256 : Bytes → Sha256Digest

/-- The source's `abi.encodePacked(bytes32, bytes32)` two-digest preimage. -/
def concatDigests (left right : Sha256Digest) : Bytes := left.bytes ++ right.bytes

/-- The two-digest preimage has exactly the pinned 64-byte source layout. -/
theorem concatDigests_length (left right : Sha256Digest) :
    (concatDigests left right).length = 2 * SHA256_DIGEST_LENGTH pinnedConfig := by
  simp [concatDigests, left.widthPinned, right.widthPinned, Nat.two_mul]

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
def computeSignatureRoot (signature : Bytes) : Sha256Digest :=
  let sigPart1 := signature.take 64
  let sigPart2 := (signature.drop 64).take 32
  sha256 (concatDigests (sha256 sigPart1) (sha256 (sigPart2 ++ List.replicate 32 0)))

/-- The source's public overload derives, rather than accepts, the signature root. -/
def signatureRoot (input : SourceDepositDataRootInput) : Sha256Digest :=
  computeSignatureRoot input.signature

/-- Source-shaped `_computeDepositDataRootWithAmount` (lines 120--135). -/
def computeDepositDataRootWithAmount (input : SourceDepositDataRootInput) : Sha256Digest :=
  let publicKeyRoot := sha256 (input.publicKey ++ List.replicate 16 0)
  let amountLE := toLittleEndian64 input.amountGwei
  sha256
    (concatDigests (sha256 (publicKeyRoot.bytes ++ input.withdrawalCredentials))
      (sha256 (amountLE ++ List.replicate 24 0 ++ (signatureRoot input).bytes)))

/-! ### Pinned `abi.encodePacked` preimage widths

With the digest width carried by `Sha256Digest`, every hash-chain preimage in
the two source functions has the exact byte width of the pinned
`abi.encodePacked` expression.  An unconstrained `Bytes → Bytes` result admits
layouts that these lemmas reject. -/

theorem signaturePart1_length (signature : Bytes)
    (hSignature : signature.length = SIGNATURE_LENGTH pinnedConfig) :
    (signature.take 64).length = 64 := by
  simp [hSignature, SIGNATURE_LENGTH, pinnedConfig]

theorem signaturePart2_preimage_length (signature : Bytes)
    (hSignature : signature.length = SIGNATURE_LENGTH pinnedConfig) :
    ((signature.drop 64).take 32 ++ List.replicate 32 0).length = 64 := by
  simp [hSignature, SIGNATURE_LENGTH, pinnedConfig]

theorem signatureRoot_preimage_length (signature : Bytes) :
    (concatDigests (sha256 (signature.take 64))
        (sha256 ((signature.drop 64).take 32 ++ List.replicate 32 0))).length = 64 := by
  rw [concatDigests_length]
  decide

theorem publicKeyRoot_preimage_length (input : SourceDepositDataRootInput)
    (hPublicKey : input.publicKey.length = PUBKEY_LENGTH pinnedConfig) :
    (input.publicKey ++ List.replicate 16 0).length = 64 := by
  simp [hPublicKey, PUBKEY_LENGTH, pinnedConfig]

theorem publicKeyWithdrawal_preimage_length (input : SourceDepositDataRootInput)
    (hWithdrawalCredentials : input.withdrawalCredentials.length =
      WITHDRAWAL_CREDENTIALS_LENGTH pinnedConfig) :
    ((sha256 (input.publicKey ++ List.replicate 16 0)).bytes ++
      input.withdrawalCredentials).length = 64 := by
  have hDigest := (sha256 (input.publicKey ++ List.replicate 16 0)).widthPinned
  rw [List.length_append, hDigest, hWithdrawalCredentials]
  decide

theorem amountSignature_preimage_length (input : SourceDepositDataRootInput) :
    (toLittleEndian64 input.amountGwei ++ List.replicate 24 0 ++
      (signatureRoot input).bytes).length = 64 := by
  have hDigest := (signatureRoot input).widthPinned
  simp [toLittleEndian64, hDigest, SHA256_DIGEST_LENGTH, pinnedConfig]

/-- The final `abi.encodePacked(pubkeyRoot', amountRoot)` preimage width. -/
theorem depositDataRoot_preimage_length (input : SourceDepositDataRootInput) :
    (concatDigests
        (sha256 ((sha256 (input.publicKey ++ List.replicate 16 0)).bytes ++
          input.withdrawalCredentials))
        (sha256 (toLittleEndian64 input.amountGwei ++ List.replicate 24 0 ++
          (signatureRoot input).bytes))).length = 64 := by
  rw [concatDigests_length]
  decide

/-! ### Value-bearing digest encoding

`digestBytesFold` is the positional base-257 encoding of a byte stream.  On the
pinned fixed-width digests it is injective, so projecting a digest through it
binds the digest *value*.  This is a structural encoding, not a SHA-256 model. -/

def digestBytesFold : Bytes → Ssz.Node
  | [] => 0
  | b :: bs => b + 257 * digestBytesFold bs

theorem digestBytesFold_injective :
    ∀ {xs ys : Bytes}, xs.length = ys.length →
      (∀ b ∈ xs, b < 257) → (∀ b ∈ ys, b < 257) →
      digestBytesFold xs = digestBytesFold ys → xs = ys := by
  intro xs
  induction xs with
  | nil => intro ys hLength _ _ _; cases ys <;> simp_all
  | cons x xs ih =>
    intro ys hLength hxs hys hFold
    cases ys with
    | nil => simp at hLength
    | cons y ys =>
      have hx : x < 257 := hxs x (List.mem_cons_self ..)
      have hy : y < 257 := hys y (List.mem_cons_self ..)
      have hCons : x + 257 * digestBytesFold xs = y + 257 * digestBytesFold ys := hFold
      have hHead : x = y := by
        have hMod := congrArg (· % 257) hCons
        simpa [Nat.add_mul_mod_self_left, Nat.mod_eq_of_lt hx, Nat.mod_eq_of_lt hy] using hMod
      have hTail : digestBytesFold xs = digestBytesFold ys := by
        have hDiv := congrArg (· / 257) hCons
        simp only [Nat.add_mul_div_left _ _ (by decide : 0 < 257),
          Nat.div_eq_of_lt hx, Nat.div_eq_of_lt hy, Nat.zero_add] at hDiv
        exact hDiv
      have hRest : xs = ys :=
        ih (by simpa using hLength)
          (fun b hb => hxs b (List.mem_cons_of_mem _ hb))
          (fun b hb => hys b (List.mem_cons_of_mem _ hb)) hTail
      simp [hHead, hRest]

/--
Project a pinned-width digest onto a structural node by its *value*.  Distinct
digest values give distinct nodes (`digestNode_injective`), so this projection
cannot collapse to a constant the way the digest length does.
-/
def digestNode (digest : Sha256Digest) : Ssz.Node := digestBytesFold digest.bytes

theorem digestNode_injective (left right : Sha256Digest)
    (h : digestNode left = digestNode right) : left.bytes = right.bytes :=
  digestBytesFold_injective
    (by rw [left.widthPinned, right.widthPinned])
    (fun b hb => Nat.lt_trans (left.bytesBounded b hb) (by decide))
    (fun b hb => Nat.lt_trans (right.bytesBounded b hb) (by decide)) h

/--
The source root used as every abstract structural leaf for this binding.  It
binds the deposit-data-root *digest value*; the constant pinned width is kept
separately in `sourceNodeWidth` so that the two cannot be confused.
-/
def sourceNode (input : SourceDepositDataRootInput) : Ssz.Node :=
  digestNode (computeDepositDataRootWithAmount input)

/-- The constant-section computation, deliberately distinct from `sourceNode`. -/
def sourceNodeWidth (input : SourceDepositDataRootInput) : Nat :=
  (computeDepositDataRootWithAmount input).bytes.length

theorem sourceNodeWidth_pinned (input : SourceDepositDataRootInput) :
    sourceNodeWidth input = SHA256_DIGEST_LENGTH pinnedConfig :=
  (computeDepositDataRootWithAmount input).widthPinned

/--
The leaf bound into the witness is value-bearing: two inputs sharing a source
node share the whole deposit-data-root digest, so a mutation of the
deposit-data-root contents cannot reuse the same structural witness.
-/
theorem sourceNode_injective (left right : SourceDepositDataRootInput)
    (h : sourceNode left = sourceNode right) :
    (computeDepositDataRootWithAmount left).bytes =
      (computeDepositDataRootWithAmount right).bytes :=
  digestNode_injective _ _ h

/-! The structural combiner is deliberately nonconstant: a changed leaf or
branch changes the reconstructed root.  It is a structural encoding, not a
SHA-256 model. -/
def structuralCombine : Ssz.Node → Ssz.Node → Ssz.Node :=
  fun left right => left * 257 + right

/-- The digest encoding is the same nonconstant combiner folded over the bytes. -/
theorem digestBytesFold_cons (b : Nat) (bs : Bytes) :
    digestBytesFold (b :: bs) = structuralCombine (digestBytesFold bs) b := by
  simp [digestBytesFold, structuralCombine, Nat.mul_comm, Nat.add_comm]

def sourceCombine (_input : SourceDepositDataRootInput) : Ssz.Node → Ssz.Node → Ssz.Node :=
  structuralCombine

/-- The pinned construction emitted into the existing structural witness model. -/
def structuralWitness (root : Ssz.Node) : Ssz.ValidatorWitness :=
  { operation := .clValidatorVerifier
    validator := ⟨0, 0, 0, 0, 0, 0, 0, 0⟩
    index := Ssz.operationIndex .clValidatorVerifier
    pivotBoundary := 2
    path := [.right]
    branch := [root] }

def sourceWitness (input : SourceDepositDataRootInput) : Ssz.ValidatorWitness :=
  structuralWitness (sourceNode input)

/--
With the exact pinned constants, the public source-shaped call derives a
signature root from the raw signature and binds the resulting deposit-data-root
node into a nonconstant structural witness.  This does not refine opaque
`sha256`, a precompile, EVM execution, or production validator provenance.
-/
theorem source_pinned_config_discharges_deposit_data_root
    (input : SourceDepositDataRootInput)
    (hPublicKey : input.publicKey.length = PUBKEY_LENGTH pinnedConfig)
    (hWithdrawalCredentials : input.withdrawalCredentials.length =
      WITHDRAWAL_CREDENTIALS_LENGTH pinnedConfig)
    (hSignature : input.signature.length = SIGNATURE_LENGTH pinnedConfig) :
    SHA256_DIGEST_LENGTH pinnedConfig = 32 ∧ PUBKEY_LENGTH pinnedConfig = 48 ∧
    WITHDRAWAL_CREDENTIALS_LENGTH pinnedConfig = 32 ∧ SIGNATURE_LENGTH pinnedConfig = 96 ∧
    DEPOSIT_DATA_LENGTH pinnedConfig = 184 ∧
    signatureRoot input = computeSignatureRoot input.signature ∧
    Ssz.HasGeneralizedIndex (sourceWitness input).index
      (sourceWitness input).pivotBoundary (sourceWitness input).path ∧
    Ssz.traverseBranch (sourceCombine input)
      (Ssz.validatorRoot (sourceCombine input) (sourceWitness input).validator)
      (sourceWitness input).path (sourceWitness input).branch = sourceNode input := by
  refine ⟨rfl, rfl, rfl, rfl, rfl, rfl, ?_, ?_⟩
  simp [sourceWitness, structuralWitness, Ssz.HasGeneralizedIndex, Ssz.operationIndex,
    Ssz.pivot, Ssz.indexFromPivotPath, Ssz.pathOffset]
  decide
  simp [sourceWitness, structuralWitness, sourceCombine, structuralCombine,
    Ssz.traverseBranch, Ssz.validatorRoot]

end LidoSRv3.Audit.Source.DepositDataRootCorrespondence
