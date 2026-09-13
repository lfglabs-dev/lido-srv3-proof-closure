import LidoSRv3.Audit.Arithmetic

/-! # Kill-lines for `Audit.Arithmetic.Quantity` unit-aware checked semantics

**Chantier (Piste A, Thomas 2026-09-13) mutant kill-lines pinning
the pinned Verity `Uint256`-backed unit-aware arithmetic:
Wei/Gwei/Validators/BasisPoints unit tags and checked add/sub/mul/div. -/

namespace LidoSRv3.Tests.AuditArithmeticUnitKillLines

open Verity
open LidoSRv3.Audit
open LidoSRv3.Audit.Quantity

/-- **Kill-line: `zero.value = 0` for any unit.** -/
theorem zero_value (unit : Type) :
    (zero : Quantity unit).value = 0 := rfl

/-- **Kill-line: `checkedAdd 0 0 = some 0` in Wei.** -/
theorem checkedAdd_zero_wei :
    checkedAdd (zero : Wei) zero = some zero := rfl

/-- **Kill-line: `checkedSub 0 0 = some 0` in Wei.** -/
theorem checkedSub_zero_wei :
    checkedSub (zero : Wei) zero = some zero := rfl

/-- **Kill-line: `checkedMul` by zero returns some zero.** -/
theorem checkedMul_zero_zero :
    checkedMul (zero : Wei) 0 = some zero := rfl

/-- **Kill-line: Wei zero fits uint256.** -/
theorem Wei_zero_fits_uint256 :
    (zero : Wei).value.val < 2 ^ 256 := (zero : Wei).value.isLt

/-- **Kill-line: Gwei zero fits uint256.** -/
theorem Gwei_zero_fits_uint256 :
    (zero : Gwei).value.val < 2 ^ 256 := (zero : Gwei).value.isLt

/-- **Kill-line: Validators zero fits uint256.** -/
theorem Validators_zero_fits_uint256 :
    (zero : Validators).value.val < 2 ^ 256 := (zero : Validators).value.isLt

/-- **Kill-line: BasisPoints zero fits uint256.** -/
theorem BasisPoints_zero_fits_uint256 :
    (zero : BasisPoints).value.val < 2 ^ 256 := (zero : BasisPoints).value.isLt

#print axioms zero_value
#print axioms checkedAdd_zero_wei
#print axioms checkedSub_zero_wei
#print axioms checkedMul_zero_zero
#print axioms Wei_zero_fits_uint256
#print axioms Gwei_zero_fits_uint256
#print axioms Validators_zero_fits_uint256
#print axioms BasisPoints_zero_fits_uint256

end LidoSRv3.Tests.AuditArithmeticUnitKillLines
