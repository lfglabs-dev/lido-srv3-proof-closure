import LidoSRv3.Audit.Source.TrioReserve1.Lookup

/-! Independent current-frame rules: a fresh oracle lookup, actual raw CALL,
and a tuple-wide 64-byte guard before either decoded word is returned. Every
failure retains the callee-returned world and both stages' attempted calls. -/
namespace LidoSRv3.Audit.Source.TrioComposition.ReserveLeafFrame
open TrioReserve1
open TrioReserve1.Live

def decoded (data : Bytes) : Nat × Nat :=
  ((word (decode (data.take 32))).val,(word (decode ((data.drop 32).take 32))).val)

inductive Describes (external : External) (ctx : Context) (before : World) :
    Except Fault (Nat × Nat) → World → List Attempt → Prop where
  | lookup_error {fault after trace}
      (hl : Lookup.Describes external ctx 0x5a2031f9 before (.error fault) after trace) :
      Describes external ctx before (.error fault) after trace
  | call_error {oracle found left fault after right}
      (hl : Lookup.Describes external ctx 0x5a2031f9 before (.ok oracle) found left)
      (hc : call external ctx oracle 0x72f79b13 (word 0) found = ⟨.error fault,after,right⟩) :
      Describes external ctx before (.error fault) after (left ++ right)
  | malformed {oracle found left data after right}
      (hl : Lookup.Describes external ctx 0x5a2031f9 before (.ok oracle) found left)
      (hc : call external ctx oracle 0x72f79b13 (word 0) found = ⟨.ok data,after,right⟩)
      (short : data.length < 64) :
      Describes external ctx before (.error .empty) after (left ++ right)
  | decoded {oracle found left data after right}
      (hl : Lookup.Describes external ctx 0x5a2031f9 before (.ok oracle) found left)
      (hc : call external ctx oracle 0x72f79b13 (word 0) found = ⟨.ok data,after,right⟩)
      (size : 64 ≤ data.length) :
      Describes external ctx before (.ok (ReserveLeafFrame.decoded data)) after (left ++ right)

def decodeFrame (data : Bytes) : Exec (Nat × Nat) := do
  require (64 ≤ data.length) .empty
  let nonce ← decodeWord data
  let timestamp ← decodeWord data 32
  pure (nonce.val,timestamp.val)

theorem decode_short (data : Bytes) (before : World) (short : data.length < 64) :
    decodeFrame data before = ⟨.error .empty,before,[]⟩ := by
  simp [decodeFrame,require,Nat.not_le.mpr short,bind,bindExec,fail]

theorem decode_long (data : Bytes) (before : World) (size : 64 ≤ data.length) :
    decodeFrame data before = ⟨.ok (decoded data),before,[]⟩ := by
  have first : 32 ≤ data.length := by omega
  simp [decodeFrame,decodeWord,require,size,first,bind,bindExec,pure,pureExec,decoded]

theorem frame_decomposition (external : External) (ctx : Context) :
    getCurrentFrame external ctx = (do
      let oracle ← locatorAddress external ctx 0x5a2031f9
      let data ← call external ctx oracle 0x72f79b13 (word 0)
      decodeFrame data) := rfl

theorem of_spec (external : External) (ctx : Context) (before after : World)
    (outcome : Except Fault (Nat × Nat)) (trace : List Attempt)
    (h : Describes external ctx before outcome after trace) :
    getCurrentFrame external ctx before = ⟨outcome,after,trace⟩ := by
  rw [frame_decomposition]
  cases h with
  | lookup_error hl =>
    have lookup := Lookup.of_spec external ctx 0x5a2031f9 _ _ _ _ hl
    simp [lookup,bind,bindExec]
  | call_error hl hc =>
    have lookup := Lookup.of_spec external ctx 0x5a2031f9 _ _ _ _ hl
    simp [lookup,hc,bind,bindExec]
  | malformed hl hc short =>
    have lookup := Lookup.of_spec external ctx 0x5a2031f9 _ _ _ _ hl
    simp [lookup,hc,bind,bindExec,decode_short _ _ short]
  | decoded hl hc size =>
    have lookup := Lookup.of_spec external ctx 0x5a2031f9 _ _ _ _ hl
    simp [lookup,hc,bind,bindExec,decode_long _ _ size]

theorem exists_spec (external : External) (ctx : Context) (before : World) :
    ∃ outcome after trace, Describes external ctx before outcome after trace := by
  obtain ⟨lookupOutcome,found,left,hl⟩ := Lookup.exists_spec external ctx 0x5a2031f9 before
  cases lookupOutcome with
  | error fault => exact ⟨_,_,_,.lookup_error hl⟩
  | ok oracle =>
    generalize hc : call external ctx oracle 0x72f79b13 (word 0) found = reply
    rcases reply with ⟨callOutcome,after,right⟩
    cases callOutcome with
    | error fault => exact ⟨_,_,_,.call_error hl hc⟩
    | ok data =>
      by_cases size : 64 ≤ data.length
      · exact ⟨_,_,_,.decoded hl hc size⟩
      · exact ⟨_,_,_,.malformed hl hc (by omega)⟩

theorem to_spec (external : External) (ctx : Context) (before after : World)
    (outcome : Except Fault (Nat × Nat)) (trace : List Attempt)
    (h : getCurrentFrame external ctx before = ⟨outcome,after,trace⟩) :
    Describes external ctx before outcome after trace := by
  obtain ⟨otherOutcome,otherWorld,otherTrace,hd⟩ := exists_spec external ctx before
  have he := of_spec external ctx before otherWorld otherOutcome otherTrace hd
  have hi : otherOutcome = outcome ∧ otherWorld = after ∧ otherTrace = trace := by
    simpa only [Result.mk.injEq] using he.symm.trans h
  obtain ⟨rfl,rfl,rfl⟩ := hi
  exact hd

theorem corresponds (external : External) (ctx : Context) (before after : World)
    (outcome : Except Fault (Nat × Nat)) (trace : List Attempt) :
    Describes external ctx before outcome after trace ↔
      getCurrentFrame external ctx before = ⟨outcome,after,trace⟩ :=
  ⟨of_spec external ctx before after outcome trace,to_spec external ctx before after outcome trace⟩

#print axioms corresponds
end LidoSRv3.Audit.Source.TrioComposition.ReserveLeafFrame
