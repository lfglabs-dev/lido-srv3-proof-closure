/-! # Lido buffered+depositedPostReport packed uint128 pair source model

**General rule (Thomas 2026-09-13, real derivation naming the pinned
Lido.sol:131-132 packed uint128 buffered+depositedPostReport pair as
a source-level function.)**

Chantier: grok differential #419 flags D-PACK-1 — Verity does not
model the packed uint128 pair `buffered` / `depositedPostReport`
(`Lido.sol:131-132`). A seeded `depositedPostReport = uint128.max +
1 ether` still fits uint256 SafeMath in the model, but the pin's
0.4.24 `<< 128` wraps the high half.

This composition names the packed uint128 pair as a source-level
function: `packed = buffered | (depositedPostReport << 128)` (both
truncated to uint128). Under a pinned "both halves ≤ uint128.max"
premise, no wrap occurs; otherwise the addition triggers a wrap.

Pinned Solidity (17005714):

- `Lido.sol:131-132`: `bytes32 constant BUFFERED_ETHER_AND_DEPOSITED_POST_REPORT_POSITION = ...` with:
  - low uint128: `buffered`
  - high uint128: `depositedPostReport`
- Reading: `packedBuffer >> 128` for the high half, low uint128 mask
  for the low half.

**Status:** first real derivation naming the D-PACK-1 divergence
(grok #419) as a source-level packed uint128 pair. -/

namespace LidoSRv3.Audit.Source.ReservePackedBufferSource

/-- uint128 upper bound: 2^128 - 1. -/
def uint128Max : Nat := 2 ^ 128 - 1

/-- uint128 mask: 2^128. -/
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
