import LidoSRv3.Audit.Source.NoReentry
import LidoSRv3.Audit.Guarantees.PTopup1MinimalLedger

/-! # P-TOPUP-1 under A-NO-REENTRY

`actual_continuation_locator_conserves` threads the exact worlds returned by
the pinned locator/queue/oracle/router dispatch chain and leaves the residual
interpreter `other` (module `obtainDepositData` bodies and the beacon deposit
contract) arbitrary. Under `NoReentry other [lido, router]` the continuation
ledger holds as before and, in addition, every CALL that reaches `other`
leaves Lido's and the router's storage unchanged, never succeeds when it
targets either of them, and records no accepted nested call into them.

**Status:** corollary of the registered
`actual_continuation_locator_conserves`; the premise is the accepted
assumption `A-NO-REENTRY`. -/

namespace LidoSRv3.Audit.Guarantees.PTopup1NoReentry

open LidoSRv3.Audit.Source Source.TrioReserve1 Source.TrioReserve1.Live
  Source.TopupRouterContinuation
open LidoSRv3.Audit.SolidityTopup
open LidoSRv3.Audit.Source.NoReentry

theorem actual_continuation_locator_conserves_no_reentry (hash : TopupRouterCredentials.Keccak)
    (k : Queue.Keccak) (config : Pipeline.Config)
    (staticOther : StaticCall.External) (other : External)
    (ctx : Context) (beacon : Address) (i : Input) (before : World)
    (bound : audit.trio.deposit.WithdrawalLedgerMinimal.LocatorBound config ctx before)
    (lido_ne_router : ctx.self ≠ ctx.sender) (router_ne_beacon : ctx.sender ≠ beacon)
    (hNo : NoReentry other [ctx.self, ctx.sender])
    (h : (execute hash (Pipeline.external k config staticOther other) ctx beacon i before).outcome =
      .ok ()) :
    (∃ total, guardSum (values i.allocations) (values i.limits) 0 = .ok total ∧
      total ≤ i.roundedTarget.val ∧
      CallSpec.Balances before.balances
        (execute hash (Pipeline.external k config staticOther other) ctx beacon i before).world.balances
        ctx.self beacon total ∧
      (execute hash (Pipeline.external k config staticOther other) ctx beacon i before).world.balances
          ctx.sender =
        before.balances ctx.sender ∧
      (total = 0 ∨ (i.pubkeys ≠ [] ∧ total = allocSum (values i.allocations)))) ∧
    Confined other [ctx.self, ctx.sender] :=
  ⟨PTopup1.actual_continuation_locator_conserves hash k config staticOther other ctx beacon i
      before bound lido_ne_router router_ne_beacon h,
    confined_of_noReentry hNo⟩

end LidoSRv3.Audit.Guarantees.PTopup1NoReentry
