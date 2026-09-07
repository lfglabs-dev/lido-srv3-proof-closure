import LidoSRv3.Audit.Source.TrioComposition.RowMemory

/-! Runtime ERC-7201 slot computations in the pinned SRLib IR allocate two
64-byte buffers each. Rows run two slot computations before configuration,
one before summary, and one before optional stake. The fixed hash and storage
address relation is inherited from Layout/readModule; keccak evaluation, memory
stores/copies and gas are outside this allocation-guard relation. In particular,
the fixed inner hash is interpreted as its nonzero constant; this module does
not prove the keccak computation or its intervening checked subtraction. -/
namespace LidoSRv3.Audit.Source.TrioComposition.FinalMemoryRows
open TrioAlloc1
open RowMemory

/-- Exact allocation order inside `constant_ROUTER_STORAGE_POSITION`. -/
def slot (pointer : Word) : Except Failure Word := do
  let next ← AllocationMemory.finalize pointer (word 64)
  AllocationMemory.finalize next (word 64)

theorem word_small (n : Nat) (h : n ≤ 2^32) : (word n).val = n := by
  exact Nat.mod_eq_of_lt (by omega)

theorem slot_exact (pointer : Word) (space : pointer.val+128 ≤ 2^32) :
    slot pointer = .ok (word (pointer.val+128)) := by
  have small : pointer.val ≤ 2^32 := by omega
  have first : AllocationMemory.finalize pointer (word 64) =
      .ok (word (pointer.val+64)) := ReturnMemory.bounded_finalize pointer 64 small (by omega)
  have firstVal := word_small (pointer.val+64) (by omega)
  have nextSmall : (word (pointer.val+64)).val ≤ 2^32 := by rw [firstVal]; omega
  simp only [slot, first, bind, Except.bind,
    ReturnMemory.bounded_finalize _ 64 nextSmall (by omega), firstVal]

def firstRow (pointer : Word) (l : Layout) (s : Storage) (input : CapacityInput)
    (i : Nat) (total : Word) : CallTree.Program ((CachedRow × Word) × Word) := do
  let slotEnd ← CallTree.check (slot pointer)
  let moduleEnd ← CallTree.check (slot slotEnd)
  let configEnd ← CallTree.check (AllocationMemory.finalize moduleEnd (word 224))
  let stored := readModule l s i
  if stored.status.val ≥ 3 then CallTree.check (.error (.panic (word 0x21)))
  else
    let summaryStart ← CallTree.check (slot configEnd)
    let (summary,summaryEnd) ← ReturnMemory.summary summaryStart stored.identity.moduleAddress
    let active ← CallTree.check
      (checkedSub summary.deposited.val (max summary.exited.val stored.accountingExited.val))
    let (allocation,next) ← if stored.wcType.val = 2 then do
      let stakeStart ← CallTree.check (slot summaryEnd)
      let (stake,stakeEnd) ← ReturnMemory.stake stakeStart stored.identity.moduleAddress
      let allocation ← CallTree.check (checkedCeilDiv stake input.config.maxEBType1)
      pure (allocation,stakeEnd)
      else pure (active,summaryEnd)
    let total' ← CallTree.check (checked (total.val+allocation.val))
    pure (({ stored,summary,active,allocation },total'),next)

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

set_option maxHeartbeats 800000 in
/-- All response, status and arithmetic failures remain in the tree. Only the
allocation panics are discharged from a worst-case numeric space budget. -/
theorem firstRow_exact (pointer : Word) (l : Layout) (s : Storage) (input : CapacityInput)
    (i : Nat) (total : Word) (space : pointer.val+864 ≤ 2^32) :
    firstRow pointer l s input i total =
      (do let value ← CallTree.firstRow l s input i total
          pure (value,word (pointer.val+704+(if (readModule l s i).wcType.val = 2 then 160 else 0)))) := by
  have v128 := word_small (pointer.val+128) (by omega)
  have v256 := word_small (pointer.val+256) (by omega)
  have v480 := word_small (pointer.val+480) (by omega)
  have v608 := word_small (pointer.val+608) (by omega)
  have v704 := word_small (pointer.val+704) (by omega)
  have v832 := word_small (pointer.val+832) (by omega)
  have s0 := slot_exact pointer (by omega)
  have s128 := slot_exact (word (pointer.val+128)) (by rw [v128]; omega)
  have conf := config_allocation (word (pointer.val+256)) (by rw [v256]; omega)
  have s480 := slot_exact (word (pointer.val+480)) (by rw [v480]; omega)
  have s704 := slot_exact (word (pointer.val+704)) (by rw [v704]; omega)
  simp only [v128, v256, v480, v704, Nat.add_assoc] at s128 conf s480 s704
  simp only [firstRow, s0, check_ok_bind, s128, conf, s480,
    ReturnMemory.summary, ReturnMemory.stake,
    summary_exact _ _ (show (word (pointer.val+608)).val ≤ 2^32 by rw [v608]; omega),
    v608, Nat.add_assoc, s704,
    stake_exact _ _ (show (word (pointer.val+832)).val ≤ 2^32 by rw [v832]; omega),
    v832, bind_assoc, check_map_bind, pure_bind]
  simp only [CallTree.firstRow, ite_bind, bind_assoc, pure_bind, error_bind]
  by_cases wc : (readModule l s i).wcType.val = 2 <;> simp only [wc, ↓reduceIte, Nat.add_zero]
  all_goals rfl

def advance (pointer : Word) (l : Layout) (s : Storage) (i : Nat) : Word :=
  word (pointer.val+704+(if (readModule l s i).wcType.val = 2 then 160 else 0))

def endPointer (l : Layout) (s : Storage) : Nat → Nat → Word → Word
  | 0, _, pointer => pointer
  | n+1, i, pointer => endPointer l s n (i+1) (advance pointer l s i)

theorem advance_bound (pointer : Word) (l : Layout) (s : Storage) (i : Nat) :
    (advance pointer l s i).val ≤ pointer.val+864 := by
  have bound := Nat.mod_le (pointer.val+704+
    (if (readModule l s i).wcType.val = 2 then 160 else 0)) (2^256)
  have increment : (if (readModule l s i).wcType.val = 2 then 160 else 0) ≤ 160 := by
    split <;> omega
  change (pointer.val+704+(if (readModule l s i).wcType.val = 2 then 160 else 0))%2^256 ≤ pointer.val+864
  omega

theorem endPointer_bound (l : Layout) (s : Storage) (n i : Nat) (pointer : Word) :
    (endPointer l s n i pointer).val ≤ pointer.val+864*n := by
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
    (n i : Nat) (total pointer : Word) (space : pointer.val+864*n ≤ 2^32) :
    firstLoop l s input n i total pointer =
      (do let result ← CallTree.firstLoop l s input n i total
          pure (result,endPointer l s n i pointer)) := by
  induction n generalizing i total pointer with
  | zero => rfl
  | succ n ih =>
    have rowSpace : pointer.val+864 ≤ 2^32 := by clear ih; omega
    have increment : (if (readModule l s i).wcType.val = 2 then 160 else 0) ≤ 160 := by
      split <;> omega
    have nextSmall : pointer.val+704+(if (readModule l s i).wcType.val = 2 then 160 else 0) < 2^256 := by omega
    have tailSpace : (advance pointer l s i).val+864*n ≤ 2^32 := by
      simp only [advance, word, Nat.mod_eq_of_lt nextSmall]
      omega
    have row := firstRow_exact pointer l s input i total rowSpace
    change firstRow pointer l s input i total =
      (do let value ← CallTree.firstRow l s input i total
          pure (value,advance pointer l s i)) at row
    simp only [firstLoop, row, CallTree.firstLoop, bind_assoc, pure_bind,
      ih (i+1) _ (advance pointer l s i) tailSpace, endPointer]

#print axioms slot_exact
#print axioms firstRow_exact
#print axioms firstLoop_exact
#print axioms endPointer_bound
end LidoSRv3.Audit.Source.TrioComposition.FinalMemoryRows
