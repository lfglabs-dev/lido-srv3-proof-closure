import audit.trio.consolidation.Gateway

namespace LidoSRv3.Tests.TrioConsolidation.Gateway

open audit.trio.consolidation

private def key (id : Nat) : Pubkey := ⟨id, 48⟩

private def groups : List WitnessGroup :=
  [⟨[key 11, key 12], key 21⟩, ⟨[key 13], key 22⟩]

/-- `abi.encodePacked` of two 48-byte keys is always 96 octets. -/
example : (encodePackedRequest (key 11) (key 21)).length = 96 := by
  native_decide

example : packedPayloads (preparePairs groups) =
    [ encodePackedRequest (key 11) (key 21)
    , encodePackedRequest (key 12) (key 21)
    , encodePackedRequest (key 13) (key 22) ] := by
  native_decide

example : (packedPayloads (preparePairs groups)).all (fun p => p.length = 96) = true := by
  native_decide

/-- Source octets occupy the first 48 bytes of the packed payload. -/
example : (encodePackedRequest (key 11) (key 21)).take 48 = pubkeyOctets (key 11) := by
  native_decide

/-- Target octets occupy the last 48 bytes of the packed payload. -/
example : (encodePackedRequest (key 11) (key 21)).drop 48 = pubkeyOctets (key 21) := by
  native_decide

example : gatewayAddConsolidationRequests (word 0) groups (word 2) 9 8 true true =
    .reverted .zeroMsgValue := by
  native_decide

example : gatewayAddConsolidationRequests (word 6) [] (word 2) 9 8 true true =
    .reverted .emptyGroups := by
  native_decide

example : gatewayAddConsolidationRequests (word 6) [⟨[], key 21⟩] (word 2) 9 8 true true =
    .reverted (.emptyGroup 0) := by
  native_decide

/-- `msg.value < requestsCount * fee` reverts with the required totalFee. -/
example : gatewayAddConsolidationRequests (word 5) groups (word 2) 9 8 true true =
    .reverted (.insufficientFee (word 6) (word 5)) := by
  native_decide

/-- Exact fee: vault hop carries `totalFee`, no refund hop. -/
example : gatewayAddConsolidationRequests (word 6) groups (word 2) 9 8 true true =
    .committed
      { pairs := preparePairs groups
        value := word 6
        payloads := packedPayloads (preparePairs groups) }
      none := by
  native_decide

/-- Overpay: vault hop still `{value: totalFee}`; remainder refunds to recipient. -/
example : gatewayAddConsolidationRequests (word 10) groups (word 2) 9 8 true true =
    .committed
      { pairs := preparePairs groups
        value := word 6
        payloads := packedPayloads (preparePairs groups) }
      (some { recipient := 9, value := word 4 }) := by
  native_decide

/-- `refundRecipient == address(0)` remaps to `msg.sender`. -/
example : gatewayAddConsolidationRequests (word 10) groups (word 2) 0 8 true true =
    .committed
      { pairs := preparePairs groups
        value := word 6
        payloads := packedPayloads (preparePairs groups) }
      (some { recipient := 8, value := word 4 }) := by
  native_decide

/-- Vault CALL failure reverts the whole entrypoint. -/
example : gatewayAddConsolidationRequests (word 10) groups (word 2) 9 8 false true =
    .reverted .vaultReverted := by
  native_decide

/-- Refund CALL failure reverts after a positive remainder. -/
example : gatewayAddConsolidationRequests (word 10) groups (word 2) 9 8 true false =
    .reverted .refundFailed := by
  native_decide

/-- Exact fee never issues a refund CALL, so `refundAccepts = false` is ignored. -/
example : gatewayAddConsolidationRequests (word 6) groups (word 2) 9 8 true false =
    .committed
      { pairs := preparePairs groups
        value := word 6
        payloads := packedPayloads (preparePairs groups) }
      none := by
  native_decide

end LidoSRv3.Tests.TrioConsolidation.Gateway
