import LidoSRv3.Audit.Guarantees.PTopup1
import LidoSRv3.Audit.Source.TopupPipelineLedger

/-! Public necessary TOPUP-1 result for the source continuation after the
module CALL. Full gateway/router-entry correspondence remains separate. -/
namespace LidoSRv3.Audit.Guarantees.PTopup1
open Source Source.TrioReserve1 Source.TrioReserve1.Live Source.TopupRouterContinuation
open LidoSRv3.Audit.SolidityTopup

/-- The source continuation's success derives the value transfer and router
restoration. Positive success also derives the exact mathematical allocation
sum and nonempty keys; no successful withdrawal or beacon-stage premises are inputs. -/
theorem actual_continuation_conserves (hash : TopupRouterCredentials.Keccak)
    (k : Queue.Keccak) (config : Pipeline.Config)
    (staticOther : StaticCall.External) (other : External)
    (ctx : Context) (beacon : Address) (i : Input) (before : World)
    (bound : Pipeline.Bound config ctx before)
    (lido_ne_router : ctx.self ≠ ctx.sender) (router_ne_beacon : ctx.sender ≠ beacon)
    (h : (execute hash (Pipeline.external k config staticOther other) ctx beacon i before).outcome = .ok ()) :
    ∃ total, guardSum (values i.allocations) (values i.limits) 0 = .ok total ∧
      total ≤ i.roundedTarget.val ∧
      CallSpec.Balances before.balances
        (execute hash (Pipeline.external k config staticOther other) ctx beacon i before).world.balances
        ctx.self beacon total ∧
      (execute hash (Pipeline.external k config staticOther other) ctx beacon i before).world.balances ctx.sender =
        before.balances ctx.sender ∧
      (total = 0 ∨ (i.pubkeys ≠ [] ∧ total = allocSum (values i.allocations))) :=
  TopupPipelineLedger.execute_success_conservation hash k config staticOther other
    ctx beacon i before bound lido_ne_router router_ne_beacon h

#print axioms actual_continuation_conserves
end LidoSRv3.Audit.Guarantees.PTopup1
