import LidoSRv3.Audit.Source.AddressWrappedTransferCalls
namespace LidoSRv3.Audit.Guarantees.PAddress1
open LidoSRv3.Audit.Source.AddressWrappedTransferCalls
open LidoSRv3.Audit.Source.TrioReserve1.Live
open LidoSRv3.Audit.Verity.AddressRecipientCallBridge (StaticExternal)

/-- The actual WstETH transferFrom and unwrap bodies execute as the same
queue's two CALLs. Retains the entire prior joined request effect and adds
source-ordered qualified balance/allowance writes and Transfer/Approval events
at the first CALL world. No final balance frame across later stETH callbacks. -/
theorem actual_wrapped_transfer_request_enqueue (conversion : StaticExternal)
    (tokenTransfer otherCalls : External) (queueQuote : StaticExternal) (ctx : Context)
    (wstETH stETH : Address) (amount : Word) (owner : Address) (id : Nat) (before : World)
    (h : (runRequest conversion tokenTransfer otherCalls queueQuote ctx wstETH stETH amount owner before).outcome = .ok id) :
    JoinedEffect conversion tokenTransfer otherCalls queueQuote ctx wstETH stETH amount owner id before
      (runRequest conversion tokenTransfer otherCalls queueQuote ctx wstETH stETH amount owner before).world
      (runRequest conversion tokenTransfer otherCalls queueQuote ctx wstETH stETH amount owner before).attempts :=
  joined_success conversion tokenTransfer otherCalls queueQuote ctx wstETH stETH amount owner id before h

theorem actual_wrapped_transfer_request_failure_restores (conversion : StaticExternal)
    (tokenTransfer otherCalls : External) (queueQuote : StaticExternal) (ctx : Context)
    (wstETH stETH : Address) (amount : Word) (owner : Address) (before : World) (fault : Fault)
    (h : (runRequest conversion tokenTransfer otherCalls queueQuote ctx wstETH stETH amount owner before).outcome = .error fault) :
    (runRequest conversion tokenTransfer otherCalls queueQuote ctx wstETH stETH amount owner before).world = before :=
  joined_failure_restores conversion tokenTransfer otherCalls queueQuote ctx wstETH stETH amount owner before fault h
end LidoSRv3.Audit.Guarantees.PAddress1
