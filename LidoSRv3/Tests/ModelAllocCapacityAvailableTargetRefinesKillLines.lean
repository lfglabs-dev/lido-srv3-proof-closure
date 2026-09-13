import LidoSRv3.Audit.Model.AllocCapacity

/-!
Kill-lines pinning `Model.AllocCapacity` `availableCapacity_success`
+ `targetValidators_success` refinement witnesses.
-/

namespace LidoSRv3.Tests.ModelAllocCapacityAvailableTargetRefinesKillLines

open LidoSRv3.Audit.AllocCapacity
open Verity
open Verity.Stdlib.Math

/-! ## `availableCapacity_success` — restated. -/

theorem availableCapacity_success_restated
    (cfg : Config) (isTopUp : Bool) (m : Module)
    (allocation active : Uint256) (hCfg : cfg.maxEBType1 ≠ 0)
    (hAllocation : (allocation : Nat) = MathView.allocationEntry cfg m)
    (hActive : (active : Nat) = MathView.activeCount m)
    (hBound : if isTopUp && m.isType2 then
      MathView.activeCount m * (cfg.maxEBType2 : Nat) ≤ MAX_UINT256
    else MathView.allocationEntry cfg m + (m.depositableCount : Nat) ≤ MAX_UINT256) :
    ∃ available,
      availableCapacity? cfg isTopUp m allocation active = some available ∧
      (available : Nat) = MathView.availableCapacity cfg isTopUp m :=
  availableCapacity_success cfg isTopUp m allocation active hCfg hAllocation
    hActive hBound

/-! ## `targetValidators_success` — restated. -/

theorem targetValidators_success_restated
    {cfg : Config} {modules : List Module} {deposits : Uint256}
    (total : Uint256) (m : Module)
    (hTotal : (total : Nat) = MathView.totalValidators cfg modules deposits)
    (hBound : (m.shareLimit : Nat) *
      MathView.totalValidators cfg modules deposits ≤ MAX_UINT256) :
    ∃ target, targetValidators? total m = some target ∧
      (target : Nat) = MathView.targetValidators cfg modules deposits m :=
  targetValidators_success total m hTotal hBound

end LidoSRv3.Tests.ModelAllocCapacityAvailableTargetRefinesKillLines
