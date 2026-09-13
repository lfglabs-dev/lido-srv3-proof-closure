import LidoSRv3.Audit.Source.TopupBeaconEffects

/-!
Kill-lines pinning `Source.TopupBeaconEffects.canonicalPayload`
ABI byte-shape identities `tail32` and `tail48`.
-/

namespace LidoSRv3.Tests.SourceTopupBeaconEffectsCanonicalPayloadKillLines

open LidoSRv3.Audit.Source.TopupBeaconEffects
open LidoSRv3.Audit.Source.TrioReserve1 Live
open LidoSRv3.Audit.Verity.TopupTx

/-! ## `tail32` — 32-byte length prefix + right-padded chunk. -/

theorem tail32_restated (xs : List Nat) (hl : xs.length = 32)
    (hb : ∀ b ∈ xs, b < 256) :
    (abiBytesTail xs).flatMap (fun w => encode 32 w.val) =
      encode 32 32 ++ xs.map UInt8.ofNat :=
  tail32 xs hl hb

/-! ## `tail48` — 48-byte length prefix + right-padded 16-zero pad. -/

theorem tail48_restated (xs : List Nat) (hl : xs.length = 48)
    (hb : ∀ b ∈ xs, b < 256) :
    (abiBytesTail xs).flatMap (fun w => encode 32 w.val) =
      encode 32 48 ++ xs.map UInt8.ofNat ++ List.replicate 16 0 :=
  tail48 xs hl hb

end LidoSRv3.Tests.SourceTopupBeaconEffectsCanonicalPayloadKillLines
