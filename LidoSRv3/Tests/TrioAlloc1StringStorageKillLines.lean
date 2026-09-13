import LidoSRv3.Audit.Source.TrioAlloc1.StringStorage

/-! # Kill-lines for `TrioAlloc1.StringStorage.oldLength` + clearRange

**Chantier 3 (Piste A, Thomas 2026-09-13) mutant kill-lines pinning
the pinned solc 0.8.25 SRLib string-storage semantics for the
short/long-encoding boundary and clear-range no-op cases. -/

namespace LidoSRv3.Tests.TrioAlloc1StringStorageKillLines

open LidoSRv3.Audit.Source.TrioAlloc1
open LidoSRv3.Audit.Source.TrioAlloc1.StringStorage

/-- **Kill-line: `oldLength (word 0) = .ok 0` (short-empty).**

Short encoding: low bit = 0, length = 0 in high bits. -/
theorem oldLength_zero : oldLength (word 0) = .ok 0 := rfl

/-- **Kill-line: `oldLength` on a short encoding with length 5.**

Short-form packing: `packed = 2 * length`. -/
theorem oldLength_short_five :
    oldLength (word (2 * 5)) = .ok 5 := rfl

/-- **Kill-line: `oldLength` rejects a malformed long (length 30, isLong=1).**

Long encoding requires length ≥ 32; check by ensuring the result
is not `.ok`. -/
theorem oldLength_bad_long_not_ok :
    (oldLength (word (2 * 30 + 1))).isOk = false := by decide

/-- **Kill-line: `oldLength` rejects malformed short (length 32, isLong=0).** -/
theorem oldLength_bad_short_not_ok :
    (oldLength (word (2 * 32))).isOk = false := by decide

/-- **Kill-line: `clearWords 0 _ s = s` (no-op base).** -/
theorem clearWords_zero (start : Nat) (s : Storage) :
    clearWords 0 start s = s := rfl

/-- **Kill-line: `clearRange s x x = s` (equal endpoints no-op).** -/
theorem clearRange_equal (s : Storage) (x : Word) :
    clearRange s x x = s := by
  unfold clearRange
  simp [clearWords]

/-- **Kill-line: `shortWord` on empty bytes yields length 0.**

`shortWord [] = word (0 * 256^32 + 0) = word 0`. -/
theorem shortWord_empty : shortWord [] = word 0 := by
  unfold shortWord
  simp

#print axioms oldLength_zero
#print axioms oldLength_short_five
#print axioms oldLength_bad_long_not_ok
#print axioms oldLength_bad_short_not_ok
#print axioms clearWords_zero
#print axioms clearRange_equal
#print axioms shortWord_empty

end LidoSRv3.Tests.TrioAlloc1StringStorageKillLines
