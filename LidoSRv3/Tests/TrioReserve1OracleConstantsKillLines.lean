import LidoSRv3.Audit.Source.TrioReserve1.Oracle

/-! # Kill-lines for `TrioReserve1.Oracle` consensus slot + Panic(0x11) selector

**Chantier 2 (Piste A, Thomas 2026-09-13) mutant kill-lines pinning
the two pinned AccountingOracle-side constants used by the executable
Lido 0.4.24 reserve path: consensusSlot ERC-1967 slot and the
Solidity 0.8.x Panic(0x11) (arithmetic overflow) revert payload. -/

namespace LidoSRv3.Tests.TrioReserve1OracleConstantsKillLines

open LidoSRv3.Audit.Source.TrioReserve1.Oracle
open LidoSRv3.Audit.Source.TrioReserve1.Live

/-- **Kill-line: pinned AccountingOracle consensus contract slot.** -/
theorem consensusSlot_pinned :
    consensusSlot =
      0xb0e01b719c2c32a677822ce1584cb6a66e576ee3c2c506b9621dbe626355aa65 :=
  rfl

/-- **Kill-line: consensusSlot fits uint256.** -/
theorem consensusSlot_fits_uint256 : consensusSlot < 2 ^ 256 := by decide

/-- **Kill-line: consensusSlot is non-zero.** -/
theorem consensusSlot_nonzero : consensusSlot ≠ 0 := by decide

/-- **Kill-line: Solidity 0.8.x `Panic(uint256)` payload byte length is
36 (4-byte selector + 32-byte uint256 code).**

A mutant that shortened or extended the panic payload would refute. -/
theorem panic_length : panic.length = 36 := by decide

/-- **Kill-line: The panic payload's uint256 code is 0x11 (arithmetic
overflow/underflow).** -/
theorem panic_code_pinned :
    panic.drop 4 = encode 32 0x11 := by decide

/-- **Kill-line: `Panic(uint256)` selector is 0x4e487b71.** -/
theorem panic_selector : panic.take 4 = encode 4 0x4e487b71 := by decide

#print axioms consensusSlot_pinned
#print axioms consensusSlot_fits_uint256
#print axioms panic_length
#print axioms panic_code_pinned
#print axioms panic_selector

end LidoSRv3.Tests.TrioReserve1OracleConstantsKillLines
