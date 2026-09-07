import audit.trio.alloc2.composition.ParentErrors
import audit.trio.alloc2.composition.ParentPostconditions

namespace LidoSRv3.Audit.Source.TrioAlloc2.Parent

/-- Every producer failure propagates before allocation or conversion, preserving
its exact failure value and attempted-call transcript. -/
theorem producer_failure_propagates
    (layout : TrioAlloc1.Layout) (storage : TrioAlloc1.Storage) (oracle : TrioAlloc1.StaticOracle)
    (config : TrioAlloc1.Config) (amount demand : Word) (topup : Bool)
    (before after : TrioAlloc1.Transcript) (failure : TrioAlloc1.Failure)
    (nonempty : (storage (TrioAlloc1.countSlot layout)).val ≠ 0)
    (divided : checkedDiv amount config.maxEBType1 = .ok demand)
    (producer : TrioAlloc1.produce layout storage oracle ⟨config, demand, topup⟩ before = (.error failure, after)) :
    run layout storage oracle config amount topup before = (.error failure, after) := by
  simp [run, nonempty, liftResult, divided, producer, TrioAlloc1.liftChecked,
    bind, TrioAlloc1.bindExec, Except.mapError, pure, TrioAlloc1.pureExec]

/-- Success at a nonempty parent entry implies successful actual division and
producer execution. Neither is assumed as a premise of this inversion. -/
theorem success_reaches_producer
    (layout : TrioAlloc1.Layout) (storage : TrioAlloc1.Storage) (oracle : TrioAlloc1.StaticOracle)
    (config : TrioAlloc1.Config) (amount : Word) (topup : Bool)
    (before after : TrioAlloc1.Transcript) (out : ParentConversion.Output)
    (nonempty : (storage (TrioAlloc1.countSlot layout)).val ≠ 0)
    (executed : run layout storage oracle config amount topup before = (.ok out, after)) :
    ∃ demand produced middle,
      checkedDiv amount config.maxEBType1 = .ok demand ∧
      TrioAlloc1.produce layout storage oracle ⟨config, demand, topup⟩ before = (.ok produced, middle) := by
  cases divided : checkedDiv amount config.maxEBType1 with
  | error reason =>
    simp [run, nonempty, liftResult, divided, TrioAlloc1.liftChecked,
      bind, TrioAlloc1.bindExec, Except.mapError, pure, TrioAlloc1.pureExec] at executed
  | ok demand =>
    cases producer : TrioAlloc1.produce layout storage oracle ⟨config, demand, topup⟩ before with
    | mk result middle =>
      cases result with
      | error reason =>
        rw [producer_failure_propagates layout storage oracle config amount demand topup
          before middle reason nonempty divided producer] at executed
        cases executed
      | ok produced => exact ⟨demand, produced, middle, rfl, producer⟩

private theorem after_producer_failure_kind
    (layout : TrioAlloc1.Layout) (storage : TrioAlloc1.Storage) (oracle : TrioAlloc1.StaticOracle)
    (config : TrioAlloc1.Config) (amount demand : Word) (topup : Bool)
    (before middle after : TrioAlloc1.Transcript) (produced : TrioAlloc1.CapacityOutput)
    (failure : TrioAlloc1.Failure)
    (nonempty : (storage (TrioAlloc1.countSlot layout)).val ≠ 0)
    (divided : checkedDiv amount config.maxEBType1 = .ok demand)
    (producer : TrioAlloc1.produce layout storage oracle ⟨config, demand, topup⟩ before = (.ok produced, middle))
    (executed : run layout storage oracle config amount topup before = (.error failure, after)) :
    failure = .panic (TrioAlloc1.word 0x11) ∧ after = middle := by
  have exactError : run layout storage oracle config amount topup before =
      (.error (.panic (TrioAlloc1.word 0x11)), middle) := by
    by_cases positive : 0 < demand.val
    · obtain ⟨allocated, _, success, failureIff⟩ := positive_success_and_error
        layout storage oracle config amount demand topup before middle produced
        nonempty divided positive producer
      apply failureIff.mpr
      intro safe
      obtain ⟨value, ok⟩ := success.mpr safe
      rw [executed] at ok
      cases ok
    · have zeroDemand : demand = zero := Fin.ext (by have := demand.isLt; simp only [zero]; omega)
      subst demand
      obtain ⟨success, failureIff⟩ := zero_success_and_error
        layout storage oracle config amount topup before middle produced nonempty divided producer
      apply failureIff.mpr
      intro safe
      obtain ⟨value, ok⟩ := success.mpr safe
      rw [executed] at ok
      cases ok
  rw [executed] at exactError
  simpa only [Prod.mk.injEq, Except.error.injEq] using exactError

/-- Complete failure classification for the decoded parent. Producer
success and division success are conclusions when appropriate, not global
premises. This does not classify additional compiler-memory or gas failures. -/
theorem failure_classification
    (layout : TrioAlloc1.Layout) (storage : TrioAlloc1.Storage) (oracle : TrioAlloc1.StaticOracle)
    (config : TrioAlloc1.Config) (amount : Word) (topup : Bool)
    (before after : TrioAlloc1.Transcript) (failure : TrioAlloc1.Failure)
    (executed : run layout storage oracle config amount topup before = (.error failure, after)) :
    (config.maxEBType1.val = 0 ∧ failure = .panic (TrioAlloc1.word 0x12) ∧ after = before) ∨
    ∃ demand, checkedDiv amount config.maxEBType1 = .ok demand ∧
      (TrioAlloc1.produce layout storage oracle ⟨config, demand, topup⟩ before = (.error failure, after) ∨
        ∃ produced, TrioAlloc1.produce layout storage oracle ⟨config, demand, topup⟩ before = (.ok produced, after) ∧
          failure = .panic (TrioAlloc1.word 0x11)) := by
  have nonempty : (storage (TrioAlloc1.countSlot layout)).val ≠ 0 := by
    intro empty
    rw [empty_before_division layout storage oracle config amount topup before empty] at executed
    cases executed
  by_cases zeroUnit : config.maxEBType1.val = 0
  · have actual := zero_divisor_before_producer layout storage oracle config amount topup before nonempty zeroUnit
    rw [executed] at actual
    exact Or.inl ⟨zeroUnit, by simpa only [Prod.mk.injEq, Except.error.injEq] using actual⟩
  · let demand : Word := ⟨amount.val / config.maxEBType1.val,
      Nat.lt_of_le_of_lt (Nat.div_le_self ..) amount.isLt⟩
    have divided : checkedDiv amount config.maxEBType1 = .ok demand := by
      simp [checkedDiv, zeroUnit, demand]
    refine Or.inr ⟨demand, divided, ?_⟩
    cases producer : TrioAlloc1.produce layout storage oracle ⟨config, demand, topup⟩ before with
    | mk result middle =>
      cases result with
      | error reason =>
        have actual := producer_failure_propagates layout storage oracle config amount demand topup
          before middle reason nonempty divided producer
        rw [executed] at actual
        have equal : failure = reason ∧ after = middle := by
          simpa only [Prod.mk.injEq, Except.error.injEq] using actual
        rcases equal with ⟨rfl, rfl⟩
        exact Or.inl rfl
      | ok produced =>
        obtain ⟨kind, trace⟩ := after_producer_failure_kind layout storage oracle config amount demand topup
          before middle after produced failure nonempty divided producer executed
        subst after
        exact Or.inr ⟨produced, rfl, kind⟩

/-- The producer reached by a successful nonempty parent has exactly the final
attempted-call transcript; it establishes the consumer premises itself. -/
theorem success_establishes_consumer_premises
    (layout : TrioAlloc1.Layout) (storage : TrioAlloc1.Storage) (oracle : TrioAlloc1.StaticOracle)
    (config : TrioAlloc1.Config) (amount : Word) (topup : Bool)
    (before after : TrioAlloc1.Transcript) (out : ParentConversion.Output)
    (nonempty : (storage (TrioAlloc1.countSlot layout)).val ≠ 0)
    (executed : run layout storage oracle config amount topup before = (.ok out, after)) :
    ∃ demand produced,
      checkedDiv amount config.maxEBType1 = .ok demand ∧
      TrioAlloc1.produce layout storage oracle ⟨config, demand, topup⟩ before = (.ok produced, after) ∧
      DecodedConsumerPremises produced := by
  obtain ⟨demand, produced, middle, divided, producer⟩ := success_reaches_producer
    layout storage oracle config amount topup before after out nonempty executed
  have trace : after = middle := by
    by_cases positive : 0 < demand.val
    · obtain ⟨_, _, _, trace⟩ := successful_positive_conversion
        layout storage oracle config amount demand topup before middle after produced out
        nonempty divided positive producer executed
      exact trace
    · have zeroDemand : demand = zero := Fin.ext (by simp only [zero]; omega)
      subst demand
      exact (successful_zero_conversion layout storage oracle config amount topup before middle after
        produced out nonempty divided producer executed).2
  subst after
  exact ⟨demand, produced, divided, producer, producer_success_establishes_consumer_premises
    layout storage oracle ⟨config, demand, topup⟩ before middle produced producer⟩

/-- Complete success split, including the empty branch that bypasses division. -/
theorem success_classification
    (layout : TrioAlloc1.Layout) (storage : TrioAlloc1.Storage) (oracle : TrioAlloc1.StaticOracle)
    (config : TrioAlloc1.Config) (amount : Word) (topup : Bool)
    (before after : TrioAlloc1.Transcript) (out : ParentConversion.Output)
    (executed : run layout storage oracle config amount topup before = (.ok out, after)) :
    ((storage (TrioAlloc1.countSlot layout)).val = 0 ∧ out = ⟨zero, ⟨[], []⟩⟩ ∧ after = before) ∨
    ∃ demand produced,
      checkedDiv amount config.maxEBType1 = .ok demand ∧
      TrioAlloc1.produce layout storage oracle ⟨config, demand, topup⟩ before = (.ok produced, after) ∧
      DecodedConsumerPremises produced := by
  by_cases empty : (storage (TrioAlloc1.countSlot layout)).val = 0
  · have actual := empty_before_division layout storage oracle config amount topup before empty
    rw [executed] at actual
    exact Or.inl ⟨empty, by simpa only [Prod.mk.injEq, Except.ok.injEq] using actual⟩
  · exact Or.inr (success_establishes_consumer_premises layout storage oracle config amount topup
      before after out empty executed)

#print axioms success_classification

#print axioms success_establishes_consumer_premises

#print axioms producer_failure_propagates
#print axioms success_reaches_producer
#print axioms failure_classification
end LidoSRv3.Audit.Source.TrioAlloc2.Parent
