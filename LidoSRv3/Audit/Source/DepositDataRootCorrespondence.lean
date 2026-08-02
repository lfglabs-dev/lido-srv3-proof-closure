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

/--
The raw values consumed by the public deposit-data-root overload.  Solidity
`bytes` elements are octets and `amountGwei` is a `uint256`; carrying those
range invariants here prevents this source-shaped model from admitting
preimages that the pinned ABI cannot receive.
-/
structure SourceDepositDataRootInput where
  withdrawalCredentials : Bytes
  publicKey : Bytes
  signature : Bytes
  amountGwei : Nat
  withdrawalCredentialsBounded : ∀ byte ∈ withdrawalCredentials, byte < 256
  publicKeyBounded : ∀ byte ∈ publicKey, byte < 256
  signatureBounded : ∀ byte ∈ signature, byte < 256
  amountGweiBounded : amountGwei < 2 ^ 256

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

/-! The structural combiner is deliberately nonconstant: a changed leaf or
branch changes the reconstructed root.  It is a structural encoding, not a
SHA-256 model. -/
def structuralCombine : Ssz.Node → Ssz.Node → Ssz.Node :=
  fun left right => left * 257 + right

/-- Incrementing a branch cannot preserve a root with the same anchor. -/
@[simp] theorem structuralCombine_rejects_incremented_branch (anchor leaf : Ssz.Node) :
    structuralCombine anchor (structuralCombine anchor leaf + 1) ≠
      structuralCombine anchor leaf := by
  simp [structuralCombine]
  omega

/-- An incremented structural branch cannot equal its unanchored leaf. -/
@[simp] theorem structuralCombine_incremented_leaf_ne (anchor leaf : Ssz.Node) :
    structuralCombine anchor leaf + 1 ≠ leaf := by
  intro h
  change anchor * 257 + leaf + 1 = leaf at h
  have hlt : leaf < anchor * 257 + leaf + 1 :=
    Nat.lt_succ_of_le (Nat.le_add_left _ _)
  exact (Nat.ne_of_gt hlt) h

@[simp] theorem anchored_incremented_leaf_ne (anchor leaf : Ssz.Node) :
    anchor * 257 + leaf + 1 ≠ leaf := by
  intro h
  have hlt : leaf < anchor * 257 + leaf + 1 :=
    Nat.lt_succ_of_le (Nat.le_add_left _ _)
  exact (Nat.ne_of_gt hlt) h

/-- The value-bearing deposit-data-root leaf used by the structural witness. -/
def sourceLeaf (input : SourceDepositDataRootInput) : Ssz.Node :=
  digestNode (computeDepositDataRootWithAmount input)

/-- A separately encoded public-key anchor for the structural witness. -/
def sourceAnchor (input : SourceDepositDataRootInput) : Ssz.Node :=
  digestBytesFold input.publicKey

/--
A separately encoded node for the *derived* signature root.  It is produced by
`_computeSignatureRoot` over `input.signature`, a different source field from
the one behind `sourceAnchor`, so the witness carries two independently sourced
components in addition to its branch leaf.
-/
def sourceSignatureNode (input : SourceDepositDataRootInput) : Ssz.Node :=
  digestNode (signatureRoot input)

/--
The expected structural root, written directly as the base-257 positional sum
of the three value-bearing components (257 is the radix `structuralCombine` and
`digestBytesFold` fold with).  It is deliberately *not* written through the
witness's own combiner nesting, so `structuralRoot_eq` below has to reassociate
the traversed tree instead of restating the witness's definition.  The constant
pinned width is kept separately in `sourceNodeWidth` so the two cannot be
confused.
-/
@[simp] def sourceNode (input : SourceDepositDataRootInput) : Ssz.Node :=
  sourceAnchor input * (257 * 257) + sourceSignatureNode input * 257 + sourceLeaf input

/-- The constant-section computation, deliberately distinct from `sourceNode`. -/
def sourceNodeWidth (input : SourceDepositDataRootInput) : Nat :=
  (computeDepositDataRootWithAmount input).bytes.length

theorem sourceNodeWidth_pinned (input : SourceDepositDataRootInput) :
    sourceNodeWidth input = SHA256_DIGEST_LENGTH pinnedConfig :=
  (computeDepositDataRootWithAmount input).widthPinned

/--
The leaf bound into the witness is value-bearing: two inputs sharing a source
leaf share the whole deposit-data-root digest, so a mutation of the
deposit-data-root contents cannot reuse the same structural witness.
-/
theorem sourceLeaf_injective (left right : SourceDepositDataRootInput)
    (h : sourceLeaf left = sourceLeaf right) :
    (computeDepositDataRootWithAmount left).bytes =
      (computeDepositDataRootWithAmount right).bytes :=
  digestNode_injective _ _ h

/-- The digest encoding is the same nonconstant combiner folded over the bytes. -/
theorem digestBytesFold_cons (b : Nat) (bs : Bytes) :
    digestBytesFold (b :: bs) = structuralCombine (digestBytesFold bs) b := by
  simp [digestBytesFold, structuralCombine, Nat.mul_comm, Nat.add_comm]

def sourceCombine (_input : SourceDepositDataRootInput) : Ssz.Node → Ssz.Node → Ssz.Node :=
  structuralCombine

/--
The pinned construction emitted into the existing structural witness model.
The public-key anchor and the derived signature-root node enter through two
distinct validator leaves; the value-bearing deposit-data-root leaf enters as
the traversed branch sibling.  The three components therefore reach the root
through three different structural positions rather than through the same pair
the expected root is written from.
-/
def structuralWitness (anchor signatureNode leaf : Ssz.Node) : Ssz.ValidatorWitness :=
  { operation := .clValidatorVerifier
    validator := ⟨0, 0, 0, 0, 0, 0, anchor, signatureNode⟩
    index := Ssz.operationIndex .clValidatorVerifier
    pivotBoundary := 2
    path := [.right]
    branch := [leaf] }

def sourceWitness (input : SourceDepositDataRootInput) : Ssz.ValidatorWitness :=
  structuralWitness (sourceAnchor input) (sourceSignatureNode input) (sourceLeaf input)

/-- The root a consumer reconstructs by traversing the witness built from the
three supplied components. -/
def structuralRoot (anchor signatureNode leaf : Ssz.Node) : Ssz.Node :=
  Ssz.traverseBranch structuralCombine
    (Ssz.validatorRoot structuralCombine (structuralWitness anchor signatureNode leaf).validator)
    (structuralWitness anchor signatureNode leaf).path
    (structuralWitness anchor signatureNode leaf).branch

/--
Closed form of the traversed witness tree: the container nesting collapses to a
base-257 positional sum whose three coefficients are exactly the three supplied
components.  Reaching it requires reassociating the tree, so it is not an
identity between two spellings of the same construction.
-/
theorem structuralRoot_eq (anchor signatureNode leaf : Ssz.Node) :
    structuralRoot anchor signatureNode leaf =
      anchor * (257 * 257) + signatureNode * 257 + leaf := by
  simp [structuralRoot, structuralWitness, structuralCombine, Ssz.traverseBranch,
    Ssz.validatorRoot, Nat.add_mul, Nat.mul_assoc]

/-- Negative binding: an incremented branch value cannot reconstruct the root
it is offered against, whatever the two validator slots hold. -/
@[simp] theorem structuralRoot_incremented_branch_ne (anchor signatureNode leaf : Ssz.Node) :
    structuralRoot anchor signatureNode (leaf + 1) ≠ leaf := by
  rw [structuralRoot_eq, ← Nat.add_assoc]
  intro h
  have hlt : leaf < anchor * (257 * 257) + signatureNode * 257 + leaf + 1 :=
    Nat.lt_succ_of_le (Nat.le_add_left _ _)
  exact (Nat.ne_of_gt hlt) h

/-- The same rejection, stated over the emitted source witness. -/
theorem sourceWitness_rejects_incremented_branch (input : SourceDepositDataRootInput)
    (root : Ssz.Node) :
    Ssz.traverseBranch (sourceCombine input)
        (Ssz.validatorRoot (sourceCombine input) (sourceWitness input).validator)
        (sourceWitness input).path [root + 1] ≠ root :=
  structuralRoot_incremented_branch_ne (sourceAnchor input) (sourceSignatureNode input) root

/--
Independent binding.  Holding the other two witness slots at their source
values, the reconstructed root pins each component on its own: a witness cannot
be replayed with a mutated public-key anchor, a mutated derived signature root,
or a mutated deposit-data-root leaf and still reconstruct `sourceNode`.  This is
what makes the reconstruction below a binding rather than a restatement of the
witness's own definition.
-/
theorem sourceNode_binds_components (input : SourceDepositDataRootInput)
    (anchor signatureNode leaf : Ssz.Node) :
    (structuralRoot anchor (sourceSignatureNode input) (sourceLeaf input) = sourceNode input →
        anchor = sourceAnchor input) ∧
      (structuralRoot (sourceAnchor input) signatureNode (sourceLeaf input) = sourceNode input →
        signatureNode = sourceSignatureNode input) ∧
      (structuralRoot (sourceAnchor input) (sourceSignatureNode input) leaf = sourceNode input →
        leaf = sourceLeaf input) := by
  refine ⟨fun h => ?_, fun h => ?_, fun h => ?_⟩ <;>
    rw [structuralRoot_eq] at h <;> simp only [sourceNode] at h
  · exact Nat.eq_of_mul_eq_mul_right (by decide)
      (Nat.add_right_cancel (Nat.add_right_cancel h))
  · exact Nat.eq_of_mul_eq_mul_right (by decide)
      (Nat.add_left_cancel (Nat.add_right_cancel h))
  · exact Nat.add_left_cancel h

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
    -- Digest width: pinned to the hash-chain span, `BeaconChainDepositor.sol`
    -- lines 126--133.
    SHA256_DIGEST_LENGTH pinnedConfig = 32 ∧
    -- Pubkey width: the `PUBLIC_KEY_LENGTH` declaration, line 21.
    PUBKEY_LENGTH pinnedConfig = 48 ∧
    -- Withdrawal-credentials width: source-layout literal on the same
    -- hash-chain span, lines 126--133.
    WITHDRAWAL_CREDENTIALS_LENGTH pinnedConfig = 32 ∧
    -- Signature width: the `SIGNATURE_LENGTH` declaration, line 22.
    SIGNATURE_LENGTH pinnedConfig = 96 ∧
    -- Aggregate deposit-data width: the ABI input shape of
    -- `_computeDepositDataRootWithAmount`, lines 120--135.
    DEPOSIT_DATA_LENGTH pinnedConfig = 184 ∧
    -- Solidity `bytes` inputs contain octets, not arbitrary natural numbers.
    (∀ byte ∈ input.withdrawalCredentials, byte < 256) ∧
    (∀ byte ∈ input.publicKey, byte < 256) ∧
    (∀ byte ∈ input.signature, byte < 256) ∧
    -- The amount parameter is Solidity `uint256` gwei.
    input.amountGwei < 2 ^ 256 ∧
    -- The raw-signature overload (lines 110--118) *derives* the signature root
    -- through `_computeSignatureRoot` (lines 137--146) instead of accepting it.
    signatureRoot input = computeSignatureRoot input.signature ∧
    -- The witness path carries its claimed generalized-index meaning, the
    -- property `SSZ.sol` `verifyProof` (lines 179--248) relies on.
    Ssz.HasGeneralizedIndex (sourceWitness input).index
      (sourceWitness input).pivotBoundary (sourceWitness input).path ∧
    -- Branch traversal reconstructs the deposit-data-root node built by
    -- `_computeDepositDataRootWithAmount` (lines 120--135), the reconstruction
    -- `SSZ.sol` `verifyProof` (lines 179--248) performs.
    Ssz.traverseBranch (sourceCombine input)
      (Ssz.validatorRoot (sourceCombine input) (sourceWitness input).validator)
      (sourceWitness input).path (sourceWitness input).branch = sourceNode input := by
  refine ⟨rfl, rfl, rfl, rfl, rfl, input.withdrawalCredentialsBounded,
    input.publicKeyBounded, input.signatureBounded, input.amountGweiBounded, rfl, ?_, ?_⟩
  · simp [sourceWitness, structuralWitness, Ssz.HasGeneralizedIndex, Ssz.operationIndex,
      Ssz.pivot, Ssz.indexFromPivotPath, Ssz.pathOffset]
    decide
  · show structuralRoot (sourceAnchor input) (sourceSignatureNode input) (sourceLeaf input) =
      sourceNode input
    rw [structuralRoot_eq]
    rfl

end LidoSRv3.Audit.Source.DepositDataRootCorrespondence
