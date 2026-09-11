import audit.trio.consolidation.PhysicalEntrySettlement
namespace LidoSRv3.Audit.Guarantees.PConsolidationEth1
open Source.TrioReserve1 Source.TrioReserve1.Live
open audit.trio.consolidation

/-- Actual modifier admission then the ENTIRE prior physical-quota public
conjunction, with the exact returned result. Omitted DSM/locator/witness
preconditions remain outside; no independent successful-stage premise. -/
theorem actual_physical_entry_quota_settlement_requests (callee : External)
    (sexternal : StaticCall.External) (ctx : Context)
    (vault gateway inbox recipient : Address) (msgValue : Live.Word)
    (groups : List WitnessGroupBytes) (before : World)
    (h : (PhysicalEntrySettlement.execute callee sexternal ctx vault gateway inbox recipient
      msgValue groups before).outcome = .ok ()) :
    PhysicalEntrySettlement.Admitted ctx msgValue before ∧
    PhysicalEntrySettlement.execute callee sexternal ctx vault gateway inbox recipient msgValue groups before =
      PhysicalEntrySettlement.ofPrior (PhysicalQuotaSettlement.execute callee sexternal ctx vault gateway inbox recipient msgValue groups before) ∧
    (∃ u,
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
      SettlementRequests.Effects callee sexternal ctx vault gateway inbox recipient msgValue groups afterQuota) := by
  obtain ⟨ha,hp,he⟩ := PhysicalEntrySettlement.execute_success _ _ _ _ _ _ _ _ _ _ h
  exact ⟨ha,he,actual_physical_quota_settlement_requests _ _ _ _ _ _ _ _ _ _ hp⟩

/-- All failures restore the original credited entry World, including quota
and late callback effects. Attempt traces preserve their inherited meaning. -/
theorem actual_physical_entry_failure_restores (callee : External)
    (sexternal : StaticCall.External) (ctx : Context)
    (vault gateway inbox recipient : Address) (msgValue : Live.Word)
    (groups : List WitnessGroupBytes) (before : World) (f : Fault)
    (h : (PhysicalEntrySettlement.execute callee sexternal ctx vault gateway inbox recipient
      msgValue groups before).outcome = .error f) :
    (PhysicalEntrySettlement.execute callee sexternal ctx vault gateway inbox recipient
      msgValue groups before).world = before :=
  PhysicalEntrySettlement.failure_restores _ _ _ _ _ _ _ _ _ _ _ h

#print axioms actual_physical_entry_quota_settlement_requests
#print axioms actual_physical_entry_failure_restores
end LidoSRv3.Audit.Guarantees.PConsolidationEth1
