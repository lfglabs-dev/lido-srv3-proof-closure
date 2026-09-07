import LidoSRv3.Audit.Source.TrioReserve1.Allocation
import LidoSRv3.Audit.Source.TrioReserve1.Lookup

/-! Independent exhaustive allocation leaf rules. Physical buffer and reserve
are saved before the locator/queue calls; arbitrary callee world changes and all
failure bytes survive. Queue demand comes from the actual returned ABI word.
Raw adversarial CALL is the explicit primitive boundary, not a success premise.
-/
namespace LidoSRv3.Audit.Source.TrioComposition.ReserveLeafAllocation
open TrioReserve1
open TrioReserve1.Live

def savedTotal (ctx : Context) (before : World) : Nat :=
  (before.core.readContractSlot ctx.self.val bufferSlot).val % width

def savedReserve (ctx : Context) (before : World) : Nat :=
  (before.core.readContractSlot ctx.self.val reserveSlot).val

def demand (data : Bytes) : Word := word (decode (data.take 32))

/-- Priority is specified by AllocationSpec maximality and conservation,
independently of the executable min/subtraction implementation. -/
inductive Describes (external : External) (ctx : Context) (before : World) :
    Except Fault Live.Allocation → World → List Attempt → Prop where
  | lookup_error {fault after trace}
      (hl : Lookup.Describes external ctx 0x37d5fe99 before (.error fault) after trace) :
      Describes external ctx before (.error fault) after trace
  | call_error {queue found left fault after right}
      (hl : Lookup.Describes external ctx 0x37d5fe99 before (.ok queue) found left)
      (hc : call external ctx queue 0xd0fb84e8 (word 0) found = ⟨.error fault,after,right⟩) :
      Describes external ctx before (.error fault) after (left ++ right)
  | malformed {queue found left data after right}
      (hl : Lookup.Describes external ctx 0x37d5fe99 before (.ok queue) found left)
      (hc : call external ctx queue 0xd0fb84e8 (word 0) found = ⟨.ok data,after,right⟩)
      (short : data.length < 32) :
      Describes external ctx before (.error .empty) after (left ++ right)
  | decoded {queue found left data after right} {a : Live.Allocation}
      (hl : Lookup.Describes external ctx 0x37d5fe99 before (.ok queue) found left)
      (hc : call external ctx queue 0xd0fb84e8 (word 0) found = ⟨.ok data,after,right⟩)
      (size : 32 ≤ data.length)
      (total : a.total = savedTotal ctx before)
      (partition : AllocationSpec.Describes (savedTotal ctx before) (savedReserve ctx before)
        (demand data).val (TrioReserve1.Allocation.observe a)) :
      Describes external ctx before (.ok a) after (left ++ right)

theorem partition_unique (buffer reserve queued : Nat) (a : Live.Allocation)
    (total : a.total = buffer)
    (partition : AllocationSpec.Describes buffer reserve queued (TrioReserve1.Allocation.observe a)) :
    a = ⟨buffer,min buffer reserve,min (buffer-min buffer reserve) queued,
      buffer-min buffer reserve-min (buffer-min buffer reserve) queued⟩ := by
  have unique := AllocationSpec.unique buffer reserve queued _ _ partition
    (AllocationSpec.exists_allocation buffer reserve queued)
  rcases a with ⟨actual,deposits,withdrawals,unreserved⟩
  simp only [TrioReserve1.Allocation.observe,AllocationSpec.Allocation.mk.injEq] at unique
  obtain ⟨hd,hw,hu⟩ := unique
  change actual = buffer at total
  simp only [total,hd,hw,hu]

theorem of_spec (external : External) (ctx : Context) (before after : World)
    (outcome : Except Fault Live.Allocation) (trace : List Attempt)
    (h : Describes external ctx before outcome after trace) :
    getBufferedEtherAllocation external ctx before = ⟨outcome,after,trace⟩ := by
  cases h with
  | lookup_error hl =>
    have lookup := Lookup.of_spec external ctx 0x37d5fe99 _ _ _ _ hl
    simp [getBufferedEtherAllocation,withdrawalQueue,Live.read,bind,bindExec,lookup]
  | call_error hl hc =>
    have lookup := Lookup.of_spec external ctx 0x37d5fe99 _ _ _ _ hl
    simp [getBufferedEtherAllocation,withdrawalQueue,Live.read,bind,bindExec,lookup,hc]
  | malformed hl hc short =>
    have lookup := Lookup.of_spec external ctx 0x37d5fe99 _ _ _ _ hl
    simp [getBufferedEtherAllocation,withdrawalQueue,Live.read,bind,bindExec,lookup,hc,
      decodeWord,require,show ¬ 32 ≤ _ from Nat.not_le.mpr short,fail]
  | decoded hl hc size total partition =>
    have lookup := Lookup.of_spec external ctx 0x37d5fe99 _ _ _ _ hl
    have value := partition_unique _ _ _ _ total partition
    simp [getBufferedEtherAllocation,withdrawalQueue,Live.read,bind,bindExec,lookup,hc,
      decodeWord,require,size,pure,pureExec,value,savedTotal,savedReserve,demand]

theorem exists_spec (external : External) (ctx : Context) (before : World) :
    ∃ outcome after trace, Describes external ctx before outcome after trace := by
  obtain ⟨lookupOutcome,found,left,hl⟩ := Lookup.exists_spec external ctx 0x37d5fe99 before
  cases lookupOutcome with
  | error fault => exact ⟨_,_,_,.lookup_error hl⟩
  | ok queue =>
    generalize hc : call external ctx queue 0xd0fb84e8 (word 0) found = reply
    rcases reply with ⟨callOutcome,after,right⟩
    cases callOutcome with
    | error fault => exact ⟨_,_,_,.call_error hl hc⟩
    | ok data =>
      by_cases size : 32 ≤ data.length
      · let a : Live.Allocation :=
          ⟨savedTotal ctx before,min (savedTotal ctx before) (savedReserve ctx before),
           min (savedTotal ctx before-min (savedTotal ctx before) (savedReserve ctx before)) (demand data).val,
           savedTotal ctx before-min (savedTotal ctx before) (savedReserve ctx before)-
             min (savedTotal ctx before-min (savedTotal ctx before) (savedReserve ctx before)) (demand data).val⟩
        exact ⟨.ok a,_,_,.decoded hl hc size rfl (AllocationSpec.exists_allocation _ _ _)⟩
      · exact ⟨_,_,_,.malformed hl hc (by omega)⟩

theorem to_spec (external : External) (ctx : Context) (before after : World)
    (outcome : Except Fault Live.Allocation) (trace : List Attempt)
    (h : getBufferedEtherAllocation external ctx before = ⟨outcome,after,trace⟩) :
    Describes external ctx before outcome after trace := by
  obtain ⟨otherOutcome,otherWorld,otherTrace,hd⟩ := exists_spec external ctx before
  have he := of_spec external ctx before otherWorld otherOutcome otherTrace hd
  have hi : otherOutcome = outcome ∧ otherWorld = after ∧ otherTrace = trace := by
    simpa only [Result.mk.injEq] using he.symm.trans h
  obtain ⟨rfl,rfl,rfl⟩ := hi
  exact hd

theorem corresponds (external : External) (ctx : Context) (before after : World)
    (outcome : Except Fault Live.Allocation) (trace : List Attempt) :
    Describes external ctx before outcome after trace ↔
      getBufferedEtherAllocation external ctx before = ⟨outcome,after,trace⟩ :=
  ⟨of_spec external ctx before after outcome trace,to_spec external ctx before after outcome trace⟩

#print axioms corresponds
end LidoSRv3.Audit.Source.TrioComposition.ReserveLeafAllocation
