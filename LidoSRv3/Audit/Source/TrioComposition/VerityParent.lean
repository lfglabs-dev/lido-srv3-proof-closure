import LidoSRv3.Audit.Source.TrioComposition.MemoryParentCalls
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

/-- VM execution with interleaved producer allocation guards. The supplied
pointer, physical stores/copies and gas remain source-model boundaries. -/
def executeWithMemory (pointer : Word) (layout : Layout) (config : Config)
    (amount : Word) (isTopUp : Bool) (adversary : DenoteExternalCalls.AdversaryModel)
    (state : DenoteExternalCalls.CallState) (before : Transcript := []) :=
  DenoteExternalCalls.denote (VerityProducer.translate before
    (MemoryParentCalls.program pointer layout (VerityProducer.worldStorage state.world)
      config amount isTopUp)) adversary state

theorem memory_correspondence (pointer : Word) (layout : Layout) (config : Config)
    (amount : Word) (isTopUp : Bool) (adversary : DenoteExternalCalls.AdversaryModel)
    (state : DenoteExternalCalls.CallState) (before : Transcript) :
    (executeWithMemory pointer layout config amount isTopUp adversary state before).1 =
      CallTree.evaluate (VerityProducer.sourceOracle adversary state.world)
        (MemoryParentCalls.program pointer layout (VerityProducer.worldStorage state.world)
          config amount isTopUp) before ∧
    (executeWithMemory pointer layout config amount isTopUp adversary state before).2.world = state.world :=
  VerityProducer.translation_correspondence _ adversary state before

theorem memory_public_iff (pointer : Word) (layout : Layout) (config : Config)
    (amount : Word) (isTopUp : Bool) (adversary : DenoteExternalCalls.AdversaryModel)
    (state : DenoteExternalCalls.CallState) (before after : Transcript)
    (result : Except Failure ParentOutput)
    (countBound : (VerityProducer.worldStorage state.world (countSlot layout)).val ≤ 32)
    (space : pointer.val+608*(VerityProducer.worldStorage state.world (countSlot layout)).val+320 ≤ 2^32) :
    ParentSpec.Public layout (VerityProducer.worldStorage state.world)
      (VerityProducer.sourceOracle adversary state.world) config amount isTopUp before result after ↔
      (executeWithMemory pointer layout config amount isTopUp adversary state before).1 = (result, after) := by
  rw [(memory_correspondence pointer layout config amount isTopUp adversary state before).1]
  rw [MemoryParentCalls.correspondence pointer layout _ _ _ _ _ countBound space]
  exact public_abi_iff _ _ _ _ _ _ _ _ _
    (MemoryParentCalls.abi_extent pointer layout _ _ _ _ _ before space)

#print axioms memory_correspondence
#print axioms memory_public_iff

#print axioms correspondence
#print axioms public_iff
end LidoSRv3.Audit.Source.TrioComposition.VerityParent
