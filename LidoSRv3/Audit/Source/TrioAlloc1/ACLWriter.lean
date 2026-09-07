import LidoSRv3.Audit.Source.TrioAlloc1.StatusWriter

namespace LidoSRv3.Audit.Source.TrioAlloc1
namespace ACLWriter

open ShareWriter (write Outcome rejected selector)

def enumerableBase : Word :=
  word 0xc1f6fe24621ce81ec5827caf0253cadb74709b061630e6b55e82371705932000

def roleData (l : Layout) (role : Word) : Word :=
  l.keccak (encodeWord role ++ encodeWord ShareWriter.aclBase)

def memberSlot (l : Layout) (role : Word) (account : Address) : Word :=
  l.keccak (encodeWord (word account.val) ++ encodeWord (roleData l role))

def setBase (l : Layout) (role : Word) : Word :=
  l.keccak (encodeWord role ++ encodeWord enumerableBase)

/-- Reuse the actual EnumerableSet primitive with its array at the role set root. -/
def setLayout (l : Layout) (role : Word) : Layout :=
  { l with routerSlot := word ((setBase l role).val + 2^256 - 1) }

theorem set_count_slot (l : Layout) (role : Word) :
    countSlot (setLayout l role) = setBase l role := by
  apply Fin.ext
  have h := (setBase l role).isLt
  simp only [countSlot, setLayout, word]
  omega

theorem set_position_slot (l : Layout) (role : Word) (account : Address) :
    ShareWriter.modulePositionSlot (setLayout l role) (word account.val) =
      l.keccak (encodeWord (word account.val) ++ encodeWord (word ((setBase l role).val+1))) := by
  have h := (setBase l role).isLt
  have offset : word ((word ((setBase l role).val+2^256-1)).val+2) =
      word ((setBase l role).val+1) := by
    apply Fin.ext
    simp only [word]
    omega
  simp only [ShareWriter.modulePositionSlot, setLayout, offset]

structure Input where
  caller : Address
  router : Address
  role : Word
  account : Address

def setMember (original : Word) : Word := word (original.val/256*256+1)

def hasRole (l : Layout) (s : Storage) (role : Word) (account : Address) : Bool :=
  field (s (memberSlot l role account)) 0 8 != 0

/-- Vendored OZ 5.2 upgradeable _grantRole: bool write and event, then set.add.
An insertion panic rolls back the earlier bool write and event at this entry. -/
def grant (l : Layout) (s : Storage) (input : Input) : Outcome :=
  if hasRole l s input.role input.account then { result := .ok (), storage := s, events := [] }
  else
    let slot := memberSlot l input.role input.account
    let updated := write s slot (setMember (s slot))
    match EnumerationWriter.insert (setLayout l input.role) updated (word input.account.val) with
    | .error reason => rejected s reason
    | .ok after => { result := .ok (), storage := after
                     events := [{ emitter := input.router
                                  topics := [l.keccak ("RoleGranted(bytes32,address,address)".toList.map
                                    (fun c => byte c.toNat)), input.role, word input.account.val,
                                    word input.caller.val]
                                  data := [] }] }

def adminRole (l : Layout) (s : Storage) (role : Word) : Word :=
  s (word ((roleData l role).val+1))

/-- Public AccessControlUpgradeable.grantRole checks the stored role admin. -/
def execute (l : Layout) (s : Storage) (input : Input) : Outcome :=
  let admin := adminRole l s input.role
  if !hasRole l s admin input.caller then
    rejected s (.revertData (selector l "AccessControlUnauthorizedAccount(address,bytes32)" ++
      encodeWords [word input.caller.val, admin]))
  else grant l s input

theorem granted_byte (original : Word) : field (setMember original) 0 8 = 1 := by
  have h := original.isLt
  simp only [setMember, field, word]
  omega

/-- Slot separation uses the count after the actual bool write; no hash alias is
silently excluded and the role-member array has no artificial 32-entry limit. -/
structure Separate (l : Layout) (s : Storage) (input : Input) (slot : Word) : Prop where
  member : slot ≠ memberSlot l input.role input.account
  count : slot ≠ countSlot (setLayout l input.role)
  position : slot ≠ ShareWriter.modulePositionSlot (setLayout l input.role) (word input.account.val)
  element : slot ≠ idSlot (setLayout l input.role)
    ((write s (memberSlot l input.role input.account)
      (setMember (s (memberSlot l input.role input.account)))) (countSlot (setLayout l input.role))).val

theorem insert_other_slot (l : Layout) (s after : Storage) (id slot : Word)
    (run : EnumerationWriter.insert l s id = .ok after)
    (count : slot ≠ countSlot l) (position : slot ≠ ShareWriter.modulePositionSlot l id)
    (element : slot ≠ idSlot l (s (countSlot l)).val) : after slot = s slot := by
  unfold EnumerationWriter.insert at run
  split at run
  · cases run; rfl
  · split at run
    · cases run
    · cases run
      simp only [write, if_neg position, if_neg element, if_neg count]

theorem grant_other_slot (l : Layout) (s : Storage) (input : Input) (slot : Word)
    (separate : Separate l s input slot) : (grant l s input).storage slot = s slot := by
  unfold grant
  split
  · rfl
  · dsimp only
    split
    · rfl
    · rename_i after run
      change after slot = s slot
      rw [insert_other_slot _ _ after _ slot run separate.count separate.position separate.element]
      exact if_neg separate.member

theorem other_slot (l : Layout) (s : Storage) (input : Input) (slot : Word)
    (separate : Separate l s input slot) : (execute l s input).storage slot = s slot := by
  unfold execute
  dsimp only
  split
  · rfl
  · exact grant_other_slot l s input slot separate

theorem grant_revert_restores (l : Layout) (s : Storage) (input : Input) (reason : Failure)
    (failed : (grant l s input).result = .error reason) :
    (grant l s input).storage = s ∧ (grant l s input).events = [] := by
  unfold grant at *
  split at failed
  · cases failed
  · dsimp only at *
    split at failed
    · simp_all [rejected]
    · cases failed

theorem grant_hasRole (l : Layout) (s : Storage) (input : Input)
    (success : (grant l s input).result = .ok ())
    (count : memberSlot l input.role input.account ≠ countSlot (setLayout l input.role))
    (position : memberSlot l input.role input.account ≠
      ShareWriter.modulePositionSlot (setLayout l input.role) (word input.account.val))
    (element : memberSlot l input.role input.account ≠ idSlot (setLayout l input.role)
      ((write s (memberSlot l input.role input.account)
        (setMember (s (memberSlot l input.role input.account)))) (countSlot (setLayout l input.role))).val) :
    hasRole l (grant l s input).storage input.role input.account = true := by
  unfold grant at *
  split at success
  · rename_i present
    simpa only [if_pos present] using present
  · rename_i absent
    simp only [if_neg absent]
    dsimp only at *
    split at success
    · cases success
    · rename_i after run
      change hasRole l after input.role input.account = true
      have preserved := insert_other_slot _ _ after _ (memberSlot l input.role input.account)
        run count position element
      simp only [hasRole, preserved, write, ite_true, granted_byte]
      rfl

structure InvariantSeparation (l : Layout) (s : Storage) (input : Input) : Prop where
  count : Separate l s input (countSlot l)
  last : Separate l s input (AdmissionChecks.lastIdSlot l)
  ids : ∀ i, i < (s (countSlot l)).val → Separate l s input (idSlot l i)
  configs : ∀ i, i < (s (countSlot l)).val → Separate l s input (moduleSlot l (s (idSlot l i)))
  positions : ∀ id, id.val < 2^24 → Separate l s input (ShareWriter.modulePositionSlot l id)
  names : ∀ id, field (s (AdmissionChecks.lastIdSlot l)) 0 24 < id.val → id.val < 2^24 →
    Separate l s input (AdmissionFacts.nameSlot l id)

/-- The internal grant used by initialization preserves router invariants under
explicit separation from its actual ACL writes. Role membership is not assumed. -/
theorem grant_preserves (l : Layout) (s : Storage) (input : Input)
    (before : WriterInvariant.Holds l s ∧ AdmissionFacts.FreshRecords l s)
    (separate : InvariantSeparation l s input) :
    WriterInvariant.Holds l (grant l s input).storage ∧
    AdmissionFacts.FreshRecords l (grant l s input).storage := by
  have count := grant_other_slot l s input _ separate.count
  have row : ∀ i, i < (s (countSlot l)).val →
      (readModule l (grant l s input).storage i).identity = (readModule l s i).identity ∧
      (readModule l (grant l s input).storage i).share = (readModule l s i).share := by
    intro i hi
    have ids := grant_other_slot l s input _ (separate.ids i hi)
    have config := grant_other_slot l s input _ (separate.configs i hi)
    simp only [readModule, ids, config]
    trivial
  constructor
  · rcases before.1 with ⟨bound, shares, unique⟩
    refine ⟨by simpa only [count] using bound, ?_, ?_⟩
    · intro i hi
      rw [count] at hi
      rw [(row i hi).2]
      exact shares i hi
    · intro i j hi hj same
      rw [count] at hi hj
      rw [(row i hi).1, (row j hj).1] at same
      exact unique i j hi hj same
  · apply RecordInvariant.preserves l s _ before.2
    constructor
    · exact count
    · rw [grant_other_slot l s input _ separate.last]
    · intro i hi; exact grant_other_slot l s input _ (separate.ids i hi)
    · intro id bound; exact grant_other_slot l s input _ (separate.positions id bound)
    · intro id beyond bound; exact grant_other_slot l s input _ (separate.names id beyond bound)

theorem preserves (l : Layout) (s : Storage) (input : Input)
    (before : WriterInvariant.Holds l s ∧ AdmissionFacts.FreshRecords l s)
    (separate : InvariantSeparation l s input) :
    WriterInvariant.Holds l (execute l s input).storage ∧
    AdmissionFacts.FreshRecords l (execute l s input).storage := by
  unfold execute
  dsimp only
  split
  · exact before
  · exact grant_preserves l s input before separate

end ACLWriter
end LidoSRv3.Audit.Source.TrioAlloc1
