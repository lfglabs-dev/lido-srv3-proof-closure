import LidoSRv3.Audit.Source.TrioReserve1.ACL

/-! # Kill-lines for `TrioReserve1.ACL` empty-params sentinel + any-entity

**Chantier 2 (Piste A, Thomas 2026-09-13) mutant kill-lines pinning
the pinned Aragon ACL constants used by the executable Lido 0.4.24
reserve path: `emptyParams` sentinel and `anyEntity` sentinel. -/

namespace LidoSRv3.Tests.TrioReserve1AclConstantsKillLines

open LidoSRv3.Audit.Source.TrioReserve1.ACL

/-- **Kill-line: pinned Aragon ACL `emptyParams` sentinel.**

`keccak256("") = 0x29...e563` (the empty-string keccak). Aragon ACL
uses this as the "no params" sentinel. A mutant that changed a
single hex digit would refute the pinned Aragon ACL semantics. -/
theorem emptyParams_pinned :
    emptyParams =
      0x290decd9548b62a8d60345a988386fc84ba6bc95484008f6362f93160ef3e563 :=
  rfl

/-- **Kill-line: `anyEntity` = uint160 max (all bits set).**

Aragon ACL's ANY_ENTITY sentinel is `address(uint160(-1))` = 2^160 - 1. -/
theorem anyEntity_pinned :
    anyEntity.toNat = 2 ^ 160 - 1 := by decide

/-- **Kill-line: `emptyParams` fits uint256.** -/
theorem emptyParams_fits_uint256 :
    emptyParams < 2 ^ 256 := by decide

/-- **Kill-line: `anyEntity` fits uint160.** -/
theorem anyEntity_fits_uint160 :
    anyEntity.toNat < 2 ^ 160 := by decide

/-- **Kill-line: `emptyParams` is non-zero.**

The empty-string keccak is not zero. -/
theorem emptyParams_nonzero : emptyParams ≠ 0 := by decide

/-- **Kill-line: `anyEntity` is non-zero.**

The uint160-max sentinel is not zero. -/
theorem anyEntity_nonzero : anyEntity.toNat ≠ 0 := by decide

/-- **Kill-line: anyEntity ≠ emptyParams as Nat.**

A mutant that collapsed the two sentinels would refute. -/
theorem anyEntity_ne_emptyParams :
    anyEntity.toNat ≠ emptyParams := by decide

#print axioms emptyParams_pinned
#print axioms anyEntity_pinned
#print axioms emptyParams_fits_uint256
#print axioms anyEntity_fits_uint160
#print axioms emptyParams_nonzero
#print axioms anyEntity_nonzero
#print axioms anyEntity_ne_emptyParams

end LidoSRv3.Tests.TrioReserve1AclConstantsKillLines
