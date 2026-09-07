import LidoSRv3.Audit.Source.TrioReserve1.CallbackSpec
import LidoSRv3.Audit.Source.TrioReserve1.VaultRules
import LidoSRv3.Audit.Source.TrioReserve1.WithdrawalCalls

namespace LidoSRv3.Audit.Source.TrioReserve1.CallbackRules
open Live

def lookup (external : External) (ctx : Context) (selector : Nat) :=
  WithdrawalCalls.lookup (CallFlow.Describes external) ctx selector

theorem lookup_observations (external : External) (ctx : Context) (selector : Nat) :
    lookup external ctx selector =
      (fun w outcome after trace => locatorAddress external ctx selector w = ⟨outcome, after, trace⟩) := by
  unfold lookup
  rw [WithdrawalCalls.call_observations]
  funext w outcome after trace
  exact propext (Lookup.corresponds external ctx selector w after outcome trace)

def total (ctx : Context) (w : World) : Nat :=
  (w.core.readContractSlot ctx.self.val VaultCallbacks.totalRewardsSlot).val

def rewardCommit (ctx : Context) (value : Word) (w : World) (sum : Nat) : World :=
  {w with
    core := w.core.writeContractSlot ctx.self.val VaultCallbacks.totalRewardsSlot (word sum)
    logs := w.logs ++ [⟨ctx.self, "ELRewardsReceived", [value]⟩]}

def withdrawalCommit (ctx : Context) (value : Word) (w : World) : World :=
  {w with logs := w.logs ++ [⟨ctx.self, "WithdrawalsReceived", [value]⟩]}

def Rewards (external : External) (ctx : Context) (value : Word) :=
  CallbackSpec.Receives (.reason "APP_AUTH_FAILED") ctx.sender (lookup external ctx 0xe441d25f)
    (CallbackSpec.RewardUpdate (.reason "MATH_ADD_OVERFLOW") Verity.Core.UINT256_MODULUS value.val
      (total ctx) (rewardCommit ctx value))

def Withdrawals (external : External) (ctx : Context) (value : Word) :=
  CallbackSpec.Receives (.reason "APP_AUTH_FAILED") ctx.sender (lookup external ctx 0x69d42148)
    (fun w outcome after => outcome = .ok () ∧ after = withdrawalCommit ctx value w)

theorem rewards_of_spec (external : External) (ctx : Context) (value : Word)
    (before after : World) (outcome : Except Fault Unit) (trace : List Attempt)
    (h : Rewards external ctx value before outcome after trace) :
    VaultCallbacks.receiveRewards external ctx value before = ⟨outcome, after, trace⟩ := by
  unfold Rewards at h
  rw [lookup_observations] at h
  cases h with
  | lookup_error hl => simp [VaultCallbacks.receiveRewards, hl, bind, bindExec]
  | unauthorized hl ha => simp [VaultCallbacks.receiveRewards, hl, ha, bind, bindExec, require, fail]
  | admitted hl ha hu =>
    cases hu <;> simp_all [VaultCallbacks.receiveRewards, total, rewardCommit,
      checkedAdd, Live.read, write, emit, bind, bindExec, require, pure, pureExec, fail, Nat.not_lt.mpr]

theorem withdrawals_of_spec (external : External) (ctx : Context) (value : Word)
    (before after : World) (outcome : Except Fault Unit) (trace : List Attempt)
    (h : Withdrawals external ctx value before outcome after trace) :
    VaultCallbacks.receiveWithdrawals external ctx value before = ⟨outcome, after, trace⟩ := by
  unfold Withdrawals at h
  rw [lookup_observations] at h
  cases h <;> simp_all [VaultCallbacks.receiveWithdrawals, withdrawalCommit,
    emit, bind, bindExec, require, pure, pureExec, fail]

theorem rewards_exists (external : External) (ctx : Context) (value : Word) (before : World) :
    ∃ outcome after trace, Rewards external ctx value before outcome after trace := by
  unfold Rewards
  rw [lookup_observations]
  generalize hl : locatorAddress external ctx 0xe441d25f before = result
  rcases result with ⟨outcome, located, trace⟩
  cases outcome with
  | error fault => exact ⟨_, _, _, .lookup_error hl⟩
  | ok vault =>
    by_cases ha : ctx.sender = vault
    · by_cases hb : total ctx located + value.val < Verity.Core.UINT256_MODULUS
      · exact ⟨_, _, _, .admitted hl ha (.collected hb)⟩
      · exact ⟨_, _, _, .admitted hl ha (.overflow (by omega))⟩
    · exact ⟨_, _, _, .unauthorized hl ha⟩

theorem withdrawals_exists (external : External) (ctx : Context) (value : Word) (before : World) :
    ∃ outcome after trace, Withdrawals external ctx value before outcome after trace := by
  unfold Withdrawals
  rw [lookup_observations]
  generalize hl : locatorAddress external ctx 0x69d42148 before = result
  rcases result with ⟨outcome, located, trace⟩
  cases outcome with
  | error fault => exact ⟨_, _, _, .lookup_error hl⟩
  | ok vault =>
    by_cases ha : ctx.sender = vault
    · exact ⟨_, _, _, .admitted hl ha ⟨rfl, rfl⟩⟩
    · exact ⟨_, _, _, .unauthorized hl ha⟩

theorem rewards_corresponds (external : External) (ctx : Context) (value : Word)
    (before after : World) (outcome : Except Fault Unit) (trace : List Attempt) :
    Rewards external ctx value before outcome after trace ↔
      VaultCallbacks.receiveRewards external ctx value before = ⟨outcome, after, trace⟩ := by
  constructor
  · exact rewards_of_spec external ctx value before after outcome trace
  · intro h
    obtain ⟨o, w, t, hd⟩ := rewards_exists external ctx value before
    have he := rewards_of_spec external ctx value before w o t hd
    have hi : o = outcome ∧ w = after ∧ t = trace := by
      simpa only [Result.mk.injEq] using he.symm.trans h
    obtain ⟨rfl, rfl, rfl⟩ := hi
    exact hd

theorem withdrawals_corresponds (external : External) (ctx : Context) (value : Word)
    (before after : World) (outcome : Except Fault Unit) (trace : List Attempt) :
    Withdrawals external ctx value before outcome after trace ↔
      VaultCallbacks.receiveWithdrawals external ctx value before = ⟨outcome, after, trace⟩ := by
  constructor
  · exact withdrawals_of_spec external ctx value before after outcome trace
  · intro h
    obtain ⟨o, w, t, hd⟩ := withdrawals_exists external ctx value before
    have he := withdrawals_of_spec external ctx value before w o t hd
    have hi : o = outcome ∧ w = after ∧ t = trace := by
      simpa only [Result.mk.injEq] using he.symm.trans h
    obtain ⟨rfl, rfl, rfl⟩ := hi
    exact hd

theorem rewards_root_corresponds (external : External) (ctx : Context) (value : Word)
    (before after : World) (outcome : Except Fault Unit) (trace : List Attempt) :
    VaultSpec.Root (Rewards external ctx value) before outcome after trace ↔
      run (VaultCallbacks.receiveRewards external ctx value) before = ⟨outcome, after, trace⟩ :=
  VaultRules.root_corresponds _ _ (rewards_corresponds external ctx value) before after outcome trace

theorem withdrawals_root_corresponds (external : External) (ctx : Context) (value : Word)
    (before after : World) (outcome : Except Fault Unit) (trace : List Attempt) :
    VaultSpec.Root (Withdrawals external ctx value) before outcome after trace ↔
      run (VaultCallbacks.receiveWithdrawals external ctx value) before = ⟨outcome, after, trace⟩ :=
  VaultRules.root_corresponds _ _ (withdrawals_corresponds external ctx value) before after outcome trace

theorem reward_commit_total (ctx : Context) (value : Word) (before : World) (sum : Nat)
    (hb : sum < Verity.Core.UINT256_MODULUS) :
    total ctx (rewardCommit ctx value before sum) = sum := by
  simp only [total, rewardCommit, Verity.ContractState.readContractSlot_writeContractSlot_same]
  exact Nat.mod_eq_of_lt hb

theorem reward_commit_balances (ctx : Context) (value : Word) (before : World) (sum : Nat) :
    (rewardCommit ctx value before sum).balances = before.balances := rfl

theorem withdrawal_commit_core (ctx : Context) (value : Word) (before : World) :
    (withdrawalCommit ctx value before).core = before.core := rfl

theorem withdrawal_commit_balances (ctx : Context) (value : Word) (before : World) :
    (withdrawalCommit ctx value before).balances = before.balances := rfl

end LidoSRv3.Audit.Source.TrioReserve1.CallbackRules
