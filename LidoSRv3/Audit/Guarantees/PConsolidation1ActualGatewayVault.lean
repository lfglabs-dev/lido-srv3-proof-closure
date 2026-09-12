import LidoSRv3.Audit.Guarantees.PConsolidation1
import audit.trio.consolidation.GatewayCall

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

#print axioms actual_gateway_vault_failure_restores
#print axioms actual_gateway_vault_requests
end LidoSRv3.Audit.Guarantees.PConsolidation1
