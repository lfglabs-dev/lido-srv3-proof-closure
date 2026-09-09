import audit.trio.consolidation.Spec

/-!
# ConsolidationGateway fee/call and 96-byte request payload

Independent executable semantics for the payable fee split of
`ConsolidationGateway.addConsolidationRequests` and the vault's packed
request payload at `lidofinance/core@17005714f151e5502c559932319a3f2f74ac2436`:

* Gateway lines 189--199 (`msg.value == 0`, nonempty `groups`, `EmptyGroup`,
  checked `requestsCount` accumulation);
* Gateway lines 211--213 (`fee`, checked `totalFee = requestsCount * fee`,
  `_checkFee`);
* Gateway line 220 (vault hop `{value: totalFee}` after
  `_prepareConsolidationPairs`);
* Gateway lines 222 / 286--307 (`refund = msg.value - totalFee`, `_refundFee`);
* `WithdrawalVaultEIP7685._callAddConsolidationRequest` line 114:
  `abi.encodePacked(sourcePubkey, targetPubkey)` — 48 source octets then
  48 target octets (`PUBLIC_KEY_LENGTH = 48`).

Role, pause, DSM/`canDeposit`, SSZ target-witness, quota, locator vault
lookup, and `preservesEthBalance` remain outside this component. The fee
`STATICCALL` is a supplied word, matching the vault-side treatment of
`_getFeeFromContract` in `SourceExecution.lean`.
-/

namespace audit.trio.consolidation

/-! ## 96-byte packed consolidation payload -/

/-- Big-endian `PUBLIC_KEY_LENGTH` octets of a pubkey's identity. This is the
byte blob `abi.encodePacked` sees for a 48-byte BLS key whose integer value
is `key.identity`. -/
def pubkeyOctets (key : Pubkey) : List Nat :=
  (List.range pubkeyLength).map fun i =>
    (key.identity / 256 ^ (pubkeyLength - 1 - i)) % 256

theorem pubkeyOctets_length (key : Pubkey) :
    (pubkeyOctets key).length = pubkeyLength := by
  simp [pubkeyOctets, pubkeyLength]

/-- Vault `_callAddConsolidationRequest` payload:
`abi.encodePacked(sourcePubkey, targetPubkey)` (`WithdrawalVaultEIP7685.sol:114`). -/
def encodePackedRequest (source target : Pubkey) : List Nat :=
  pubkeyOctets source ++ pubkeyOctets target

theorem encodePackedRequest_length (source target : Pubkey) :
    (encodePackedRequest source target).length = 96 := by
  simp [encodePackedRequest, pubkeyOctets_length, pubkeyLength]

theorem encodePackedRequest_source_prefix (source target : Pubkey) :
    (encodePackedRequest source target).take pubkeyLength = pubkeyOctets source := by
  simp [encodePackedRequest, pubkeyOctets_length]

theorem encodePackedRequest_target_suffix (source target : Pubkey) :
    (encodePackedRequest source target).drop pubkeyLength = pubkeyOctets target := by
  simp [encodePackedRequest, pubkeyOctets_length]

/-- One packed payload per flattened gateway pair, in `_prepareConsolidationPairs`
order. -/
def packedPayloads (pairs : List (Pubkey × Pubkey)) : List (List Nat) :=
  pairs.map fun pair => encodePackedRequest pair.1 pair.2

theorem packedPayloads_length (pairs : List (Pubkey × Pubkey)) :
    (packedPayloads pairs).length = pairs.length := by
  simp [packedPayloads]

theorem packedPayloads_each_96 (pairs : List (Pubkey × Pubkey))
    (payload : List Nat) (hmem : payload ∈ packedPayloads pairs) :
    payload.length = 96 := by
  obtain ⟨pair, _, rfl⟩ := List.mem_map.mp hmem
  exact encodePackedRequest_length pair.1 pair.2

/-! ## Gateway payable fee/call computation -/

inductive GatewayError where
  | zeroMsgValue
  | emptyGroups
  | emptyGroup (groupIndex : Nat)
  | countOverflow
  | feeOverflow
  | insufficientFee (required provided : Word)
  | vaultReverted
  | refundFailed
  deriving DecidableEq, Repr

/-- Vault hop at `ConsolidationGateway.sol:220`. -/
structure VaultHop where
  pairs : List (Pubkey × Pubkey)
  value : Word
  payloads : List (List Nat)
  deriving DecidableEq, Repr

/-- Refund hop at `ConsolidationGateway.sol:302`, omitted when remainder is 0. -/
structure RefundHop where
  recipient : Nat
  value : Word
  deriving DecidableEq, Repr

inductive GatewayOutcome where
  | reverted (error : GatewayError)
  | committed (vault : VaultHop) (refund : Option RefundHop)
  deriving DecidableEq, Repr

private def checkedAdd (a b : Nat) : Option Nat :=
  if a + b < 2 ^ 256 then some (a + b) else none

/-- First loop of `addConsolidationRequests` (lines 194--199): reject an empty
source group and accumulate `requestsCount` with Solidity 0.8 checked add. -/
def countGatewayRequests : List WitnessGroup → Except GatewayError Nat :=
  go 0 0
where
  go (groupIndex total : Nat) : List WitnessGroup → Except GatewayError Nat
    | [] => .ok total
    | group :: rest =>
        if group.sources.isEmpty then .error (.emptyGroup groupIndex)
        else match checkedAdd total group.sources.length with
          | none => .error .countOverflow
          | some next => go (groupIndex + 1) next rest

/-- `ConsolidationGateway.sol:286-292` `_checkFee`. -/
def checkFee (msgValue required : Word) : Except GatewayError Word :=
  if msgValue.val < required.val then
    .error (.insufficientFee required msgValue)
  else
    .ok (word (msgValue.val - required.val))

/-- `ConsolidationGateway.sol:298-300`: `address(0)` remaps to `msg.sender`. -/
def resolveRecipient (recipient sender : Nat) : Nat :=
  if recipient = 0 then sender else recipient

/-- Remainder attached to a committed refund hop, or 0 when the hop is omitted. -/
def refundAmount : Option RefundHop → Nat
  | none => 0
  | some hop => hop.value.val

/-- Payable fee/call computation of `addConsolidationRequests` after the
out-of-scope role/pause/quota/witness prefix. `fee` is the value returned by
`withdrawalVault.getConsolidationRequestFee()` (line 211). `vaultAccepts` /
`refundAccepts` are the success bits of the two value-bearing CALLs. -/
def gatewayAddConsolidationRequests (msgValue : Word) (groups : List WitnessGroup)
    (fee : Word) (refundRecipient sender : Nat)
    (vaultAccepts refundAccepts : Bool) : GatewayOutcome :=
  -- ConsolidationGateway.sol:189  if (msg.value == 0) revert ZeroArgument("msg.value");
  if msgValue.val = 0 then .reverted .zeroMsgValue
  else
    -- ConsolidationGateway.sol:190-191  if (groupsCount == 0) revert ZeroArgument("groups");
    if groups.isEmpty then .reverted .emptyGroups
    else match countGatewayRequests groups with
      | .error error => .reverted error
      | .ok requestsCount =>
          -- ConsolidationGateway.sol:211-212  uint256 totalFee = requestsCount * fee;
          match checkedMulWord requestsCount fee with
          | none => .reverted .feeOverflow
          | some totalFee =>
              -- ConsolidationGateway.sol:213 / 286-292
              match checkFee msgValue totalFee with
              | .error error => .reverted error
              | .ok refundVal =>
                  let pairs := preparePairs groups
                  let vault : VaultHop :=
                    { pairs := pairs
                      value := totalFee
                      payloads := packedPayloads pairs }
                  -- ConsolidationGateway.sol:220  {value: totalFee}
                  if !vaultAccepts then .reverted .vaultReverted
                  else if refundVal.val = 0 then
                    -- ConsolidationGateway.sol:296  if (refund > 0) { ... }
                    .committed vault none
                  else if !refundAccepts then .reverted .refundFailed
                  else
                    -- ConsolidationGateway.sol:302  recipient.call{value: refund}("");
                    .committed vault
                      (some
                        { recipient := resolveRecipient refundRecipient sender
                          value := refundVal })

theorem add_zero_msgValue (groups : List WitnessGroup) (fee : Word)
    (refundRecipient sender : Nat) (vaultAccepts refundAccepts : Bool) :
    gatewayAddConsolidationRequests (word 0) groups fee refundRecipient sender
      vaultAccepts refundAccepts = .reverted .zeroMsgValue := by
  simp [gatewayAddConsolidationRequests, word]

theorem add_empty_groups (msgValue fee : Word) (refundRecipient sender : Nat)
    (vaultAccepts refundAccepts : Bool) (hvalue : msgValue.val ≠ 0) :
    gatewayAddConsolidationRequests msgValue [] fee refundRecipient sender
      vaultAccepts refundAccepts = .reverted .emptyGroups := by
  simp [gatewayAddConsolidationRequests, hvalue]

theorem add_empty_group (msgValue fee : Word) (target : Pubkey)
    (refundRecipient sender : Nat) (vaultAccepts refundAccepts : Bool)
    (hvalue : msgValue.val ≠ 0) :
    gatewayAddConsolidationRequests msgValue [⟨[], target⟩] fee refundRecipient sender
      vaultAccepts refundAccepts = .reverted (.emptyGroup 0) := by
  simp [gatewayAddConsolidationRequests, countGatewayRequests, countGatewayRequests.go,
    hvalue]

theorem checkFee_under (msgValue required : Word)
    (h : msgValue.val < required.val) :
    checkFee msgValue required = .error (.insufficientFee required msgValue) := by
  simp [checkFee, h]

theorem checkFee_refund (msgValue required : Word)
    (h : required.val ≤ msgValue.val) :
    checkFee msgValue required = .ok (word (msgValue.val - required.val)) := by
  have hlt : ¬ msgValue.val < required.val := Nat.not_lt.mpr h
  simp [checkFee, hlt]

/-- `_checkFee` remainder plus the vault `totalFee` reconstructs `msg.value`. -/
theorem checkFee_additive (msgValue required : Word)
    (hle : required.val ≤ msgValue.val) :
    required.val + (word (msgValue.val - required.val)).val = msgValue.val := by
  have hlt : msgValue.val - required.val < Verity.Core.Uint256.modulus := by
    change msgValue.val - required.val < Verity.Core.UINT256_MODULUS
    exact Nat.lt_of_le_of_lt (Nat.sub_le _ _) msgValue.isLt
  change required.val + ((msgValue.val - required.val) % Verity.Core.Uint256.modulus) =
    msgValue.val
  rw [Nat.mod_eq_of_lt hlt, Nat.add_sub_of_le hle]

theorem resolveRecipient_zero (sender : Nat) :
    resolveRecipient 0 sender = sender := rfl

theorem resolveRecipient_set (recipient sender : Nat) (h : recipient ≠ 0) :
    resolveRecipient recipient sender = recipient := by
  simp [resolveRecipient, h]

theorem countGatewayRequests_nil : countGatewayRequests [] = .ok 0 := rfl

end audit.trio.consolidation
