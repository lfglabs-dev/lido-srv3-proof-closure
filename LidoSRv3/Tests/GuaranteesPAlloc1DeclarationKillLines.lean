import LidoSRv3.Audit.Guarantees.PAlloc1

/-!
Kill-lines pinning the P-ALLOC-1 guarantee declaration and its
`active_capacity_bounded` retired-conjunct passthrough.
-/

namespace LidoSRv3.Tests.GuaranteesPAlloc1DeclarationKillLines

open LidoSRv3.Audit.Guarantees.PAlloc1
open LidoSRv3.Audit.Guarantees

/-! ## Guarantee-plane declaration -/

theorem guarantee_id : guarantee.id = Id.pAlloc1 := rfl

theorem guarantee_checkedLayers :
    guarantee.checkedLayers =
      [CheckedLayer.model, CheckedLayer.source, CheckedLayer.verityTx] := rfl

/-! ## The retired Wave-1 `active_capacity_bounded` conjunct

    The parent theorem is now unregistered but retained. This kill-line
    passthrough guarantees that the passthrough matches the model-plane
    `AllocCapacity.active_capacity_bounded`. -/

theorem active_capacity_bounded_restated
    (cfg : LidoSRv3.Audit.AllocCapacity.Config)
    (modules : List LidoSRv3.Audit.AllocCapacity.Module)
    (depositsToAllocate : Verity.Uint256)
    (isTopUp : Bool) (module : LidoSRv3.Audit.AllocCapacity.Module)
    (hActive : module.isActive = true) :
    LidoSRv3.Audit.AllocCapacity.MathView.capacity cfg modules
        depositsToAllocate isTopUp module ≤
      LidoSRv3.Audit.AllocCapacity.MathView.targetValidators cfg modules
        depositsToAllocate module ∧
    LidoSRv3.Audit.AllocCapacity.MathView.capacity cfg modules
        depositsToAllocate isTopUp module ≤
      LidoSRv3.Audit.AllocCapacity.MathView.availableCapacity cfg isTopUp module :=
  active_capacity_bounded cfg modules depositsToAllocate isTopUp module hActive

/-! ## The registered Wave-2 parent `source_capacities_match_canonical`. -/

theorem source_capacities_match_canonical_restated
    (cfg : LidoSRv3.Audit.AllocCapacity.Config)
    (modules : List LidoSRv3.Audit.AllocCapacity.Module)
    (depositsToAllocate : Verity.Uint256)
    (isTopUp : Bool)
    (hBounds : LidoSRv3.Audit.AllocCapacity.CheckedBounds cfg modules
      depositsToAllocate isTopUp) :
    ∃ rows,
      LidoSRv3.Audit.SolidityAllocCapacity.execute cfg modules
          depositsToAllocate isTopUp = some rows ∧
      rows.map (fun row => (row.capacity : Nat)) =
        LidoSRv3.Audit.AllocCapacity.MathView.capacities cfg modules
          depositsToAllocate isTopUp :=
  source_capacities_match_canonical cfg modules depositsToAllocate isTopUp hBounds

end LidoSRv3.Tests.GuaranteesPAlloc1DeclarationKillLines
