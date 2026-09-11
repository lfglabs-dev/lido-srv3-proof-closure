import LidoSRv3.Audit.Source.AddressPermitRequestCalls
namespace LidoSRv3.Audit.Guarantees.PAddress1
open LidoSRv3.Audit.Source.TrioReserve1.Live
open LidoSRv3.Audit.Source.AddressRequestBatches
open LidoSRv3.Audit.Source.AddressPermitRequestCalls
open LidoSRv3.Audit.Verity.AddressRecipientCallBridge (StaticExternal)

/-- Actual permit CALL then the complete typed stETH batch effect on its returned
world. The permit implementation is external; no signature/body claim is made. -/
theorem actual_steth_permit_batch (permit callee : External) (quote : StaticExternal)
    (ctx : Context) (stETH owner : Address) (p : PermitInput) (amounts : List Word)
    (ids : List Nat) (before : World)
    (h : (runPermit permit ctx stETH p (runBatch (stETHStep callee quote ctx stETH) ctx owner amounts) before).outcome = .ok ids) :
    JoinedEffect permit ctx stETH p (StETHEffect callee quote ctx stETH owner amounts) ids before
      (runPermit permit ctx stETH p (runBatch (stETHStep callee quote ctx stETH) ctx owner amounts) before).world
      (runPermit permit ctx stETH p (runBatch (stETHStep callee quote ctx stETH) ctx owner amounts) before).attempts :=
  joined_success _ _ _ _ _ _ (fun w ids hs => actual_steth_request_batch callee quote ctx stETH owner amounts ids w hs) before ids h

/-- Includes actual WSTETH transferFrom and unwrap for every batch item; permit's
returned allowance/storage is consumed by that same execution. No frame premise. -/
theorem actual_wrapped_permit_batch (permit : External) (conversion : StaticExternal)
    (tokenTransfer otherCalls : External) (quote : StaticExternal) (ctx : Context)
    (wstETH stETH owner : Address) (p : PermitInput) (amounts : List Word) (ids : List Nat) (before : World)
    (h : (runPermit permit ctx wstETH p (runBatch (wrappedStep conversion tokenTransfer otherCalls quote ctx wstETH stETH)
      ctx owner amounts) before).outcome = .ok ids) :
    JoinedEffect permit ctx wstETH p (WrappedEffect conversion tokenTransfer otherCalls quote ctx wstETH stETH owner amounts) ids before
      (runPermit permit ctx wstETH p (runBatch (wrappedStep conversion tokenTransfer otherCalls quote ctx wstETH stETH) ctx owner amounts) before).world
      (runPermit permit ctx wstETH p (runBatch (wrappedStep conversion tokenTransfer otherCalls quote ctx wstETH stETH) ctx owner amounts) before).attempts :=
  joined_success _ _ _ _ _ _ (fun w ids hs => actual_wrapped_request_batch conversion tokenTransfer otherCalls quote ctx wstETH stETH owner amounts ids w hs) before ids h

theorem actual_steth_permit_failure_restores (permit callee : External) (quote : StaticExternal)
    (ctx : Context) (stETH owner : Address) (p : PermitInput) (amounts : List Word) (before : World) (fault : Fault)
    (h : (runPermit permit ctx stETH p (runBatch (stETHStep callee quote ctx stETH) ctx owner amounts) before).outcome = .error fault) :
    (runPermit permit ctx stETH p (runBatch (stETHStep callee quote ctx stETH) ctx owner amounts) before).world = before :=
  failure_restores _ _ _ _ _ _ _ h

theorem actual_wrapped_permit_failure_restores (permit : External) (conversion : StaticExternal)
    (tokenTransfer otherCalls : External) (quote : StaticExternal) (ctx : Context)
    (wstETH stETH owner : Address) (p : PermitInput) (amounts : List Word) (before : World) (fault : Fault)
    (h : (runPermit permit ctx wstETH p (runBatch (wrappedStep conversion tokenTransfer otherCalls quote ctx wstETH stETH)
      ctx owner amounts) before).outcome = .error fault) :
    (runPermit permit ctx wstETH p (runBatch (wrappedStep conversion tokenTransfer otherCalls quote ctx wstETH stETH) ctx owner amounts) before).world = before :=
  failure_restores _ _ _ _ _ _ _ h
end LidoSRv3.Audit.Guarantees.PAddress1
