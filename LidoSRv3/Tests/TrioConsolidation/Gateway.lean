import audit.trio.consolidation.Gateway

namespace LidoSRv3.Tests.TrioConsolidation.Gateway

open audit.trio.consolidation

private def key (id : Nat) : Pubkey := ⟨id, 48⟩

/-- Distinct identity that the wrapping encoder would confuse with `key 1`. -/
private def wrapKey (id : Nat) : Pubkey := ⟨id + pubkeyModulus, 48⟩

private def groups : List WitnessGroup :=
  [⟨[key 11, key 12], key 21⟩, ⟨[key 13], key 22⟩]

private def payload (source target : Pubkey) : List Nat :=
  (encodePackedRequest source target).getD []

private def groupPayloads : List (List Nat) :=
  (packedPayloads (preparePairs groups)).getD []

/-- `abi.encodePacked` of two raw 48-byte keys is 96 octets. -/
example : (payload (key 11) (key 21)).length = 96 := by
  native_decide

example : packedPayloads (preparePairs groups) =
    some [ payload (key 11) (key 21)
         , payload (key 12) (key 21)
         , payload (key 13) (key 22) ] := by
  native_decide

example : ((packedPayloads (preparePairs groups)).getD []).all
    (fun p => p.length = 96) = true := by
  native_decide

/-- Source octets occupy the first 48 bytes of the packed payload. -/
example : (payload (key 11) (key 21)).take 48 =
    (pubkeyOctets (key 11)).getD [] := by
  native_decide

/-- Target octets occupy the last 48 bytes of the packed payload. -/
example : (payload (key 11) (key 21)).drop 48 =
    (pubkeyOctets (key 21)).getD [] := by
  native_decide

/-- Unrestricted `integerBE` wraps: identities `1` and `1+2^384` collide. -/
example : integerBE pubkeyLength 1 =
    integerBE pubkeyLength (1 + pubkeyModulus) := by
  native_decide

/-- The actual 48-byte representation refuses the wrapping identity. -/
example : pubkeyOctets (key 1) ≠ pubkeyOctets (wrapKey 1) := by
  native_decide

example : pubkeyOctets (wrapKey 1) = none := by
  native_decide

example : pubkeyOctets (key 1) =
    some (integerBE pubkeyLength 1) := by
  native_decide

/-- Distinct raw identities do not encode to the same 48 bytes. -/
example : pubkeyOctets (key 1) ≠ pubkeyOctets (key 2) := by
  native_decide

/-- A wrapping source is not a 48-byte callee payload. -/
example : encodePackedRequest (wrapKey 1) (key 21) = none := by
  native_decide

/-- Gateway refuses wrapping identities rather than emitting a colliding
48-byte callee payload. -/
example : gatewayAddConsolidationRequests (word 6)
    [⟨[wrapKey 1], key 21⟩] (word 2) 9 8 true true =
    .reverted .invalidPubkey := by
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
        payloads := groupPayloads }
      none := by
  native_decide

/-- Overpay: vault hop still `{value: totalFee}`; remainder refunds to recipient. -/
example : gatewayAddConsolidationRequests (word 10) groups (word 2) 9 8 true true =
    .committed
      { pairs := preparePairs groups
        value := word 6
        payloads := groupPayloads }
      (some { recipient := 9, value := word 4 }) := by
  native_decide

/-- `refundRecipient == address(0)` remaps to `msg.sender`. -/
example : gatewayAddConsolidationRequests (word 10) groups (word 2) 0 8 true true =
    .committed
      { pairs := preparePairs groups
        value := word 6
        payloads := groupPayloads }
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
        payloads := groupPayloads }
      none := by
  native_decide

end LidoSRv3.Tests.TrioConsolidation.Gateway
