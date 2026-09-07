import LidoSRv3.Audit.Source.TrioComposition.ParentCalls
import LidoSRv3.Audit.Source.TrioComposition.MemoryGuard

/-! Parent call tree with the modeled allocation prefix between division and
producer calls. Pointer provenance, compiler scheduling, memory stores and gas
remain explicit boundaries; this module proves this composition's behavior. -/
namespace LidoSRv3.Audit.Source.TrioComposition.AllocationParentCalls
open TrioAlloc1

def program (pointer : Word) (layout : Layout) (storage : Storage) (config : Config)
    (amount : Word) (isTopUp : Bool) : CallTree.Program ParentOutput := do
  let count := storage (countSlot layout)
  if count.val = 0 then
    pure ⟨word 0, [], []⟩
  else
    let demand ← CallTree.check (checkedDiv amount config.maxEBType1)
    let _ ← CallTree.check (MemoryGuard.check pointer count)
    ParentCalls.afterDivision layout storage config demand isTopUp

theorem successful_prefix (pointer : Word) (layout : Layout) (storage : Storage)
    (config : Config) (amount : Word) (isTopUp : Bool) (next : Word)
    (success : MemoryGuard.check pointer (storage (countSlot layout)) = .ok next) :
    program pointer layout storage config amount isTopUp =
      ParentCalls.program layout storage config amount isTopUp := by
  unfold program ParentCalls.program
  by_cases empty : (storage (countSlot layout)).val = 0
  · simp [empty]
  · simp only [empty, ↓reduceIte]
    cases divided : checkedDiv amount config.maxEBType1 <;>
      simp [divided, success, CallTree.check, bind, CallTree.bind]

theorem division_failure (pointer : Word) (layout : Layout) (storage : Storage)
    (config : Config) (amount : Word) (isTopUp : Bool) (reason : Failure)
    (nonempty : (storage (countSlot layout)).val ≠ 0)
    (divided : checkedDiv amount config.maxEBType1 = .error reason) :
    program pointer layout storage config amount isTopUp = .done (.error reason) := by
  simp [program, nonempty, divided, CallTree.check, bind, CallTree.bind]

theorem memory_failure (pointer : Word) (layout : Layout) (storage : Storage)
    (config : Config) (amount : Word) (isTopUp : Bool) (demand : Word) (reason : Failure)
    (nonempty : (storage (countSlot layout)).val ≠ 0)
    (divided : checkedDiv amount config.maxEBType1 = .ok demand)
    (failed : MemoryGuard.check pointer (storage (countSlot layout)) = .error reason) :
    program pointer layout storage config amount isTopUp = .done (.error reason) := by
  simp [program, nonempty, divided, failed, CallTree.check, bind, CallTree.bind]

theorem successful_prefix_correspondence (pointer : Word) (layout : Layout) (storage : Storage)
    (oracle : StaticOracle) (config : Config) (amount : Word) (isTopUp : Bool) (next : Word)
    (success : MemoryGuard.check pointer (storage (countSlot layout)) = .ok next) :
    CallTree.evaluate oracle (program pointer layout storage config amount isTopUp) =
      getDepositAllocationsABI layout storage oracle config amount isTopUp := by
  rw [successful_prefix pointer layout storage config amount isTopUp next success,
    ParentCalls.correspondence]

/-- Prefix success derives the canonical byte extent for every reached producer
success. No module-count or separate packet-size hypothesis is supplied. -/
theorem successful_prefix_extent (pointer : Word) (layout : Layout) (storage : Storage)
    (oracle : StaticOracle) (config : Config) (amount : Word) (isTopUp : Bool) (next : Word) (before : Transcript)
    (success : MemoryGuard.check pointer (storage (countSlot layout)) = .ok next) :
    ReachableABIExtent layout storage oracle config amount isTopUp before := by
  intro demand produced middle _ producer _
  rw [MemoryGuard.check_eq] at success
  cases memory : TrioAlloc2.MemoryPrefix.execute pointer (storage (countSlot layout)) with
  | error reason => simp [memory, Except.mapError] at success
  | ok actual =>
    have extent := TrioAlloc2.MemoryPrefix.execute_extent _ _ _ memory
    have lengths := producer_length_from_storage layout storage oracle
      ⟨config,demand,isTopUp⟩ before middle produced producer
    simp only [TrioAlloc2.LibraryABI.encodeArguments, TrioAlloc2.producerArguments,
      List.length_append, encodeWord_length, encodeArray_length]
    omega

#print axioms successful_prefix_extent

#print axioms successful_prefix_correspondence
#print axioms division_failure
#print axioms memory_failure
end LidoSRv3.Audit.Source.TrioComposition.AllocationParentCalls
