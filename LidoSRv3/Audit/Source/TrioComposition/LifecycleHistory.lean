import LidoSRv3.Audit.Source.TrioAlloc1.ProxyGenesis
import LidoSRv3.Audit.Source.TrioComposition.WriterMemory
import LidoSRv3.Audit.Source.TrioComposition.FinalMemoryStoredParent

/-! Histories rooted in the actual modeled proxy initialization prefix. Public
ACL grants permit the subsequent four writer families to become authorized.
The finite storage separation and initializer callback model stay explicit;
proxy dispatch/final admin, migration and other writer families are separate. -/
namespace LidoSRv3.Audit.Source.TrioComposition.LifecycleHistory
open TrioAlloc1

/-- Physical layout obligations for initialization, not a post-state invariant
or a successful initializer/callback assumption. -/
structure Genesis (l : Layout) where
  implementation : Address
  input : Initialization.Input
  step : Nat → Storage → ShareWriter.Outcome
  prefixSeparate : RecordInvariant.SeparateFrom l ProxyGenesis.fresh ProxyGenesis.implementationSlot
  initSeparate : RecordInvariant.SeparateFrom l (ProxyGenesis.beforeDelegatecall implementation) Initialization.slot
  bodySeparate : Initialization.BodyRecordSeparation l
    (Initialization.begin (ProxyGenesis.beforeDelegatecall implementation) ⟨4, by decide⟩) input
  capSeparate : countSlot l ≠ AdmissionChecks.lastIdSlot l
  finishSeparate : RecordInvariant.SeparateFrom l
    (Initialization.routerBody l
      (Initialization.begin (ProxyGenesis.beforeDelegatecall implementation) ⟨4, by decide⟩)
      input (Initialization.notifications l step)).storage Initialization.slot

def Genesis.storage (g : Genesis l) : Storage :=
  (Initialization.execute l (ProxyGenesis.beforeDelegatecall g.implementation) g.input
    (Initialization.notifications l g.step)).storage

theorem genesis_invariants (l : Layout) (g : Genesis l) :
    WriterInvariant.Holds l g.storage ∧ AdmissionFacts.FreshRecords l g.storage :=
  ProxyGenesis.initialization_invariants l g.implementation g.input g.step
    g.prefixSeparate g.initSeparate g.bodySeparate g.capSeparate g.finishSeparate

/-- Every transition executes its real source guard chain, including rejected
writes. Unlike the zero-based component history, authorization can be granted. -/
inductive History (l : Layout) : Storage → Prop where
  | initialized (g : Genesis l) : History l g.storage
  | acl (s : Storage) (input : ACLWriter.Input) (before : History l s)
      (separate : ACLWriter.InvariantSeparation l s input) :
      History l (ACLWriter.execute l s input).storage
  | share (s : Storage) (input : ShareWriter.Input) (before : History l s)
      (layout : RecordInvariant.SeparateFrom l s (moduleSlot l input.moduleId)) :
      History l (ShareWriter.execute l s input).storage
  | parameter (s : Storage) (input : ParameterWriter.Input) (before : History l s)
      (config : RecordInvariant.SeparateFrom l s (moduleSlot l input.moduleId))
      (deposit : RecordInvariant.SeparateFrom l s (word ((moduleSlot l input.moduleId).val+1)))
      (rows : ∀ i, i < (s (countSlot l)).val →
        moduleSlot l (s (idSlot l i)) ≠ word ((moduleSlot l input.moduleId).val+1)) :
      History l (ParameterWriter.execute l s input).storage
  | admission (s : Storage) (input : AdmissionWriter.Input) (before : History l s)
      (layout : ∀ success, AdmissionWriter.stages l s input = .ok success →
        RecordInvariant.AdmissionSeparation l s success.id) :
      History l (AdmissionWriter.execute l s input).storage

  | status (s : Storage) (input : StatusWriter.Input) (before : History l s)
      (layout : RecordInvariant.SeparateFrom l s (moduleSlot l input.moduleId)) :
      History l (StatusWriter.execute l s input).storage

theorem invariants (l : Layout) (s : Storage) (history : History l s) :
    WriterInvariant.Holds l s ∧ AdmissionFacts.FreshRecords l s := by
  induction history with
  | initialized g => exact genesis_invariants l g
  | acl s input _ separate ih => exact ACLWriter.preserves l s input ih separate
  | share s input _ layout ih =>
    exact ⟨WriterInvariant.share_writer_preserves l s input ih.1 layout.count layout.ids,
      RecordInvariant.share_preserves l s input ih.2 layout⟩
  | parameter s input _ config deposit rows ih =>
    exact ⟨WriterInvariant.parameter_writer_preserves l s input ih.1
      ⟨config.count, deposit.count, config.ids, deposit.ids, rows⟩,
      RecordInvariant.parameter_preserves l s input ih.2 config deposit⟩
  | admission s input _ layout ih =>
    exact ⟨AdmissionFacts.public_preserves l s input ih.1 ih.2 (fun success run => (layout success run).append),
      RecordInvariant.public_admission_preserves l s input ih.2 layout⟩

  | status s input _ layout ih => exact StatusWriter.preserves l s input ih layout

/-- The physical count/share/identity invariant comes from actual initialization
and writer executions; it is not supplied as an unrelated post-state premise. -/
theorem parent_correspondence (pointer : Word) (l : Layout) (s : Storage)
    (config : Config) (amount : Word) (isTopUp : Bool)
    (history : History l s) (small : pointer.val ≤ 2^31) :
    MemoryParentCalls.program pointer l s config amount isTopUp =
      ParentCalls.program l s config amount isTopUp :=
  WriterMemory.from_invariant pointer l s config amount isTopUp (invariants l s history).1 small

/-- Initialization/ACL/public-writer histories now supply the corrected complete
allocation budget and independent all-outcome parent relation. -/
theorem final_parent_iff (pointer : Word) (l : Layout) (s : Storage)
    (oracle : StaticOracle) (config : Config) (amount : Word) (isTopUp : Bool)
    (before after : Transcript) (result : Except Failure ParentOutput)
    (history : History l s) (small : pointer.val ≤ 2^31) :
    ParentSpec.Public l s oracle config amount isTopUp before result after ↔
      CallTree.evaluate oracle (FinalMemoryParent.program pointer l s config amount isTopUp)
        before = (result,after) :=
  FinalMemoryParent.public_iff pointer l s oracle config amount isTopUp before after result
    (invariants l s history).1.1
    (FinalMemoryParent.budget_from_small_entry pointer (s (countSlot l)) small (invariants l s history).1.1)

/-- The same actual initialization/writer history supplies the count and
allocation budget of the single memory-storing and library-observing parent. -/
theorem stored_parent_iff (target : Address) (memory : MemoryWords) (pointer : Word)
    (l : Layout) (s : Storage) (oracle : StaticOracle) (config : Config)
    (amount : Word) (isTopUp : Bool) (before after : Transcript)
    (trace : MemoryTransportCall.Trace) (result : Except Failure ParentOutput)
    (history : History l s) (small : pointer.val ≤ 2^31) :
    ParentSpec.Public l s oracle config amount isTopUp before result after ↔
      FinalMemoryStoredParent.project
        (FinalMemoryStoredParent.program target memory pointer l s oracle config amount isTopUp before trace) =
        (result,after) :=
  FinalMemoryStoredParent.public_iff target memory pointer l s oracle config amount isTopUp
    before after trace result (invariants l s history).1.1
    (FinalMemoryParent.budget_from_small_entry pointer (s (countSlot l)) small (invariants l s history).1.1)

#print axioms stored_parent_iff

#print axioms final_parent_iff

#print axioms genesis_invariants
#print axioms invariants
#print axioms parent_correspondence
end LidoSRv3.Audit.Source.TrioComposition.LifecycleHistory
