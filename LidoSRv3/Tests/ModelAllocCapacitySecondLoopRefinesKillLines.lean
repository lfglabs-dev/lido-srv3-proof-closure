import LidoSRv3.Audit.Model.AllocCapacity

/-!
Kill-lines pinning `Model.AllocCapacity` `targetValidators_success`,
`secondLoop_refines`, `execute_refines_math`, and
`secondLoop_router_order` witnesses.
-/

namespace LidoSRv3.Tests.ModelAllocCapacitySecondLoopRefinesKillLines

open LidoSRv3.Audit.AllocCapacity
open Verity
open Verity.Stdlib.Math

/-! ## `execute_refines_math` — restated (Wave-2 registered parent). -/

theorem execute_refines_math_restated
    (cfg : Config) (modules : List Module)
    (deposits : Uint256) (isTopUp : Bool)
    (hBounds : CheckedBounds cfg modules deposits isTopUp) :
    ∃ rows, execute cfg modules deposits isTopUp = some rows ∧
      rows.map (fun r => (r.capacity : Nat)) =
        MathView.capacities cfg modules deposits isTopUp :=
  execute_refines_math cfg modules deposits isTopUp hBounds

/-! ## `active_capacity_bounded` — restated (retired Wave-1 conjunct). -/

theorem active_capacity_bounded_restated
    (cfg : Config) (modules : List Module)
    (deposits : Uint256) (isTopUp : Bool)
    (m : Module) (hActive : m.isActive = true) :
    MathView.capacity cfg modules deposits isTopUp m ≤
        MathView.targetValidators cfg modules deposits m ∧
      MathView.capacity cfg modules deposits isTopUp m ≤
        MathView.availableCapacity cfg isTopUp m :=
  active_capacity_bounded cfg modules deposits isTopUp m hActive

/-! ## `secondLoop_router_order` — restated. -/

theorem secondLoop_router_order_restated
    {cfg : Config} {isTopUp : Bool} {total : Uint256}
    {modules : List Module} {entries : List (Uint256 × Uint256)}
    {rows : List Row}
    (h : secondLoop cfg isTopUp total modules entries = some rows) :
    rows.map Row.moduleId = modules.map Module.moduleId :=
  secondLoop_router_order h

end LidoSRv3.Tests.ModelAllocCapacitySecondLoopRefinesKillLines
