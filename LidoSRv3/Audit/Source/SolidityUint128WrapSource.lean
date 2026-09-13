/-! # Solidity uint128 arithmetic wrap source model

**General rule (Thomas 2026-09-13, real derivation naming the pinned
Solidity uint128 arithmetic wrap semantics — used by the packed
Lido buffered+depositedPostReport pair and any downstream consumer
of narrower integer types.)**

Solidity's uint128 wraps mod 2^128; when it appears as a field of a
packed uint256 slot (e.g., `Lido.sol:131-132` buffered/
depositedPostReport pair), the arithmetic in the shift/mask
operations follows the uint128 wrap. The Verity plane uses unbounded
`Nat` arithmetic; source consumers need a shared uint128 wrap model.

This composition names the uint128 wrap as a source-level function
`toUint128 x = x % 2^128`, plus overflow detection and wrap-add.

**Status:** first real derivation of the shared Solidity uint128
arithmetic-wrap semantics. Downstream consumers (packed
buffered+depositedPostReport pair, any uint128 field of a packed
struct) can compose through this. -/

namespace LidoSRv3.Audit.Source.SolidityUint128WrapSource

/-- uint128 upper bound: 2^128 - 1. -/
def uint128Max : Nat := 2 ^ 128 - 1

/-- uint128 modulus: 2^128. -/
def uint128Modulus : Nat := 2 ^ 128

/-- Solidity `uint128(x)` cast: truncate to uint128. -/
def toUint128 (x : Nat) : Nat := x % uint128Modulus

/-- Modular addition wrap. -/
def wrappedAdd (a b : Nat) : Nat := (a + b) % uint128Modulus

/-- Overflow-detection predicate: overflow iff `a + b ≥ uint128Modulus`. -/
def checkedAddOverflow (a b : Nat) : Bool :=
  decide (a + b ≥ uint128Modulus)

/-- The truncated value is strictly less than uint128Modulus. -/
theorem toUint128_lt_modulus (x : Nat) : toUint128 x < uint128Modulus := by
  have hToUint : toUint128 x = x % (2 ^ 128) := rfl
  have hMod : uint128Modulus = 2 ^ 128 := rfl
  rw [hToUint, hMod]
  apply Nat.mod_lt
  exact Nat.two_pow_pos 128

/-- Idempotence: `toUint128 ∘ toUint128 = toUint128`. -/
theorem toUint128_idem (x : Nat) : toUint128 (toUint128 x) = toUint128 x := by
  unfold toUint128
  exact Nat.mod_mod x uint128Modulus

/-- Under the pinned "`a + b < uint128Modulus`" premise, the
overflow-detection predicate is false. -/
theorem checkedAddOverflow_false_of_bounded
    {a b : Nat} (hLt : a + b < uint128Modulus) :
    checkedAddOverflow a b = false := by
  simp [checkedAddOverflow]
  omega

/-- Under the pinned "`a + b ≥ uint128Modulus`" premise, the
overflow-detection predicate is true. -/
theorem checkedAddOverflow_true_of_wrap
    {a b : Nat} (hGe : a + b ≥ uint128Modulus) :
    checkedAddOverflow a b = true := by
  simp [checkedAddOverflow, hGe]

end LidoSRv3.Audit.Source.SolidityUint128WrapSource
