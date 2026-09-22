/-!
Packed buffered-ether and post-report-deposit projection for
[Lido's pair setter](https://github.com/lidofinance/core/blob/17005714f151e5502c559932319a3f2f74ac2436/contracts/0.4.24/Lido.sol#L1507-L1513).
The delegated [storage helper](https://github.com/lidofinance/core/blob/17005714f151e5502c559932319a3f2f74ac2436/contracts/0.4.24/utils/UnstructuredStorageExt.sol#L38-L46)
stores `(high << 128) | (low & UINT128_LOW_MASK)`. The mask discards
low-argument bits above bit 127; the uint256 shift discards high-argument
bits above bit 127. Packing performs no checked addition or range guard.

`packPair` expresses the resulting word with modular halves and arithmetic
addition of disjoint bit ranges. Its round-trip theorem recovers the low
input when that input fits 128 bits. This arithmetic projection does not
itself connect the setter to live account storage or prove the complete
withdrawal transition, and its bounded theorem does not rule out truncation
on arbitrary source inputs.
-/

namespace LidoSRv3.Audit.Source.ReservePackedBufferSource

/-- uint128 upper bound: 2^128 - 1. -/
def uint128Max : Nat := 2 ^ 128 - 1

/-- uint128 modulus: 2^128. -/
def uint128Modulus : Nat := 2 ^ 128

/-- Source-level definition of the pinned packed uint128 pair:
`low | (high << 128)`, both halves truncated to uint128. -/
def packPair (buffered depositedPostReport : Nat) : Nat :=
  (buffered % uint128Modulus)
    + (depositedPostReport % uint128Modulus) * uint128Modulus

/-- Source-level definition of the low-half extraction from the
packed word. -/
def unpackBuffered (packedWord : Nat) : Nat :=
  packedWord % uint128Modulus

/-- Source-level definition of the high-half extraction from the
packed word. -/
def unpackDepositedPostReport (packedWord : Nat) : Nat :=
  (packedWord / uint128Modulus) % uint128Modulus

/-- Round-trip: under the pinned "buffered ≤ uint128Max" premise,
low-half extraction recovers the original value. -/
theorem unpackBuffered_of_packPair_of_bounded
    {buffered depositedPostReport : Nat}
    (hLow : buffered ≤ uint128Max) :
    unpackBuffered (packPair buffered depositedPostReport) = buffered := by
  unfold unpackBuffered packPair
  have hLowMod : buffered % uint128Modulus = buffered := by
    apply Nat.mod_eq_of_lt
    unfold uint128Modulus uint128Max at *
    omega
  rw [Nat.add_mul_mod_self_right, Nat.mod_mod]
  exact hLowMod

end LidoSRv3.Audit.Source.ReservePackedBufferSource
