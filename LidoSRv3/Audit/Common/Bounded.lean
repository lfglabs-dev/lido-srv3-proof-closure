import LidoSRv3.Audit.Common.Units

namespace LidoSRv3.Audit.Common

/-! Explicit bounds for source-width quantities; no overflow behavior is assumed. -/

structure BoundedAmount (unit : Type) (limit : Nat) where
  amount : Amount unit
  within : amount.value ≤ limit

def BoundedAmount.checkedAdd
    (a b : BoundedAmount unit limit) : Option (BoundedAmount unit limit) :=
  if h : a.amount.value + b.amount.value ≤ limit then
    some ⟨Amount.add a.amount b.amount, h⟩
  else
    none

theorem BoundedAmount.checkedAdd_sound
    {a b : BoundedAmount unit limit} {sum : BoundedAmount unit limit}
    (h : checkedAdd a b = some sum) :
    sum.amount.value = a.amount.value + b.amount.value := by
  simp only [checkedAdd] at h
  split at h
  · cases h
    rfl
  · contradiction

end LidoSRv3.Audit.Common
