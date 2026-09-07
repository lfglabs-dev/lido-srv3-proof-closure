import LidoSRv3.Audit.Source.TrioAlloc1.AdmissionFacts

namespace LidoSRv3.Audit.Source.TrioAlloc1
namespace RecordInvariant

open AdmissionFacts (FreshRecords nameSlot)

/-- Only storage reads used by the fresh-record invariant, with the admission-ID
domain restricted to uint24. This is a frame condition, not hash injectivity. -/
structure SameReads (l : Layout) (before after : Storage) : Prop where
  count : after (countSlot l) = before (countSlot l)
  last : field (after (AdmissionChecks.lastIdSlot l)) 0 24 =
    field (before (AdmissionChecks.lastIdSlot l)) 0 24
  ids : ∀ i, i < (before (countSlot l)).val → after (idSlot l i) = before (idSlot l i)
  positions : ∀ id, id.val < 2^24 →
    after (ShareWriter.modulePositionSlot l id) = before (ShareWriter.modulePositionSlot l id)
  names : ∀ id, field (before (AdmissionChecks.lastIdSlot l)) 0 24 < id.val →
    id.val < 2^24 → after (nameSlot l id) = before (nameSlot l id)

theorem preserves (l : Layout) (before after : Storage) (records : FreshRecords l before)
    (frame : SameReads l before after) : FreshRecords l after := by
  constructor
  · intro id bound present
    rw [frame.positions id bound] at present
    obtain ⟨i, inside, same⟩ := records.position_complete id bound present
    exact ⟨i, by simpa only [frame.count] using inside, by rw [frame.ids i inside, same]⟩
  · intro i inside
    rw [frame.count] at inside
    rw [frame.ids i inside, frame.last]
    exact records.ids_bounded i inside
  · intro id beyond bound
    rw [frame.last] at beyond
    rw [frame.names id beyond bound]
    exact records.future_names id beyond bound

structure SeparateFrom (l : Layout) (s : Storage) (target : Word) : Prop where
  count : countSlot l ≠ target
  last : AdmissionChecks.lastIdSlot l ≠ target
  ids : ∀ i, i < (s (countSlot l)).val → idSlot l i ≠ target
  positions : ∀ id, id.val < 2^24 → ShareWriter.modulePositionSlot l id ≠ target
  names : ∀ id, field (s (AdmissionChecks.lastIdSlot l)) 0 24 < id.val →
    id.val < 2^24 → nameSlot l id ≠ target

theorem share_frame (l : Layout) (s : Storage) (input : ShareWriter.Input)
    (separate : SeparateFrom l s (moduleSlot l input.moduleId)) :
    SameReads l s (ShareWriter.execute l s input).storage := by
  constructor
  · exact ShareWriter.execute_other_slot_preserved l s input _ separate.count
  · rw [ShareWriter.execute_other_slot_preserved l s input _ separate.last]
  · intro i hi
    exact ShareWriter.execute_other_slot_preserved l s input _ (separate.ids i hi)
  · intro id bound
    exact ShareWriter.execute_other_slot_preserved l s input _ (separate.positions id bound)
  · intro id beyond bound
    exact ShareWriter.execute_other_slot_preserved l s input _ (separate.names id beyond bound)

theorem share_preserves (l : Layout) (s : Storage) (input : ShareWriter.Input)
    (records : FreshRecords l s)
    (separate : SeparateFrom l s (moduleSlot l input.moduleId)) :
    FreshRecords l (ShareWriter.execute l s input).storage :=
  preserves l s _ records (share_frame l s input separate)

theorem parameter_helper_frame (l : Layout) (s : Storage) (input : ParameterWriter.Input)
    (config : SeparateFrom l s (moduleSlot l input.moduleId))
    (deposit : SeparateFrom l s (word ((moduleSlot l input.moduleId).val+1))) :
    SameReads l s (ParameterWriter.executeHelper l s input).storage := by
  constructor
  · exact ParameterWriter.helper_other_slot l s input _ config.count deposit.count
  · rw [ParameterWriter.helper_other_slot l s input _ config.last deposit.last]
  · intro i hi
    exact ParameterWriter.helper_other_slot l s input _ (config.ids i hi) (deposit.ids i hi)
  · intro id bound
    exact ParameterWriter.helper_other_slot l s input _ (config.positions id bound) (deposit.positions id bound)
  · intro id beyond bound
    exact ParameterWriter.helper_other_slot l s input _ (config.names id beyond bound) (deposit.names id beyond bound)

theorem parameter_preserves (l : Layout) (s : Storage) (input : ParameterWriter.Input)
    (records : FreshRecords l s)
    (config : SeparateFrom l s (moduleSlot l input.moduleId))
    (deposit : SeparateFrom l s (word ((moduleSlot l input.moduleId).val+1))) :
    FreshRecords l (ParameterWriter.execute l s input).storage := by
  unfold ParameterWriter.execute
  split
  · exact records
  · split
    · exact records
    · exact preserves l s _ records (parameter_helper_frame l s input config deposit)

theorem admission_last_id (l : Layout) (s : Storage) (input : AdmissionWriter.Input)
    (success : AdmissionWriter.Success) (run : AdmissionWriter.stages l s input = .ok success)
    (separate : AdmissionChecks.lastIdSlot l ≠ word ((moduleSlot l success.id).val+1)) :
    field (success.storage (AdmissionChecks.lastIdSlot l)) 0 24 = success.id.val := by
  obtain ⟨_, named, _, _, _, _, storage⟩ := AdmissionFacts.success_witness l s input success run
  have idBound := (AdmissionFacts.success_id_bounds l s input success run).2.2
  rw [storage]
  simp only [AdmissionFacts.finalStorage, ShareWriter.write, if_neg separate, ite_true]
  have originalBound := ((ParameterWriter.executeHelper l named
    (AdmissionWriter.parameters input success.id)).storage (AdmissionChecks.lastIdSlot l)).isLt
  simp only [AdmissionWriter.lastIdWord, field, word]
  omega

structure AdmissionSeparation (l : Layout) (s : Storage) (id : Word) : Prop where
  append : AdmissionFacts.AppendSeparation l s id
  last_deposit : AdmissionChecks.lastIdSlot l ≠ word ((moduleSlot l id).val+1)
  other_positions : ∀ other, other.val < 2^24 → other ≠ id →
    AdmissionFacts.Untouched l s id (ShareWriter.modulePositionSlot l other)
  future_names : ∀ other, id.val < other.val → other.val < 2^24 →
    AdmissionFacts.Untouched l s id (nameSlot l other)

/-- Successful admission preserves the fresh-record predicate itself. All aliasing
conditions are limited to the checked uint24 ID domain; no global hash axiom is used. -/
theorem admission_preserves (l : Layout) (s : Storage) (input : AdmissionWriter.Input)
    (success : AdmissionWriter.Success) (run : AdmissionWriter.stages l s input = .ok success)
    (records : FreshRecords l s) (separate : AdmissionSeparation l s success.id) :
    FreshRecords l success.storage := by
  have fresh := AdmissionFacts.successful_record_freshness l s input success run records
  have count := AdmissionFacts.success_count_growth l s input success run separate.append.count fresh.2 fresh.1
  have element := AdmissionFacts.success_new_element l s input success run separate.append.count
    fresh.2 fresh.1 separate.append.element_position separate.append.element_post
  have last := admission_last_id l s input success run separate.last_deposit
  have idBounds := AdmissionFacts.success_id_bounds l s input success run
  have oldIds := fun i hi => AdmissionFacts.success_other_slot l s input success run
    separate.append.count fresh.2 (idSlot l i) (separate.append.old_ids i hi)
  constructor
  · intro id bound present
    by_cases same : id = success.id
    · subst id
      exact ⟨(s (countSlot l)).val, by omega, element⟩
    · have position := AdmissionFacts.success_other_slot l s input success run
        separate.append.count fresh.2 _ (separate.other_positions id bound same)
      rw [position] at present
      obtain ⟨i, inside, equal⟩ := records.position_complete id bound present
      exact ⟨i, by omega, by rw [oldIds i inside, equal]⟩
  · intro i inside
    rw [last]
    by_cases old : i < (s (countSlot l)).val
    · rw [oldIds i old]
      have bound := records.ids_bounded i old
      omega
    · have final : i = (s (countSlot l)).val := by omega
      subst i
      rw [element]
      omega
  · intro id beyond bound
    rw [last] at beyond
    rw [AdmissionFacts.success_other_slot l s input success run separate.append.count fresh.2 _
      (separate.future_names id beyond bound)]
    exact records.future_names id (by omega) bound

theorem public_admission_preserves (l : Layout) (s : Storage) (input : AdmissionWriter.Input)
    (records : FreshRecords l s)
    (layout : ∀ success, AdmissionWriter.stages l s input = .ok success →
      AdmissionSeparation l s success.id) :
    FreshRecords l (AdmissionWriter.execute l s input).storage := by
  unfold AdmissionWriter.execute
  cases run : AdmissionWriter.stages l s input with
  | error reason => exact records
  | ok success => exact admission_preserves l s input success run records (layout success run)

/-- Histories of the three implemented public writers. Initialization, migration,
and the remaining router writer families must be added before this is a complete
router lifecycle. Every transition is an actual SOURCE execution, not an assumed
post-state invariant. Layout conditions remain explicit. -/
inductive History (l : Layout) : Storage → Prop where
  | zero (s : Storage) (empty : ∀ slot, s slot = 0) : History l s
  | share (s : Storage) (input : ShareWriter.Input) (before : History l s)
      (layout : SeparateFrom l s (moduleSlot l input.moduleId)) :
      History l (ShareWriter.execute l s input).storage
  | parameter (s : Storage) (input : ParameterWriter.Input) (before : History l s)
      (config : SeparateFrom l s (moduleSlot l input.moduleId))
      (deposit : SeparateFrom l s (word ((moduleSlot l input.moduleId).val+1)))
      (rows : ∀ i, i < (s (countSlot l)).val →
        moduleSlot l (s (idSlot l i)) ≠ word ((moduleSlot l input.moduleId).val+1)) :
      History l (ParameterWriter.execute l s input).storage
  | admission (s : Storage) (input : AdmissionWriter.Input) (before : History l s)
      (layout : ∀ success, AdmissionWriter.stages l s input = .ok success →
        AdmissionSeparation l s success.id) :
      History l (AdmissionWriter.execute l s input).storage

theorem history_invariants (l : Layout) (s : Storage) (history : History l s) :
    WriterInvariant.Holds l s ∧ FreshRecords l s := by
  induction history with
  | zero s empty =>
    exact ⟨WriterInvariant.empty l s (by simp [empty]), AdmissionFacts.zero_fresh_records l s empty⟩
  | share s input _ layout ih =>
    exact ⟨WriterInvariant.share_writer_preserves l s input ih.1 layout.count layout.ids,
      share_preserves l s input ih.2 layout⟩
  | parameter s input _ config deposit rows ih =>
    exact ⟨WriterInvariant.parameter_writer_preserves l s input ih.1
      ⟨config.count, deposit.count, config.ids, deposit.ids, rows⟩,
      parameter_preserves l s input ih.2 config deposit⟩
  | admission s input _ layout ih =>
    exact ⟨AdmissionFacts.public_preserves l s input ih.1 ih.2 (fun success run => (layout success run).append),
      public_admission_preserves l s input ih.2 layout⟩

end RecordInvariant
end LidoSRv3.Audit.Source.TrioAlloc1
