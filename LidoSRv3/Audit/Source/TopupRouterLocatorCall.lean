import LidoSRv3.Audit.Guarantees.PTopupTimingHistory

/-! core17005714 TopUpGateway: typed length and temporal admission precede
an actual LOCATOR.stakingRouter STATICCALL. Its canonical address is consumed
as the router by the existing physical credentials/root/module/history suffix.
The locator allocator's next pointer is the credentials getter's cursor.
Immutable locator identity, role/pause, outer router entry CALL, initial memory
provenance, complete memory/gas and deployed locator body remain phase boundaries. -/
set_option autoImplicit false
namespace LidoSRv3.Audit.Source.TopupRouterLocatorCall
open TrioReserve1 Live TopupGatewayWitnessBatch
open TopupGatewayRootCalls (Environment)
open audit.trio.deposit.ModuleCall (finalizeAllocation)

def selector : Nat := 0xef6c064c

def request (gateway locator : Address) : Request :=
  ⟨gateway,locator,word 0,encode 4 selector⟩

/-- Same min32 allocation and signed head guard as the adjacent bytes32 getter,
then the compiled address decoder's canonical160 guard. Trailing data is ignored. -/
def decodeRouter (cursor : Word) (raw : Bytes) : Except Fault (Address × Word) := do
  let (value,next) ← TopupCredentialCall.decodeCredentials cursor raw
  if h : value.val < 2^160 then .ok (⟨value.val,h⟩,next) else .error .empty

theorem decode_fields (cursor : Word) (raw : Bytes) (router : Address) (next : Word)
    (h : decodeRouter cursor raw = .ok (router,next)) :
    32 ≤ (word raw.length).val ∧ router.val = (word (decode (raw.take 32))).val ∧
    router.val < 2^160 ∧ finalizeAllocation cursor 32 = .ok next ∧
    cursor.val + 32 = next.val ∧ next.val < 2^64 := by
  unfold decodeRouter at h
  cases hd : TopupCredentialCall.decodeCredentials cursor raw with
  | «error» f => simp [hd,bind,Except.bind] at h
  | ok pair =>
    rcases pair with ⟨value,ptr⟩
    simp only [hd,bind,Except.bind] at h
    split at h
    · cases h
      obtain ⟨hl,hv,ha,he,hb⟩ := TopupCredentialCall.decode_fields cursor raw value next hd
      exact ⟨hl,by simpa only [hv],by assumption,ha,he,hb⟩
    · cases h

structure LookupResult where
  outcome : Except Fault (Address × Word)
  attempts : List NestedAttempt
  deriving DecidableEq

def lookup (locatorCall : StaticCall.External) (gateway locator : Address)
    (cursor : Word) (before : World) : LookupResult :=
  let r := audit.trio.consolidation.lowLevelStaticCall locatorCall gateway locator
    (request gateway locator).payload before
  match r.outcome with
  | .error bytes => ⟨.error (.bubbled bytes),r.attempts⟩
  | .ok raw => ⟨decodeRouter cursor raw,r.attempts⟩

theorem lookup_origin (locatorCall : StaticCall.External) (gateway locator : Address)
    (cursor : Word) (before : World) (router : Address) (next : Word) (trace : List NestedAttempt)
    (h : lookup locatorCall gateway locator cursor before = ⟨.ok (router,next),trace⟩) :
    (before.core.codeSize locator.val).val ≠ 0 ∧ ∃ raw,
      locatorCall (request gateway locator) before = .success raw ∧
      decodeRouter cursor raw = .ok (router,next) ∧
      32 ≤ (word raw.length).val ∧ router.val = (word (decode (raw.take 32))).val ∧
      router.val < 2^160 ∧ finalizeAllocation cursor 32 = .ok next ∧
      cursor.val + 32 = next.val ∧ next.val < 2^64 ∧
      trace = [⟨request gateway locator,true,true,raw,1⟩] := by
  unfold lookup audit.trio.consolidation.lowLevelStaticCall at h
  by_cases hc : (before.core.codeSize locator.val).val = 0
  · simp only [hc,if_true] at h
    have hd := congrArg LookupResult.outcome h
    have hb := (decode_fields cursor [] router next hd).1
    norm_num [word,Verity.Core.Uint256.modulus,Verity.Core.UINT256_MODULUS] at hb
  · simp only [hc,if_false] at h
    cases hr : locatorCall (request gateway locator) before with
    | rejected data => simp only [request] at hr h; simp [hr] at h
    | forbiddenStateChange => simp only [request] at hr h; simp [hr] at h
    | success raw =>
      simp only [request] at hr h
      simp only [hr] at h
      have hd := congrArg LookupResult.outcome h
      have ht := congrArg LookupResult.attempts h
      obtain ⟨hl,hv,h160,ha,he,hb⟩ := decode_fields cursor raw router next hd
      exact ⟨hc,raw,rfl,hd,hl,hv,h160,ha,he,hb,ht.symm⟩

def resolved (ctx : Context) (router : Address) : Context := {ctx with sender := router}

inductive Error where
  | lengths (fault : GatewayFault)
  | timing (fault : TopupTimingHistory.TimingFault)
  | lookup (fault : Fault)
  | phase (fault : TopupTimingHistory.Error)
  deriving DecidableEq, Repr

structure Result where
  outcome : Except Error Unit
  world : World
  locatorAttempts : List NestedAttempt
  suffix : Option TopupTimingHistory.Result

def ofTiming (trace : List NestedAttempt) (r : TopupTimingHistory.Result) : Result :=
  ⟨r.outcome.mapError Error.phase,r.world,trace,some r⟩

def Result.observations (r : Result) : List (Sum NestedAttempt Attempt) :=
  r.locatorAttempts.map Sum.inl ++ match r.suffix with
  | none => []
  | some s => (s.credentialAttempts ++ s.rootAttempts).map Sum.inl ++ s.moduleAttempts.map Sum.inr

/-- Execute only the old suffix after the locator; the old public run is related
by the already executed identical pure guards, never by a supplied stage premise. -/
def run (locatorCall : StaticCall.External) (locator : Address) (cursor returnBuffer : Word)
    (hash : TopupRouterCredentials.Keccak) (m x : External) (e : Environment) (ctx : Context)
    (deposit : Address) (moduleId : Word) (keys operators : List Word) (rows : List Row)
    (allocation : Word) : Result :=
  match checkLengths (TopupBatchRootCalls.environment e).cfg rows.length keys.length operators.length rows.length rows.length with
  | .error f => ⟨.error (.lengths f),e.before,[],none⟩
  | .ok () =>
    match TopupTimingHistory.gates e with
    | .error f => ⟨.error (.timing f),e.before,[],none⟩
    | .ok () =>
      let q := lookup locatorCall e.gateway locator cursor e.before
      match q.outcome with
      | .error f => ⟨.error (.lookup f),e.before,q.attempts,none⟩
      | .ok (router,next) => ofTiming q.attempts (TopupTimingHistory.finish e.gateway
          (TopupTimingHistory.execute next returnBuffer hash m x e (resolved ctx router)
            deposit moduleId keys operators rows allocation))

private theorem suffix_eq_run (cursor returnBuffer : Word) (hash : TopupRouterCredentials.Keccak)
    (m x : External) (e : Environment) (ctx : Context) (deposit : Address) (moduleId : Word)
    (keys operators : List Word) (rows : List Row) (allocation : Word)
    (hl : checkLengths (TopupBatchRootCalls.environment e).cfg rows.length keys.length operators.length rows.length rows.length = .ok ())
    (hg : TopupTimingHistory.gates e = .ok ()) :
    TopupTimingHistory.finish e.gateway (TopupTimingHistory.execute cursor returnBuffer hash m x e ctx deposit moduleId keys operators rows allocation) =
      TopupTimingHistory.run cursor returnBuffer hash m x e ctx deposit moduleId keys operators rows allocation := by
  simp only [TopupTimingHistory.run,hl,hg]

theorem run_success (locatorCall : StaticCall.External) (locator : Address) (cursor returnBuffer : Word)
    (hash : TopupRouterCredentials.Keccak) (m x : External) (e : Environment) (ctx : Context)
    (deposit : Address) (moduleId : Word) (keys operators : List Word) (rows : List Row) (allocation : Word)
    (h : (run locatorCall locator cursor returnBuffer hash m x e ctx deposit moduleId keys operators rows allocation).outcome = .ok ()) :
    ∃ router next trace,
      lookup locatorCall e.gateway locator cursor e.before = ⟨.ok (router,next),trace⟩ ∧
      (TopupTimingHistory.run next returnBuffer hash m x e (resolved ctx router) deposit moduleId keys operators rows allocation).outcome = .ok () ∧
      run locatorCall locator cursor returnBuffer hash m x e ctx deposit moduleId keys operators rows allocation =
        ofTiming trace (TopupTimingHistory.run next returnBuffer hash m x e (resolved ctx router) deposit moduleId keys operators rows allocation) := by
  unfold run at h ⊢
  cases hl : checkLengths (TopupBatchRootCalls.environment e).cfg rows.length keys.length operators.length rows.length rows.length with
  | «error» f => simp [hl] at h
  | ok u =>
    cases u
    simp only [hl] at h ⊢
    cases hg : TopupTimingHistory.gates e with
    | «error» f => simp [hg] at h
    | ok u =>
      cases u
      simp only [hg] at h ⊢
      cases hq : lookup locatorCall e.gateway locator cursor e.before with
      | mk outcome trace =>
        cases outcome with
        | «error» f => simp [hq] at h
        | ok pair =>
          rcases pair with ⟨router,next⟩
          simp only [hq,suffix_eq_run next returnBuffer hash m x e (resolved ctx router) deposit moduleId keys operators rows allocation hl hg] at h ⊢
          have hs : (TopupTimingHistory.run next returnBuffer hash m x e (resolved ctx router) deposit moduleId keys operators rows allocation).outcome = .ok () := by
            cases hb : (TopupTimingHistory.run next returnBuffer hash m x e (resolved ctx router) deposit moduleId keys operators rows allocation).outcome with
            | «error» f => simp [ofTiming,hb,Except.mapError] at h
            | ok u => cases u; rfl
          exact ⟨router,next,trace,rfl,hs,rfl⟩

theorem failure_restores (locatorCall : StaticCall.External) (locator : Address) (cursor returnBuffer : Word)
    (hash : TopupRouterCredentials.Keccak) (m x : External) (e : Environment) (ctx : Context)
    (deposit : Address) (moduleId : Word) (keys operators : List Word) (rows : List Row) (allocation : Word) (fault : Error)
    (h : (run locatorCall locator cursor returnBuffer hash m x e ctx deposit moduleId keys operators rows allocation).outcome = .error fault) :
    (run locatorCall locator cursor returnBuffer hash m x e ctx deposit moduleId keys operators rows allocation).world = e.before := by
  unfold run at h ⊢
  cases hl : checkLengths (TopupBatchRootCalls.environment e).cfg rows.length keys.length operators.length rows.length rows.length with
  | «error» f => rfl
  | ok u =>
    cases u
    simp only [hl] at h ⊢
    cases hg : TopupTimingHistory.gates e with
    | «error» f => rfl
    | ok u =>
      cases u
      simp only [hg] at h ⊢
      cases hq : lookup locatorCall e.gateway locator cursor e.before with
      | mk outcome trace =>
        cases outcome with
        | «error» f => rfl
        | ok pair =>
          rcases pair with ⟨router,next⟩
          simp only [hq,suffix_eq_run next returnBuffer hash m x e (resolved ctx router) deposit moduleId keys operators rows allocation hl hg,ofTiming] at h ⊢
          cases hb : (TopupTimingHistory.run next returnBuffer hash m x e (resolved ctx router) deposit moduleId keys operators rows allocation).outcome with
          | ok u => simp [hb,Except.mapError] at h
          | «error» f => exact TopupTimingHistory.failure_restores next returnBuffer hash m x e (resolved ctx router) deposit moduleId keys operators rows allocation f hb

#print axioms decode_fields
#print axioms lookup_origin
#print axioms run_success
#print axioms failure_restores
end LidoSRv3.Audit.Source.TopupRouterLocatorCall
