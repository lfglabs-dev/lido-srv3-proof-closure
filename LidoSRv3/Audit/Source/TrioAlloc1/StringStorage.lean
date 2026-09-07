import LidoSRv3.Audit.Source.TrioAlloc1.ShareWriter

/-!
Pinned solc 0.8.25 optimized SRLib string-storage operations for an admitted
name of at most 31 bytes. Old malformed encoding retains panic 0x22; long-name
cleanup uses the compiler's unsigned start/end comparison after word addition.
This models storage effects, not compiler memory or gas consumption.
-/
namespace LidoSRv3.Audit.Source.TrioAlloc1
namespace StringStorage

def oldLength (packed : Word) : Except Failure Nat :=
  let isLong := packed.val % 2
  let length := if isLong = 0 then packed.val / 2 % 128 else packed.val / 2
  if (isLong = 1 ∧ length < 32) ∨ (isLong = 0 ∧ length ≥ 32) then
    .error (.panic 0x22)
  else .ok length

def clearWords : Nat → Nat → Storage → Storage
  | 0, _, s => s
  | n+1, start, s => clearWords n (start+1) (ShareWriter.write s (word start) 0)

/-- Equal/reversed endpoints perform zero writes, including a wrapped endpoint. -/
def clearRange (s : Storage) (start finish : Word) : Storage :=
  clearWords (finish.val-start.val) start.val s

def shortWord (name : Bytes) : Word :=
  word (name.foldl (fun n b => n*256+b.val) 0 * 256^(32-name.length) + 2*name.length)

-- SRLib.sol:216
/-- Caller has performed the 1..31-byte admission guard. -/
def writeShort (l : Layout) (s : Storage) (slot : Word) (name : Bytes) : Except Failure Storage := do
  let length ← oldLength (s slot)
  let clean := if length > 31 then
      let start := l.keccak (encodeWord slot)
      clearRange s start (word (start.val+(length+31)/32))
    else s
  pure (ShareWriter.write clean slot (shortWord name))

theorem malformed_short (packed : Word)
    (short : packed.val % 2 = 0) (bad : packed.val / 2 % 128 ≥ 32) :
    oldLength packed = .error (.panic 0x22) := by
  simp [oldLength, short, bad]

theorem malformed_long (packed : Word)
    (long : packed.val % 2 = 1) (bad : packed.val / 2 < 32) :
    oldLength packed = .error (.panic 0x22) := by
  simp [oldLength, long, bad]

theorem zero_length : oldLength 0 = .ok 0 := by rfl

theorem clearRange_reversed (s : Storage) (start finish : Word) (h : finish.val ≤ start.val) :
    clearRange s start finish = s := by
  simp [clearRange, Nat.sub_eq_zero_of_le h, clearWords]

theorem writeShort_zero (l : Layout) (s : Storage) (slot : Word) (name : Bytes)
    (empty : s slot = 0) :
    writeShort l s slot name = .ok (ShareWriter.write s slot (shortWord name)) := by
  simp [writeShort, empty, oldLength]
  rfl

theorem writeShort_stored (l : Layout) (s after : Storage) (slot : Word) (name : Bytes)
    (run : writeShort l s slot name = .ok after) : after slot = shortWord name := by
  unfold writeShort at run
  cases old : oldLength (s slot) with
  | error reason =>
    simp only [old] at run
    change Except.error reason = Except.ok after at run
    cases run
  | ok length =>
    simp only [old] at run
    change Except.ok (ShareWriter.write _ slot (shortWord name)) = Except.ok after at run
    cases run
    simp [ShareWriter.write]

end StringStorage
end LidoSRv3.Audit.Source.TrioAlloc1
