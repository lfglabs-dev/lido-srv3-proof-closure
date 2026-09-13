import LidoSRv3.Audit.Source.TrioAlloc1.ProxyGenesis

/-! # Kill-lines for `TrioAlloc1.ProxyGenesis.implementationSlot`

**Chantier 3 (Piste A, Thomas 2026-09-13) mutant kill-lines pinning
the pinned OZ ERC1967Upgrade._IMPLEMENTATION_SLOT constant used
by OssifiableProxy at genesis. -/

namespace LidoSRv3.Tests.TrioAlloc1ProxyGenesisSlotKillLines

open LidoSRv3.Audit.Source.TrioAlloc1
open LidoSRv3.Audit.Source.TrioAlloc1.ProxyGenesis

/-- **Kill-line: pinned OZ ERC1967 _IMPLEMENTATION_SLOT constant.**

`keccak256("eip1967.proxy.implementation") - 1` =
0x360894...382bbc. -/
theorem implementationSlot_pinned :
    implementationSlot =
      word 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc :=
  rfl

/-- **Kill-line: implementationSlot fits uint256.** -/
theorem implementationSlot_fits_uint256 :
    implementationSlot.val < 2 ^ 256 := implementationSlot.isLt

/-- **Kill-line: implementationSlot is non-zero.** -/
theorem implementationSlot_nonzero :
    implementationSlot.val ≠ 0 := by decide

/-- **Kill-line: fresh storage returns zero for every slot.** -/
theorem fresh_returns_zero (slot : Word) : fresh slot = 0 := rfl

/-- **Kill-line: `beforeDelegatecall implementation implementationSlot =
word implementation.val`.**

A mutant that stored the address at a different slot would refute. -/
theorem implementation_stored_kill (implementation : Address) :
    beforeDelegatecall implementation implementationSlot =
      word implementation.val :=
  implementation_stored implementation

/-- **Kill-line: on any distinct slot, `beforeDelegatecall` returns 0.** -/
theorem other_slot_zero_kill (implementation : Address) (target : Word)
    (separate : target ≠ implementationSlot) :
    beforeDelegatecall implementation target = 0 :=
  other_slot_zero implementation target separate

#print axioms implementationSlot_pinned
#print axioms implementationSlot_nonzero
#print axioms fresh_returns_zero
#print axioms implementation_stored_kill
#print axioms other_slot_zero_kill

end LidoSRv3.Tests.TrioAlloc1ProxyGenesisSlotKillLines
