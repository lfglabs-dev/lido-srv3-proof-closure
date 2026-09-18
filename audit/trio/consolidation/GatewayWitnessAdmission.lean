import audit.trio.consolidation.WitnessProof

/-! Whole-prefix physical admission of ConsolidationGateway.addConsolidationRequests
at core17005714: the GatewayAdmission prefix through the locator vault read
(185-203), then the per-group witness loop against that vault's 0x02
credentials (205-207), then the retained physical entry/quota/settlement
executor (209-222) on the same entry World and the read vault. The witness
checks are read-only; their EIP-4788 STATICCALLs join the trace between the
prefix observations and the suffix trace. Every failure restores the entry
World. Outer ABI/payable credit remains outside. -/
set_option autoImplicit false
namespace audit.trio.consolidation.GatewayWitnessAdmission
open LidoSRv3.Audit.Source
open LidoSRv3.Audit.Source.TrioReserve1 LidoSRv3.Audit.Source.TrioReserve1.Live
open SszWrapperIndex

structure Result where
  outcome : Except Fault Unit
  world : World
  trace : List NestedAttempt
  vault : Option Address
  suffix : Option PhysicalEntrySettlement.Result

/-- The producer view of the typed groups. -/
def bytesOf (groups : List WitnessProof.WitnessGroup) : List WitnessGroupBytes :=
  groups.map WitnessProof.WitnessGroup.bytes

def execute (callee : External) (sexternal : StaticCall.External) (ctx : Context)
    (locator gateway inbox recipient : Address) (cfg : Configuration) (msgValue : Word)
    (groups : List WitnessProof.WitnessGroup) (before : World) : Result :=
  let p := GatewayAdmission.entryPrefix sexternal ctx locator msgValue (bytesOf groups) before
  match p.outcome with
  | .error f => ⟨.error f,before,p.attempts,none,none⟩
  | .ok vault =>
    let c := WitnessProof.validateAll sexternal cfg ctx (WitnessProof.credentialsWord vault) groups before
    match c.outcome with
    | .error f => ⟨.error f,before,p.attempts ++ c.attempts,some vault,none⟩
    | .ok () =>
      let r := PhysicalEntrySettlement.execute callee sexternal ctx vault gateway inbox recipient
        msgValue (bytesOf groups) before
      ⟨r.outcome,r.world,p.attempts ++ c.attempts ++ r.trace,some vault,some r⟩

/-- Whole-prefix admission: the extended admission through the vault read,
and every group's witness check passed against that vault's credentials. -/
def Admitted (sexternal : StaticCall.External) (ctx : Context) (locator : Address)
    (cfg : Configuration) (msgValue : Word) (groups : List WitnessProof.WitnessGroup)
    (before : World) (vault : Address) : Prop :=
  GatewayAdmission.Admitted sexternal ctx locator msgValue (bytesOf groups) before vault ∧
  (WitnessProof.validateAll sexternal cfg ctx (WitnessProof.credentialsWord vault) groups before).outcome = .ok () ∧
  ∀ g ∈ groups, WitnessProof.Passed sexternal cfg ctx (WitnessProof.credentialsWord vault) g.witness before

theorem execute_success (callee : External) (sexternal : StaticCall.External) (ctx : Context)
    (locator gateway inbox recipient : Address) (cfg : Configuration) (msgValue : Word)
    (groups : List WitnessProof.WitnessGroup) (before : World)
    (h : (execute callee sexternal ctx locator gateway inbox recipient cfg msgValue groups before).outcome = .ok ()) :
    ∃ vault, Admitted sexternal ctx locator cfg msgValue groups before vault ∧
      (PhysicalEntrySettlement.execute callee sexternal ctx vault gateway inbox recipient msgValue
        (bytesOf groups) before).outcome = .ok () ∧
      execute callee sexternal ctx locator gateway inbox recipient cfg msgValue groups before =
        ⟨.ok (),(PhysicalEntrySettlement.execute callee sexternal ctx vault gateway inbox recipient msgValue
            (bytesOf groups) before).world,
          (GatewayAdmission.entryPrefix sexternal ctx locator msgValue (bytesOf groups) before).attempts ++
            (WitnessProof.validateAll sexternal cfg ctx (WitnessProof.credentialsWord vault) groups before).attempts ++
            (PhysicalEntrySettlement.execute callee sexternal ctx vault gateway inbox recipient msgValue
              (bytesOf groups) before).trace,
          some vault,
          some (PhysicalEntrySettlement.execute callee sexternal ctx vault gateway inbox recipient msgValue
            (bytesOf groups) before)⟩ := by
  unfold execute at h ⊢
  try dsimp only at h ⊢
  cases hp : (GatewayAdmission.entryPrefix sexternal ctx locator msgValue (bytesOf groups) before).outcome with
  | «error» f => simp [hp] at h
  | ok vault =>
    simp only [hp] at h ⊢
    cases hc : (WitnessProof.validateAll sexternal cfg ctx (WitnessProof.credentialsWord vault) groups before).outcome with
    | «error» f => simp [hc] at h
    | ok u =>
      cases u
      simp only [hc] at h ⊢
      exact ⟨vault,⟨(GatewayAdmission.prefix_success _ _ _ _ _ _ _ hp).1,hc,
        WitnessProof.validateAll_success _ _ _ _ _ _ hc⟩,h,by rw [h]⟩

theorem failure_restores (callee : External) (sexternal : StaticCall.External) (ctx : Context)
    (locator gateway inbox recipient : Address) (cfg : Configuration) (msgValue : Word)
    (groups : List WitnessProof.WitnessGroup) (before : World) (f : Fault)
    (h : (execute callee sexternal ctx locator gateway inbox recipient cfg msgValue groups before).outcome = .error f) :
    (execute callee sexternal ctx locator gateway inbox recipient cfg msgValue groups before).world = before := by
  unfold execute at h ⊢
  try dsimp only at h ⊢
  cases hp : (GatewayAdmission.entryPrefix sexternal ctx locator msgValue (bytesOf groups) before).outcome with
  | «error» g => simp
  | ok vault =>
    simp only [hp] at h ⊢
    cases hc : (WitnessProof.validateAll sexternal cfg ctx (WitnessProof.credentialsWord vault) groups before).outcome with
    | «error» g => simp
    | ok u =>
      cases u
      simp only [hc] at h ⊢
      exact PhysicalEntrySettlement.failure_restores _ _ _ _ _ _ _ _ _ _ _ h

#print axioms execute_success
#print axioms failure_restores
end audit.trio.consolidation.GatewayWitnessAdmission
