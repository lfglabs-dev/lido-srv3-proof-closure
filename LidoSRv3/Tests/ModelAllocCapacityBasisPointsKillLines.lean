import LidoSRv3.Audit.Model.AllocCapacity

/-! # Kill-lines for `Model.AllocCapacity.totalBasisPoints`

**Chantier 3 (Piste A, Thomas 2026-09-13) mutant kill-lines pinning
the pinned `SRUtils.TOTAL_BASIS_POINTS` constant used by the
P-ALLOC-1 target-multiplication semantics. -/

namespace LidoSRv3.Tests.ModelAllocCapacityBasisPointsKillLines

open LidoSRv3.Audit.AllocCapacity

/-- **Kill-line: pinned SRUtils.TOTAL_BASIS_POINTS = 10000.**

100% expressed as basis points; the P-ALLOC-1 target-mult formula
`share * total / TOTAL_BASIS_POINTS` uses this constant. -/
theorem totalBasisPoints_pinned :
    totalBasisPoints.val = 10000 := by decide

/-- **Kill-line: `totalBasisPoints` is non-zero.**

A mutant zeroing it would introduce division-by-zero in the pinned
target calculation. -/
theorem totalBasisPoints_nonzero :
    totalBasisPoints.val ≠ 0 := by decide

/-- **Kill-line: `totalBasisPoints` fits uint16.** -/
theorem totalBasisPoints_fits_uint16 :
    totalBasisPoints.val < 2 ^ 16 := by decide

/-- **Kill-line: `totalBasisPoints` fits uint256 (word).** -/
theorem totalBasisPoints_fits_uint256 :
    totalBasisPoints.val < 2 ^ 256 := by decide

#print axioms totalBasisPoints_pinned
#print axioms totalBasisPoints_nonzero
#print axioms totalBasisPoints_fits_uint16
#print axioms totalBasisPoints_fits_uint256

end LidoSRv3.Tests.ModelAllocCapacityBasisPointsKillLines
