import LidoSRv3.Audit.Source.TrioReserve1.Kernel

/-! # Kill-lines for `TrioReserve1.Kernel` Aragon app-namespace + ACL app-id

**Chantier 2 (Piste A, Thomas 2026-09-13) mutant kill-lines pinning
the two pinned Aragon Kernel constants used by the executable Lido
0.4.24 reserve path: KernelStorage.apps app namespace and ACL app id. -/

namespace LidoSRv3.Tests.TrioReserve1KernelConstantsKillLines

open LidoSRv3.Audit.Source.TrioReserve1.Kernel

/-- **Kill-line: pinned Aragon Kernel `apps` namespace.**

`keccak256("apps")` = 0xd6f028...02fb. A mutant that changed a
single hex digit would refute the pinned Aragon Kernel semantics. -/
theorem appNamespace_pinned :
    appNamespace =
      0xd6f028ca0e8edb4a8c9757ca4fdccab25fa1e0317da1188108f7d2dee14902fb :=
  rfl

/-- **Kill-line: pinned ACL app-id.**

`keccak256("aragonpm.eth:acl.aragonpm.eth")` = 0xe32623...ad6a. -/
theorem aclAppId_pinned :
    aclAppId =
      0xe3262375f45a6e2026b7e7b18c2b807434f2508fe1a2a3dfb493c7df8f4aad6a :=
  rfl

/-- **Kill-line: both constants fit uint256.** -/
theorem appNamespace_fits_uint256 : appNamespace < 2 ^ 256 := by decide
theorem aclAppId_fits_uint256 : aclAppId < 2 ^ 256 := by decide

/-- **Kill-line: both constants are non-zero.** -/
theorem appNamespace_nonzero : appNamespace ≠ 0 := by decide
theorem aclAppId_nonzero : aclAppId ≠ 0 := by decide

/-- **Kill-line: `appNamespace ≠ aclAppId`.**

A mutant that collapsed the two Aragon Kernel identifiers would
refute their pinned semantic distinction. -/
theorem appNamespace_ne_aclAppId :
    appNamespace ≠ aclAppId := by decide

#print axioms appNamespace_pinned
#print axioms aclAppId_pinned
#print axioms appNamespace_ne_aclAppId

end LidoSRv3.Tests.TrioReserve1KernelConstantsKillLines
