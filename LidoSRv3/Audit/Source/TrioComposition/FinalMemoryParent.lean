import LidoSRv3.Audit.Source.TrioComposition.FinalMemoryProducer
import LidoSRv3.Audit.Source.TrioComposition.FinalMemoryCaller

/-! Bounded final caller/producer composition at the pinned internal
`fun_getDepositAllocations` entry. The free pointer is an explicit entry value;
its provenance through dispatch, deployed library identity, compiler correctness,
physical memory stores/copies, gas, and keccak remain outside this relation.
Static-module calls, bytes, failures and their attempted-call order are retained.
The internal allocation library is interpreted through the executed canonical
LibraryABI model, and its canonical shape is proved from reached producer outputs. -/
namespace LidoSRv3.Audit.Source.TrioComposition.FinalMemoryParent
open TrioAlloc1

/-- Both empty arrays are allocated after the outer slot computation. -/
def empty (pointer : Word) : CallTree.Program ParentOutput := do
  let next ← CallTree.check (AllocationMemory.allocateArray pointer (word 0))
  let _ ← CallTree.check (AllocationMemory.allocateArray next (word 0))
  pure ⟨word 0,[],[]⟩

def program (pointer : Word) (layout : Layout) (storage : Storage) (config : Config)
    (amount : Word) (isTopUp : Bool) : CallTree.Program ParentOutput := do
  let countPointer ← CallTree.check (FinalMemoryRows.slot pointer)
  let count := storage (countSlot layout)
  if count.val = 0 then empty countPointer
  else
    let demand ← CallTree.check (checkedDiv amount config.maxEBType1)
    let (produced,next) ← FinalMemoryProducer.producer countPointer layout storage ⟨config,demand,isTopUp⟩
    FinalMemoryCaller.afterProducer next count config demand produced

theorem empty_exact (pointer : Word) (space : pointer.val+64 ≤ 2^32) :
    empty pointer = pure ⟨word 0,[],[]⟩ := by
  have small : pointer.val ≤ 2^32 := by omega
  have firstVal := FinalMemoryRows.word_small (pointer.val+32) (by omega)
  have secondSmall : (word (pointer.val+32)).val ≤ 2^32 := by rw [firstVal]; omega
  simp only [empty, AllocationMemory.bounded_array_allocates pointer (word 0) small (by decide),
    show (word 0).val = 0 from rfl, Nat.mul_zero, Nat.add_zero, RowMemory.check_ok_bind,
    AllocationMemory.bounded_array_allocates _ (word 0) secondSmall (by decide)]

/-- Unlike the earlier prefix-only model, even division-by-zero is preceded by
both dynamic slot allocations. This statement has no small-pointer hypothesis. -/
theorem outer_allocation_failure (pointer : Word) (layout : Layout) (storage : Storage)
    (config : Config) (amount : Word) (isTopUp : Bool) (reason : Failure)
    (failed : FinalMemoryRows.slot pointer = .error reason) :
    program pointer layout storage config amount isTopUp = .done (.error reason) := by
  simp [program, failed, CallTree.check, bind, CallTree.bind]

/-- The whole budget covers outer slot 128, producer 1120*n+448 and successful
caller 128+64*n. Only the canonical response prefix 96+32*n is needed as a
precondition by CallerMemory; the budget also reserves its decoded array. -/
theorem caller_space (pointer : Word) (layout : Layout) (storage : Storage)
    (space : pointer.val+1184*(storage (countSlot layout)).val+704 ≤ 2^32) :
    (FinalMemoryProducer.endPointer (word (pointer.val+128)) layout storage).val+
      96+32*(storage (countSlot layout)).val ≤ 2^32 := by
  have outerVal := FinalMemoryRows.word_small (pointer.val+128) (by omega)
  have producerBound := FinalMemoryProducer.endPointer_bound (word (pointer.val+128)) layout storage
  rw [outerVal] at producerBound
  omega

set_option maxRecDepth 4096 in
/-- All-outcome correspondence: no division, module reply, producer, allocation
library, or Ether conversion success is assumed. The two numeric bounds erase
allocation panics; every original failure and attempted-call transcript survives. -/
theorem correspondence (pointer : Word) (layout : Layout) (storage : Storage)
    (oracle : StaticOracle) (config : Config) (amount : Word) (isTopUp : Bool)
    (countBound : (storage (countSlot layout)).val ≤ 32)
    (space : pointer.val+1184*(storage (countSlot layout)).val+704 ≤ 2^32) :
    CallTree.evaluate oracle (program pointer layout storage config amount isTopUp) =
      getDepositAllocationsABI layout storage oracle config amount isTopUp := by
  have outerSpace : pointer.val+128 ≤ 2^32 := by omega
  have outerVal := FinalMemoryRows.word_small (pointer.val+128) outerSpace
  have producerSpace : (word (pointer.val+128)).val+
      1120*(storage (countSlot layout)).val+448 ≤ 2^32 := by rw [outerVal]; omega
  have callerSpace := caller_space pointer layout storage space
  simp only [program, FinalMemoryRows.slot_exact pointer outerSpace, RowMemory.check_ok_bind]
  by_cases noModules : (storage (countSlot layout)).val = 0
  · have emptySpace : (word (pointer.val+128)).val+64 ≤ 2^32 := by rw [outerVal]; omega
    simp only [noModules, ↓reduceIte, empty_exact _ emptySpace, CallTree.evaluate_pure,
      getDepositAllocationsABI]
    rfl
  · simp only [noModules, ↓reduceIte,
      FinalMemoryProducer.producer_exact _ layout storage _ countBound producerSpace,
      RowMemory.bind_assoc, RowMemory.pure_bind,
      CallTree.evaluate_monad_bind, CallTree.evaluate_check, CallTree.producer_correspondence]
    funext before
    simp only [getDepositAllocationsABI, noModules, ↓reduceIte, bind, bindExec, liftChecked]
    cases divided : checkedDiv amount config.maxEBType1 with
    | error reason => rfl
    | ok demand =>
      simp only
      cases producedEq : produce layout storage oracle ⟨config,demand,isTopUp⟩ before with
      | mk result middle =>
        cases result with
        | error reason => rfl
        | ok produced =>
          simp only
          rw [FinalMemoryCaller.afterProducer_exact _ layout storage oracle
            ⟨config,demand,isTopUp⟩ before middle produced producedEq callerSpace countBound]
          simp only [ParentCalls.afterProducer, CallTree.evaluate_ite,
            CallTree.evaluate_monad_bind, CallTree.evaluate_check, CallTree.evaluate_pure]
          rfl

/-- The independent public specification is reached with the ABI extent derived
from storage count and successful producer length, not supplied as a premise. -/
theorem public_iff (pointer : Word) (layout : Layout) (storage : Storage)
    (oracle : StaticOracle) (config : Config) (amount : Word) (isTopUp : Bool)
    (before after : Transcript) (result : Except Failure ParentOutput)
    (countBound : (storage (countSlot layout)).val ≤ 32)
    (space : pointer.val+1184*(storage (countSlot layout)).val+704 ≤ 2^32) :
    ParentSpec.Public layout storage oracle config amount isTopUp before result after ↔
      CallTree.evaluate oracle (program pointer layout storage config amount isTopUp) before = (result,after) := by
  rw [correspondence pointer layout storage oracle config amount isTopUp countBound space]
  apply public_abi_iff
  intro demand produced middle _ executed _
  exact FinalMemoryCaller.producer_extent layout storage oracle ⟨config,demand,isTopUp⟩
    before middle produced executed countBound

/-- Once an entry pointer is known to be at most 2^31, the physical count ≤ 32
alone supplies the complete caller budget. This does not assert entry provenance. -/
theorem budget_from_small_entry (pointer count : Word)
    (hp : pointer.val ≤ 2^31) (hc : count.val ≤ 32) :
    pointer.val+1184*count.val+704 ≤ 2^32 := by omega

#print axioms correspondence
#print axioms public_iff
#print axioms outer_allocation_failure
#print axioms budget_from_small_entry
end LidoSRv3.Audit.Source.TrioComposition.FinalMemoryParent
