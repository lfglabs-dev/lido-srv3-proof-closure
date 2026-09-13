import LidoSRv3.Audit.Source.TopupCredentialCall

/-! # Kill-lines for `TopupCredentialCall.selector`

**Chantier 1 (Piste A, Thomas 2026-09-13) mutant kill-lines pinning
the pinned gateway-to-router credentials STATICCALL selector. -/

namespace LidoSRv3.Tests.TopupCredentialCallSelectorKillLines

open LidoSRv3.Audit.Source.TopupCredentialCall

/-- **Kill-line: pinned gateway credentials STATICCALL selector.**

A mutant that changed one hex digit would refute the ABI-derived
pin. -/
theorem selector_pinned :
    selector = 0xf85c6ceb := rfl

/-- **Kill-line: the selector fits uint32 (bytes4).**

A mutant that overflowed the 4-byte ABI selector width would refute. -/
theorem selector_fits_uint32 :
    selector < 2 ^ 32 := by decide

/-- **Kill-line: the selector is non-zero.**

A mutant that zeroed the selector would refute the pinned ABI
signature (Solidity always emits a nonzero first 4 bytes for any
concrete function). -/
theorem selector_nonzero : selector ≠ 0 := by decide

#print axioms selector_pinned
#print axioms selector_fits_uint32
#print axioms selector_nonzero

end LidoSRv3.Tests.TopupCredentialCallSelectorKillLines
