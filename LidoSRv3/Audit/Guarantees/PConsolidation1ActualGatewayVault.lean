import LidoSRv3.Audit.Guarantees.PConsolidation1
import LidoSRv3.Audit.Guarantees.PConsolidationEth1PhysicalEntry

namespace LidoSRv3.Audit.Guarantees.PConsolidation1
open Source.TrioReserve1 Source.TrioReserve1.Live
open audit.trio.consolidation

/-- Actual gateway-to-vault CALL success derives authorization, exact fee,
width-valid decoded requests and the consumer world/trace. Full gateway
prefix and array-allocation provenance remain internal composition work. -/
theorem actual_gateway_vault_requests (callee : External) (sexternal : StaticCall.External)
    (ctx : Context) (vault gateway inbox : Address) (value : Live.Word)
    (groups : List WitnessGroupBytes) (before : World) (returned : Bytes)
    (h : (GatewayCall.execute callee sexternal ctx vault gateway inbox value groups before).outcome = .ok returned) :
    ctx.self = gateway ∧
    ∃ sources targets data sats attempts,
      decodeVaultArgs (gatewayVaultArgs (GatewayCall.sourceArray groups) (GatewayCall.targetArray groups)) = some (sources, targets) ∧
      sources.length ≠ 0 ∧ sources.length = targets.length ∧
      lowLevelStaticCall sexternal vault inbox [] (transfer before ctx.self vault value.val) =
        ⟨.ok data, sats⟩ ∧
      data.length = 32 ∧ sources.length * (Live.word (decode data)).val = value.val ∧
      (∀ p ∈ pairsOf sources targets, widthOk p) ∧
      attempts.map (·.request) = hopRequests ⟨vault, ctx.self⟩ inbox
        (Live.word (decode data)) (pairsOf sources targets) ∧
      (GatewayCall.execute callee sexternal ctx vault gateway inbox value groups before).world =
        (addConsolidationRequestsLoop callee ⟨vault, ctx.self⟩ inbox (Live.word (decode data))
          (pairsOf sources targets) (transfer before ctx.self vault value.val)).world ∧
      (GatewayCall.execute callee sexternal ctx vault gateway inbox value groups before).attempts =
        [⟨⟨ctx.self, vault, value,
          gatewayVaultCalldata GatewayCall.selector (GatewayCall.sourceArray groups) (GatewayCall.targetArray groups)⟩,
          true, [], sats ++ GatewayCall.callTrace attempts⟩] :=
  GatewayCall.execute_success_requests callee sexternal ctx vault gateway inbox value groups before returned h

/-- Failure of this actual vault CALL restores the caller world before its
value transfer. This is the call-frame rollback, not the full gateway entry. -/
theorem actual_gateway_vault_failure_restores (callee : External) (sexternal : StaticCall.External)
    (ctx : Context) (vault gateway inbox : Address) (value : Live.Word)
    (groups : List WitnessGroupBytes) (before : World) (fault : Fault)
    (h : (GatewayCall.execute callee sexternal ctx vault gateway inbox value groups before).outcome =
      .error fault) :
    (GatewayCall.execute callee sexternal ctx vault gateway inbox value groups before).world = before :=
  GatewayCall.invoke_failure_restores (GatewayCall.vaultExternal callee sexternal gateway inbox)
    ctx vault value (GatewayCall.sourceArray groups) (GatewayCall.targetArray groups) before fault h

/-- Complete existing physical-entry/quota/settlement certificate. Every
boundary equality here is a derived conclusion of root execution, never a
caller-supplied frame premise. The same External handles inbox and refund,
including address aliases. Outer payable credit, DSM/locator/witness checks,
source allocation extents and deployed-code refinement remain outside scope. -/
abbrev GatewayVaultEffects (callee : External) (sexternal : StaticCall.External)
    (ctx : Context) (vault gateway inbox recipient : Address) (msgValue : Live.Word)
    (groups : List WitnessGroupBytes) (before : World) : Prop :=
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
      SettlementRequests.Effects callee sexternal ctx vault gateway inbox recipient msgValue groups afterQuota)

/-- Registered executable gateway-to-vault parent. Actual root success derives
physical admission and quota state, fee STATICCALL observations, checked
count/fee/value/refund arithmetic, raw-byte ABI production and decoding,
per-request inbox CALLs, and final refund world/trace. Root failure restores
the original credited world, including quota and earlier callback effects.

This preserves the reviewed handoff's composition intent using the stronger
current physical-entry executor. It assumes neither desired boundary equality
nor independent fee, stage-success, or refund-success facts. It does not
identify this executor with the historical slot-free projection. -/
theorem gateway_vault_live_success_and_revert
    (callee : External) (sexternal : StaticCall.External) (ctx : Context)
    (vault gateway inbox recipient : Address) (msgValue : Live.Word)
    (groups : List WitnessGroupBytes) (before : World) :
    let result := PhysicalEntrySettlement.execute callee sexternal ctx vault gateway
      inbox recipient msgValue groups before
    match result.outcome with
    | .ok _ => GatewayVaultEffects callee sexternal ctx vault gateway inbox recipient
        msgValue groups before
    | .error _ => result.world = before := by
  dsimp only
  cases h : (PhysicalEntrySettlement.execute callee sexternal ctx vault gateway
      inbox recipient msgValue groups before).outcome with
  | ok value =>
      cases value
      exact PConsolidationEth1.actual_physical_entry_quota_settlement_requests
        callee sexternal ctx vault gateway inbox recipient msgValue groups before h
  | «error» fault =>
      exact PConsolidationEth1.actual_physical_entry_failure_restores
        callee sexternal ctx vault gateway inbox recipient msgValue groups before fault h

#print axioms gateway_vault_live_success_and_revert

#print axioms actual_gateway_vault_failure_restores
#print axioms actual_gateway_vault_requests
end LidoSRv3.Audit.Guarantees.PConsolidation1
