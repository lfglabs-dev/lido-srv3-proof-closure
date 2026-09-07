import LidoSRv3.Audit.Source.TrioAlloc1.Relational

namespace LidoSRv3.Audit.Source.TrioAlloc1
namespace Relational

def Deterministic (step : Step α) : Prop :=
  ∀ before result₁ after₁ result₂ after₂,
    step before result₁ after₁ → step before result₂ after₂ →
      result₁ = result₂ ∧ after₁ = after₂

def Unique (relation : Except Failure α → Prop) : Prop :=
  ∀ result₁ result₂, relation result₁ → relation result₂ → result₁ = result₂

theorem done_deterministic (value : α) : Deterministic (Done value) := by
  intro before r₁ t₁ r₂ t₂ ⟨hr₁, ht₁⟩ ⟨hr₂, ht₂⟩
  exact ⟨hr₁.trans hr₂.symm, ht₁.trans ht₂.symm⟩

theorem abort_deterministic {α : Type} (error : Failure) : Deterministic (Abort (α := α) error) := by
  intro before r₁ t₁ r₂ t₂ ⟨hr₁, ht₁⟩ ⟨hr₂, ht₂⟩
  exact ⟨hr₁.trans hr₂.symm, ht₁.trans ht₂.symm⟩

theorem check_deterministic (relation : Except Failure α → Prop) (unique : Unique relation) :
    Deterministic (Check relation) := by
  intro before r₁ t₁ r₂ t₂ ⟨hr₁, ht₁⟩ ⟨hr₂, ht₂⟩
  exact ⟨unique _ _ hr₁ hr₂, ht₁.trans ht₂.symm⟩

theorem then_deterministic (first : Step α) (next : α → Step β)
    (hf : Deterministic first) (hn : ∀ value, Deterministic (next value)) :
    Deterministic (Then first next) := by
  intro before r₁ t₁ r₂ t₂ h₁ h₂
  cases h₁ with
  | error ha =>
    cases h₂ with
    | error hb =>
      obtain ⟨he, ht⟩ := hf _ _ _ _ _ ha hb
      cases he
      exact ⟨rfl, ht⟩
    | ok hb _ =>
      obtain ⟨he, _⟩ := hf _ _ _ _ _ ha hb
      cases he
  | ok ha hrest =>
    cases h₂ with
    | error hb =>
      obtain ⟨he, _⟩ := hf _ _ _ _ _ ha hb
      cases he
    | ok hb hrest' =>
      obtain ⟨he, ht⟩ := hf _ _ _ _ _ ha hb
      cases he
      cases ht
      exact hn _ _ _ _ _ _ hrest hrest'

theorem call_deterministic (oracle : StaticOracle) (request : CallRequest) :
    Deterministic (Call oracle request) := by
  intro before r₁ t₁ r₂ t₂ h₁ h₂
  unfold Call at h₁ h₂
  rcases h₁ with ⟨ht₁, hr₁⟩
  rcases h₂ with ⟨ht₂, hr₂⟩
  refine ⟨?_, ht₁.trans ht₂.symm⟩
  cases hc : oracle before request <;>
    simp only [hc] at hr₁ hr₂ <;> exact hr₁.trans hr₂.symm

theorem word_unique (n : Nat) : Unique (WordResult n) := by
  intro r₁ r₂ h₁ h₂
  rcases h₁ with ⟨bound, rfl⟩ | ⟨v₁, rfl, hv₁⟩
  · rcases h₂ with ⟨_, rfl⟩ | ⟨v₂, rfl, hv₂⟩
    · rfl
    · have := v₂.isLt; omega
  · rcases h₂ with ⟨bound, rfl⟩ | ⟨v₂, rfl, hv₂⟩
    · have := v₁.isLt; omega
    · have he : v₁ = v₂ := Fin.ext (hv₁.trans hv₂.symm)
      rw [he]

theorem active_unique (deposited : Word) (exited : Nat) : Unique (ActiveResult deposited exited) := by
  intro r₁ r₂ h₁ h₂
  rcases h₁ with ⟨bad, rfl⟩ | ⟨v₁, rfl, hv₁⟩
  · rcases h₂ with ⟨_, rfl⟩ | ⟨v₂, rfl, hv₂⟩
    · rfl
    · omega
  · rcases h₂ with ⟨bad, rfl⟩ | ⟨v₂, rfl, hv₂⟩
    · omega
    · have he : v₁ = v₂ := Fin.ext (by omega)
      rw [he]

theorem ceiling_unique (stake divisor : Word) : Unique (CeilingResult stake divisor) := by
  intro r₁ r₂ h₁ h₂
  rcases h₁ with ⟨zero, rfl⟩ | ⟨positive, v₁, rfl, hv₁⟩
  · rcases h₂ with ⟨_, rfl⟩ | ⟨positive, _⟩
    · rfl
    · exact False.elim (positive zero)
  · rcases h₂ with ⟨zero, _⟩ | ⟨_, v₂, rfl, hv₂⟩
    · exact False.elim (positive zero)
    · have he : v₁ = v₂ := Fin.ext (Nat.le_antisymm (hv₁.2 _ hv₂.1) (hv₂.2 _ hv₁.1))
      rw [he]

theorem division_unique (numerator divisor : Word) : Unique (DivisionResult numerator divisor) := by
  intro r₁ r₂ h₁ h₂
  rcases h₁ with ⟨zero, rfl⟩ | ⟨positive, v₁, rfl, hv₁⟩
  · rcases h₂ with ⟨_, rfl⟩ | ⟨positive, _⟩
    · rfl
    · exact False.elim (positive zero)
  · rcases h₂ with ⟨zero, _⟩ | ⟨_, v₂, rfl, hv₂⟩
    · exact False.elim (positive zero)
    · rw [Fin.ext (hv₁.trans hv₂.symm)]

theorem summary_unique (bytes : Bytes) : Unique (SummaryResult bytes) := by
  intro r₁ r₂ h₁ h₂
  unfold SummaryResult at h₁ h₂
  split at h₁ <;> simp_all

theorem stake_unique (bytes : Bytes) : Unique (StakeResult bytes) := by
  intro r₁ r₂ h₁ h₂
  unfold StakeResult at h₁ h₂
  split at h₁ <;> simp_all

theorem finishRow_deterministic (stored : StoredModule) (summary : Summary) (active allocation total : Word) :
    Deterministic (FinishRow stored summary active allocation total) :=
  then_deterministic _ _ (check_deterministic _ (word_unique _)) (fun _ => done_deterministic _)

theorem firstRow_deterministic (l : Layout) (storage : Storage) (oracle : StaticOracle)
    (input : CapacityInput) (index : Nat) (total : Word) :
    Deterministic (FirstRow l storage oracle input index total) := by
  dsimp only [FirstRow]
  split
  · exact abort_deterministic _
  · apply then_deterministic
    · exact call_deterministic _ _
    · intro bytes
      apply then_deterministic
      · exact check_deterministic _ (summary_unique _)
      · intro summary
        apply then_deterministic
        · exact check_deterministic _ (active_unique _ _)
        · intro active
          split
          · apply then_deterministic
            · exact call_deterministic _ _
            · intro bytes
              apply then_deterministic
              · exact check_deterministic _ (stake_unique _)
              · intro stake
                exact then_deterministic _ _ (check_deterministic _ (ceiling_unique _ _))
                  (fun _ => finishRow_deterministic _ _ _ _ _)
          · exact then_deterministic _ _ (done_deterministic _)
              (fun _ => finishRow_deterministic _ _ _ _ _)

theorem firstLoop_deterministic (l : Layout) (storage : Storage) (oracle : StaticOracle)
    (input : CapacityInput) (n index : Nat) (total : Word) :
    Deterministic (FirstLoop l storage oracle input n index total) := by
  induction n generalizing index total with
  | zero => exact done_deterministic _
  | succ n ih =>
    apply then_deterministic
    · exact firstRow_deterministic _ _ _ _ _ _
    · intro (row, nextTotal)
      exact then_deterministic _ _ (ih (index+1) nextTotal) (fun _ => done_deterministic _)

theorem finishCapacity_deterministic (total : Word) (row : CachedRow) (available : Word) :
    Deterministic (FinishCapacity total row available) :=
  then_deterministic _ _ (check_deterministic _ (word_unique _)) (fun _ => done_deterministic _)

theorem rowCapacity_deterministic (input : CapacityInput) (total : Word) (row : CachedRow) :
    Deterministic (RowCapacity input total row) := by
  unfold RowCapacity
  split
  · exact done_deterministic _
  · split
    · exact then_deterministic _ _ (check_deterministic _ (word_unique _)) (fun _ =>
        then_deterministic _ _ (check_deterministic _ (division_unique _ _))
          (fun _ => finishCapacity_deterministic _ _ _))
    · exact then_deterministic _ _ (check_deterministic _ (word_unique _))
        (fun _ => finishCapacity_deterministic _ _ _)

theorem secondLoop_deterministic (input : CapacityInput) (total : Word) (rows : List CachedRow) :
    Deterministic (SecondLoop input total rows) := by
  induction rows with
  | nil => exact done_deterministic _
  | cons row rows ih =>
    exact then_deterministic _ _ (rowCapacity_deterministic _ _ _) (fun _ =>
      then_deterministic _ _ ih (fun _ => done_deterministic _))

theorem output_deterministic (buckets : List Bucket) : Deterministic (Output buckets) := by
  intro before r₁ t₁ r₂ t₂ h₁ h₂
  rcases h₁ with ⟨ht₁, o₁, rfl, hi₁, ha₁, hc₁⟩
  rcases h₂ with ⟨ht₂, o₂, rfl, hi₂, ha₂, hc₂⟩
  have hid := hi₁.trans hi₂.symm
  have hal := ha₁.trans ha₂.symm
  have hca := hc₁.trans hc₂.symm
  have ho : o₁ = o₂ := by
    cases o₁
    cases o₂
    simp_all
  exact ⟨congrArg Except.ok ho, ht₁.trans ht₂.symm⟩

theorem producer_deterministic (l : Layout) (storage : Storage) (oracle : StaticOracle) (input : CapacityInput) :
    Deterministic (Producer l storage oracle input) := by
  apply then_deterministic
  · exact firstLoop_deterministic _ _ _ _ _ _ _
  · intro (rows, total)
    exact then_deterministic _ _ (secondLoop_deterministic _ _ _) (fun _ => output_deterministic _)

/-- Exact two-way correspondence at the SOURCE helper layer, for success and error.
The actual Solidity compiler/memory and Verity refinement obligations remain separate. -/
theorem producer_iff (l : Layout) (storage : Storage) (oracle : StaticOracle) (input : CapacityInput)
    (before after : Transcript) (result : CapacityResult) :
    Producer l storage oracle input before result after ↔
      produce l storage oracle input before = (result, after) := by
  constructor
  · intro specified
    have computed := producer_sound l storage oracle input before
    obtain ⟨hr, ht⟩ := producer_deterministic l storage oracle input _ _ _ _ _ computed specified
    exact Prod.ext hr ht
  · exact producer_all_outcomes _ _ _ _ _ _ _

end Relational
end LidoSRv3.Audit.Source.TrioAlloc1
