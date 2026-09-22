import LidoSRv3.Audit.Source.TrioComposition.ParentABI
import LidoSRv3.Audit.Source.TrioAlloc1.VerityProducer

namespace LidoSRv3.Audit.Source.TrioComposition.VerityParentResult
open TrioAlloc1
open Compiler.CompilationModel

/-- The returned producer arrays flow into the library ABI and checked ether
conversion in the same execution. No final array or successful reply is supplied.
The library here is its byte executor, not deployed DELEGATECALL refinement. -/
def program (layout : Layout) (words : Storage) (config : Config)
    (amount : Word) (isTopUp : Bool) : CallTree.Program ParentOutput := do
  let count := (words (countSlot layout)).val
  if count = 0 then
    pure ⟨word 0, [], []⟩
  else
    let demand ← CallTree.check (checkedDiv amount config.maxEBType1)
    let produced ← CallTree.producer layout words ⟨config, demand, isTopUp⟩
    if demand.val > 0 then
      let result ← CallTree.check (libraryThroughABI produced demand)
      let total ← CallTree.check (checked (result.amount.val * config.maxEBType1.val))
      let (deltas, totals) ← CallTree.check
        (convertPositive config.maxEBType1 count produced.allocations result.buckets)
      pure ⟨total, deltas, totals⟩
    else
      let (deltas, totals) ← CallTree.check (convertZero config.maxEBType1 count produced.allocations)
      pure ⟨word 0, deltas, totals⟩

theorem program_correspondence (layout : Layout) (words : Storage) (oracle : StaticOracle)
    (config : Config) (amount : Word) (isTopUp : Bool) :
    CallTree.evaluate oracle (program layout words config amount isTopUp) =
      getDepositAllocationsABI layout words oracle config amount isTopUp := by
  simp only [program, getDepositAllocationsABI, CallTree.evaluate_ite,
    CallTree.evaluate_monad_bind, CallTree.evaluate_check, CallTree.evaluate_pure,
    CallTree.producer_correspondence]
  rfl

def execute (layout : Layout) (config : Config) (amount : Word) (isTopUp : Bool)
    (adversary : DenoteExternalCalls.AdversaryModel) (state : DenoteExternalCalls.CallState)
    (before : Transcript) :=
  DenoteExternalCalls.denote (VerityProducer.translate before
    (program layout (VerityProducer.accountStorage state.world) config amount isTopUp)) adversary state

/-- Exact success/failure, arrays and complete module-call transcript of the VM
execution, followed by world preservation. Empty-count and checked failures are
included; no supported-module bounds or desired result equality is assumed. -/
theorem execute_correspondence (layout : Layout) (config : Config) (amount : Word) (isTopUp : Bool)
    (adversary : DenoteExternalCalls.AdversaryModel) (state : DenoteExternalCalls.CallState)
    (before : Transcript) :
    (execute layout config amount isTopUp adversary state before).1 =
      getDepositAllocationsABI layout (VerityProducer.accountStorage state.world)
        (VerityProducer.sourceOracle adversary state.world) config amount isTopUp before ∧
    (execute layout config amount isTopUp adversary state before).2.world = state.world := by
  have h := VerityProducer.translation_correspondence
    (program layout (VerityProducer.accountStorage state.world) config amount isTopUp)
    adversary state before
  rw [program_correspondence] at h
  exact h

#print axioms execute_correspondence
end LidoSRv3.Audit.Source.TrioComposition.VerityParentResult
