import audit.trio.deposit.LiveBeaconCommitted
import LidoSRv3.Audit.Source.TopupRouterCredentials

/-! StakingRouter.sol:976/1054 and SRLib.sol:896 at core17005714.
The packed module word is changed in the same live world BEFORE the zero-key
return or Lido withdrawal. This is consumed by the execution below, rather
than recorded in auxiliary metadata after the external calls.

The allocation/module prefix still uses the existing prepared-prefix model;
its physical CALL/storage connection is not established here. Events retain
the declared Live.Log semantic representation, not LOG topics/data. -/
namespace audit.trio.deposit.PhysicalMetadata
open LidoSRv3.Audit.Source
open TrioReserve1 Live
open audit.trio.deposit
open TopupRouterCredentials (Keccak)

/-- ModuleState.deposits is slot 1 of the mapping entry, with EVM wrap. -/
def moduleDepositSlot (hash : Keccak) (moduleId : TrioAlloc1.Word) : Nat :=
  (Live.word (TopupRouterCredentials.moduleSlot hash (Live.word moduleId.val) + 1)).val

def setTimestamp (old : Live.Word) (timestamp : Nat) : Live.Word :=
  Live.word (old.val / 2^64 * 2^64 + timestamp % 2^64)

def setBlock (old : Live.Word) (blockNumber : Nat) : Live.Word :=
  Live.word (old.val % 2^64 + blockNumber % 2^64 * 2^64 + old.val / 2^128 * 2^128)

/-- Two uint64 assignments preserve the upper maxDeposits/minDistance pair. -/
theorem packed_fields (old : Live.Word) (timestamp blockNumber : Nat) :
    (setBlock (setTimestamp old timestamp) blockNumber).val % 2^64 = timestamp % 2^64 ∧
    (setBlock (setTimestamp old timestamp) blockNumber).val / 2^64 % 2^64 = blockNumber % 2^64 ∧
    (setBlock (setTimestamp old timestamp) blockNumber).val / 2^128 = old.val / 2^128 := by
  have ho := old.isLt
  simp only [setBlock, setTimestamp, Live.word, Verity.Core.Uint256.ofNat, Verity.Core.Uint256.modulus, Verity.Core.UINT256_MODULUS] at *
  omega

def routerEvent (router : Live.Address) (prepared : PreparedDeposit) : Live.Log :=
  ⟨router, "StakingRouterETHDeposited",
    [Live.word prepared.moduleId.val, Live.word prepared.values.lidoPullWei]⟩

/-- Actual read/modify/write order, followed by the source router event. -/
def update (hash : Keccak) (_ctx : RouterDeposit.Context) (router : Live.Address)
    (prepared : PreparedDeposit) (before : Live.World) : Live.World :=
  let key := moduleDepositSlot hash prepared.moduleId
  let first := before.core.writeContractSlot router.val key
    (setTimestamp (before.core.readContractSlot router.val key) before.core.blockTimestamp.val)
  let second := first.writeContractSlot router.val key
    (setBlock (first.readContractSlot router.val key) before.core.blockNumber.val)
  { before with core := second, logs := before.logs ++ [routerEvent router prepared] }

theorem update_word (hash : Keccak) (ctx : RouterDeposit.Context) (router : Live.Address)
    (prepared : PreparedDeposit) (before : Live.World) :
    ((update hash ctx router prepared before).core.readContractSlot router.val
      (moduleDepositSlot hash prepared.moduleId)).val =
      (setBlock (setTimestamp (before.core.readContractSlot router.val
        (moduleDepositSlot hash prepared.moduleId)) before.core.blockTimestamp.val) before.core.blockNumber.val).val := by
  by_cases hr : router.val = 0 <;>
    simp [update, Verity.ContractState.readContractSlot, Verity.ContractState.writeContractSlot,
      Verity.ContractState.readSlot, Verity.ContractState.writeSlot,
      Verity.ContractState.storage, Verity.ContractState.contractStorage, hr]

theorem update_fields (hash : Keccak) (ctx : RouterDeposit.Context) (router : Live.Address)
    (prepared : PreparedDeposit) (before : Live.World) :
    let key := moduleDepositSlot hash prepared.moduleId
    let result := ((update hash ctx router prepared before).core.readContractSlot router.val key).val
    result % 2^64 = before.core.blockTimestamp.val % 2^64 ∧
    result / 2^64 % 2^64 = before.core.blockNumber.val % 2^64 ∧
    result / 2^128 = (before.core.readContractSlot router.val key).val / 2^128 := by
  dsimp only
  rw [update_word]
  exact packed_fields _ _ _

structure World where
  allocationTranscript : TrioAlloc1.Transcript
  live : Live.World

structure Result where
  outcome : Except LiveBeacon.Fault Unit
  world : World
  attempts : List Live.Attempt := []

/-- Same prepared-prefix branches as LiveBeacon, with physical metadata and
the event now visible to the withdrawal and its callbacks in the correct order. -/
def executeRaw (hash : Keccak) (callee : Live.External) (ctx : RouterDeposit.Context)
    (inputs : RouterDeposit.Inputs) (before : World) : Result :=
  if ctx.caller != ctx.depositSecurityModule then ⟨.error .notAuthorized, before, []⟩
  else if !ctx.moduleActive then ⟨.error .moduleNotActive, before, []⟩
  else match ctx.withdrawalCredentials with
  | none => ⟨.error .unsupportedWithdrawalCredentials, before, []⟩
  | some credentials =>
    let preparation := prepareDepositABI inputs.layout inputs.storage inputs.oracle inputs.config
      inputs.requested before.allocationTranscript inputs.moduleId inputs.limits
      inputs.obtainDepositData DEPOSIT_SIZE
    match preparation.1 with
    | .error reason =>
      ⟨.error (.depositPrefix reason), {before with allocationTranscript := preparation.2}, []⟩
    | .ok prepared =>
      let updated := update hash ctx inputs.liveContext.sender prepared before.live
      let r := LiveBeacon.suffix callee ctx inputs.liveContext credentials prepared updated
      ⟨LiveBeacon.liftOutcome r.outcome, ⟨preparation.2,r.world⟩, r.attempts⟩

def execute (hash : Keccak) (callee : Live.External) (ctx : RouterDeposit.Context)
    (inputs : RouterDeposit.Inputs) (before : World) : Result :=
  let r := executeRaw hash callee ctx inputs before
  match r.outcome with
  | .ok () => r
  | .error fault => ⟨.error fault,before,r.attempts⟩

theorem failure_restores (hash : Keccak) (callee : Live.External) (ctx : RouterDeposit.Context)
    (inputs : RouterDeposit.Inputs) (before after : World) (fault : LiveBeacon.Fault)
    (attempts : List Live.Attempt)
    (h : execute hash callee ctx inputs before = ⟨.error fault,after,attempts⟩) :
    after = before := by
  unfold execute at h
  dsimp only at h
  split at h
  · have he := congrArg Result.outcome h
    simp_all
  · exact (Result.mk.inj h).2.1.symm

/-- Success supplies the executed preparation and suffix; no supplied
successful stage, zero-key restriction or metadata/ledger preservation premise. -/
theorem success_suffix (hash : Keccak) (callee : Live.External) (ctx : RouterDeposit.Context)
    (inputs : RouterDeposit.Inputs) (before after : World) (attempts : List Live.Attempt)
    (h : execute hash callee ctx inputs before = ⟨.ok (),after,attempts⟩) :
    ∃ credentials prepared transcript,
      prepareDepositABI inputs.layout inputs.storage inputs.oracle inputs.config
        inputs.requested before.allocationTranscript inputs.moduleId inputs.limits
        inputs.obtainDepositData DEPOSIT_SIZE = (.ok prepared,transcript) ∧
      after.allocationTranscript = transcript ∧
      LiveBeacon.suffix callee ctx inputs.liveContext credentials prepared
        (update hash ctx inputs.liveContext.sender prepared before.live) =
        ⟨.ok (),after.live,attempts⟩ := by
  by_cases ha : ctx.caller = ctx.depositSecurityModule
  · by_cases hm : ctx.moduleActive = true
    · cases hc : ctx.withdrawalCredentials with
      | none => simp [execute,executeRaw,ha,hm,hc] at h
      | some credentials =>
        cases hp : prepareDepositABI inputs.layout inputs.storage inputs.oracle inputs.config
          inputs.requested before.allocationTranscript inputs.moduleId inputs.limits
          inputs.obtainDepositData DEPOSIT_SIZE with
        | mk outcome transcript =>
          cases outcome with
          | «error» fault => simp [execute,executeRaw,ha,hm,hc,hp] at h
          | ok prepared =>
            cases hs : LiveBeacon.suffix callee ctx inputs.liveContext credentials prepared
              (update hash ctx inputs.liveContext.sender prepared before.live) with
            | mk outcome live trace =>
              cases outcome with
              | «error» fault => simp [execute,executeRaw,ha,hm,hc,hp,hs,LiveBeacon.liftOutcome] at h
              | ok u =>
                cases u
                simp only [execute,executeRaw,ha,bne_self_eq_false,Bool.false_eq_true,if_false,
                  hm,Bool.not_true,hc,hp,hs,LiveBeacon.liftOutcome,Result.mk.injEq,true_and] at h
                obtain ⟨hw,ht⟩ := h
                cases hw
                cases ht
                exact ⟨credentials,prepared,transcript,rfl,rfl,hs⟩
    · simp [execute,executeRaw,ha,hm] at h
  · simp [execute,executeRaw,ha] at h

/-- The physical prefix is the input of the actual withdrawal/beacon
continuation. A zero-key commit retains its writes/event without making calls;
a nonzero commit derives the actual same-world withdrawal and beacon effects. -/
theorem success_effects (hash : Keccak) (callee : Live.External) (ctx : RouterDeposit.Context)
    (inputs : RouterDeposit.Inputs) (before after : World) (attempts : List Live.Attempt)
    (h : execute hash callee ctx inputs before = ⟨.ok (),after,attempts⟩) :
    ∃ credentials prepared transcript,
      prepareDepositABI inputs.layout inputs.storage inputs.oracle inputs.config
        inputs.requested before.allocationTranscript inputs.moduleId inputs.limits
        inputs.obtainDepositData DEPOSIT_SIZE = (.ok prepared,transcript) ∧
      after.allocationTranscript = transcript ∧
      let updated := update hash ctx inputs.liveContext.sender prepared before.live
      let key := moduleDepositSlot hash prepared.moduleId
      let packed := (updated.core.readContractSlot inputs.liveContext.sender.val key).val
      (packed % 2^64 = before.live.core.blockTimestamp.val % 2^64 ∧
       packed / 2^64 % 2^64 = before.live.core.blockNumber.val % 2^64 ∧
       packed / 2^128 = (before.live.core.readContractSlot inputs.liveContext.sender.val key).val / 2^128) ∧
      updated.balances = before.live.balances ∧
      updated.logs = before.live.logs ++ [routerEvent inputs.liveContext.sender prepared] ∧
      ((prepared.values.actualKeys = 0 ∧ after.live = updated ∧ attempts = []) ∨
       (prepared.values.actualKeys ≠ 0 ∧ Nonempty
         (LiveBeaconCommitted.SuffixCommitment callee ctx inputs.liveContext credentials prepared
           updated after.live attempts))) := by
  obtain ⟨credentials,prepared,transcript,hp,ht,hs⟩ :=
    success_suffix hash callee ctx inputs before after attempts h
  refine ⟨credentials,prepared,transcript,hp,ht,
    update_fields hash ctx inputs.liveContext.sender prepared before.live,rfl,rfl,?_⟩
  by_cases hz : prepared.values.actualKeys = 0
  · left
    rw [LiveBeacon.zero_keys_no_calls callee ctx inputs.liveContext credentials prepared _ hz] at hs
    exact ⟨hz,(Live.Result.mk.inj hs).2.1.symm,(Live.Result.mk.inj hs).2.2.symm⟩
  · exact Or.inr ⟨hz,LiveBeaconCommitted.suffix_ok_commitment callee ctx inputs.liveContext
      credentials prepared _ after.live attempts hz hs⟩

#print axioms packed_fields
#print axioms success_effects
#print axioms failure_restores
end audit.trio.deposit.PhysicalMetadata
