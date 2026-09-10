import audit.trio.consolidation.GatewaySettlement

/-! Public consumer for the same-world fee→vault→refund suffix. The certificate
exposes actual executions, exact fee arithmetic, sequential worlds and traces.
One shared External interprets both inbox and refund calls, including aliases.
The admitted payable world and omitted gateway prefix remain explicit scope;
this is not aggregate recipient-credit or whole-deployment correspondence. -/
namespace LidoSRv3.Audit.Guarantees.PConsolidationEth1
open Source.TrioReserve1 Source.TrioReserve1.Live
open audit.trio.consolidation

/-- Success of the executed suffix derives the checked count and fee quote,
actual vault CALL, refund on its returned world, exact value split, combined
traces and gateway's final balance assertion. No successful-stage receipts,
funding, BalanceFrame, LogFrame or Untraced premises are supplied. -/
theorem actual_settlement_success (callee : External)
    (staticExternal : StaticCall.External) (ctx : Context)
    (vault gateway inbox recipient : Address) (msgValue : Live.Word)
    (groups : List WitnessGroupBytes) (before : World)
    (h : (GatewaySettlement.execute callee callee staticExternal ctx
      vault gateway inbox recipient msgValue groups before).outcome = .ok ()) :
    GatewaySettlement.Success callee callee staticExternal ctx
      vault gateway inbox recipient msgValue groups before :=
  GatewaySettlement.execute_success callee callee staticExternal ctx
    vault gateway inbox recipient msgValue groups before h

/-- Any failed suffix, including refund failure after successful vault effects,
restores the whole incoming suffix world under the declared root model rule. -/
theorem actual_settlement_failure_restores (callee : External)
    (staticExternal : StaticCall.External) (ctx : Context)
    (vault gateway inbox recipient : Address) (msgValue : Live.Word)
    (groups : List WitnessGroupBytes) (before : World) (fault : Fault)
    (h : (GatewaySettlement.execute callee callee staticExternal ctx
      vault gateway inbox recipient msgValue groups before).outcome = .error fault) :
    (GatewaySettlement.execute callee callee staticExternal ctx
      vault gateway inbox recipient msgValue groups before).world = before :=
  GatewaySettlement.failure_restores callee callee staticExternal ctx
    vault gateway inbox recipient msgValue groups before fault h

#print axioms actual_settlement_success
#print axioms actual_settlement_failure_restores
end LidoSRv3.Audit.Guarantees.PConsolidationEth1
