import LidoSRv3.Audit.Source.SszValidatorLeaf

/-!
Typed ordered composition of CLValidatorVerifier.sol:44-56, 89-108 at core pin
17005714f151e5502c559932319a3f2f74ac2436. External root bytes are consumed,
not replaced by a root-match Boolean. Raw EVM memory/calldata, ABI error bytes,
gas and beacon-root authenticity remain outside this source interpretation.
-/
namespace LidoSRv3.Audit.Source.SszVerifierEntry
open SszValidatorLeaf SszWrapperIndex SszLittleEndianCorrespondence

/-- Literal EIP-4788 destination. -/
def beaconRootsAddress : BitVec 160 := 0x000F3df6D732807Ef1319fB7B8bB8522d0Beac02

/-- uint64 ABI input: one zero-extended big-endian word, without selector. -/
def timestampPayload (timestamp : BitVec 64) : List Byte :=
  digestBytes (timestamp.zeroExtend 256)

/-- First bytes32 word, reconstructed from the bits of the first32 big-endian
bytes. The length check is separate; missing bytes here default to zero. -/
def firstWord (bytes : List Byte) : Digest :=
  (BitVec.ofBoolListLE (List.ofFn fun i : Fin 256 =>
    (bytes[31 - i.val / 8]?.getD 0).getLsbD (i.val % 8))).setWidth 256

theorem first_word_encoded (word : Digest) (trailing : List Byte) :
    firstWord (digestBytes word ++ trailing) = word := by
  apply BitVec.eq_of_getLsbD_eq
  intro i hi
  have hbyte : 31 - i / 8 < 32 := by omega
  have hbit : i % 8 < 8 := Nat.mod_lt _ (by decide)
  have hpos : 8 * (31 - (31 - i / 8)) + i % 8 = i := by omega
  simp only [firstWord, BitVec.getLsbD_setWidth, decide_true, Bool.true_and,
    BitVec.getLsbD_ofBoolListLE, List.getD, List.getElem?_ofFn, hi, dif_pos,
    Option.getD_some]
  rw [List.getElem?_append_left (l₁ := digestBytes word) (l₂ := trailing)
    (by simpa only [digestBytes, List.length_ofFn] using hbyte)]
  simp only [digestBytes, List.getElem?_ofFn, hbyte, dif_pos, Option.getD_some, BitVec.getLsbD_extractLsb',
    hbit, decide_true, Bool.true_and, hpos]

structure RootReply where
  success : Bool
  data : List Byte
  deriving DecidableEq, Repr

/-- Typed read-only staticcall. Destination and complete calldata are observable
inputs. A deterministic oracle does not establish deployment or authenticity. -/
abbrev RootOracle := BitVec 160 → List Byte → RootReply

inductive Error where
  | bls (cause : SszValidatorLeaf.Error)
  | slotOrIndex (cause : SszWrapperIndex.Error)
  | rootNotFound
  | abiDecodeFailure
  | proof (cause : SszProofFold.Error)
  deriving DecidableEq, Repr

def liftBls (result : Except SszValidatorLeaf.Error α) : Except Error α :=
  result.mapError Error.bls

def liftIndex (result : Except SszWrapperIndex.Error α) : Except Error α :=
  result.mapError Error.slotOrIndex

/-- BLS.sha256Pair executes and checks exact returndata size BEFORE the checked
proof.length-2 subtraction and array access. -/
def sourceSlot (precompile : Precompile) (proof : List Digest)
    (slot proposer : BitVec 64) : Except Error Unit := do
  let expected ← liftBls (sourcePair precompile
    (sourceUint256 (slot.zeroExtend 256)) (sourceUint256 (proposer.zeroExtend 256)))
  let actual ← liftIndex (sourceSlotSibling proof)
  if actual = expected then .ok () else .error (.slotOrIndex .invalidSlot)

/-- High-level ABI bytes32 decoding permits trailing data, but not1..31 bytes.
A failed call wins even when its returned bytes would otherwise decode. -/
def decodeRootReply (reply : RootReply) : Except Error Digest :=
  if !reply.success || reply.data.isEmpty then .error .rootNotFound
  else if reply.data.length < 32 then .error .abiDecodeFailure
  else .ok (firstWord reply.data)

def sourceRoot (oracle : RootOracle) (timestamp : BitVec 64) : Except Error Digest :=
  decodeRootReply (oracle beaconRootsAddress (timestampPayload timestamp))

/-- SSZ.verifyProof checks CALL success only, unlike the two BLS helpers.
The output is the typed scratch word: nonstandard short returndata/memory
copying is not modeled and no missing returndata-size guard is invented. -/
def foldHash (precompile : Precompile) : SszProofFold.Hash Digest := fun left right =>
  let reply := precompile (digestBytes left ++ digestBytes right)
  if reply.success then some reply.output else none

structure BeaconData where
  childBlockTimestamp : BitVec 64
  slot : BitVec 64
  proposerIndex : BitVec 64
  deriving DecidableEq, Repr

/-- The same proof, witness, slot and credentials flow through every stage.
All intermediate digests and the generalized index are actually computed. -/
def sourceEntry (precompile : Precompile) (oracle : RootOracle)
    (scratch : Fin 32 → Byte) (cfg : Configuration) (beacon : BeaconData)
    (witness : Witness) (proof : List Digest) (offset : Fin wordModulus)
    (expectedCredentials : Digest) : Except Error Unit := do
  sourceSlot precompile proof beacon.slot beacon.proposerIndex
  let root ← sourceRoot oracle beacon.childBlockTimestamp
  let gi ← liftIndex (sourceWrapper cfg ⟨beacon.slot.toNat, beacon.slot.isLt⟩ offset)
  let leaf ← liftBls (sourceLeaf precompile scratch witness expectedCredentials)
  (SszProofFold.sourceVerify (foldHash precompile) gi.index leaf proof root).mapError Error.proof

theorem timestamp_payload_length (timestamp : BitVec 64) :
    (timestampPayload timestamp).length = 32 := by simp [timestampPayload, digestBytes]

theorem decoded_root_with_suffix (root : Digest) (suffix : List Byte) :
    decodeRootReply ⟨true, digestBytes root ++ suffix⟩ = .ok root := by
  have hlen : (digestBytes root ++ suffix).length = 32 + suffix.length := by
    simp only [digestBytes, List.length_append, List.length_ofFn]
  have hempty : (digestBytes root ++ suffix).isEmpty = false := by
    apply Bool.eq_false_iff.mpr
    intro h
    have := List.isEmpty_iff_length_eq_zero.mp h
    omega
  simp only [decodeRootReply, Bool.not_true, hempty, Bool.or_self, Bool.false_eq_true,
    ↓reduceIte, hlen, show ¬32 + suffix.length < 32 by omega, first_word_encoded]

theorem root_reply_success_iff (reply : RootReply) (root : Digest) :
    decodeRootReply reply = .ok root ↔
      reply.success = true ∧ 32 ≤ reply.data.length ∧ firstWord reply.data = root := by
  cases hs : reply.success with
  | false => simp [decodeRootReply, hs]
  | true =>
    cases he : reply.data.isEmpty with
    | true =>
      have hn := List.isEmpty_iff_length_eq_zero.mp he
      simp [decodeRootReply, hs, he, hn]
    | false =>
      simp only [decodeRootReply, hs, he, Bool.not_true, Bool.or_self,
        Bool.false_eq_true, ↓reduceIte, true_and]
      split <;> simp_all

theorem slot_success_length (precompile : Precompile) (proof : List Digest)
    (slot proposer : BitVec 64)
    (h : sourceSlot precompile proof slot proposer = .ok ()) : 2 ≤ proof.length := by
  by_contra hn
  have hshort : proof.length < 2 := by omega
  unfold sourceSlot at h
  cases hpair : sourcePair precompile (sourceUint256 (slot.zeroExtend 256))
      (sourceUint256 (proposer.zeroExtend 256)) <;>
    simp [hpair, liftBls, liftIndex, Except.mapError, bind, Except.bind, sourceSlotSibling, hshort] at h

theorem source_slot_standard (sha : Sha) (proof : List Digest) (slot proposer : BitVec 64) :
    sourceSlot (standardSha sha) proof slot proposer =
      liftIndex (sourceVerifySlotArithmetic (pair sha) proof slot proposer) := by
  unfold sourceSlot sourceVerifySlotArithmetic
  rw [source_pair_standard]
  cases sourceSlotSibling proof <;>
    simp only [liftBls, liftIndex, Except.mapError, bind, Except.bind]
  split <;> rfl

theorem fold_hash_standard (sha : Sha) :
    foldHash (standardSha sha) = fun a b => some (pair sha a b) := rfl

/-- Root trust is precisely a successful response carrying the independently
computed root bytes at the exact timestamp/address request. -/
theorem root_from_response (oracle : RootOracle) (timestamp : BitVec 64)
    (root : Digest) (suffix : List Byte)
    (hresponse : oracle beaconRootsAddress (timestampPayload timestamp) =
      ⟨true, digestBytes root ++ suffix⟩) : sourceRoot oracle timestamp = .ok root := by
  simp only [sourceRoot, hresponse, decoded_root_with_suffix]

/-- Ordered composition lemma retains actual computation equations; the next
consumer discharges them from a semantic validator/header tree and raw bytes. -/
theorem entry_of_components
    (precompile : Precompile) (oracle : RootOracle) (scratch : Fin 32 → Byte)
    (cfg : Configuration) (beacon : BeaconData) (witness : Witness)
    (proof : List Digest) (offset : Fin wordModulus) (credentials root leaf : Digest)
    (gi : PackedIndex)
    (hs : sourceSlot precompile proof beacon.slot beacon.proposerIndex = .ok ())
    (hr : sourceRoot oracle beacon.childBlockTimestamp = .ok root)
    (hg : sourceWrapper cfg ⟨beacon.slot.toNat, beacon.slot.isLt⟩ offset = .ok gi)
    (hl : sourceLeaf precompile scratch witness credentials = .ok leaf)
    (hv : SszProofFold.sourceVerify (foldHash precompile) gi.index leaf proof root = .ok ()) :
    sourceEntry precompile oracle scratch cfg beacon witness proof offset credentials = .ok () := by
  simp only [sourceEntry, hs, hr, hg, hl, hv, liftIndex, liftBls, Except.mapError,
    bind, Except.bind]

/-- The entry's necessary and sufficient success conditions include the real
returned byte word and an independently constructed ordered Merkle branch.
There is no final-root-match Boolean or assumed computed digest. -/
theorem entry_success_iff
    (precompile : Precompile) (oracle : RootOracle) (scratch : Fin 32 → Byte)
    (cfg : Configuration) (beacon : BeaconData) (witness : Witness)
    (proof : List Digest) (offset : Fin wordModulus) (credentials : Digest) :
    sourceEntry precompile oracle scratch cfg beacon witness proof offset credentials = .ok () ↔
    ∃ root gi leaf,
      sourceSlot precompile proof beacon.slot beacon.proposerIndex = .ok () ∧
      sourceRoot oracle beacon.childBlockTimestamp = .ok root ∧
      sourceWrapper cfg ⟨beacon.slot.toNat, beacon.slot.isLt⟩ offset = .ok gi ∧
      sourceLeaf precompile scratch witness credentials = .ok leaf ∧
      proof ≠ [] ∧ SszProofFold.Branch (foldHash precompile) gi.index.val leaf proof root := by
  unfold sourceEntry
  cases hs : sourceSlot precompile proof beacon.slot beacon.proposerIndex with
  | error e => simp [bind, Except.bind]
  | ok u =>
    cases u
    cases hr : sourceRoot oracle beacon.childBlockTimestamp with
    | error e => simp [bind, Except.bind]
    | ok root =>
      cases hg : sourceWrapper cfg ⟨beacon.slot.toNat, beacon.slot.isLt⟩ offset with
      | error e => simp [liftIndex, Except.mapError, bind, Except.bind]
      | ok gi =>
        cases hl : sourceLeaf precompile scratch witness credentials with
        | error e => simp [liftIndex, liftBls, Except.mapError, bind, Except.bind]
        | ok leaf =>
          simp only [liftIndex, liftBls, Except.mapError, bind, Except.bind, Except.ok.injEq,
            true_and]
          cases hv : SszProofFold.sourceVerify (foldHash precompile) gi.index leaf proof root with
          | error e =>
            have hn : ¬(proof ≠ [] ∧ SszProofFold.Branch (foldHash precompile) gi.index.val leaf proof root) := by
              intro h
              have := (SszProofFold.verify_success_iff _ gi.index leaf root proof).mpr h
              simp [hv] at this
            simp [hn]
          | ok u =>
            cases u
            have hb := (SszProofFold.verify_success_iff _ gi.index leaf root proof).mp hv
            simp [hb]

/-- Necessary successful response and independent branch against the word
actually decoded from that response. The returned bytes, rather than an
assumed match flag, determine the branch root. -/
theorem entry_success_returned_bytes
    (precompile : Precompile) (oracle : RootOracle) (scratch : Fin 32 → Byte)
    (cfg : Configuration) (beacon : BeaconData) (witness : Witness)
    (proof : List Digest) (offset : Fin wordModulus) (credentials : Digest)
    (h : sourceEntry precompile oracle scratch cfg beacon witness proof offset credentials = .ok ()) :
    let reply := oracle beaconRootsAddress (timestampPayload beacon.childBlockTimestamp)
    reply.success = true ∧ 32 ≤ reply.data.length ∧
      ∃ gi leaf,
        sourceWrapper cfg ⟨beacon.slot.toNat, beacon.slot.isLt⟩ offset = .ok gi ∧
        sourceLeaf precompile scratch witness credentials = .ok leaf ∧
        SszProofFold.Branch (foldHash precompile) gi.index.val leaf proof (firstWord reply.data) := by
  obtain ⟨root, gi, leaf, _, hr, hg, hl, _, hb⟩ :=
    (entry_success_iff precompile oracle scratch cfg beacon witness proof offset credentials).mp h
  have hd := (root_reply_success_iff
    (oracle beaconRootsAddress (timestampPayload beacon.childBlockTimestamp)) root).mp hr
  exact ⟨hd.1, hd.2.1, gi, leaf, hg, hl, hd.2.2 ▸ hb⟩

/-- Actual success derives the real pubkey length and the uint248 proof-depth
bound; no artificial list limit is imposed on the model's inputs. -/
theorem entry_success_domains
    (precompile : Precompile) (oracle : RootOracle) (scratch : Fin 32 → Byte)
    (cfg : Configuration) (beacon : BeaconData) (witness : Witness)
    (proof : List Digest) (offset : Fin wordModulus) (credentials : Digest)
    (h : sourceEntry precompile oracle scratch cfg beacon witness proof offset credentials = .ok ()) :
    witness.pubkey.length = 48 ∧ 2 ≤ proof.length ∧ proof.length ≤ 247 := by
  obtain ⟨root, gi, leaf, hs, _, _, hl, hp, hb⟩ :=
    (entry_success_iff precompile oracle scratch cfg beacon witness proof offset credentials).mp h
  have hv := (SszProofFold.verify_success_iff _ gi.index leaf root proof).mpr ⟨hp, hb⟩
  have hd := SszProofFold.verify_depth _ gi.index leaf root proof hv
  exact ⟨leaf_success_length precompile scratch witness credentials leaf hl, slot_success_length precompile proof beacon.slot beacon.proposerIndex hs, hd.2.2⟩

/-- Successful actual entry for the pinned validator/header layout. Structural
state placement is input, not proved protocol reachability. The oracle-response
premise is explicitly trusted; it is not derived from cryptographic anchoring.
The proof is the canonical branch, and leaf/index/root are calculated. -/
theorem validator_entry_consumer
    (sha : Sha) (oracle : RootOracle) (scratch : Fin 32 → Byte)
    (w : Witness) (credentials : Digest) (hlen : w.pubkey.length = 48)
    (pivot : Fin (2 ^ 64)) (beacon : BeaconData)
    (offset : Fin wordModulus) (out : PackedIndex)
    (parentRoot bodyRoot : Digest) (state : Tree Digest)
    (path : List Bool) (stateProof : List Digest) (suffix : List Byte)
    (hw : sourceWrapper (pinnedConfiguration pivot) ⟨beacon.slot.toNat, beacon.slot.isLt⟩ offset = .ok out)
    (hi : SszProofFold.treeIndex path = 150 * 2 ^ 40 + offset.val)
    (hp : treeBranch (pair sha) state path = some stateProof)
    (hplace : subtreeAt state path = some (validatorTree sha w credentials))
    (hresponse : oracle beaconRootsAddress (timestampPayload beacon.childBlockTimestamp) =
      ⟨true, digestBytes (treeDigest (pair sha)
        (headerTree (uint64Chunk beacon.slot) (uint64Chunk beacon.proposerIndex)
          parentRoot bodyRoot 0 state)) ++ suffix⟩) :
    ∃ proof,
      treeBranch (pair sha)
        (headerTree (uint64Chunk beacon.slot) (uint64Chunk beacon.proposerIndex)
          parentRoot bodyRoot 0 state) ([false, true, true] ++ path) = some proof ∧
      proof.length = 50 ∧
      sourceEntry (standardSha sha) oracle scratch (pinnedConfiguration pivot)
        beacon w proof offset credentials = .ok () := by
  obtain ⟨leaf, proof, hl, hb, hlenProof, hv, hs⟩ := validator_header_consumer
    sha scratch w credentials hlen pivot beacon.slot beacon.proposerIndex offset out
    parentRoot bodyRoot state path stateProof hw hi hp hplace
  refine ⟨proof, hb, hlenProof, ?_⟩
  apply entry_of_components (gi := out) (leaf := leaf)
  · rw [source_slot_standard, hs]
    rfl
  · exact root_from_response oracle beacon.childBlockTimestamp _ suffix hresponse
  · exact hw
  · exact hl
  · simpa only [fold_hash_standard] using hv

end LidoSRv3.Audit.Source.SszVerifierEntry
