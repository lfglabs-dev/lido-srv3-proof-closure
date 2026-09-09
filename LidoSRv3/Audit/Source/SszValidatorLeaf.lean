import LidoSRv3.Audit.Source.SszProofFold

/-!
CLValidatorVerifier.sol:60-85, BLS.sol:516-561, core pin
17005714f151e5502c559932319a3f2f74ac2436. This is the actual calldata pubkey
helper and separate expected-credentials argument, not SSZ's memory helper.
Memory and precompile results have typed interpretations below; raw EVM memory,
calldata offsets, gas and deployment correspondence remain outside the model.
-/
namespace LidoSRv3.Audit.Source.SszValidatorLeaf
open SszWrapperIndex
open SszLittleEndianCorrespondence

abbrev Byte := BitVec 8
abbrev Digest := BitVec 256
abbrev Sha := List Byte → Digest

/-- Semantic witness fields. Credentials are intentionally absent: the actual
wrapper takes them from its separate expected-credentials argument. -/
structure Witness where
  pubkey : List Byte
  effectiveBalance : BitVec 64
  slashed : Bool
  activationEligibilityEpoch : BitVec 64
  activationEpoch : BitVec 64
  exitEpoch : BitVec 64
  withdrawableEpoch : BitVec 64
  deriving DecidableEq, Repr

inductive Error where
  | invalidPubkeyLength | sha256PrecompileFailed
  deriving DecidableEq, Repr

/-- Typed staticcall result, including exact returndata size. The word denotes
the output scratch word; it is consumed only after both source checks pass.
This is not a derivation from raw returndata copying or EVM execution. -/
structure ShaReply where
  success : Bool
  returndataSize : Nat
  output : Digest
  deriving DecidableEq, Repr

abbrev Precompile := List Byte → ShaReply

/-- Canonical bytes32 memory/serialization interpretation, high byte first. -/
def digestBytes (word : Digest) : List Byte :=
  List.ofFn fun i : Fin 32 => word.extractLsb' (8 * (31 - i.val)) 8

/-- Source mstore(0x20, 0): the lower half is arbitrary old scratch data. -/
def clearUpper (oldLower : Fin 32 → Byte) : List Byte :=
  List.ofFn oldLower ++ List.replicate 32 0

/-- Source calldatacopy(0, pubkey.offset, 48), after clearing the upper half.
The caller's length guard ensures this is exactly a 48-byte copy. -/
def sourcePubkeyBytes (oldLower : Fin 32 → Byte) (pubkey : List Byte) : List Byte :=
  pubkey.take 48 ++ (clearUpper oldLower).drop 48

/-- Independent SSZ Bytes48 merkleization input. -/
def pubkeyBlock (pubkey : List Byte) : List Byte := pubkey ++ List.replicate 16 0

theorem source_pubkey_padding (oldLower : Fin 32 → Byte) (pubkey : List Byte)
    (h : pubkey.length = 48) : sourcePubkeyBytes oldLower pubkey = pubkeyBlock pubkey := by
  simp [sourcePubkeyBytes, clearUpper, pubkeyBlock,
    List.take_of_length_le (by omega : pubkey.length ≤ 48)]

/-- Both BLS helpers reject failed calls OR any returndata size other than 32.
The digest is actually obtained from the precompile response. -/
def checkedSha (precompile : Precompile) (bytes : List Byte) : Except Error Digest :=
  let reply := precompile bytes
  if reply.success && reply.returndataSize == 32 then .ok reply.output
  else .error .sha256PrecompileFailed

def sourcePubkeyRoot (precompile : Precompile) (oldLower : Fin 32 → Byte)
    (pubkey : List Byte) : Except Error Digest :=
  if pubkey.length ≠ 48 then .error .invalidPubkeyLength
  else checkedSha precompile (sourcePubkeyBytes oldLower pubkey)

/-- Typed interpretation of the two full-word mstores before sha256Pair. -/
def sourcePair (precompile : Precompile) (left right : Digest) : Except Error Digest :=
  checkedSha precompile (digestBytes left ++ digestBytes right)

/-- The actual uint64 integer overload used for slashed, not the bool overload. -/
def sourceSlashed (slashed : Bool) : Digest :=
  sourceUint256 ((if slashed then (1 : BitVec 64) else 0).zeroExtend 256)

/-- The seven source pair calls, in their actual execution order. The helper
parameter keeps byte serialization opaque while proving this finite control flow. -/
def sourceMerkle (hash : Digest → Digest → Except Error Digest)
    (leaf0 leaf1 leaf2 leaf3 leaf4 leaf5 leaf6 leaf7 : Digest) : Except Error Digest := do
  let l10 ← hash leaf0 leaf1
  let l11 ← hash leaf2 leaf3
  let l12 ← hash leaf4 leaf5
  let l13 ← hash leaf6 leaf7
  let l20 ← hash l10 l11
  let l21 ← hash l12 l13
  hash l20 l21

/-- Literal field selection of the actual calldata wrapper. -/
def sourceLeaf (precompile : Precompile) (oldLower : Fin 32 → Byte)
    (w : Witness) (expectedCredentials : Digest) : Except Error Digest := do
  let leaf0 ← sourcePubkeyRoot precompile oldLower w.pubkey
  sourceMerkle (sourcePair precompile) leaf0 expectedCredentials
    (sourceUint256 (w.effectiveBalance.zeroExtend 256)) (sourceSlashed w.slashed)
    (sourceUint256 (w.activationEligibilityEpoch.zeroExtend 256))
    (sourceUint256 (w.activationEpoch.zeroExtend 256))
    (sourceUint256 (w.exitEpoch.zeroExtend 256))
    (sourceUint256 (w.withdrawableEpoch.zeroExtend 256))

/-- Mathematical pair hashing on the same byte-level SHA function. -/
def pair (sha : Sha) (left right : Digest) : Digest :=
  sha (digestBytes left ++ digestBytes right)

/-- Independent SSZ container tree from semantic fields. It receives neither
encoded field chunks, a pubkey digest nor an expected final digest as input. -/
def validatorTree (sha : Sha) (w : Witness) (expectedCredentials : Digest) : Tree Digest :=
  .node
    (.node
      (.node (.leaf (sha (pubkeyBlock w.pubkey))) (.leaf expectedCredentials))
      (.node (.leaf (uint64Chunk w.effectiveBalance)) (.leaf (boolChunk w.slashed))))
    (.node
      (.node (.leaf (uint64Chunk w.activationEligibilityEpoch)) (.leaf (uint64Chunk w.activationEpoch)))
      (.node (.leaf (uint64Chunk w.exitEpoch)) (.leaf (uint64Chunk w.withdrawableEpoch))))

/-- Standard successful SHA adapter. Totality is explicit and is not a theorem
of EVM gas sufficiency; no source precompile-success guard is removed. -/
def standardSha (sha : Sha) : Precompile := fun bytes => ⟨true, 32, sha bytes⟩

theorem checked_sha_success_iff (precompile : Precompile) (bytes : List Byte) (digest : Digest) :
    checkedSha precompile bytes = .ok digest ↔
      (precompile bytes).success = true ∧ (precompile bytes).returndataSize = 32 ∧
      (precompile bytes).output = digest := by
  unfold checkedSha
  dsimp only
  split <;> simp_all

theorem checked_sha_standard (sha : Sha) (bytes : List Byte) :
    checkedSha (standardSha sha) bytes = .ok (sha bytes) := rfl

theorem source_pair_standard (sha : Sha) (left right : Digest) :
    sourcePair (standardSha sha) left right = .ok (pair sha left right) := rfl

theorem source_pubkey_standard (sha : Sha) (oldLower : Fin 32 → Byte)
    (pubkey : List Byte) (h : pubkey.length = 48) :
    sourcePubkeyRoot (standardSha sha) oldLower pubkey = .ok (sha (pubkeyBlock pubkey)) := by
  simp only [sourcePubkeyRoot, h, ne_eq, not_true_eq_false, ↓reduceIte,
    source_pubkey_padding oldLower pubkey h, checked_sha_standard]

theorem pubkey_success_length (precompile : Precompile) (oldLower : Fin 32 → Byte)
    (pubkey : List Byte) (digest : Digest)
    (h : sourcePubkeyRoot precompile oldLower pubkey = .ok digest) : pubkey.length = 48 := by
  unfold sourcePubkeyRoot at h
  split at h
  · contradiction
  · omega

theorem leaf_success_length (precompile : Precompile) (oldLower : Fin 32 → Byte)
    (w : Witness) (expectedCredentials digest : Digest)
    (h : sourceLeaf precompile oldLower w expectedCredentials = .ok digest) : w.pubkey.length = 48 := by
  unfold sourceLeaf at h
  cases hp : sourcePubkeyRoot precompile oldLower w.pubkey with
  | error e => simp [hp, bind, Except.bind] at h
  | ok d => exact pubkey_success_length precompile oldLower w.pubkey d hp

theorem source_slashed_chunk (slashed : Bool) : sourceSlashed slashed = boolChunk slashed := by
  unfold sourceSlashed
  rw [source_uint64_chunk]
  cases slashed <;> decide

/-- Finite pair-call composition with an uninterpreted total pair function.
The separate field/padding theorem below connects the actual byte inputs. -/
theorem source_merkle_pure (hash : Digest → Digest → Digest)
    (a b c d e f g h : Digest) :
    sourceMerkle (fun l r => .ok (hash l r)) a b c d e f g h =
      .ok (hash (hash (hash a b) (hash c d)) (hash (hash e f) (hash g h))) := rfl

/-- Exact admitted and rejected outcomes on standard successful SHA. The leaf
is calculated from the source fields and proved equal to independent SSZ tree
merkleization; the expected root is never an assumption. -/
theorem source_leaf_eq_tree (sha : Sha) (oldLower : Fin 32 → Byte)
    (w : Witness) (expectedCredentials : Digest) :
    sourceLeaf (standardSha sha) oldLower w expectedCredentials =
      if w.pubkey.length = 48 then
        .ok (treeDigest (pair sha) (validatorTree sha w expectedCredentials))
      else .error .invalidPubkeyLength := by
  have hpair : sourcePair (standardSha sha) = fun a b => .ok (pair sha a b) := rfl
  by_cases hlen : w.pubkey.length = 48
  · simp only [if_pos hlen, sourceLeaf, source_pubkey_standard sha oldLower w.pubkey hlen,
      hpair, bind, Except.bind, source_merkle_pure, source_uint64_chunk, source_slashed_chunk,
      validatorTree, treeDigest]
  · simp only [sourceLeaf, sourcePubkeyRoot, hlen, ne_eq, not_false_eq_true,
      ↓reduceIte, bind, Except.bind]

/-- Structural placement of a tree, independent of hashes or verifier outputs. -/
def subtreeAt : Tree α → List Bool → Option (Tree α)
  | tree, [] => some tree
  | .leaf _, _ :: _ => none
  | .node left _, false :: rest => subtreeAt left rest
  | .node _ right, true :: rest => subtreeAt right rest

theorem subtree_digest (hash : α → α → α) (tree subtree : Tree α) (path : List Bool)
    (h : subtreeAt tree path = some subtree) :
    SszProofFold.treeAt hash tree path = some (treeDigest hash subtree) := by
  induction path generalizing tree with
  | nil =>
      simp only [subtreeAt, Option.some.injEq] at h
      subst tree
      cases subtree <;> rfl
  | cons side rest ih =>
      cases tree with
      | leaf value => simp [subtreeAt] at h
      | node left right =>
          cases side
          · exact ih left h
          · exact ih right h

/-- The derived validator leaf is now fed into the delivered header proof
consumer. State-list/container placement is an explicit structural input;
there is no supplied pubkey digest, leaf-digest equality or final-root match.
This composes successful checks, not the full wrapper's failure ordering. -/
theorem validator_header_consumer
    (sha : Sha) (oldLower : Fin 32 → Byte) (w : Witness) (expectedCredentials : Digest)
    (hlen : w.pubkey.length = 48)
    (pivot : Fin (2 ^ 64)) (slot proposer : BitVec 64)
    (offset : Fin wordModulus) (out : PackedIndex)
    (parentRoot bodyRoot : Digest) (state : Tree Digest)
    (path : List Bool) (stateProof : List Digest)
    (hw : sourceWrapper (pinnedConfiguration pivot) ⟨slot.toNat, slot.isLt⟩ offset = .ok out)
    (hi : SszProofFold.treeIndex path = 150 * 2 ^ 40 + offset.val)
    (hp : treeBranch (pair sha) state path = some stateProof)
    (hplace : subtreeAt state path = some (validatorTree sha w expectedCredentials)) :
    let header := headerTree (uint64Chunk slot) (uint64Chunk proposer) parentRoot bodyRoot 0 state
    ∃ leaf proof,
      sourceLeaf (standardSha sha) oldLower w expectedCredentials = .ok leaf ∧
      treeBranch (pair sha) header ([false, true, true] ++ path) = some proof ∧
      proof.length = 50 ∧
      SszProofFold.sourceVerify (fun a b => some (pair sha a b)) out.index leaf proof
        (treeDigest (pair sha) header) = .ok () ∧
      sourceVerifySlotArithmetic (pair sha) proof slot proposer = .ok () := by
  dsimp only
  let leaf := treeDigest (pair sha) (validatorTree sha w expectedCredentials)
  have hleaf := subtree_digest (pair sha) state (validatorTree sha w expectedCredentials) path hplace
  obtain ⟨proof, hpFull, hpLen, hv, hs⟩ := SszProofFold.pinned_encoded_header_verifies
    (pair sha) pivot slot proposer offset out parentRoot bodyRoot leaf state path stateProof hw hi hp hleaf
  refine ⟨leaf, proof, ?_, hpFull, hpLen, hv, hs⟩
  rw [source_leaf_eq_tree, if_pos hlen]

end LidoSRv3.Audit.Source.SszValidatorLeaf
