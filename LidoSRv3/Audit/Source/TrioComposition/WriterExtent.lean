import LidoSRv3.Audit.Source.TrioComposition.ParentABI
import LidoSRv3.Audit.Source.TrioAlloc1.WriterInvariant

/-! Numeric ABI extent from the producer's physical enumeration invariant.
This connects the checked share-writer transition to the parent obligation;
all-writer/deployment reachability remains a separate requirement. -/
namespace LidoSRv3.Audit.Source.TrioComposition
open TrioAlloc1

theorem bounded_count_abi_extent (layout : Layout) (storage : Storage) (oracle : StaticOracle)
    (config : Config) (amount : Word) (isTopUp : Bool) (before : Transcript)
    (countBound : (storage (countSlot layout)).val ≤ 32) :
    ReachableABIExtent layout storage oracle config amount isTopUp before := by
  intro demand output middle _ executed _
  have order := producer_router_order layout storage oracle ⟨config, demand, isTopUp⟩
    before middle output executed
  change output.identities = routerOrder layout storage at order
  have length : output.allocations.length = (storage (countSlot layout)).val := by
    rw [output.allocations_length, order]
    simp [routerOrder]
  have lengths := output_lengths_equal output
  simp only [TrioAlloc2.LibraryABI.encodeArguments, TrioAlloc2.producerArguments,
    List.length_append, encodeWord_length, encodeArray_length]
  omega

theorem writer_invariant_abi_extent (layout : Layout) (storage : Storage) (oracle : StaticOracle)
    (config : Config) (amount : Word) (isTopUp : Bool) (before : Transcript)
    (invariant : WriterInvariant.Holds layout storage) :
    ReachableABIExtent layout storage oracle config amount isTopUp before :=
  bounded_count_abi_extent layout storage oracle config amount isTopUp before invariant.1

/-- Every outcome of the actual share writer preserves the numeric parent ABI
obligation, including rejected writes. The finite slot-separation and initial
physical invariant premises are retained explicitly. -/
theorem share_writer_abi_extent (layout : Layout) (storage : Storage)
    (input : ShareWriter.Input) (oracle : StaticOracle) (config : Config)
    (amount : Word) (isTopUp : Bool) (before : Transcript)
    (invariant : WriterInvariant.Holds layout storage)
    (countSeparate : countSlot layout ≠ moduleSlot layout input.moduleId)
    (idsSeparate : ∀ i, i < (storage (countSlot layout)).val →
      idSlot layout i ≠ moduleSlot layout input.moduleId) :
    ReachableABIExtent layout (ShareWriter.execute layout storage input).storage
      oracle config amount isTopUp before :=
  writer_invariant_abi_extent layout _ oracle config amount isTopUp before
    (WriterInvariant.share_writer_preserves layout storage input invariant countSeparate idsSeparate)

#print axioms share_writer_abi_extent

/-- Public parameter updates preserve the same parent extent obligation. This
uses the executed writer's physical invariant theorem for every outcome. -/
theorem parameter_writer_abi_extent (layout : Layout) (storage : Storage)
    (input : ParameterWriter.Input) (oracle : StaticOracle) (config : Config)
    (amount : Word) (isTopUp : Bool) (before : Transcript)
    (invariant : WriterInvariant.Holds layout storage)
    (separate : WriterInvariant.ParameterSeparation layout storage input) :
    ReachableABIExtent layout (ParameterWriter.execute layout storage input).storage
      oracle config amount isTopUp before :=
  writer_invariant_abi_extent layout _ oracle config amount isTopUp before
    (WriterInvariant.parameter_writer_preserves layout storage input invariant separate)

#print axioms parameter_writer_abi_extent
end LidoSRv3.Audit.Source.TrioComposition
