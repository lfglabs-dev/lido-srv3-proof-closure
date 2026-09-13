import LidoSRv3.Audit.Source.TrioReserve1.ABI

/-! # Kill-lines for `TrioReserve1.ABI` big-endian encode/decode round-trip

**Chantier 2 (Piste A, Thomas 2026-09-13) mutant kill-lines pinning
the byte-level big-endian encode/decode identities that ground the
executable Lido 0.4.24 reserve path. -/

namespace LidoSRv3.Tests.TrioReserve1AbiEncodeDecodeKillLines

open LidoSRv3.Audit.Source.TrioReserve1.Live

/-- **Kill-line: `encode size n` produces exactly `size` bytes.**

A mutant that dropped or added a byte would refute the length pin. -/
theorem encode_length_kill (size n : Nat) :
    (encode size n).length = size :=
  LidoSRv3.Audit.Source.TrioReserve1.ABI.encode_length size n

/-- **Kill-line: `decode` on empty list is 0.**

Base-case pin. A mutant returning a non-zero base would refute. -/
theorem decode_empty : decode [] = 0 := rfl

/-- **Kill-line: `encode 0 n = []` for any `n`.** -/
theorem encode_zero (n : Nat) : encode 0 n = [] := rfl

/-- **Kill-line: `decode ∘ encode = _ % 256^size`.**

The composed round-trip is the bedrock of the ABI encode/decode
pair (reduces mod 256^size for arbitrary `n`). -/
theorem decode_encode_kill (size n : Nat) :
    decode (encode size n) = n % 256 ^ size :=
  LidoSRv3.Audit.Source.TrioReserve1.ABI.decode_encode size n

/-- **Kill-line: encoding a 1-byte value round-trips for 42.** -/
theorem decode_encode_one_byte_42 :
    decode (encode 1 42) = 42 := by
  rw [decode_encode_kill]

/-- **Kill-line: encoding a 32-byte word round-trips for 12345.** -/
theorem decode_encode_word_12345 :
    decode (encode 32 12345) = 12345 := by
  rw [decode_encode_kill]

#print axioms encode_length_kill
#print axioms decode_empty
#print axioms encode_zero
#print axioms decode_encode_kill
#print axioms decode_encode_one_byte_42
#print axioms decode_encode_word_12345

end LidoSRv3.Tests.TrioReserve1AbiEncodeDecodeKillLines
