import audit.trio.alloc2.composition.Composition
import LidoSRv3.Audit.Source.TrioAlloc1.Memory
import LidoSRv3.Audit.Source.TrioAlloc2.ParentArraySafety

/-! Decoded parent execution with the actual producer, preserving the count guard,
division, producer calls, allocation and both conversion branches. The byte-copy
and compiler/physical-memory relation remain explicit integration obligations. -/
namespace LidoSRv3.Audit.Source.TrioAlloc2.Parent

def liftResult (result : Result α) : TrioAlloc1.Execution α :=
  TrioAlloc1.liftChecked (result.mapError fun reason =>
    TrioAlloc1.Failure.panic (TrioAlloc1.word (match reason with
      | .arithmetic => 0x11 | .divisionByZero => 0x12 | .arrayBounds => 0x32)))

def run (layout : TrioAlloc1.Layout) (storage : TrioAlloc1.Storage)
    (oracle : TrioAlloc1.StaticOracle) (config : TrioAlloc1.Config) (amount : Word)
    (topup : Bool) : TrioAlloc1.Execution ParentConversion.Output := do
  let count := storage (TrioAlloc1.countSlot layout)
  if count.val = 0 then return ⟨zero, ⟨[], []⟩⟩
  let demand ← liftResult (checkedDiv amount config.maxEBType1)
  let produced ← TrioAlloc1.produce layout storage oracle ⟨config, demand, topup⟩
  if demand.val > 0 then
    let allocated ← liftResult (allocate produced.allocations produced.capacities demand)
    liftResult (ParentConversion.positive count.val config.maxEBType1 allocated.amount
      ⟨produced.allocations, allocated.buckets⟩)
  else
    liftResult (ParentConversion.zeroDemand count.val config.maxEBType1 produced.allocations)

theorem empty_before_division (layout : TrioAlloc1.Layout) (storage : TrioAlloc1.Storage)
    (oracle : TrioAlloc1.StaticOracle) (config : TrioAlloc1.Config) (amount : Word)
    (topup : Bool) (before : TrioAlloc1.Transcript)
    (empty : (storage (TrioAlloc1.countSlot layout)).val = 0) :
    run layout storage oracle config amount topup before = (.ok ⟨zero, ⟨[], []⟩⟩, before) := by
  simp [run, empty, pure, TrioAlloc1.pureExec]

theorem zero_divisor_before_producer (layout : TrioAlloc1.Layout) (storage : TrioAlloc1.Storage)
    (oracle : TrioAlloc1.StaticOracle) (config : TrioAlloc1.Config) (amount : Word)
    (topup : Bool) (before : TrioAlloc1.Transcript)
    (nonempty : (storage (TrioAlloc1.countSlot layout)).val ≠ 0)
    (zeroUnit : config.maxEBType1.val = 0) :
    run layout storage oracle config amount topup before =
      (.error (.panic (TrioAlloc1.word 0x12)), before) := by
  simp [run, nonempty, liftResult, checkedDiv, zeroUnit, Except.mapError,
    TrioAlloc1.liftChecked, bind, TrioAlloc1.bindExec, pure, TrioAlloc1.pureExec]

/-- The actual producer and consumer establish every bound needed by the
positive conversion loop; only arithmetic failures remain possible there. -/
theorem producer_positive_arrays_safe (layout : TrioAlloc1.Layout) (storage : TrioAlloc1.Storage)
    (oracle : TrioAlloc1.StaticOracle) (input : TrioAlloc1.CapacityInput)
    (before after : TrioAlloc1.Transcript) (produced : TrioAlloc1.CapacityOutput)
    (out : StepOutput) (unit : Word)
    (producer : TrioAlloc1.produce layout storage oracle input before = (.ok produced, after))
    (consumer : allocate produced.allocations produced.capacities input.depositsToAllocate = .ok out) :
    ParentConversion.ArrayResultSafe produced.allocations.length out.buckets.length
      (ParentConversion.positiveRows (storage (TrioAlloc1.countSlot layout)).val 0 unit
        ⟨produced.allocations, out.buckets⟩) := by
  have lengths := TrioAlloc1.producer_length_from_storage layout storage oracle input before after produced producer
  have preserved := allocate_preserves_length _ _ _ _ consumer
  apply ParentConversion.positiveRows_array_safe <;> simp only [Nat.zero_add] <;> omega

/-- Zero demand still visits every producer row; its fresh result array has
exactly that count, so any conversion failure is arithmetic rather than bounds. -/
theorem producer_zero_arrays_safe (layout : TrioAlloc1.Layout) (storage : TrioAlloc1.Storage)
    (oracle : TrioAlloc1.StaticOracle) (input : TrioAlloc1.CapacityInput)
    (before after : TrioAlloc1.Transcript) (produced : TrioAlloc1.CapacityOutput) (unit : Word)
    (producer : TrioAlloc1.produce layout storage oracle input before = (.ok produced, after)) :
    ParentConversion.ArrayResultSafe produced.allocations.length (storage (TrioAlloc1.countSlot layout)).val
      (ParentConversion.zeroRows (storage (TrioAlloc1.countSlot layout)).val 0 unit
        ⟨produced.allocations, List.replicate (storage (TrioAlloc1.countSlot layout)).val zero⟩) := by
  have lengths := TrioAlloc1.producer_length_from_storage layout storage oracle input before after produced producer
  simpa only [List.length_replicate] using ParentConversion.zeroRows_array_safe
    (storage (TrioAlloc1.countSlot layout)).val 0 unit
    ⟨produced.allocations, List.replicate (storage (TrioAlloc1.countSlot layout)).val zero⟩
    (by simp only [Nat.zero_add]; omega) (by simp)

#print axioms producer_positive_arrays_safe
#print axioms producer_zero_arrays_safe

#print axioms empty_before_division
#print axioms zero_divisor_before_producer
end LidoSRv3.Audit.Source.TrioAlloc2.Parent
