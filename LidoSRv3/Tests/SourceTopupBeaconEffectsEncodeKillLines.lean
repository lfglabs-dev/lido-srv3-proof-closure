import LidoSRv3.Audit.Source.TopupBeaconEffects

/-!
Kill-lines pinning `Source.TopupBeaconEffects` byte-encoding
round-trip identities used by the P-TOPUP-1 beacon-callee payload.
-/

namespace LidoSRv3.Tests.SourceTopupBeaconEffectsEncodeKillLines

open LidoSRv3.Audit.Source.TopupBeaconEffects
open LidoSRv3.Audit.Source.TrioReserve1 Live

/-! ## `encode_decode_bytes` — round-trip identity for byte lists. -/

theorem encode_decode_bytes_restated (bytes : Bytes) :
    encode bytes.length (decode bytes) = bytes :=
  encode_decode_bytes bytes

/-! ## `encode_mod` — reducing input mod 256^size is idempotent. -/

theorem encode_mod_restated (size n : Nat) :
    encode size (n % 256^size) = encode size n :=
  encode_mod size n

/-! ## `decode_serialized_word` — decoding a 32-byte encoded Word
    recovers its value. -/

theorem decode_serialized_word_restated (w : Word) :
    decode (encode 32 w.val) = w.val :=
  decode_serialized_word w

/-! ## `serialize` on empty payload is empty bytes. -/

theorem serialize_empty : serialize [] = [] := rfl

end LidoSRv3.Tests.SourceTopupBeaconEffectsEncodeKillLines
