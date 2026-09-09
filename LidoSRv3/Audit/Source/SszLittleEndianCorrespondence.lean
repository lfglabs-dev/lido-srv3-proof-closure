import Mathlib.Tactic.IntervalCases

/-!
# SSZ integer and boolean leaf encoding

Pinned source: `lidofinance/core@17005714f151e5502c559932319a3f2f74ac2436`,
`contracts/common/lib/SSZ.sol:251-270`. The integer overload is used for
validator balance and epoch fields at lines 113 and 115-118; the boolean
overload encodes `slashed` at line 114. Header integers use it at lines 23-24.

`sourceUint256` transcribes the five fixed-width mask/shift stages. The
independent specification concatenates the original octets in increasing
significance order, which is their order in a little-endian SSZ chunk.
`source_uint256_eq_octets` proves equality for **every** 256-bit input, with
no range or equivalence assumption. `source_uint64_chunk` specializes to
SSZ uint64 values and proves that the remaining 24 bytes are zero.

This is a narrow source-arithmetic result. The transcription-to-Solidity link
requires source review; this file proves no compiler/EVM execution, memory
layout, validator field selection, SHA-256, verifier path, or deployment fact.
-/

namespace LidoSRv3.Audit.Source.SszLittleEndianCorrespondence

abbrev Word := BitVec 256

set_option maxRecDepth 4096
set_option maxHeartbeats 1000000

/-- Literal fixed-width operations of `SSZ.sol:252-265`. -/
def sourceUint256 (v : BitVec 256) : BitVec 256 :=
  let v :=
    ((v &&& 0xFF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00) >>> (8 : Nat)) |||
    ((v &&& 0x00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF) <<< (8 : Nat))
  let v :=
    ((v &&& 0xFFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000) >>> (16 : Nat)) |||
    ((v &&& 0x0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF) <<< (16 : Nat))
  let v :=
    ((v &&& 0xFFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000) >>> (32 : Nat)) |||
    ((v &&& 0x00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF) <<< (32 : Nat))
  let v :=
    ((v &&& 0xFFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF0000000000000000) >>> (64 : Nat)) |||
    ((v &&& 0x0000000000000000FFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF) <<< (64 : Nat))
  (v >>> (128 : Nat)) ||| (v <<< (128 : Nat))

/-- Mathematical little-endian serialization, represented as a bytes32 word:
the least significant input octet is the first (most significant) output octet.
No source masks or staged swapping algorithm occurs in this definition. -/
def littleEndianOctets (v : BitVec 256) : BitVec 256 :=
  v.extractLsb' 0 8 ++ v.extractLsb' 8 8 ++
  v.extractLsb' 16 8 ++ v.extractLsb' 24 8 ++
  v.extractLsb' 32 8 ++ v.extractLsb' 40 8 ++
  v.extractLsb' 48 8 ++ v.extractLsb' 56 8 ++
  v.extractLsb' 64 8 ++ v.extractLsb' 72 8 ++
  v.extractLsb' 80 8 ++ v.extractLsb' 88 8 ++
  v.extractLsb' 96 8 ++ v.extractLsb' 104 8 ++
  v.extractLsb' 112 8 ++ v.extractLsb' 120 8 ++
  v.extractLsb' 128 8 ++ v.extractLsb' 136 8 ++
  v.extractLsb' 144 8 ++ v.extractLsb' 152 8 ++
  v.extractLsb' 160 8 ++ v.extractLsb' 168 8 ++
  v.extractLsb' 176 8 ++ v.extractLsb' 184 8 ++
  v.extractLsb' 192 8 ++ v.extractLsb' 200 8 ++
  v.extractLsb' 208 8 ++ v.extractLsb' 216 8 ++
  v.extractLsb' 224 8 ++ v.extractLsb' 232 8 ++
  v.extractLsb' 240 8 ++ v.extractLsb' 248 8

/-- Independent uint64 SSZ chunk: eight little-endian octets then 24 zero bytes. -/
def uint64Chunk (v : BitVec 64) : BitVec 256 :=
  v.extractLsb' 0 8 ++ v.extractLsb' 8 8 ++
  v.extractLsb' 16 8 ++ v.extractLsb' 24 8 ++
  v.extractLsb' 32 8 ++ v.extractLsb' 40 8 ++
  v.extractLsb' 48 8 ++ v.extractLsb' 56 8 ++ (0 : BitVec 192)

/-- Literal `SSZ.sol:268-269`, including the bytes32 position of the one byte. -/
def sourceBool (v : Bool) : BitVec 256 :=
  if v then (1 : BitVec 256) <<< (248 : Nat) else 0

/-- SSZ boolean byte (0 or 1), followed by 31 zero bytes. -/
def boolChunk (v : Bool) : BitVec 256 :=
  (if v then (1 : BitVec 8) else 0) ++ (0 : BitVec 248)

theorem source_uint256_eq_octets (v : BitVec 256) :
    sourceUint256 v = littleEndianOctets v := by
  apply BitVec.eq_of_getLsbD_eq_iff.mpr
  intro i hi
  simp only [littleEndianOctets, BitVec.getLsbD_append]
  interval_cases i <;> simp [sourceUint256]

/-- Numeric uint64 values are widened with zeros before entering the overload. -/
theorem source_uint64_chunk (v : BitVec 64) :
    sourceUint256 (v.zeroExtend 256) = uint64Chunk v := by
  rw [source_uint256_eq_octets]
  apply BitVec.eq_of_getLsbD_eq_iff.mpr
  intro i hi
  simp only [littleEndianOctets, uint64Chunk, BitVec.getLsbD_append]
  interval_cases i <;> simp

theorem source_bool_chunk (v : Bool) : sourceBool v = boolChunk v := by
  cases v <;> decide

/-- Serialization loses no input bits, independently of any hash function. -/
theorem source_uint256_injective (a b : BitVec 256)
    (h : sourceUint256 a = sourceUint256 b) : a = b := by
  apply BitVec.eq_of_getLsbD_eq_iff.mpr
  intro i hi
  have hbit := congrArg (fun w : BitVec 256 =>
    w.getLsbD ((31 - i / 8) * 8 + i % 8)) h
  interval_cases i <;> simpa [sourceUint256] using hbit

end LidoSRv3.Audit.Source.SszLittleEndianCorrespondence
