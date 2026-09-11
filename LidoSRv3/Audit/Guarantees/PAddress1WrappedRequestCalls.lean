import LidoSRv3.Audit.Source.AddressWrappedRequestCalls

namespace LidoSRv3.Audit.Guarantees.PAddress1
open LidoSRv3.Audit.Source.AddressWrappedRequestCalls
open LidoSRv3.Audit.Source.TrioReserve1.Live
open LidoSRv3.Audit.Verity.AddressRecipientCallBridge (StaticExternal)

/-- WithdrawalQueue's one-item wrapped request: actual transferFrom, then actual
unwrap CALL on its returned world, decoded amount admission, STETH STATICCALL
and the same physical enqueue/events. No extra STETH transferFrom and no supplied
successful stage. The WSTETH implementation's burn/allowance semantics, initial
pause/batch/ABI setup and deployed-EVM correspondence remain separate boundaries. -/
theorem actual_wrapped_request_withdrawal_enqueue (callee : External) (quote : StaticExternal)
    (ctx : Context) (wstETH stETH : Verity.Address) (amount : Verity.Uint256)
    (owner : Verity.Address) (id : Nat) (before : World)
    (h : (runRequest callee quote ctx wstETH stETH amount owner before).outcome = .ok id) :
    RequestEffect callee quote ctx wstETH stETH amount owner id before
      (runRequest callee quote ctx wstETH stETH amount owner before).world
      (runRequest callee quote ctx wstETH stETH amount owner before).attempts :=
  run_success callee quote ctx wstETH stETH amount owner id before h

theorem actual_wrapped_request_withdrawal_failure_restores (callee : External) (quote : StaticExternal)
    (ctx : Context) (wstETH stETH : Verity.Address) (amount : Verity.Uint256)
    (owner : Verity.Address) (before : World) (fault : Fault)
    (h : (runRequest callee quote ctx wstETH stETH amount owner before).outcome = .error fault) :
    (runRequest callee quote ctx wstETH stETH amount owner before).world = before :=
  run_failure_restores callee quote ctx wstETH stETH amount owner before fault h
end LidoSRv3.Audit.Guarantees.PAddress1
