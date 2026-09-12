import LidoSRv3.Audit.Source.TopupRouterAdmissionCallGates
set_option autoImplicit false
set_option maxRecDepth 4096
set_option maxHeartbeats 800000
namespace LidoSRv3.Audit.Source.TopupRouterAdmissionCall
open TrioReserve1 Live TopupGatewayWitnessBatch

structure Input where
  caller : Address
  locatorCall : StaticCall.External
  locator : Address
  cursor : Word
  returnBuffer : Word
  hash : TopupRouterCredentials.Keccak
  moduleCall : External
  withdrawalCall : External
  gateway : TopupGatewayRootCalls.Environment
  ctx : Context
  deposit : Address
  moduleId : Word
  keys : List Word
  operators : List Word
  rows : List Row
  allocation : Word

def prior (i : Input) : TopupEntryAdmission.Result :=
  TopupEntryAdmission.run i.caller i.locatorCall i.locator i.cursor i.returnBuffer i.hash
    i.moduleCall i.withdrawalCall i.gateway i.ctx i.deposit i.moduleId i.keys i.operators i.rows i.allocation

/-- Internally produced seam values, never a caller-supplied certificate. -/
structure Ready where
  router : Address
  next : Word
  wc : Word
  locatorAttempts : List NestedAttempt
  credentialAttempts : List NestedAttempt
  rootAttempts : List NestedAttempt
  output : Output

def selected (i : Input) (p : Ready) : Context := TopupRouterLocatorCall.resolved i.ctx p.router

def moduleInput (i : Input) (p : Ready) : TopupModuleCall.Input :=
  TopupBatchConsumer.moduleInput p.output i.moduleId i.keys i.operators p.router i.allocation i.gateway.before

def afterRoots (i : Input) (router : Address) (wc : Word)
    (locatorTrace credentialTrace : List NestedAttempt) (checked : TopupGatewayRootCalls.Result Output) : TopupEntryAdmission.Result :=
  TopupEntryAdmission.ofPrior (TopupRouterLocatorCall.ofTiming locatorTrace
    (TopupTimingHistory.finish i.gateway.gateway
      ⟨TopupCredentialCall.ofBatch credentialTrace
        (TopupBatchMemory.finish i.returnBuffer i.hash i.moduleCall i.withdrawalCall
          (TopupCredentialCall.resolved i.gateway wc) (TopupRouterLocatorCall.resolved i.ctx router)
          i.deposit i.moduleId i.keys i.operators i.allocation checked),
       match checked.outcome with | .error _ => none | .ok out => some (wc,out)⟩))

def finish (i : Input) (p : Ready) : TopupEntryAdmission.Result :=
  afterRoots i p.router p.wc p.locatorAttempts p.credentialAttempts ⟨.ok p.output,p.rootAttempts⟩

/-- The prefix invokes each actual external stage once. Only its terminal
continuation varies; module effects and history have not run at this seam. -/
def walk {α : Type} (i : Input) (early : TopupEntryAdmission.Error → TopupEntryAdmission.Result → α)
    (consume : Ready → α) : α :=
  match TopupEntryAdmission.gates i.gateway.gateway i.caller i.gateway.before with
  | .error f => early (.admission f) ⟨.error (.admission f),i.gateway.before,none⟩
  | .ok () =>
    match checkLengths (TopupBatchRootCalls.environment i.gateway).cfg i.rows.length i.keys.length i.operators.length i.rows.length i.rows.length with
    | .error f => early (.phase (.lengths f)) (TopupEntryAdmission.ofPrior ⟨.error (.lengths f),i.gateway.before,[],none⟩)
    | .ok () =>
      match TopupTimingHistory.gates i.gateway with
      | .error f => early (.phase (.timing f)) (TopupEntryAdmission.ofPrior ⟨.error (.timing f),i.gateway.before,[],none⟩)
      | .ok () =>
        let q := TopupRouterLocatorCall.lookup i.locatorCall i.gateway.gateway i.locator i.cursor i.gateway.before
        match q.outcome with
        | .error f => early (.phase (.lookup f)) (TopupEntryAdmission.ofPrior ⟨.error (.lookup f),i.gateway.before,q.attempts,none⟩)
        | .ok (router,next) =>
          let c := TopupCredentialCall.lookup (TopupPhysicalCredentialGetter.dispatch i.hash)
            i.gateway.gateway router i.moduleId next i.gateway.before
          match c.outcome with
          | .error f => early (.phase (.phase (.phase (.lookup f))))
              (TopupEntryAdmission.ofPrior (TopupRouterLocatorCall.ofTiming q.attempts
                (TopupTimingHistory.finish i.gateway.gateway ⟨⟨.error (.lookup f),i.gateway.before,c.attempts,[],[]⟩,none⟩)))
          | .ok (wc,_) =>
            if wc.val / 2^248 ≠ 2 then
              early (.phase (.phase (.phase .wrongWithdrawalCredentials)))
                (TopupEntryAdmission.ofPrior (TopupRouterLocatorCall.ofTiming q.attempts
                  (TopupTimingHistory.finish i.gateway.gateway ⟨⟨.error .wrongWithdrawalCredentials,i.gateway.before,c.attempts,[],[]⟩,none⟩)))
            else
              let checked := TopupGatewayRootCalls.loop (TopupBatchRootCalls.environment (TopupCredentialCall.resolved i.gateway wc)) none 0 i.rows
              match checked.outcome with
              | .error f => early (.phase (.phase (.phase (.batch (.gateway f)))))
                  (afterRoots i router wc q.attempts c.attempts checked)
              | .ok out => consume ⟨router,next,wc,q.attempts,c.attempts,checked.attempts,out⟩

/-- Congruence of the same executed prefix, not a second execution in run. -/
theorem walk_relation {α β : Type} (i : Input) (a : TopupEntryAdmission.Error → TopupEntryAdmission.Result → α)
    (b : TopupEntryAdmission.Error → TopupEntryAdmission.Result → β)
    (f : Ready → α) (g : Ready → β) (R : α → β → Prop)
    (he : ∀ fault r, R (a fault r) (b fault r)) (hc : ∀ p, R (f p) (g p)) :
    R (walk i a f) (walk i b g) := by
  simp only [walk]
  repeat' first
    | exact he _ _
    | exact hc _
    | (split <;> try simp_all only)

theorem walk_prior (i : Input) : walk i (fun _ r => r) (finish i) = prior i := by
  simp only [walk,prior,TopupEntryAdmission.run,TopupRouterLocatorCall.run,
    TopupTimingHistory.execute,TopupRouterLocatorCall.resolved]
  repeat' first
    | rfl
    | (split <;> try simp_all only)
  all_goals simp_all only [finish,afterRoots,TopupRouterLocatorCall.resolved,TopupBatchMemory.finish]

inductive Error where
  | prior (fault : TopupEntryAdmission.Error)
  | admission (fault : Fault)
  deriving DecidableEq, Repr

structure Result where
  outcome : Except Error Unit
  world : World
  projection : Option TopupEntryAdmission.Result
  admissionAttempts : List NestedAttempt
  ready : Option Ready

def consume (g : TopupRouterAdmissionCallGates.Environment) (i : Input) (p : Ready) : Result :=
  let a := TopupRouterAdmissionCallGates.run g i.hash i.gateway.gateway (selected i p) (moduleInput i p) i.gateway.before
  match a.outcome with
  | .error f => ⟨.error (.admission f),i.gateway.before,none,a.attempts,some p⟩
  | .ok () =>
    let r := finish i p
    ⟨r.outcome.mapError Error.prior,r.world,some r,a.attempts,some p⟩

def run (g : TopupRouterAdmissionCallGates.Environment) (i : Input) : Result :=
  walk i (fun f r => ⟨.error (.prior f),i.gateway.before,some r,[],none⟩) (consume g i)

def SuccessRelation (g : TopupRouterAdmissionCallGates.Environment) (i : Input)
    (r : Result) (old : TopupEntryAdmission.Result) : Prop :=
  r.outcome = .ok () → old.outcome = .ok () ∧ r.world = old.world ∧ r.projection = some old ∧
    ∃ p, r.ready = some p ∧ old = finish i p ∧
      TopupRouterAdmissionCallGates.Admitted g i.hash i.gateway.gateway (selected i p) (moduleInput i p) i.gateway.before ∧
      r.admissionAttempts = (TopupRouterAdmissionCallGates.run g i.hash i.gateway.gateway (selected i p) (moduleInput i p) i.gateway.before).attempts

theorem run_success (g : TopupRouterAdmissionCallGates.Environment) (i : Input)
    (h : (run g i).outcome = .ok ()) :
    (prior i).outcome = .ok () ∧ (run g i).world = (prior i).world ∧ (run g i).projection = some (prior i) ∧
    ∃ p, (run g i).ready = some p ∧ prior i = finish i p ∧
      TopupRouterAdmissionCallGates.Admitted g i.hash i.gateway.gateway (selected i p) (moduleInput i p) i.gateway.before ∧
      (run g i).admissionAttempts = (TopupRouterAdmissionCallGates.run g i.hash i.gateway.gateway (selected i p) (moduleInput i p) i.gateway.before).attempts := by
  have hr : SuccessRelation g i (run g i) (prior i) := by
    rw [← walk_prior]
    apply walk_relation
    · intro f r hs
      cases hs
    · intro p hs
      unfold consume at hs ⊢
      cases ha : (TopupRouterAdmissionCallGates.run g i.hash i.gateway.gateway (selected i p) (moduleInput i p) i.gateway.before).outcome with
      | «error» f => simp [ha] at hs
      | ok u =>
        cases u
        simp only [ha] at hs ⊢
        have ho : (finish i p).outcome = .ok () := by
          cases hf : (finish i p).outcome with
          | «error» f => simp [hf,Except.mapError] at hs
          | ok u => cases u; rfl
        exact ⟨ho,trivial,trivial,p,rfl,rfl,TopupRouterAdmissionCallGates.run_admitted _ _ _ _ _ _ ha,rfl⟩
  exact hr h

theorem failure_restores (g : TopupRouterAdmissionCallGates.Environment) (i : Input) (fault : Error)
    (h : (run g i).outcome = .error fault) : (run g i).world = i.gateway.before := by
  let R : Result → TopupEntryAdmission.Result → Prop := fun r old =>
    ∀ f, r.outcome = .error f → r.world = i.gateway.before ∨
      ∃ oldFault, old.outcome = .error oldFault ∧ r.world = old.world
  have hr : R (run g i) (prior i) := by
    rw [← walk_prior]
    apply walk_relation
    · intro f r err hfail
      exact Or.inl rfl
    · intro p err hfail
      unfold consume at hfail ⊢
      cases ha : (TopupRouterAdmissionCallGates.run g i.hash i.gateway.gateway (selected i p) (moduleInput i p) i.gateway.before).outcome with
      | «error» f => simp only [ha]; exact Or.inl trivial
      | ok u =>
        cases u
        simp only [ha] at hfail ⊢
        cases ho : (finish i p).outcome with
        | ok u => simp [ho,Except.mapError] at hfail
        | «error» f => exact Or.inr ⟨f,rfl,trivial⟩
  rcases hr fault h with he | ⟨f,hf,he⟩
  · exact he
  · rw [he]
    exact TopupEntryAdmission.failure_restores i.caller i.locatorCall i.locator i.cursor i.returnBuffer i.hash
      i.moduleCall i.withdrawalCall i.gateway i.ctx i.deposit i.moduleId i.keys i.operators i.rows i.allocation f hf

#print axioms failure_restores

#print axioms walk_relation
#print axioms walk_prior
#print axioms run_success
end LidoSRv3.Audit.Source.TopupRouterAdmissionCall
