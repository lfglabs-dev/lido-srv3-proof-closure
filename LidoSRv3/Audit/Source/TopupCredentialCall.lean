import LidoSRv3.Audit.Guarantees.PTopupMemoryCalls
import audit.trio.consolidation.LowLevel

/-! The covered TOPUP phase begins with the existing typed length/config guards,
then the actual gateway-to-router credentials STATICCALL and prefix02 check.
The resolved word replaces Environment.credentials before the actual witness,
module and physical continuation. Role/pause/timing/locator, the gateway-to-
router topUp CALL, initial memory provenance/copy/aliasing and gas remain outside.
Both cursors are explicit phase inputs; their relationship is not asserted. -/
set_option autoImplicit false
namespace LidoSRv3.Audit.Source.TopupCredentialCall
open TrioReserve1 Live TopupGatewayWitnessBatch
open TopupGatewayRootCalls (Environment)
open audit.trio.deposit.ModuleCall (finalizeAllocation)

def selector : Nat := 0xf85c6ceb

def request (gateway router : Address) (moduleId : Word) : Request :=
  ⟨gateway,router,word 0,encode 4 selector ++ encode 32 moduleId.val⟩

/-- IR copies min(32,returndatasize), finalizes allocation before its signed
head check, then loads the unrestricted bytes32. The copied size is at most32,
so the wrapped ADD/SUB signed check equals this natural comparison. -/
def decodeCredentials (cursor : Word) (raw : Bytes) : Except Fault (Word × Word) := do
  let copied := min 32 (word raw.length).val
  let next ← finalizeAllocation cursor copied
  if copied < 32 then .error .empty else .ok (word (decode (raw.take 32)),next)

theorem copied_signed_guard (cursor : Word) (raw : Bytes) :
    audit.trio.deposit.ModuleCall.signedLt
      (word ((word (cursor.val + (min 32 (word raw.length).val))).val + 2^256 - cursor.val))
      (word 32) = decide (min 32 (word raw.length).val < 32) := by
  have hb : min 32 (word raw.length).val < 2^255 := by omega
  have hw : (word (min 32 (word raw.length).val)).val = min 32 (word raw.length).val := by
    change _ % 2^256 = _; apply Nat.mod_eq_of_lt; omega
  have he := audit.trio.deposit.ModuleCall.end_sub_base cursor (word (min 32 (word raw.length).val))
  rw [hw] at he
  rw [he]
  unfold audit.trio.deposit.ModuleCall.signedLt
  rw [show audit.trio.deposit.ModuleCall.signed (word 32) = 32 from by decide +kernel]
  simp only [audit.trio.deposit.ModuleCall.signed,hw,if_pos hb]
  by_cases h : min 32 (word raw.length).val < 32
  · have hi : Int.ofNat (min 32 (word raw.length).val) < 32 := by simpa only [Int.ofNat_eq_natCast] using (show ((min 32 (word raw.length).val : Nat) : Int) < 32 from by omega)
    simp only [h,hi,decide_true]
  · have hi : ¬ Int.ofNat (min 32 (word raw.length).val) < 32 := by simpa only [Int.ofNat_eq_natCast] using (show ¬ ((min 32 (word raw.length).val : Nat) : Int) < 32 from by omega)
    simp only [h,hi,decide_false]

theorem decode_fields (cursor : Word) (raw : Bytes) (wc next : Word)
    (h : decodeCredentials cursor raw = .ok (wc,next)) :
    32 ≤ (word raw.length).val ∧ wc = word (decode (raw.take 32)) ∧
    finalizeAllocation cursor 32 = .ok next ∧ cursor.val + 32 = next.val ∧ next.val < 2^64 := by
  unfold decodeCredentials at h
  cases ha : finalizeAllocation cursor (min 32 (word raw.length).val) with
  | «error» e => simp [ha,bind,Except.bind] at h
  | ok ptr =>
    simp only [ha,bind,Except.bind] at h
    split at h
    · cases h
    · rename_i hl
      have hs : 32 ≤ (word raw.length).val := by omega
      have hm : min 32 (word raw.length).val = 32 := by omega
      cases h
      rw [hm] at ha
      obtain ⟨hb,_,he⟩ := audit.trio.deposit.ModuleCall.finalizeAllocation_ok cursor next 32 ha
      have heq : next.val = cursor.val + 32 := by
        rw [he]
        change (cursor.val + 32) % 2^256 = _
        apply Nat.mod_eq_of_lt
        have hc := cursor.isLt
        obtain ⟨_,hmono,_⟩ := audit.trio.deposit.ModuleCall.finalizeAllocation_ok cursor next 32 ha
        change cursor.val < 2^256 at hc
        omega
      exact ⟨hs,rfl,ha,heq.symm,hb⟩

structure LookupResult where
  outcome : Except Fault (Word × Word)
  attempts : List NestedAttempt
  deriving DecidableEq

/-- Ordinary no-code transport succeeds empty and reaches allocation/decoder.
No 0.8.9 EXTCODESIZE precheck is inserted; precompiles retain the inherited
lowLevelStaticCall boundary. The getter exposes no writable reply World. -/
def lookup (getter : StaticCall.External) (gateway router : Address) (moduleId cursor : Word)
    (before : World) : LookupResult :=
  let r := audit.trio.consolidation.lowLevelStaticCall getter gateway router
    (request gateway router moduleId).payload before
  match r.outcome with
  | .error bytes => ⟨.error (.bubbled bytes),r.attempts⟩
  | .ok raw => ⟨decodeCredentials cursor raw,r.attempts⟩

theorem lookup_origin (getter : StaticCall.External) (gateway router : Address)
    (moduleId cursor : Word) (before : World) (wc next : Word) (trace : List NestedAttempt)
    (h : lookup getter gateway router moduleId cursor before = ⟨.ok (wc,next),trace⟩) :
    (before.core.codeSize router.val).val ≠ 0 ∧ ∃ raw,
      getter (request gateway router moduleId) before = .success raw ∧
      decodeCredentials cursor raw = .ok (wc,next) ∧
      32 ≤ (word raw.length).val ∧ wc = word (decode (raw.take 32)) ∧
      finalizeAllocation cursor 32 = .ok next ∧ cursor.val + 32 = next.val ∧ next.val < 2^64 ∧
      trace = [⟨request gateway router moduleId,true,true,raw,1⟩] := by
  unfold lookup audit.trio.consolidation.lowLevelStaticCall at h
  by_cases hc : (before.core.codeSize router.val).val = 0
  · simp only [hc,if_true] at h
    have hd := congrArg LookupResult.outcome h
    have hb := (decode_fields cursor [] wc next hd).1
    norm_num [word,Verity.Core.Uint256.modulus,Verity.Core.UINT256_MODULUS] at hb
  · simp only [hc,if_false] at h
    cases hr : getter (request gateway router moduleId) before with
    | rejected data => simp only [request] at hr h; simp [hr] at h
    | forbiddenStateChange => simp only [request] at hr h; simp [hr] at h
    | success raw =>
      simp only [request] at hr h
      simp only [hr] at h
      have hd := congrArg LookupResult.outcome h
      have ht := congrArg LookupResult.attempts h
      obtain ⟨hl,hv,ha,he,hb⟩ := decode_fields cursor raw wc next hd
      exact ⟨hc,raw,rfl,hd,hl,hv,ha,he,hb,ht.symm⟩

def resolved (e : Environment) (wc : Word) : Environment :=
  {e with credentials := BitVec.ofNat 256 wc.val}

inductive Error where
  | lengths (fault : GatewayFault)
  | lookup (fault : Fault)
  | wrongWithdrawalCredentials
  | batch (fault : TopupBatchRootCalls.Error)
  deriving DecidableEq, Repr

structure Result where
  outcome : Except Error Unit
  world : World
  credentialAttempts : List NestedAttempt
  rootAttempts : List NestedAttempt
  moduleAttempts : List Attempt

/-- Same downstream result projected without replacing its world or journal. -/
def ofBatch (trace : List NestedAttempt) (r : TopupBatchRootCalls.Result) : Result :=
  ⟨r.outcome.mapError Error.batch,r.world,trace,r.rootAttempts,r.moduleAttempts⟩

def Result.observations (r : Result) : List (Sum NestedAttempt Attempt) :=
  (r.credentialAttempts ++ r.rootAttempts).map Sum.inl ++ r.moduleAttempts.map Sum.inr

def run (getter : StaticCall.External) (credentialCursor returnBuffer : Word)
    (hash : TopupRouterCredentials.Keccak) (m x : External) (e : Environment) (ctx : Context)
    (deposit : Address) (moduleId : Word) (keys operators : List Word) (rows : List Row)
    (allocation : Word) : Result :=
  match checkLengths (TopupBatchRootCalls.environment e).cfg rows.length keys.length operators.length rows.length rows.length with
  | .error fault => ⟨.error (.lengths fault),e.before,[],[],[]⟩
  | .ok () =>
    let q := lookup getter e.gateway ctx.sender moduleId credentialCursor e.before
    match q.outcome with
    | .error fault => ⟨.error (.lookup fault),e.before,q.attempts,[],[]⟩
    | .ok (wc,_) =>
      if wc.val / 2^248 ≠ 2 then ⟨.error .wrongWithdrawalCredentials,e.before,q.attempts,[],[]⟩ else
      ofBatch q.attempts (TopupBatchMemory.run returnBuffer hash m x (resolved e wc) ctx deposit moduleId
        keys operators rows allocation)

/-- Success derives both admission and actual lookup; the repeated downstream
length test is pure on identical configuration and rows. No stage premise. -/
theorem run_success (getter : StaticCall.External) (credentialCursor returnBuffer : Word)
    (hash : TopupRouterCredentials.Keccak) (m x : External) (e : Environment) (ctx : Context)
    (deposit : Address) (moduleId : Word) (keys operators : List Word) (rows : List Row) (allocation : Word)
    (h : (run getter credentialCursor returnBuffer hash m x e ctx deposit moduleId keys operators rows allocation).outcome = .ok ()) :
    checkLengths (TopupBatchRootCalls.environment e).cfg rows.length keys.length operators.length rows.length rows.length = .ok () ∧
    ∃ wc next trace,
      lookup getter e.gateway ctx.sender moduleId credentialCursor e.before = ⟨.ok (wc,next),trace⟩ ∧
      wc.val / 2^248 = 2 ∧
      (TopupBatchMemory.run returnBuffer hash m x (resolved e wc) ctx deposit moduleId keys operators rows allocation).outcome = .ok () ∧
      run getter credentialCursor returnBuffer hash m x e ctx deposit moduleId keys operators rows allocation =
        ofBatch trace (TopupBatchMemory.run returnBuffer hash m x (resolved e wc) ctx deposit moduleId keys operators rows allocation) := by
  unfold run at h ⊢
  cases hl : checkLengths (TopupBatchRootCalls.environment e).cfg rows.length keys.length operators.length rows.length rows.length with
  | «error» f => simp [hl] at h
  | ok u =>
    cases u
    simp only [hl] at h ⊢
    cases hq : lookup getter e.gateway ctx.sender moduleId credentialCursor e.before with
    | mk outcome trace =>
      cases outcome with
      | «error» f => simp [hq] at h
      | ok pair =>
        rcases pair with ⟨wc,next⟩
        simp only [hq] at h ⊢
        split at h
        · cases h
        · rename_i hp
          have hs : (TopupBatchMemory.run returnBuffer hash m x (resolved e wc) ctx deposit moduleId keys operators rows allocation).outcome = .ok () := by
            cases hb : (TopupBatchMemory.run returnBuffer hash m x (resolved e wc) ctx deposit moduleId keys operators rows allocation).outcome with
            | «error» f => simp [ofBatch,hb,Except.mapError] at h
            | ok u => cases u; rfl
          exact ⟨trivial,wc,next,trace,rfl,by omega,hs,by simp only [if_neg hp]⟩

theorem failure_restores (getter : StaticCall.External) (credentialCursor returnBuffer : Word)
    (hash : TopupRouterCredentials.Keccak) (m x : External) (e : Environment) (ctx : Context)
    (deposit : Address) (moduleId : Word) (keys operators : List Word) (rows : List Row) (allocation : Word) (fault : Error)
    (h : (run getter credentialCursor returnBuffer hash m x e ctx deposit moduleId keys operators rows allocation).outcome = .error fault) :
    (run getter credentialCursor returnBuffer hash m x e ctx deposit moduleId keys operators rows allocation).world = e.before := by
  unfold run at h ⊢
  cases hl : checkLengths (TopupBatchRootCalls.environment e).cfg rows.length keys.length operators.length rows.length rows.length with
  | «error» f => rfl
  | ok u =>
    cases u
    simp only [hl] at h ⊢
    cases hq : lookup getter e.gateway ctx.sender moduleId credentialCursor e.before with
    | mk outcome trace =>
      cases outcome with
      | «error» f => rfl
      | ok pair =>
        rcases pair with ⟨wc,next⟩
        simp only [hq] at h ⊢
        by_cases hp : wc.val / 2^248 ≠ 2
        · simp only [if_pos hp]
        · simp only [if_neg hp,ofBatch] at h ⊢
          cases hb : (TopupBatchMemory.run returnBuffer hash m x (resolved e wc) ctx deposit moduleId keys operators rows allocation).outcome with
          | ok u => simp [hb,Except.mapError] at h
          | «error» f => exact TopupBatchMemory.failure_restores returnBuffer hash m x (resolved e wc) ctx deposit moduleId keys operators rows allocation f hb

#print axioms copied_signed_guard
#print axioms decode_fields
#print axioms lookup_origin
#print axioms run_success
#print axioms failure_restores
end LidoSRv3.Audit.Source.TopupCredentialCall
