import LidoSRv3.Audit.Source.TrioAlloc1.Bytes

/-!
Kill-lines pinning `TrioAlloc1.Bytes` ABI encode/decode round-trip
identities. These pin the source-plane bytes shape used by the
P-ALLOC-1 pinned verifier.
-/

namespace LidoSRv3.Tests.SourceTrioAlloc1BytesKillLines

open LidoSRv3.Audit.Source.TrioAlloc1

/-! ## `encodeBE_length` — restated. -/

theorem encodeBE_length_restated (width n : Nat) :
    (encodeBE width n).length = width :=
  encodeBE_length width n

/-! ## `decodeBE_encodeBE` — inverse identity mod 256^width. -/

theorem decodeBE_encodeBE_restated (width n : Nat) :
    (encodeBE width n).foldl (fun a b => a*256+b.val) 0 = n % 256^width :=
  decodeBE_encodeBE width n

/-! ## `encodeWord_length` — 32 bytes. -/

theorem encodeWord_length_restated (w : Word) :
    (encodeWord w).length = 32 :=
  encodeWord_length w

/-! ## `decodeWord_encodeWord` — inverse identity. -/

theorem decodeWord_encodeWord_restated (w : Word) :
    decodeWord (encodeWord w) 0 = w :=
  decodeWord_encodeWord w

end LidoSRv3.Tests.SourceTrioAlloc1BytesKillLines
