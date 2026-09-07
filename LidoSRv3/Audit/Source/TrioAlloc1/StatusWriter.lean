import LidoSRv3.Audit.Source.TrioAlloc1.RecordInvariant

namespace LidoSRv3.Audit.Source.TrioAlloc1
namespace StatusWriter

open ShareWriter (write rejected error Outcome)

structure Input where
  caller : Address
  router : Address
  moduleId : Word
  status : Fin 3

/-- Pinned solc 0.8.25 packed status assignment preserves all other bytes. -/
def packed (original : Word) (status : Fin 3) : Word :=
  word (original.val % 2^224 + status.val*2^224 + original.val/2^232*2^232)

/-- SRLib.sol:363-369. Typed input follows ABI enum decoding; malformed calldata
is outside this entry relation. Stored enum validation precedes equality. -/
def helper (l : Layout) (s : Storage) (input : Input) : Outcome :=
  let slot := moduleSlot l input.moduleId
  if field (s slot) 224 8 ≥ 3 then rejected s (.panic 0x21)
  else if field (s slot) 224 8 = input.status.val then
    rejected s (error l "StakingModuleStatusTheSame()")
  else { result := .ok (), storage := write s slot (packed (s slot) input.status)
         events := [{ emitter := input.router
                      topics := [l.keccak ("StakingModuleStatusSet(uint256,uint8,address)".toList.map
                        (fun c => byte c.toNat)), input.moduleId]
                      data := encodeWords [word input.status.val, word input.caller.val] }] }

/-- StakingRouter.sol:560-565: role, membership, helper. -/
def execute (l : Layout) (s : Storage) (input : Input) : Outcome :=
  if !AdmissionChecks.admitted l s input.caller then
    rejected s (AdmissionChecks.unauthorized l input.caller)
  else if (s (ShareWriter.modulePositionSlot l input.moduleId)).val = 0 then
    rejected s (error l "StakingModuleUnregistered()")
  else helper l s input

theorem packed_address (original : Word) (status : Fin 3) :
    field (packed original status) 0 160 = field original 0 160 := by
  have ho := original.isLt
  have hs := status.isLt
  simp only [packed, field, word]
  omega

theorem packed_share (original : Word) (status : Fin 3) :
    field (packed original status) 192 16 = field original 192 16 := by
  have ho := original.isLt
  have hs := status.isLt
  simp only [packed, field, word]
  omega

theorem packed_status (original : Word) (status : Fin 3) :
    field (packed original status) 224 8 = status.val := by
  have ho := original.isLt
  have hs := status.isLt
  simp only [packed, field, word]
  omega

theorem revert_restores (l : Layout) (s : Storage) (input : Input) (reason : Failure)
    (failed : (execute l s input).result = .error reason) :
    (execute l s input).storage = s ∧ (execute l s input).events = [] := by
  unfold execute helper at *
  dsimp only at *
  split at failed
  · simp_all [rejected]
  · split at failed
    · simp_all [rejected]
    · split at failed
      · simp_all [rejected]
      · split at failed
        · simp_all [rejected, Nat.not_le.mpr input.status.isLt]
        · cases failed

theorem execute_storage (l : Layout) (s : Storage) (input : Input) :
    (execute l s input).storage = s ∨
    (execute l s input).storage = write s (moduleSlot l input.moduleId)
      (packed (s (moduleSlot l input.moduleId)) input.status) := by
  unfold execute helper
  dsimp only
  split <;> try { exact Or.inl rfl }
  split <;> try { exact Or.inl rfl }
  split <;> try { exact Or.inl rfl }
  split
  · exact Or.inl rfl
  · exact Or.inr rfl

theorem other_slot (l : Layout) (s : Storage) (input : Input) (slot : Word)
    (separate : slot ≠ moduleSlot l input.moduleId) :
    (execute l s input).storage slot = s slot := by
  rcases execute_storage l s input with same | changed
  · rw [same]
  · rw [changed]
    exact if_neg separate

theorem row_fields (l : Layout) (s : Storage) (input : Input) (i : Nat)
    (separate : idSlot l i ≠ moduleSlot l input.moduleId) :
    (readModule l (execute l s input).storage i).identity = (readModule l s i).identity ∧
    (readModule l (execute l s input).storage i).share = (readModule l s i).share := by
  rcases execute_storage l s input with same | changed
  · rw [same]; exact ⟨rfl, rfl⟩
  · have ids := other_slot l s input (idSlot l i) separate
    rw [changed]
    rw [changed] at ids
    simp only [readModule, ids]
    by_cases equal : moduleSlot l (s (idSlot l i)) = moduleSlot l input.moduleId
    · simp only [write, equal, ite_true, packed_address, packed_share]
      trivial
    · simp only [write, if_neg equal]
      trivial

theorem preserves (l : Layout) (s : Storage) (input : Input)
    (before : WriterInvariant.Holds l s ∧ AdmissionFacts.FreshRecords l s)
    (separate : RecordInvariant.SeparateFrom l s (moduleSlot l input.moduleId)) :
    WriterInvariant.Holds l (execute l s input).storage ∧
    AdmissionFacts.FreshRecords l (execute l s input).storage := by
  have count := other_slot l s input _ separate.count
  constructor
  · rcases before.1 with ⟨bound, shares, unique⟩
    refine ⟨by simpa only [count] using bound, ?_, ?_⟩
    · intro i hi
      rw [count] at hi
      rw [(row_fields l s input i (separate.ids i hi)).2]
      exact shares i hi
    · intro i j hi hj same
      rw [count] at hi hj
      rw [(row_fields l s input i (separate.ids i hi)).1,
        (row_fields l s input j (separate.ids j hj)).1] at same
      exact unique i j hi hj same
  · apply RecordInvariant.preserves l s _ before.2
    constructor
    · exact count
    · rw [other_slot l s input _ separate.last]
    · intro i hi; exact other_slot l s input _ (separate.ids i hi)
    · intro id bound; exact other_slot l s input _ (separate.positions id bound)
    · intro id beyond bound; exact other_slot l s input _ (separate.names id beyond bound)

/-- Four actual public writer families. Proxy initialization, migration and the
remaining writers are still required for full router lifecycle reachability. -/
inductive History (l : Layout) : Storage → Prop where
  | zero (s : Storage) (empty : ∀ slot, s slot = 0) : History l s
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

  | status (s : Storage) (input : Input) (before : History l s)
      (layout : RecordInvariant.SeparateFrom l s (moduleSlot l input.moduleId)) :
      History l (execute l s input).storage

theorem history_invariants (l : Layout) (s : Storage) (history : History l s) :
    WriterInvariant.Holds l s ∧ AdmissionFacts.FreshRecords l s := by
  induction history with
  | zero s empty =>
    exact ⟨WriterInvariant.empty l s (by simp [empty]), AdmissionFacts.zero_fresh_records l s empty⟩
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

  | status s input _ layout ih => exact preserves l s input ih layout

end StatusWriter
end LidoSRv3.Audit.Source.TrioAlloc1
