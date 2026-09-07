import LidoSRv3.Audit.Source.TrioComposition.ParentABI
import LidoSRv3.Audit.Source.TrioAlloc1.CallTree

/-! Deferred parent call tree. Producer calls execute before the canonical ABI
consumer and checked Ether conversions. This is not a completed-trace replay. -/
namespace LidoSRv3.Audit.Source.TrioComposition.ParentCalls
open TrioAlloc1

def afterProducer (count : Nat) (config : Config) (demand : Word)
    (produced : CapacityOutput) : CallTree.Program ParentOutput := do
  if demand.val > 0 then
    let result ← CallTree.check (libraryThroughABI produced demand)
    let total ← CallTree.check (checked (result.amount.val * config.maxEBType1.val))
    let (deltas, totals) ← CallTree.check
      (convertPositive config.maxEBType1 count produced.allocations result.buckets)
    pure ⟨total, deltas, totals⟩
  else
    let (deltas, totals) ← CallTree.check
      (convertZero config.maxEBType1 count produced.allocations)
    pure ⟨word 0, deltas, totals⟩

def afterDivision (layout : Layout) (storage : Storage) (config : Config)
    (demand : Word) (isTopUp : Bool) : CallTree.Program ParentOutput := do
  let produced ← CallTree.producer layout storage ⟨config,demand,isTopUp⟩
  afterProducer (storage (countSlot layout)).val config demand produced

def program (layout : Layout) (storage : Storage) (config : Config)
    (amount : Word) (isTopUp : Bool) : CallTree.Program ParentOutput := do
  let count := (storage (countSlot layout)).val
  if count = 0 then
    pure ⟨word 0, [], []⟩
  else
    let demand ← CallTree.check (checkedDiv amount config.maxEBType1)
    afterDivision layout storage config demand isTopUp

theorem correspondence (layout : Layout) (storage : Storage) (oracle : StaticOracle)
    (config : Config) (amount : Word) (isTopUp : Bool) :
    CallTree.evaluate oracle (program layout storage config amount isTopUp) =
      getDepositAllocationsABI layout storage oracle config amount isTopUp := by
  simp only [program, afterDivision, afterProducer, getDepositAllocationsABI, CallTree.evaluate_ite,
    CallTree.evaluate_monad_bind, CallTree.evaluate_check, CallTree.producer_correspondence,
    CallTree.evaluate_pure]
  rfl

#print axioms correspondence
end LidoSRv3.Audit.Source.TrioComposition.ParentCalls
