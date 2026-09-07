import Init

/-!
Consumer-local arithmetic. Pinned source: lidofinance/core@
17005714f151e5502c559932319a3f2f74ac2436,
contracts/common/lib/Math256.sol:39–43. No producer namespace or interface change.
Panic constructors are semantic outcomes; exact revert bytes are a separate layer.
-/
namespace LidoSRv3.Audit.Source.TrioAlloc2

abbrev Word := Fin (2 ^ 256)

inductive Panic where
  | arithmetic
  | divisionByZero
  | arrayBounds
  deriving DecidableEq, Repr

abbrev Result (α : Type) := Except Panic α

def zero : Word := ⟨0, by decide⟩
def one : Word := ⟨1, by decide⟩
def maxWord : Word := ⟨2 ^ 256 - 1, by decide⟩

def checkedAdd (a b : Word) : Result Word :=
  if h : a.val + b.val < 2 ^ 256 then .ok ⟨a.val + b.val, h⟩
  else .error .arithmetic

def checkedSub (a b : Word) : Result Word :=
  if b.val ≤ a.val then .ok ⟨a.val - b.val, Nat.lt_of_le_of_lt (Nat.sub_le ..) a.isLt⟩
  else .error .arithmetic

def checkedMul (a b : Word) : Result Word :=
  if h : a.val * b.val < 2 ^ 256 then .ok ⟨a.val * b.val, h⟩
  else .error .arithmetic

def checkedDiv (a b : Word) : Result Word :=
  if b.val = 0 then .error .divisionByZero
  else .ok ⟨a.val / b.val, Nat.lt_of_le_of_lt (Nat.div_le_self ..) a.isLt⟩

/-- Source conditional precedes subtraction and division, even when b = 0. -/
def ceilDiv (a b : Word) : Result Word := do
  if a.val = 0 then return zero
  let decremented ← checkedSub a one
  let quotient ← checkedDiv decremented b
  checkedAdd quotient one

def minWord (a b : Word) : Word := if a.val < b.val then a else b

theorem checkedAdd_value (a b out : Word) (h : checkedAdd a b = .ok out) :
    out.val = a.val + b.val := by
  unfold checkedAdd at h
  split at h
  · cases h; rfl
  · cases h

theorem checkedMul_value (a b out : Word) (h : checkedMul a b = .ok out) :
    out.val = a.val * b.val := by
  unfold checkedMul at h
  split at h
  · cases h; rfl
  · cases h

theorem ceilDiv_zero_numerator (b : Word) : ceilDiv zero b = .ok zero := by
  rfl

end LidoSRv3.Audit.Source.TrioAlloc2
