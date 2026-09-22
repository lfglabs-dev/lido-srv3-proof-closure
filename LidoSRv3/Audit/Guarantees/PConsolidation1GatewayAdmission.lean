import LidoSRv3.Audit.Guarantees.PConsolidation1ActualGatewayVault
import audit.trio.consolidation.GatewayAdmission

/-! Step 3a of the "not proven" cleanup (2026-09-18): the displayed executor
starts after the gateway's DSM/locator prefix. `GatewayAdmission.execute`
executes that prefix on the entry World (ConsolidationGateway.sol:201-203)
and feeds the vault it read into the retained physical executor. The witness
loop (205-207) is composed separately in PConsolidation1WitnessAdmission. -/
namespace LidoSRv3.Audit.Guarantees.PConsolidation1
open Source.TrioReserve1 Source.TrioReserve1.Live
open audit.trio.consolidation

/-- The existing success/rollback certificate under the extended admission.
Root success derives the prior modifier admission, the accepted count, the four
executed DSM/Lido static observations, the executed locator vault read, and the
complete GatewayVaultEffects certificate on that read vault; the world and trace
are the retained executor's, prefixed by the static observations. Any failure,
in the prefix or in the retained executor, restores the entry World. -/
theorem gateway_admission_live_success_and_revert
    (callee : External) (sexternal : StaticCall.External) (ctx : Context)
    (locator gateway inbox recipient : Address) (msgValue : Live.Word)
    (groups : List WitnessGroupBytes) (before : World) :
    let result := GatewayAdmission.execute callee sexternal ctx locator gateway inbox
      recipient msgValue groups before
    match result.outcome with
    | .ok _ => ∃ vault,
        GatewayAdmission.Admitted sexternal ctx locator msgValue groups before vault ∧
        GatewayVaultEffects callee sexternal ctx vault gateway inbox recipient msgValue groups before ∧
        result.world = (PhysicalEntrySettlement.execute callee sexternal ctx vault gateway inbox
          recipient msgValue groups before).world ∧
        result.trace = (GatewayAdmission.entryPrefix sexternal ctx locator msgValue groups before).attempts ++
          (PhysicalEntrySettlement.execute callee sexternal ctx vault gateway inbox
            recipient msgValue groups before).trace
    | .error _ => result.world = before := by
  dsimp only
  cases h : (GatewayAdmission.execute callee sexternal ctx locator gateway inbox
      recipient msgValue groups before).outcome with
  | ok value =>
      cases value
      obtain ⟨vault,ha,_,hs,he⟩ := GatewayAdmission.execute_success
        callee sexternal ctx locator gateway inbox recipient msgValue groups before h
      refine ⟨vault,ha,PConsolidationEth1.actual_physical_entry_quota_settlement_requests
        callee sexternal ctx vault gateway inbox recipient msgValue groups before hs,?_,?_⟩
      · rw [he]
      · rw [he]
  | «error» fault =>
      exact GatewayAdmission.failure_restores
        callee sexternal ctx locator gateway inbox recipient msgValue groups before fault h

#print axioms gateway_admission_live_success_and_revert
end LidoSRv3.Audit.Guarantees.PConsolidation1
