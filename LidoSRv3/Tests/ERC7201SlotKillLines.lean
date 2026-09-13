import LidoSRv3.Audit.Source.ERC7201StorageSlotSource

/-! # Kill-lines for `ERC7201StorageSlotSource`

**Chantier 2 (Piste A, Thomas 2026-09-13) mutant kill-lines pinning
the pinned ERC-7201-style keccak slot derivation.**

`ERC7201StorageSlotSource` defines:
- `namespaceToNat ns` = ns → Nat encoding.
- `maskLowByte word` = `word - (word % 256)` (clears the low byte,
  the EIP-7201 rule).
- `realERC7201BaseSlot oracle ns` = `maskLowByte (oracle.hash
  ((oracle.hash (namespaceToNat ns)) - 1))`.

These kill-lines pin the mask-low-byte rule (per EIP-7201 spec) and
demonstrate that a mutant that skipped the mask or masked a different
byte would produce different slots. -/

namespace LidoSRv3.Tests.ERC7201SlotKillLines

open LidoSRv3.Audit.Source.ERC7201StorageSlotSource

/-- **Kill-line: `maskLowByte` clears exactly the low byte.**

`maskLowByte 511 = 256` — the low byte (0xFF = 255) is cleared and
the next byte (0x01 = 1) survives, producing `256`.  A mutant that
skipped the mask would return `511`. -/
theorem maskLowByte_at_511_is_256 :
    maskLowByte 511 = 256 := by
  unfold maskLowByte
  decide

/-- **Kill-line: `maskLowByte` is idempotent.**

`maskLowByte (maskLowByte x) = maskLowByte x` for any x whose low byte
is already zero after the first mask.  A mutant that clobbered
already-masked values would fail. -/
theorem maskLowByte_idempotent_at_256 :
    maskLowByte (maskLowByte 256) = maskLowByte 256 := by
  unfold maskLowByte
  decide

/-- **Kill-line: `maskLowByte` on a value ≤ 255 gives 0.**

Any single-byte value gets zeroed by the low-byte mask.  A mutant
that returned the value itself would fail. -/
theorem maskLowByte_of_uint8_is_zero :
    maskLowByte 128 = 0 := by
  unfold maskLowByte
  decide

/-- **Kill-line: `maskLowByte` preserves large aligned values.**

`maskLowByte 0x1000` = `0x1000` (already aligned to a byte boundary).
A mutant that clobbered aligned values would fail. -/
theorem maskLowByte_preserves_aligned :
    maskLowByte 0x1000 = 0x1000 := by
  unfold maskLowByte
  decide

/-- **Kill-line: `maskLowByte` on 0 is 0.**

Boundary case — the mask must not corrupt zero. -/
theorem maskLowByte_of_zero :
    maskLowByte 0 = 0 := by
  unfold maskLowByte
  decide

/-- **Kill-line: `namespaceToNat` on empty string is 0.**

The pinned encoding maps the empty string to zero.  A mutant that
returned a non-zero for empty would fail. -/
theorem namespaceToNat_empty :
    namespaceToNat "" = 0 := by
  simp [namespaceToNat]

/-- **Kill-line: two distinct non-empty strings can have distinct
`namespaceToNat` values.**

`namespaceToNat "a" ≠ namespaceToNat "b"` — the encoding is
injective on distinct single-char strings.  A mutant that mapped all
strings to zero (or a constant) would fail. -/
theorem namespaceToNat_distinguishes_a_b :
    namespaceToNat "a" ≠ namespaceToNat "b" := by
  unfold namespaceToNat
  decide

#print axioms maskLowByte_at_511_is_256
#print axioms maskLowByte_idempotent_at_256
#print axioms maskLowByte_of_uint8_is_zero
#print axioms maskLowByte_preserves_aligned
#print axioms maskLowByte_of_zero
#print axioms namespaceToNat_empty
#print axioms namespaceToNat_distinguishes_a_b

end LidoSRv3.Tests.ERC7201SlotKillLines
