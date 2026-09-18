import LidoSRv3.Audit.Source.TopupRouterAdmissionCall
set_option autoImplicit false
namespace LidoSRv3.Audit.Guarantees.PTopupRouterAdmissionCall
open Source Source.TrioReserve1 Live TopupGatewayWitnessBatch
open TopupTimingHistory PTopupTimingHistory PTopupRouterLocatorCall
open TopupCredentialCall (resolved)
open TopupRouterAdmissionCall (Input Ready prior run finish selected moduleInput)

/-- Retained TOPUP342 execution effects with precompile-aware locator origin.
Actual response bytes replace the invalid generic inference of code presence. -/
def PriorEffects (i : Input) : Prop :=
  let caller := i.caller
  let locatorCall := i.locatorCall
  let locator := i.locator
  let cursor := i.cursor
  let returnBuffer := i.returnBuffer
  let hash := i.hash
  let m := i.moduleCall
  let x := i.withdrawalCall
  let e := i.gateway
  let ctx := i.ctx
  let deposit := i.deposit
  let moduleId := i.moduleId
  let keys := i.keys
  let operators := i.operators
  let rows := i.rows
  let allocation := i.allocation;
    TopupEntryAdmission.Admitted e.gateway caller e.before ∧
    TopupEntryAdmission.run caller locatorCall locator cursor returnBuffer hash m x e ctx deposit moduleId keys operators rows allocation = TopupEntryAdmission.ofPrior (TopupRouterLocatorCall.run locatorCall locator cursor returnBuffer hash m x e ctx deposit moduleId keys operators rows allocation) ∧
    (∃ router next raw,
      ¬ audit.trio.consolidation.emptyCodeAccount e.before locator ∧
      locatorCall (TopupRouterLocatorCall.request e.gateway locator) e.before = .success raw ∧
      TopupRouterLocatorCall.decodeRouter cursor raw = .ok (router,next) ∧
      32 ≤ (word raw.length).val ∧ router.val = (word (decode (raw.take 32))).val ∧
      router.val < 2^160 ∧ audit.trio.deposit.ModuleCall.finalizeAllocation cursor 32 = .ok next ∧
      cursor.val + 32 = next.val ∧ next.val < 2^64 ∧
      let selected := TopupRouterLocatorCall.resolved ctx router
      selected.self = ctx.self ∧ selected.sender = router ∧
      let prior := TopupTimingHistory.run next returnBuffer hash m x e selected deposit moduleId keys operators rows allocation
      let result := TopupRouterLocatorCall.run locatorCall locator cursor returnBuffer hash m x e ctx deposit moduleId keys operators rows allocation
      result = TopupRouterLocatorCall.ofTiming [⟨TopupRouterLocatorCall.request e.gateway locator,true,true,raw,1⟩] prior ∧
      result.world = prior.world ∧ result.suffix = some prior ∧
      result.observations = [Sum.inl ⟨TopupRouterLocatorCall.request e.gateway locator,true,true,raw,1⟩] ++
        (prior.credentialAttempts ++ prior.rootAttempts).map Sum.inl ++ prior.moduleAttempts.map Sum.inr ∧
      TimingEffects next returnBuffer hash m x e selected deposit moduleId keys operators rows allocation)

/-- Only whole execution success is a premise. Actual decoder/authentication,
physical admission and conditional Lido static call are consumed before the
unchanged actual module/withdrawal/history continuation. Allocation view calls
and outer gateway-to-router transport retain their explicitly bounded scope. -/
theorem actual_router_admission_complete_prior (g : TopupRouterAdmissionCallGates.Environment) (i : Input)
    (h : (run g i).outcome = .ok ()) :
    PriorEffects i ∧ (run g i).world = (prior i).world ∧ (run g i).projection = some (prior i) ∧
    ∃ p, (run g i).ready = some p ∧ prior i = finish i p ∧
      TopupRouterAdmissionCallGates.Admitted g i.hash i.gateway.gateway (selected i p) (moduleInput i p) i.gateway.before ∧
      TopupRouterAdmissionCallGates.CallFacts g i.gateway.gateway (selected i p) (moduleInput i p) i.gateway.before ∧
      (run g i).admissionAttempts = (TopupRouterAdmissionCallGates.run g i.hash i.gateway.gateway (selected i p) (moduleInput i p) i.gateway.before).attempts := by
  obtain ⟨hp,hw,hprojection,p,hr,hfinish,ha,ht⟩ := TopupRouterAdmissionCall.run_success g i h
  refine ⟨?_,hw,hprojection,p,hr,hfinish,ha,TopupRouterAdmissionCallGates.admitted_calls _ _ _ _ _ _ ha,ht⟩
  exact PTopupEntryAdmission.actual_physical_entry_locator_timing_credential_root_module_memory_history
    i.caller i.locatorCall i.locator i.cursor i.returnBuffer i.hash i.moduleCall i.withdrawalCall
    i.gateway i.ctx i.deposit i.moduleId i.keys i.operators i.rows i.allocation hp

theorem actual_gateway_entry_failure_restores (g : TopupRouterAdmissionCallGates.Environment) (i : Input)
    (fault : TopupRouterAdmissionCall.Error) (h : (run g i).outcome = .error fault) :
    (run g i).world = i.gateway.before := TopupRouterAdmissionCall.failure_restores g i fault h

/-- Full admission and retained physical/root/module/per-key/history effects.
This is the complete existing success conclusion, including actual call facts. -/
def ActualEffects (g : TopupRouterAdmissionCallGates.Environment) (i : Input) : Prop :=
    PriorEffects i ∧ (run g i).world = (prior i).world ∧ (run g i).projection = some (prior i) ∧
    ∃ p, (run g i).ready = some p ∧ prior i = finish i p ∧
      TopupRouterAdmissionCallGates.Admitted g i.hash i.gateway.gateway (selected i p) (moduleInput i p) i.gateway.before ∧
      TopupRouterAdmissionCallGates.CallFacts g i.gateway.gateway (selected i p) (moduleInput i p) i.gateway.before ∧
      (run g i).admissionAttempts = (TopupRouterAdmissionCallGates.run g i.hash i.gateway.gateway (selected i p) (moduleInput i p) i.gateway.before).attempts

/-- Bind the registered physical storage consumer to the concrete hash engine.
Generic helpers and small-slot fixtures remain separately parameterized. -/
def physicalKeccak : TopupRouterCredentials.Keccak := fun bytes =>
  word (EvmYul.fromByteArrayBigEndian
    (KeccakEngine.keccak256 (ByteArray.mk bytes.toArray)))

/-- Registered executable parent. The computed success branch provides the
entire earlier conjunction; every error restores the same entry World.
The typed seam still excludes allocation-view calls and outer gateway/router
ABI transport. These omissions are not assumed boundary equalities. -/
theorem actual_topup_admission_calls_wei_and_revert
    (g : TopupRouterAdmissionCallGates.Environment) (input : Input) :
    let i := { input with hash := physicalKeccak }
    match (run g i).outcome with
    | .ok _ => ActualEffects g i
    | .error _ => (run g i).world = i.gateway.before := by
  dsimp only
  cases h : (run g { input with hash := physicalKeccak }).outcome with
  | ok value =>
    cases value
    exact actual_router_admission_complete_prior g _ h
  | «error» fault =>
    exact actual_gateway_entry_failure_restores g _ fault h

#print axioms actual_topup_admission_calls_wei_and_revert

#print axioms actual_router_admission_complete_prior
#print axioms actual_gateway_entry_failure_restores
end LidoSRv3.Audit.Guarantees.PTopupRouterAdmissionCall
