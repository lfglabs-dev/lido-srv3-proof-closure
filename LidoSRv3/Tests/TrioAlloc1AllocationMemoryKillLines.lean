import LidoSRv3.Audit.Source.TrioAlloc1.AllocationMemory

/-! # Kill-lines for `TrioAlloc1.AllocationMemory` limit constant + rounded size

**Chantier 3 (Piste A, Thomas 2026-09-13) mutant kill-lines pinning
the pinned solc 0.8.25 via-IR allocation primitives: uint64 limit,
`arraySize` overflow guard, and 32-byte rounded-size projection. -/

namespace LidoSRv3.Tests.TrioAlloc1AllocationMemoryKillLines

open LidoSRv3.Audit.Source.TrioAlloc1.AllocationMemory
open LidoSRv3.Audit.Source.TrioAlloc1

/-- **Kill-line: `limit = 2^64 - 1` (uint64 upper bound).**

A mutant that widened or shrunk the limit would refute the
solc-observed guard. -/
theorem limit_pinned : limit = 2 ^ 64 - 1 := rfl

/-- **Kill-line: `limit` decimal.** -/
theorem limit_decimal : limit = 18446744073709551615 := by decide

/-- **Kill-line: `limit` fits uint64.** -/
theorem limit_fits_uint64 : limit < 2 ^ 64 := by decide

/-- **Kill-line: `arraySize` for count 0 gives header word 32 (32 * 0 + 32).**

Empty arrays still carry a length word per the Solidity ABI. -/
theorem arraySize_zero :
    arraySize ⟨0, by decide⟩ = .ok (word 32) := rfl

/-- **Kill-line: `arraySize` for count 1 gives 64 bytes (length + 1 word).** -/
theorem arraySize_one :
    arraySize ⟨1, by decide⟩ = .ok (word 64) := rfl

/-- **Kill-line: `roundedSize 0 = 0`.** -/
theorem roundedSize_zero :
    roundedSize ⟨0, by decide⟩ = 0 := by decide

/-- **Kill-line: `roundedSize 32 = 32`.** -/
theorem roundedSize_thirtyTwo :
    roundedSize ⟨32, by decide⟩ = 32 := by decide

/-- **Kill-line: `roundedSize 33 = 64` (rounds up to next 32-byte multiple).** -/
theorem roundedSize_thirtyThree :
    roundedSize ⟨33, by decide⟩ = 64 := by decide

#print axioms limit_pinned
#print axioms limit_decimal
#print axioms arraySize_zero
#print axioms roundedSize_zero
#print axioms roundedSize_thirtyThree

end LidoSRv3.Tests.TrioAlloc1AllocationMemoryKillLines
