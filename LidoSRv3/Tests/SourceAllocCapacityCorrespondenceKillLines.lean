import LidoSRv3.Audit.Source.AllocCapacityCorrespondence

/-!
Kill-lines pinning `Source.AllocCapacityCorrespondence` executable
API + two named correspondence theorems (independent-model refinement
and router-order preservation).
-/

namespace LidoSRv3.Tests.SourceAllocCapacityCorrespondenceKillLines

open LidoSRv3.Audit.SolidityAllocCapacity
open LidoSRv3.Audit.AllocCapacity

/-! ## `execute` is the model executor, exposed under the SolidityAllocCapacity
    namespace. -/

theorem execute_is_model_executor :
    @LidoSRv3.Audit.SolidityAllocCapacity.execute =
      @LidoSRv3.Audit.AllocCapacity.execute := rfl

theorem _getModulesAllocationAndCapacity_alias :
    @LidoSRv3.Audit.SolidityAllocCapacity._getModulesAllocationAndCapacity =
      @LidoSRv3.Audit.SolidityAllocCapacity.execute := rfl

/-! ## `source_execute_refines_audit_model` — restated. -/

theorem source_execute_refines_audit_model_restated
    (cfg : SourceConfig) (modules : List SourceModule)
    (depositsToAllocate : Verity.Uint256) (isTopUp : Bool)
    (hBounds : CheckedBounds cfg modules depositsToAllocate isTopUp) :
    ∃ rows,
      LidoSRv3.Audit.SolidityAllocCapacity.execute cfg modules
        depositsToAllocate isTopUp = some rows ∧
      rows.map (fun row => (row.capacity : Nat)) =
        MathView.capacities cfg modules depositsToAllocate isTopUp :=
  source_execute_refines_audit_model cfg modules depositsToAllocate isTopUp hBounds

/-! ## `router_order_preserved` — restated. -/

theorem router_order_preserved_restated
    {cfg : SourceConfig} {modules : List SourceModule}
    {depositsToAllocate : Verity.Uint256} {isTopUp : Bool}
    {rows : List Row}
    (h : LidoSRv3.Audit.SolidityAllocCapacity.execute cfg modules
      depositsToAllocate isTopUp = some rows) :
    rows.map Row.moduleId = modules.map Module.moduleId :=
  router_order_preserved h

/-! ## `execute` on empty modules is a definitional identity. -/

private def cfg0 : Config := { maxEBType1 := 32, maxEBType2 := 2048 }

theorem execute_empty_source :
    LidoSRv3.Audit.SolidityAllocCapacity.execute cfg0 [] 0 false =
      some [] := by decide

theorem execute_empty_source_topup :
    LidoSRv3.Audit.SolidityAllocCapacity.execute cfg0 [] 0 true =
      some [] := by decide

end LidoSRv3.Tests.SourceAllocCapacityCorrespondenceKillLines
