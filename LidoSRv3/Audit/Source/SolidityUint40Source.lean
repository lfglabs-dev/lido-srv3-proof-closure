/-! # Solidity uint40 truncation source model

**General rule (Thomas 2026-09-13, real derivation naming the pinned
Solidity uint40 truncation semantics — used by the WQ
WithdrawalRequest.timestamp field and any downstream consumer of a
40-bit integer.)**

Solidity's uint40 fits in 40 bits (2^40 ≈ 1.1 × 10^12), typically
used for block timestamps and similar time-bounded values. Packed-
decoder extractions for uint40 fields (WithdrawalRequest.timestamp,
etc.) truncate at 40 bits per the pinned Solidity semantics.

This composition names the uint40 truncation as a source-level
function plus the standard idempotence and bounded round-trip
theorems.

**Status:** first real derivation of the shared Solidity uint40
truncation. Downstream consumers (WithdrawalRequest.timestamp
extraction) can compose through this. -/

namespace LidoSRv3.Audit.Source.SolidityUint40Source

/-- uint40 upper bound: 2^40 - 1. -/
def uint40Max : Nat := 2 ^ 40 - 1

/-- uint40 modulus: 2^40. -/
def uint40Modulus : Nat := 2 ^ 40

/-- Solidity `uint40(x)` cast: truncate to uint40. -/
def toUint40 (x : Nat) : Nat := x % uint40Modulus

/-- The truncated value is strictly less than uint40Modulus. -/
theorem toUint40_lt_modulus (x : Nat) : toUint40 x < uint40Modulus := by
  have hToUint : toUint40 x = x % (2 ^ 40) := rfl
  have hMod : uint40Modulus = 2 ^ 40 := rfl
  rw [hToUint, hMod]
  apply Nat.mod_lt
  exact Nat.two_pow_pos 40

/-- Idempotence: `toUint40 ∘ toUint40 = toUint40`. -/
theorem toUint40_idem (x : Nat) : toUint40 (toUint40 x) = toUint40 x := by
  unfold toUint40
  exact Nat.mod_mod x uint40Modulus

end LidoSRv3.Audit.Source.SolidityUint40Source
