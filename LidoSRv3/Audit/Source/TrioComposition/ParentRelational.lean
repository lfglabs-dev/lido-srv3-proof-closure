import LidoSRv3.Audit.Source.TrioComposition.ParentComposition
import LidoSRv3.Audit.Source.TrioAlloc1.Relational

/-!
All-outcome relational specification of the decoded public allocation wrapper.
Relations use independent mathematical arithmetic and proportional distribution;
they do not call the public executor, conversion loops or proportional executor.
Module calls are interpreted by the producer relation. Library DELEGATECALL/ABI,
compiler memory and the deployment/world relation remain separate obligations.
-/
namespace LidoSRv3.Audit.Source.TrioComposition.ParentSpec
open TrioAlloc1 TrioAlloc1.Relational

/-- Bind refinement restricted to successors actually reached by the first action.
This discharges consumer bounds from producer execution rather than assuming them
for arbitrary synthetic CapacityOutput values. -/
theorem bind_sound_reachable (action : Execution α) (next : α → Execution β)
    (first : Step α) (rest : α → Step β) (ha : Satisfies action first)
    (hb : ∀ before value middle, action before = (.ok value, middle) →
      rest value middle (next value middle).1 (next value middle).2) :
    Satisfies (bindExec action next) (Then first rest) := by
  intro before
  have h := ha before
  cases he : action before with
  | mk result middle =>
    rw [he] at h
    cases result with
    | error e => simpa only [bindExec, he] using Then.error (next := rest) h
    | ok value => simpa only [bindExec, he] using Then.ok h (hb before value middle he)

def Head (values : List Word) : Step Word :=
  match values with
  | [] => Abort (.panic (word 0x32))
  | value :: _ => Done value

theorem head_sound (values : List Word) :
    Satisfies (liftChecked (readHead values)) (Head values) := by
  cases values with
  | nil => exact abort_sound _
  | cons value values => exact pure_sound _

/-- Sequence of independent row checks. An error ends the sequence before any
later row or later arithmetic check is observed. -/
def Positive (unit : Word) : Nat → List Word → List Word → Step (List Word × List Word)
  | 0, _, _ => Done ([], [])
  | n+1, old, fresh => Then (Head fresh) fun next =>
      Then (Head old) fun previous =>
        Then (Check (ActiveResult next previous.val)) fun delta =>
          Then (Check (WordResult (delta.val * unit.val))) fun deltaWei =>
            Then (Check (WordResult (next.val * unit.val))) fun nextWei =>
              Then (Positive unit n old.tail fresh.tail) fun (deltas, totals) =>
                Done (deltaWei :: deltas, nextWei :: totals)

def Zero (unit : Word) : Nat → List Word → Step (List Word × List Word)
  | 0, _ => Done ([], [])
  | n+1, old => Then (Head old) fun previous =>
      Then (Check (WordResult (previous.val * unit.val))) fun previousWei =>
        Then (Zero unit n old.tail) fun (deltas, totals) =>
          Done (word 0 :: deltas, previousWei :: totals)

theorem positive_sound (unit : Word) (count : Nat) (old fresh : List Word) :
    Satisfies (liftChecked (convertPositive unit count old fresh)) (Positive unit count old fresh) := by
  induction count generalizing old fresh with
  | zero => exact pure_sound _
  | succ count ih =>
    simp only [convertPositive, Positive]
    apply except_bind_sound
    · exact head_sound fresh
    · intro next
      apply except_bind_sound
      · exact head_sound old
      · intro previous
        apply except_bind_sound
        · exact active_sound next previous.val
        · intro delta
          apply except_bind_sound
          · exact word_sound _
          · intro deltaWei
            apply except_bind_sound
            · exact word_sound _
            · intro nextWei
              exact except_bind_sound _ _ _ _ (ih old.tail fresh.tail) (fun _ => pure_sound _)

theorem zero_sound (unit : Word) (count : Nat) (old : List Word) :
    Satisfies (liftChecked (convertZero unit count old)) (Zero unit count old) := by
  induction count generalizing old with
  | zero => exact pure_sound _
  | succ count ih =>
    simp only [convertZero, Zero]
    apply except_bind_sound
    · exact head_sound old
    · intro previous
      apply except_bind_sound
      · exact word_sound _
      · intro previousWei
        exact except_bind_sound _ _ _ _ (ih old.tail) (fun _ => pure_sound _)

/-- The mathematical consumer relation excludes errors on actual producer outputs.
The equal-length and representability obligations are proved at the call site. -/
def Consumer (output : CapacityOutput) (demand : Word)
    (result : Except Failure TrioAlloc2.StepOutput) : Prop :=
  ∃ value, result = .ok value ∧
    TrioAlloc2.Spec.Distributes (TrioAlloc2.decodedRows output.allocations output.capacities)
      demand.val value.amount.val (TrioAlloc2.decodedRows value.buckets output.capacities) ∧
    value.amount.val ≤ demand.val ∧ value.buckets.length = output.allocations.length

theorem consumer_sound (output : CapacityOutput) (demand : Word)
    (bounded : output.allocations.length < 2^256) :
    Satisfies (liftChecked (libraryResult (TrioAlloc2.allocate output.allocations output.capacities demand)))
      (Check (Consumer output demand)) := by
  obtain ⟨result, run⟩ := TrioAlloc2.allocate_success output.allocations output.capacities demand
    (Nat.le_of_eq (output_lengths_equal output)) bounded
  apply check_sound
  exact ⟨result, by simp [libraryResult, run], TrioAlloc2.allocate_refines _ _ _ _ run,
    TrioAlloc2.allocate_amount_le_demand _ _ _ _ run, TrioAlloc2.allocate_preserves_length _ _ _ _ run⟩

def FinishPositive (output : CapacityOutput) (demand unit : Word) (count : Nat) : Step ParentOutput :=
  Then (Check (Consumer output demand)) fun result =>
    Then (Check (WordResult (result.amount.val * unit.val))) fun total =>
      Then (Positive unit count output.allocations result.buckets) fun (deltas, totals) =>
        Done ⟨total, deltas, totals⟩

def FinishZero (output : CapacityOutput) (unit : Word) (count : Nat) : Step ParentOutput :=
  Then (Zero unit count output.allocations) fun (deltas, totals) =>
    Done ⟨word 0, deltas, totals⟩

theorem finishPositive_sound (output : CapacityOutput) (demand unit : Word) (count : Nat)
    (bounded : output.allocations.length < 2^256) :
    Satisfies (do
      let result ← liftChecked (libraryResult (TrioAlloc2.allocate output.allocations output.capacities demand))
      let total ← liftChecked (checked (result.amount.val * unit.val))
      let (deltas, totals) ← liftChecked (convertPositive unit count output.allocations result.buckets)
      pure (ParentOutput.mk total deltas totals)) (FinishPositive output demand unit count) := by
  exact bind_sound _ _ _ _ (consumer_sound output demand bounded) (fun result =>
    bind_sound _ _ _ _ (word_sound _) (fun total =>
      bind_sound _ _ _ _ (positive_sound unit count output.allocations result.buckets) (fun _ => pure_sound _)))

theorem finishZero_sound (output : CapacityOutput) (unit : Word) (count : Nat) :
    Satisfies (do
      let (deltas, totals) ← liftChecked (convertZero unit count output.allocations)
      pure (ParentOutput.mk (word 0) deltas totals)) (FinishZero output unit count) := by
  exact bind_sound _ _ _ _ (zero_sound unit count output.allocations) (fun _ => pure_sound _)

def Public (layout : Layout) (storage : Storage) (oracle : StaticOracle)
    (config : Config) (amount : Word) (isTopUp : Bool) : Step ParentOutput :=
  let count := (storage (countSlot layout)).val
  if count = 0 then Done ⟨word 0, [], []⟩
  else Then (Check (DivisionResult amount config.maxEBType1)) fun demand =>
    Then (Producer layout storage oracle ⟨config, demand, isTopUp⟩) fun output =>
      if demand.val > 0 then FinishPositive output demand config.maxEBType1 count
      else FinishZero output config.maxEBType1 count

theorem public_sound (layout : Layout) (storage : Storage) (oracle : StaticOracle)
    (config : Config) (amount : Word) (isTopUp : Bool) :
    Satisfies (getDepositAllocations layout storage oracle config amount isTopUp)
      (Public layout storage oracle config amount isTopUp) := by
  unfold getDepositAllocations Public
  by_cases empty : (storage (countSlot layout)).val = 0
  · simpa only [empty, ↓reduceIte, pure] using pure_sound (ParentOutput.mk (word 0) [] [])
  · simp only [empty, ↓reduceIte]
    apply bind_sound
    · exact division_sound amount config.maxEBType1
    · intro demand
      apply bind_sound_reachable
      · exact producer_sound layout storage oracle ⟨config, demand, isTopUp⟩
      · intro before output middle executed
        have bounded := (TrioAlloc2.producer_success_establishes_consumer_premises
          layout storage oracle ⟨config, demand, isTopUp⟩ before middle output executed).length_representable
        by_cases positive : demand.val > 0
        · simp only [positive, ↓reduceIte]
          exact finishPositive_sound output demand config.maxEBType1 _ bounded middle
        · simp only [positive, ↓reduceIte]
          exact finishZero_sound output config.maxEBType1 _ middle

/-- Every decoded wrapper return or revert satisfies the independent relation,
including the exact attempted module-call prefix on failure. -/
theorem public_all_outcomes (layout : Layout) (storage : Storage) (oracle : StaticOracle)
    (config : Config) (amount : Word) (isTopUp : Bool) (before after : Transcript)
    (result : Except Failure ParentOutput)
    (executed : getDepositAllocations layout storage oracle config amount isTopUp before = (result, after)) :
    Public layout storage oracle config amount isTopUp before result after := by
  have h := public_sound layout storage oracle config amount isTopUp before
  simpa only [executed] using h

#print axioms public_all_outcomes
end LidoSRv3.Audit.Source.TrioComposition.ParentSpec
