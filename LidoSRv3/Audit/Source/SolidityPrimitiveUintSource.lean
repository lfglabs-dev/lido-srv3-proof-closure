/-! # Solidity uint96/uint64/uint32/uint24/uint16/uint8 truncation source model

**General rule (Thomas 2026-09-13, real derivation naming the pinned
Solidity primitive-uint truncation semantics — shared source-model
for all packed-decoder consumers.)**

Solidity's uint96/uint64/uint32/uint24/uint16/uint8 each truncate at
their bit width. Packed-decoder extractions across every registered
guarantee use these; a shared source model amortizes the naming
across many downstream consumers.

Modelled fields:
- uint96 (Lido StakeLimitStruct prevStakeLimit, maxStakeLimit)
- uint64 (SR module deposited/depositable/summaryExited counts)
- uint32 (Lido StakeLimitStruct prevStakeBlockNumber, maxStakeLimitGrowthBlocks; ABI selectors)
- uint24 (SR moduleId)
- uint16 (any narrow packed field)
- uint8 (Lido StakeLimitStruct paused; WQ Checkpoint reportTimestampMargin;
        WC type byte; boolean packing)

**Status:** first real derivation of the shared Solidity primitive-
uint truncations. Downstream consumers can compose through any of
the six modeled widths. -/

namespace LidoSRv3.Audit.Source.SolidityPrimitiveUintSource

/-- Generic uint-width truncation with the corresponding max/modulus. -/
def uintNMax (width : Nat) : Nat := 2 ^ width - 1
def uintNModulus (width : Nat) : Nat := 2 ^ width
def toUintN (width x : Nat) : Nat := x % uintNModulus width

/-- Instances at pinned widths: 96, 64, 32, 24, 16, 8. -/
def toUint96 (x : Nat) : Nat := toUintN 96 x
def toUint64 (x : Nat) : Nat := toUintN 64 x
def toUint32 (x : Nat) : Nat := toUintN 32 x
def toUint24 (x : Nat) : Nat := toUintN 24 x
def toUint16 (x : Nat) : Nat := toUintN 16 x
def toUint8  (x : Nat) : Nat := toUintN 8  x

/-- Generic bound: the truncated value is strictly less than the
modulus at the width. -/
theorem toUintN_lt_modulus (width x : Nat) :
    toUintN width x < uintNModulus width := by
  have hToUint : toUintN width x = x % (2 ^ width) := rfl
  have hMod : uintNModulus width = 2 ^ width := rfl
  rw [hToUint, hMod]
  apply Nat.mod_lt
  exact Nat.two_pow_pos width

/-- Generic idempotence. -/
theorem toUintN_idem (width x : Nat) :
    toUintN width (toUintN width x) = toUintN width x := by
  unfold toUintN
  exact Nat.mod_mod x (uintNModulus width)

end LidoSRv3.Audit.Source.SolidityPrimitiveUintSource
