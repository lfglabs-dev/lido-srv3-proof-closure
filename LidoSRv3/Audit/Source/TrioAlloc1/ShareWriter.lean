import LidoSRv3.Audit.Source.TrioAlloc1.Bytes

/-!
Physical `StakingRouter.updateModuleShares` path at core@17005714: role admission,
EnumerableSet membership, share guards, packed update and event. Hashing and the
router execution context remain explicit parameters; admission is read from state.
This is one relevant writer, not a proof of reachability through every writer.
-/
namespace LidoSRv3.Audit.Source.TrioAlloc1
namespace ShareWriter

private def ascii (value : String) : Bytes := value.toList.map (fun c => byte c.toNat)

def roleId (l : Layout) : Word := l.keccak (ascii "STAKING_MODULE_SHARE_MANAGE_ROLE")

def aclBase : Word := word 0x02dd7bc7dec4dceedda775e58dd541e08a116c6c53815c0bd028192f7b626800

def roleMemberSlot (l : Layout) (caller : Address) : Word :=
  l.keccak (encodeWord (word caller.val) ++
    encodeWord (l.keccak (encodeWord (roleId l) ++ encodeWord aclBase)))

def modulePositionSlot (l : Layout) (id : Word) : Word :=
  l.keccak (encodeWord id ++ encodeWord (word (l.routerSlot.val+2)))

def admitted (l : Layout) (s : Storage) (caller : Address) : Bool :=
  field (s (roleMemberSlot l caller)) 0 8 != 0

def selector (l : Layout) (signature : String) : Bytes :=
  (encodeWord (l.keccak (ascii signature))).take 4

def error (l : Layout) (signature : String) : Failure := .revertData (selector l signature)

def unauthorized (l : Layout) (caller : Address) : Failure :=
  .revertData (selector l "AccessControlUnauthorizedAccount(address,bytes32)" ++
    encodeWord (word caller.val) ++ encodeWord (roleId l))

def replaceShares (original : Word) (share threshold : Fin (2^16)) : Word :=
  word (original.val % 2^192 + share.val*2^192 + threshold.val*2^208 + original.val/2^224*2^224)

def write (s : Storage) (slot value : Word) : Storage := fun address =>
  if address = slot then value else s address

structure Event where
  emitter : Address
  topics : List Word
  data : Bytes
  deriving DecidableEq, Repr

structure Input where
  caller : Address
  router : Address
  moduleId : Word
  share : Fin (2^16)
  threshold : Fin (2^16)

structure Outcome where
  result : Except Failure Unit
  storage : Storage
  events : List Event

def rejected (s : Storage) (reason : Failure) : Outcome := ⟨.error reason, s, []⟩

/-- Public function order: role, module membership, share validation, enum load, write/event. -/
def execute (l : Layout) (s : Storage) (input : Input) : Outcome :=
  if !admitted l s input.caller then rejected s (unauthorized l input.caller)
  else if (s (modulePositionSlot l input.moduleId)).val = 0 then
    rejected s (error l "StakingModuleUnregistered()")
  else if input.share.val > 10000 then rejected s (error l "InvalidStakeShareLimit()")
  else if input.threshold.val > 10000 then rejected s (error l "InvalidPriorityExitShareThreshold()")
  else if input.share.val > input.threshold.val then rejected s (error l "InvalidPriorityExitShareThreshold()")
  else
    let slot := moduleSlot l input.moduleId
    let original := s slot
    if field original 224 8 ≥ 3 then rejected s (.panic (word 0x21))
    else { result := .ok (), storage := write s slot (replaceShares original input.share input.threshold)
           events := [{ emitter := input.router
                        topics := [l.keccak (ascii "StakingModuleShareLimitSet(uint256,uint256,uint256,address)"), input.moduleId]
                        data := encodeWords [word input.share.val, word input.threshold.val, word input.caller.val] }] }

theorem replaceShares_share (original : Word) (share threshold : Fin (2^16)) :
    field (replaceShares original share threshold) 192 16 = share.val := by
  have ho := original.isLt
  have hs := share.isLt
  have ht := threshold.isLt
  simp only [replaceShares, field, word]
  omega

theorem replaceShares_threshold (original : Word) (share threshold : Fin (2^16)) :
    field (replaceShares original share threshold) 208 16 = threshold.val := by
  have ho := original.isLt
  have hs := share.isLt
  have ht := threshold.isLt
  simp only [replaceShares, field, word]
  omega

theorem replaceShares_preserves_low (original : Word) (share threshold : Fin (2^16)) :
    (replaceShares original share threshold).val % 2^192 = original.val % 2^192 := by
  have ho := original.isLt
  have hs := share.isLt
  have ht := threshold.isLt
  simp only [replaceShares, word]
  omega

theorem replaceShares_preserves_high (original : Word) (share threshold : Fin (2^16)) :
    (replaceShares original share threshold).val / 2^224 = original.val / 2^224 := by
  have ho := original.isLt
  have hs := share.isLt
  have ht := threshold.isLt
  simp only [replaceShares, word]
  omega

theorem execute_cases (l : Layout) (s : Storage) (input : Input) :
    (∃ reason, execute l s input = rejected s reason) ∨ (execute l s input).result = .ok () := by
  dsimp only [execute]
  repeat first | (exact Or.inl ⟨_, rfl⟩) | (exact Or.inr rfl) | split

theorem execute_revert_restores (l : Layout) (s : Storage) (input : Input) (reason : Failure)
    (h : (execute l s input).result = .error reason) :
    (execute l s input).storage = s ∧ (execute l s input).events = [] := by
  rcases execute_cases l s input with ⟨reason', hr⟩ | success
  · rw [hr]
    exact ⟨rfl, rfl⟩
  · rw [success] at h
    cases h

theorem execute_derives_admission_and_bounds (l : Layout) (s : Storage) (input : Input)
    (h : (execute l s input).result = .ok ()) :
    admitted l s input.caller = true ∧
    (s (modulePositionSlot l input.moduleId)).val ≠ 0 ∧
    input.share.val ≤ 10000 ∧ input.threshold.val ≤ 10000 ∧ input.share.val ≤ input.threshold.val := by
  unfold execute at h
  repeat first | split at h | (simp_all [rejected])

end ShareWriter
end LidoSRv3.Audit.Source.TrioAlloc1
