import audit.trio.consolidation.GatewaySettlement

/-! Same executed settlement, actual decoded inbox requests, and refund world.
No executor or stage-success premise is introduced. Outer and inner fee reads
remain distinct: the latter observes the actual value-credited vault world. -/
namespace audit.trio.consolidation.SettlementRequests
open LidoSRv3.Audit.Source.TrioReserve1
open LidoSRv3.Audit.Source.TrioReserve1.Live

/-- Necessary same-execution composition. Raw gateway byte arrays remain
explicit in the decoder and actual CALL payload; decoded pairs, not assumed
canonical input identities, determine the real inbox loop. -/
def Effects (callee : External) (sexternal : StaticCall.External)
    (ctx : Context) (vault gateway inbox recipient : Address) (msgValue : Word)
    (groups : List WitnessGroupBytes) (before : World) : Prop :=
  ctx.self = gateway ∧
  ∃ fee outerData quoteAttempts sources targets innerData innerAttempts,
    (GatewaySettlement.quote sexternal ctx vault inbox before).outcome = .ok fee ∧
    lowLevelStaticCall sexternal vault inbox [] before = ⟨.ok outerData,quoteAttempts⟩ ∧
    outerData.length = 32 ∧ fee = Live.word (decode outerData) ∧
    (GatewayCall.sourceArray groups).length = GatewaySettlement.requestCount groups ∧
    let total := Live.word (GatewaySettlement.requestCount groups * fee.val)
    let refund := Live.word (msgValue.val - GatewaySettlement.requestCount groups * fee.val)
    let credited := transfer before ctx.self vault total.val
    let loop := addConsolidationRequestsLoop callee ⟨vault,ctx.self⟩ inbox
      (Live.word (decode innerData)) (pairsOf sources targets) credited
    let v := GatewayCall.execute callee sexternal ctx vault gateway inbox total groups before
    let r := refundFee callee ctx refund recipient loop.world
    total.val = GatewaySettlement.requestCount groups * fee.val ∧
    total.val + refund.val = msgValue.val ∧ checkFee msgValue total = .ok refund ∧
    decodeVaultArgs (gatewayVaultArgs (GatewayCall.sourceArray groups) (GatewayCall.targetArray groups)) =
      some (sources,targets) ∧
    sources.length ≠ 0 ∧ sources.length = targets.length ∧
    lowLevelStaticCall sexternal vault inbox [] credited = ⟨.ok innerData,innerAttempts⟩ ∧
    innerData.length = 32 ∧ sources.length * (Live.word (decode innerData)).val = total.val ∧
    loop.outcome = .ok () ∧ (∀ p ∈ pairsOf sources targets, widthOk p) ∧
    loop.attempts.map (·.request) = hopRequests ⟨vault,ctx.self⟩ inbox
      (Live.word (decode innerData)) (pairsOf sources targets) ∧
    v.world = loop.world ∧
    v.attempts = [⟨⟨ctx.self,vault,total,
      gatewayVaultCalldata GatewayCall.selector (GatewayCall.sourceArray groups) (GatewayCall.targetArray groups)⟩,
      true,[],innerAttempts ++ GatewayCall.callTrace loop.attempts⟩] ∧
    r.outcome = .ok () ∧
    (∀ a ∈ r.attempts, a.request = refundRequest ctx refund recipient) ∧
    (refund.val = 0 → r = ⟨.ok (),loop.world,[]⟩) ∧
    (GatewaySettlement.execute callee callee sexternal ctx vault gateway inbox recipient msgValue groups before).world = r.world ∧
    (GatewaySettlement.execute callee callee sexternal ctx vault gateway inbox recipient msgValue groups before).trace =
      GatewaySettlement.quoteTrace ctx vault true (encode 32 fee.val) quoteAttempts ++
      (GatewayCall.callTrace v.attempts ++ GatewayCall.callTrace r.attempts) ∧
    r.world.balances ctx.self = before.balances ctx.self - msgValue.val

theorem execute_success (callee : External) (sexternal : StaticCall.External)
    (ctx : Context) (vault gateway inbox recipient : Address) (msgValue : Word)
    (groups : List WitnessGroupBytes) (before : World)
    (h : (GatewaySettlement.execute callee callee sexternal ctx vault gateway inbox recipient
      msgValue groups before).outcome = .ok ()) :
    GatewaySettlement.Success callee callee sexternal ctx vault gateway inbox recipient msgValue groups before ∧
    Effects callee sexternal ctx vault gateway inbox recipient msgValue groups before := by
  have hs := GatewaySettlement.execute_success callee callee sexternal ctx vault gateway inbox recipient msgValue groups before h
  refine ⟨hs,?_⟩
  obtain ⟨fee,outerData,qats,hq,hread,hlen,hfee,_,_,_,htotal,hsplit,hcheck,hsettle,hrequests,hzero,hw,ht⟩ := hs.effects
  obtain ⟨returned,hv⟩ := hsettle.vaultOk
  obtain ⟨_,_,sources,targets,hd,vaultSuccess,hvw,hva⟩ :=
    GatewayCall.execute_success callee sexternal ctx vault gateway inbox _ groups before returned hv
  obtain ⟨innerData,sats,hi,hilength,hifee,hloop,hloopworld,hlooptrace,_⟩ := vaultSuccess.effects
  obtain ⟨hold,holdworld,holdtrace⟩ := GatewayCall.loop_success_projection callee ⟨vault,ctx.self⟩ inbox _ _ _ hloop
  obtain ⟨hwidth,hrequest,_⟩ := loop_success callee ⟨vault,ctx.self⟩ inbox _ _ _ hold
  have world := hvw.trans (hloopworld.trans holdworld)
  have attempts := hva.trans (by rw [hlooptrace,holdtrace])
  refine ⟨vaultSuccess.authorized,fee,outerData,qats,sources,targets,innerData,sats,hq,hread,hlen,hfee,
    GatewaySettlement.requestCount_sourceArray groups,htotal,hsplit,hcheck,hd,
    vaultSuccess.nonempty,vaultSuccess.sameLength,hi,hilength,hifee,hold,hwidth,hrequest,
    world,attempts,?_,?_,?_,?_,?_,?_⟩
  · rw [← world]
    exact hsettle.refundOk
  · rw [← world]
    exact hrequests
  · rw [← world]
    exact hzero
  · rw [← world]
    exact hw
  · rw [← world]
    exact ht
  · rw [← world]
    exact hsettle.balance

#print axioms execute_success
end audit.trio.consolidation.SettlementRequests
