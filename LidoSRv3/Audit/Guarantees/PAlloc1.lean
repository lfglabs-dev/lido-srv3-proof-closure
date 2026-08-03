import LidoSRv3.Audit.Model.AllocCapacity
import LidoSRv3.Audit.Source.AllocCapacityCorrespondence
import LidoSRv3.Audit.Guarantees.Registry

namespace LidoSRv3.Audit.Guarantees.PAlloc1

open Verity
open Verity.Stdlib.Math
open LidoSRv3.Audit.AllocCapacity

def guarantee : Guarantee := ⟨.pAlloc1, [.model, .source]⟩

/-- The canonical active capacity is bounded by both operands of the pinned
`Math.min` clamp. -/
theorem active_capacity_bounded
    (cfg : Config) (modules : List Module) (depositsToAllocate : Uint256)
    (isTopUp : Bool) (module : Module) (hActive : module.isActive = true) :
    MathView.capacity cfg modules depositsToAllocate isTopUp module ≤
        MathView.targetValidators cfg modules depositsToAllocate module ∧
      MathView.capacity cfg modules depositsToAllocate isTopUp module ≤
        MathView.availableCapacity cfg isTopUp module :=
  AllocCapacity.active_capacity_bounded cfg modules depositsToAllocate isTopUp module hActive

/-- The pinned source execution is the canonical checked audit execution. -/
theorem source_capacities_match_canonical
    (cfg : Config) (modules : List Module) (depositsToAllocate : Uint256)
    (isTopUp : Bool) :
    SolidityAllocCapacity.execute cfg modules depositsToAllocate isTopUp =
      AllocCapacity.execute cfg modules depositsToAllocate isTopUp :=
  SolidityAllocCapacity.source_execute_eq_canonical cfg modules depositsToAllocate isTopUp

/-- Successful execution retains router index order. -/
theorem router_order_preserved {cfg : Config} {modules : List Module}
    {depositsToAllocate : Uint256} {isTopUp : Bool} {rows : List Row}
    (h : AllocCapacity.execute cfg modules depositsToAllocate isTopUp = some rows) :
    rows.map Row.moduleId = modules.map Module.moduleId :=
  SolidityAllocCapacity.router_order_preserved h

/-- The checked operations used by canonical execution refine their natural
number meanings exactly at the named Solidity bounds; no unbounded arithmetic
is substituted into execution. -/
theorem checked_uint256_execution_refines_math :
    (∀ a b c : Uint256, (b : Nat) ≤ (a : Nat) → safeSub a b = some c →
      (c : Nat) = (a : Nat) - (b : Nat)) ∧
    (∀ a b c : Uint256, (a : Nat) + (b : Nat) ≤ Verity.Stdlib.Math.MAX_UINT256 →
      safeAdd a b = some c → (c : Nat) = (a : Nat) + (b : Nat)) ∧
    (∀ a b c : Uint256, (a : Nat) * (b : Nat) ≤ Verity.Stdlib.Math.MAX_UINT256 →
      safeMul a b = some c → (c : Nat) = (a : Nat) * (b : Nat)) ∧
    (∀ a b c : Uint256, b ≠ 0 → safeDiv a b = some c →
      (c : Nat) = (a : Nat) / (b : Nat)) := by
  exact ⟨LidoSRv3.Audit.AllocCapacity.safeSub_refines_nat,
    LidoSRv3.Audit.AllocCapacity.safeAdd_refines_nat,
    LidoSRv3.Audit.AllocCapacity.safeMul_refines_nat,
    LidoSRv3.Audit.AllocCapacity.safeDiv_refines_nat⟩

end LidoSRv3.Audit.Guarantees.PAlloc1
