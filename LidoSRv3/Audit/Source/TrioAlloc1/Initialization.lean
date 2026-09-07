import LidoSRv3.Audit.Source.TrioAlloc1.ACLWriter

namespace LidoSRv3.Audit.Source.TrioAlloc1
namespace Initialization

open ShareWriter (write rejected error Outcome)

def slot : Word := word 0xf0c57e16840df040f15088dc2f81fe391c3923bec73e23a9662efc9c229c6a00

def versionWord (original : Word) (version : Fin (2^64)) : Word :=
  word (original.val/2^64*2^64 + version.val)

def flagWord (original : Word) (flag : Bool) : Word :=
  word (original.val % 2^64 + (if flag then 1 else 0)*2^64 + original.val/2^72*2^72)

def begin (s : Storage) (version : Fin (2^64)) : Storage :=
  let versioned := write s slot (versionWord (s slot) version)
  write versioned slot (flagWord (versioned slot) true)

/-- Vendored OZ Initializable.sol:152-163. The body parameter is an explicit
storage/event execution to be instantiated by the router body, not an assumption
that the body succeeds or preserves state. The outer failure restores entry state. -/
def reinitialize (l : Layout) (s : Storage) (router : Address) (version : Fin (2^64))
    (body : Storage → Outcome) : Outcome :=
  if field (s slot) 64 8 ≠ 0 ∨ field (s slot) 0 64 ≥ version.val then
    rejected s (error l "InvalidInitialization()")
  else
    let result := body (begin s version)
    match result.result with
    | .error reason => rejected s reason
    | .ok () => { result := .ok (), storage := write result.storage slot (flagWord (result.storage slot) false)
                  events := result.events ++ [{ emitter := router, topics := [l.keccak ("Initialized(uint64)".toList.map (fun c => byte c.toNat))], data := encodeWord (word version.val) }] }

theorem version_field (original : Word) (version : Fin (2^64)) :
    field (versionWord original version) 0 64 = version.val := by
  have ho := original.isLt
  have hv := version.isLt
  simp only [versionWord, field, word]
  omega

theorem flag_preserves_version (original : Word) (flag : Bool) :
    field (flagWord original flag) 0 64 = field original 0 64 := by
  have ho := original.isLt
  cases flag <;> simp only [flagWord, field, word, Bool.false_eq_true, ↓reduceIte] <;> omega

theorem flag_field (original : Word) (flag : Bool) :
    field (flagWord original flag) 64 8 = (if flag then 1 else 0) := by
  have ho := original.isLt
  cases flag <;> simp only [flagWord, field, word, Bool.false_eq_true, ↓reduceIte] <;> omega

theorem begin_fields (s : Storage) (version : Fin (2^64)) :
    field (begin s version slot) 0 64 = version.val ∧ field (begin s version slot) 64 8 = 1 := by
  simp only [begin, write, ite_true, flag_preserves_version, version_field, flag_field]
  trivial

theorem begin_other (s : Storage) (version : Fin (2^64)) (target : Word) (separate : target ≠ slot) :
    begin s version target = s target := by
  simp only [begin, write, if_neg separate]

theorem revert_restores (l : Layout) (s : Storage) (router : Address) (version : Fin (2^64))
    (body : Storage → Outcome) (reason : Failure)
    (failed : (reinitialize l s router version body).result = .error reason) :
    (reinitialize l s router version body).storage = s ∧
    (reinitialize l s router version body).events = [] := by
  unfold reinitialize at *
  split at failed
  · rename_i invalid
    simp only [if_pos invalid, rejected]
    trivial
  · rename_i valid
    simp only [if_neg valid]
    dsimp only at *
    split at failed
    · simp only [rejected]
      trivial
    · cases failed

structure Input where
  caller : Address
  router : Address
  admin : Address
  credentials : Word
  topUpCap : Word

def grantInput (input : Input) : ACLWriter.Input :=
  ⟨input.caller, input.router, 0, input.admin⟩

def credentialsSlot (l : Layout) : Word := word (l.routerSlot.val+4)

def capWord (original : Word) (cap : Word) : Word :=
  word (original.val % 2^24 + (cap.val % 2^64)*2^24 + original.val/2^88*2^88)

def credentialsEvent (l : Layout) (input : Input) : ShareWriter.Event :=
  { emitter := input.router
    topics := [l.keccak ("WithdrawalCredentialsSet(bytes32,address)".toList.map (fun c => byte c.toNat))]
    data := encodeWords [input.credentials, word input.caller.val] }

def capEvent (l : Layout) (input : Input) : ShareWriter.Event :=
  { emitter := input.router
    topics := [l.keccak ("MaxTopUpPerBlockGweiSet(uint256,address)".toList.map (fun c => byte c.toNat))]
    data := encodeWords [input.topUpCap, word input.caller.val] }

/-- StakingRouter.initialize body. `notify` is the explicit notification execution
at the post-credentials state; its source implementation/callback relation must
be supplied for whole-router correspondence. No callee success is assumed. -/
def routerBody (l : Layout) (s : Storage) (input : Input) (notify : Storage → Outcome) : Outcome :=
  if input.admin.val = 0 then rejected s (error l "ZeroAddress()")
  else
    let granted := ACLWriter.grant l s (grantInput input)
    match granted.result with
    | .error reason => rejected s reason
    | .ok () =>
      if field input.credentials 0 160 = 0 then rejected s (error l "ZeroAddress()")
      else if field input.credentials 248 8 ≠ 1 ∧ field input.credentials 248 8 ≠ 2 then
        rejected s (error l "WrongWithdrawalCredentialsType()")
      else
        let withCredentials := write granted.storage (credentialsSlot l) input.credentials
        let notified := notify withCredentials
        match notified.result with
        | .error reason => rejected s reason
        | .ok () =>
          if input.topUpCap.val = 0 ∨ input.topUpCap.val ≥ 2^64 then
            rejected s (error l "InvalidMaxTopUpPerBlockGwei()")
          else { result := .ok (), storage := write notified.storage (AdmissionChecks.lastIdSlot l)
                   (capWord (notified.storage (AdmissionChecks.lastIdSlot l)) input.topUpCap),
                 events := granted.events ++ [credentialsEvent l input] ++ notified.events ++ [capEvent l input] }

def execute (l : Layout) (s : Storage) (input : Input) (notify : Storage → Outcome) : Outcome :=
  reinitialize l s input.router ⟨4, by decide⟩ (fun before => routerBody l before input notify)

theorem cap_preserves_last_id (original cap : Word) :
    field (capWord original cap) 0 24 = field original 0 24 := by
  have ho := original.isLt
  have hc := cap.isLt
  simp only [capWord, field, word]
  omega

/-- At the notification boundary, empty enumeration is derived through the actual
ACL grant and credentials write. Thus a source notification loop with this state
has zero iterations; this does not assume a callback succeeds. -/
theorem notification_count_zero (l : Layout) (s : Storage) (input : Input)
    (empty : (s (countSlot l)).val = 0)
    (grantSeparate : ACLWriter.Separate l s (grantInput input) (countSlot l))
    (credentialsSeparate : countSlot l ≠ credentialsSlot l) :
    ((write (ACLWriter.grant l s (grantInput input)).storage (credentialsSlot l) input.credentials)
      (countSlot l)).val = 0 := by
  simp only [write, if_neg credentialsSeparate, ACLWriter.grant_other_slot l s _ _ grantSeparate, empty]

/-- Notification preserves empty enumeration when it performs zero iterations.
The premise is only required on physically empty states, not arbitrary callbacks. -/
theorem body_count_zero (l : Layout) (s : Storage) (input : Input) (notify : Storage → Outcome)
    (empty : (s (countSlot l)).val = 0)
    (grantSeparate : ACLWriter.Separate l s (grantInput input) (countSlot l))
    (credentialsSeparate : countSlot l ≠ credentialsSlot l)
    (capSeparate : countSlot l ≠ AdmissionChecks.lastIdSlot l)
    (notifyEmpty : ∀ before, (before (countSlot l)).val = 0 →
      ((notify before).storage (countSlot l)).val = 0) :
    ((routerBody l s input notify).storage (countSlot l)).val = 0 := by
  have notificationEmpty := notification_count_zero l s input empty grantSeparate credentialsSeparate
  unfold routerBody
  split
  · exact empty
  · dsimp only
    split
    · exact empty
    · split
      · exact empty
      · split
        · exact empty
        · try dsimp only
          split
          · exact empty
          · split
            · exact empty
            · simp only [write, if_neg capSeparate]
              exact notifyEmpty _ notificationEmpty

theorem execute_count_zero (l : Layout) (s : Storage) (input : Input) (notify : Storage → Outcome)
    (empty : (s (countSlot l)).val = 0)
    (initSeparate : countSlot l ≠ slot)
    (grantSeparate : ACLWriter.Separate l (begin s ⟨4, by decide⟩) (grantInput input) (countSlot l))
    (credentialsSeparate : countSlot l ≠ credentialsSlot l)
    (capSeparate : countSlot l ≠ AdmissionChecks.lastIdSlot l)
    (notifyEmpty : ∀ before, (before (countSlot l)).val = 0 →
      ((notify before).storage (countSlot l)).val = 0) :
    WriterInvariant.Holds l (execute l s input notify).storage := by
  apply WriterInvariant.empty
  have begunEmpty : (begin s ⟨4, by decide⟩ (countSlot l)).val = 0 := by
    rw [begin_other s _ _ initSeparate, empty]
  have bodyEmpty := body_count_zero l (begin s ⟨4, by decide⟩) input notify begunEmpty
    grantSeparate credentialsSeparate capSeparate notifyEmpty
  unfold execute reinitialize
  split
  · exact empty
  · dsimp only
    split
    · exact empty
    · simp only [write, if_neg initSeparate]
      exact bodyEmpty

/-- Notification loop control from SRLib.sol:904-919. `step` represents one
iteration including ID lookup, external call and catch handling. That nonempty
iteration relation remains an explicit composition boundary. -/
def notificationLoop (step : Nat → Storage → Outcome) : Nat → Nat → Storage → Outcome
  | 0, _, s => { result := .ok (), storage := s, events := [] }
  | n+1, i, s =>
    let first := step i s
    match first.result with
    | .error reason => rejected s reason
    | .ok () =>
      let rest := notificationLoop step n (i+1) first.storage
      match rest.result with
      | .error reason => rejected s reason
      | .ok () => { result := .ok (), storage := rest.storage, events := first.events ++ rest.events }

def notifications (l : Layout) (step : Nat → Storage → Outcome) (s : Storage) : Outcome :=
  notificationLoop step (s (countSlot l)).val 0 s

theorem notifications_empty (l : Layout) (step : Nat → Storage → Outcome) (s : Storage)
    (empty : (s (countSlot l)).val = 0) :
    notifications l step s = { result := .ok (), storage := s, events := [] } := by
  simp only [notifications, empty, notificationLoop]

/-- Empty-state initialization has the capacity invariant for every possible
notification iteration implementation, because the actual loop executes none.
This still requires the stated finite slot relation and is not proxy deployment. -/
theorem execute_from_empty (l : Layout) (s : Storage) (input : Input)
    (step : Nat → Storage → Outcome)
    (empty : (s (countSlot l)).val = 0)
    (initSeparate : countSlot l ≠ slot)
    (grantSeparate : ACLWriter.Separate l (begin s ⟨4, by decide⟩) (grantInput input) (countSlot l))
    (credentialsSeparate : countSlot l ≠ credentialsSlot l)
    (capSeparate : countSlot l ≠ AdmissionChecks.lastIdSlot l) :
    WriterInvariant.Holds l (execute l s input (notifications l step)).storage := by
  apply execute_count_zero l s input _ empty initSeparate grantSeparate credentialsSeparate capSeparate
  intro before beforeEmpty
  rw [notifications_empty l step before beforeEmpty]
  exact beforeEmpty

structure RecordWriteSeparation (l : Layout) (s : Storage) (target : Word) : Prop where
  count : countSlot l ≠ target
  ids : ∀ i, i < (s (countSlot l)).val → idSlot l i ≠ target
  positions : ∀ id, id.val < 2^24 → ShareWriter.modulePositionSlot l id ≠ target
  names : ∀ id, field (s (AdmissionChecks.lastIdSlot l)) 0 24 < id.val → id.val < 2^24 →
    AdmissionFacts.nameSlot l id ≠ target

theorem write_records (l : Layout) (s : Storage) (target value : Word)
    (before : AdmissionFacts.FreshRecords l s)
    (separate : RecordWriteSeparation l s target)
    (last : AdmissionChecks.lastIdSlot l = target →
      field value 0 24 = field (s (AdmissionChecks.lastIdSlot l)) 0 24) :
    AdmissionFacts.FreshRecords l (write s target value) := by
  apply RecordInvariant.preserves l s _ before
  constructor
  · exact if_neg separate.count
  · by_cases same : AdmissionChecks.lastIdSlot l = target
    · simp only [write, if_pos same, last same]
    · simp only [write, if_neg same]
  · intro i hi; exact if_neg (separate.ids i hi)
  · intro id bound; exact if_neg (separate.positions id bound)
  · intro id beyond bound; exact if_neg (separate.names id beyond bound)

theorem begin_records (l : Layout) (s : Storage) (version : Fin (2^64))
    (before : AdmissionFacts.FreshRecords l s)
    (separate : RecordInvariant.SeparateFrom l s slot) :
    AdmissionFacts.FreshRecords l (begin s version) := by
  apply RecordInvariant.preserves l s _ before
  constructor
  · exact begin_other s version _ separate.count
  · rw [begin_other s version _ separate.last]
  · intro i hi; exact begin_other s version _ (separate.ids i hi)
  · intro id bound; exact begin_other s version _ (separate.positions id bound)
  · intro id beyond bound; exact begin_other s version _ (separate.names id beyond bound)

structure BodyRecordSeparation (l : Layout) (s : Storage) (input : Input) : Prop where
  grant : ACLWriter.InvariantSeparation l s (grantInput input)
  credentials : RecordWriteSeparation l (ACLWriter.grant l s (grantInput input)).storage (credentialsSlot l)
  last_credentials : AdmissionChecks.lastIdSlot l ≠ credentialsSlot l
  cap : RecordWriteSeparation l
    (write (ACLWriter.grant l s (grantInput input)).storage (credentialsSlot l) input.credentials)
    (AdmissionChecks.lastIdSlot l)

theorem body_records (l : Layout) (s : Storage) (input : Input) (step : Nat → Storage → Outcome)
    (empty : (s (countSlot l)).val = 0) (before : AdmissionFacts.FreshRecords l s)
    (separate : BodyRecordSeparation l s input) :
    AdmissionFacts.FreshRecords l (routerBody l s input (notifications l step)).storage := by
  have grantedRecords := (ACLWriter.grant_preserves l s (grantInput input)
    ⟨WriterInvariant.empty l s empty, before⟩ separate.grant).2
  have credentialsRecords := write_records l _ (credentialsSlot l) input.credentials
    grantedRecords separate.credentials (fun equal => False.elim (separate.last_credentials equal))
  have credentialsEmpty := notification_count_zero l s input empty separate.grant.count separate.credentials.count
  have notified := notifications_empty l step _ credentialsEmpty
  have finalRecords := write_records l _ (AdmissionChecks.lastIdSlot l)
    (capWord ((write (ACLWriter.grant l s (grantInput input)).storage (credentialsSlot l)
      input.credentials) (AdmissionChecks.lastIdSlot l)) input.topUpCap)
    credentialsRecords separate.cap (fun _ => cap_preserves_last_id _ _)
  unfold routerBody
  split
  · exact before
  · dsimp only
    split
    · exact before
    · split
      · exact before
      · split
        · exact before
        · rw [notified]
          dsimp only
          split
          · exact before
          · exact finalRecords

theorem execute_records (l : Layout) (s : Storage) (input : Input) (step : Nat → Storage → Outcome)
    (empty : (s (countSlot l)).val = 0) (before : AdmissionFacts.FreshRecords l s)
    (initSeparate : RecordInvariant.SeparateFrom l s slot)
    (bodySeparate : BodyRecordSeparation l (begin s ⟨4, by decide⟩) input)
    (finishSeparate : RecordInvariant.SeparateFrom l
      (routerBody l (begin s ⟨4, by decide⟩) input (notifications l step)).storage slot) :
    AdmissionFacts.FreshRecords l (execute l s input (notifications l step)).storage := by
  have begun := begin_records l s ⟨4, by decide⟩ before initSeparate
  have begunEmpty : (begin s ⟨4, by decide⟩ (countSlot l)).val = 0 := by
    rw [begin_other s _ _ initSeparate.count, empty]
  have bodyRecords := body_records l _ input step begunEmpty begun bodySeparate
  have finished := write_records l _ slot
    (flagWord ((routerBody l (begin s ⟨4, by decide⟩) input (notifications l step)).storage slot) false)
    bodyRecords ⟨finishSeparate.count, finishSeparate.ids, finishSeparate.positions, finishSeparate.names⟩
    (fun equal => False.elim (finishSeparate.last equal))
  unfold execute reinitialize
  split
  · exact before
  · dsimp only
    split
    · exact before
    · exact finished

end Initialization
end LidoSRv3.Audit.Source.TrioAlloc1
