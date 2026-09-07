import LidoSRv3.Audit.Source.TrioComposition.AllocationParentCalls
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

/-- VM execution with the proved allocation-guard prefix. The supplied pointer
and prefix placement remain source-model boundaries, not physical VM memory. -/
def executeWithMemory (pointer : Word) (layout : Layout) (config : Config)
    (amount : Word) (isTopUp : Bool) (adversary : DenoteExternalCalls.AdversaryModel)
    (state : DenoteExternalCalls.CallState) (before : Transcript := []) :=
  DenoteExternalCalls.denote (VerityProducer.translate before
    (AllocationParentCalls.program pointer layout (VerityProducer.worldStorage state.world)
      config amount isTopUp)) adversary state

theorem memory_correspondence (pointer : Word) (layout : Layout) (config : Config)
    (amount : Word) (isTopUp : Bool) (adversary : DenoteExternalCalls.AdversaryModel)
    (state : DenoteExternalCalls.CallState) (before : Transcript) :
    (executeWithMemory pointer layout config amount isTopUp adversary state before).1 =
      CallTree.evaluate (VerityProducer.sourceOracle adversary state.world)
        (AllocationParentCalls.program pointer layout (VerityProducer.worldStorage state.world)
          config amount isTopUp) before ∧
    (executeWithMemory pointer layout config amount isTopUp adversary state before).2.world = state.world :=
  VerityProducer.translation_correspondence _ adversary state before

theorem memory_public_iff (pointer : Word) (layout : Layout) (config : Config)
    (amount : Word) (isTopUp : Bool) (adversary : DenoteExternalCalls.AdversaryModel)
    (state : DenoteExternalCalls.CallState) (before after : Transcript)
    (result : Except Failure ParentOutput) (next : Word)
    (memory : MemoryGuard.check pointer
      (VerityProducer.worldStorage state.world (countSlot layout)) = .ok next) :
    ParentSpec.Public layout (VerityProducer.worldStorage state.world)
      (VerityProducer.sourceOracle adversary state.world) config amount isTopUp before result after ↔
      (executeWithMemory pointer layout config amount isTopUp adversary state before).1 = (result, after) := by
  rw [(memory_correspondence pointer layout config amount isTopUp adversary state before).1]
  rw [AllocationParentCalls.successful_prefix_correspondence pointer layout _ _ _ _ _ next memory]
  exact public_abi_iff _ _ _ _ _ _ _ _ _
    (AllocationParentCalls.successful_prefix_extent pointer layout _ _ _ _ _ next before memory)

#print axioms memory_correspondence
#print axioms memory_public_iff

#print axioms correspondence
#print axioms public_iff
end LidoSRv3.Audit.Source.TrioComposition.VerityParent
