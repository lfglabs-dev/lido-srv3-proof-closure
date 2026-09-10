import audit.trio.consolidation.Composition
import audit.trio.consolidation.Predeploy

/-! Executable vectors for the gateway→vault ABI hop
(`ConsolidationGateway.sol:220`): the Solidity ABI argument block of
`addConsolidationRequests(bytes[], bytes[])` (head offsets, count words,
per-element offset tables, length words, 32-octet padding; 640 octets for two
pairs) is spelled out word by word, round-trips through `decodeVaultArgs`,
truncated or mis-framed blocks are refused the way Solidity's calldata
decoder refuses them, non-canonical offset layouts Solidity accepts are
accepted, the hop arrays built from the committed gateway pairs are the
producer blobs whose zip is the vault's `pairsOf`, and the vault entrypoint
on the raw calldata (`executeVaultCalldata`) commits the same hops as
`executeVault` on the decoded arrays. -/

namespace LidoSRv3.Tests.TrioConsolidation.Composition

open audit.trio.consolidation
open LidoSRv3.Audit.Source.TrioReserve1
open LidoSRv3.Audit.Source.TrioReserve1.Live
open LidoSRv3.Audit.Source.TrioReserve1.ABI

private def blob (id : Nat) : Bytes := encode pubkeyLength id
private def key (id : Nat) : Pubkey := ⟨id, 48⟩

private def sources : List Bytes := [blob 11, blob 12]
private def targets : List Bytes := [blob 21, blob 22]
private def args : Bytes := gatewayVaultArgs sources targets

/-- Zero padding of a 48-octet element to 64 octets. -/
private def pad16 : Bytes := List.replicate 16 0

/-- One `bytes[]` tail of two 48-octet keys, by the ABI specification: count
`2`; offsets `0x40` and `0xa0` relative to the octet after the count word;
element = length `48`, the 48 octets, 16 zero octets. -/
private def specTail (a b : Bytes) : Bytes :=
  encode 32 2 ++ encode 32 0x40 ++ encode 32 0xa0 ++
    encode 32 48 ++ a ++ pad16 ++ encode 32 48 ++ b ++ pad16

/-! ### The argument block, word by word (ABI specification) -/

/-- The encoder output is the specification layout: heads `0x40` and
`0x160`, then the two 288-octet tails. -/
example : args = encode 32 0x40 ++ encode 32 0x160 ++
    specTail (blob 11) (blob 12) ++ specTail (blob 21) (blob 22) := by native_decide

example : args.length = 640 := by native_decide
example : (specTail (blob 11) (blob 12)).length = 288 := by native_decide
example : (abiBytesElement (blob 11)).length = 96 := by native_decide

/-- Head offsets. -/
example : decode (args.take 32) = 64 := by native_decide
example : decode ((args.drop 32).take 32) = 352 := by native_decide

/-- First tail: count, per-element offsets, first element framing. -/
example : decode ((args.drop 64).take 32) = 2 := by native_decide
example : decode ((args.drop 96).take 32) = 64 := by native_decide
example : decode ((args.drop 128).take 32) = 160 := by native_decide
example : decode ((args.drop 160).take 32) = 48 := by native_decide
example : (args.drop 192).take 48 = blob 11 := by native_decide
example : (args.drop 240).take 16 = pad16 := by native_decide
example : decode ((args.drop 256).take 32) = 48 := by native_decide
example : (args.drop 288).take 48 = blob 12 := by native_decide

/-- Second tail starts at the second head offset with its count word. -/
example : decode ((args.drop 352).take 32) = 2 := by native_decide
example : (args.drop 480).take 48 = blob 21 := by native_decide
example : (args.drop 576).take 48 = blob 22 := by native_decide

/-- The generic length theorem on the same vectors. -/
example : (gatewayVaultArgs (hopSources [(key 11, key 21), (key 12, key 22)])
    (hopTargets [(key 11, key 21), (key 12, key 22)])).length = 64 + 2 * (32 + 128 * 2) := by
  native_decide

/-! ### Round trip -/

example : decodeVaultArgs args = some (sources, targets) := by native_decide

/-- The round-trip theorem, instantiated on the same vectors. -/
example : decodeVaultArgs args = some (sources, targets) :=
  decodeVaultArgs_gatewayVaultArgs sources targets (by native_decide) (by native_decide)
    (by native_decide) (by native_decide)

/-- A single pair and an empty array frame and decode too. -/
example : decodeVaultArgs (gatewayVaultArgs [blob 11] [blob 21]) = some ([blob 11], [blob 21]) := by
  native_decide
example : (gatewayVaultArgs [blob 11] [blob 21]).length = 64 + 2 * 160 := by native_decide
example : decodeVaultArgs (gatewayVaultArgs [] []) = some ([], []) := by native_decide

/-- A 33-octet element pads to 64 octets; a 32-octet element gets no padding. -/
example : (abiBytesElement (List.replicate 33 1)).length = 96 := by native_decide
example : (abiBytesElement (List.replicate 32 1)).length = 64 := by native_decide
example : decodeVaultArgs (gatewayVaultArgs [List.replicate 33 1] [List.replicate 32 2]) =
    some ([List.replicate 33 1], [List.replicate 32 2]) := by native_decide

/-! ### Refusals (what Solidity's calldata decoder refuses) -/

/-- Truncated heads. -/
example : decodeVaultArgs (args.take 63) = none := by native_decide

/-- Truncated inside the last element's payload. -/
example : decodeVaultArgs (args.take 620) = none := by native_decide

/-- Truncated inside the first tail (second head offset points past the end). -/
example : decodeVaultArgs (args.take 300) = none := by native_decide

/-- A head offset past the calldata. -/
example : decodeVaultArgs (encode 32 1000 ++ args.drop 32) = none := by native_decide

/-- An element offset past the array body. -/
example : decodeVaultArgs (args.take 128 ++ encode 32 1000 ++ args.drop 160) = none := by
  native_decide

/-- A count whose offset table does not fit the remaining calldata. -/
example : decodeVaultArgs (args.take 64 ++ encode 32 100 ++ args.drop 96) = none := by
  native_decide

/-- An element length past the calldata. -/
example : decodeVaultArgs (args.take 544 ++ encode 32 100 ++ args.drop 576) = none := by
  native_decide

/-! ### Leniency (what Solidity's calldata decoder accepts) -/

/-- Padding octets are not inspected: the last 16 padding octets may be
absent (`addr + length + 32 ≤ calldatasize` still holds). -/
example : decodeVaultArgs (args.take 624) = some (sources, targets) := by native_decide

/-- Swapped head offsets are followed, not rejected: the arrays come back
swapped. -/
example : decodeVaultArgs (encode 32 352 ++ encode 32 64 ++ args.drop 64) =
    some (targets, sources) := by native_decide

/-- Element offsets are followed: a tail listing its elements in reverse
order decodes to the reversed array. -/
example : decodeVaultArgs (encode 32 64 ++ encode 32 352 ++
    (encode 32 2 ++ encode 32 0xa0 ++ encode 32 0x40 ++
      encode 32 48 ++ blob 12 ++ pad16 ++ encode 32 48 ++ blob 11 ++ pad16) ++
    specTail (blob 21) (blob 22)) = some ([blob 11, blob 12], targets) := by native_decide

/-- Unequal arrays still decode; the vault's `ArraysLengthMismatch` guard
(`WithdrawalVaultEIP7685.sol:62-63`) is downstream of the ABI hop. -/
example : decodeVaultArgs (gatewayVaultArgs sources [blob 21]) = some (sources, [blob 21]) := by
  native_decide

/-! ### Hop arrays from the committed gateway pairs -/

private def pairs : List (Pubkey × Pubkey) := [(key 11, key 21), (key 12, key 22)]

/-- The hop arrays are the producer blobs. -/
example : hopSources pairs = sources := by native_decide
example : hopTargets pairs = targets := by native_decide

/-- Zipping them is the vault's pair list. -/
example : pairsOf (hopSources pairs) (hopTargets pairs) =
    [⟨blob 11, blob 21⟩, ⟨blob 12, blob 22⟩] := by native_decide

/-- The vault's re-packed line-114 payloads are the gateway's packed payloads. -/
example : (pairsOf (hopSources pairs) (hopTargets pairs)).map vaultCallPayload =
    ((packedPayloads pairs).getD []).map (List.map UInt8.ofNat) := by native_decide

/-- The committed hop carried over the ABI decodes to the same arrays. -/
example : decodeVaultArgs (gatewayVaultArgs (hopSources pairs) (hopTargets pairs)) =
    some (hopSources pairs, hopTargets pairs) := by native_decide

/-! ### The vault entrypoint on the raw calldata -/

private def addr (n : Nat) : Live.Address := Verity.Core.Address.ofNat n
private def vault : Live.Address := addr 0xA1
private def gateway : Live.Address := addr 0xB2
private def inbox : Live.Address := addr 0x0000BBdDc7CE488642fb579F8B00f3a590007251
private def ctx : Context := ⟨vault, gateway⟩

/-- The predeploy has code and its fee slot holds `7`. -/
private def core : Verity.ContractState :=
  ({ Verity.defaultState with
      codeSize := fun a => if a = inbox.val then Live.word 1 else Live.word 0 } :
    Verity.ContractState).writeContractSlot inbox.val predeployFeeSlot (Live.word 7)

private def before (msgValue : Nat) : World :=
  ⟨core, fun a => if a = vault then msgValue else 0, []⟩

/-- Selector parameter (keccak is outside the model): four arbitrary octets. -/
private def selector : Bytes := [0xde, 0xad, 0xbe, 0xef]

private def calldata : Bytes := gatewayVaultCalldata selector (hopSources pairs) (hopTargets pairs)

private def viaCalldata : Result Unit :=
  executeVaultCalldata predeployBody predeployStaticBody ctx gateway inbox (Live.word 14)
    selector calldata (before 14)

private def viaArrays : Result Unit :=
  executeVault predeployBody predeployStaticBody ctx gateway inbox (Live.word 14)
    (hopSources pairs) (hopTargets pairs) (before 14)

private def isOk (r : Result Unit) : Bool :=
  match r.outcome with
  | .ok _ => true
  | .error _ => false

private def faultOf (r : Result Unit) : Option Fault :=
  match r.outcome with
  | .ok _ => none
  | .error f => some f

example : calldata.length = 4 + 640 := by native_decide

/-- The calldata entry commits and is the same result as the array entry. -/
example : isOk viaCalldata = true := by native_decide
example : viaCalldata.attempts = viaArrays.attempts := by native_decide
example : viaCalldata.world.logs.map (·.values) = viaArrays.world.logs.map (·.values) := by
  native_decide
example : viaCalldata.world.logs.length = 2 := by native_decide
example : viaCalldata.world.balances vault = 0 := by native_decide
example : viaCalldata.world.balances inbox = 14 := by native_decide

/-- The attempted line-115 requests carry the gateway's packed payloads. -/
example : viaCalldata.attempts.map (·.request.payload) =
    ((packedPayloads pairs).getD []).map (List.map UInt8.ofNat) := by native_decide

/-- Wrong selector: dispatcher revert, no attempt, world untouched. -/
example : faultOf (executeVaultCalldata predeployBody predeployStaticBody ctx gateway inbox
    (Live.word 14) selector ([0xde, 0xad, 0xbe, 0xee] ++ calldata.drop 4) (before 14)) =
    some (.reason "UnknownSelector") := by native_decide

/-- Malformed calldata: ABI decoder revert before any hop, no attempt. -/
example : faultOf (executeVaultCalldata predeployBody predeployStaticBody ctx gateway inbox
    (Live.word 14) selector (calldata.take 300) (before 14)) =
    some (.reason "AbiDecodingFailed") := by native_decide
example : (executeVaultCalldata predeployBody predeployStaticBody ctx gateway inbox
    (Live.word 14) selector (calldata.take 300) (before 14)).attempts = [] := by native_decide

/-- The composition theorem, instantiated. -/
example : viaCalldata = viaArrays :=
  executeVaultCalldata_gateway predeployBody predeployStaticBody ctx gateway inbox (Live.word 14)
    selector pairs (before 14) (by native_decide) (by native_decide)

end LidoSRv3.Tests.TrioConsolidation.Composition
