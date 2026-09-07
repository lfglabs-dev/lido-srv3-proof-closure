import audit.trio.alloc2.composition.Parent
import LidoSRv3.Audit.Source.TrioAlloc2.ParentValues

namespace LidoSRv3.Audit.Source.TrioAlloc2.Parent

private theorem liftResult_success (result : Result α) (out : α)
    (before after : TrioAlloc1.Transcript)
    (executed : liftResult result before = (.ok out, after)) :
    result = .ok out ∧ after = before := by
  cases result with
  | error reason => simp [liftResult, TrioAlloc1.liftChecked, Except.mapError] at executed
  | ok value =>
    simp only [liftResult, TrioAlloc1.liftChecked, Except.mapError, Prod.mk.injEq,
      Except.ok.injEq] at executed
    exact ⟨congrArg Except.ok executed.1, executed.2.symm⟩

/-- A successful actual parent return is the conversion of the actual producer
and consumer arrays. Consumer success is derived, not an input premise. -/
theorem successful_positive_conversion
    (layout : TrioAlloc1.Layout) (storage : TrioAlloc1.Storage) (oracle : TrioAlloc1.StaticOracle)
    (config : TrioAlloc1.Config) (amount demand : Word) (topup : Bool)
    (before middle after : TrioAlloc1.Transcript) (produced : TrioAlloc1.CapacityOutput)
    (out : ParentConversion.Output)
    (nonempty : (storage (TrioAlloc1.countSlot layout)).val ≠ 0)
    (divided : checkedDiv amount config.maxEBType1 = .ok demand)
    (positiveDemand : 0 < demand.val)
    (producer : TrioAlloc1.produce layout storage oracle ⟨config, demand, topup⟩ before = (.ok produced, middle))
    (executed : run layout storage oracle config amount topup before = (.ok out, after)) :
    ∃ allocated, allocate produced.allocations produced.capacities demand = .ok allocated ∧
      ParentConversion.positive (storage (TrioAlloc1.countSlot layout)).val config.maxEBType1
        allocated.amount ⟨produced.allocations, allocated.buckets⟩ = .ok out ∧ after = middle := by
  obtain ⟨allocated, consumer, _, _, _⟩ := producer_then_consumer_succeeds
    layout storage oracle ⟨config, demand, topup⟩ before middle produced producer
  have reduced : run layout storage oracle config amount topup before =
      liftResult (ParentConversion.positive (storage (TrioAlloc1.countSlot layout)).val config.maxEBType1
        allocated.amount ⟨produced.allocations, allocated.buckets⟩) middle := by
    simp [run, nonempty, liftResult, divided, producer, positiveDemand, consumer,
      TrioAlloc1.liftChecked, bind, TrioAlloc1.bindExec, Except.mapError, pure, TrioAlloc1.pureExec]
  rw [reduced] at executed
  exact ⟨allocated, consumer, liftResult_success _ _ _ _ executed⟩

/-- Zero demand preserves producer calls and performs conversion before return. -/
theorem successful_zero_conversion
    (layout : TrioAlloc1.Layout) (storage : TrioAlloc1.Storage) (oracle : TrioAlloc1.StaticOracle)
    (config : TrioAlloc1.Config) (amount : Word) (topup : Bool)
    (before middle after : TrioAlloc1.Transcript) (produced : TrioAlloc1.CapacityOutput)
    (out : ParentConversion.Output)
    (nonempty : (storage (TrioAlloc1.countSlot layout)).val ≠ 0)
    (divided : checkedDiv amount config.maxEBType1 = .ok zero)
    (producer : TrioAlloc1.produce layout storage oracle ⟨config, zero, topup⟩ before = (.ok produced, middle))
    (executed : run layout storage oracle config amount topup before = (.ok out, after)) :
    ParentConversion.zeroDemand (storage (TrioAlloc1.countSlot layout)).val config.maxEBType1
      produced.allocations = .ok out ∧ after = middle := by
  have reduced : run layout storage oracle config amount topup before =
      liftResult (ParentConversion.zeroDemand (storage (TrioAlloc1.countSlot layout)).val config.maxEBType1
        produced.allocations) middle := by
    simp only [run, nonempty, ↓reduceIte, liftResult, divided, producer,
      TrioAlloc1.liftChecked, bind, TrioAlloc1.bindExec, Except.mapError, pure, TrioAlloc1.pureExec]
    simp [zero, TrioAlloc1.liftChecked]
  rw [reduced] at executed
  exact liftResult_success _ _ _ _ executed

/-- The successful decoded parent returns an independent proportional
allocation converted to wei at every router index, with the producer transcript. -/
theorem successful_positive_postcondition
    (layout : TrioAlloc1.Layout) (storage : TrioAlloc1.Storage) (oracle : TrioAlloc1.StaticOracle)
    (config : TrioAlloc1.Config) (amount demand : Word) (topup : Bool)
    (before middle after : TrioAlloc1.Transcript) (produced : TrioAlloc1.CapacityOutput)
    (out : ParentConversion.Output)
    (nonempty : (storage (TrioAlloc1.countSlot layout)).val ≠ 0)
    (divided : checkedDiv amount config.maxEBType1 = .ok demand)
    (positiveDemand : 0 < demand.val)
    (producer : TrioAlloc1.produce layout storage oracle ⟨config, demand, topup⟩ before = (.ok produced, middle))
    (executed : run layout storage oracle config amount topup before = (.ok out, after)) :
    ∃ allocated : StepOutput,
      Spec.Distributes (decodedRows produced.allocations produced.capacities) demand.val allocated.amount.val
        (decodedRows allocated.buckets produced.capacities) ∧
      after = middle ∧ out.totalAllocated.val = allocated.amount.val*config.maxEBType1.val ∧
      ∀ j, j < (storage (TrioAlloc1.countSlot layout)).val →
        (out.arrays.allocated[j]?).map Fin.val =
          ((allocated.buckets[j]?).bind fun next =>
            (produced.allocations[j]?).map fun previous => (next.val-previous.val)*config.maxEBType1.val) ∧
        (out.arrays.newAllocations[j]?).map Fin.val =
          (allocated.buckets[j]?).map (fun w => w.val*config.maxEBType1.val) := by
  obtain ⟨allocated, consumer, converted, trace⟩ := successful_positive_conversion
    layout storage oracle config amount demand topup before middle after produced out
    nonempty divided positiveDemand producer executed
  have values := ParentConversion.positive_values _ _ _ _ _ converted
  exact ⟨allocated, allocate_refines _ _ _ _ consumer, trace, values⟩

theorem successful_zero_postcondition
    (layout : TrioAlloc1.Layout) (storage : TrioAlloc1.Storage) (oracle : TrioAlloc1.StaticOracle)
    (config : TrioAlloc1.Config) (amount : Word) (topup : Bool)
    (before middle after : TrioAlloc1.Transcript) (produced : TrioAlloc1.CapacityOutput)
    (out : ParentConversion.Output)
    (nonempty : (storage (TrioAlloc1.countSlot layout)).val ≠ 0)
    (divided : checkedDiv amount config.maxEBType1 = .ok zero)
    (producer : TrioAlloc1.produce layout storage oracle ⟨config, zero, topup⟩ before = (.ok produced, middle))
    (executed : run layout storage oracle config amount topup before = (.ok out, after)) :
    after = middle ∧ out.totalAllocated = zero ∧
      ∀ j, j < (storage (TrioAlloc1.countSlot layout)).val →
        out.arrays.allocated[j]? = some zero ∧
        (out.arrays.newAllocations[j]?).map Fin.val =
          (produced.allocations[j]?).map (fun w => w.val*config.maxEBType1.val) := by
  obtain ⟨converted, trace⟩ := successful_zero_conversion
    layout storage oracle config amount topup before middle after produced out
    nonempty divided producer executed
  exact ⟨trace, ParentConversion.zeroDemand_values _ _ _ _ converted⟩

#print axioms successful_positive_postcondition
#print axioms successful_zero_postcondition

#print axioms successful_positive_conversion
#print axioms successful_zero_conversion
end LidoSRv3.Audit.Source.TrioAlloc2.Parent
