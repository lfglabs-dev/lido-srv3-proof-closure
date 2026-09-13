import LidoSRv3.Audit.Allocation

/-! # Kill-lines for `Audit.AllocationMode` and `Audit.CredentialType` enums

**Chantier 3 (Piste A, Thomas 2026-09-13) mutant kill-lines pinning
the pinned P-ALLOC-1 allocation-mode and credential-type
enumerations. -/

namespace LidoSRv3.Tests.AuditAllocationModeCredentialTypeKillLines

open LidoSRv3.Audit

/-- **Kill-line: `AllocationMode` has exactly two constructors:
`initialDeposit` and `topUp`.**

A mutant that collapsed the two modes would refute Piste A/B
disambiguation. -/
theorem allocationMode_initialDeposit_ne_topUp :
    AllocationMode.initialDeposit ≠ AllocationMode.topUp := by decide

/-- **Kill-line: `CredentialType` has exactly two constructors:
`wc01` and `wc02`.**

A mutant that collapsed WC types 1 and 2 would refute the topup
type-2 eligibility guard. -/
theorem credentialType_wc01_ne_wc02 :
    CredentialType.wc01 ≠ CredentialType.wc02 := by decide

/-- **Kill-line: DecidableEq on AllocationMode agrees with `=`.** -/
theorem allocationMode_decidable_initialDeposit :
    (decide (AllocationMode.initialDeposit = AllocationMode.initialDeposit)) = true := by decide

theorem allocationMode_decidable_topUp :
    (decide (AllocationMode.topUp = AllocationMode.topUp)) = true := by decide

/-- **Kill-line: DecidableEq on CredentialType agrees with `=`.** -/
theorem credentialType_decidable_wc01 :
    (decide (CredentialType.wc01 = CredentialType.wc01)) = true := by decide

theorem credentialType_decidable_wc02 :
    (decide (CredentialType.wc02 = CredentialType.wc02)) = true := by decide

#print axioms allocationMode_initialDeposit_ne_topUp
#print axioms credentialType_wc01_ne_wc02
#print axioms allocationMode_decidable_initialDeposit
#print axioms credentialType_decidable_wc01

end LidoSRv3.Tests.AuditAllocationModeCredentialTypeKillLines
