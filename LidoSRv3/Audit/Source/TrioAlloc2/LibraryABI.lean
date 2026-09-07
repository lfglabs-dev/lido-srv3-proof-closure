import LidoSRv3.Audit.Source.TrioAlloc1.Bytes
import LidoSRv3.Audit.Source.TrioAlloc2.LoopCorrespondence

/-! Consumer-owned byte boundary using the pinned producer's actual byte codec.
Offsets are relative to the arguments block (the four-byte selector is separate).
The canonical ABI round trips below do not certify compiler-generated dispatch,
memory allocation, or every noncanonical ABI input; those remain separate gates. -/
namespace LidoSRv3.Audit.Source.TrioAlloc2.LibraryABI
open _root_.LidoSRv3.Audit.Source.TrioAlloc1 (Bytes encodeWord encodeArray decodeWord)

/-- Bounds are checked before any array element is decoded. -/
def decodeArray (bytes : Bytes) (offset : Nat) : Except Unit (List Word) :=
  if offset + 32 > bytes.length then .error () else
  let count := (decodeWord bytes offset).val
  if count ≥ 2^64 then .error () else
  if offset + 32 * (count + 1) > bytes.length then .error () else
  .ok (List.ofFn fun i : Fin count => decodeWord bytes (offset + 32*(i.val+1)))

/-- Canonical array bytes recover every original word in order, even with
arbitrary bytes before and after the encoded array. -/
theorem decodeArray_encoded (values : List Word) (pre tail : Bytes)
    (bound : values.length < 2^64) :
    decodeArray (pre ++ encodeArray values ++ tail) pre.length = .ok values := by
  have wordBound : values.length < 2^256 := by omega
  have related := TrioAlloc1.encodedArray_related values pre tail wordBound
  have headerBound : ¬ pre.length + 32 > (pre ++ encodeArray values ++ tail).length := by
    simp only [List.length_append, TrioAlloc1.encodeArray_length]
    omega
  have extent : ¬ pre.length + 32*(values.length+1) > (pre ++ encodeArray values ++ tail).length := by
    simp only [List.length_append, TrioAlloc1.encodeArray_length]
    omega
  unfold decodeArray
  rw [if_neg headerBound]
  dsimp only
  rw [related.1, if_neg (show ¬ values.length ≥ 2^64 by omega), if_neg extent]
  apply congrArg Except.ok
  apply List.ext_getElem (by simp only [List.length_ofFn])
  intro i hi hj
  simpa only [List.getElem_ofFn, Fin.getElem_fin] using related.2 ⟨i, hj⟩

structure Arguments where
  buckets : List Word
  capacities : List Word
  demand : Word
  deriving DecidableEq, Repr

/-- Standard ABI head followed by two length-prefixed dynamic uint256 arrays. -/
def encodeArguments (a : Arguments) : Bytes :=
  encodeWord (TrioAlloc1.word 96) ++
  encodeWord (TrioAlloc1.word (96 + 32*(a.buckets.length+1))) ++ encodeWord a.demand ++
  encodeArray a.buckets ++ encodeArray a.capacities

def decodeArguments (bytes : Bytes) : Except Unit Arguments := do
  if bytes.length < 96 then .error () else do
    let bp := (decodeWord bytes 0).val
    let cp := (decodeWord bytes 32).val
    if bp ≥ 2^64 ∨ cp ≥ 2^64 then .error () else do
      let buckets ← decodeArray bytes bp
      let capacities ← decodeArray bytes cp
      .ok ⟨buckets, capacities, decodeWord bytes 64⟩

attribute [local irreducible] TrioAlloc1.encodeWord TrioAlloc1.encodeArray TrioAlloc1.decodeWord decodeArray

theorem decodeArguments_encoded (a : Arguments)
    (bound : (encodeArguments a).length < 2^64) :
    decodeArguments (encodeArguments a) = .ok a := by
  have size := bound
  simp only [encodeArguments, List.length_append, TrioAlloc1.encodeWord_length,
    TrioAlloc1.encodeArray_length] at size
  have bucketBound : a.buckets.length < 2^64 := by omega
  have capacityBound : a.capacities.length < 2^64 := by omega
  have offsetBound : 96 + 32*(a.buckets.length+1) < 2^64 := by omega
  have offsetWordBound : 96 + 32*(a.buckets.length+1) < 2^256 := by omega
  let cp := TrioAlloc1.word (96 + 32*(a.buckets.length+1))
  have cpValue : cp.val = 96 + 32*(a.buckets.length+1) := Nat.mod_eq_of_lt offsetWordBound
  have first := TrioAlloc1.decodeWord_append (TrioAlloc1.word 96)
    (encodeWord cp ++ encodeWord a.demand ++ encodeArray a.buckets ++ encodeArray a.capacities)
  have second := TrioAlloc1.decodeWord_after_prefix (encodeWord (TrioAlloc1.word 96)) cp
    (encodeWord a.demand ++ encodeArray a.buckets ++ encodeArray a.capacities)
  have demand := TrioAlloc1.decodeWord_after_prefix
    (encodeWord (TrioAlloc1.word 96) ++ encodeWord cp) a.demand
    (encodeArray a.buckets ++ encodeArray a.capacities)
  have buckets := decodeArray_encoded a.buckets
    (encodeWord (TrioAlloc1.word 96) ++ encodeWord cp ++ encodeWord a.demand)
    (encodeArray a.capacities) bucketBound
  have capacities := decodeArray_encoded a.capacities
    (encodeWord (TrioAlloc1.word 96) ++ encodeWord cp ++ encodeWord a.demand ++ encodeArray a.buckets)
    [] capacityBound
  simp only [List.length_append, TrioAlloc1.encodeWord_length, TrioAlloc1.encodeArray_length,
    List.append_nil, List.append_assoc] at first second demand buckets capacities
  have headBound : ¬ (encodeArguments a).length < 96 := by
    simp only [encodeArguments, List.length_append, TrioAlloc1.encodeWord_length,
      TrioAlloc1.encodeArray_length]
    omega
  have firstEq : decodeWord (encodeArguments a) 0 = TrioAlloc1.word 96 := by
    simpa only [encodeArguments, cp, List.append_assoc] using first
  have secondEq : decodeWord (encodeArguments a) 32 = cp := by
    simpa only [encodeArguments, cp, List.append_assoc] using second
  have demandEq : decodeWord (encodeArguments a) 64 = a.demand := by
    simpa only [encodeArguments, cp, List.append_assoc, ← Nat.add_assoc, Nat.reduceAdd] using demand
  have bucketsEq : decodeArray (encodeArguments a) 96 = .ok a.buckets := by
    simpa only [encodeArguments, cp, List.append_assoc, ← Nat.add_assoc, Nat.reduceAdd] using buckets
  have capacitiesEq : decodeArray (encodeArguments a) (96 + 32*(a.buckets.length+1)) = .ok a.capacities := by
    simpa only [encodeArguments, cp, List.append_assoc, ← Nat.add_assoc, Nat.reduceAdd] using capacities
  have ninetySix : (TrioAlloc1.word 96).val = 96 := by decide
  simp only [decodeArguments, headBound, ↓reduceIte, firstEq, secondEq, cpValue, ninetySix,
    show ¬ ((96 : Nat) ≥ 2^64 ∨ 96 + 32*(a.buckets.length+1) ≥ 2^64) by omega,
    bucketsEq, capacitiesEq, demandEq, bind, Except.bind]

/-- Return ABI contains the allocated word and a single dynamic array. -/
def encodeReturn (out : StepOutput) : Bytes :=
  encodeWord out.amount ++ encodeWord (TrioAlloc1.word 64) ++ encodeArray out.buckets

def decodeReturn (bytes : Bytes) : Except Unit StepOutput := do
  if bytes.length < 64 then .error () else do
    let offset := (decodeWord bytes 32).val
    if offset ≥ 2^64 then .error () else do
      let buckets ← decodeArray bytes offset
      .ok ⟨decodeWord bytes 0, buckets⟩

theorem decodeReturn_encoded (out : StepOutput) (bound : out.buckets.length < 2^64) :
    decodeReturn (encodeReturn out) = .ok out := by
  have amount := TrioAlloc1.decodeWord_append out.amount (encodeWord (TrioAlloc1.word 64) ++ encodeArray out.buckets)
  have offset := TrioAlloc1.decodeWord_after_prefix (encodeWord out.amount) (TrioAlloc1.word 64) (encodeArray out.buckets)
  have array := decodeArray_encoded out.buckets (encodeWord out.amount ++ encodeWord (TrioAlloc1.word 64)) [] bound
  simp only [TrioAlloc1.encodeWord_length] at offset
  simp only [List.length_append, TrioAlloc1.encodeWord_length, List.append_nil] at array
  have lengthBound : ¬ (encodeReturn out).length < 64 := by
    simp only [encodeReturn, List.length_append, TrioAlloc1.encodeWord_length, TrioAlloc1.encodeArray_length]
    omega
  have amountEq : decodeWord (encodeReturn out) 0 = out.amount := by
    simpa only [encodeReturn, List.append_assoc] using amount
  have offsetEq : decodeWord (encodeReturn out) 32 = TrioAlloc1.word 64 := by
    simpa only [encodeReturn, List.append_assoc] using offset
  have arrayEq : decodeArray (encodeReturn out) 64 = .ok out.buckets := by
    simpa only [encodeReturn, List.append_assoc, ← Nat.add_assoc, Nat.reduceAdd] using array
  have sixtyFour : (TrioAlloc1.word 64).val = 64 := by decide
  simp only [decodeReturn, lengthBound, ↓reduceIte, offsetEq, sixtyFour,
    show ¬ (64 : Nat) ≥ 2^64 by decide, arrayEq, amountEq, bind, Except.bind]

/-- Solidity Panic(uint256) selector and its 32-byte code. -/
def panicBytes (reason : Panic) : Bytes :=
  [TrioAlloc1.byte 0x4e, TrioAlloc1.byte 0x48, TrioAlloc1.byte 0x7b, TrioAlloc1.byte 0x71] ++
    encodeWord (TrioAlloc1.word (match reason with
      | .arithmetic => 0x11 | .divisionByZero => 0x12 | .arrayBounds => 0x32))

def encodeOutcome : Result StepOutput → Except Bytes Bytes
  | .error reason => .error (panicBytes reason)
  | .ok out => .ok (encodeReturn out)

/-- Decoder failure precedes the source demand guard. The selector has already
been dispatched; failure bytes and successful return bytes remain distinct. -/
def run (bytes : Bytes) : Except Bytes Bytes :=
  match decodeArguments bytes with
  | .error () => .error []
  | .ok a => encodeOutcome (allocate a.buckets a.capacities a.demand)

theorem run_encoded (a : Arguments) (bound : (encodeArguments a).length < 2^64) :
    run (encodeArguments a) = encodeOutcome (allocate a.buckets a.capacities a.demand) := by
  simp only [run, decodeArguments_encoded a bound]

theorem run_short (bytes : Bytes) (short : bytes.length < 96) : run bytes = .error [] := by
  simp only [run, decodeArguments, short, ↓reduceIte]

theorem panicBytes_length (reason : Panic) : (panicBytes reason).length = 36 := by
  simp only [panicBytes, List.length_append, List.length_cons, List.length_nil,
    TrioAlloc1.encodeWord_length]

#print axioms decodeArray_encoded
#print axioms decodeArguments_encoded
#print axioms decodeReturn_encoded
#print axioms run_encoded
#print axioms run_short
end LidoSRv3.Audit.Source.TrioAlloc2.LibraryABI
