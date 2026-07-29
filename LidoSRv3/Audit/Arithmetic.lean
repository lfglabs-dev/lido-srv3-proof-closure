import Verity.Stdlib.Math

namespace LidoSRv3.Audit

/-!
# Checked, unit-aware arithmetic

Economic quantities use Verity's pinned `Uint256`. `Nat` is used only for list
indices and recursion. The phantom unit prevents accidental Wei/Gwei/validator
mixing while retaining the exact checked arithmetic supplied by Verity.
-/

open Verity
open Verity.Stdlib.Math

inductive WeiUnit
  deriving DecidableEq, Repr
inductive GweiUnit
  deriving DecidableEq, Repr
inductive ValidatorUnit
  deriving DecidableEq, Repr
inductive BasisPointUnit
  deriving DecidableEq, Repr

/-- A `uint256` quantity whose unit is checked by Lean. -/
structure Quantity (unit : Type) where
  value : Uint256
  deriving DecidableEq, Repr

abbrev Wei := Quantity WeiUnit
abbrev Gwei := Quantity GweiUnit
abbrev Validators := Quantity ValidatorUnit
abbrev BasisPoints := Quantity BasisPointUnit

namespace Quantity

def zero : Quantity unit := ⟨0⟩

/-- Solidity-0.8-style checked addition, via pinned Verity `safeAdd`. -/
def checkedAdd (a b : Quantity unit) : Option (Quantity unit) :=
  (safeAdd a.value b.value).map Quantity.mk

/-- Solidity-0.8-style checked subtraction, via pinned Verity `safeSub`. -/
def checkedSub (a b : Quantity unit) : Option (Quantity unit) :=
  (safeSub a.value b.value).map Quantity.mk

/-- Solidity-0.8-style checked multiplication by a dimensionless word. -/
def checkedMul (a : Quantity unit) (factor : Uint256) : Option (Quantity unit) :=
  (safeMul a.value factor).map Quantity.mk

/-- Checked division: unlike EVM `DIV`, a zero divisor is rejected. -/
def checkedDiv (a : Quantity unit) (divisor : Uint256) : Option (Quantity unit) :=
  if divisor = 0 then none else some ⟨a.value / divisor⟩

/-- Source-only saturating subtraction (for `Math.max`/headroom expressions). -/
def saturatingSub (a b : Quantity unit) : Quantity unit :=
  if b.value ≤ a.value then ⟨a.value - b.value⟩ else zero

/-- Checked left-to-right sum. The `Nat` recursion is structural only. -/
def checkedSum : List (Quantity unit) → Option (Quantity unit)
  | [] => some zero
  | x :: xs => do
      let tail ← checkedSum xs
      checkedAdd x tail

@[simp] theorem checkedSum_nil :
    checkedSum ([] : List (Quantity unit)) = some zero := rfl

@[simp] theorem checkedSum_cons (x : Quantity unit) (xs : List (Quantity unit)) :
    checkedSum (x :: xs) = (do
      let tail ← checkedSum xs
      checkedAdd x tail) := rfl

theorem checkedDiv_zero (a : Quantity unit) :
    checkedDiv a 0 = none := by
  simp [checkedDiv]

theorem saturatingSub_zero_of_le {a b : Quantity unit} (h : a.value ≤ b.value) :
    saturatingSub a b = zero := by
  unfold saturatingSub
  by_cases hEq : a.value = b.value
  · simp [hEq, zero]
  · have hNot : ¬ b.value ≤ a.value := by
      intro hReverse
      exact hEq (Verity.Core.Uint256.ext (Nat.le_antisymm h hReverse))
    simp [hNot, zero]

end Quantity

end LidoSRv3.Audit
