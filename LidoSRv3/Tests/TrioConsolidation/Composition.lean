import audit.trio.consolidation.Composition

/-! Executable vectors for the gateway→vault ABI hop
(`ConsolidationGateway.sol:220`): the `addConsolidationRequests(bytes[],
bytes[])` argument block round-trips through `decodeVaultArgs`, truncated or
mis-headed blocks are refused, and the hop arrays built from the committed
gateway pairs are the producer blobs whose zip is the vault's `pairsOf`. -/

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

/-! ### Framing of the argument block -/

/-- Head offsets: the first tail at `64`, the second after `32 + 2 * 80`. -/
example : decode (args.take 32) = 64 := by native_decide
example : decode ((args.drop 32).take 32) = 64 + 32 + 2 * 80 := by native_decide
example : args.length = 64 + 2 * (32 + 2 * 80) := by native_decide

/-- Each tail starts with its count word. -/
example : decode ((args.drop 64).take 32) = 2 := by native_decide
example : decode ((args.drop (64 + 32 + 2 * 80)).take 32) = 2 := by native_decide

/-- First framed element: 32-octet length word `48`, then the 48 octets. -/
example : decode ((args.drop 96).take 32) = 48 := by native_decide
example : (args.drop 128).take 48 = blob 11 := by native_decide

/-! ### Round trip -/

example : decodeVaultArgs args = some (sources, targets) := by native_decide

/-- The round-trip theorem, instantiated on the same vectors. -/
example : decodeVaultArgs args = some (sources, targets) :=
  decodeVaultArgs_gatewayVaultArgs sources targets (by native_decide) (by native_decide)
    (by native_decide) (by native_decide) (by native_decide)

/-- A truncated block is refused. -/
example : decodeVaultArgs (args.take 100) = none := by native_decide
example : decodeVaultArgs (args.take 63) = none := by native_decide

/-- A wrong first head offset is refused. -/
example : decodeVaultArgs (encode 32 32 ++ args.drop 32) = none := by native_decide

/-- A wrong second head offset is refused. -/
example : decodeVaultArgs (args.take 32 ++ encode 32 64 ++ args.drop 64) = none := by
  native_decide

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

end LidoSRv3.Tests.TrioConsolidation.Composition
