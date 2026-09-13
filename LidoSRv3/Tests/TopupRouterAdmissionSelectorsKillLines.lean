import LidoSRv3.Audit.Source.TopupRouterAdmissionCallGates

/-! # Kill-lines for `TopupRouterAdmissionCallGates` selectors

**Chantier 1 (Piste A, Thomas 2026-09-13) mutant kill-lines pinning
the pinned post-root/pre-module STATICCALL selectors used at the
StakingRouter.topUp admission seam. -/

namespace LidoSRv3.Tests.TopupRouterAdmissionSelectorsKillLines

open LidoSRv3.Audit.Source.TopupRouterAdmissionCallGates

/-- **Kill-line: pinned Lido `authorizedRouter()` STATICCALL selector.**

Bytes4(keccak256("authorizedRouter()")) = 0x644862de. -/
theorem authSelector_pinned :
    authSelector = 0x644862de := rfl

/-- **Kill-line: pinned Lido `canDeposit()` STATICCALL selector.**

Bytes4(keccak256("canDeposit()")) = 0xe78a5875. -/
theorem canDepositSelector_pinned :
    canDepositSelector = 0xe78a5875 := rfl

/-- **Kill-line: both selectors fit uint32 (bytes4).**

A mutant overflowing the 4-byte ABI selector width would refute. -/
theorem authSelector_fits_uint32 : authSelector < 2 ^ 32 := by decide
theorem canDepositSelector_fits_uint32 : canDepositSelector < 2 ^ 32 := by decide

/-- **Kill-line: both selectors are non-zero and distinct.**

A mutant that collapsed the two selectors or zeroed either would
refute the ABI-derived pins. -/
theorem authSelector_nonzero : authSelector ≠ 0 := by decide
theorem canDepositSelector_nonzero : canDepositSelector ≠ 0 := by decide
theorem selectors_distinct : authSelector ≠ canDepositSelector := by decide

#print axioms authSelector_pinned
#print axioms canDepositSelector_pinned
#print axioms authSelector_fits_uint32
#print axioms selectors_distinct

end LidoSRv3.Tests.TopupRouterAdmissionSelectorsKillLines
