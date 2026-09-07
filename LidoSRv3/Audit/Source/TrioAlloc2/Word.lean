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

theorem checkedSub_value (a b out : Word) (h : checkedSub a b = .ok out) :
    out.val = a.val - b.val := by
  unfold checkedSub at h
  split at h
  · cases h; rfl
  · cases h

theorem checkedDiv_value (a b out : Word) (h : checkedDiv a b = .ok out) :
    out.val = a.val / b.val := by
  unfold checkedDiv at h
  split at h
  · cases h
  · cases h; rfl

theorem minWord_le_left (a b : Word) : (minWord a b).val ≤ a.val := by
  unfold minWord
  split <;> simp_all <;> omega

theorem ceilDiv_le_numerator (a b out : Word) (h : ceilDiv a b = .ok out) :
    out.val ≤ a.val := by
  unfold ceilDiv at h
  by_cases hz : a.val = 0
  · simp [hz] at h
    cases h
    exact Nat.zero_le _
  · simp only [hz, ↓reduceIte] at h
    cases hs : checkedSub a one with
    | error e => simp [hs, bind, Except.bind, pure, Except.pure] at h
    | ok decremented =>
      cases hd : checkedDiv decremented b with
      | error e => simp [hs, hd, bind, Except.bind, pure, Except.pure] at h
      | ok quotient =>
        have hadd : checkedAdd quotient one = .ok out := by simpa [hs, hd, bind, Except.bind, pure, Except.pure] using h
        have subValue := checkedSub_value a one decremented hs
        have divValue := checkedDiv_value decremented b quotient hd
        have addValue := checkedAdd_value quotient one out hadd
        have divBound := Nat.div_le_self decremented.val b.val
        simp only [one] at *
        omega

end LidoSRv3.Audit.Source.TrioAlloc2
