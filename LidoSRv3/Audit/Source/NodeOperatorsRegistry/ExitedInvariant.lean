import LidoSRv3.Audit.Source.NodeOperatorsRegistry.ExitedValidators

/-!
Counter effects of the [NOR exit writer](https://github.com/lidofinance/core/blob/17005714f151e5502c559932319a3f2f74ac2436/contracts/0.4.24/nos/NodeOperatorsRegistry.sol#L558-L587), including its final maximum
update. These are derived from successful execution, not supplied postconditions.
The conservation equation avoids truncated subtraction when exits decrease.
-/
namespace LidoSRv3.Audit.Source.NodeOperatorsRegistry
open TrioAlloc1

private theorem bind_success {ε α β : Type} {step : Except ε α}
    {next : α → Except ε β} {value : β} (h : (step >>= next) = .ok value) :
    ∃ x, step = .ok x ∧ next x = .ok value := by
  cases step with
  | error e => cases h
  | ok x => exact ⟨x, rfl, h⟩

/-- Lean's do elaborator distributes the continuation into the source branch. -/
private theorem bind_ite {ε α β : Type} (condition : Prop) [Decidable condition]
    (yes no : Except ε α) (next : α → Except ε β) :
    ((if condition then yes else no) >>= next) =
      (if condition then yes >>= next else no >>= next) := by
  by_cases h : condition <;> simp [h]

private theorem summary_exit_adjustment (summary oldExited newExited result : Word)
    (success : (if newExited.val > oldExited.val then
        Packed64x4.add summary 1 (word (newExited.val-oldExited.val))
      else Packed64x4.sub summary 1 (word (oldExited.val-newExited.val))) = .ok result) :
    (packedGet result 1).val + oldExited.val = (packedGet summary 1).val + newExited.val ∧
      packedGet result 3 = packedGet summary 3 := by
  simp only [packedGet]
  split at success
  · have spec := Packed64x4.add_success _ _ _ _ success
    have bound : newExited.val-oldExited.val < 2^256 :=
      Nat.lt_of_le_of_lt (Nat.sub_le _ _) newExited.isLt
    have equation := spec.1
    simp only [word, Nat.mod_eq_of_lt bound] at equation
    exact ⟨by omega, spec.2 3 (by decide)⟩
  · have spec := Packed64x4.sub_success _ _ _ _ success
    have bound : oldExited.val-newExited.val < 2^256 :=
      Nat.lt_of_le_of_lt (Nat.sub_le _ _) oldExited.isLt
    have equation := spec.1
    simp only [word, Nat.mod_eq_of_lt bound] at equation
    exact ⟨by omega, spec.2 3 (by decide)⟩

/-- A successful exit update sets the selected count, preserves every deposited
count and every other operator's signing word, and changes the aggregate by
exactly the local change. No aggregate consistency premise is needed here. -/
theorem updateExited_effects (s after : State) (id newExited : Word)
    (allowDecrease : Bool) (events : ExitEvents)
    (success : updateExitedValidatorsCount s id newExited allowDecrease = .ok (after, events)) :
    (packedGet (after.operators id).signingKeysStats 1).val = newExited.val ∧
    (∀ queried, packedGet (after.operators queried).signingKeysStats 3 =
      packedGet (s.operators queried).signingKeysStats 3) ∧
    (packedGet after.summarySigningKeysStats 1).val +
        (packedGet (s.operators id).signingKeysStats 1).val =
      (packedGet s.summarySigningKeysStats 1).val + newExited.val ∧
    packedGet after.summarySigningKeysStats 3 = packedGet s.summarySigningKeysStats 3 ∧
    (∀ queried, queried ≠ id → (after.operators queried).signingKeysStats =
      (s.operators queried).signingKeysStats) := by
  dsimp only [updateExitedValidatorsCount] at success
  split at success
  · simp only [pure, Except.pure, Except.ok.injEq, Prod.mk.injEq] at success
    rcases success with ⟨rfl, rfl⟩
    simp_all
  · split at success
    · cases success
    · split at success
      · cases success
      · obtain ⟨signing, stored, success⟩ := bind_success success
        rw [← bind_ite] at success
        obtain ⟨summary, adjusted, success⟩ := bind_success success
        obtain ⟨settled, maximum, success⟩ := bind_success success
        change Except.ok (settled, [(id, newExited)]) = Except.ok (after, events) at success
        simp only [Except.ok.injEq, Prod.mk.injEq] at success
        rcases success with ⟨stateEq, eventEq⟩
        subst after
        subst events
        have store := Packed64x4.set_success _ _ _ _ stored
        have aggregate := summary_exit_adjustment _ _ _ _ adjusted
        have frame := updateMaximum_frame _ _ _ maximum
        have selected : (settled.operators id).signingKeysStats = signing := by
          simpa [saveOperator] using frame.1 id
        have others : ∀ queried, queried ≠ id → (settled.operators queried).signingKeysStats =
            (s.operators queried).signingKeysStats := by
          intro queried different
          simpa [saveOperator, different] using frame.1 queried
        refine ⟨?_, ?_, ?_, ?_, others⟩
        · rw [selected]
          exact store.1
        · intro queried
          by_cases equal : queried = id
          · subst queried
            rw [selected]
            exact store.2 3 (by decide)
          · rw [others queried equal]
        · rw [frame.2.1]
          exact aggregate.1
        · exact frame.2.2.trans aggregate.2

/-- Sum over the observed operator enumeration. Binding this enumeration to
the registry's count/storage is a separate source-state relation. -/
def counterSum (s : State) (field : Fin 4) : List Word → Nat
  | [] => 0
  | id :: rest => (packedGet (s.operators id).signingKeysStats field).val + counterSum s field rest

private theorem counterSum_congr (s after : State) (field : Fin 4) (ids : List Word)
    (same : ∀ id ∈ ids, packedGet (after.operators id).signingKeysStats field =
      packedGet (s.operators id).signingKeysStats field) :
    counterSum after field ids = counterSum s field ids := by
  induction ids with
  | nil => rfl
  | cons head tail ih =>
    simp only [counterSum, same head (by simp)]
    rw [ih (fun id member => same id (by simp [member]))]

theorem counterSum_single_change (s after : State) (field : Fin 4) (id newValue : Word) (ids : List Word)
    (unique : ids.Nodup) (member : id ∈ ids)
    (selected : (packedGet (after.operators id).signingKeysStats field).val = newValue.val)
    (others : ∀ queried, queried ≠ id → (after.operators queried).signingKeysStats =
      (s.operators queried).signingKeysStats) :
    counterSum after field ids + (packedGet (s.operators id).signingKeysStats field).val =
      counterSum s field ids + newValue.val := by
  induction ids with
  | nil => simp at member
  | cons head tail ih =>
    have nodup := List.nodup_cons.mp unique
    by_cases equal : head = id
    · subst head
      have tail_same : counterSum after field tail = counterSum s field tail :=
        counterSum_congr s after field tail (fun queried belongs => by
          have different : queried ≠ id := by intro equal; subst queried; exact nodup.1 belongs
          rw [others queried different])
      simp only [counterSum, selected, tail_same]
      omega
    · have tail_member : id ∈ tail := by simpa [List.mem_cons, Ne.symm equal] using member
      have tail_effect := ih nodup.2 tail_member
      simp only [counterSum, others head equal]
      omega

/-- The prestate ties packed aggregates to all enumerated operators. This is
an inductive invariant candidate, not an assumption about a desired poststate. -/
structure AccountingInvariant (s : State) (ids : List Word) : Prop where
  unique : ids.Nodup
  exited_sum : (packedGet s.summarySigningKeysStats 1).val = counterSum s 1 ids
  deposited_sum : (packedGet s.summarySigningKeysStats 3).val = counterSum s 3 ids
  local_consistency : ∀ id ∈ ids,
    (packedGet (s.operators id).signingKeysStats 1).val ≤
      (packedGet (s.operators id).signingKeysStats 3).val

/-- Preserve the aggregate-sum and per-operator invariants through the complete
successful internal exit writer, including decreases and maximum updates. -/
theorem updateExited_preserves_accounting (s after : State) (ids : List Word)
    (id newExited : Word) (allowDecrease : Bool) (events : ExitEvents)
    (before : AccountingInvariant s ids) (member : id ∈ ids)
    (success : updateExitedValidatorsCount s id newExited allowDecrease = .ok (after, events)) :
    AccountingInvariant after ids := by
  obtain ⟨selected, deposits, aggregate, aggregateDeposits, others⟩ :=
    updateExited_effects s after id newExited allowDecrease events success
  have sum_effect := counterSum_single_change s after 1 id newExited ids before.unique member selected others
  have deposit_sum := counterSum_congr s after 3 ids (fun queried _ => deposits queried)
  have admitted : newExited.val ≤ (packedGet (s.operators id).signingKeysStats 3).val := by
    rcases updateExited_admission s after id newExited allowDecrease events success with unchanged | changed
    · rw [unchanged]
      exact before.local_consistency id member
    · exact changed.2
  refine ⟨before.unique, ?_, ?_, ?_⟩
  · have old_sum := before.exited_sum
    omega
  · rw [aggregateDeposits, deposit_sum]
    exact before.deposited_sum
  · intro queried belongs
    by_cases equal : queried = id
    · subst queried
      rw [selected, deposits id]
      exact admitted
    · rw [others queried equal]
      exact before.local_consistency queried belongs

/-- Preservation covers every transactional outcome. A later arithmetic
failure restores the prestate, so it cannot leave a partially updated sum. -/
theorem executeUpdateExited_preserves_accounting (s : State) (ids : List Word)
    (id newExited : Word) (allowDecrease : Bool)
    (before : AccountingInvariant s ids) (member : id ∈ ids) :
    AccountingInvariant (executeUpdateExited s id newExited allowDecrease).state ids := by
  cases result : updateExitedValidatorsCount s id newExited allowDecrease with
  | error reason => simpa only [executeUpdateExited, result] using before
  | ok value =>
    rcases value with ⟨after, events⟩
    simpa only [executeUpdateExited, result] using
      updateExited_preserves_accounting s after ids id newExited allowDecrease events before member result

/-- Aggregate ordering follows from the sum relation and each operator's
ordering; it is not an independent aggregate-bound premise. -/
theorem AccountingInvariant.exited_le_deposited (s : State) (ids : List Word)
    (invariant : AccountingInvariant s ids) :
    (packedGet s.summarySigningKeysStats 1).val ≤
      (packedGet s.summarySigningKeysStats 3).val := by
  rw [invariant.exited_sum, invariant.deposited_sum]
  have sumBound : ∀ domain : List Word,
      (∀ id ∈ domain, (packedGet (s.operators id).signingKeysStats 1).val ≤
        (packedGet (s.operators id).signingKeysStats 3).val) →
      counterSum s 1 domain ≤ counterSum s 3 domain := by
    intro domain
    induction domain with
    | nil => intro _; exact Nat.le_refl 0
    | cons head tail ih =>
      intro bounds
      exact Nat.add_le_add (bounds head (by simp))
        (ih (fun queried belongs => bounds queried (by simp [belongs])))
  exact sumBound ids invariant.local_consistency

/-- Consume the preserved invariant at the actual getter after an exit update.
Getter success remains explicit because maximum/depositable consistency is a
different invariant; router accounting and other writers remain separate. -/
theorem updated_summary_consistent (s after : State) (ids : List Word)
    (id newExited : Word) (allowDecrease : Bool) (events : ExitEvents) (summary : Summary)
    (before : AccountingInvariant s ids) (member : id ∈ ids)
    (success : updateExitedValidatorsCount s id newExited allowDecrease = .ok (after, events))
    (getter : getStakingModuleSummary after.summarySigningKeysStats = .ok summary) :
    summary.exited.val ≤ summary.deposited.val := by
  have invariant := updateExited_preserves_accounting s after ids id newExited allowDecrease
    events before member success
  have ordering := AccountingInvariant.exited_le_deposited after ids invariant
  dsimp only [getStakingModuleSummary] at getter
  split at getter
  · cases getter
    exact ordering
  · cases getter

end LidoSRv3.Audit.Source.NodeOperatorsRegistry
