import LidoSRv3.Audit.Source.TrioComposition.ParentCalls
import LidoSRv3.Audit.Source.TrioAlloc1.VerityProducer

/-! Actual pinned Verity call-VM execution of the parent call tree. The VM
executes module STATICCALLs and response-dependent continuations; the library
ABI/allocator remains the SOURCE byte interpreter. Gas, compiler memory,
deployed DELEGATECALL and full recursive callback observation remain open. -/
namespace LidoSRv3.Audit.Source.TrioComposition.VerityParent
open TrioAlloc1
open Compiler.CompilationModel

def execute (layout : Layout) (config : Config) (amount : Word) (isTopUp : Bool)
    (adversary : DenoteExternalCalls.AdversaryModel) (state : DenoteExternalCalls.CallState)
    (before : Transcript := []) :=
  DenoteExternalCalls.denote (VerityProducer.translate before
    (ParentCalls.program layout (VerityProducer.worldStorage state.world) config amount isTopUp))
    adversary state

theorem correspondence (layout : Layout) (config : Config) (amount : Word) (isTopUp : Bool)
    (adversary : DenoteExternalCalls.AdversaryModel) (state : DenoteExternalCalls.CallState)
    (before : Transcript) :
    (execute layout config amount isTopUp adversary state before).1 =
      getDepositAllocationsABI layout (VerityProducer.worldStorage state.world)
        (VerityProducer.sourceOracle adversary state.world) config amount isTopUp before ∧
    (execute layout config amount isTopUp adversary state before).2.world = state.world := by
  have h := VerityProducer.translation_correspondence
    (ParentCalls.program layout (VerityProducer.worldStorage state.world) config amount isTopUp)
    adversary state before
  rw [ParentCalls.correspondence] at h
  exact h

/-- Independent result/transcript specification for the VM execution, retaining
the explicit compiler allocation obligation from the ABI parent theorem. -/
theorem public_iff (layout : Layout) (config : Config) (amount : Word) (isTopUp : Bool)
    (adversary : DenoteExternalCalls.AdversaryModel) (state : DenoteExternalCalls.CallState)
    (before after : Transcript) (result : Except Failure ParentOutput)
    (extent : ReachableABIExtent layout (VerityProducer.worldStorage state.world)
      (VerityProducer.sourceOracle adversary state.world) config amount isTopUp before) :
    ParentSpec.Public layout (VerityProducer.worldStorage state.world)
      (VerityProducer.sourceOracle adversary state.world) config amount isTopUp before result after ↔
      (execute layout config amount isTopUp adversary state before).1 = (result, after) := by
  rw [(correspondence layout config amount isTopUp adversary state before).1]
  exact public_abi_iff _ _ _ _ _ _ _ _ _ extent

#print axioms correspondence
#print axioms public_iff
end LidoSRv3.Audit.Source.TrioComposition.VerityParent
