import LidoSRv3.Audit.Source.TrioComposition.FinalMemoryStoredParentCaller
import LidoSRv3.Audit.Source.TrioComposition.FinalMemoryParent

/-! Closed source parent composition: one guarded/storing producer evaluation,
one positive-demand closed-library DELEGATECALL observed from actual memory,
raw-return staging and live decoder copy, then in-place Ether conversion.

This model observes source module calls and the configured library target/raw
reply. The library implementation is the closed LibraryABI model, not arbitrary
deployed code. Entry-pointer provenance, storage/hash correspondence, omitted
cache/scratch stores, word/byte primitive refinement and gas remain local compiler
or deployment boundaries. All numeric and array premises used below are derived;
there is no assumed successful producer/library/conversion or final array relation. -/
namespace LidoSRv3.Audit.Source.TrioComposition.FinalMemoryStoredParent
open TrioAlloc1
open FinalMemoryStoredParentMemory
open FinalMemoryStoredParentCaller

structure Run where
  result : Except Failure Output
  modules : Transcript
  calls : MemoryTransportCall.Trace

def project (run : Run) : Except Failure ParentOutput × Transcript :=
  (run.result.map observe,run.modules)

/-- Existing full-call history is retained once; only the new module suffix is
embedded before the library event. Failure retains every newly attempted call. -/
def program (target : Address) (memory : MemoryWords) (pointer : Word)
    (layout : Layout) (storage : Storage) (oracle : StaticOracle) (config : Config)
    (amount : Word) (isTopUp : Bool) (before : Transcript) (trace : MemoryTransportCall.Trace) : Run :=
  match FinalMemoryRows.slot pointer with
  | .error reason => ⟨.error reason,before,trace⟩
  | .ok countPointer =>
    let count := storage (countSlot layout)
    if count.val = 0 then ⟨empty memory countPointer,before,trace⟩
    else match checkedDiv amount config.maxEBType1 with
    | .error reason => ⟨.error reason,before,trace⟩
    | .ok demand =>
      let (produced,middle) := CallTree.evaluate oracle
        (FinalMemoryStoredProducer.producer memory countPointer layout storage ⟨config,demand,isTopUp⟩) before
      let observed := trace ++ (middle.drop before.length).map MemoryTransportCall.staticEvent
      match produced with
      | .error reason => ⟨.error reason,middle,observed⟩
      | .ok out =>
        let (result,ending) := afterProducer target out count config.maxEBType1 demand observed
        ⟨result,middle,ending⟩

private theorem producer_projection (memory : MemoryWords) (pointer : Word)
    (layout : Layout) (storage : Storage) (oracle : StaticOracle) (input : CapacityInput)
    (before : Transcript) (hc : (storage (countSlot layout)).val ≤ 32)
    (space : pointer.val+1120*(storage (countSlot layout)).val+448 ≤ 2^32) :
    let actual := CallTree.evaluate oracle (FinalMemoryStoredProducer.producer memory pointer layout storage input) before
    (actual.1.map FinalMemoryStoredProducer.Output.produced,actual.2) = produce layout storage oracle input before := by
  rw [← CallTree.producer_correspondence,← FinalMemoryStoredProducer.projection memory pointer layout storage input hc space]
  simp only [CallTree.evaluate_monad_bind,CallTree.evaluate_pure]
  cases actual : CallTree.evaluate oracle (FinalMemoryStoredProducer.producer memory pointer layout storage input) before with
  | mk result after => cases result <;> simp only [bind,bindExec,actual,pureExec,Except.map]

private theorem after_tree (count : Nat) (config : Config) (demand : Word) (produced : CapacityOutput) :
    ParentCalls.afterProducer count config demand produced = CallTree.check (decodedAfter count config demand produced) := by
  unfold ParentCalls.afterProducer decodedAfter
  by_cases positive : demand.val > 0
  · simp only [positive,↓reduceIte]
    cases libraryThroughABI produced demand with
    | error reason => rfl
    | ok result =>
      simp only [bind,Except.bind,CallTree.bind,CallTree.check]
      cases checked (result.amount.val*config.maxEBType1.val) with
      | error reason => rfl
      | ok total =>
        simp only
        cases convertPositive config.maxEBType1 count produced.allocations result.buckets <;> rfl
  · simp only [positive,↓reduceIte]
    cases convertZero config.maxEBType1 count produced.allocations <;> rfl

/-- All outcomes of the full storing/calling parent project to the independently
proved ABI parent, including errors after a recorded library call or partial
internal conversion writes. Only the internal reverted memory is discarded. -/
theorem projection_abi (target : Address) (memory : MemoryWords) (pointer : Word)
    (layout : Layout) (storage : Storage) (oracle : StaticOracle) (config : Config)
    (amount : Word) (isTopUp : Bool) (before : Transcript) (trace : MemoryTransportCall.Trace)
    (hc : (storage (countSlot layout)).val ≤ 32)
    (space : pointer.val+1184*(storage (countSlot layout)).val+704 ≤ 2^32) :
    project (program target memory pointer layout storage oracle config amount isTopUp before trace) =
      getDepositAllocationsABI layout storage oracle config amount isTopUp before := by
  have slotSpace : pointer.val+128 ≤ 2^32 := by omega
  have slotVal := FinalMemoryRows.word_small (pointer.val+128) slotSpace
  have producerSpace : (word (pointer.val+128)).val+1120*(storage (countSlot layout)).val+448 ≤ 2^32 := by
    rw [slotVal]; omega
  have callerSpace : (word (pointer.val+128)).val+1184*(storage (countSlot layout)).val+576 ≤ 2^32 := by
    rw [slotVal]; omega
  rw [← ParentCalls.correspondence]
  simp only [program,FinalMemoryRows.slot_exact pointer slotSpace,ParentCalls.program]
  by_cases noModules : (storage (countSlot layout)).val = 0
  · have emptySpace : (word (pointer.val+128)).val+64 ≤ 2^32 := by rw [slotVal]; omega
    simp only [noModules,↓reduceIte,project,empty_projection memory _ emptySpace,CallTree.evaluate_pure,pureExec]
  · simp only [noModules,↓reduceIte,ParentCalls.afterDivision,after_tree]
    simp only [CallTree.evaluate_monad_bind,CallTree.evaluate_check,CallTree.producer_correspondence]
    simp only [bind,bindExec,liftChecked]
    cases divided : checkedDiv amount config.maxEBType1 with
    | error reason => rfl
    | ok demand =>
      simp only
      have projected := producer_projection memory (word (pointer.val+128)) layout storage oracle
        ⟨config,demand,isTopUp⟩ before hc producerSpace
      cases producedEq : CallTree.evaluate oracle
        (FinalMemoryStoredProducer.producer memory (word (pointer.val+128)) layout storage ⟨config,demand,isTopUp⟩) before with
      | mk produced middle =>
        rw [producedEq] at projected
        cases produced with
        | error reason =>
          change (.error reason,middle) = produce layout storage oracle ⟨config,demand,isTopUp⟩ before at projected
          rw [← projected]
          rfl
        | ok out =>
          change (.ok out.produced,middle) = produce layout storage oracle ⟨config,demand,isTopUp⟩ before at projected
          rw [← projected]
          change ((afterProducer target out (storage (countSlot layout)) config.maxEBType1 demand
            (trace ++ (middle.drop before.length).map MemoryTransportCall.staticEvent)).1.map observe,middle) = _
          apply Prod.ext
          · exact afterProducer_projection target memory (word (pointer.val+128)) layout storage oracle
              ⟨config,demand,isTopUp⟩ before middle out producedEq hc callerSpace _
          · rfl

/-- Allocation-only and storing/observable parents agree on every return/error
and source module transcript; the extra library event is retained separately. -/
theorem projection (target : Address) (memory : MemoryWords) (pointer : Word)
    (layout : Layout) (storage : Storage) (oracle : StaticOracle) (config : Config)
    (amount : Word) (isTopUp : Bool) (before : Transcript) (trace : MemoryTransportCall.Trace)
    (hc : (storage (countSlot layout)).val ≤ 32)
    (space : pointer.val+1184*(storage (countSlot layout)).val+704 ≤ 2^32) :
    project (program target memory pointer layout storage oracle config amount isTopUp before trace) =
      CallTree.evaluate oracle (FinalMemoryParent.program pointer layout storage config amount isTopUp) before := by
  rw [projection_abi target memory pointer layout storage oracle config amount isTopUp before trace hc space,
    FinalMemoryParent.correspondence pointer layout storage oracle config amount isTopUp hc space]

theorem public_iff (target : Address) (memory : MemoryWords) (pointer : Word)
    (layout : Layout) (storage : Storage) (oracle : StaticOracle) (config : Config)
    (amount : Word) (isTopUp : Bool) (before after : Transcript) (trace : MemoryTransportCall.Trace)
    (result : Except Failure ParentOutput) (hc : (storage (countSlot layout)).val ≤ 32)
    (space : pointer.val+1184*(storage (countSlot layout)).val+704 ≤ 2^32) :
    ParentSpec.Public layout storage oracle config amount isTopUp before result after ↔
      project (program target memory pointer layout storage oracle config amount isTopUp before trace) = (result,after) := by
  rw [projection target memory pointer layout storage oracle config amount isTopUp before trace hc space]
  exact FinalMemoryParent.public_iff pointer layout storage oracle config amount isTopUp before after result hc space

/-- Successful output is read from the actual resulting memory. Its public
specification and both array relations follow; no expected output is supplied. -/
theorem success (target : Address) (memory : MemoryWords) (pointer : Word)
    (layout : Layout) (storage : Storage) (oracle : StaticOracle) (config : Config)
    (amount : Word) (isTopUp : Bool) (before : Transcript) (trace : MemoryTransportCall.Trace)
    (out : Output) (hc : (storage (countSlot layout)).val ≤ 32)
    (space : pointer.val+1184*(storage (countSlot layout)).val+704 ≤ 2^32)
    (executed : (program target memory pointer layout storage oracle config amount isTopUp before trace).result = .ok out) :
    ParentSpec.Public layout storage oracle config amount isTopUp before (.ok (observe out))
      (program target memory pointer layout storage oracle config amount isTopUp before trace).modules ∧
    ArrayAt out.memory out.ap.val (observe out).allocated ∧
    ArrayAt out.memory out.rp.val (observe out).newAllocations := by
  constructor
  · apply (public_iff target memory pointer layout storage oracle config amount isTopUp before _ trace _ hc space).mpr
    simp only [project,executed,Except.map]
  · exact observed_memory out

/-- The exact positive branch suffix is recorded even when caller allocation or
conversion subsequently fails. Only this invocation's static suffix is appended. -/
theorem positive_calls (target : Address) (memory : MemoryWords) (pointer countPointer : Word)
    (layout : Layout) (storage : Storage) (oracle : StaticOracle) (config : Config)
    (amount demand : Word) (isTopUp : Bool) (before middle : Transcript) (trace : MemoryTransportCall.Trace)
    (out : FinalMemoryStoredProducer.Output)
    (slot : FinalMemoryRows.slot pointer = .ok countPointer)
    (nonempty : (storage (countSlot layout)).val ≠ 0)
    (divided : checkedDiv amount config.maxEBType1 = .ok demand) (positive : demand.val > 0)
    (produced : CallTree.evaluate oracle (FinalMemoryStoredProducer.producer memory countPointer layout storage
      ⟨config,demand,isTopUp⟩) before = (.ok out,middle)) :
    (program target memory pointer layout storage oracle config amount isTopUp before trace).calls =
      trace ++ (middle.drop before.length).map MemoryTransportCall.staticEvent ++
        [MemoryTransportCall.event target out.memory out.allocationPointer.val out.capacityPointer.val demand] := by
  simp only [program,slot,nonempty,↓reduceIte,divided,produced]
  exact (afterProducer_trace target out (storage (countSlot layout)) config.maxEBType1 demand _).trans
    (if_pos positive)

/-- Universal full-trace shape, including every failure path: the supplied
prefix appears once, followed by this invocation's module suffix, followed by
at most one DELEGATECALL event. Conversion/allocation failure cannot erase it. -/
theorem trace_shape (target : Address) (memory : MemoryWords) (pointer : Word)
    (layout : Layout) (storage : Storage) (oracle : StaticOracle) (config : Config)
    (amount : Word) (isTopUp : Bool) (before : Transcript) (trace : MemoryTransportCall.Trace) :
    let run := program target memory pointer layout storage oracle config amount isTopUp before trace
    ∃ suffix, run.calls = trace ++ (run.modules.drop before.length).map MemoryTransportCall.staticEvent ++ suffix ∧
      suffix.length ≤ 1 ∧ ∀ event ∈ suffix, event.request.kind = MemoryTransportCall.Kind.delegateCall := by
  unfold program
  cases slot : FinalMemoryRows.slot pointer with
  | error reason => exact ⟨[],by simp,by simp,by simp⟩
  | ok countPointer =>
    simp only
    by_cases noModules : (storage (countSlot layout)).val = 0
    · simp only [noModules,↓reduceIte]
      exact ⟨[],by simp,by simp,by simp⟩
    · simp only [noModules,↓reduceIte]
      cases divided : checkedDiv amount config.maxEBType1 with
      | error reason => exact ⟨[],by simp,by simp,by simp⟩
      | ok demand =>
        simp only
        cases actual : CallTree.evaluate oracle
          (FinalMemoryStoredProducer.producer memory countPointer layout storage ⟨config,demand,isTopUp⟩) before with
        | mk result middle =>
          cases result with
          | error reason => exact ⟨[],by simp,by simp,by simp⟩
          | ok out =>
            simp only
            have shape := afterProducer_trace target out (storage (countSlot layout)) config.maxEBType1 demand
              (trace ++ (middle.drop before.length).map MemoryTransportCall.staticEvent)
            by_cases positive : demand.val > 0
            · simp only [positive,↓reduceIte] at shape
              refine ⟨[MemoryTransportCall.event target out.memory out.allocationPointer.val out.capacityPointer.val demand],shape,by simp,?_⟩
              intro event member
              simp only [List.mem_singleton] at member
              subst event
              rfl
            · simp only [positive,↓reduceIte] at shape
              exact ⟨[],by simpa using shape,by simp,by simp⟩

#print axioms projection
#print axioms public_iff
#print axioms success
#print axioms positive_calls
#print axioms trace_shape
end LidoSRv3.Audit.Source.TrioComposition.FinalMemoryStoredParent
