import LidoSRv3.Audit.Source.TrioComposition.MemoryParentCalls
import LidoSRv3.Audit.Source.TrioAlloc1.StatusWriter

/-! Derive the producer's allocation budget from its physical writer invariant.
The pointer bound and writer lifecycle/layout obligations remain explicit;
this is not an assertion of whole-deployment reachability. -/
namespace LidoSRv3.Audit.Source.TrioComposition.WriterMemory
open TrioAlloc1

theorem budget (pointer : Word) (layout : Layout) (storage : Storage)
    (invariant : WriterInvariant.Holds layout storage) (small : pointer.val ≤ 2^31) :
    pointer.val+608*(storage (countSlot layout)).val+320 ≤ 2^32 := by
  have count := invariant.1
  omega

theorem from_invariant (pointer : Word) (layout : Layout) (storage : Storage)
    (config : Config) (amount : Word) (isTopUp : Bool)
    (invariant : WriterInvariant.Holds layout storage) (small : pointer.val ≤ 2^31) :
    MemoryParentCalls.program pointer layout storage config amount isTopUp =
      ParentCalls.program layout storage config amount isTopUp :=
  MemoryParentCalls.program_eq pointer layout storage config amount isTopUp invariant.1
    (budget pointer layout storage invariant small)

theorem after_share_writer (pointer : Word) (layout : Layout) (storage : Storage)
    (input : ShareWriter.Input) (config : Config) (amount : Word) (isTopUp : Bool)
    (invariant : WriterInvariant.Holds layout storage) (small : pointer.val ≤ 2^31)
    (countSeparate : countSlot layout ≠ moduleSlot layout input.moduleId)
    (idsSeparate : ∀ i, i < (storage (countSlot layout)).val →
      idSlot layout i ≠ moduleSlot layout input.moduleId) :
    MemoryParentCalls.program pointer layout (ShareWriter.execute layout storage input).storage
      config amount isTopUp =
      ParentCalls.program layout (ShareWriter.execute layout storage input).storage config amount isTopUp :=
  from_invariant pointer layout _ config amount isTopUp
    (WriterInvariant.share_writer_preserves layout storage input invariant countSeparate idsSeparate) small

theorem after_parameter_writer (pointer : Word) (layout : Layout) (storage : Storage)
    (input : ParameterWriter.Input) (config : Config) (amount : Word) (isTopUp : Bool)
    (invariant : WriterInvariant.Holds layout storage) (small : pointer.val ≤ 2^31)
    (separate : WriterInvariant.ParameterSeparation layout storage input) :
    MemoryParentCalls.program pointer layout (ParameterWriter.execute layout storage input).storage
      config amount isTopUp =
      ParentCalls.program layout (ParameterWriter.execute layout storage input).storage config amount isTopUp :=
  from_invariant pointer layout _ config amount isTopUp
    (WriterInvariant.parameter_writer_preserves layout storage input invariant separate) small

theorem after_admission (pointer : Word) (layout : Layout) (storage : Storage)
    (input : AdmissionWriter.Input) (config : Config) (amount : Word) (isTopUp : Bool)
    (invariant : WriterInvariant.Holds layout storage) (small : pointer.val ≤ 2^31)
    (records : AdmissionFacts.FreshRecords layout storage)
    (separate : ∀ success, AdmissionWriter.stages layout storage input = .ok success →
      AdmissionFacts.AppendSeparation layout storage success.id) :
    MemoryParentCalls.program pointer layout (AdmissionWriter.execute layout storage input).storage
      config amount isTopUp =
      ParentCalls.program layout (AdmissionWriter.execute layout storage input).storage config amount isTopUp :=
  from_invariant pointer layout _ config amount isTopUp
    (AdmissionFacts.public_preserves layout storage input invariant records separate) small

/-- No post-state count/share premise is supplied: the actual covered history
establishes it, including rejected public writes. Initialization, migration and
uncaptured writer families remain outside this four-family history. -/
theorem from_history (pointer : Word) (layout : Layout) (storage : Storage)
    (config : Config) (amount : Word) (isTopUp : Bool)
    (history : StatusWriter.History layout storage) (small : pointer.val ≤ 2^31) :
    MemoryParentCalls.program pointer layout storage config amount isTopUp =
      ParentCalls.program layout storage config amount isTopUp :=
  from_invariant pointer layout storage config amount isTopUp
    (StatusWriter.history_invariants layout storage history).1 small

theorem history_public_iff (pointer : Word) (layout : Layout) (storage : Storage)
    (oracle : StaticOracle) (config : Config) (amount : Word) (isTopUp : Bool)
    (before after : Transcript) (result : Except Failure ParentOutput)
    (history : StatusWriter.History layout storage) (small : pointer.val ≤ 2^31) :
    ParentSpec.Public layout storage oracle config amount isTopUp before result after ↔
      CallTree.evaluate oracle (MemoryParentCalls.program pointer layout storage config amount isTopUp)
        before = (result,after) := by
  rw [from_history pointer layout storage config amount isTopUp history small,
    ParentCalls.correspondence]
  exact public_abi_iff _ _ _ _ _ _ _ _ _
    (MemoryParentCalls.abi_extent pointer layout storage oracle config amount isTopUp before
      (budget pointer layout storage (StatusWriter.history_invariants layout storage history).1 small))

#print axioms from_history
#print axioms history_public_iff
#print axioms from_invariant
#print axioms after_share_writer
#print axioms after_parameter_writer
#print axioms after_admission
end LidoSRv3.Audit.Source.TrioComposition.WriterMemory
