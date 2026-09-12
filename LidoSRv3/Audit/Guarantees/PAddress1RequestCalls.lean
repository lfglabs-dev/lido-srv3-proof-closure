import LidoSRv3.Audit.Source.AddressRequestCalls

/-! Public one-item WQ request consumers. Supplementary to PAddress1's existing
claim consumers and abstract equivariance theorem; no guarantee-status change. -/
namespace LidoSRv3.Audit.Guarantees.PAddress1
open LidoSRv3.Audit.Source.AddressRequestCalls
open LidoSRv3.Audit.Source.TrioReserve1.Live
open LidoSRv3.Audit.Verity.AddressRecipientCallBridge (StaticExternal)

/-- Whole request success derives admission, actual transfer/quote effects on the
same returned world, truncating casts, checked sums/ID, physical ordered enqueue,
owner insertion and both final events. No stage success, shares-fit or alias
premise; the pause/batch wrapper and final slot re-reads are outside this slice. -/
theorem actual_request_withdrawal_enqueue (callee : External) (quote : StaticExternal)
    (ctx : Context) (stETH : Verity.Address) (amount : Nat) (owner : Verity.Address)
    (id : Nat) (before : World)
    (h : (runRequest callee quote ctx stETH amount owner before).outcome = .ok id) :
    RequestEffect callee quote ctx stETH amount owner id before
      (runRequest callee quote ctx stETH amount owner before).world
      (runRequest callee quote ctx stETH amount owner before).attempts :=
  run_success callee quote ctx stETH amount owner id before h

/-- Reverting one-item execution restores all modeled entry storage, balances
and events, including transferFrom effects. Attempts remain audit observations. -/
theorem actual_request_withdrawal_failure_restores (callee : External) (quote : StaticExternal)
    (ctx : Context) (stETH : Verity.Address) (amount : Nat) (owner : Verity.Address)
    (before : World) (fault : Fault)
    (h : (runRequest callee quote ctx stETH amount owner before).outcome = .error fault) :
    (runRequest callee quote ctx stETH amount owner before).world = before :=
  run_failure_restores callee quote ctx stETH amount owner before fault h
end LidoSRv3.Audit.Guarantees.PAddress1
