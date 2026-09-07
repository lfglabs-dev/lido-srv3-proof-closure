import LidoSRv3.Audit.Source.TrioComposition.MemoryProducer
import LidoSRv3.Audit.Source.TrioComposition.AllocationParentCalls

/-! Parent call tree with the interleaved producer allocation guards. Canonical
consumer ABI bytes and checked Ether conversion follow the producer. Physical
copies/stores, consumer call memory, pointer provenance and gas remain open. -/
namespace LidoSRv3.Audit.Source.TrioComposition.MemoryParentCalls
open TrioAlloc1

def program (pointer : Word) (layout : Layout) (storage : Storage) (config : Config)
    (amount : Word) (isTopUp : Bool) : CallTree.Program ParentOutput := do
  let count := storage (countSlot layout)
  if count.val = 0 then
    let _ ← CallTree.check (MemoryGuard.check pointer count)
    pure ⟨word 0,[],[]⟩
  else
    let demand ← CallTree.check (checkedDiv amount config.maxEBType1)
    let (produced,_) ← MemoryProducer.producer pointer layout storage ⟨config,demand,isTopUp⟩
    ParentCalls.afterProducer count.val config demand produced

theorem prefix_safe (pointer count : Word)
    (space : pointer.val+608*count.val+320 ≤ 2^32) :
    MemoryGuard.check pointer count = .ok (word (pointer.val+224*count.val+64)) := by
  have bound : pointer.val+224*count.val+64 < 2^64 := by omega
  simp [MemoryGuard.check, MemoryGuard.run, bound, Except.mapError]

set_option maxRecDepth 4096 in
/-- The physical count and a single whole-producer budget discharge every
modeled allocation, preserving the complete original parent call tree. -/
theorem program_eq (pointer : Word) (layout : Layout) (storage : Storage) (config : Config)
    (amount : Word) (isTopUp : Bool)
    (countBound : (storage (countSlot layout)).val ≤ 32)
    (space : pointer.val+608*(storage (countSlot layout)).val+320 ≤ 2^32) :
    program pointer layout storage config amount isTopUp =
      ParentCalls.program layout storage config amount isTopUp := by
  simp only [program, ParentCalls.program]
  by_cases empty : (storage (countSlot layout)).val = 0
  · simp [empty, prefix_safe pointer _ space, RowMemory.check_ok_bind]
  · simp only [empty, ↓reduceIte, ParentCalls.afterDivision,
      MemoryProducer.producer_exact pointer layout storage _ countBound space,
      RowMemory.bind_assoc, RowMemory.pure_bind]

theorem correspondence (pointer : Word) (layout : Layout) (storage : Storage)
    (oracle : StaticOracle) (config : Config) (amount : Word) (isTopUp : Bool)
    (countBound : (storage (countSlot layout)).val ≤ 32)
    (space : pointer.val+608*(storage (countSlot layout)).val+320 ≤ 2^32) :
    CallTree.evaluate oracle (program pointer layout storage config amount isTopUp) =
      getDepositAllocationsABI layout storage oracle config amount isTopUp := by
  rw [program_eq pointer layout storage config amount isTopUp countBound space,
    ParentCalls.correspondence]

theorem abi_extent (pointer : Word) (layout : Layout) (storage : Storage)
    (oracle : StaticOracle) (config : Config) (amount : Word) (isTopUp : Bool) (before : Transcript)
    (space : pointer.val+608*(storage (countSlot layout)).val+320 ≤ 2^32) :
    ReachableABIExtent layout storage oracle config amount isTopUp before :=
  AllocationParentCalls.successful_prefix_extent pointer layout storage oracle config amount
    isTopUp _ before (prefix_safe pointer _ space)

#print axioms program_eq
#print axioms correspondence
#print axioms abi_extent
end LidoSRv3.Audit.Source.TrioComposition.MemoryParentCalls
