import LidoSRv3.Audit.Verity.TopupTx

/-!
Kill-lines pinning `Verity.TopupTx` ABI-byte encoders
(`sourceByteCommitment`, `abiWordOfBytes`, `abiByteWords`,
`abiBytesTail`, `abiBytesArrayOffsets`, `abiBytesArrayTail`) on
concrete inputs. These pin the byte-stream ABI transcription used by
the beacon deposit call plane.
-/

namespace LidoSRv3.Tests.VerityTopupTxAbiEncodersKillLines

open LidoSRv3.Audit.Verity.TopupTx

/-! ## `sourceByteCommitment` — big-endian fold over bytes. -/

theorem sourceByteCommitment_empty :
    sourceByteCommitment [] = 0 := rfl

theorem sourceByteCommitment_single :
    sourceByteCommitment [0x42] = 0x42 := by decide

theorem sourceByteCommitment_two :
    sourceByteCommitment [0x01, 0x02] = 0x0102 := by decide

theorem sourceByteCommitment_four_bytes :
    sourceByteCommitment [0xde, 0xad, 0xbe, 0xef] = 0xdeadbeef := by decide

/-! ## `abiWordOfBytes` — pad-right to 32 bytes. -/

theorem abiWordOfBytes_empty :
    abiWordOfBytes [] = (0 : Verity.Uint256) := rfl

/-- A single byte at index 0 has its value at position 31 (right-padded). -/
theorem abiWordOfBytes_single_byte_high :
    (abiWordOfBytes [0x01]).val = 256 ^ 31 := by decide

/-- Exactly 32 bytes of `0x01` — no padding — is a specific concrete Nat. -/
theorem abiWordOfBytes_32_of_ones_nonzero :
    (abiWordOfBytes (List.replicate 32 1)).val ≠ 0 := by decide

/-! ## `abiByteWords` — chunk into 32-byte words. -/

theorem abiByteWords_empty :
    abiByteWords [] = [] := rfl

theorem abiByteWords_length_1 :
    (abiByteWords [0x42]).length = 1 := rfl

theorem abiByteWords_length_32 :
    (abiByteWords (List.replicate 32 1)).length = 1 := rfl

theorem abiByteWords_length_33 :
    (abiByteWords (List.replicate 33 1)).length = 2 := rfl

/-! ## `abiBytesTail` — length prefix then padded content. -/

theorem abiBytesTail_empty :
    abiBytesTail [] = [(0 : Verity.Uint256)] := rfl

theorem abiBytesTail_length_prefix :
    (abiBytesTail [0x01, 0x02]).head?.get! = (2 : Verity.Uint256) := by decide

/-! ## `abiBytesArrayOffsets` — offsets accumulate with word-count. -/

theorem abiBytesArrayOffsets_empty (offset : Nat) :
    abiBytesArrayOffsets [] offset = [] := rfl

/-! ## `abiBytesArrayTail` — length prefix + offsets + flattened tails. -/

theorem abiBytesArrayTail_empty :
    abiBytesArrayTail [] = [(0 : Verity.Uint256)] := rfl

end LidoSRv3.Tests.VerityTopupTxAbiEncodersKillLines
