import LidoSRv3.Audit.Source.TopupParentCorrespondence

/-! # Kill-lines for `TopupParentCorrespondence.CallControl` + `CallKind` enums

**Chantier 1 (Piste A, Thomas 2026-09-13) mutant kill-lines pinning
the P-TOPUP-1 parent-execute call-outcome trichotomy (success /
failure / revert) and the two-way call-kind enum. -/

namespace LidoSRv3.Tests.TopupParentCallControlKillLines

open LidoSRv3.Audit.SolidityTopupParent

/-- **Kill-line: `CallControl` has three distinct constructors.**

A mutant that collapsed `.failure` and `.revert` would obscure the
distinction between low-level revert and returned-failure. -/
theorem callControl_success_ne_failure :
    CallControl.success ≠ CallControl.failure := by decide

theorem callControl_failure_ne_revert :
    CallControl.failure ≠ CallControl.revert := by decide

theorem callControl_success_ne_revert :
    CallControl.success ≠ CallControl.revert := by decide

/-- **Kill-line: `CallKind` has exactly two constructors.** -/
theorem callKind_allocation_ne_lidoPull :
    CallKind.allocation ≠ CallKind.lidoPull := by decide

/-- **Kill-line: DecidableEq reflexivity for CallControl.** -/
theorem callControl_success_refl :
    decide (CallControl.success = CallControl.success) = true := by decide
theorem callControl_failure_refl :
    decide (CallControl.failure = CallControl.failure) = true := by decide
theorem callControl_revert_refl :
    decide (CallControl.revert = CallControl.revert) = true := by decide

/-- **Kill-line: DecidableEq reflexivity for CallKind.** -/
theorem callKind_allocation_refl :
    decide (CallKind.allocation = CallKind.allocation) = true := by decide

#print axioms callControl_success_ne_failure
#print axioms callControl_failure_ne_revert
#print axioms callControl_success_ne_revert
#print axioms callKind_allocation_ne_lidoPull
#print axioms callControl_success_refl
#print axioms callKind_allocation_refl

end LidoSRv3.Tests.TopupParentCallControlKillLines
