import LidoSRv3.Audit.Source.TrioComposition.ParentDeterminism
import LidoSRv3.Audit.Source.TrioAlloc2.ABIComposition

/-! Public wrapper with an executed canonical library ABI boundary. This composes
the byte model, not compiler memory or deployed library code. The remaining
allocation extent obligation is stated on actual reachable producer outcomes. -/
namespace LidoSRv3.Audit.Source.TrioComposition
open TrioAlloc1

def libraryThroughABI (output : CapacityOutput) (demand : Word) :
    Except Failure TrioAlloc2.StepOutput :=
  match TrioAlloc2.LibraryABI.run (TrioAlloc2.LibraryABI.encodeArguments
      (TrioAlloc2.producerArguments output demand)) with
  | .error bytes => .error (.revertData bytes)
  | .ok bytes => match TrioAlloc2.LibraryABI.decodeReturn bytes with
    | .error () => .error .decoderFailure
    | .ok result => .ok result

theorem producer_libraryThroughABI (layout : Layout) (storage : Storage) (oracle : StaticOracle)
    (input : CapacityInput) (before after : Transcript) (output : CapacityOutput)
    (executed : produce layout storage oracle input before = (.ok output, after))
    (extent : (TrioAlloc2.LibraryABI.encodeArguments
      (TrioAlloc2.producerArguments output input.depositsToAllocate)).length < 2^64) :
    libraryThroughABI output input.depositsToAllocate =
      libraryResult (TrioAlloc2.allocate output.allocations output.capacities input.depositsToAllocate) := by
  obtain ⟨result, ran, _, _, _⟩ := TrioAlloc2.producer_then_consumer_succeeds
    layout storage oracle input before after output executed
  have size := extent
  simp only [TrioAlloc2.producerArguments, TrioAlloc2.LibraryABI.encodeArguments,
    List.length_append, encodeWord_length, encodeArray_length] at size
  have resultBound : result.buckets.length < 2^64 := by
    rw [TrioAlloc2.allocate_preserves_length _ _ _ _ ran]
    omega
  unfold libraryThroughABI
  rw [TrioAlloc2.LibraryABI.run_encoded _ extent]
  change (match TrioAlloc2.LibraryABI.encodeOutcome
    (TrioAlloc2.allocate output.allocations output.capacities input.depositsToAllocate) with
    | .error bytes => Except.error (Failure.revertData bytes)
    | .ok bytes => match TrioAlloc2.LibraryABI.decodeReturn bytes with
      | .error () => Except.error Failure.decoderFailure
      | .ok result => Except.ok result : Except Failure TrioAlloc2.StepOutput) = _
  rw [ran]
  simp only [TrioAlloc2.LibraryABI.encodeOutcome,
    TrioAlloc2.LibraryABI.decodeReturn_encoded result resultBound, libraryResult]

def getDepositAllocationsABI (layout : Layout) (storage : Storage) (oracle : StaticOracle)
    (config : Config) (amount : Word) (isTopUp : Bool) : Execution ParentOutput := do
  let count := (storage (countSlot layout)).val
  if count = 0 then
    pure ⟨word 0, [], []⟩
  else
    let demand ← liftChecked (checkedDiv amount config.maxEBType1)
    let produced ← produce layout storage oracle ⟨config, demand, isTopUp⟩
    if demand.val > 0 then
      let result ← liftChecked (libraryThroughABI produced demand)
      let total ← liftChecked (checked (result.amount.val * config.maxEBType1.val))
      let (deltas, totals) ← liftChecked
        (convertPositive config.maxEBType1 count produced.allocations result.buckets)
      pure ⟨total, deltas, totals⟩
    else
      let (deltas, totals) ← liftChecked (convertZero config.maxEBType1 count produced.allocations)
      pure ⟨word 0, deltas, totals⟩

/-- Only a positive-demand producer outcome that is actually reached needs
the ABI extent bound. Empty enumeration, division failures, producer failures,
and the zero-demand branch do not require it. -/
def ReachableABIExtent (layout : Layout) (storage : Storage) (oracle : StaticOracle)
    (config : Config) (amount : Word) (isTopUp : Bool) (before : Transcript) : Prop :=
  ∀ demand output middle,
    checkedDiv amount config.maxEBType1 = .ok demand →
    produce layout storage oracle ⟨config, demand, isTopUp⟩ before = (.ok output, middle) →
    demand.val > 0 →
    (TrioAlloc2.LibraryABI.encodeArguments (TrioAlloc2.producerArguments output demand)).length < 2^64

theorem getDepositAllocationsABI_eq (layout : Layout) (storage : Storage) (oracle : StaticOracle)
    (config : Config) (amount : Word) (isTopUp : Bool) (before : Transcript)
    (extent : ReachableABIExtent layout storage oracle config amount isTopUp before) :
    getDepositAllocationsABI layout storage oracle config amount isTopUp before =
      getDepositAllocations layout storage oracle config amount isTopUp before := by
  by_cases empty : (storage (countSlot layout)).val = 0
  · simp [getDepositAllocationsABI, getDepositAllocations, empty]
  · simp only [getDepositAllocationsABI, getDepositAllocations, empty, ↓reduceIte,
      bind, bindExec, liftChecked]
    cases divEq : checkedDiv amount config.maxEBType1 with
    | error error => simp
    | ok demand =>
      simp only
      cases prodEq : produce layout storage oracle ⟨config, demand, isTopUp⟩ before with
      | mk produced middle =>
        cases produced with
        | error error => rfl
        | ok output =>
          by_cases positive : demand.val > 0
          · simp only [positive, ↓reduceIte]
            rw [producer_libraryThroughABI layout storage oracle ⟨config, demand, isTopUp⟩
              before middle output prodEq (extent demand output middle divEq prodEq positive)]
          · simp only [positive, ↓reduceIte]

/-- The independent all-outcome parent relation is unchanged by the executed
canonical ABI boundary, under the explicit reachable allocation obligation. -/
theorem public_abi_iff (layout : Layout) (storage : Storage) (oracle : StaticOracle)
    (config : Config) (amount : Word) (isTopUp : Bool) (before after : Transcript)
    (result : Except Failure ParentOutput)
    (extent : ReachableABIExtent layout storage oracle config amount isTopUp before) :
    ParentSpec.Public layout storage oracle config amount isTopUp before result after ↔
      getDepositAllocationsABI layout storage oracle config amount isTopUp before = (result, after) := by
  rw [getDepositAllocationsABI_eq layout storage oracle config amount isTopUp before extent]
  exact ParentSpec.public_iff _ _ _ _ _ _ _ _ _

#print axioms public_abi_iff
end LidoSRv3.Audit.Source.TrioComposition
