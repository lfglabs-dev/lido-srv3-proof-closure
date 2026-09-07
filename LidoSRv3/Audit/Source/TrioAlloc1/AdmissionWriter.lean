import LidoSRv3.Audit.Source.TrioAlloc1.ParameterWriter
import LidoSRv3.Audit.Source.TrioAlloc1.EnumerationWriter
import LidoSRv3.Audit.Source.TrioAlloc1.StringStorage

/-!
Public addStakingModule transition through parameter validation, name storage,
last-ID and last-deposit fields and all six events. Every failed stage is rolled
back to the public entry snapshot. This is a physical SOURCE transition; full
reachable-state induction and bytecode/memory/gas correspondence remain separate.
-/
namespace LidoSRv3.Audit.Source.TrioAlloc1
namespace AdmissionWriter

open ShareWriter (write Event)

structure Input where
  caller : Address
  router : Address
  address : Address
  name : Bytes
  wcType : Word
  share : Word
  threshold : Word
  moduleFee : Word
  treasuryFee : Word
  maxDeposits : Word
  minDistance : Word
  timestamp : Word
  blockNumber : Word

def checks (input : Input) : AdmissionChecks.Input :=
  ⟨input.caller, input.address, input.name, input.wcType⟩

def parameters (input : Input) (id : Word) : ParameterWriter.Input :=
  ⟨input.caller, input.router, id, input.share, input.threshold, input.moduleFee,
    input.treasuryFee, input.maxDeposits, input.minDistance⟩

def addressActiveWord (original : Word) (address : Address) : Word :=
  word (address.val + (original.val/2^160 % 2^64)*2^160 + original.val/2^232*2^232)

def credentialsWord (original wc : Word) : Word :=
  word (original.val % 2^232 + (wc.val % 256)*2^232 + original.val/2^240*2^240)

def lastIdWord (original id : Word) : Word :=
  word (id.val % 2^24 + original.val/2^24*2^24)

def lastDepositWord (original timestamp blockNumber : Word) : Word :=
  word (timestamp.val % 2^64 + (blockNumber.val % 2^64)*2^64 + original.val/2^128*2^128)

private def ascii (value : String) : Bytes := value.toList.map (fun c => byte c.toNat)

def addedEvent (l : Layout) (input : Input) (id : Word) : Event :=
  { emitter := input.router
    topics := [l.keccak (ascii "StakingModuleAdded(uint256,address,string,address)"), id]
    data := encodeWords [word input.address.val, 96, word input.caller.val, word input.name.length] ++
      input.name ++ List.replicate ((32-input.name.length % 32) % 32) 0 }

def depositEvent (l : Layout) (input : Input) (id : Word) : Event :=
  { emitter := input.router
    topics := [l.keccak (ascii "StakingRouterETHDeposited(uint256,uint256)"), id]
    data := encodeWord 0 }

structure Success where
  id : Word
  storage : Storage
  events : List Event

-- SRLib.sol:208-232
-- StakingRouter.sol:185-189
-- SRLib.sol:896-901
-- StakingRouter.sol:1054-1056
def stages (l : Layout) (s : Storage) (input : Input) : Except Failure Success := do
  let _ ← AdmissionChecks.check l s (checks input)
  let id ← AdmissionChecks.nextId l s
  let inserted ← EnumerationWriter.insert l s id
  let slot := moduleSlot l id
  let addressed := write inserted slot (addressActiveWord (inserted slot) input.address)
  let configured := write addressed slot (credentialsWord (addressed slot) input.wcType)
  let named ← StringStorage.writeShort l configured (word (slot.val+3)) input.name
  let updated := ParameterWriter.executeHelper l named (parameters input id)
  match updated.result with
  | .error reason => .error reason
  | .ok () =>
    let last := AdmissionChecks.lastIdSlot l
    let numbered := write updated.storage last (lastIdWord (updated.storage last) id)
    let deposit := word (slot.val+1)
    let final := write numbered deposit
      (lastDepositWord (numbered deposit) input.timestamp input.blockNumber)
    .ok ⟨id, final, [addedEvent l input id] ++ updated.events ++ [depositEvent l input id]⟩

structure Outcome where
  result : Except Failure Word
  storage : Storage
  events : List Event

-- StakingRouter.sol:180-190
def execute (l : Layout) (s : Storage) (input : Input) : Outcome :=
  match stages l s input with
  | .error reason => ⟨.error reason, s, []⟩
  | .ok success => ⟨.ok success.id, success.storage, success.events⟩

theorem revert_restores (l : Layout) (s : Storage) (input : Input) (reason : Failure)
    (run : (execute l s input).result = .error reason) :
    (execute l s input).storage = s ∧ (execute l s input).events = [] := by
  unfold execute at *
  split at * <;> simp_all

theorem stages_admission_checks (l : Layout) (s : Storage) (input : Input) (success : Success)
    (run : stages l s input = .ok success) :
    AdmissionChecks.check l s (checks input) = .ok (s (countSlot l)) := by
  cases guard : AdmissionChecks.check l s (checks input) with
  | error reason =>
    unfold stages at run
    simp only [guard] at run
    change Except.error reason = Except.ok success at run
    cases run
  | ok count =>
    have same := (AdmissionChecks.check_success l s (checks input) count guard).1
    subst count
    rfl

theorem successful_entry_bound_and_freshness (l : Layout) (s : Storage) (input : Input)
    (success : Success) (run : stages l s input = .ok success) :
    (s (countSlot l)).val < 32 ∧
    ∀ i, i < (s (countSlot l)).val →
      (readModule l s i).identity.moduleAddress ≠ input.address := by
  have admitted := AdmissionChecks.check_success l s (checks input) (s (countSlot l))
    (stages_admission_checks l s input success run)
  exact ⟨admitted.2.1, admitted.2.2.2.2.2.2.2⟩

theorem active_address (original : Word) (address : Address) :
    field (addressActiveWord original address) 0 160 = address.val ∧
    field (addressActiveWord original address) 224 8 = 0 := by
  have ho := original.isLt
  have ha := address.isLt
  simp only [addressActiveWord, field, word]
  omega

theorem credentials_preserve_address (original wc : Word) :
    field (credentialsWord original wc) 0 160 = field original 0 160 := by
  have ho := original.isLt
  simp only [credentialsWord, field, word]
  omega

theorem lastDeposit_fields (original timestamp blockNumber : Word) :
    field (lastDepositWord original timestamp blockNumber) 0 64 = timestamp.val % 2^64 ∧
    field (lastDepositWord original timestamp blockNumber) 64 64 = blockNumber.val % 2^64 ∧
    (lastDepositWord original timestamp blockNumber).val / 2^128 = original.val / 2^128 := by
  have ho := original.isLt
  simp only [lastDepositWord, field, word]
  omega

end AdmissionWriter
end LidoSRv3.Audit.Source.TrioAlloc1
