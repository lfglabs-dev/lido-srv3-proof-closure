import LidoSRv3.Audit.Source.NodeOperatorsRegistry.Summary

/-!
[NOR internal exit writer](https://github.com/lidofinance/core/blob/17005714f151e5502c559932319a3f2f74ac2436/contracts/0.4.24/nos/NodeOperatorsRegistry.sol#L558-L587),
including `_updateSummaryMaxValidatorsCount` and `_applyNodeOperatorLimits`.
State names the Solidity struct fields, before compiler slot instantiation.
Events record source arguments; event ABI and public caller admission remain
separate from this internal helper. Errors commit neither writes nor events.
-/
namespace LidoSRv3.Audit.Source.NodeOperatorsRegistry
open TrioAlloc1

structure Operator where
  signingKeysStats : Word
  targetValidatorsStats : Word

structure State where
  operators : Word → Operator
  summarySigningKeysStats : Word

def saveOperator (s : State) (id : Word) (operator : Operator) : State :=
  { s with operators := fun queried => if queried = id then operator else s.operators queried }

def applyNodeOperatorLimits (s : State) (id : Word) : Except Bytes (State × Word × Word) := do
  let operator := s.operators id
  let signing := operator.signingKeysStats
  let target := operator.targetValidatorsStats
  let deposited := packedGet signing 3
  let vetted := packedGet signing 0
  let newMaximum := if (packedGet target 0).val ≠ 0 then
      word (max deposited.val (min vetted.val
        ((packedGet signing 1).val + (packedGet target 1).val)))
    else vetted
  let oldMaximum := packedGet target 2
  if oldMaximum ≠ newMaximum then
    let updated ← Packed64x4.set target 2 newMaximum
    pure (saveOperator s id { operator with targetValidatorsStats := updated }, oldMaximum, newMaximum)
  else pure (s, oldMaximum, newMaximum)

private theorem saveTarget_frame (s : State) (id target : Word) :
    (saveOperator s id { s.operators id with targetValidatorsStats := target }).summarySigningKeysStats =
      s.summarySigningKeysStats ∧
    ∀ queried, ((saveOperator s id
      { s.operators id with targetValidatorsStats := target }).operators queried).signingKeysStats =
        (s.operators queried).signingKeysStats := by
  constructor
  · rfl
  · intro queried
    by_cases equal : queried = id <;> simp [saveOperator, equal]

theorem applyLimits_frame (s after : State) (id oldMaximum newMaximum : Word)
    (success : applyNodeOperatorLimits s id = .ok (after, oldMaximum, newMaximum)) :
    after.summarySigningKeysStats = s.summarySigningKeysStats ∧
      ∀ queried, (after.operators queried).signingKeysStats =
        (s.operators queried).signingKeysStats := by
  dsimp only [applyNodeOperatorLimits] at success
  simp only [bind, pure] at success
  repeat first
    | (split at success)
    | (simp only [Except.bind, Except.pure] at success)
    | (simp at success)
    | (obtain ⟨rfl, rfl, rfl⟩ := success; exact saveTarget_frame _ _ _)
    | (obtain ⟨rfl, rfl, rfl⟩ := success; exact ⟨rfl, fun _ => rfl⟩)

def updateSummaryMaxValidatorsCount (s : State) (id : Word) : Except Bytes State := do
  let (s, oldMaximum, newMaximum) ← applyNodeOperatorLimits s id
  if newMaximum = oldMaximum then pure s
  else
    let summary ← if newMaximum.val > oldMaximum.val then
        Packed64x4.add s.summarySigningKeysStats 0 (word (newMaximum.val-oldMaximum.val))
      else Packed64x4.sub s.summarySigningKeysStats 0 (word (oldMaximum.val-newMaximum.val))
    pure { s with summarySigningKeysStats := summary }

/-- Applying limits and changing aggregate maximum cannot change any operator
signing counter or aggregate exited/deposited counter. -/
theorem updateMaximum_frame (s after : State) (id : Word)
    (success : updateSummaryMaxValidatorsCount s id = .ok after) :
    (∀ queried, (after.operators queried).signingKeysStats =
      (s.operators queried).signingKeysStats) ∧
    packedGet after.summarySigningKeysStats 1 = packedGet s.summarySigningKeysStats 1 ∧
    packedGet after.summarySigningKeysStats 3 = packedGet s.summarySigningKeysStats 3 := by
  cases limits : applyNodeOperatorLimits s id with
  | error reason => simp [updateSummaryMaxValidatorsCount, limits, bind, Except.bind] at success
  | ok result =>
    rcases result with ⟨middle, oldMaximum, newMaximum⟩
    have frame := applyLimits_frame s middle id oldMaximum newMaximum limits
    simp only [updateSummaryMaxValidatorsCount, limits, bind, Except.bind] at success
    split at success
    · simp only [pure, Except.pure, Except.ok.injEq] at success
      subst after
      exact ⟨frame.2, by rw [frame.1], by rw [frame.1]⟩
    · split at success
      · cases adjustment : Packed64x4.add middle.summarySigningKeysStats 0
            (word (newMaximum.val-oldMaximum.val)) with
        | error reason => simp [adjustment] at success
        | ok summary =>
          simp only [adjustment, pure, Except.pure, Except.ok.injEq] at success
          subst after
          have preserved := (Packed64x4.add_success _ _ _ _ adjustment).2
          exact ⟨frame.2,
            (preserved 1 (by decide)).trans (congrArg (fun w => packedGet w 1) frame.1),
            (preserved 3 (by decide)).trans (congrArg (fun w => packedGet w 3) frame.1)⟩
      · cases adjustment : Packed64x4.sub middle.summarySigningKeysStats 0
            (word (oldMaximum.val-newMaximum.val)) with
        | error reason => simp [adjustment] at success
        | ok summary =>
          simp only [adjustment, pure, Except.pure, Except.ok.injEq] at success
          subst after
          have preserved := (Packed64x4.sub_success _ _ _ _ adjustment).2
          exact ⟨frame.2,
            (preserved 1 (by decide)).trans (congrArg (fun w => packedGet w 1) frame.1),
            (preserved 3 (by decide)).trans (congrArg (fun w => packedGet w 3) frame.1)⟩

/-- Source arguments of ExitedSigningKeysCountChanged, in emission order. -/
abbrev ExitEvents := List (Word × Word)

def updateExitedValidatorsCount (s : State) (id newExited : Word) (allowDecrease : Bool) :
    Except Bytes (State × ExitEvents) := do
  let operator := s.operators id
  let signing := operator.signingKeysStats
  let oldExited := packedGet signing 1
  if newExited = oldExited then pure (s, [])
  else if !(allowDecrease || decide (newExited.val > oldExited.val)) then
    .error (Packed64x4.errorString "EXITED_VALIDATORS_COUNT_DECREASED")
  else if ¬ newExited.val ≤ (packedGet signing 3).val then
    .error (Packed64x4.errorString "OUT_OF_RANGE")
  else
    let signing ← Packed64x4.set signing 1 newExited
    let s := saveOperator s id { operator with signingKeysStats := signing }
    let summary ← if newExited.val > oldExited.val then
        Packed64x4.add s.summarySigningKeysStats 1 (word (newExited.val-oldExited.val))
      else Packed64x4.sub s.summarySigningKeysStats 1 (word (oldExited.val-newExited.val))
    let s ← updateSummaryMaxValidatorsCount { s with summarySigningKeysStats := summary } id
    pure (s, [(id, newExited)])

structure Outcome where
  result : Except Bytes Unit
  state : State
  events : ExitEvents

/-- Transactional observation of the internal helper, including final rollback
when a later aggregate/max update fails after the source's event emission. -/
def executeUpdateExited (s : State) (id newExited : Word) (allowDecrease : Bool) : Outcome :=
  match updateExitedValidatorsCount s id newExited allowDecrease with
  | .error reason => ⟨.error reason, s, []⟩
  | .ok (after, events) => ⟨.ok (), after, events⟩

theorem updateExited_failure_restores (s : State) (id newExited : Word) (allowDecrease : Bool)
    (reason : Bytes)
    (failure : (executeUpdateExited s id newExited allowDecrease).result = .error reason) :
    (executeUpdateExited s id newExited allowDecrease).state = s ∧
      (executeUpdateExited s id newExited allowDecrease).events = [] := by
  unfold executeUpdateExited at *
  split at failure <;> simp_all

/-- The equal-value return precedes the nondecrease and deposited-count guards.
An invalid incoming invariant is therefore not repaired by this branch. -/
theorem updateExited_unchanged (s : State) (id : Word) (allowDecrease : Bool) :
    updateExitedValidatorsCount s id (packedGet (s.operators id).signingKeysStats 1)
      allowDecrease = .ok (s, []) := by
  simp [updateExitedValidatorsCount, pure, Except.pure]

/-- Derive the actual writer's admission alternatives, retaining its early
return. In particular, success alone does not establish a valid input state. -/
theorem updateExited_admission (s after : State) (id newExited : Word)
    (allowDecrease : Bool) (events : ExitEvents)
    (success : updateExitedValidatorsCount s id newExited allowDecrease = .ok (after, events)) :
    newExited = packedGet (s.operators id).signingKeysStats 1 ∨
      ((allowDecrease = true ∨
        (packedGet (s.operators id).signingKeysStats 1).val < newExited.val) ∧
        newExited.val ≤ (packedGet (s.operators id).signingKeysStats 3).val) := by
  dsimp only [updateExitedValidatorsCount] at success
  split at success
  · exact Or.inl ‹_›
  · apply Or.inr
    split at success
    · cases success
    · split at success
      · cases success
      · cases allowDecrease <;> simp_all

end LidoSRv3.Audit.Source.NodeOperatorsRegistry
