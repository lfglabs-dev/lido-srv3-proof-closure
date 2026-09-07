import audit.trio.alloc2.composition.Parent
import LidoSRv3.Audit.Source.TrioAlloc2.ParentSuccess

namespace LidoSRv3.Audit.Source.TrioAlloc2.Parent

private theorem lift_success_iff (result : Result α) (trace : TrioAlloc1.Transcript) :
    (∃ out, liftResult result trace = (.ok out, trace)) ↔ ∃ out, result = .ok out := by
  cases result <;> simp [liftResult, TrioAlloc1.liftChecked, Except.mapError]

private theorem lift_arithmetic_iff (result : Result α) (trace : TrioAlloc1.Transcript) :
    liftResult result trace = (.error (.panic (TrioAlloc1.word 0x11)), trace) ↔
      result = .error .arithmetic := by
  cases result with
  | ok out => simp [liftResult, TrioAlloc1.liftChecked, Except.mapError]
  | error reason =>
    cases reason <;> simp [liftResult, TrioAlloc1.liftChecked, Except.mapError, TrioAlloc1.word]

/-- Actual producer lengths discharge the loop bounds, and actual division plus
allocation discharge total multiplication. Per-row representability is the exact
remaining success condition; its negation produces panic 0x11 with the producer trace. -/
theorem positive_success_and_error
    (layout : TrioAlloc1.Layout) (storage : TrioAlloc1.Storage) (oracle : TrioAlloc1.StaticOracle)
    (config : TrioAlloc1.Config) (amount demand : Word) (topup : Bool)
    (before middle : TrioAlloc1.Transcript) (produced : TrioAlloc1.CapacityOutput)
    (nonempty : (storage (TrioAlloc1.countSlot layout)).val ≠ 0)
    (divided : checkedDiv amount config.maxEBType1 = .ok demand)
    (positiveDemand : 0 < demand.val)
    (producer : TrioAlloc1.produce layout storage oracle ⟨config, demand, topup⟩ before = (.ok produced, middle)) :
    ∃ allocated, allocate produced.allocations produced.capacities demand = .ok allocated ∧
      ((∃ out, run layout storage oracle config amount topup before = (.ok out, middle)) ↔
        ParentConversion.PositiveRangeSafe (storage (TrioAlloc1.countSlot layout)).val 0
          config.maxEBType1 ⟨produced.allocations, allocated.buckets⟩) ∧
      (run layout storage oracle config amount topup before =
          (.error (.panic (TrioAlloc1.word 0x11)), middle) ↔
        ¬ ParentConversion.PositiveRangeSafe (storage (TrioAlloc1.countSlot layout)).val 0
          config.maxEBType1 ⟨produced.allocations, allocated.buckets⟩) := by
  obtain ⟨allocated, consumer, _, _, _⟩ := producer_then_consumer_succeeds
    layout storage oracle ⟨config, demand, topup⟩ before middle produced producer
  have lengths := TrioAlloc1.producer_length_from_storage
    layout storage oracle ⟨config, demand, topup⟩ before middle produced producer
  have preserved := allocate_preserves_length _ _ _ _ consumer
  obtain ⟨scaled, multiplied, _⟩ := ParentConversion.allocated_total_mul_success
    amount config.maxEBType1 demand produced.allocations produced.capacities allocated divided consumer
  have totalSafe : allocated.amount.val*config.maxEBType1.val < 2^256 := by
    rw [← checkedMul_value _ _ _ multiplied]
    exact scaled.isLt
  have reduced : run layout storage oracle config amount topup before =
      liftResult (ParentConversion.positive (storage (TrioAlloc1.countSlot layout)).val config.maxEBType1
        allocated.amount ⟨produced.allocations, allocated.buckets⟩) middle := by
    simp [run, nonempty, liftResult, divided, producer, positiveDemand, consumer,
      TrioAlloc1.liftChecked, bind, TrioAlloc1.bindExec, Except.mapError, pure, TrioAlloc1.pureExec]
  refine ⟨allocated, consumer, ?_, ?_⟩
  · rw [reduced, lift_success_iff, ParentConversion.positive_success_iff]
    · simp [totalSafe]
    · change (storage (TrioAlloc1.countSlot layout)).val ≤ produced.allocations.length; omega
    · change (storage (TrioAlloc1.countSlot layout)).val ≤ allocated.buckets.length; omega
  · rw [reduced, lift_arithmetic_iff, ParentConversion.positive_arithmetic_iff]
    · simp [totalSafe]
    · change (storage (TrioAlloc1.countSlot layout)).val ≤ produced.allocations.length; omega
    · change (storage (TrioAlloc1.countSlot layout)).val ≤ allocated.buckets.length; omega

/-- Zero demand still uses every actual producer allocation in the overflow condition. -/
theorem zero_success_and_error
    (layout : TrioAlloc1.Layout) (storage : TrioAlloc1.Storage) (oracle : TrioAlloc1.StaticOracle)
    (config : TrioAlloc1.Config) (amount : Word) (topup : Bool)
    (before middle : TrioAlloc1.Transcript) (produced : TrioAlloc1.CapacityOutput)
    (nonempty : (storage (TrioAlloc1.countSlot layout)).val ≠ 0)
    (divided : checkedDiv amount config.maxEBType1 = .ok zero)
    (producer : TrioAlloc1.produce layout storage oracle ⟨config, zero, topup⟩ before = (.ok produced, middle)) :
    ((∃ out, run layout storage oracle config amount topup before = (.ok out, middle)) ↔
      ParentConversion.ZeroRangeSafe (storage (TrioAlloc1.countSlot layout)).val 0
        config.maxEBType1 produced.allocations) ∧
    (run layout storage oracle config amount topup before =
        (.error (.panic (TrioAlloc1.word 0x11)), middle) ↔
      ¬ ParentConversion.ZeroRangeSafe (storage (TrioAlloc1.countSlot layout)).val 0
        config.maxEBType1 produced.allocations) := by
  have lengths := TrioAlloc1.producer_length_from_storage
    layout storage oracle ⟨config, zero, topup⟩ before middle produced producer
  have reduced : run layout storage oracle config amount topup before =
      liftResult (ParentConversion.zeroDemand (storage (TrioAlloc1.countSlot layout)).val config.maxEBType1
        produced.allocations) middle := by
    simp only [run, nonempty, ↓reduceIte, liftResult, divided, producer,
      TrioAlloc1.liftChecked, bind, TrioAlloc1.bindExec, Except.mapError, pure, TrioAlloc1.pureExec]
    simp [zero, TrioAlloc1.liftChecked]
  constructor
  · rw [reduced, lift_success_iff, ParentConversion.zeroDemand_success_iff]
    omega
  · rw [reduced, lift_arithmetic_iff, ParentConversion.zeroDemand_arithmetic_iff]
    omega

#print axioms positive_success_and_error
#print axioms zero_success_and_error
end LidoSRv3.Audit.Source.TrioAlloc2.Parent
