import LidoSRv3.Audit.Model.AllocCapacity

/-!
Kill-lines pinning `Model.AllocCapacity` `ceilDiv_coe`,
`allocationEntry_success`, and `firstLoop_refines` refinement
witnesses (SRLib.sol:509-532).
-/

namespace LidoSRv3.Tests.ModelAllocCapacityFirstLoopRefinesKillLines

open LidoSRv3.Audit.AllocCapacity
open Verity
open Verity.Stdlib.Math

/-! ## `ceilDiv_coe` — restated. -/

theorem ceilDiv_coe_restated (a b : Uint256) (hB : b ≠ 0) :
    (ceilDiv a b : Nat) = ((a : Nat) + (b : Nat) - 1) / (b : Nat) :=
  ceilDiv_coe a b hB

/-! ## `allocationEntry_success` — restated. -/

theorem allocationEntry_success_restated
    (cfg : Config) (m : Module)
    (hCfg : cfg.maxEBType1 ≠ 0)
    (hSub : (wordMax m.summaryExitedCount m.accountingExitedCount : Nat) ≤
      (m.depositedCount : Nat)) :
    ∃ entry, allocationEntry? cfg m = some entry ∧
      (entry.1 : Nat) = MathView.allocationEntry cfg m ∧
      (entry.2 : Nat) = MathView.activeCount m :=
  allocationEntry_success cfg m hCfg hSub

/-! ## `firstLoop_refines` — restated. -/

theorem firstLoop_refines_restated
    (cfg : Config) (modules : List Module) (start : Uint256)
    (hCfg : cfg.maxEBType1 ≠ 0)
    (hSub : ∀ m ∈ modules,
      (wordMax m.summaryExitedCount m.accountingExitedCount : Nat) ≤
        (m.depositedCount : Nat))
    (hTotal : (start : Nat) + (modules.map (MathView.allocationEntry cfg)).sum ≤
      MAX_UINT256) :
    ∃ entries total, firstLoop cfg modules start = some (entries, total) ∧
      entries.map (fun e => (e.1 : Nat)) =
        modules.map (MathView.allocationEntry cfg) ∧
      entries.map (fun e => (e.2 : Nat)) = modules.map MathView.activeCount ∧
      (total : Nat) = (start : Nat) +
        (modules.map (MathView.allocationEntry cfg)).sum :=
  firstLoop_refines cfg modules start hCfg hSub hTotal

end LidoSRv3.Tests.ModelAllocCapacityFirstLoopRefinesKillLines
