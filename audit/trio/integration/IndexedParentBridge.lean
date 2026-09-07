import LidoSRv3.Audit.Source.TrioComposition.ParentABI
import LidoSRv3.Audit.Source.TrioComposition.ConversionBridge
import audit.trio.alloc2.composition.Parent

namespace LidoSRv3.Audit.Source.TrioComposition
open TrioAlloc1
open ConversionBridge

private theorem liftResult_eq (r : TrioAlloc2.Result α) :
    TrioAlloc2.Parent.liftResult r = liftChecked (libraryResult r) := by
  cases r with
  | ok x => rfl
  | error e => cases e <;> rfl

/-- Map only the decoded output representation, preserving every failure and
attempted module-call transcript of the indexed parent. -/
def indexedParent (layout : Layout) (storage : Storage) (oracle : StaticOracle)
    (config : Config) (amount : Word) (topup : Bool) (before : Transcript) :
    Except Failure ParentOutput × Transcript :=
  let result := TrioAlloc2.Parent.run layout storage oracle config amount topup before
  (result.1.map ConversionBridge.output, result.2)

theorem indexed_parent_eq (layout : Layout) (storage : Storage) (oracle : StaticOracle)
    (config : Config) (amount : Word) (topup : Bool) (before : Transcript) :
    indexedParent layout storage oracle config amount topup before =
      getDepositAllocations layout storage oracle config amount topup before := by
  unfold indexedParent TrioAlloc2.Parent.run getDepositAllocations
  simp only [liftResult_eq, div_bridge]
  by_cases empty : (storage (countSlot layout)).val = 0
  · simp [empty, pure, pureExec, ConversionBridge.output, TrioAlloc2.zero, word, Except.map]
  · simp only [empty, ↓reduceIte, bind, bindExec, pure, pureExec]
    cases divided : TrioAlloc1.checkedDiv amount config.maxEBType1 with
    | error reason => simp [divided, liftChecked, Except.map]
    | ok demand =>
      simp only [divided, liftChecked]
      cases produced : produce layout storage oracle ⟨config,demand,topup⟩ before with
      | mk result middle =>
        cases result with
        | error reason => simp [produced, Except.map]
        | ok capacity =>
          simp only [produced]
          by_cases positiveDemand : demand.val > 0
          · simp only [positiveDemand, ↓reduceIte]
            obtain ⟨allocated, consumed, _, _, _⟩ := TrioAlloc2.producer_then_consumer_succeeds
              layout storage oracle ⟨config,demand,topup⟩ before middle capacity produced
            simp only [consumed, libraryResult, liftChecked]
            have bridge := producer_consumer_conversion_equiv layout storage oracle
              ⟨config,demand,topup⟩ before middle capacity produced allocated consumed
            rw [libraryResult_map] at bridge
            cases total : checked (allocated.amount.val*config.maxEBType1.val) <;>
              cases rows : convertPositive config.maxEBType1 (storage (countSlot layout)).val
                capacity.allocations allocated.buckets <;>
              simpa [total, rows, bind, Except.bind, liftChecked, bindExec, pure, pureExec,
                libraryResult, Except.pure] using
                congrArg (fun r => (r, middle)) bridge
          · simp only [positiveDemand, ↓reduceIte]
            have length := (producer_length_from_storage layout storage oracle
              ⟨config,demand,topup⟩ before middle capacity produced).1
            have bridge := zero_conversion_equiv (storage (countSlot layout)).val
              config.maxEBType1 capacity.allocations length
            rw [libraryResult_map] at bridge
            cases rows : convertZero config.maxEBType1 (storage (countSlot layout)).val
                capacity.allocations <;>
              simpa [rows, bind, Except.bind, liftChecked, bindExec, pure, pureExec, Except.map] using
                congrArg (fun r => (r, middle)) bridge

/-- The indexed parent satisfies the same independent all-outcome relation. -/
theorem indexed_parent_iff (layout : Layout) (storage : Storage) (oracle : StaticOracle)
    (config : Config) (amount : Word) (topup : Bool) (before after : Transcript)
    (result : Except Failure ParentOutput) :
    ParentSpec.Public layout storage oracle config amount topup before result after ↔
      indexedParent layout storage oracle config amount topup before = (result, after) := by
  rw [indexed_parent_eq]
  exact ParentSpec.public_iff _ _ _ _ _ _ _ _ _

/-- Canonical ABI execution agrees under the explicit reachable byte extent. -/
theorem indexed_parent_abi_eq (layout : Layout) (storage : Storage) (oracle : StaticOracle)
    (config : Config) (amount : Word) (topup : Bool) (before : Transcript)
    (extent : ReachableABIExtent layout storage oracle config amount topup before) :
    indexedParent layout storage oracle config amount topup before =
      getDepositAllocationsABI layout storage oracle config amount topup before := by
  rw [indexed_parent_eq, getDepositAllocationsABI_eq _ _ _ _ _ _ _ extent]

#print axioms indexed_parent_iff
#print axioms indexed_parent_abi_eq

#print axioms indexed_parent_eq
end LidoSRv3.Audit.Source.TrioComposition
