import LidoSRv3.Audit.Source.TrioComposition.ParentRelational
import LidoSRv3.Audit.Source.TrioAlloc1.Determinism

namespace LidoSRv3.Audit.Source.TrioComposition.ParentSpec
open TrioAlloc1 TrioAlloc1.Relational

/-- The independent proportional relation has a unique spent amount and final
row sequence, without referring to executable allocation. -/
theorem distribution_unique {rows : List TrioAlloc2.Spec.Row} {demand spent₁ spent₂ : Nat}
    {final₁ final₂ : List TrioAlloc2.Spec.Row}
    (first : TrioAlloc2.Spec.Distributes rows demand spent₁ final₁)
    (second : TrioAlloc2.Spec.Distributes rows demand spent₂ final₂) :
    spent₁ = spent₂ ∧ final₁ = final₂ := by
  induction first generalizing spent₂ final₂ with
  | stopped rows demand noChoice =>
    cases second with
    | stopped => exact ⟨rfl, rfl⟩
    | advance rows demand choice spent final selected rest =>
      rw [noChoice] at selected
      cases selected
  | advance rows demand choice spent final selected rest ih =>
    cases second with
    | stopped rows demand noChoice =>
      rw [noChoice] at selected
      cases selected
    | advance rows demand other otherSpent otherFinal otherSelected otherRest =>
      have same : choice = other := Option.some.inj (selected.symm.trans otherSelected)
      cases same
      obtain ⟨rfl, rfl⟩ := ih otherRest
      exact ⟨rfl, rfl⟩

theorem decodedRows_injective (left right capacities : List Word)
    (leftLength : left.length ≤ capacities.length) (rightLength : right.length ≤ capacities.length)
    (same : TrioAlloc2.decodedRows left capacities = TrioAlloc2.decodedRows right capacities) : left = right := by
  induction capacities generalizing left right with
  | nil =>
    have leftEmpty : left = [] := by simpa using leftLength
    have rightEmpty : right = [] := by simpa using rightLength
    exact leftEmpty.trans rightEmpty.symm
  | cons cap capacities ih =>
    cases left with
    | nil =>
      cases right with
      | nil => rfl
      | cons r rs => simp [TrioAlloc2.decodedRows] at same
    | cons l ls =>
      cases right with
      | nil => simp [TrioAlloc2.decodedRows] at same
      | cons r rs =>
        have parts : l.val = r.val ∧
            TrioAlloc2.decodedRows ls capacities = TrioAlloc2.decodedRows rs capacities := by
          simpa [TrioAlloc2.decodedRows] using same
        have head : l = r := Fin.ext parts.1
        cases head
        exact congrArg (List.cons l) (ih ls rs (by simpa using leftLength)
          (by simpa using rightLength) parts.2)

theorem consumer_unique (output : CapacityOutput) (demand : Word) : Unique (Consumer output demand) := by
  intro r₁ r₂ h₁ h₂
  rcases h₁ with ⟨v₁, rfl, distribution₁, _, length₁⟩
  rcases h₂ with ⟨v₂, rfl, distribution₂, _, length₂⟩
  obtain ⟨amount, rows⟩ := distribution_unique distribution₁ distribution₂
  have amountEq : v₁.amount = v₂.amount := Fin.ext amount
  have arrayEq := decodedRows_injective v₁.buckets v₂.buckets output.capacities
    (by rw [length₁, output_lengths_equal output]; exact Nat.le_refl _)
    (by rw [length₂, output_lengths_equal output]; exact Nat.le_refl _) rows
  have valueEq : v₁ = v₂ := by
    cases v₁
    cases v₂
    simp_all
  exact congrArg Except.ok valueEq

theorem head_deterministic (values : List Word) : Deterministic (Head values) := by
  cases values with
  | nil => exact abort_deterministic _
  | cons value values => exact done_deterministic _

theorem positive_deterministic (unit : Word) (count : Nat) (old fresh : List Word) :
    Deterministic (Positive unit count old fresh) := by
  induction count generalizing old fresh with
  | zero => exact done_deterministic _
  | succ count ih =>
    apply then_deterministic
    · exact head_deterministic fresh
    · intro next
      apply then_deterministic
      · exact head_deterministic old
      · intro previous
        apply then_deterministic
        · exact check_deterministic _ (active_unique next previous.val)
        · intro delta
          apply then_deterministic
          · exact check_deterministic _ (word_unique _)
          · intro deltaWei
            apply then_deterministic
            · exact check_deterministic _ (word_unique _)
            · intro nextWei
              exact then_deterministic _ _ (ih old.tail fresh.tail) (fun _ => done_deterministic _)

theorem zero_deterministic (unit : Word) (count : Nat) (old : List Word) :
    Deterministic (Zero unit count old) := by
  induction count generalizing old with
  | zero => exact done_deterministic _
  | succ count ih =>
    apply then_deterministic
    · exact head_deterministic old
    · intro previous
      exact then_deterministic _ _ (check_deterministic _ (word_unique _)) (fun _ =>
        then_deterministic _ _ (ih old.tail) (fun _ => done_deterministic _))

theorem finishPositive_deterministic (output : CapacityOutput) (demand unit : Word) (count : Nat) :
    Deterministic (FinishPositive output demand unit count) := by
  exact then_deterministic _ _ (check_deterministic _ (consumer_unique output demand)) (fun result =>
    then_deterministic _ _ (check_deterministic _ (word_unique _)) (fun _ =>
      then_deterministic _ _ (positive_deterministic unit count output.allocations result.buckets)
        (fun _ => done_deterministic _)))

theorem finishZero_deterministic (output : CapacityOutput) (unit : Word) (count : Nat) :
    Deterministic (FinishZero output unit count) :=
  then_deterministic _ _ (zero_deterministic unit count output.allocations) (fun _ => done_deterministic _)

theorem public_deterministic (layout : Layout) (storage : Storage) (oracle : StaticOracle)
    (config : Config) (amount : Word) (isTopUp : Bool) :
    Deterministic (Public layout storage oracle config amount isTopUp) := by
  dsimp only [Public]
  split
  · exact done_deterministic _
  · apply then_deterministic
    · exact check_deterministic _ (division_unique _ _)
    · intro demand
      apply then_deterministic
      · exact producer_deterministic _ _ _ _
      · intro output
        split
        · exact finishPositive_deterministic _ _ _ _
        · exact finishZero_deterministic _ _ _

/-- Exact two-way correspondence for the decoded public wrapper. This binds the
complete result and attempted module transcript, not just successful totals.
Compiler memory, delegated library ABI and concrete EVM world binding remain
separate from this SOURCE-layer theorem. -/
theorem public_iff (layout : Layout) (storage : Storage) (oracle : StaticOracle)
    (config : Config) (amount : Word) (isTopUp : Bool) (before after : Transcript)
    (result : Except Failure ParentOutput) :
    Public layout storage oracle config amount isTopUp before result after ↔
      getDepositAllocations layout storage oracle config amount isTopUp before = (result, after) := by
  constructor
  · intro specified
    have computed := public_sound layout storage oracle config amount isTopUp before
    obtain ⟨hr, ht⟩ := public_deterministic layout storage oracle config amount isTopUp
      _ _ _ _ _ computed specified
    exact Prod.ext hr ht
  · exact public_all_outcomes _ _ _ _ _ _ _ _ _

#print axioms public_iff
end LidoSRv3.Audit.Source.TrioComposition.ParentSpec
