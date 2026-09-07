import LidoSRv3.Audit.Source.TrioAlloc1.Execution

namespace LidoSRv3.Audit.Source.TrioAlloc1


@[simp] theorem encodeBE_length (width n : Nat) : (encodeBE width n).length = width := by
  induction width generalizing n with
  | zero => rfl
  | succ width ih => simp [encodeBE, ih]

theorem decodeBE_encodeBE (width n : Nat) :
    (encodeBE width n).foldl (fun a b => a*256+b.val) 0 = n % 256^width := by
  induction width generalizing n with
  | zero => simp [encodeBE, Nat.mod_one]
  | succ width ih =>
    simp only [encodeBE, List.foldl_append, List.foldl_cons, List.foldl_nil, ih, byte]
    conv => rhs; rw [Nat.pow_succ, Nat.mul_comm, Nat.mod_mul]
    omega

@[simp] theorem encodeWord_length (w : Word) : (encodeWord w).length = 32 :=
  encodeBE_length 32 w.val

/-- Actual 32-byte ABI encoding is a left inverse of the executor's word decoder. -/
theorem decodeWord_encodeWord (w : Word) : decodeWord (encodeWord w) 0 = w := by
  unfold decodeWord
  simp only [List.drop_zero]
  rw [List.take_of_length_le (by simp)]
  unfold encodeWord
  rw [decodeBE_encodeBE]
  have hp : 256^32 = 2^256 := by decide
  apply Fin.ext
  simp [word, hp, Nat.mod_eq_of_lt w.isLt]

/-- The decoder consumes exactly one word and ignores trailing bytes. -/
theorem decodeWord_append (w : Word) (tail : Bytes) :
    decodeWord (encodeWord w ++ tail) 0 = w := by
  unfold decodeWord
  simp only [List.drop_zero]
  rw [List.take_append_of_le_length (by simp)]
  change decodeWord (encodeWord w) 0 = w
  exact decodeWord_encodeWord w

attribute [local irreducible] encodeBE encodeWord decodeWord

theorem decodeWord_after_prefix (pre : Bytes) (w : Word) (tail : Bytes) :
    decodeWord (pre ++ (encodeWord w ++ tail)) pre.length = w := by
  unfold decodeWord
  rw [List.drop_left]
  simpa only [decodeWord, List.drop_zero] using decodeWord_append w tail

/-- Exact summary ABI field order, with arbitrary trailing returndata. -/
theorem decodeSummary_encoded (exited deposited depositable : Word) (tail : Bytes) :
    decodeSummary (encodeWord exited ++ encodeWord deposited ++ encodeWord depositable ++ tail) =
      .ok { exited, deposited, depositable } := by
  have length : ¬ (encodeWord exited ++ encodeWord deposited ++ encodeWord depositable ++ tail).length < 96 := by
    simp only [List.length_append, encodeWord_length]
    omega
  have he : decodeWord (encodeWord exited ++ encodeWord deposited ++ encodeWord depositable ++ tail) 0 = exited := by
    simpa only [List.append_assoc] using
      decodeWord_append exited (encodeWord deposited ++ encodeWord depositable ++ tail)
  have hd : decodeWord (encodeWord exited ++ encodeWord deposited ++ encodeWord depositable ++ tail) 32 = deposited := by
    simpa only [List.append_assoc, encodeWord_length] using
      decodeWord_after_prefix (encodeWord exited) deposited (encodeWord depositable ++ tail)
  have hp : decodeWord (encodeWord exited ++ encodeWord deposited ++ encodeWord depositable ++ tail) 64 = depositable := by
    simpa only [List.append_assoc, List.length_append, encodeWord_length] using
      decodeWord_after_prefix (encodeWord exited ++ encodeWord deposited) depositable tail
  simp only [decodeSummary, if_neg length, he, hd, hp]

def encodeWords (values : List Word) : Bytes := values.flatMap encodeWord

def encodeArray (values : List Word) : Bytes := encodeWord (word values.length) ++ encodeWords values

@[simp] theorem encodeWords_length (values : List Word) :
    (encodeWords values).length = 32*values.length := by
  induction values with
  | nil => simp [encodeWords]
  | cons value values ih =>
    change (encodeWord value ++ encodeWords values).length = 32*(values.length+1)
    simp [ih, Nat.mul_add, Nat.add_comm]

@[simp] theorem encodeArray_length (values : List Word) :
    (encodeArray values).length = 32*(values.length+1) := by
  simp [encodeArray, Nat.mul_add, Nat.add_comm]

/-- A byte-level element theorem, with arbitrary bytes both before and after the array. -/
theorem decodeWords_get (values : List Word) (i : Nat) (hi : i < values.length)
    (pre tail : Bytes) :
    decodeWord (pre ++ encodeWords values ++ tail) (pre.length+32*i) = values[i] := by
  induction values generalizing i pre with
  | nil => simp at hi
  | cons value values ih =>
    cases i with
    | zero =>
      simpa only [encodeWords, List.flatMap_cons, List.append_assoc, Nat.mul_zero,
        Nat.add_zero, List.getElem_cons_zero] using
        decodeWord_after_prefix pre value (encodeWords values ++ tail)
    | succ i =>
      have hi' : i < values.length := by simpa using hi
      have h := ih i hi' (pre ++ encodeWord value)
      simpa [encodeWords, List.flatMap_cons, List.append_assoc, List.length_append,
        encodeWord_length, Nat.mul_add, Nat.add_assoc, Nat.add_left_comm, Nat.add_comm] using h

/-- Word-memory reads are derived from actual byte sequences, not planted words. -/
theorem encodedArray_related (values : List Word) (pre tail : Bytes)
    (bound : values.length < 2^256) :
    ArrayAt (fun address => decodeWord (pre ++ encodeArray values ++ tail) address)
      pre.length values := by
  constructor
  · have h := decodeWord_after_prefix pre (word values.length) (encodeWords values ++ tail)
    have h' : decodeWord (pre ++ encodeArray values ++ tail) pre.length = word values.length := by
      simpa only [encodeArray, List.append_assoc] using h
    change (decodeWord (pre ++ encodeArray values ++ tail) pre.length).val = values.length
    rw [h']
    exact Nat.mod_eq_of_lt bound
  · intro i
    have h := decodeWords_get values i.val i.isLt (pre ++ encodeWord (word values.length)) tail
    simpa [encodeArray, List.append_assoc, List.length_append, encodeWord_length,
      Nat.mul_add, Nat.add_assoc, Nat.add_left_comm, Nat.add_comm] using h

end LidoSRv3.Audit.Source.TrioAlloc1
