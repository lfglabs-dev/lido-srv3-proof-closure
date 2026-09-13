import LidoSRv3.Audit.Source.ReservePackedBufferSource

/-! # Kill-lines for `ReservePackedBufferSource`

**Chantier 2 (Piste A, Thomas 2026-09-13) mutant kill-lines pinning
the pinned packed uint128 pair semantics (D-PACK-1).**

`ReservePackedBufferSource.packPair` / `unpackBuffered` /
`unpackDepositedPostReport` name the pinned `Lido.sol:131-132`
packed uint256 storage: low uint128 = `buffered`, high uint128 =
`depositedPostReport`.

These kill-lines exhibit concrete counterexamples for weakened
formulations. -/

namespace LidoSRv3.Tests.ReservePackedBufferKillLines

open LidoSRv3.Audit.Source.ReservePackedBufferSource

/-- **Kill-line: `packPair` at witness values.**

`packPair 42 100` = `42 + 100 * 2^128` — the pair concatenation with
low = 42, high = 100. -/
theorem packPair_at_witness :
    packPair 42 100 = 42 + 100 * uint128Modulus := by
  simp [packPair, uint128Modulus]

/-- **Kill-line: `unpackBuffered` recovers the low half at witness.**

`unpackBuffered (packPair 42 100) = 42` under the bounded premise.  A
mutant that returned the high half would produce 100. -/
theorem unpackBuffered_at_witness :
    unpackBuffered (packPair 42 100) = 42 := by
  apply unpackBuffered_of_packPair_of_bounded
  unfold uint128Max
  decide

/-- **Kill-line: `unpackDepositedPostReport` recovers the high half.**

`unpackDepositedPostReport (packPair 42 100)` should recover 100 (the
high uint128).  Provable directly under bounded premise. -/
theorem unpackDepositedPostReport_at_witness :
    unpackDepositedPostReport (packPair 42 100) = 100 := by
  unfold unpackDepositedPostReport packPair uint128Modulus
  decide

/-- **Kill-line: `unpackBuffered` on unbounded values wraps.**

Applied to `x = uint128Modulus + 1`, `unpackBuffered x = 1` — the
truncation wraps.  A mutant that returned the raw value would produce
`uint128Modulus + 1`. -/
theorem unpackBuffered_wraps_above_modulus :
    unpackBuffered (uint128Modulus + 1) = 1 := by
  unfold unpackBuffered uint128Modulus
  decide

/-- **Kill-line: `packPair` and `unpackBuffered` are inverse only under
bound.**

Without the bound, `unpackBuffered (packPair (2^128) 0) = 0 ≠ 2^128`
— because `(2^128) % 2^128 = 0`.  The bounded premise is
load-bearing for the inverse identity. -/
theorem packPair_unpack_needs_bound :
    unpackBuffered (packPair uint128Modulus 0) ≠ uint128Modulus := by
  unfold unpackBuffered packPair uint128Modulus
  decide

/-- **Kill-line: `packPair 0 0 = 0`.** -/
theorem packPair_of_zero_zero :
    packPair 0 0 = 0 := by
  simp [packPair]

/-- **Kill-line: `uint128Modulus = 2^128`.** -/
theorem uint128Modulus_pinned :
    uint128Modulus = 2 ^ 128 := rfl

/-- **Kill-line: `uint128Max = 2^128 - 1`.** -/
theorem uint128Max_pinned :
    uint128Max = 2 ^ 128 - 1 := rfl

#print axioms packPair_at_witness
#print axioms unpackBuffered_at_witness
#print axioms unpackDepositedPostReport_at_witness
#print axioms unpackBuffered_wraps_above_modulus
#print axioms packPair_unpack_needs_bound
#print axioms packPair_of_zero_zero
#print axioms uint128Modulus_pinned
#print axioms uint128Max_pinned

end LidoSRv3.Tests.ReservePackedBufferKillLines
