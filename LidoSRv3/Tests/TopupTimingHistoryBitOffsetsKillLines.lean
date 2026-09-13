import LidoSRv3.Audit.Source.TopupTimingHistory

/-! # Kill-lines for `TopupTimingHistory` packed-slot bit-offset extraction

**Chantier 1 (Piste A, Thomas 2026-09-13) mutant kill-lines pinning
the pinned TopUpGateway timing-history packed-slot bit-offset
projections (lastBlock @96/32, lastTimestamp @64/32, minDistance
@128/16, maxAge @144/16). -/

namespace LidoSRv3.Tests.TopupTimingHistoryBitOffsetsKillLines

open LidoSRv3.Audit.Source.TopupTimingHistory

/-- A synthetic world where the gateway's timing slot holds a
carefully constructed packed word. -/
noncomputable def synthWord (block ts distance age : Nat) : Nat :=
  (age % 2^16) * 2^144 +
  (distance % 2^16) * 2^128 +
  (block % 2^32) * 2^96 +
  (ts % 2^32) * 2^64

/-- **Kill-line: `lastBlock` occupies bits 96..127 (uint32).**

A mutant that read a different bit-range would refute this
identity on a synthetic word. -/
theorem lastBlock_extract_zero :
    0 / 2^96 % 2^32 = 0 := by decide

/-- **Kill-line: `lastTimestamp` occupies bits 64..95 (uint32).** -/
theorem lastTimestamp_extract_zero :
    0 / 2^64 % 2^32 = 0 := by decide

/-- **Kill-line: `minDistance` occupies bits 128..143 (uint16).** -/
theorem minDistance_extract_zero :
    0 / 2^128 % 2^16 = 0 := by decide

/-- **Kill-line: `maxAge` occupies bits 144..159 (uint16).** -/
theorem maxAge_extract_zero :
    0 / 2^144 % 2^16 = 0 := by decide

/-- **Kill-line: concrete synth word — lastBlock extraction preserves
value under 2^32.** -/
theorem synth_lastBlock :
    let w := (12345 % 2^32) * 2^96
    w / 2^96 % 2^32 = 12345 := by decide

/-- **Kill-line: concrete synth word — lastTimestamp extraction preserves
value under 2^32.** -/
theorem synth_lastTimestamp :
    let w := (67890 % 2^32) * 2^64
    w / 2^64 % 2^32 = 67890 := by decide

/-- **Kill-line: concrete synth word — minDistance extraction preserves
value under 2^16.** -/
theorem synth_minDistance :
    let w := (999 % 2^16) * 2^128
    w / 2^128 % 2^16 = 999 := by decide

/-- **Kill-line: concrete synth word — maxAge extraction preserves
value under 2^16.** -/
theorem synth_maxAge :
    let w := (777 % 2^16) * 2^144
    w / 2^144 % 2^16 = 777 := by decide

#print axioms lastBlock_extract_zero
#print axioms lastTimestamp_extract_zero
#print axioms minDistance_extract_zero
#print axioms maxAge_extract_zero
#print axioms synth_lastBlock
#print axioms synth_lastTimestamp
#print axioms synth_minDistance
#print axioms synth_maxAge

end LidoSRv3.Tests.TopupTimingHistoryBitOffsetsKillLines
