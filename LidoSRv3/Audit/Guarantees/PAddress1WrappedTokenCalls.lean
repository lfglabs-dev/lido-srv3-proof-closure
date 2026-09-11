import LidoSRv3.Audit.Source.AddressWrappedTokenCalls
namespace LidoSRv3.Audit.Guarantees.PAddress1
open LidoSRv3.Audit.Source.AddressWrappedTokenCalls
open LidoSRv3.Audit.Source.TrioReserve1.Live
open LidoSRv3.Audit.Verity.AddressRecipientCallBridge (StaticExternal)

/-- The actual WstETH unwrap body is the implementation of the existing queue
CALL, and its qualified burn/conversion/transfer effect is joined to the same
returned amount, world, quote and enqueue in the prior public request effect.
The first WSTETH transferFrom and STETH callees remain explicit externals; no
final burn balance is asserted across arbitrary STETH callbacks. -/
theorem actual_wrapped_token_request_enqueue (conversion : StaticExternal)
    (tokenTransfer otherCalls : External) (queueQuote : StaticExternal) (ctx : Context)
    (wstETH stETH : Address) (amount : Word) (owner : Address) (id : Nat) (before : World)
    (h : (runRequest conversion tokenTransfer otherCalls queueQuote ctx wstETH stETH amount owner before).outcome = .ok id) :
    JoinedEffect conversion tokenTransfer otherCalls queueQuote ctx wstETH stETH amount owner id before
      (runRequest conversion tokenTransfer otherCalls queueQuote ctx wstETH stETH amount owner before).world
      (runRequest conversion tokenTransfer otherCalls queueQuote ctx wstETH stETH amount owner before).attempts :=
  joined_success conversion tokenTransfer otherCalls queueQuote ctx wstETH stETH amount owner id before h

theorem actual_wrapped_token_request_failure_restores (conversion : StaticExternal)
    (tokenTransfer otherCalls : External) (queueQuote : StaticExternal) (ctx : Context)
    (wstETH stETH : Address) (amount : Word) (owner : Address) (before : World) (fault : Fault)
    (h : (runRequest conversion tokenTransfer otherCalls queueQuote ctx wstETH stETH amount owner before).outcome = .error fault) :
    (runRequest conversion tokenTransfer otherCalls queueQuote ctx wstETH stETH amount owner before).world = before :=
  joined_failure_restores conversion tokenTransfer otherCalls queueQuote ctx wstETH stETH amount owner before fault h
end LidoSRv3.Audit.Guarantees.PAddress1
