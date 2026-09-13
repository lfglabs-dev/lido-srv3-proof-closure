import LidoSRv3.Audit.Source.TrioAlloc1.Storage

/-! # Kill-lines for `TrioAlloc1.Storage.encodeBE` + `encodeWord` + slot layout

**Chantier 3 (Piste A, Thomas 2026-09-13) mutant kill-lines pinning
the pinned SR router-storage layout encoding: fixed-width big-
endian ABI encoding, 32-byte word wrapper, and countSlot = routerSlot + 1. -/

namespace LidoSRv3.Tests.TrioAlloc1StorageEncodeSlotsKillLines

open LidoSRv3.Audit.Source.TrioAlloc1

/-- **Kill-line: `encodeBE 0 _` yields the empty byte-list.** -/
theorem encodeBE_zero (n : Nat) : encodeBE 0 n = [] := rfl

/-- **Kill-line: `encodeBE 1 n` yields a single byte = n % 256.** -/
theorem encodeBE_one : encodeBE 1 42 = [byte 42] := rfl

/-- **Kill-line: `encodeBE width n` produces exactly `width` bytes.** -/
theorem encodeBE_length : ∀ width n, (encodeBE width n).length = width
  | 0, _ => rfl
  | width + 1, n => by
      simp [encodeBE, encodeBE_length width]

/-- **Kill-line: `encodeWord w` produces exactly 32 bytes.** -/
theorem encodeWord_length (w : Word) : (encodeWord w).length = 32 :=
  encodeBE_length 32 w.val

/-- **Kill-line: `encodeBE (width+1) n = encodeBE width (n/256) ++ [byte n]`
recursive step.** -/
theorem encodeBE_succ (width n : Nat) :
    encodeBE (width + 1) n = encodeBE width (n / 256) ++ [byte n] := rfl

/-- **Kill-line: `word 0 = ⟨0, _⟩` as expected.** -/
theorem word_zero : (word 0).val = 0 := rfl

/-- **Kill-line: `word n` reduces modulo 2^256.**

Concrete: word (2^256) = 0. -/
theorem word_wraps : (word (2 ^ 256)).val = 0 := by decide

/-- **Kill-line: `countSlot = routerSlot + 1` (pinned relative slot).** -/
theorem countSlot_pinned (l : Layout) :
    countSlot l = word (l.routerSlot.val + 1) := rfl

/-- **Kill-line: `byte n = n % 256`.** -/
theorem byte_composition (n : Nat) : (byte n).val = n % 256 := rfl

#print axioms encodeBE_zero
#print axioms encodeBE_one
#print axioms encodeBE_succ
#print axioms word_zero
#print axioms word_wraps
#print axioms countSlot_pinned
#print axioms byte_composition

end LidoSRv3.Tests.TrioAlloc1StorageEncodeSlotsKillLines
