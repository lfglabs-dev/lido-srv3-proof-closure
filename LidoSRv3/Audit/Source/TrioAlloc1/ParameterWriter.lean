import LidoSRv3.Audit.Source.TrioAlloc1.AdmissionChecks

/-!
Physical public updateStakingModule and its SRLib._updateModuleParams helper.
The helper is separately exposed for admission composition. Validation reads the
physical enumeration; failures restore the helper entry snapshot. A caller that
has already written storage must compose that failure with its outer snapshot.
-/
namespace LidoSRv3.Audit.Source.TrioAlloc1
namespace ParameterWriter

open ShareWriter (write error Event Outcome rejected)

structure Input where
  caller : Address
  router : Address
  moduleId : Word
  share : Word
  threshold : Word
  moduleFee : Word
  treasuryFee : Word
  maxDeposits : Word
  minDistance : Word

-- SRLib.sol:296-309
def consistentFees (l : Layout) (s : Storage) (id : Word) (feeSum : Nat) :
    Nat → Nat → Except Failure Unit
  | 0, _ => .ok ()
  | n+1, i =>
    let current := s (idSlot l i)
    if current = id then consistentFees l s id feeSum n (i+1)
    else
      let packed := s (moduleSlot l current)
      if field packed 224 8 ≥ 3 then .error (.panic 0x21)
      else if field packed 160 16 + field packed 176 16 ≠ feeSum then
        .error (error l "InconsistentFeeSum()")
      else consistentFees l s id feeSum n (i+1)

-- SRLib.sol:239-266
def validate (l : Layout) (s : Storage) (input : Input) : Except Failure Unit :=
  if input.share.val > 10000 then .error (error l "InvalidStakeShareLimit()")
  else if input.threshold.val > 10000 then .error (error l "InvalidPriorityExitShareThreshold()")
  else if input.share.val > input.threshold.val then .error (error l "InvalidPriorityExitShareThreshold()")
  else if input.moduleFee.val + input.treasuryFee.val ≥ 2^256 then .error (.panic 0x11)
  else if input.moduleFee.val + input.treasuryFee.val > 10000 then .error (error l "InvalidFeeSum()")
  else match consistentFees l s input.moduleId (input.moduleFee.val+input.treasuryFee.val)
      (s (countSlot l)).val 0 with
    | .error reason => .error reason
    | .ok () =>
      if input.minDistance.val = 0 ∨ input.minDistance.val ≥ 2^64 then
        .error (error l "InvalidMinDepositBlockDistance()")
      else if input.maxDeposits.val = 0 ∨ input.maxDeposits.val ≥ 2^64 then
        .error (error l "InvalidMaxDepositPerBlockValue()")
      else if field (s (moduleSlot l input.moduleId)) 224 8 ≥ 3 then .error (.panic 0x21)
      else .ok ()

theorem validate_bounds (l : Layout) (s : Storage) (input : Input)
    (run : validate l s input = .ok ()) :
    input.share.val ≤ 10000 ∧ input.threshold.val ≤ 10000 ∧
    input.share.val ≤ input.threshold.val ∧
    input.moduleFee.val+input.treasuryFee.val ≤ 10000 ∧
    0 < input.minDistance.val ∧ input.minDistance.val < 2^64 ∧
    0 < input.maxDeposits.val ∧ input.maxDeposits.val < 2^64 := by
  unfold validate at run
  repeat first | (split at run) | (cases run)
  all_goals omega

def configWord (original : Word) (input : Input) : Word :=
  word (original.val % 2^160 + (input.moduleFee.val % 2^16)*2^160 +
    (input.treasuryFee.val % 2^16)*2^176 + (input.share.val % 2^16)*2^192 +
    (input.threshold.val % 2^16)*2^208 + original.val/2^224*2^224)

def depositsWord (original : Word) (input : Input) : Word :=
  word (original.val % 2^128 + (input.maxDeposits.val % 2^64)*2^128 +
    (input.minDistance.val % 2^64)*2^192)

private def ascii (value : String) : Bytes := value.toList.map (fun c => byte c.toNat)

def event (l : Layout) (input : Input) (signature : String) (values : List Word) : Event :=
  { emitter := input.router, topics := [l.keccak (ascii signature), input.moduleId]
    data := encodeWords (values ++ [word input.caller.val]) }

-- SRLib.sol:268-293
def executeHelper (l : Layout) (s : Storage) (input : Input) : Outcome :=
  match validate l s input with
  | .error reason => rejected s reason
  | .ok () =>
    let slot := moduleSlot l input.moduleId
    let first := write s slot (configWord (s slot) input)
    let depositSlot := word (slot.val+1)
    { result := .ok (), storage := write first depositSlot (depositsWord (first depositSlot) input)
      events := [event l input "StakingModuleShareLimitSet(uint256,uint256,uint256,address)" [input.share, input.threshold],
        event l input "StakingModuleFeesSet(uint256,uint256,uint256,address)" [input.moduleFee, input.treasuryFee],
        event l input "StakingModuleMaxDepositsPerBlockSet(uint256,uint256,address)" [input.maxDeposits],
        event l input "StakingModuleMinDepositBlockDistanceSet(uint256,uint256,address)" [input.minDistance]] }

-- StakingRouter.sol:201-220
def execute (l : Layout) (s : Storage) (input : Input) : Outcome :=
  if !AdmissionChecks.admitted l s input.caller then
    rejected s (AdmissionChecks.unauthorized l input.caller)
  else if (s (ShareWriter.modulePositionSlot l input.moduleId)).val = 0 then
    rejected s (error l "StakingModuleUnregistered()")
  else executeHelper l s input

theorem helper_revert_restores (l : Layout) (s : Storage) (input : Input) (reason : Failure)
    (run : (executeHelper l s input).result = .error reason) :
    (executeHelper l s input).storage = s ∧ (executeHelper l s input).events = [] := by
  unfold executeHelper at *
  split at * <;> simp_all [rejected]

theorem config_address (original : Word) (input : Input) :
    field (configWord original input) 0 160 = field original 0 160 := by
  have bound := original.isLt
  simp only [configWord, field, word]
  omega

theorem config_share (original : Word) (input : Input) (bound : input.share.val ≤ 10000) :
    field (configWord original input) 192 16 = input.share.val := by
  have originalBound := original.isLt
  simp only [configWord, field, word]
  omega

theorem helper_success_iff (l : Layout) (s : Storage) (input : Input) :
    (executeHelper l s input).result = .ok () ↔ validate l s input = .ok () := by
  unfold executeHelper
  split <;> simp_all [rejected]

theorem helper_stored_share_bound (l : Layout) (s : Storage) (input : Input)
    (run : (executeHelper l s input).result = .ok ()) :
    field ((executeHelper l s input).storage (moduleSlot l input.moduleId)) 192 16 ≤ 10000 := by
  have valid := (helper_success_iff l s input).mp run
  have bounded := (validate_bounds l s input valid).1
  have slotBound := (moduleSlot l input.moduleId).isLt
  have separate : moduleSlot l input.moduleId ≠ word ((moduleSlot l input.moduleId).val+1) := by
    intro equal
    have := congrArg Fin.val equal
    simp only [word] at this
    omega
  simp only [executeHelper, valid, write, if_neg separate, ite_true]
  rw [config_share _ input bounded]
  exact bounded

theorem helper_other_slot (l : Layout) (s : Storage) (input : Input) (slot : Word)
    (configSeparate : slot ≠ moduleSlot l input.moduleId)
    (depositSeparate : slot ≠ word ((moduleSlot l input.moduleId).val+1)) :
    (executeHelper l s input).storage slot = s slot := by
  unfold executeHelper
  split <;> simp [rejected, write, configSeparate, depositSeparate]

theorem execute_revert_restores (l : Layout) (s : Storage) (input : Input) (reason : Failure)
    (run : (execute l s input).result = .error reason) :
    (execute l s input).storage = s ∧ (execute l s input).events = [] := by
  unfold execute at *
  split
  · simp [rejected]
  · split
    · simp [rejected]
    · exact helper_revert_restores l s input reason (by simp_all)

theorem helper_identity (l : Layout) (s : Storage) (input : Input) (i : Nat)
    (idConfig : idSlot l i ≠ moduleSlot l input.moduleId)
    (idDeposit : idSlot l i ≠ word ((moduleSlot l input.moduleId).val+1))
    (rowDeposit : moduleSlot l (s (idSlot l i)) ≠ word ((moduleSlot l input.moduleId).val+1)) :
    (readModule l (executeHelper l s input).storage i).identity = (readModule l s i).identity := by
  have ids := helper_other_slot l s input (idSlot l i) idConfig idDeposit
  simp only [readModule, ids]
  cases valid : validate l s input with
  | error reason => simp only [executeHelper, valid, rejected]
  | ok result =>
    cases result
    simp only [executeHelper, valid, write, if_neg rowDeposit]
    by_cases same : moduleSlot l (s (idSlot l i)) = moduleSlot l input.moduleId
    · simp [same, config_address]
    · simp only [if_neg same]

theorem helper_row_share_bound (l : Layout) (s : Storage) (input : Input) (i : Nat)
    (idConfig : idSlot l i ≠ moduleSlot l input.moduleId)
    (idDeposit : idSlot l i ≠ word ((moduleSlot l input.moduleId).val+1))
    (rowDeposit : moduleSlot l (s (idSlot l i)) ≠ word ((moduleSlot l input.moduleId).val+1))
    (before : (readModule l s i).share.val ≤ 10000) :
    (readModule l (executeHelper l s input).storage i).share.val ≤ 10000 := by
  have ids := helper_other_slot l s input (idSlot l i) idConfig idDeposit
  simp only [readModule, ids]
  unfold executeHelper
  split
  · exact before
  · rename_i valid
    simp only [write, if_neg rowDeposit]
    by_cases same : moduleSlot l (s (idSlot l i)) = moduleSlot l input.moduleId
    · simp only [if_pos same, config_share _ input (validate_bounds l s input valid).1]
      exact (validate_bounds l s input valid).1
    · simpa only [readModule, if_neg same] using before

end ParameterWriter
end LidoSRv3.Audit.Source.TrioAlloc1
