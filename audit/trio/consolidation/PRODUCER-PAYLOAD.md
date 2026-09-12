# Consolidation producer-to-payload validation packet

Pin: `lidofinance/core@17005714f151e5502c559932319a3f2f74ac2436`.
PR: #281 (`p-consolidation-pubkey-octets`).
Parent held: `d2983de830161b9317d43c12269f88591d392144`.
Codec head before this increment: `605b88290d5353eb9760686b5dce3a02a67a7b8b`.
P-CONSOLIDATION remains OPEN. #263 inadmissible. #276 fee-only. No merge.

Producer-to-payload only. Not Live CALL. Callee, world, rollback, log,
refund, and vault hop remain OPEN. Codec lemmas are reused, not reopened.

## Producer

Executor/gateway input is grouped `bytes[]`
(`ConsolidationBus.sol:383-390`, `ConsolidationGateway.sol:348-365`).
Each element is a physical blob (`Bytes = List UInt8`, equivalently
`ByteArray`). Nat identity is `Live.decode` of those octets.

ABI `bytes` framing is the 32-byte length word followed by the payload
(`encodeBytesElement` / `decodeBytesElement`).

## Width check ⇒ Raw48

`_validatePublicKey` (`WithdrawalVaultEIP7685.sol:97-101`) is
`pubkey.length == 48`. Success is the existing `Raw48` adapter.

## Vault payload

`WithdrawalVaultEIP7685.sol:113-120`:
`bytes memory request = abi.encodePacked(sourcePubkey, targetPubkey)`.
The proved concatenation `source ++ target` is the input to
`encodePackedRequest_of_bytes`.

| Claim | Theorem |
| --- | --- |
| ABI `bytes` round trip | `decode_encode_bytes_element` |
| Flatten then derive Nats | `preparePairs_of_producer` |
| Source width ⇒ Raw48 | `widthOk_source_is_raw48` |
| Target width ⇒ Raw48 | `widthOk_target_is_raw48` |
| Packed payload is 96 octets | `widthOk_payload_length` |
| Packed encoder of producer concat | `vaultCallPayload_is_packed` |
| ByteArray producer | `vaultCallPayload_is_packed_byteArray` |

Tests: `LidoSRv3/Tests/TrioConsolidation/Producer.lean`.
Reused, not reopened: `Raw48`, `encode_decode_raw48`,
`encodePackedRequest_of_bytes`.

## Targeted compile / axiom inspection

`lake build +audit.trio.consolidation.Producer`
`lake build +LidoSRv3.Tests.TrioConsolidation.Producer`
`lake build +audit.trio.consolidation.InspectAxioms`
True compiler exit (no `tee`). Lean 4.31.0.

| Theorem | Axioms |
| --- | --- |
| `decode_encode_bytes_element` | `propext`, `Classical.choice`, `Quot.sound` |
| `preparePairs_of_producer` | `propext` |
| `widthOk_source_is_raw48` | `propext`, `Quot.sound` |
| `widthOk_target_is_raw48` | `propext`, `Quot.sound` |
| `widthOk_payload_length` | `propext` |
| `vaultCallPayload_is_packed` | `propext`, `Quot.sound` |
| `vaultCallPayload_is_packed_byteArray` | `propext`, `Quot.sound` |

No Live CALL. P-CONSOLIDATION remains OPEN.
