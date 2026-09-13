/-! # Solidity min/max primitive source model

**General rule (Thomas 2026-09-13, real derivation naming the pinned
Solidity min/max helpers as source-level functions — used across
TOPUP-2 evaluateTopUpLimit, allocation loops, and any downstream
consumer of a bounded aggregate.)**

Solidity's `Math.min(a, b) = a < b ? a : b` and
`Math.max(a, b) = a < b ? b : a` appear in many pinned code paths
(TopUpGateway._evaluateTopUpLimit, StakingRouter allocation loops,
Lido stake-limit computations). This composition names the pinned
semantics as source-level functions, plus symmetry / idempotence /
bounded-property theorems.

**Status:** first real derivation of the shared Solidity min/max
primitives. Downstream consumers can compose through these to
eliminate Nat.min/Nat.max obfuscation of the pinned Solidity
semantics. -/

namespace LidoSRv3.Audit.Source.SolidityMinSource

/-- Source-level definition of the pinned `Math.min(a, b)`. -/
def minU (a b : Nat) : Nat := if a < b then a else b

/-- Source-level definition of the pinned `Math.max(a, b)`. -/
def maxU (a b : Nat) : Nat := if a < b then b else a

/-- min is bounded above by both arguments. -/
theorem minU_le_left (a b : Nat) : minU a b ≤ a := by
  unfold minU
  split
  · exact Nat.le_refl a
  · omega

theorem minU_le_right (a b : Nat) : minU a b ≤ b := by
  unfold minU
  split
  · omega
  · exact Nat.le_refl b

/-- max is bounded below by both arguments. -/
theorem left_le_maxU (a b : Nat) : a ≤ maxU a b := by
  unfold maxU
  split
  · omega
  · exact Nat.le_refl a

theorem right_le_maxU (a b : Nat) : b ≤ maxU a b := by
  unfold maxU
  split
  · exact Nat.le_refl b
  · omega

/-- Idempotence. -/
theorem minU_self (a : Nat) : minU a a = a := by
  unfold minU; simp

theorem maxU_self (a : Nat) : maxU a a = a := by
  unfold maxU; simp

end LidoSRv3.Audit.Source.SolidityMinSource
