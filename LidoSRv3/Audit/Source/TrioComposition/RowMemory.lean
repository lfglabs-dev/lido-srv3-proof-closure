import LidoSRv3.Audit.Source.TrioComposition.ReturnMemory

/-! Interleaved compiler allocation guards for one producer row. The pointer
remains an explicit source value; physical stores, gas and entry provenance
are separate obligations. Configuration allocation precedes enum validation. -/
namespace LidoSRv3.Audit.Source.TrioComposition.RowMemory
open TrioAlloc1

theorem config_allocation (pointer : Word) (small : pointer.val ≤ 2^32) :
    AllocationMemory.finalize pointer (word 224) = .ok (word (pointer.val+224)) := by
  have noWrap : pointer.val+224 < 2^256 := by omega
  have noFail : ¬ ((word (pointer.val+224)).val > AllocationMemory.limit ∨
      (word (pointer.val+224)).val < pointer.val) := by
    simp only [word, Nat.mod_eq_of_lt noWrap, AllocationMemory.limit]
    omega
  have rounded : AllocationMemory.roundedSize (word 224) = 224 := by decide
  simp only [AllocationMemory.finalize, rounded, noFail, ↓reduceIte]

theorem summary_exact (pointer : Word) (data : Bytes) (small : pointer.val ≤ 2^32) :
    ReturnMemory.decodeAllocated 96 decodeSummary pointer data =
      (decodeSummary data).map (fun value => (value,word (pointer.val+96))) := by
  have allocated := ReturnMemory.bounded_finalize pointer (min 96 data.length) small (Nat.min_le_left ..)
  unfold ReturnMemory.decodeAllocated
  rw [allocated, ReturnMemory.summary_take]
  by_cases short : data.length < 96
  · simp [decodeSummary, short, bind, Except.bind, Except.map]
  · have full : min 96 data.length = 96 := by omega
    simp [full, bind, Except.bind, Except.map, pure, Except.pure]

theorem stake_exact (pointer : Word) (data : Bytes) (small : pointer.val ≤ 2^32) :
    ReturnMemory.decodeAllocated 32 decodeStake pointer data =
      (decodeStake data).map (fun value => (value,word (pointer.val+32))) := by
  have allocated := ReturnMemory.bounded_finalize pointer (min 32 data.length) small
    (by have := Nat.min_le_left 32 data.length; omega)
  unfold ReturnMemory.decodeAllocated
  rw [allocated, ReturnMemory.stake_take]
  by_cases short : data.length < 32
  · simp [decodeStake, short, bind, Except.bind, Except.map]
  · have full : min 32 data.length = 32 := by omega
    simp [full, bind, Except.bind, Except.map, pure, Except.pure]

def firstRow (pointer : Word) (l : Layout) (s : Storage) (input : CapacityInput)
    (i : Nat) (total : Word) : CallTree.Program ((CachedRow × Word) × Word) := do
  let configEnd ← CallTree.check (AllocationMemory.finalize pointer (word 224))
  let stored := readModule l s i
  if stored.status.val ≥ 3 then CallTree.check (.error (.panic (word 0x21)))
  else
    let (summary,summaryEnd) ← ReturnMemory.summary configEnd stored.identity.moduleAddress
    let active ← CallTree.check
      (checkedSub summary.deposited.val (max summary.exited.val stored.accountingExited.val))
    let (allocation,next) ← if stored.wcType.val = 2 then do
      let (stake,stakeEnd) ← ReturnMemory.stake summaryEnd stored.identity.moduleAddress
      let allocation ← CallTree.check (checkedCeilDiv stake input.config.maxEBType1)
      pure (allocation,stakeEnd)
      else pure (active,summaryEnd)
    let total' ← CallTree.check (checked (total.val+allocation.val))
    pure (({ stored,summary,active,allocation },total'),next)

theorem config_failure (pointer : Word) (l : Layout) (s : Storage) (input : CapacityInput)
    (i : Nat) (total : Word) (reason : Failure)
    (failed : AllocationMemory.finalize pointer (word 224) = .error reason) :
    firstRow pointer l s input i total = .done (.error reason) := by
  simp [firstRow, failed, CallTree.check, bind, CallTree.bind]

theorem bind_assoc (p : CallTree.Program α) (f : α → CallTree.Program β)
    (g : β → CallTree.Program γ) :
    (p >>= f) >>= g = p >>= (fun a => f a >>= g) := by
  induction p with
  | done result => cases result <;> rfl
  | call request next ih =>
    simp only [bind, CallTree.bind]
    congr 1
    funext response
    exact ih response

private theorem check_map_bind (result : Except Failure α) (f : α → β)
    (next : β → CallTree.Program γ) :
    (CallTree.check (result.map f) >>= next) =
      (CallTree.check result >>= fun value => next (f value)) := by
  cases result <;> rfl

theorem check_ok_bind (value : α) (next : α → CallTree.Program β) :
    (CallTree.check (.ok value) >>= next) = next value := rfl

theorem pure_bind (value : α) (next : α → CallTree.Program β) :
    ((pure value : CallTree.Program α) >>= next) = next value := rfl

private theorem error_bind (reason : Failure) (next : α → CallTree.Program β) :
    (CallTree.check (.error reason) >>= next) = .done (.error reason) := rfl

private theorem ite_bind (p : Prop) [Decidable p] (yes no : CallTree.Program α)
    (next : α → CallTree.Program β) :
    ((if p then yes else no) >>= next) =
      (if p then yes >>= next else no >>= next) := by
  split <;> rfl

/-- Erasing the successful row's next pointer gives precisely the original
producer call tree, including every enum, response, arithmetic and call error.
The 352-byte budget covers configuration, summary and optional stake buffers. -/
theorem firstRow_erasure (pointer : Word) (l : Layout) (s : Storage) (input : CapacityInput)
    (i : Nat) (total : Word) (space : pointer.val+352 ≤ 2^32) :
    (do let (value,_) ← firstRow pointer l s input i total; pure value) =
      CallTree.firstRow l s input i total := by
  have small : pointer.val ≤ 2^32 := by omega
  have configSmall : (word (pointer.val+224)).val ≤ 2^32 := by
    have h : pointer.val+224 < 2^256 := by omega
    simp only [word, Nat.mod_eq_of_lt h]
    omega
  have summarySmall : (word ((word (pointer.val+224)).val+96)).val ≤ 2^32 := by
    have h : pointer.val+224 < 2^256 := by omega
    have h' : pointer.val+224+96 < 2^256 := by omega
    simp only [word, Nat.mod_eq_of_lt h, Nat.mod_eq_of_lt h']
    omega
  simp only [firstRow, config_allocation pointer small, check_ok_bind,
    ReturnMemory.summary, ReturnMemory.stake,
    summary_exact _ _ configSmall, stake_exact _ _ summarySmall,
    bind_assoc, check_map_bind, pure_bind]
  simp only [CallTree.firstRow, ite_bind, bind_assoc, pure_bind, error_bind]
  rfl

set_option maxHeartbeats 800000 in
/-- A successful row consumes exactly its bounded fixed-width buffers. -/
theorem firstRow_exact (pointer : Word) (l : Layout) (s : Storage) (input : CapacityInput)
    (i : Nat) (total : Word) (space : pointer.val+352 ≤ 2^32) :
    firstRow pointer l s input i total =
      (do let value ← CallTree.firstRow l s input i total
          pure (value,word (pointer.val+320+(if (readModule l s i).wcType.val = 2 then 32 else 0)))) := by
  have small : pointer.val ≤ 2^32 := by omega
  have h224 : pointer.val+224 < 2^256 := by omega
  have h320 : pointer.val+320 < 2^256 := by omega
  have configVal : (word (pointer.val+224)).val = pointer.val+224 := Nat.mod_eq_of_lt h224
  have configSmall : (word (pointer.val+224)).val ≤ 2^32 := by rw [configVal]; omega
  have summaryEnd : word ((word (pointer.val+224)).val+96) = word (pointer.val+320) := by
    rw [configVal]
  have summarySmall : (word ((word (pointer.val+224)).val+96)).val ≤ 2^32 := by
    rw [summaryEnd]
    change (pointer.val+320)%2^256 ≤ 2^32
    rw [Nat.mod_eq_of_lt h320]
    omega
  have stakeEnd : word ((word ((word (pointer.val+224)).val+96)).val+32) =
      word (pointer.val+320+32) := by
    rw [summaryEnd]
    change word ((pointer.val+320)%2^256+32) = _
    rw [Nat.mod_eq_of_lt h320]
  simp only [firstRow, config_allocation pointer small, check_ok_bind,
    ReturnMemory.summary, ReturnMemory.stake,
    summary_exact _ _ configSmall, stake_exact _ _ summarySmall,
    bind_assoc, check_map_bind, pure_bind]
  simp only [CallTree.firstRow, ite_bind, bind_assoc, pure_bind, error_bind,
    stakeEnd]
  simp only [summaryEnd]
  by_cases wc : (readModule l s i).wcType.val = 2 <;> simp only [wc, ↓reduceIte, Nat.add_zero]
  all_goals rfl

def advance (pointer : Word) (l : Layout) (s : Storage) (i : Nat) : Word :=
  word (pointer.val+320+(if (readModule l s i).wcType.val = 2 then 32 else 0))

def endPointer (l : Layout) (s : Storage) : Nat → Nat → Word → Word
  | 0, _, pointer => pointer
  | n+1, i, pointer => endPointer l s n (i+1) (advance pointer l s i)

theorem advance_bound (pointer : Word) (l : Layout) (s : Storage) (i : Nat) :
    (advance pointer l s i).val ≤ pointer.val+352 := by
  have bound := Nat.mod_le (pointer.val+320+
    (if (readModule l s i).wcType.val = 2 then 32 else 0)) (2^256)
  have increment : (if (readModule l s i).wcType.val = 2 then 32 else 0) ≤ 32 := by
    split <;> omega
  change (pointer.val+320+(if (readModule l s i).wcType.val = 2 then 32 else 0))%2^256 ≤ pointer.val+352
  omega

theorem endPointer_bound (l : Layout) (s : Storage) (n i : Nat) (pointer : Word) :
    (endPointer l s n i pointer).val ≤ pointer.val+352*n := by
  induction n generalizing i pointer with
  | zero => simp [endPointer]
  | succ n ih =>
    have tail := ih (i+1) (advance pointer l s i)
    have head := advance_bound pointer l s i
    simp only [endPointer]
    omega

def firstLoop (l : Layout) (s : Storage) (input : CapacityInput) :
    Nat → Nat → Word → Word → CallTree.Program ((List CachedRow × Word) × Word)
  | 0, _, total, pointer => pure (([],total),pointer)
  | n+1, i, total, pointer => do
    let ((row,total'),next) ← firstRow pointer l s input i total
    let ((rows,finalTotal),finalPointer) ← firstLoop l s input n (i+1) total' next
    pure ((row::rows,finalTotal),finalPointer)

set_option maxRecDepth 4096 in
/-- The complete first pass threads its pointer across every executed row.
All call and arithmetic failure alternatives are retained; no successful
producer or successful callback outcome is a premise. -/
theorem firstLoop_exact (l : Layout) (s : Storage) (input : CapacityInput)
    (n i : Nat) (total pointer : Word) (space : pointer.val+352*n ≤ 2^32) :
    firstLoop l s input n i total pointer =
      (do let result ← CallTree.firstLoop l s input n i total
          pure (result,endPointer l s n i pointer)) := by
  induction n generalizing i total pointer with
  | zero => rfl
  | succ n ih =>
    have rowSpace : pointer.val+352 ≤ 2^32 := by clear ih; omega
    have increment : (if (readModule l s i).wcType.val = 2 then 32 else 0) ≤ 32 := by
      split <;> omega
    have nextSmall : pointer.val+320+(if (readModule l s i).wcType.val = 2 then 32 else 0) < 2^256 := by omega
    have tailSpace : (advance pointer l s i).val+352*n ≤ 2^32 := by
      simp only [advance, word, Nat.mod_eq_of_lt nextSmall]
      omega
    have row := firstRow_exact pointer l s input i total rowSpace
    change firstRow pointer l s input i total =
      (do let value ← CallTree.firstRow l s input i total
          pure (value,advance pointer l s i)) at row
    simp only [firstLoop, row, CallTree.firstLoop, bind_assoc, pure_bind,
      ih (i+1) _ (advance pointer l s i) tailSpace, endPointer]

#print axioms firstLoop_exact
#print axioms endPointer_bound
#print axioms firstRow_exact
#print axioms firstRow_erasure
#print axioms config_failure

end LidoSRv3.Audit.Source.TrioComposition.RowMemory
