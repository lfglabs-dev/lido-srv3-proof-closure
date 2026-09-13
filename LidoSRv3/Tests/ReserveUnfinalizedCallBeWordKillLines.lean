import LidoSRv3.Audit.Source.ReserveUnfinalizedCall

/-! # Kill-lines for `ReserveUnfinalizedCall.beWord` and `decodeWord32`

**Chantier 2 (Piste A, Thomas 2026-09-13) mutant kill-lines pinning
the big-endian ABI decoder used by the pinned
`unfinalizedStETH()` STATICCALL.** -/

namespace LidoSRv3.Tests.ReserveUnfinalizedCallBeWordKillLines

open LidoSRv3.Audit.Source.ReserveUnfinalizedCall

/-- **Kill-line: empty byte-list decodes to 0.**

A mutant returning a non-zero base case would refute. -/
theorem beWord_nil : beWord [] = 0 := rfl

/-- **Kill-line: single-byte big-endian decoding = byte mod 256.**

Solidity ABI is big-endian; a single byte occupies the lowest word. -/
theorem beWord_single_zero  : beWord [0]  = 0   := rfl
theorem beWord_single_one   : beWord [1]  = 1   := rfl
theorem beWord_single_ff    : beWord [255] = 255 := rfl

/-- **Kill-line: two-byte big-endian = high * 256 + low.** -/
theorem beWord_two_bytes :
    beWord [1, 2] = 1 * 256 + 2 := rfl

/-- **Kill-line: three-byte big-endian = h * 256^2 + m * 256 + l.** -/
theorem beWord_three_bytes :
    beWord [1, 2, 3] = 1 * 256 * 256 + 2 * 256 + 3 := rfl

/-- **Kill-line: `decodeWord32` on empty returns none.**

A mutant that dropped the length check would refute. -/
theorem decodeWord32_empty : decodeWord32 [] = none := rfl

/-- **Kill-line: `decodeWord32` on a 31-byte list returns none.**

Short returndata should fail-closed per the module contract. -/
theorem decodeWord32_thirtyOne :
    decodeWord32 (List.replicate 31 0) = none := by
  unfold decodeWord32
  simp

/-- **Kill-line: `decodeWord32` on a 32-byte zero list = some 0.**

Well-formed 32-byte all-zero decodes to zero. -/
theorem decodeWord32_thirtyTwo_zero :
    decodeWord32 (List.replicate 32 0) = some (Verity.Core.Uint256.ofNat 0) := by
  unfold decodeWord32
  simp
  rfl

/-- **Kill-line: `decodeWord32` on a 33-byte list returns none.**

Overlong returndata should fail-closed as well. -/
theorem decodeWord32_thirtyThree :
    decodeWord32 (List.replicate 33 0) = none := by
  unfold decodeWord32
  simp

/-- **Kill-line: the pinned `unfinalizedStETH()` selector is
`0xd0fb84e8`.**

A mutant that changed the selector would break the ABI-derived pin. -/
theorem unfinalizedStETHSelector_pinned :
    unfinalizedStETHSelector = 0xd0fb84e8 := rfl

#print axioms beWord_nil
#print axioms beWord_single_ff
#print axioms beWord_three_bytes
#print axioms decodeWord32_empty
#print axioms decodeWord32_thirtyOne
#print axioms decodeWord32_thirtyThree
#print axioms unfinalizedStETHSelector_pinned

end LidoSRv3.Tests.ReserveUnfinalizedCallBeWordKillLines
