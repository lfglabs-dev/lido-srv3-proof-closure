import LidoSRv3.Audit.Model.AllocCapacity

/-!
Kill-lines pinning `Model.AllocCapacity` `safe*_refines_nat` +
`wordMax_coe`/`wordMin_coe`/`activeCount_success` witness theorems.
-/

namespace LidoSRv3.Tests.ModelAllocCapacitySafeArithKillLines

open LidoSRv3.Audit.AllocCapacity
open Verity
open Verity.Stdlib.Math

/-! ## `safeSub_refines_nat` — success matches Nat subtraction. -/

theorem safeSub_refines_nat_restated
    (a b c : Uint256) (hBound : (b : Nat) ≤ (a : Nat))
    (h : safeSub a b = some c) :
    (c : Nat) = (a : Nat) - (b : Nat) :=
  safeSub_refines_nat a b c hBound h

/-! ## `safeAdd_refines_nat` — success matches Nat addition. -/

theorem safeAdd_refines_nat_restated
    (a b c : Uint256)
    (hBound : (a : Nat) + (b : Nat) ≤ Verity.Stdlib.Math.MAX_UINT256)
    (h : safeAdd a b = some c) :
    (c : Nat) = (a : Nat) + (b : Nat) :=
  safeAdd_refines_nat a b c hBound h

/-! ## `safeMul_refines_nat` — success matches Nat multiplication. -/

theorem safeMul_refines_nat_restated
    (a b c : Uint256)
    (hBound : (a : Nat) * (b : Nat) ≤ Verity.Stdlib.Math.MAX_UINT256)
    (h : safeMul a b = some c) :
    (c : Nat) = (a : Nat) * (b : Nat) :=
  safeMul_refines_nat a b c hBound h

/-! ## `safeDiv_refines_nat` — success matches truncating Nat division. -/

theorem safeDiv_refines_nat_restated
    (a b c : Uint256) (hNonzero : b ≠ 0)
    (h : safeDiv a b = some c) :
    (c : Nat) = (a : Nat) / (b : Nat) :=
  safeDiv_refines_nat a b c hNonzero h

/-! ## `wordMax_coe` — Uint256 max matches Nat max. -/

theorem wordMax_coe_restated (a b : Uint256) :
    (wordMax a b : Nat) = max (a : Nat) (b : Nat) :=
  wordMax_coe a b

/-! ## `wordMin_coe` — Uint256 min matches Nat min. -/

theorem wordMin_coe_restated (a b : Uint256) :
    (wordMin a b : Nat) = min (a : Nat) (b : Nat) :=
  wordMin_coe a b

/-! ## `activeCount_success` — restated. -/

theorem activeCount_success_restated
    (m : Module)
    (h : (wordMax m.summaryExitedCount m.accountingExitedCount : Nat) ≤
      (m.depositedCount : Nat)) :
    ∃ active,
      activeCount? m = some active ∧
      (active : Nat) = MathView.activeCount m :=
  activeCount_success m h

end LidoSRv3.Tests.ModelAllocCapacitySafeArithKillLines
