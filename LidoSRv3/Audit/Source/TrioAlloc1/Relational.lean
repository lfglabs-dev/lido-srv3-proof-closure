import LidoSRv3.Audit.Source.TrioAlloc1.FirstPass

/-!
Relational specifications of helper outcomes. Relations do not invoke the helper
executor, its checked arithmetic, or its call/decoder actions. Shared `decodeWord`
is the byte interpretation primitive, separately checked in `Bytes.lean`.
This layer does not yet model solc memory allocation failures.
-/
namespace LidoSRv3.Audit.Source.TrioAlloc1
namespace Relational

abbrev Step (α : Type) := Transcript → Except Failure α → Transcript → Prop

def Done (value : α) : Step α := fun before result after => result = .ok value ∧ after = before
def Abort (error : Failure) : Step α := fun before result after => result = .error error ∧ after = before

def Check (relation : Except Failure α → Prop) : Step α :=
  fun before result after => relation result ∧ after = before

/-- Sequence preserves the exact failure prefix, without running a continuation after error. -/
inductive Then (first : Step α) (next : α → Step β) : Step β where
  | error {before after error} : first before (.error error) after →
      Then first next before (.error error) after
  | ok {before middle after value result} : first before (.ok value) middle →
      next value middle result after → Then first next before result after

def Satisfies (action : Execution α) (relation : Step α) : Prop :=
  ∀ before, relation before (action before).1 (action before).2

theorem pure_sound (value : α) : Satisfies (pureExec value) (Done value) :=
  fun _ => ⟨rfl, rfl⟩
theorem abort_sound {α : Type} (error : Failure) : Satisfies (failExec (α := α) error) (Abort error) :=
  fun _ => ⟨rfl, rfl⟩
theorem check_sound (result : Except Failure α) (relation : Except Failure α → Prop)
    (h : relation result) : Satisfies (liftChecked result) (Check relation) :=
  fun _ => ⟨h, rfl⟩

theorem bind_sound (action : Execution α) (next : α → Execution β)
    (first : Step α) (rest : α → Step β)
    (ha : Satisfies action first) (hb : ∀ a, Satisfies (next a) (rest a)) :
    Satisfies (bindExec action next) (Then first rest) := by
  intro before
  have h := ha before
  cases he : action before with
  | mk result middle =>
    rw [he] at h
    cases result with
    | error e => simpa only [bindExec, he] using Then.error (next := rest) h
    | ok a => simpa only [bindExec, he] using Then.ok h (hb a middle)

/-- External behavior is adversarial and history-sensitive; direct call attempts are exact. -/
def Call (oracle : StaticOracle) (request : CallRequest) : Step Bytes := fun before result after =>
  let response := oracle before request
  after = before ++ [{ request, response }] ∧
  match response with
  | .returned bytes => result = .ok bytes
  | .reverted bytes => result = .error (.revertData bytes)
  | .exceptional => result = .error .exceptionalCall

theorem call_sound (oracle : StaticOracle) (request : CallRequest) :
    Satisfies (staticCall oracle request) (Call oracle request) := by
  intro before
  unfold Call staticCall
  cases oracle before request <;> exact ⟨rfl, rfl⟩

def WordResult (n : Nat) (result : Except Failure Word) : Prop :=
  (2^256 ≤ n ∧ result = .error (.panic (word 0x11))) ∨
  (∃ value, result = .ok value ∧ value.val = n)

def ActiveResult (deposited : Word) (exited : Nat) (result : Except Failure Word) : Prop :=
  (deposited.val < exited ∧ result = .error (.panic (word 0x11))) ∨
  (∃ active, result = .ok active ∧ active.val + exited = deposited.val)

def CeilingResult (stake divisor : Word) (result : Except Failure Word) : Prop :=
  (divisor.val = 0 ∧ result = .error (.panic (word 0x12))) ∨
  (divisor.val ≠ 0 ∧ ∃ count, result = .ok count ∧ Ceiling stake.val divisor.val count.val)

def DivisionResult (numerator divisor : Word) (result : Except Failure Word) : Prop :=
  (divisor.val = 0 ∧ result = .error (.panic (word 0x12))) ∨
  (divisor.val ≠ 0 ∧ ∃ quotient, result = .ok quotient ∧ quotient.val = numerator.val/divisor.val)

def SummaryResult (bytes : Bytes) (result : Except Failure Summary) : Prop :=
  if bytes.length < 96 then result = .error .decoderFailure
  else result = .ok { exited := decodeWord bytes 0, deposited := decodeWord bytes 32,
                      depositable := decodeWord bytes 64 }

def StakeResult (bytes : Bytes) (result : Except Failure Word) : Prop :=
  if bytes.length < 32 then result = .error .decoderFailure
  else result = .ok (decodeWord bytes 0)

theorem word_sound (n : Nat) : Satisfies (liftChecked (checked n)) (Check (WordResult n)) := by
  apply check_sound
  unfold checked
  split
  · exact Or.inr ⟨_, rfl, rfl⟩
  · exact Or.inl ⟨by omega, rfl⟩

theorem active_sound (deposited : Word) (exited : Nat) :
    Satisfies (liftChecked (checkedSub deposited.val exited)) (Check (ActiveResult deposited exited)) :=
  check_sound _ _ (checkedSub_word_all_outcomes deposited exited)

theorem ceiling_sound (stake divisor : Word) :
    Satisfies (liftChecked (checkedCeilDiv stake divisor)) (Check (CeilingResult stake divisor)) :=
  check_sound _ _ (checkedCeilDiv_all_outcomes stake divisor)

theorem division_sound (numerator divisor : Word) :
    Satisfies (liftChecked (checkedDiv numerator divisor)) (Check (DivisionResult numerator divisor)) := by
  apply check_sound
  by_cases zero : divisor.val = 0
  · exact Or.inl ⟨zero, by simp [checkedDiv, zero]⟩
  · refine Or.inr ⟨zero, word (numerator.val/divisor.val), by simp [checkedDiv, zero], ?_⟩
    exact Nat.mod_eq_of_lt (Nat.lt_of_le_of_lt (Nat.div_le_self _ _) numerator.isLt)

theorem summary_sound (bytes : Bytes) :
    Satisfies (liftChecked (decodeSummary bytes)) (Check (SummaryResult bytes)) := by
  apply check_sound
  unfold SummaryResult decodeSummary
  split <;> rfl

theorem stake_sound (bytes : Bytes) :
    Satisfies (liftChecked (decodeStake bytes)) (Check (StakeResult bytes)) := by
  apply check_sound
  unfold StakeResult decodeStake
  split <;> rfl

def FinishRow (stored : StoredModule) (summary : Summary) (active allocation total : Word) :
    Step (CachedRow × Word) :=
  Then (Check (WordResult (total.val+allocation.val))) fun next =>
    Done ({ stored, summary, active, allocation }, next)

/-- Full row relation: call prefix and each mathematical check follow source order. -/
def FirstRow (l : Layout) (storage : Storage) (oracle : StaticOracle)
    (input : CapacityInput) (index : Nat) (total : Word) : Step (CachedRow × Word) :=
  let stored := readModule l storage index
  if stored.status.val ≥ 3 then Abort (.panic (word 0x21))
  else Then (Call oracle { target := stored.identity.moduleAddress, payload := summaryPayload }) fun bytes =>
    Then (Check (SummaryResult bytes)) fun summary =>
      Then (Check (ActiveResult summary.deposited (max summary.exited.val stored.accountingExited.val))) fun active =>
        if stored.wcType.val = 2 then
          Then (Call oracle { target := stored.identity.moduleAddress, payload := stakePayload }) fun bytes =>
            Then (Check (StakeResult bytes)) fun stake =>
              Then (Check (CeilingResult stake input.config.maxEBType1)) fun allocation =>
                FinishRow stored summary active allocation total
        else Then (Done active) fun allocation => FinishRow stored summary active allocation total

theorem finishRow_sound (stored : StoredModule) (summary : Summary) (active allocation total : Word) :
    Satisfies (do
      let next ← liftChecked (checked (total.val+allocation.val))
      pure ({ stored, summary, active, allocation }, next))
      (FinishRow stored summary active allocation total) := by
  exact bind_sound _ _ _ _ (word_sound _) (fun _ => pure_sound _)

/-- Universal refinement includes failed calls, malformed data and every arithmetic error. -/
theorem firstRow_sound (l : Layout) (storage : Storage) (oracle : StaticOracle)
    (input : CapacityInput) (index : Nat) (total : Word) :
    Satisfies (firstRow l storage oracle input index total) (FirstRow l storage oracle input index total) := by
  unfold firstRow FirstRow
  by_cases invalid : (readModule l storage index).status.val ≥ 3
  · simpa only [invalid, ↓reduceIte] using abort_sound (α := CachedRow × Word) (.panic (word 0x21))
  · simp only [invalid, ↓reduceIte]
    apply bind_sound
    · exact call_sound _ _
    · intro bytes
      apply bind_sound
      · exact summary_sound _
      · intro summary
        apply bind_sound
        · exact active_sound _ _
        · intro active
          by_cases type2 : (readModule l storage index).wcType.val = 2
          · simp only [type2, ↓reduceIte]
            apply bind_sound
            · exact call_sound _ _
            · intro bytes
              apply bind_sound
              · exact stake_sound _
              · intro stake
                apply bind_sound
                · exact ceiling_sound _ _
                · intro allocation
                  exact finishRow_sound _ _ _ _ _
          · simp only [type2, ↓reduceIte]
            exact bind_sound _ _ _ _ (pure_sound _) (fun _ => finishRow_sound _ _ _ _ _)

def FirstLoop (l : Layout) (storage : Storage) (oracle : StaticOracle) (input : CapacityInput) :
    Nat → Nat → Word → Step (List CachedRow × Word)
  | 0, _, total => Done ([], total)
  | n+1, index, total => Then (FirstRow l storage oracle input index total) fun (row, nextTotal) =>
      Then (FirstLoop l storage oracle input n (index+1) nextTotal) fun (rows, finalTotal) =>
        Done (row :: rows, finalTotal)

theorem firstLoop_sound (l : Layout) (storage : Storage) (oracle : StaticOracle)
    (input : CapacityInput) (n index : Nat) (total : Word) :
    Satisfies (firstLoop l storage oracle input n index total)
      (FirstLoop l storage oracle input n index total) := by
  induction n generalizing index total with
  | zero => exact pure_sound _
  | succ n ih =>
    apply bind_sound
    · exact firstRow_sound _ _ _ _ _ _
    · intro (row, nextTotal)
      exact bind_sound _ _ _ _ (ih (index+1) nextTotal) (fun _ => pure_sound _)

theorem liftChecked_bind (first : Except Failure α) (next : α → Except Failure β) :
    liftChecked (first >>= next) = bindExec (liftChecked first) (fun a => liftChecked (next a)) := by
  funext before
  cases first <;> rfl

theorem except_bind_sound (first : Except Failure α) (next : α → Except Failure β)
    (rfirst : Step α) (rnext : α → Step β)
    (ha : Satisfies (liftChecked first) rfirst) (hb : ∀ a, Satisfies (liftChecked (next a)) (rnext a)) :
    Satisfies (liftChecked (first >>= next)) (Then rfirst rnext) := by
  rw [liftChecked_bind]
  exact bind_sound _ _ _ _ ha hb

def FinishCapacity (total : Word) (row : CachedRow) (available : Word) : Step Word :=
  Then (Check (WordResult (row.stored.share.val*total.val))) fun targetProduct =>
    Done (word (min (targetProduct.val/10000) available.val))

def RowCapacity (input : CapacityInput) (total : Word) (row : CachedRow) : Step Word :=
  if row.stored.status.val ≠ 0 then Done row.allocation
  else if input.isTopUp && row.stored.wcType.val == 2 then
    Then (Check (WordResult (row.active.val*input.config.maxEBType2.val))) fun product =>
      Then (Check (DivisionResult product input.config.maxEBType1)) fun available =>
        FinishCapacity total row available
  else Then (Check (WordResult (row.allocation.val+row.summary.depositable.val))) fun available =>
    FinishCapacity total row available

theorem finishCapacity_sound (total : Word) (row : CachedRow) (available : Word) :
    Satisfies (liftChecked (do
      let product ← checked (row.stored.share.val*total.val)
      pure (word (min (product.val/10000) available.val)))) (FinishCapacity total row available) := by
  exact except_bind_sound _ _ _ _ (word_sound _) (fun _ => pure_sound _)

theorem rowCapacity_sound (input : CapacityInput) (total : Word) (row : CachedRow) :
    Satisfies (liftChecked (rowCapacity input total row)) (RowCapacity input total row) := by
  unfold rowCapacity RowCapacity
  by_cases inactive : row.stored.status.val ≠ 0
  · simp only [ne_eq, inactive]
    exact pure_sound _
  · simp only [inactive, ↓reduceIte]
    by_cases topup : (input.isTopUp && row.stored.wcType.val == 2) = true
    · simp only [topup, ↓reduceIte]
      apply except_bind_sound
      · exact word_sound _
      · intro product
        exact except_bind_sound _ _ _ _ (division_sound _ _) (fun _ => finishCapacity_sound _ _ _)
    · simp only [topup]
      exact except_bind_sound _ _ _ _ (word_sound _) (fun _ => finishCapacity_sound _ _ _)

def SecondLoop (input : CapacityInput) (total : Word) : List CachedRow → Step (List Bucket)
  | [] => Done []
  | row :: rows => Then (RowCapacity input total row) fun capacity =>
      Then (SecondLoop input total rows) fun rest => Done ({ row, capacity } :: rest)

theorem secondLoop_sound (input : CapacityInput) (total : Word) (rows : List CachedRow) :
    Satisfies (liftChecked (secondLoop input total rows)) (SecondLoop input total rows) := by
  induction rows with
  | nil => exact pure_sound _
  | cons row rows ih =>
    exact except_bind_sound _ _ _ _ (rowCapacity_sound _ _ _) (fun _ =>
      except_bind_sound _ _ _ _ ih (fun _ => pure_sound _))

/-- Output columns are specified independently of the executable output adapter. -/
def Output (buckets : List Bucket) : Step CapacityOutput := fun before result after =>
  after = before ∧ ∃ output, result = .ok output ∧
    output.identities = buckets.map (fun b => b.row.stored.identity) ∧
    output.allocations = buckets.map (fun b => b.row.allocation) ∧
    output.capacities = buckets.map (fun b => b.capacity)

def Producer (l : Layout) (storage : Storage) (oracle : StaticOracle) (input : CapacityInput) :
    Step CapacityOutput :=
  Then (FirstLoop l storage oracle input (storage (countSlot l)).val 0 input.depositsToAllocate)
    fun (rows, total) => Then (SecondLoop input total rows) (fun buckets => Output buckets)

/-- Every success or error of the storage-backed executor satisfies the independent
relational helper specification. No successful-callee or pre-bound module list premise. -/
theorem producer_sound (l : Layout) (storage : Storage) (oracle : StaticOracle) (input : CapacityInput) :
    Satisfies (produce l storage oracle input) (Producer l storage oracle input) := by
  apply bind_sound
  · exact firstLoop_sound _ _ _ _ _ _ _
  · intro (rows, total)
    apply bind_sound
    · exact secondLoop_sound _ _ _
    · intro buckets before
      exact ⟨rfl, outputOfBuckets buckets, rfl, rfl, rfl, rfl⟩

theorem producer_all_outcomes (l : Layout) (storage : Storage) (oracle : StaticOracle)
    (input : CapacityInput) (before after : Transcript) (result : CapacityResult)
    (h : produce l storage oracle input before = (result, after)) :
    Producer l storage oracle input before result after := by
  have sound := producer_sound l storage oracle input before
  simpa only [h] using sound

end Relational
end LidoSRv3.Audit.Source.TrioAlloc1
