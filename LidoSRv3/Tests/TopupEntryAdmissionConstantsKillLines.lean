import LidoSRv3.Audit.Source.TopupEntryAdmission

/-! # Kill-lines for `TopupEntryAdmission` role/access/resume slot constants

**Chantier 1 (Piste A, Thomas 2026-09-13) mutant kill-lines pinning
the physical TopUpGateway onlyRole/whenResumed pinned slot
constants against source-model mutations.** -/

namespace LidoSRv3.Tests.TopupEntryAdmissionConstantsKillLines

open LidoSRv3.Audit.Source.TopupEntryAdmission

/-- **Kill-line: TopUpGateway TOP_UP_ROLE constant.**

Pinned OZ5.2 role hash keccak256("TOP_UP_ROLE"). A mutant that
changed a single hex digit would refute this. -/
theorem role_pinned :
    role = 0x5e4bd437d29fad01c10cdcfff414f0d6b0e84b96d2dade88d780d45b5630696b :=
  rfl

/-- **Kill-line: TopUpGateway ERC-7201 access-control storage slot.** -/
theorem accessSlot_pinned :
    accessSlot = 0x02dd7bc7dec4dceedda775e58dd541e08a116c6c53815c0bd028192f7b626800 :=
  rfl

/-- **Kill-line: TopUpGateway ERC-7201 pause/resume storage slot.** -/
theorem resumeSlot_pinned :
    resumeSlot = 0xe8b012900cb200ee5dfc3b895a32791b67d12891b09f117814f167a237783a02 :=
  rfl

/-- **Kill-line: all three constants fit uint256.**

A mutant that overflowed the 256-bit slot space would refute. -/
theorem role_fits_uint256 : role < 2 ^ 256 := by decide
theorem accessSlot_fits_uint256 : accessSlot < 2 ^ 256 := by decide
theorem resumeSlot_fits_uint256 : resumeSlot < 2 ^ 256 := by decide

/-- **Kill-line: all three constants are distinct.**

A mutant that collapsed two ERC-7201 slots to the same value would
refute this separation. -/
theorem role_ne_accessSlot : role ≠ accessSlot := by decide
theorem role_ne_resumeSlot : role ≠ resumeSlot := by decide
theorem accessSlot_ne_resumeSlot : accessSlot ≠ resumeSlot := by decide

#print axioms role_pinned
#print axioms accessSlot_pinned
#print axioms resumeSlot_pinned
#print axioms role_fits_uint256
#print axioms role_ne_accessSlot

end LidoSRv3.Tests.TopupEntryAdmissionConstantsKillLines
