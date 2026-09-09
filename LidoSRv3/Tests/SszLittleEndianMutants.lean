import LidoSRv3.Audit.Source.SszLittleEndianCorrespondence

/-! Kernel-checked vectors and counterexamples for the narrow SSZ endian slice.
These tests check byte order across all stages, uint64 zero padding, bool
placement, and detect three plausible regressions. They do not execute Solidity.
-/

namespace LidoSRv3.Tests.SszLittleEndianMutants

open LidoSRv3.Audit.Source.SszLittleEndianCorrespondence

theorem distinct_octets :
    sourceUint256
      0x000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f =
      0x1f1e1d1c1b1a191817161514131211100f0e0d0c0b0a09080706050403020100 := by
  decide

theorem uint64_max_padding :
    sourceUint256 0xffffffffffffffff =
      0xffffffffffffffff000000000000000000000000000000000000000000000000 := by
  decide

theorem high_input_byte_is_preserved :
    sourceUint256 (1 <<< 248) = 1 := by decide

theorem bool_values :
    sourceBool false = 0 ∧
    sourceBool true =
      0x0100000000000000000000000000000000000000000000000000000000000000 := by
  decide

/-- Reversing the final 128-bit swap simulates omitting that source stage. -/
def omitFinalSwap (v : Word) : Word :=
  (sourceUint256 v >>> 128) ||| (sourceUint256 v <<< 128)

theorem missing_final_swap_detected :
    omitFinalSwap 1 ≠ littleEndianOctets 1 := by decide

/-- A mistaken uint64 restriction discards legal high bits of the uint256 overload. -/
def truncateInput (v : Word) : Word :=
  sourceUint256 (v &&& 0xffffffffffffffff)

theorem uint64_truncation_detected :
    truncateInput (1 <<< 248) ≠ littleEndianOctets (1 <<< 248) := by decide

def boolAtWrongEnd (v : Bool) : Word := if v then 1 else 0

theorem bool_position_detected :
    boolAtWrongEnd true ≠ boolChunk true := by decide

end LidoSRv3.Tests.SszLittleEndianMutants
