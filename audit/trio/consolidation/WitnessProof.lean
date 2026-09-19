import audit.trio.consolidation.GatewayAdmission
import LidoSRv3.Audit.Source.SszBlsComposition
import LidoSRv3.Audit.Source.SszRootCall

/-! Typed executable model of `CLProofVerifier._validatePubKeyWCProof`
(CLProofVerifier.sol:150-175 at core17005714), invoked per group at
ConsolidationGateway.sol:206, on Live.World and in source order:
`_verifySlot` (178-190), the pubkey/credentials leaf (BLS.sol:516-558), the
fork-aware generalized index (CLProofVerifier.sol:192-202, GIndex.sol:22-89),
the EIP-4788 STATICCALL (204-218) and `SSZ.verifyProof` (SSZ.sol:179-249).

SHA-256 is the opaque engine FFI `shaOutput` (A-SHA256-FFI); the source's two
returndata-size guards are executed, `SSZ.verifyProof` has none. The Merkle
fold is P-SSZ-1's typed `SszProofFold.sourceVerify` under its `ffiPair`, and
the index is P-SSZ-1's source transcription of `shr`/`concat`; neither is
re-proved here. The beacon root is the bytes the accepted StaticCall.External
returns for the pinned BEACON_ROOTS request on the entry World; its
authenticity is a premise, not a conclusion. Precompile-2 STATICCALLs are not
journaled; the EIP-4788 STATICCALL is. No world is written. -/
set_option autoImplicit false
namespace audit.trio.consolidation.WitnessProof
open LidoSRv3.Audit.Source
open LidoSRv3.Audit.Source.TrioReserve1 LidoSRv3.Audit.Source.TrioReserve1.Live
open EvmYul SszWrapperIndex

/-- `IPredepositGuarantee.ValidatorWitness` after ABI decoding: proof words,
raw pubkey bytes, validatorIndex, childBlockTimestamp, slot, proposerIndex. -/
structure ValidatorWitness where
  proof : List UInt256
  pubkey : Bytes
  validatorIndex : UInt256
  childBlockTimestamp : BitVec 64
  provenSlot : BitVec 64
  proposerIndex : BitVec 64

/-- `ConsolidationWitnessGroup`: source pubkeys and the target witness. -/
structure WitnessGroup where
  sources : List Bytes
  witness : ValidatorWitness

/-- The producer input of the retained executor: `targetWitness.pubkey`
(`_prepareConsolidationPairs`, ConsolidationGateway.sol:357). -/
def WitnessGroup.bytes (g : WitnessGroup) : WitnessGroupBytes := ⟨g.sources,g.witness.pubkey⟩

def shaFailed : Fault := .bubbled (encode 4 0xdd5cab3e)
def invalidPubkeyLength : Fault := .bubbled (encode 4 0x9ca717ed)
def invalidSlot : Fault := .bubbled (encode 4 0x1258e443)
def rootNotFound : Fault := .bubbled (encode 4 0x3033b0ff)
def indexOutOfRange : Fault := .bubbled (encode 4 0x1390f2a1)
def invalidProof : Fault := .bubbled (encode 4 0x09bde339)
def extraItem : Fault := .bubbled (encode 4 0x5849603f)
def missingItem : Fault := .bubbled (encode 4 0x1b6661c3)

/-- Line 378: `bytes32(COMPOUNDING_PREFIX | uint160(vaultAddress))` as the
verifier's word. -/
def credentialsWord (vault : Address) : UInt256 :=
  UInt256.ofNat (GatewayPreconditions.compoundingPrefix ||| vault.val)

/-- BLS.sha256Pair (516-534): one precompile call whose output must be
exactly 32 bytes; the digest is the opaque engine's. -/
def sha256Pair (left right : UInt256) : Except Fault UInt256 :=
  let out := SszShaCallMemory.shaOutput
    (SszWordBytes.fixedBE 32 left.toNat ++ SszWordBytes.fixedBE 32 right.toNat)
  if out.size = 32 then .ok (UInt256.ofNat (fromByteArrayBigEndian out)) else .error shaFailed

/-- An accepted pair is P-SSZ-1's `pairDigest`, the digest its `ffiPair` folds. -/
theorem sha256Pair_success (left right d : UInt256) (h : sha256Pair left right = .ok d) :
    d = SszBlsComposition.pairDigest left right ∧
    SszProofCalldataStep.ffiPair left right = some d := by
  unfold sha256Pair at h
  try dsimp only at h
  split at h
  · cases h; exact ⟨rfl,rfl⟩
  · contradiction

/-- BLS.pubkeyRoot (538-558): 48 key octets then 16 zero bytes. -/
def pubkeyBlock (pubkey : Bytes) : ByteArray := ⟨(pubkey ++ List.replicate 16 0).toArray⟩

def pubkeyRoot (pubkey : Bytes) : Except Fault UInt256 :=
  if pubkey.length ≠ 48 then .error invalidPubkeyLength else
  let out := SszShaCallMemory.shaOutput (pubkeyBlock pubkey)
  if out.size = 32 then .ok (UInt256.ofNat (fromByteArrayBigEndian out)) else .error shaFailed

/-- The pure digest of an accepted 48-byte key. -/
def pubkeyDigest (pubkey : Bytes) : UInt256 :=
  UInt256.ofNat (fromByteArrayBigEndian (SszShaCallMemory.shaOutput (pubkeyBlock pubkey)))

theorem pubkeyRoot_success (pubkey : Bytes) (d : UInt256) (h : pubkeyRoot pubkey = .ok d) :
    pubkey.length = 48 ∧ d = pubkeyDigest pubkey := by
  unfold pubkeyRoot at h
  split at h
  · contradiction
  · rename_i hl
    try dsimp only at h
    split at h
    · cases h; exact ⟨by omega,rfl⟩
    · contradiction

/-- Line 163: `sha256Pair(pubkeyRoot(pubkey), withdrawalCredentials)`. -/
def leaf (pubkey : Bytes) (credentials : UInt256) : Except Fault UInt256 := do
  let root ← pubkeyRoot pubkey
  sha256Pair root credentials

/-- The pure leaf of an accepted key: the pair digest of the key digest and
the credentials word. -/
def leafDigest (pubkey : Bytes) (credentials : UInt256) : UInt256 :=
  SszBlsComposition.pairDigest (pubkeyDigest pubkey) credentials

theorem leaf_success (pubkey : Bytes) (credentials l : UInt256)
    (h : leaf pubkey credentials = .ok l) :
    pubkey.length = 48 ∧ l = leafDigest pubkey credentials := by
  unfold leaf at h
  cases hr : pubkeyRoot pubkey with
  | «error» f => simp [hr,bind,Except.bind] at h
  | ok root =>
    simp only [hr,bind,Except.bind] at h
    obtain ⟨hl,hd⟩ := pubkeyRoot_success _ _ hr
    obtain ⟨hp,_⟩ := sha256Pair_success _ _ _ h
    subst hp
    subst hd
    exact ⟨hl,rfl⟩

/-- CLProofVerifier.sol:178-190: `proof[proof.length - 2]` must equal the pair
digest of the little-endian slot and proposer words. The pair SHA precedes the
checked subtraction (panic 0x11) and the bounds check (panic 0x32). -/
def verifySlot (w : ValidatorWitness) : Except Fault Unit := do
  let expected ← sha256Pair (SszBlsComposition.chunk w.provenSlot) (SszBlsComposition.chunk w.proposerIndex)
  if w.proof.length < 2 then .error PhysicalQuotaSettlement.arithmetic else
  match w.proof[w.proof.length - 2]? with
  | none => .error (.bubbled (GatewayCall.panic 0x32))
  | some actual => if actual = expected then .ok () else .error invalidSlot

theorem verifySlot_success (w : ValidatorWitness) (h : verifySlot w = .ok ()) :
    2 ≤ w.proof.length ∧
    w.proof[w.proof.length - 2]? = some (SszBlsComposition.pairDigest
      (SszBlsComposition.chunk w.provenSlot) (SszBlsComposition.chunk w.proposerIndex)) := by
  unfold verifySlot at h
  cases he : sha256Pair (SszBlsComposition.chunk w.provenSlot) (SszBlsComposition.chunk w.proposerIndex) with
  | «error» f => simp [he,bind,Except.bind] at h
  | ok expected =>
    simp only [he,bind,Except.bind] at h
    obtain ⟨hd,_⟩ := sha256Pair_success _ _ _ he
    split at h
    · contradiction
    · rename_i hl
      split at h
      · contradiction
      · next actual hget =>
        split at h
        · next heq => exact ⟨by omega,by rw [hget,heq,hd]⟩
        · contradiction

/-- `GI_PUBKEY_WC_PARENT = pack(4, 2)` (CLProofVerifier.sol:57-59). -/
def pubkeyWcParent : PackedIndex := ⟨⟨4,by decide⟩,⟨2,by decide⟩⟩

/-- GIndex.sol reverts: checked arithmetic panics, `IndexOutOfRange()`. -/
def liftIndex {α : Type} : Except SszWrapperIndex.Error α → Except Fault α
  | .ok a => .ok a
  | .error .arithmeticPanic => .error PhysicalQuotaSettlement.arithmetic
  | .error .indexOutOfRange => .error indexOutOfRange
  | .error .invalidSlot => .error invalidSlot

theorem liftIndex_success {α : Type} (r : Except SszWrapperIndex.Error α) (a : α)
    (h : liftIndex r = .ok a) : r = .ok a := by
  cases r with
  | ok b => simpa [liftIndex] using h
  | «error» e => cases e <;> simp [liftIndex] at h

/-- CLProofVerifier.sol:165-168 with 192-202: `concat(GI_STATE_ROOT,
concat(_getValidatorGI(validatorIndex, slot), GI_PUBKEY_WC_PARENT))`, the
fork-aware base selected by `slot < PIVOT_SLOT`, through P-SSZ-1's source
transcriptions of `GIndex.shr` and `GIndex.concat`. -/
def gatewayIndex (cfg : Configuration) (w : ValidatorWitness) : Except Fault PackedIndex :=
  match liftIndex (sourceNeighbor (selected cfg w.provenSlot.toFin)
      ⟨w.validatorIndex.toNat,w.validatorIndex.val.isLt⟩) with
  | .error f => .error f
  | .ok validator =>
    match liftIndex (sourceConcat validator pubkeyWcParent) with
    | .error f => .error f
    | .ok inner => liftIndex (sourceConcat stateRootIndex inner)

theorem gatewayIndex_success (cfg : Configuration) (w : ValidatorWitness) (gi : PackedIndex)
    (h : gatewayIndex cfg w = .ok gi) :
    ∃ validator inner,
      sourceNeighbor (selected cfg w.provenSlot.toFin) ⟨w.validatorIndex.toNat,w.validatorIndex.val.isLt⟩ =
        .ok validator ∧
      sourceConcat validator pubkeyWcParent = .ok inner ∧
      sourceConcat stateRootIndex inner = .ok gi := by
  unfold gatewayIndex at h
  cases hv : liftIndex (sourceNeighbor (selected cfg w.provenSlot.toFin)
      ⟨w.validatorIndex.toNat,w.validatorIndex.val.isLt⟩) with
  | «error» f => simp [hv] at h
  | ok validator =>
    simp only [hv] at h
    cases hi : liftIndex (sourceConcat validator pubkeyWcParent) with
    | «error» f => simp [hi] at h
    | ok inner =>
      simp only [hi] at h
      exact ⟨validator,inner,liftIndex_success _ _ hv,liftIndex_success _ _ hi,
        liftIndex_success _ _ h⟩

/-- CLProofVerifier.sol:210-217: a failed call or empty data reverts
`RootNotFound()`; `abi.decode(data, (bytes32))` needs 32 bytes (else an empty
revert) and keeps the first word, ignoring trailing bytes. -/
def decodeRoot (reply : Except Bytes Bytes) : Except Fault UInt256 :=
  match reply with
  | .error _ => .error rootNotFound
  | .ok data =>
    if data.length = 0 then .error rootNotFound
    else if data.length < 32 then .error .empty
    else .ok (SszTypedFfiBridge.toWord (SszVerifierEntry.firstWord (SszRootCall.fromBytes data)))

theorem decodeRoot_success (reply : Except Bytes Bytes) (root : UInt256)
    (h : decodeRoot reply = .ok root) :
    ∃ data, reply = .ok data ∧ 32 ≤ data.length ∧
      root = SszTypedFfiBridge.toWord (SszVerifierEntry.firstWord (SszRootCall.fromBytes data)) := by
  cases reply with
  | «error» e => simp [decodeRoot] at h
  | ok data =>
    unfold decodeRoot at h
    by_cases h0 : data.length = 0
    · simp [h0] at h
    · by_cases h32 : data.length < 32
      · simp [h0,h32] at h
      · simp only [h0,h32,↓reduceIte,Except.ok.injEq] at h
        exact ⟨data,rfl,by omega,h.symm⟩

/-- The one EIP-4788 STATICCALL of a check: P-SSZ-1's request on the pinned
BEACON_ROOTS address through the existing low-level static primitive. -/
theorem call_success (sexternal : StaticCall.External) (caller : Address)
    (timestamp : BitVec 64) (world : World) (data : Bytes)
    (h : (SszRootCall.call sexternal caller timestamp world).outcome = .ok data) :
    SszRootCall.call sexternal caller timestamp world =
      ⟨.ok data,[⟨SszRootCall.request caller timestamp,true,true,data,1⟩]⟩ := by
  unfold SszRootCall.call at h ⊢
  rcases lowLevelStaticCall_shape sexternal caller SszRootCall.target
      (SszRootCall.payload timestamp) world with
    ⟨_,he⟩ | ⟨_,⟨raw,_,he⟩ | ⟨raw,_,he⟩ | ⟨_,he⟩⟩
  · simp only [he] at h
    have hd : [] = data := by simpa using h
    subst hd
    exact he.trans rfl
  · simp only [he] at h
    have hd : raw = data := by simpa using h
    subst hd
    exact he.trans rfl
  · simp [he] at h
  · simp [he] at h

/-- SSZ.sol reverts: `InvalidProof()`, `BranchHasExtraItem()`, a failed
precompile call (`revert(0, 0)`), `BranchHasMissingItem()`. -/
def liftFold : Except SszProofFold.Error Unit → Except Fault Unit
  | .ok () => .ok ()
  | .error .invalidProof => .error invalidProof
  | .error .extraItem => .error extraItem
  | .error .hashFailure => .error .empty
  | .error .missingItem => .error missingItem

theorem liftFold_success (r : Except SszProofFold.Error Unit) (h : liftFold r = .ok ()) :
    r = .ok () := by
  cases r with
  | ok u => cases u; rfl
  | «error» e => cases e <;> simp [liftFold] at h

structure CheckResult where
  outcome : Except Fault Unit
  attempts : List NestedAttempt

/-- Lines 150-175 in source order on the entry World. -/
def validate (sexternal : StaticCall.External) (cfg : Configuration) (ctx : Context)
    (credentials : UInt256) (w : ValidatorWitness) (world : World) : CheckResult :=
  match verifySlot w with
  | .error f => ⟨.error f,[]⟩
  | .ok () =>
  match leaf w.pubkey credentials with
  | .error f => ⟨.error f,[]⟩
  | .ok l =>
  match gatewayIndex cfg w with
  | .error f => ⟨.error f,[]⟩
  | .ok gi =>
    let called := SszRootCall.call sexternal ctx.self w.childBlockTimestamp world
    match decodeRoot called.outcome with
    | .error f => ⟨.error f,called.attempts⟩
    | .ok root =>
      ⟨liftFold (SszProofFold.sourceVerify SszProofCalldataStep.ffiPair gi.index l w.proof root),
        called.attempts⟩

/-- What a passed check establishes: the slot/proposer sibling, the accepted
48-byte key, the executed fork-aware generalized index, the executed EIP-4788
STATICCALL with its 32-byte reply, and P-SSZ-1's independent Merkle branch from
the key/credentials leaf to the received root under the opaque pair digest. -/
def Passed (sexternal : StaticCall.External) (cfg : Configuration) (ctx : Context)
    (credentials : UInt256) (w : ValidatorWitness) (world : World) : Prop :=
  2 ≤ w.proof.length ∧
  w.proof[w.proof.length - 2]? = some (SszBlsComposition.pairDigest
    (SszBlsComposition.chunk w.provenSlot) (SszBlsComposition.chunk w.proposerIndex)) ∧
  w.pubkey.length = 48 ∧
  ∃ gi data,
    gatewayIndex cfg w = .ok gi ∧
    SszRootCall.call sexternal ctx.self w.childBlockTimestamp world =
      ⟨.ok data,[⟨SszRootCall.request ctx.self w.childBlockTimestamp,true,true,data,1⟩]⟩ ∧
    32 ≤ data.length ∧
    SszProofFold.Branch SszProofCalldataStep.ffiPair gi.index.val
      (leafDigest w.pubkey credentials) w.proof
      (SszTypedFfiBridge.toWord (SszVerifierEntry.firstWord (SszRootCall.fromBytes data)))

theorem validate_success (sexternal : StaticCall.External) (cfg : Configuration)
    (ctx : Context) (credentials : UInt256) (w : ValidatorWitness) (world : World)
    (h : (validate sexternal cfg ctx credentials w world).outcome = .ok ()) :
    Passed sexternal cfg ctx credentials w world ∧
    ∃ data, (validate sexternal cfg ctx credentials w world).attempts =
      [⟨SszRootCall.request ctx.self w.childBlockTimestamp,true,true,data,1⟩] := by
  unfold validate at h ⊢
  cases hs : verifySlot w with
  | «error» f => simp [hs] at h
  | ok u =>
    cases u
    simp only [hs] at h ⊢
    cases hl : leaf w.pubkey credentials with
    | «error» f => simp [hl] at h
    | ok l =>
      simp only [hl] at h ⊢
      cases hg : gatewayIndex cfg w with
      | «error» f => simp [hg] at h
      | ok gi =>
        simp only [hg] at h ⊢
        try dsimp only at h ⊢
        cases hr : decodeRoot (SszRootCall.call sexternal ctx.self w.childBlockTimestamp world).outcome with
        | «error» f => simp [hr] at h
        | ok root =>
          simp only [hr] at h ⊢
          obtain ⟨data,hcall,hlen,hroot⟩ := decodeRoot_success _ _ hr
          have hc := call_success sexternal ctx.self w.childBlockTimestamp world data hcall
          obtain ⟨h2,hsib⟩ := verifySlot_success w hs
          obtain ⟨h48,hleaf⟩ := leaf_success _ _ _ hl
          have hv := liftFold_success _ h
          obtain ⟨_,hb⟩ := (SszProofFold.verify_success_iff _ _ _ _ _).mp hv
          subst hleaf
          subst hroot
          exact ⟨⟨h2,hsib,h48,gi,data,hg,hc,hlen,hb⟩,data,by rw [hc]⟩

/-- ConsolidationGateway.sol:205-207: every group's target witness against the
vault's 0x02 credentials, in order, on the unchanged entry World. -/
def validateAll (sexternal : StaticCall.External) (cfg : Configuration) (ctx : Context)
    (credentials : UInt256) : List WitnessGroup → World → CheckResult
  | [], _ => ⟨.ok (),[]⟩
  | g :: gs, world =>
    let r := validate sexternal cfg ctx credentials g.witness world
    match r.outcome with
    | .error f => ⟨.error f,r.attempts⟩
    | .ok () =>
      let rest := validateAll sexternal cfg ctx credentials gs world
      ⟨rest.outcome,r.attempts ++ rest.attempts⟩

theorem validateAll_success (sexternal : StaticCall.External) (cfg : Configuration)
    (ctx : Context) (credentials : UInt256) (groups : List WitnessGroup) (world : World)
    (h : (validateAll sexternal cfg ctx credentials groups world).outcome = .ok ()) :
    ∀ g ∈ groups, Passed sexternal cfg ctx credentials g.witness world := by
  induction groups with
  | nil => intro g hg; simp at hg
  | cons g gs ih =>
    intro x hx
    simp only [validateAll] at h
    cases hv : (validate sexternal cfg ctx credentials g.witness world).outcome with
    | «error» f => simp [hv] at h
    | ok u =>
      cases u
      simp only [hv] at h
      rcases List.mem_cons.mp hx with rfl | hmem
      · exact (validate_success _ _ _ _ _ _ hv).1
      · exact ih h x hmem

#print axioms sha256Pair_success
#print axioms leaf_success
#print axioms verifySlot_success
#print axioms gatewayIndex_success
#print axioms decodeRoot_success
#print axioms call_success
#print axioms validate_success
#print axioms validateAll_success
end audit.trio.consolidation.WitnessProof
