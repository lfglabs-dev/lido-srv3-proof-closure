import LidoSRv3.Audit.Verity.AllocCapacity

/-! # Kill-lines for `Verity.AllocCapacity.selector` and spec identity

**Chantier 3 (Piste A, Thomas 2026-09-13) mutant kill-lines pinning
the compilation-model entry selector and identity for the Lido
alloc-capacity one-module compiled program. -/

namespace LidoSRv3.Tests.VerityAllocCapacitySelectorKillLines

open LidoSRv3.Audit.Verity.AllocCapacity

/-- **Kill-line: pinned entry selector for the one-module capacity
program.**

`bytes4(keccak256("oneModule(uint256,uint256,uint256,bool)"))` = 0x6a70ca01. -/
theorem selector_pinned :
    selector = 0x6a70ca01 := rfl

/-- **Kill-line: selector fits uint32.** -/
theorem selector_fits_uint32 :
    selector < 2 ^ 32 := by decide

/-- **Kill-line: selector is non-zero.** -/
theorem selector_nonzero :
    selector ≠ 0 := by decide

/-- **Kill-line: spec name is "LidoAllocCapacityOneModule".**

A mutant that renamed the compilation unit would refute. -/
theorem spec_name : spec.name = "LidoAllocCapacityOneModule" := rfl

/-- **Kill-line: spec has no storage fields.** -/
theorem spec_no_fields : spec.fields = [] := rfl

/-- **Kill-line: spec has no constructor.** -/
theorem spec_no_constructor : spec.constructor = none := rfl

/-- **Kill-line: spec has exactly one function (`oneModule`).** -/
theorem spec_one_function : spec.functions.length = 1 := rfl

#print axioms selector_pinned
#print axioms selector_fits_uint32
#print axioms spec_name
#print axioms spec_no_fields
#print axioms spec_no_constructor
#print axioms spec_one_function

end LidoSRv3.Tests.VerityAllocCapacitySelectorKillLines
