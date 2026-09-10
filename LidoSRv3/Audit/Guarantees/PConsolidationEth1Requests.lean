import LidoSRv3.Audit.Guarantees.PConsolidationEth1ActualSettlement
import audit.trio.consolidation.SettlementRequests

namespace LidoSRv3.Audit.Guarantees.PConsolidationEth1
open Source.TrioReserve1 Source.TrioReserve1.Live
open audit.trio.consolidation

/-- The same successful settlement executes width-valid decoded inbox requests
and refunds from their returned world. Outer quote and inner fee reread are
kept separate. The existing settlement certificate, exact fee split, final
balance assertion and complete attempt trace are retained without extra
stage-success, ABI-roundtrip or callee-frame hypotheses. -/
theorem actual_settlement_requests (callee : External) (sexternal : StaticCall.External)
    (ctx : Context) (vault gateway inbox recipient : Address) (msgValue : Live.Word)
    (groups : List WitnessGroupBytes) (before : World)
    (h : (GatewaySettlement.execute callee callee sexternal ctx vault gateway inbox recipient
      msgValue groups before).outcome = .ok ()) :
    GatewaySettlement.Success callee callee sexternal ctx vault gateway inbox recipient msgValue groups before ∧
    SettlementRequests.Effects callee sexternal ctx vault gateway inbox recipient msgValue groups before :=
  SettlementRequests.execute_success callee sexternal ctx vault gateway inbox recipient msgValue groups before h

#print axioms actual_settlement_requests
end LidoSRv3.Audit.Guarantees.PConsolidationEth1
