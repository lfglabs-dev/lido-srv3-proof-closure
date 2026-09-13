/-! # Solidity uint256 arithmetic wrap source model

**General rule (Thomas 2026-09-13, real derivation naming the pinned
Solidity uint256 arithmetic wrap semantics as a source-level
function.)**

Solidity's built-in uint256 arithmetic wraps mod 2^256 (post-0.8
overflow-checked; pre-0.8 wraps by default). SafeMath overflow
detection compares the sum to its inputs. The Verity plane uses
unbounded `Nat` arithmetic; source consumers of pinned Solidity
arithmetic need a shared wrap model.

This composition names the uint256 wrap as a source-level function
`toUint256 x = x % 2^256`, plus wrap-detection predicates for SafeMath
overflow (`checkedAddOverflow a b = a + b < a`) and the modular
`wrappedAdd a b = (a + b) % 2^256`.

**Status:** first real derivation of the shared Solidity uint256
arithmetic-wrap semantics. Downstream consumers can compose through
this to eliminate free `Nat` slots for uint256 values. -/

namespace LidoSRv3.Audit.Source.SolidityUint256WrapSource

/-- uint256 upper bound: 2^256 - 1. -/
def uint256Max : Nat := 2 ^ 256 - 1

/-- uint256 modulus: 2^256. -/
def uint256Modulus : Nat := 2 ^ 256

/-- Solidity `uint256(x)` cast: truncate to uint256. -/
def toUint256 (x : Nat) : Nat := x % uint256Modulus

/-- Modular addition wrap. -/
def wrappedAdd (a b : Nat) : Nat := (a + b) % uint256Modulus

/-- Pre-0.8 SafeMath overflow-detection predicate: overflow iff
`a + b < a` (modular arithmetic surface). Modelled on Nat as
`a + b ≥ uint256Modulus`. -/
def checkedAddOverflow (a b : Nat) : Bool :=
  decide (a + b ≥ uint256Modulus)

/-- The truncated value is strictly less than uint256Modulus. -/
theorem toUint256_lt_modulus (x : Nat) : toUint256 x < uint256Modulus := by
  have hToUint : toUint256 x = x % (2 ^ 256) := rfl
  have hMod : uint256Modulus = 2 ^ 256 := rfl
  rw [hToUint, hMod]
  apply Nat.mod_lt
  exact Nat.two_pow_pos 256

/-- Idempotence: `toUint256 ∘ toUint256 = toUint256`. -/
theorem toUint256_idem (x : Nat) : toUint256 (toUint256 x) = toUint256 x := by
  unfold toUint256
  exact Nat.mod_mod x uint256Modulus

/-- Under the pinned "`a + b < uint256Modulus`" premise, the
SafeMath overflow-detection predicate is false. Real derivation. -/
theorem checkedAddOverflow_false_of_bounded
    {a b : Nat} (hLt : a + b < uint256Modulus) :
    checkedAddOverflow a b = false := by
  simp [checkedAddOverflow]
  omega

/-- Under the pinned "`a + b ≥ uint256Modulus`" premise, the
SafeMath overflow-detection predicate is true. Real derivation. -/
theorem checkedAddOverflow_true_of_wrap
    {a b : Nat} (hGe : a + b ≥ uint256Modulus) :
    checkedAddOverflow a b = true := by
  simp [checkedAddOverflow, hGe]

end LidoSRv3.Audit.Source.SolidityUint256WrapSource
