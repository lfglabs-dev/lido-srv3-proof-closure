import LidoSRv3.Legacy.Model
import LidoSRv3.Audit.Model.AllocCapacity

/-!
Temporary machine-checked regression bridge. This module is intentionally not
imported by the public P-ALLOC-1 facade.
-/

namespace LidoSRv3.Audit.Regression.AllocCapacityLegacy

open Verity
open LidoSRv3.Audit.AllocCapacity

/-- Explicit representation assumptions between the former broad Legacy row
and the narrow canonical source row. Intermediate equalities expose, rather
than hide, the legacy representation's collapsed exited-count field. -/
structure ModuleAgrees (oldCfg : LidoSRv3.AllocationConfig)
    (newCfg : Config) (old : LidoSRv3.Module) (new : AllocCapacity.Module) : Prop where
  id : (new.moduleId : Nat) = old.id
  active : new.isActive = decide (old.status = LidoSRv3.ModuleStatus.active)
  share : (new.shareLimit : Nat) = old.stakeShareLimitBps
  current : MathView.allocationEntry newCfg new =
    LidoSRv3.moduleCurrentAllocationEquivalent oldCfg old
  activeCount : MathView.activeCount new = LidoSRv3.moduleActiveValidators old
  available : ∀ isTopUp, MathView.availableCapacity newCfg isTopUp new =
    LidoSRv3.moduleAvailableCapacityEquivalent oldCfg isTopUp old

/-- Router-order representation agreement. -/
def RowsAgree (oldCfg : LidoSRv3.AllocationConfig) (newCfg : Config) :
    List LidoSRv3.Module → List AllocCapacity.Module → Prop
  | [], [] => True
  | old :: olds, new :: news =>
      ModuleAgrees oldCfg newCfg old new ∧ RowsAgree oldCfg newCfg olds news
  | _, _ => False

theorem sum_current_agrees {oldCfg : LidoSRv3.AllocationConfig} {newCfg : Config} :
    ∀ {olds : List LidoSRv3.Module} {news : List AllocCapacity.Module}, RowsAgree oldCfg newCfg olds news →
      (news.map (MathView.allocationEntry newCfg)).sum =
        (olds.map (LidoSRv3.moduleCurrentAllocationEquivalent oldCfg)).sum := by
  intro olds
  induction olds with
  | nil =>
      intro news h
      cases news <;> simp_all [RowsAgree]
  | cons old olds ih =>
      intro news h
      cases news with
      | nil => simp [RowsAgree] at h
      | cons new news =>
          simp only [List.map_cons, List.sum_cons]
          rw [h.1.current, ih h.2]

/-- The former Legacy capacity column agrees with the canonical mathematical
view under explicit row representation assumptions. This preserves regression
continuity while keeping Legacy out of the public dependency graph. -/
theorem map_capacity_agrees {oldCfg : LidoSRv3.AllocationConfig} {newCfg : Config}
    {fullOlds : List LidoSRv3.Module} {fullNews : List AllocCapacity.Module}
    {deposits : Uint256} {isTopUp : Bool}
    (hTotal : MathView.totalValidators newCfg fullNews deposits =
      LidoSRv3.allocationTotalValidators oldCfg fullOlds (deposits : Nat)) :
    ∀ {olds : List LidoSRv3.Module} {news : List AllocCapacity.Module},
      RowsAgree oldCfg newCfg olds news →
      (olds.map (LidoSRv3.allocationCapacityRow oldCfg fullOlds
        (deposits : Nat) isTopUp)).map LidoSRv3.AllocationCapacityRow.capacity =
        news.map (MathView.capacity newCfg fullNews deposits isTopUp) := by
  intro olds
  induction olds with
  | nil =>
      intro news hRows
      cases news <;> simp_all [RowsAgree]
  | cons old olds ih =>
      intro news hRows
      cases news with
      | nil => simp [RowsAgree] at hRows
      | cons new news =>
          simp only [List.map_cons, List.cons.injEq]
          constructor
          · unfold LidoSRv3.allocationCapacityRow MathView.capacity
            rw [hRows.1.active]
            by_cases hActive : old.status = LidoSRv3.ModuleStatus.active
            · simp [hActive, hRows.1.available, LidoSRv3.moduleTargetValidators,
                MathView.targetValidators, hRows.1.share, hTotal, LidoSRv3.bpsDenominator]
            · simp [hActive, hRows.1.current]
          · exact ih hRows.2

theorem legacy_capacities_eq_canonical {oldCfg : LidoSRv3.AllocationConfig}
    {newCfg : Config} {olds : List LidoSRv3.Module} {news : List AllocCapacity.Module}
    (deposits : Uint256) (isTopUp : Bool)
    (_hBounds : CheckedBounds newCfg news deposits isTopUp)
    (hRows : RowsAgree oldCfg newCfg olds news) :
    LidoSRv3.allocatedCapacityValues
        (LidoSRv3.modulesAllocationAndCapacity oldCfg olds (deposits : Nat) isTopUp) =
      MathView.capacities newCfg news deposits isTopUp := by
  have hTotal : MathView.totalValidators newCfg news deposits =
      LidoSRv3.allocationTotalValidators oldCfg olds (deposits : Nat) := by
    simp only [MathView.totalValidators, LidoSRv3.allocationTotalValidators]
    rw [sum_current_agrees hRows]
    omega
  exact map_capacity_agrees hTotal hRows

end LidoSRv3.Audit.Regression.AllocCapacityLegacy
