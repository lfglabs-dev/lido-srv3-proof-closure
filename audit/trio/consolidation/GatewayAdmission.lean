import audit.trio.consolidation.GatewayPreconditions

/-! Extended physical admission of ConsolidationGateway.addConsolidationRequests
at core17005714: the typed modifier gates (185), the pure guards and checked
count (189-199), the DSM/Lido preconditions (201) and the locator vault read
(203) execute in source order on the entry World, then the existing physical
entry/quota/settlement executor runs on the vault that was actually read.
The per-group witness loop (205-207) is composed in GatewayWitnessAdmission.
The pure gates and count are replayed by the retained suffix; they are functions
of the unchanged entry World, so the replay yields the same acceptance. Every
prefix failure and every suffix failure restores the entry World. -/
set_option autoImplicit false
namespace audit.trio.consolidation.GatewayAdmission
open LidoSRv3.Audit.Source.TrioReserve1 LidoSRv3.Audit.Source.TrioReserve1.Live

/-- Static prefix: role/balance/pause, pure guards and count, DSM/Lido, vault. -/
def entryPrefix (sexternal : StaticCall.External) (ctx : Context) (locator : Address)
    (msgValue : Word) (groups : List WitnessGroupBytes) (before : World) :
    GatewayPreconditions.Observed Address :=
  match PhysicalEntrySettlement.gates ctx msgValue before with
  | .error f => ⟨.error f,[]⟩
  | .ok () =>
  match PhysicalQuotaSettlement.prepare ctx msgValue groups before with
  | .error f => ⟨.error f,[]⟩
  | .ok _ =>
    let pre := GatewayPreconditions.preconditions sexternal ctx locator before
    match pre.outcome with
    | .error f => ⟨.error f,pre.attempts⟩
    | .ok () =>
      let vd := GatewayPreconditions.vaultData sexternal ctx locator before
      ⟨vd.outcome,pre.attempts ++ vd.attempts⟩

/-- Admission through line 203: the prior modifier admission, the accepted
pure count, the executed DSM/Lido preconditions and the executed vault read. -/
def Admitted (sexternal : StaticCall.External) (ctx : Context) (locator : Address)
    (msgValue : Word) (groups : List WitnessGroupBytes) (before : World) (vault : Address) : Prop :=
  PhysicalEntrySettlement.Admitted ctx msgValue before ∧
  PhysicalQuotaSettlement.prepare ctx msgValue groups before = .ok (GatewaySettlement.requestCount groups) ∧
  (GatewayPreconditions.preconditions sexternal ctx locator before).outcome = .ok () ∧
  (GatewayPreconditions.vaultData sexternal ctx locator before).outcome = .ok vault

theorem prefix_success (sexternal : StaticCall.External) (ctx : Context) (locator : Address)
    (msgValue : Word) (groups : List WitnessGroupBytes) (before : World) (vault : Address)
    (h : (entryPrefix sexternal ctx locator msgValue groups before).outcome = .ok vault) :
    Admitted sexternal ctx locator msgValue groups before vault ∧
    (entryPrefix sexternal ctx locator msgValue groups before).attempts =
      (GatewayPreconditions.preconditions sexternal ctx locator before).attempts ++
      (GatewayPreconditions.vaultData sexternal ctx locator before).attempts := by
  unfold entryPrefix at h ⊢
  cases hg : PhysicalEntrySettlement.gates ctx msgValue before with
  | «error» f => simp [hg] at h
  | ok u =>
    cases u
    simp only [hg] at h ⊢
    cases hp : PhysicalQuotaSettlement.prepare ctx msgValue groups before with
    | «error» f => simp [hp] at h
    | ok count =>
      simp only [hp] at h ⊢
      cases hpre : (GatewayPreconditions.preconditions sexternal ctx locator before).outcome with
      | «error» f => simp [hpre] at h
      | ok u =>
        cases u
        simp only [hpre] at h ⊢
        have hc := (PhysicalQuotaSettlement.prepare_success _ _ _ _ _ hp).1
        subst hc
        exact ⟨⟨PhysicalEntrySettlement.gates_success _ _ _ hg,hp,hpre,h⟩,by trivial⟩

structure Result where
  outcome : Except Fault Unit
  world : World
  trace : List NestedAttempt
  vault : Option Address
  suffix : Option PhysicalEntrySettlement.Result

/-- The read vault feeds the retained executor; the static prefix observations
precede the suffix trace. -/
def execute (callee : External) (sexternal : StaticCall.External) (ctx : Context)
    (locator gateway inbox recipient : Address) (msgValue : Word)
    (groups : List WitnessGroupBytes) (before : World) : Result :=
  let p := entryPrefix sexternal ctx locator msgValue groups before
  match p.outcome with
  | .error f => ⟨.error f,before,p.attempts,none,none⟩
  | .ok vault =>
    let r := PhysicalEntrySettlement.execute callee sexternal ctx vault gateway inbox recipient msgValue groups before
    ⟨r.outcome,r.world,p.attempts ++ r.trace,some vault,some r⟩

theorem execute_success (callee : External) (sexternal : StaticCall.External) (ctx : Context)
    (locator gateway inbox recipient : Address) (msgValue : Word)
    (groups : List WitnessGroupBytes) (before : World)
    (h : (execute callee sexternal ctx locator gateway inbox recipient msgValue groups before).outcome = .ok ()) :
    ∃ vault, Admitted sexternal ctx locator msgValue groups before vault ∧
      (entryPrefix sexternal ctx locator msgValue groups before).outcome = .ok vault ∧
      (PhysicalEntrySettlement.execute callee sexternal ctx vault gateway inbox recipient msgValue groups before).outcome = .ok () ∧
      execute callee sexternal ctx locator gateway inbox recipient msgValue groups before =
        ⟨.ok (),(PhysicalEntrySettlement.execute callee sexternal ctx vault gateway inbox recipient msgValue groups before).world,
          (entryPrefix sexternal ctx locator msgValue groups before).attempts ++
            (PhysicalEntrySettlement.execute callee sexternal ctx vault gateway inbox recipient msgValue groups before).trace,
          some vault,
          some (PhysicalEntrySettlement.execute callee sexternal ctx vault gateway inbox recipient msgValue groups before)⟩ := by
  unfold execute at h ⊢
  try dsimp only at h ⊢
  cases hp : (entryPrefix sexternal ctx locator msgValue groups before).outcome with
  | «error» f => simp [hp] at h
  | ok vault =>
    simp only [hp] at h ⊢
    exact ⟨vault,(prefix_success _ _ _ _ _ _ _ hp).1,by trivial,h,by rw [h]⟩

theorem failure_restores (callee : External) (sexternal : StaticCall.External) (ctx : Context)
    (locator gateway inbox recipient : Address) (msgValue : Word)
    (groups : List WitnessGroupBytes) (before : World) (f : Fault)
    (h : (execute callee sexternal ctx locator gateway inbox recipient msgValue groups before).outcome = .error f) :
    (execute callee sexternal ctx locator gateway inbox recipient msgValue groups before).world = before := by
  unfold execute at h ⊢
  try dsimp only at h ⊢
  cases hp : (entryPrefix sexternal ctx locator msgValue groups before).outcome with
  | «error» g => simp
  | ok vault =>
    simp only [hp] at h ⊢
    exact PhysicalEntrySettlement.failure_restores _ _ _ _ _ _ _ _ _ _ _ h

#print axioms prefix_success
#print axioms execute_success
#print axioms failure_restores
end audit.trio.consolidation.GatewayAdmission
