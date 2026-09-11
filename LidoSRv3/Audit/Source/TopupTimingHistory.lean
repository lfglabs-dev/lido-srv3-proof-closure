import LidoSRv3.Audit.Guarantees.PTopupPhysicalCredentialGetter

/-! core17005714 TopUpGateway:159–235,323–345,380–388. Typed phase with
physical temporal admission and the final packed history write. The actual
loop is executed once and its total is retained across the actual module
continuation. Role/pause/locator, outer router entry CALL, complete compiled
memory/copy/gas, deployment and LOG byte encoding retain their prior scope. -/
set_option autoImplicit false
namespace LidoSRv3.Audit.Source.TopupTimingHistory
open TrioReserve1 Live TopupGatewayWitnessBatch TopupCredentialCall
open TopupGatewayRootCalls (Environment)

def stored (gateway : Address) (w : World) : Word :=
  w.core.readContractSlot gateway.val TopupGatewayConfigWords.gatewayRoot

def lastBlock (gateway : Address) (w : World) : Nat := (stored gateway w).val / 2^96 % 2^32
def lastTimestamp (gateway : Address) (w : World) : Nat := (stored gateway w).val / 2^64 % 2^32
def minDistance (gateway : Address) (w : World) : Nat := (stored gateway w).val / 2^128 % 2^16
def maxAge (gateway : Address) (w : World) : Nat := (stored gateway w).val / 2^144 % 2^16

inductive TimingFault where
  | arithmetic
  | minBlockDistanceNotMet
  | rootIsTooOld
  | rootPrecedesLastTopUp
  deriving DecidableEq, Repr

/-- Short-circuit first; the subtraction is checked uint256. The timestamp
addition is checked uint64, even though the comparison uses uint256 TIMESTAMP. -/
def gates (e : Environment) : Except TimingFault Unit := do
  if lastBlock e.gateway e.before ≠ 0 then
    if e.before.core.blockNumber.val < lastBlock e.gateway e.before then .error .arithmetic
    else if e.before.core.blockNumber.val - lastBlock e.gateway e.before < minDistance e.gateway e.before then
      .error .minBlockDistanceNotMet
    else pure ()
  else pure ()
  let limit := e.beacon.childBlockTimestamp.toNat + maxAge e.gateway e.before
  if 2^64 ≤ limit then .error .arithmetic
  else if limit < e.before.core.blockTimestamp.val then .error .rootIsTooOld
  else if e.beacon.childBlockTimestamp.toNat ≤ lastTimestamp e.gateway e.before then
    .error .rootPrecedesLastTopUp
  else pure ()

def Admitted (e : Environment) : Prop :=
  (lastBlock e.gateway e.before = 0 ∨
    (lastBlock e.gateway e.before ≤ e.before.core.blockNumber.val ∧
      minDistance e.gateway e.before ≤ e.before.core.blockNumber.val - lastBlock e.gateway e.before)) ∧
  e.beacon.childBlockTimestamp.toNat + maxAge e.gateway e.before < 2^64 ∧
  e.before.core.blockTimestamp.val ≤ e.beacon.childBlockTimestamp.toNat + maxAge e.gateway e.before ∧
  lastTimestamp e.gateway e.before < e.beacon.childBlockTimestamp.toNat

theorem gates_admitted (e : Environment) (h : gates e = .ok ()) : Admitted e := by
  simp only [gates,pure,Except.pure,bind,Except.bind] at h
  split_ifs at h <;> simp_all [Admitted]

/-- The optimizer coalesces the source's two uint32 assignments. -/
def packed (old : Word) (timestamp blockNumber : Nat) : Word :=
  word (old.val % 2^64 + timestamp % 2^32 * 2^64 + blockNumber % 2^32 * 2^96 + old.val / 2^128 * 2^128)

theorem packed_fields (old : Word) (timestamp blockNumber : Nat) :
    (packed old timestamp blockNumber).val % 2^64 = old.val % 2^64 ∧
    (packed old timestamp blockNumber).val / 2^64 % 2^32 = timestamp % 2^32 ∧
    (packed old timestamp blockNumber).val / 2^96 % 2^32 = blockNumber % 2^32 ∧
    (packed old timestamp blockNumber).val / 2^128 = old.val / 2^128 := by
  have ho := old.isLt
  simp only [packed,word,Verity.Core.Uint256.ofNat,Verity.Core.Uint256.modulus,Verity.Core.UINT256_MODULUS] at *
  omega

def historyEvent (gateway : Address) (w : World) : Log :=
  ⟨gateway,"LastTopUpChanged",[w.core.blockTimestamp]⟩

def update (gateway : Address) (w : World) : World :=
  let core := w.core.writeContractSlot gateway.val TopupGatewayConfigWords.gatewayRoot
    (packed (stored gateway w) w.core.blockTimestamp.val w.core.blockNumber.val)
  {w with core := core, logs := w.logs ++ [historyEvent gateway w]}

def finishHistory (gateway : Address) (total : Nat) (w : World) : World :=
  if total = 0 then w else update gateway w

theorem update_word (gateway : Address) (w : World) :
    stored gateway (update gateway w) = packed (stored gateway w) w.core.blockTimestamp.val w.core.blockNumber.val := by
  by_cases hg : gateway.val = 0 <;>
    simp [stored,update,Verity.ContractState.readContractSlot,Verity.ContractState.writeContractSlot,
      Verity.ContractState.readSlot,Verity.ContractState.writeSlot,
      Verity.ContractState.storage,Verity.ContractState.contractStorage,hg]

/-- Instrumentation retains the output of the same root interpreter that is
passed to finish. It does not invoke a second interpreter to reconstruct total. -/
structure Stage where
  intermediate : TopupCredentialCall.Result
  produced : Option (Word × Output)

def execute (credentialCursor returnBuffer : Word) (hash : TopupRouterCredentials.Keccak)
    (m x : External) (e : Environment) (ctx : Context) (deposit : Address) (moduleId : Word)
    (keys operators : List Word) (rows : List Row) (allocation : Word) : Stage :=
  match checkLengths (TopupBatchRootCalls.environment e).cfg rows.length keys.length operators.length rows.length rows.length with
  | .error f => ⟨⟨.error (.lengths f),e.before,[],[],[]⟩,none⟩
  | .ok () =>
    let q := lookup (TopupPhysicalCredentialGetter.dispatch hash) e.gateway ctx.sender moduleId credentialCursor e.before
    match q.outcome with
    | .error f => ⟨⟨.error (.lookup f),e.before,q.attempts,[],[]⟩,none⟩
    | .ok (wc,_) =>
      if wc.val / 2^248 ≠ 2 then ⟨⟨.error .wrongWithdrawalCredentials,e.before,q.attempts,[],[]⟩,none⟩ else
      let checked := TopupGatewayRootCalls.loop (TopupBatchRootCalls.environment (resolved e wc)) none 0 rows
      ⟨ofBatch q.attempts (TopupBatchMemory.finish returnBuffer hash m x (resolved e wc) ctx deposit moduleId keys operators allocation checked),
       match checked.outcome with | .error _ => none | .ok out => some (wc,out)⟩

theorem execute_projection (credentialCursor returnBuffer : Word) (hash : TopupRouterCredentials.Keccak)
    (m x : External) (e : Environment) (ctx : Context) (deposit : Address) (moduleId : Word)
    (keys operators : List Word) (rows : List Row) (allocation : Word) :
    (execute credentialCursor returnBuffer hash m x e ctx deposit moduleId keys operators rows allocation).intermediate =
      TopupPhysicalCredentialGetter.run credentialCursor returnBuffer hash m x e ctx deposit moduleId keys operators rows allocation := by
  unfold execute TopupPhysicalCredentialGetter.run TopupCredentialCall.run
  cases hl : checkLengths (TopupBatchRootCalls.environment e).cfg rows.length keys.length operators.length rows.length rows.length with
  | «error» f => rfl
  | ok u =>
    cases u
    simp only
    cases hq : (lookup (TopupPhysicalCredentialGetter.dispatch hash) e.gateway ctx.sender moduleId credentialCursor e.before).outcome with
    | «error» f => rfl
    | ok pair =>
      rcases pair with ⟨wc,next⟩
      by_cases hp : wc.val / 2^248 ≠ 2
      · simp only [if_pos hp]
      · simp only [if_neg hp]
        unfold TopupBatchMemory.run
        have hc : (TopupBatchRootCalls.environment (resolved e wc)).cfg = (TopupBatchRootCalls.environment e).cfg := rfl
        simp only [hc,hl]


theorem execute_produced (credentialCursor returnBuffer : Word) (hash : TopupRouterCredentials.Keccak)
    (m x : External) (e : Environment) (ctx : Context) (deposit : Address) (moduleId : Word)
    (keys operators : List Word) (rows : List Row) (allocation : Word)
    (h : (execute credentialCursor returnBuffer hash m x e ctx deposit moduleId keys operators rows allocation).intermediate.outcome = .ok ()) :
    ∃ wc out, (execute credentialCursor returnBuffer hash m x e ctx deposit moduleId keys operators rows allocation).produced = some (wc,out) ∧
      (TopupGatewayRootCalls.loop (TopupBatchRootCalls.environment (resolved e wc)) none 0 rows).outcome = .ok out := by
  unfold execute at h ⊢
  cases hl : checkLengths (TopupBatchRootCalls.environment e).cfg rows.length keys.length operators.length rows.length rows.length with
  | «error» f => simp [hl] at h
  | ok u =>
    cases u
    simp only [hl] at h ⊢
    cases hq : (lookup (TopupPhysicalCredentialGetter.dispatch hash) e.gateway ctx.sender moduleId credentialCursor e.before).outcome with
    | «error» f => simp [hq] at h
    | ok pair =>
      rcases pair with ⟨wc,next⟩
      simp only [hq] at h ⊢
      by_cases hp : wc.val / 2^248 ≠ 2
      · simp only [if_pos hp] at h; cases h
      · simp only [if_neg hp] at h ⊢
        cases ho : (TopupGatewayRootCalls.loop (TopupBatchRootCalls.environment (resolved e wc)) none 0 rows).outcome with
        | «error» f => simp [ofBatch,TopupBatchMemory.finish,ho,Except.mapError] at h
        | ok out => exact ⟨wc,out,rfl,ho⟩

inductive Error where
  | lengths (fault : GatewayFault)
  | timing (fault : TimingFault)
  | phase (fault : TopupCredentialCall.Error)
  deriving DecidableEq, Repr

structure Result where
  outcome : Except Error Unit
  world : World
  credentialAttempts : List NestedAttempt
  rootAttempts : List NestedAttempt
  moduleAttempts : List Attempt
  stage : Option Stage

def finish (gateway : Address) (s : Stage) : Result :=
  let r := s.intermediate
  ⟨r.outcome.mapError Error.phase,
    match r.outcome with
    | .error _ => r.world
    | .ok () => finishHistory gateway (s.produced.map (fun p => p.2.total) |>.getD 0) r.world,
    r.credentialAttempts,r.rootAttempts,r.moduleAttempts,some s⟩

def run (credentialCursor returnBuffer : Word) (hash : TopupRouterCredentials.Keccak)
    (m x : External) (e : Environment) (ctx : Context) (deposit : Address) (moduleId : Word)
    (keys operators : List Word) (rows : List Row) (allocation : Word) : Result :=
  match checkLengths (TopupBatchRootCalls.environment e).cfg rows.length keys.length operators.length rows.length rows.length with
  | .error f => ⟨.error (.lengths f),e.before,[],[],[],none⟩
  | .ok () =>
    match gates e with
    | .error f => ⟨.error (.timing f),e.before,[],[],[],none⟩
    | .ok () => finish e.gateway (execute credentialCursor returnBuffer hash m x e ctx deposit moduleId keys operators rows allocation)

theorem run_success (credentialCursor returnBuffer : Word) (hash : TopupRouterCredentials.Keccak)
    (m x : External) (e : Environment) (ctx : Context) (deposit : Address) (moduleId : Word)
    (keys operators : List Word) (rows : List Row) (allocation : Word)
    (h : (run credentialCursor returnBuffer hash m x e ctx deposit moduleId keys operators rows allocation).outcome = .ok ()) :
    gates e = .ok () ∧
    let s := execute credentialCursor returnBuffer hash m x e ctx deposit moduleId keys operators rows allocation
    s.intermediate.outcome = .ok () ∧
    run credentialCursor returnBuffer hash m x e ctx deposit moduleId keys operators rows allocation = finish e.gateway s := by
  unfold run at h ⊢
  cases hl : checkLengths (TopupBatchRootCalls.environment e).cfg rows.length keys.length operators.length rows.length rows.length with
  | «error» f => simp [hl] at h
  | ok u =>
    cases u
    simp only [hl] at h ⊢
    cases hg : gates e with
    | «error» f => simp [hg] at h
    | ok u =>
      cases u
      simp only [hg] at h ⊢
      cases hs : (execute credentialCursor returnBuffer hash m x e ctx deposit moduleId keys operators rows allocation).intermediate.outcome with
      | «error» f => simp [finish,hs,Except.mapError] at h
      | ok u => cases u; exact ⟨by trivial,by rfl,by trivial⟩

theorem failure_restores (credentialCursor returnBuffer : Word) (hash : TopupRouterCredentials.Keccak)
    (m x : External) (e : Environment) (ctx : Context) (deposit : Address) (moduleId : Word)
    (keys operators : List Word) (rows : List Row) (allocation : Word) (fault : Error)
    (h : (run credentialCursor returnBuffer hash m x e ctx deposit moduleId keys operators rows allocation).outcome = .error fault) :
    (run credentialCursor returnBuffer hash m x e ctx deposit moduleId keys operators rows allocation).world = e.before := by
  unfold run at h ⊢
  cases hl : checkLengths (TopupBatchRootCalls.environment e).cfg rows.length keys.length operators.length rows.length rows.length with
  | «error» f => rfl
  | ok u =>
    cases u
    simp only [hl] at h ⊢
    cases hg : gates e with
    | «error» f => rfl
    | ok u =>
      cases u
      simp only [hg,finish,execute_projection] at h ⊢
      cases hs : (TopupPhysicalCredentialGetter.run credentialCursor returnBuffer hash m x e ctx deposit moduleId keys operators rows allocation).outcome with
      | ok u => simp [hs,Except.mapError] at h
      | «error» f =>
        simp only
        exact TopupCredentialCall.failure_restores (TopupPhysicalCredentialGetter.dispatch hash)
          credentialCursor returnBuffer hash m x e ctx deposit moduleId keys operators rows allocation f hs

#print axioms execute_produced
#print axioms run_success
#print axioms failure_restores

#print axioms gates_admitted
#print axioms packed_fields
#print axioms update_word
#print axioms execute_projection
end LidoSRv3.Audit.Source.TopupTimingHistory
