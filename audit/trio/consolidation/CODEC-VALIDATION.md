# Consolidation codec validation packet

Pin: `lidofinance/core@17005714f151e5502c559932319a3f2f74ac2436`.
PR: #281 (`p-consolidation-pubkey-octets`). Parent held: `d2983de830161b9317d43c12269f88591d392144`.
P-CONSOLIDATION remains OPEN. #263 inadmissible. #276 fee-only. No merge.
Codec only: no Live CALL, no vault hop, no SSZ/TOPUP/site/DEPOSIT.

## Adapter

`Bytes = List UInt8`. Nat is derived by `Live.decode`. Recovery is
`LidoSRv3.Audit.Source.TopupBeaconEffects.encode_decode_bytes` (`TopupBeaconEffects.lean:86`):

```
encode pubkeyLength (decode raw48) = raw48
```

| Claim | Theorem |
| --- | --- |
| Width-48 round trip | `encode_decode_raw48` / `encode_decode_Raw48` |
| Adapter is a `RawPubkey` | `raw48Pubkey_raw` |
| Distinct 48-octet blobs ⇒ distinct Nats | `raw48_nat_injective` |
| Leading-zero mutant (MSB padding observable) | `leading_zero_mutant` |
| Endian mutant (reverse with distinct ends) | `endian_mutant` |

Tests: `LidoSRv3/Tests/TrioConsolidation/Codec.lean`.
Axioms used: `propext`, `Quot.sound`, `Classical.choice` (`leading_zero_mutant` only).
