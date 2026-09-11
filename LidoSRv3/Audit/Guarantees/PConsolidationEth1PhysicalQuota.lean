import audit.trio.consolidation.PhysicalQuotaSettlement

namespace LidoSRv3.Audit.Guarantees.PConsolidationEth1
open Source.TrioReserve1 Source.TrioReserve1.Live
open audit.trio.consolidation

/-- Same execution: physical quota from the original entry, then the ENTIRE
accepted settlement certificate and decoded inbox/refund effects on its actual
post-quota World. No separate stage-success, frame or initialization premise. -/
theorem actual_physical_quota_settlement_requests (callee : External)
    (sexternal : StaticCall.External) (ctx : Context)
    (vault gateway inbox recipient : Address) (msgValue : Live.Word)
    (groups : List WitnessGroupBytes) (before : World)
    (h : (PhysicalQuotaSettlement.execute callee sexternal ctx vault gateway inbox recipient
      msgValue groups before).outcome = .ok ()) :
    ∃ u,
      PhysicalQuotaSettlement.prepare ctx msgValue groups before = .ok (GatewaySettlement.requestCount groups) ∧
      GatewaySettlement.requestCount groups < Verity.Core.UINT256_MODULUS ∧
      PhysicalQuotaSettlement.transition (PhysicalQuotaSettlement.stored ctx.self before)
        before.core.blockTimestamp.val (GatewaySettlement.requestCount groups) = .ok u ∧
      PhysicalQuotaSettlement.QuotaEffects ctx.self before (GatewaySettlement.requestCount groups) u ∧
      let afterQuota := PhysicalQuotaSettlement.postQuota ctx.self before u
      PhysicalQuotaSettlement.execute callee sexternal ctx vault gateway inbox recipient msgValue groups before =
        PhysicalQuotaSettlement.ofPrior (GatewaySettlement.requestCount groups) u
          (GatewaySettlement.execute callee callee sexternal ctx vault gateway inbox recipient msgValue groups afterQuota) ∧
      GatewaySettlement.Success callee callee sexternal ctx vault gateway inbox recipient msgValue groups afterQuota ∧
      SettlementRequests.Effects callee sexternal ctx vault gateway inbox recipient msgValue groups afterQuota := by
  obtain ⟨count,u,hp,hq,hs,he⟩ := PhysicalQuotaSettlement.execute_success _ _ _ _ _ _ _ _ _ _ h
  obtain ⟨hc,hfit⟩ := PhysicalQuotaSettlement.prepare_success _ _ _ _ _ hp
  subst count
  exact ⟨u,hp,hfit,hq,PhysicalQuotaSettlement.quota_effects _ _ _ _ hq,he,
    actual_settlement_requests _ _ _ _ _ _ _ _ _ _ hs⟩

/-- Root rollback includes the quota write even after vault/inbox/refund effects.
Attempt traces remain observable under the inherited diagnostic semantics. -/
theorem actual_physical_quota_failure_restores (callee : External)
    (sexternal : StaticCall.External) (ctx : Context)
    (vault gateway inbox recipient : Address) (msgValue : Live.Word)
    (groups : List WitnessGroupBytes) (before : World) (f : Fault)
    (h : (PhysicalQuotaSettlement.execute callee sexternal ctx vault gateway inbox recipient
      msgValue groups before).outcome = .error f) :
    (PhysicalQuotaSettlement.execute callee sexternal ctx vault gateway inbox recipient
      msgValue groups before).world = before :=
  PhysicalQuotaSettlement.failure_restores _ _ _ _ _ _ _ _ _ _ _ h

#print axioms actual_physical_quota_settlement_requests
#print axioms actual_physical_quota_failure_restores
end LidoSRv3.Audit.Guarantees.PConsolidationEth1
