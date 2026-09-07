import LidoSRv3.Audit.Source.TrioAlloc2.Step

/-!
Pinned source: lidofinance/core@17005714f151e5502c559932319a3f2f74ac2436,
contracts/common/lib/MinFirstAllocationStrategy.sol:30–44.
The actual while loop: checked remainder, candidate step, zero-amount break,
checked accumulated amount, repeat. No artificial fuel or exhaustion outcome.
Termination uses the finite word distance above the accumulated amount. A
successful checked addition of a nonzero amount strictly decreases that distance,
even before proving the stronger requested-demand bound.
-/
namespace LidoSRv3.Audit.Source.TrioAlloc2

def allocateLoop (buckets capacities : List Word) (demand allocated : Word) :
    Result StepOutput :=
  if allocated.val < demand.val then
    match checkedSub demand allocated with
    | .error error => .error error
    | .ok remaining =>
      match step buckets capacities remaining with
      | .error error => .error error
      | .ok result =>
        if result.amount.val = 0 then .ok ⟨allocated, result.buckets⟩
        else
          match _hadd : checkedAdd allocated result.amount with
          | .error error => .error error
          | .ok total => allocateLoop result.buckets capacities demand total
  else .ok ⟨allocated, buckets⟩
termination_by 2 ^ 256 - allocated.val
decreasing_by
  have value := checkedAdd_value allocated result.amount total _hadd
  have := total.isLt
  omega

def allocate (buckets capacities : List Word) (demand : Word) : Result StepOutput :=
  allocateLoop buckets capacities demand zero

theorem allocateLoop_done (buckets capacities : List Word) (demand allocated : Word)
    (h : demand.val ≤ allocated.val) :
    allocateLoop buckets capacities demand allocated = .ok ⟨allocated, buckets⟩ := by
  rw [allocateLoop]
  simp only [show ¬ allocated.val < demand.val by omega, ↓reduceIte]

theorem allocate_zero_demand (buckets capacities : List Word) :
    allocate buckets capacities zero = .ok ⟨zero, buckets⟩ := by
  exact allocateLoop_done buckets capacities zero zero (Nat.le_refl _)

end LidoSRv3.Audit.Source.TrioAlloc2
