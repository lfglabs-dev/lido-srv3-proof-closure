import LidoSRv3.Audit.Source.TrioAlloc1.Initialization

namespace LidoSRv3.Audit.Source.TrioAlloc1
namespace ProxyGenesis

/-- OZ 4.4.1 ERC1967Upgrade._IMPLEMENTATION_SLOT. The constructor writes this
before its initialization delegatecall. OssifiableProxy changes admin afterwards.
The bytecode/code-existence check, delegatecall dispatch and final admin transition
remain separate correspondence obligations; this is the physical storage boundary. -/
def implementationSlot : Word :=
  word 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc

def fresh : Storage := fun _ => 0

def beforeDelegatecall (implementation : Address) : Storage :=
  ShareWriter.write fresh implementationSlot (word implementation.val)

theorem implementation_stored (implementation : Address) :
    beforeDelegatecall implementation implementationSlot = word implementation.val := by
  simp only [beforeDelegatecall, ShareWriter.write, ite_true]

theorem other_slot_zero (implementation : Address) (target : Word)
    (separate : target ≠ implementationSlot) :
    beforeDelegatecall implementation target = 0 := by
  simp only [beforeDelegatecall, ShareWriter.write, if_neg separate, fresh]

theorem count_zero (l : Layout) (implementation : Address)
    (separate : countSlot l ≠ implementationSlot) :
    (beforeDelegatecall implementation (countSlot l)).val = 0 := by
  rw [other_slot_zero implementation _ separate]
  rfl

theorem records (l : Layout) (implementation : Address)
    (separate : RecordInvariant.SeparateFrom l fresh implementationSlot) :
    AdmissionFacts.FreshRecords l (beforeDelegatecall implementation) := by
  apply Initialization.write_records l fresh implementationSlot (word implementation.val)
    (AdmissionFacts.zero_fresh_records l fresh (fun _ => rfl))
    ⟨separate.count, separate.ids, separate.positions, separate.names⟩
  intro equal
  exact False.elim (separate.last equal)

/-- Compose initialization with its actual nonzero implementation-slot prefix.
Both capacity and fresh-record invariants are derived; no initializer success,
final invariant, or successful notification callback is a premise. Finite storage
separation is still explicit and does not assert global hash injectivity. -/
theorem initialization_invariants (l : Layout) (implementation : Address)
    (input : Initialization.Input) (step : Nat → Storage → ShareWriter.Outcome)
    (prefixSeparate : RecordInvariant.SeparateFrom l fresh implementationSlot)
    (initSeparate : RecordInvariant.SeparateFrom l (beforeDelegatecall implementation) Initialization.slot)
    (bodySeparate : Initialization.BodyRecordSeparation l
      (Initialization.begin (beforeDelegatecall implementation) ⟨4, by decide⟩) input)
    (capSeparate : countSlot l ≠ AdmissionChecks.lastIdSlot l)
    (finishSeparate : RecordInvariant.SeparateFrom l
      (Initialization.routerBody l
        (Initialization.begin (beforeDelegatecall implementation) ⟨4, by decide⟩)
        input (Initialization.notifications l step)).storage Initialization.slot) :
    WriterInvariant.Holds l
      (Initialization.execute l (beforeDelegatecall implementation) input
        (Initialization.notifications l step)).storage ∧
    AdmissionFacts.FreshRecords l
      (Initialization.execute l (beforeDelegatecall implementation) input
        (Initialization.notifications l step)).storage := by
  have empty := count_zero l implementation prefixSeparate.count
  constructor
  · exact Initialization.execute_from_empty l _ input step empty initSeparate.count
      bodySeparate.grant.count bodySeparate.credentials.count capSeparate
  · exact Initialization.execute_records l _ input step empty (records l implementation prefixSeparate)
      initSeparate bodySeparate finishSeparate

end ProxyGenesis
end LidoSRv3.Audit.Source.TrioAlloc1
