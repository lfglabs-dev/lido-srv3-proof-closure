import LidoSRv3.Audit.Source.TrioAlloc1.AdmissionWriter
import LidoSRv3.Audit.Source.TrioAlloc1.WriterInvariant

namespace LidoSRv3.Audit.Source.TrioAlloc1
namespace AdmissionFacts

open AdmissionWriter

/-- Actual state after the two address/status/credential assignments. -/
def configured (l : Layout) (s : Storage) (input : Input) (id : Word) : Storage :=
  let slot := moduleSlot l id
  let addressed := ShareWriter.write s slot (addressActiveWord (s slot) input.address)
  ShareWriter.write addressed slot (credentialsWord (addressed slot) input.wcType)

def finalStorage (l : Layout) (s : Storage) (input : Input) (id : Word) : Storage :=
  let last := AdmissionChecks.lastIdSlot l
  let numbered := ShareWriter.write s last (lastIdWord (s last) id)
  let deposit := word ((moduleSlot l id).val+1)
  ShareWriter.write numbered deposit (lastDepositWord (numbered deposit) input.timestamp input.blockNumber)

/-- Successful public admission exposes each actual intermediate state, without
assuming that its checks or parameter helper succeeded. -/
theorem success_witness (l : Layout) (s : Storage) (input : Input) (success : Success)
    (run : stages l s input = .ok success) :
    ∃ inserted named,
      AdmissionChecks.nextId l s = .ok success.id ∧
      EnumerationWriter.insert l s success.id = .ok inserted ∧
      StringStorage.writeShort l (configured l inserted input success.id)
        (word ((moduleSlot l success.id).val+3)) input.name = .ok named ∧
      (ParameterWriter.executeHelper l named (parameters input success.id)).result = .ok () ∧
      success.storage = finalStorage l
        (ParameterWriter.executeHelper l named (parameters input success.id)).storage input success.id := by
  have guard := stages_admission_checks l s input success run
  unfold stages at run
  rw [guard] at run
  cases next : AdmissionChecks.nextId l s with
  | error reason =>
    simp only [next] at run
    cases run
  | ok id =>
    simp only [next] at run
    try dsimp only [Bind.bind, Except.bind] at run
    cases insertion : EnumerationWriter.insert l s id with
    | error reason =>
      simp only [insertion] at run
      cases run
    | ok inserted =>
      simp only [insertion] at run
      try dsimp only [Bind.bind, Except.bind] at run
      cases nameRun : StringStorage.writeShort l (configured l inserted input id)
          (word ((moduleSlot l id).val+3)) input.name with
      | error reason =>
        simp only [configured] at nameRun
        simp only [nameRun] at run
        cases run
      | ok named =>
        have naming := nameRun
        simp only [configured] at nameRun
        simp only [nameRun] at run
        try dsimp only [Bind.bind, Except.bind] at run
        cases updated : (ParameterWriter.executeHelper l named (parameters input id)).result with
        | error reason =>
          simp only [updated] at run
          cases run
        | ok result =>
          cases result
          simp only [updated] at run
          cases run
          exact ⟨inserted, named, rfl, insertion, naming, updated, rfl⟩

theorem final_other_slot (l : Layout) (s : Storage) (input : Input) (id slot : Word)
    (lastSeparate : slot ≠ AdmissionChecks.lastIdSlot l)
    (depositSeparate : slot ≠ word ((moduleSlot l id).val+1)) :
    finalStorage l s input id slot = s slot := by
  simp [finalStorage, ShareWriter.write, lastSeparate, depositSeparate]

theorem configured_other_slot (l : Layout) (s : Storage) (input : Input) (id slot : Word)
    (separate : slot ≠ moduleSlot l id) : configured l s input id slot = s slot := by
  simp [configured, ShareWriter.write, separate]

theorem insertion_other_slot (l : Layout) (s after : Storage) (id slot : Word)
    (bound : (s (countSlot l)).val < 32)
    (countSeparate : slot ≠ countSlot l)
    (elementSeparate : slot ≠ idSlot l (s (countSlot l)).val)
    (positionSeparate : slot ≠ ShareWriter.modulePositionSlot l id)
    (run : EnumerationWriter.insert l s id = .ok after) : after slot = s slot := by
  by_cases present : (s (ShareWriter.modulePositionSlot l id)).val ≠ 0
  · rw [EnumerationWriter.existing_noop l s id present] at run
    cases run
    rfl
  · have absent : (s (ShareWriter.modulePositionSlot l id)).val = 0 := by omega
    rw [EnumerationWriter.absent_insert l s id absent bound] at run
    cases run
    simp [ShareWriter.write, countSeparate, elementSeparate, positionSeparate]

theorem success_id_bounds (l : Layout) (s : Storage) (input : Input) (success : Success)
    (run : stages l s input = .ok success) :
    success.id.val = field (s (AdmissionChecks.lastIdSlot l)) 0 24 + 1 ∧
    0 < success.id.val ∧ success.id.val < 2^24 := by
  obtain ⟨_, _, next, _⟩ := success_witness l s input success run
  exact AdmissionChecks.nextId_success l s success.id next

/-- The share bound is about the final physical record after all admission writes. -/
theorem success_stored_share (l : Layout) (s : Storage) (input : Input) (success : Success)
    (run : stages l s input = .ok success)
    (lastSeparate : moduleSlot l success.id ≠ AdmissionChecks.lastIdSlot l) :
    field (success.storage (moduleSlot l success.id)) 192 16 ≤ 10000 := by
  obtain ⟨inserted, named, _, _, _, updated, storage⟩ := success_witness l s input success run
  have separate : moduleSlot l success.id ≠ word ((moduleSlot l success.id).val+1) := by
    have bound := (moduleSlot l success.id).isLt
    intro equal
    have := congrArg Fin.val equal
    simp only [word] at this
    omega
  rw [storage, final_other_slot l _ input success.id _ lastSeparate separate]
  exact ParameterWriter.helper_stored_share_bound l named (parameters input success.id) updated

def nameSlot (l : Layout) (id : Word) : Word := word ((moduleSlot l id).val+3)

/-- Finite storage-layout obligations for preserving count through admission. -/
structure CountSeparation (l : Layout) (s : Storage) (id : Word) : Prop where
  count_element : countSlot l ≠ idSlot l (s (countSlot l)).val
  count_position : countSlot l ≠ ShareWriter.modulePositionSlot l id
  count_config : countSlot l ≠ moduleSlot l id
  count_name : countSlot l ≠ nameSlot l id
  count_deposit : countSlot l ≠ word ((moduleSlot l id).val+1)
  count_last : countSlot l ≠ AdmissionChecks.lastIdSlot l
  name_element : nameSlot l id ≠ idSlot l (s (countSlot l)).val
  name_position : nameSlot l id ≠ ShareWriter.modulePositionSlot l id
  name_config : nameSlot l id ≠ moduleSlot l id

/-- On a fresh name slot, the final physical count bound follows from the entry
guard and every intervening write. Freshness/layout must be established by the
reachable-state induction; neither is inferred merely from successful admission. -/
theorem success_count_bound (l : Layout) (s : Storage) (input : Input) (success : Success)
    (run : stages l s input = .ok success)
    (separate : CountSeparation l s success.id)
    (freshName : s (nameSlot l success.id) = 0) :
    (success.storage (countSlot l)).val ≤ 32 := by
  obtain ⟨inserted, named, _, insertion, naming, updated, storage⟩ := success_witness l s input success run
  have bound := (successful_entry_bound_and_freshness l s input success run).1
  have insertedBound : (inserted (countSlot l)).val ≤ 32 := by
    by_cases present : (s (ShareWriter.modulePositionSlot l success.id)).val ≠ 0
    · rw [EnumerationWriter.existing_noop l s success.id present] at insertion
      cases insertion
      omega
    · have absent : (s (ShareWriter.modulePositionSlot l success.id)).val = 0 := by omega
      have count := EnumerationWriter.absent_count l s inserted success.id absent bound
        separate.count_element separate.count_position insertion
      omega
  have nameZero : configured l inserted input success.id (nameSlot l success.id) = 0 := by
    rw [configured_other_slot l inserted input success.id _ separate.name_config]
    rw [insertion_other_slot l s inserted success.id _ bound (Ne.symm separate.count_name)
      separate.name_element separate.name_position insertion, freshName]
  change StringStorage.writeShort l (configured l inserted input success.id)
    (nameSlot l success.id) input.name = .ok named at naming
  rw [StringStorage.writeShort_zero l _ _ input.name nameZero] at naming
  have namedEq := Except.ok.inj naming
  have namedCount : named (countSlot l) = inserted (countSlot l) := by
    rw [← namedEq]
    simp only [ShareWriter.write, if_neg separate.count_name]
    exact configured_other_slot l inserted input success.id _ separate.count_config
  rw [storage, final_other_slot l _ input success.id _ separate.count_last separate.count_deposit]
  rw [ParameterWriter.helper_other_slot l named (parameters input success.id) _
    separate.count_config separate.count_deposit, namedCount]
  exact insertedBound

structure Untouched (l : Layout) (s : Storage) (id slot : Word) : Prop where
  count : slot ≠ countSlot l
  element : slot ≠ idSlot l (s (countSlot l)).val
  position : slot ≠ ShareWriter.modulePositionSlot l id
  config : slot ≠ moduleSlot l id
  name : slot ≠ nameSlot l id
  deposit : slot ≠ word ((moduleSlot l id).val+1)
  last : slot ≠ AdmissionChecks.lastIdSlot l

theorem success_other_slot (l : Layout) (s : Storage) (input : Input) (success : Success)
    (run : stages l s input = .ok success)
    (separate : CountSeparation l s success.id)
    (freshName : s (nameSlot l success.id) = 0)
    (slot : Word) (untouched : Untouched l s success.id slot) :
    success.storage slot = s slot := by
  obtain ⟨inserted, named, _, insertion, naming, _, storage⟩ := success_witness l s input success run
  have bound := (successful_entry_bound_and_freshness l s input success run).1
  have nameZero : configured l inserted input success.id (nameSlot l success.id) = 0 := by
    rw [configured_other_slot l inserted input success.id _ separate.name_config]
    rw [insertion_other_slot l s inserted success.id _ bound (Ne.symm separate.count_name)
      separate.name_element separate.name_position insertion, freshName]
  change StringStorage.writeShort l (configured l inserted input success.id)
    (nameSlot l success.id) input.name = .ok named at naming
  rw [StringStorage.writeShort_zero l _ _ input.name nameZero] at naming
  have namedEq := Except.ok.inj naming
  rw [storage, final_other_slot l _ input success.id slot untouched.last untouched.deposit]
  rw [ParameterWriter.helper_other_slot l named (parameters input success.id) slot
    untouched.config untouched.deposit, ← namedEq]
  simp only [ShareWriter.write, if_neg untouched.name]
  rw [configured_other_slot l inserted input success.id slot untouched.config]
  exact insertion_other_slot l s inserted success.id slot bound untouched.count
    untouched.element untouched.position insertion

theorem success_old_identity_and_share (l : Layout) (s : Storage) (input : Input) (success : Success)
    (run : stages l s input = .ok success)
    (separate : CountSeparation l s success.id)
    (freshName : s (nameSlot l success.id) = 0)
    (i : Nat) (idUntouched : Untouched l s success.id (idSlot l i))
    (configUntouched : Untouched l s success.id (moduleSlot l (s (idSlot l i)))) :
    (readModule l success.storage i).identity = (readModule l s i).identity ∧
    (readModule l success.storage i).share = (readModule l s i).share := by
  have ids := success_other_slot l s input success run separate freshName _ idUntouched
  have config := success_other_slot l s input success run separate freshName _ configUntouched
  simp [readModule, ids, config]

theorem success_new_address (l : Layout) (s : Storage) (input : Input) (success : Success)
    (run : stages l s input = .ok success)
    (separate : CountSeparation l s success.id)
    (freshName : s (nameSlot l success.id) = 0)
    (configLast : moduleSlot l success.id ≠ AdmissionChecks.lastIdSlot l) :
    field (success.storage (moduleSlot l success.id)) 0 160 = input.address.val := by
  obtain ⟨inserted, named, _, insertion, naming, updated, storage⟩ := success_witness l s input success run
  have bound := (successful_entry_bound_and_freshness l s input success run).1
  have nameZero : configured l inserted input success.id (nameSlot l success.id) = 0 := by
    rw [configured_other_slot l inserted input success.id _ separate.name_config]
    rw [insertion_other_slot l s inserted success.id _ bound (Ne.symm separate.count_name)
      separate.name_element separate.name_position insertion, freshName]
  change StringStorage.writeShort l (configured l inserted input success.id)
    (nameSlot l success.id) input.name = .ok named at naming
  rw [StringStorage.writeShort_zero l _ _ input.name nameZero] at naming
  have namedEq := Except.ok.inj naming
  have configDeposit : moduleSlot l success.id ≠ word ((moduleSlot l success.id).val+1) := by
    have slotBound := (moduleSlot l success.id).isLt
    intro equal
    have := congrArg Fin.val equal
    simp only [word] at this
    omega
  have valid := (ParameterWriter.helper_success_iff l named (parameters input success.id)).mp updated
  rw [storage, final_other_slot l _ input success.id _ configLast configDeposit]
  simp only [ParameterWriter.executeHelper, valid]
  change field (ShareWriter.write _ (word ((moduleSlot l success.id).val+1)) _
    (moduleSlot l success.id)) 0 160 = input.address.val
  simp only [parameters, ShareWriter.write, if_neg configDeposit, ite_true, ParameterWriter.config_address]
  rw [← namedEq]
  simp only [ShareWriter.write, if_neg (Ne.symm separate.name_config)]
  simp only [configured, ShareWriter.write, ite_true, credentials_preserve_address]
  exact (active_address _ input.address).1

structure PostSeparation (l : Layout) (id slot : Word) : Prop where
  config : slot ≠ moduleSlot l id
  name : slot ≠ nameSlot l id
  deposit : slot ≠ word ((moduleSlot l id).val+1)
  last : slot ≠ AdmissionChecks.lastIdSlot l

theorem success_post_insertion_slot (l : Layout) (s inserted : Storage) (input : Input)
    (success : Success) (run : stages l s input = .ok success)
    (insertRun : EnumerationWriter.insert l s success.id = .ok inserted)
    (separate : CountSeparation l s success.id)
    (freshName : s (nameSlot l success.id) = 0)
    (slot : Word) (post : PostSeparation l success.id slot) :
    success.storage slot = inserted slot := by
  obtain ⟨actual, named, _, insertion, naming, _, storage⟩ := success_witness l s input success run
  rw [insertRun] at insertion
  have same := Except.ok.inj insertion
  subst actual
  have bound := (successful_entry_bound_and_freshness l s input success run).1
  have nameZero : configured l inserted input success.id (nameSlot l success.id) = 0 := by
    rw [configured_other_slot l inserted input success.id _ separate.name_config]
    rw [insertion_other_slot l s inserted success.id _ bound (Ne.symm separate.count_name)
      separate.name_element separate.name_position insertRun, freshName]
  change StringStorage.writeShort l (configured l inserted input success.id)
    (nameSlot l success.id) input.name = .ok named at naming
  rw [StringStorage.writeShort_zero l _ _ input.name nameZero] at naming
  have namedEq := Except.ok.inj naming
  rw [storage, final_other_slot l _ input success.id slot post.last post.deposit]
  rw [ParameterWriter.helper_other_slot l named (parameters input success.id) slot
    post.config post.deposit, ← namedEq]
  simp only [ShareWriter.write, if_neg post.name]
  exact configured_other_slot l inserted input success.id slot post.config

theorem success_count_growth (l : Layout) (s : Storage) (input : Input) (success : Success)
    (run : stages l s input = .ok success)
    (separate : CountSeparation l s success.id)
    (freshName : s (nameSlot l success.id) = 0)
    (absent : (s (ShareWriter.modulePositionSlot l success.id)).val = 0) :
    (success.storage (countSlot l)).val = (s (countSlot l)).val+1 := by
  obtain ⟨inserted, _, _, insertion, _⟩ := success_witness l s input success run
  rw [success_post_insertion_slot l s inserted input success run insertion separate freshName
    (countSlot l) ⟨separate.count_config, separate.count_name, separate.count_deposit, separate.count_last⟩]
  exact EnumerationWriter.absent_count l s inserted success.id absent
    (successful_entry_bound_and_freshness l s input success run).1
    separate.count_element separate.count_position insertion

theorem success_new_element (l : Layout) (s : Storage) (input : Input) (success : Success)
    (run : stages l s input = .ok success)
    (separate : CountSeparation l s success.id)
    (freshName : s (nameSlot l success.id) = 0)
    (absent : (s (ShareWriter.modulePositionSlot l success.id)).val = 0)
    (elementPosition : idSlot l (s (countSlot l)).val ≠ ShareWriter.modulePositionSlot l success.id)
    (post : PostSeparation l success.id (idSlot l (s (countSlot l)).val)) :
    success.storage (idSlot l (s (countSlot l)).val) = success.id := by
  obtain ⟨inserted, _, _, insertion, _⟩ := success_witness l s input success run
  rw [success_post_insertion_slot l s inserted input success run insertion separate freshName _ post]
  exact EnumerationWriter.new_element l s inserted success.id absent
    (successful_entry_bound_and_freshness l s input success run).1 elementPosition insertion

structure AppendSeparation (l : Layout) (s : Storage) (id : Word) : Prop where
  count : CountSeparation l s id
  element_position : idSlot l (s (countSlot l)).val ≠ ShareWriter.modulePositionSlot l id
  element_post : PostSeparation l id (idSlot l (s (countSlot l)).val)
  config_last : moduleSlot l id ≠ AdmissionChecks.lastIdSlot l
  old_ids : ∀ i, i < (s (countSlot l)).val → Untouched l s id (idSlot l i)
  old_configs : ∀ i, i < (s (countSlot l)).val →
    Untouched l s id (moduleSlot l (s (idSlot l i)))

/-- Full successful admission preserves the producer invariant on a fresh record
and absent ID under the stated finite layout obligations. Reachability must still
establish freshness/absence; address freshness and share bounds are derived here. -/
theorem admission_preserves (l : Layout) (s : Storage) (input : Input) (success : Success)
    (run : stages l s input = .ok success) (before : WriterInvariant.Holds l s)
    (separate : AppendSeparation l s success.id)
    (freshName : s (nameSlot l success.id) = 0)
    (absent : (s (ShareWriter.modulePositionSlot l success.id)).val = 0) :
    WriterInvariant.Holds l success.storage := by
  have count := success_count_growth l s input success run separate.count freshName absent
  have element := success_new_element l s input success run separate.count freshName absent
    separate.element_position separate.element_post
  have newAddress : (readModule l success.storage (s (countSlot l)).val).identity.moduleAddress =
      input.address := by
    apply Fin.ext
    simp only [readModule, element]
    exact success_new_address l s input success run separate.count freshName separate.config_last
  have oldRows := fun i hi => success_old_identity_and_share l s input success run
    separate.count freshName i (separate.old_ids i hi) (separate.old_configs i hi)
  have fresh := (successful_entry_bound_and_freshness l s input success run).2
  rcases before with ⟨_, shares, unique⟩
  refine ⟨success_count_bound l s input success run separate.count freshName, ?_, ?_⟩
  · intro i hi
    by_cases old : i < (s (countSlot l)).val
    · rw [(oldRows i old).2]
      exact shares i old
    · have last : i = (s (countSlot l)).val := by omega
      subst i
      simp only [readModule, element]
      exact success_stored_share l s input success run separate.config_last
  · intro i j hi hj equal
    by_cases oldI : i < (s (countSlot l)).val
    · by_cases oldJ : j < (s (countSlot l)).val
      · rw [(oldRows i oldI).1, (oldRows j oldJ).1] at equal
        exact unique i j oldI oldJ equal
      · have lastJ : j = (s (countSlot l)).val := by omega
        subst j
        rw [(oldRows i oldI).1, newAddress] at equal
        exact False.elim (fresh i oldI equal)
    · have lastI : i = (s (countSlot l)).val := by omega
      subst i
      by_cases oldJ : j < (s (countSlot l)).val
      · rw [newAddress, (oldRows j oldJ).1] at equal
        exact False.elim (fresh j oldJ equal.symm)
      · omega

/-- Storage facts needed to derive fresh admission records. These are an
inductive-state obligation, not assumptions about the proposed address/share. -/
structure FreshRecords (l : Layout) (s : Storage) : Prop where
  position_complete : ∀ id, id.val < 2^24 → (s (ShareWriter.modulePositionSlot l id)).val ≠ 0 →
    ∃ i, i < (s (countSlot l)).val ∧ s (idSlot l i) = id
  ids_bounded : ∀ i, i < (s (countSlot l)).val →
    (s (idSlot l i)).val ≤ field (s (AdmissionChecks.lastIdSlot l)) 0 24
  future_names : ∀ id, field (s (AdmissionChecks.lastIdSlot l)) 0 24 < id.val →
    id.val < 2^24 → s (nameSlot l id) = 0

theorem zero_fresh_records (l : Layout) (s : Storage) (zero : ∀ slot, s slot = 0) :
    FreshRecords l s := by
  constructor
  · intro id _ present
    simp [zero] at present
  · intro i inside
    simp [zero] at inside
  · intro id _ _
    exact zero _

theorem successful_record_freshness (l : Layout) (s : Storage) (input : Input) (success : Success)
    (run : stages l s input = .ok success) (records : FreshRecords l s) :
    (s (ShareWriter.modulePositionSlot l success.id)).val = 0 ∧
    s (nameSlot l success.id) = 0 := by
  have idBounds := success_id_bounds l s input success run
  have beyond : field (s (AdmissionChecks.lastIdSlot l)) 0 24 < success.id.val := by omega
  refine ⟨?_, records.future_names success.id beyond idBounds.2.2⟩
  by_cases zero : (s (ShareWriter.modulePositionSlot l success.id)).val = 0
  · exact zero
  · obtain ⟨i, inside, same⟩ := records.position_complete success.id idBounds.2.2 zero
    have bound := records.ids_bounded i inside
    rw [same] at bound
    omega

theorem admission_preserves_from_records (l : Layout) (s : Storage) (input : Input) (success : Success)
    (run : stages l s input = .ok success) (before : WriterInvariant.Holds l s)
    (records : FreshRecords l s) (separate : AppendSeparation l s success.id) :
    WriterInvariant.Holds l success.storage := by
  have fresh := successful_record_freshness l s input success run records
  exact admission_preserves l s input success run before separate fresh.2 fresh.1

/-- Both success and rejection of the public writer, with finite layout conditions
for each actual successful next ID rather than an assumed successful call. -/
theorem public_preserves (l : Layout) (s : Storage) (input : Input)
    (before : WriterInvariant.Holds l s) (records : FreshRecords l s)
    (layout : ∀ success, stages l s input = .ok success → AppendSeparation l s success.id) :
    WriterInvariant.Holds l (execute l s input).storage := by
  unfold execute
  cases run : stages l s input with
  | error reason => exact before
  | ok success => exact admission_preserves_from_records l s input success run before records (layout success run)

end AdmissionFacts
end LidoSRv3.Audit.Source.TrioAlloc1
