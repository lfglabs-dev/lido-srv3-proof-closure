import LidoSRv3.Audit.Source.TopupModuleCall

/-!
Kill-lines pinning `Source.TopupModuleCall` `encodeWords` length
identity + `decodeReturn` round-trip for encoded call-return words.
-/

namespace LidoSRv3.Tests.SourceTopupModuleCallEncodeKillLines

open LidoSRv3.Audit.Source.TopupModuleCall
open LidoSRv3.Audit.Source.TrioReserve1 Live

/-! ## `encodeWords_length` — restated. -/

theorem encodeWords_length_restated (xs : List Word) :
    (encodeWords xs).length = 32 * xs.length :=
  encodeWords_length xs

/-! ## `readWords_encoded` — reading back encoded words + tail. -/

theorem readWords_encoded_restated (xs : List Word) (tail : Bytes) :
    readWords xs.length (encodeWords xs ++ tail) = xs :=
  readWords_encoded xs tail

/-! ## `decodeReturn_encoded` — round-trip for uint64-bounded lists. -/

theorem decodeReturn_encoded_restated
    (xs : List Word) (tail : Bytes) (hn : xs.length < 2^64) :
    decodeReturn (encodeReturn xs ++ tail) = .ok xs :=
  decodeReturn_encoded xs tail hn

end LidoSRv3.Tests.SourceTopupModuleCallEncodeKillLines
