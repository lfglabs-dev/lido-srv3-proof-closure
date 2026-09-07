import LidoSRv3.Audit.Source.TrioAlloc1.ShareWriter

/-!
The read-only admission prefix, before the first write in SRLib._addModule.
This is not the whole public writer: parameter updates, EnumerableSet writes,
name encoding, events, last-ID and last-deposit writes must still be composed.
-/
namespace LidoSRv3.Audit.Source.TrioAlloc1
namespace AdmissionChecks

-- SRLib.sol:203-210
/-- Forward scan, preserving the first duplicate rejection. -/
def scan (l : Layout) (s : Storage) (address : Address) : Nat → Nat → Except Failure Unit
  | 0, _ => .ok ()
  | n+1, i =>
    if (readModule l s i).identity.moduleAddress = address then
      .error (ShareWriter.error l "StakingModuleAddressExists()")
    else scan l s address n (i+1)

theorem scan_success_iff (l : Layout) (s : Storage) (address : Address) (n i : Nat) :
    scan l s address n i = .ok () ↔
      ∀ j, i ≤ j → j < i+n → (readModule l s j).identity.moduleAddress ≠ address := by
  induction n generalizing i with
  | zero =>
    constructor
    · intro _ j low high
      omega
    · intro _
      rfl
  | succ n ih =>
    simp only [scan]
    split
    · rename_i duplicate
      constructor
      · intro impossible
        cases impossible
      · intro fresh
        exact False.elim (fresh i (by omega) (by omega) duplicate)
    · rename_i freshHead
      rw [ih]
      constructor
      · intro rest j low high
        by_cases atHead : j = i
        · simpa only [atHead] using freshHead
        · exact rest j (by omega) (by omega)
      · intro all j low high
        exact all j (by omega) (by omega)

private def ascii (value : String) : Bytes := value.toList.map (fun c => byte c.toNat)

def manageRole (l : Layout) : Word := l.keccak (ascii "STAKING_MODULE_MANAGE_ROLE")

def roleSlot (l : Layout) (caller : Address) : Word :=
  l.keccak (encodeWord (word caller.val) ++
    encodeWord (l.keccak (encodeWord (manageRole l) ++ encodeWord ShareWriter.aclBase)))

def admitted (l : Layout) (s : Storage) (caller : Address) : Bool :=
  field (s (roleSlot l caller)) 0 8 != 0

def unauthorized (l : Layout) (caller : Address) : Failure := .revertData
  (ShareWriter.selector l "AccessControlUnauthorizedAccount(address,bytes32)" ++
    encodeWord (word caller.val) ++ encodeWord (manageRole l))

structure Input where
  caller : Address
  address : Address
  name : Bytes
  wcType : Word

-- StakingRouter.sol:180-185
-- SRLib.sol:188-210
/-- Actual guard order through the duplicate scan; returns the physical count. -/
def check (l : Layout) (s : Storage) (input : Input) : Except Failure Word :=
  if !admitted l s input.caller then .error (unauthorized l input.caller)
  else if input.address.val = 0 then .error (ShareWriter.error l "ZeroAddress()")
  else if input.name.length = 0 ∨ input.name.length > 31 then
    .error (ShareWriter.error l "StakingModuleWrongName()")
  else if (s (countSlot l)).val ≥ 32 then .error (ShareWriter.error l "StakingModulesLimitExceeded()")
  else if ¬ (input.wcType.val = 1 ∨ input.wcType.val = 2) then
    .error (ShareWriter.error l "WrongWithdrawalCredentialsType()")
  else match scan l s input.address (s (countSlot l)).val 0 with
    | .error reason => .error reason
    | .ok () => .ok (s (countSlot l))

theorem check_success (l : Layout) (s : Storage) (input : Input) (count : Word)
    (h : check l s input = .ok count) :
    count = s (countSlot l) ∧ count.val < 32 ∧
    admitted l s input.caller = true ∧ input.address.val ≠ 0 ∧
    0 < input.name.length ∧ input.name.length ≤ 31 ∧
    (input.wcType.val = 1 ∨ input.wcType.val = 2) ∧
    ∀ i, i < count.val → (readModule l s i).identity.moduleAddress ≠ input.address := by
  unfold check at h
  split at h
  · cases h
  · rename_i role
    split at h
    · cases h
    · rename_i address
      split at h
      · cases h
      · rename_i name
        split at h
        · cases h
        · rename_i countBound
          split at h
          · cases h
          · rename_i wc
            split at h
            · cases h
            · rename_i scanned
              cases h
              refine ⟨rfl, by omega, by simpa using role, address, by omega, by omega, by omega, ?_⟩
              intro i hi
              exact (scan_success_iff l s input.address _ _).mp scanned i (by omega) (by omega)

def lastIdSlot (l : Layout) : Word := word (l.routerSlot.val+5)

-- SRLib.sol:208
/-- Addition is performed in uint24 before widening to the uint256 return ID. -/
def nextId (l : Layout) (s : Storage) : Except Failure Word :=
  let next := field (s (lastIdSlot l)) 0 24 + 1
  if next < 2^24 then .ok (word next) else .error (.panic 0x11)

theorem nextId_success (l : Layout) (s : Storage) (id : Word)
    (run : nextId l s = .ok id) :
    id.val = field (s (lastIdSlot l)) 0 24 + 1 ∧ 0 < id.val ∧ id.val < 2^24 := by
  unfold nextId at run
  dsimp only at run
  split at run
  · rename_i safe
    cases run
    have wide : field (s (lastIdSlot l)) 0 24 + 1 < 2^256 := by omega
    change (field (s (lastIdSlot l)) 0 24 + 1) % 2^256 = _ ∧
      0 < (field (s (lastIdSlot l)) 0 24 + 1) % 2^256 ∧
      (field (s (lastIdSlot l)) 0 24 + 1) % 2^256 < 2^24
    rw [Nat.mod_eq_of_lt wide]
    exact ⟨rfl, by omega, safe⟩
  · cases run

theorem nextId_overflow (l : Layout) (s : Storage)
    (maximal : field (s (lastIdSlot l)) 0 24 = 2^24-1) :
    nextId l s = .error (.panic 0x11) := by
  simp [nextId, maximal]

end AdmissionChecks
end LidoSRv3.Audit.Source.TrioAlloc1
