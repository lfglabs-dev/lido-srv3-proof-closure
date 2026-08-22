import LidoSRv3.Audit.Spec
import LidoSRv3.Audit.Spec.AllocationCorrespondence
import LidoSRv3.Audit.Model.AllocCapacity
import LidoSRv3.Audit.Source.AllocCapacityCorrespondence
import LidoSRv3.Audit.Guarantees.PAlloc1
import LidoSRv3.Audit.Guarantees.PDeposit1
import LidoSRv3.Audit.Verity.DepositParentTx

/-!
# Pack A fail-closed vectors

Unregistered Spec.Allocation children. These mutants do not replace the
registered ALLOC / DEPOSIT parents. The first substitutes `targetValidators`
for `capacity` in the ALLOC-1 projection. The second restates ALLOC ↛
`LinksSource` on validator-count Spec amounts.
-/

namespace LidoSRv3.Tests.PackAAllocSpecMutants

open Verity
open LidoSRv3.Audit.AllocCapacity
open LidoSRv3.Audit.Spec
open LidoSRv3.Audit.Spec.AllocationCorrespondence
open LidoSRv3.Audit.Guarantees
open LidoSRv3.Audit.Verity.DepositParentTx

private def w (n : Nat) : Verity.Core.Uint256 := Verity.Core.Uint256.ofNat n

private def cfg : Config := ⟨w 32, w 64⟩

/-- Same `CheckedBounds` witness as `AllocationTxMutants.capacity_target_kill_line`. -/
private def killLineModules : List Module :=
  [ { moduleId := w 1, shareLimit := w 8000, isActive := true, isType2 := false
      depositableCount := w 1, depositedCount := w 10
      summaryExitedCount := w 0, accountingExitedCount := w 0
      totalModuleStake := w 0 }
  , { moduleId := w 2, shareLimit := w 8000, isActive := true, isType2 := false
      depositableCount := w 1, depositedCount := w 10
      summaryExitedCount := w 0, accountingExitedCount := w 0
      totalModuleStake := w 0 } ]

/-- Mutant projection: reads `targetValidators` as the Spec capacity column. -/
def specOfAlloc1RowTargetAsCapacity (r : Row) : Allocation where
  moduleId := (r.moduleId : Nat)
  capacity := ⟨(r.targetValidators : Nat)⟩
  amount := ⟨(r.currentAllocation : Nat)⟩

/-- Kill-line for the unregistered ALLOC-1 Spec capacity child. Under
`CheckedBounds` the honest executor commits and its true Spec capacities
match `MathView`. Reading `targetValidators` as capacity yields the raw
share-limit targets `[24, 24]`, not `MathView`'s clamped `[11, 11]`. -/
theorem target_as_capacity_kill_line_refutes_alloc1_spec :
    CheckedBounds cfg killLineModules (w 10) false ∧
      (∃ rows,
        LidoSRv3.Audit.SolidityAllocCapacity.execute cfg killLineModules (w 10) false =
          some rows ∧
          (rows.map specOfAlloc1Row).map (fun a => a.capacity.value) =
            MathView.capacities cfg killLineModules (w 10) false ∧
          (rows.map specOfAlloc1RowTargetAsCapacity).map (fun a => a.capacity.value) ≠
            MathView.capacities cfg killLineModules (w 10) false) := by
  refine ⟨⟨by decide, by decide, by decide, by decide, by decide⟩, ?_⟩
  obtain ⟨rows, hExec, hCap, _hIds⟩ :=
    AllocationCorrespondence.alloc1_spec_capacity_correspondence
      cfg killLineModules (w 10) false
      ⟨by decide, by decide, by decide, by decide, by decide⟩
  refine ⟨rows, hExec, hCap, ?_⟩
  have hMath : MathView.capacities cfg killLineModules (w 10) false = [11, 11] := by
    decide
  have hMut :
      (LidoSRv3.Audit.SolidityAllocCapacity.execute cfg killLineModules (w 10) false).map
        (fun rows => (rows.map specOfAlloc1RowTargetAsCapacity).map
          (fun a => a.capacity.value)) = some [24, 24] := by
    decide
  simp [hExec] at hMut
  simp [hMut, hMath]

/-- Spec-shaped ALLOC ↛ LinksSource: validator-count Spec amounts equal to
the two batch key counts still fail `LinksSource.firstAmount`. -/
theorem spec_amounts_kill_line_refutes_linkssource :
    ¬ (∀ (specRows : List Allocation)
        (cfg : LidoSRv3.Audit.SolidityDeposit.SourceDepositConfig)
        (inp : LidoSRv3.Audit.SolidityDeposit.SourceDepositInput)
        (inputs : Inputs),
          specRows.map (fun a => a.amount.value) =
            [inputs.first.keys.val, inputs.second.keys.val] →
          PDeposit1.LinksSource cfg inp inputs) :=
  AllocationCorrespondence.spec_amounts_do_not_imply_linkssource

end LidoSRv3.Tests.PackAAllocSpecMutants
