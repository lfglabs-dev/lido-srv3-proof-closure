import LidoSRv3.Audit.Source.SszVerifierEntry
import audit.trio.consolidation.LowLevel

/-! Typed CLValidatorVerifier entry with the existing physical-world low-level
STATICCALL primitive. The root response is decoded and consumed by the ensuing
index/leaf/proof computation. This is not the compiled calldata/memory entry.
The SHA interpretation and external contract interpreter remain boundaries. -/
namespace LidoSRv3.Audit.Source.SszRootCall
open SszVerifierEntry SszValidatorLeaf SszWrapperIndex
open TrioReserve1

abbrev toBytes (data : List Byte) : Live.Bytes := data.map fun b => UInt8.ofNat b.toNat
abbrev fromBytes (data : Live.Bytes) : List Byte := data.map fun b => BitVec.ofNat 8 b.toNat

def target : Live.Address := ⟨beaconRootsAddress.toNat, beaconRootsAddress.isLt⟩
def payload (timestamp : BitVec 64) : Live.Bytes := toBytes (timestampPayload timestamp)
def request (caller : Live.Address) (timestamp : BitVec 64) : Live.Request :=
  ⟨caller,target,Live.word 0,payload timestamp⟩

/-- No selector and exactly one zero-extended uint64 ABI word. -/
theorem request_shape (caller : Live.Address) (timestamp : BitVec 64) :
    (request caller timestamp).target.val = 0x000F3df6D732807Ef1319fB7B8bB8522d0Beac02 ∧
    (request caller timestamp).value = Live.word 0 ∧
    (request caller timestamp).payload = toBytes (digestBytes (timestamp.zeroExtend 256)) ∧
    (request caller timestamp).payload.length = 32 := by
  refine ⟨rfl,rfl,rfl,?_⟩
  simp [request,payload,toBytes,timestamp_payload_length]

/-- Existing low-level primitive: a code-less target returns success-empty;
forbidden state change and rejected external execution return failure. -/
def call (external : StaticCall.External) (caller : Live.Address)
    (timestamp : BitVec 64) (world : Live.World) : StaticCall.Result :=
  audit.trio.consolidation.lowLevelStaticCall external caller target (payload timestamp) world

/-- Failed call and successful empty data both hit RootNotFound before ABI
bytes32 decoding. A successful long reply keeps its trailing bytes. -/
def decode (reply : Except Live.Bytes Live.Bytes) : Except SszVerifierEntry.Error Digest :=
  match reply with
  | .error _ => .error .rootNotFound
  | .ok data => decodeRootReply ⟨true,fromBytes data⟩

structure Input where
  scratch : Fin 32 → Byte
  cfg : Configuration
  beacon : BeaconData
  witness : Witness
  proof : List Digest
  offset : Fin wordModulus
  credentials : Digest

/-- The root argument is the actual decoded STATICCALL output, and is passed
as the root of sourceVerify after index and leaf construction. -/
def afterRoot (precompile : Precompile) (input : Input) (root : Digest) :
    Except SszVerifierEntry.Error Unit := do
  let gi ← liftIndex (sourceWrapper input.cfg
    input.beacon.slot.toFin input.offset)
  let leaf ← liftBls (sourceLeaf precompile input.scratch input.witness input.credentials)
  (SszProofFold.sourceVerify (foldHash precompile) gi.index leaf input.proof root).mapError
    SszVerifierEntry.Error.proof

def afterCall (precompile : Precompile) (input : Input)
    (reply : Except Live.Bytes Live.Bytes) : Except SszVerifierEntry.Error Unit := do
  let root ← decode reply
  afterRoot precompile input root

structure Result where
  outcome : Except SszVerifierEntry.Error Unit
  world : Live.World
  attempts : List Live.NestedAttempt

/-- Slot validation executes first; its failure makes no root attempt. The
single low-level call's returned bytes flow through decode into afterRoot.
The static primitive and typed SHA/index/leaf steps have no writable world. -/
def run (precompile : Precompile) (external : StaticCall.External)
    (caller : Live.Address) (input : Input) (world : Live.World) : Result :=
  match sourceSlot precompile input.proof input.beacon.slot input.beacon.proposerIndex with
  | .error reason => ⟨.error reason,world,[]⟩
  | .ok () =>
    let called := call external caller input.beacon.childBlockTimestamp world
    ⟨afterCall precompile input called.outcome,world,called.attempts⟩

private theorem bind_success {ε α β : Type} {step : Except ε α}
    {next : α → Except ε β} {value : β} (h : (step >>= next) = .ok value) :
    ∃ x, step = .ok x ∧ next x = .ok value := by
  cases step with
  | error e => cases h
  | ok x => exact ⟨x,rfl,h⟩

/-- Successful decoding derives call success and the bytes32 length guard. -/
theorem decode_success (reply : Except Live.Bytes Live.Bytes) (root : Digest)
    (h : decode reply = .ok root) :
    ∃ data, reply = .ok data ∧ 32 ≤ data.length ∧ firstWord (fromBytes data) = root := by
  cases reply with
  | error e => cases h
  | ok data =>
    have hd := (root_reply_success_iff ⟨true,fromBytes data⟩ root).mp h
    exact ⟨data,rfl,by simpa [fromBytes] using hd.2.1,hd.2.2⟩

/-- Structural compatibility with the pre-existing typed entry: the same
slot/index/leaf/fold sequence follows any particular returned root reply.
This is only a proof projection, not another call in run. -/
theorem source_entry_projection (precompile : Precompile) (input : Input)
    (reply : RootReply) :
    sourceEntry precompile (fun _ _ => reply) input.scratch input.cfg input.beacon
      input.witness input.proof input.offset input.credentials =
    (do
      sourceSlot precompile input.proof input.beacon.slot input.beacon.proposerIndex
      let root ← decodeRootReply reply
      afterRoot precompile input root) := rfl

theorem afterRoot_success (precompile : Precompile) (input : Input) (root : Digest)
    (h : afterRoot precompile input root = .ok ()) :
    ∃ gi leaf,
      sourceWrapper input.cfg input.beacon.slot.toFin input.offset = .ok gi ∧
      sourceLeaf precompile input.scratch input.witness input.credentials = .ok leaf ∧
      input.proof ≠ [] ∧
      SszProofFold.Branch (foldHash precompile) gi.index.val leaf input.proof root := by
  unfold afterRoot at h
  cases hg : sourceWrapper input.cfg input.beacon.slot.toFin input.offset with
  | error e => simp [hg,liftIndex,Except.mapError,bind,Except.bind] at h
  | ok gi =>
    cases hl : sourceLeaf precompile input.scratch input.witness input.credentials with
    | error e => simp [hg,hl,liftIndex,liftBls,Except.mapError,bind,Except.bind] at h
    | ok leaf =>
      simp only [hg,hl,liftIndex,liftBls,Except.mapError,bind,Except.bind] at h
      have hv : SszProofFold.sourceVerify (foldHash precompile) gi.index leaf input.proof root = .ok () := by
        cases he : SszProofFold.sourceVerify (foldHash precompile) gi.index leaf input.proof root with
        | error e => simp [he] at h
        | ok u => cases u; rfl
      obtain ⟨hn,hb⟩ := (SszProofFold.verify_success_iff _ gi.index leaf root input.proof).mp hv
      exact ⟨gi,leaf,rfl,rfl,hn,hb⟩

/-- Successful nonempty reply can only come from the external execution on a
code-bearing BEACON_ROOTS target. Its exact request is retained once. -/
theorem call_success (external : StaticCall.External) (caller : Live.Address)
    (timestamp : BitVec 64) (world : Live.World) (data : Live.Bytes)
    (h : (call external caller timestamp world).outcome = .ok data)
    (hlen : 32 ≤ data.length) :
    (world.core.codeSize target.val).val ≠ 0 ∧
    external (request caller timestamp) world = .success data ∧
    (call external caller timestamp world).attempts =
      [⟨request caller timestamp,true,true,data,1⟩] := by
  unfold call audit.trio.consolidation.lowLevelStaticCall at h ⊢
  by_cases hc : (world.core.codeSize target.val).val = 0
  · simp only [hc,if_true,Except.ok.injEq] at h
    subst data
    simp at hlen
  · simp only [hc,if_false] at h ⊢
    cases he : external (request caller timestamp) world with
    | success bytes =>
      simp only [request] at he
      rw [he] at h ⊢
      cases h
      exact ⟨hc,rfl,rfl⟩
    | rejected bytes =>
      simp only [request] at he
      rw [he] at h
      cases h
    | forbiddenStateChange =>
      simp only [request] at he
      rw [he] at h
      cases h

/-- Success of the whole ordered entry derives all component successes and
binds the branch root to the bytes returned by its one STATICCALL. -/
theorem run_success (precompile : Precompile) (external : StaticCall.External)
    (caller : Live.Address) (input : Input) (world : Live.World)
    (h : (run precompile external caller input world).outcome = .ok ()) :
    sourceSlot precompile input.proof input.beacon.slot input.beacon.proposerIndex = .ok () ∧
    ∃ data gi leaf,
      (call external caller input.beacon.childBlockTimestamp world).outcome = .ok data ∧
      (world.core.codeSize target.val).val ≠ 0 ∧
      external (request caller input.beacon.childBlockTimestamp) world = .success data ∧
      32 ≤ data.length ∧
      sourceWrapper input.cfg input.beacon.slot.toFin input.offset = .ok gi ∧
      sourceLeaf precompile input.scratch input.witness input.credentials = .ok leaf ∧
      input.proof ≠ [] ∧
      SszProofFold.Branch (foldHash precompile) gi.index.val leaf input.proof (firstWord (fromBytes data)) ∧
      (run precompile external caller input world).attempts =
        [⟨request caller input.beacon.childBlockTimestamp,true,true,data,1⟩] ∧
      (run precompile external caller input world).world = world := by
  cases hs : sourceSlot precompile input.proof input.beacon.slot input.beacon.proposerIndex with
  | error e => simp [run,hs] at h
  | ok u =>
    cases u
    simp only [run,hs] at h
    obtain ⟨root,hd,ha⟩ := bind_success h
    obtain ⟨data,hcall,hlen,hr⟩ := decode_success _ root hd
    obtain ⟨gi,leaf,hg,hl,hn,hb⟩ := afterRoot_success precompile input root ha
    obtain ⟨hc,he,ht⟩ := call_success external caller input.beacon.childBlockTimestamp world data hcall hlen
    refine ⟨rfl,data,gi,leaf,hcall,hc,he,hlen,hg,hl,hn,hr ▸ hb,?_,?_⟩
    · simpa only [run,hs] using ht
    · simp only [run,hs]

theorem slot_failure_no_call (precompile : Precompile) (external : StaticCall.External)
    (caller : Live.Address) (input : Input) (world : Live.World) (reason : SszVerifierEntry.Error)
    (h : sourceSlot precompile input.proof input.beacon.slot input.beacon.proposerIndex = .error reason) :
    run precompile external caller input world = ⟨.error reason,world,[]⟩ := by simp [run,h]

theorem run_world (precompile : Precompile) (external : StaticCall.External)
    (caller : Live.Address) (input : Input) (world : Live.World) :
    (run precompile external caller input world).world = world := by
  unfold run
  split <;> rfl

#print axioms run_success
#print axioms slot_failure_no_call
#print axioms run_world
end LidoSRv3.Audit.Source.SszRootCall
