import LidoSRv3.Audit.Source.TrioReserve1.VaultSpec
import LidoSRv3.Audit.Source.TrioReserve1.Vaults
import LidoSRv3.Audit.Source.TrioReserve1.CallFlow

namespace LidoSRv3.Audit.Source.TrioReserve1.VaultRules
open Live

def Rewards (external : External) (ctx : Context) (lido : Address) (maximum : Word) (before : World) :=
  VaultSpec.Rewards (.reason "ONLY_LIDO_CAN_WITHDRAW") word (ctx.sender = lido)
    (before.balances ctx.self) maximum.val
    (fun amount => CallFlow.Describes external ctx lido 0x4ad509b2 (word amount)) before

def Withdrawals (external : External) (ctx : Context) (lido : Address) (amount : Word) (before : World) :=
  VaultSpec.Withdrawals (.bubbled (encode 4 0x25a81d75)) (.bubbled (encode 4 0x1f2a2005))
    (.bubbled (encode 4 0x41ba67b6 ++ encode 32 amount.val ++ encode 32 (before.balances ctx.self)))
    (ctx.sender = lido) (before.balances ctx.self) amount.val
    (CallFlow.Describes external ctx lido 0x78ffcfe2 amount) before

theorem call_observations (external : External) (ctx : Context) (lido : Address) (selector : Nat) (amount : Word) :
    CallFlow.Describes external ctx lido selector amount =
      (fun w outcome after trace => call external ctx lido selector amount w = ⟨outcome, after, trace⟩) := by
  funext w outcome after trace
  exact propext (CallFlow.corresponds external ctx lido selector amount w after outcome trace)

theorem rewards_of_spec (external : External) (ctx : Context) (lido : Address) (maximum : Word)
    (before after : World) (outcome : Except Fault Word) (trace : List Attempt)
    (h : Rewards external ctx lido maximum before outcome after trace) :
    Vaults.rewards external ctx lido maximum before = ⟨outcome, after, trace⟩ := by
  unfold Rewards at h
  simp only [call_observations] at h
  cases h <;> simp_all [VaultSpec.capped_iff, Vaults.rewards, bind, bindExec, require, pure, pureExec, fail]

theorem withdrawals_of_spec (external : External) (ctx : Context) (lido : Address) (amount : Word)
    (before after : World) (outcome : Except Fault Unit) (trace : List Attempt)
    (h : Withdrawals external ctx lido amount before outcome after trace) :
    Vaults.withdrawals external ctx lido amount before = ⟨outcome, after, trace⟩ := by
  unfold Withdrawals at h
  rw [call_observations] at h
  cases h <;> simp_all [Vaults.withdrawals, bind, bindExec, require, pure, pureExec, fail, Nat.not_le.mpr]

theorem rewards_exists (external : External) (ctx : Context) (lido : Address) (maximum : Word) (before : World) :
    ∃ outcome after trace, Rewards external ctx lido maximum before outcome after trace := by
  unfold Rewards
  simp only [call_observations]
  by_cases ha : ctx.sender = lido
  · let amount := min (before.balances ctx.self) maximum.val
    have hc : VaultSpec.Capped (before.balances ctx.self) maximum.val amount :=
      (VaultSpec.capped_iff _ _ _).mpr rfl
    by_cases hz : amount = 0
    · exact ⟨_, _, _, .zero ha (hz ▸ hc)⟩
    · have hn : 0 < amount := by omega
      generalize he : call external ctx lido 0x4ad509b2 (word amount) before = result
      rcases result with ⟨outcome, after, trace⟩
      cases outcome with
      | error fault => exact ⟨_, _, _, .failed ha hc hn he⟩
      | ok data => exact ⟨_, _, _, .paid ha hc hn he⟩
  · exact ⟨_, _, _, .denied ha⟩

theorem withdrawals_exists (external : External) (ctx : Context) (lido : Address) (amount : Word) (before : World) :
    ∃ outcome after trace, Withdrawals external ctx lido amount before outcome after trace := by
  unfold Withdrawals
  rw [call_observations]
  by_cases ha : ctx.sender = lido
  · by_cases hz : amount.val = 0
    · exact ⟨_, _, _, .zero ha hz⟩
    · by_cases hb : amount.val ≤ before.balances ctx.self
      · generalize he : call external ctx lido 0x78ffcfe2 amount before = result
        rcases result with ⟨outcome, after, trace⟩
        cases outcome with
        | error fault => exact ⟨_, _, _, .failed ha hz hb he⟩
        | ok data => exact ⟨_, _, _, .paid ha hz hb he⟩
      · exact ⟨_, _, _, .insufficient ha hz (by omega)⟩
  · exact ⟨_, _, _, .denied ha⟩

theorem rewards_corresponds (external : External) (ctx : Context) (lido : Address) (maximum : Word)
    (before after : World) (outcome : Except Fault Word) (trace : List Attempt) :
    Rewards external ctx lido maximum before outcome after trace ↔
      Vaults.rewards external ctx lido maximum before = ⟨outcome, after, trace⟩ := by
  constructor
  · exact rewards_of_spec external ctx lido maximum before after outcome trace
  · intro h
    obtain ⟨o, w, t, hd⟩ := rewards_exists external ctx lido maximum before
    have he := rewards_of_spec external ctx lido maximum before w o t hd
    have hi : o = outcome ∧ w = after ∧ t = trace := by
      simpa only [Result.mk.injEq] using he.symm.trans h
    obtain ⟨rfl, rfl, rfl⟩ := hi
    exact hd

theorem withdrawals_corresponds (external : External) (ctx : Context) (lido : Address) (amount : Word)
    (before after : World) (outcome : Except Fault Unit) (trace : List Attempt) :
    Withdrawals external ctx lido amount before outcome after trace ↔
      Vaults.withdrawals external ctx lido amount before = ⟨outcome, after, trace⟩ := by
  constructor
  · exact withdrawals_of_spec external ctx lido amount before after outcome trace
  · intro h
    obtain ⟨o, w, t, hd⟩ := withdrawals_exists external ctx lido amount before
    have he := withdrawals_of_spec external ctx lido amount before w o t hd
    have hi : o = outcome ∧ w = after ∧ t = trace := by
      simpa only [Result.mk.injEq] using he.symm.trans h
    obtain ⟨rfl, rfl, rfl⟩ := hi
    exact hd

theorem root_corresponds (program : Exec α)
    (stage : World → Except Fault α → World → List Attempt → Prop)
    (hs : ∀ before after outcome trace,
      stage before outcome after trace ↔ program before = ⟨outcome, after, trace⟩)
    (before after : World) (outcome : Except Fault α) (trace : List Attempt) :
    VaultSpec.Root stage before outcome after trace ↔ run program before = ⟨outcome, after, trace⟩ := by
  constructor
  · intro h
    cases h with
    | committed h => rw [run, (hs _ _ _ _).mp h]
    | reverted h => rw [run, (hs _ _ _ _).mp h]
  · intro h
    generalize he : program before = result at h
    rcases result with ⟨o, w, t⟩
    have hd := (hs before w o t).mpr he
    cases o with
    | ok value =>
      have hi : Except.ok value = outcome ∧ w = after ∧ t = trace := by
        simpa [run, he] using h
      obtain ⟨rfl, rfl, rfl⟩ := hi
      exact .committed hd
    | error fault =>
      have hi : Except.error fault = outcome ∧ before = after ∧ t = trace := by
        simpa [run, he] using h
      obtain ⟨rfl, rfl, rfl⟩ := hi
      exact .reverted hd

theorem rewards_root_corresponds (external : External) (ctx : Context) (lido : Address) (maximum : Word)
    (before after : World) (outcome : Except Fault Word) (trace : List Attempt) :
    VaultSpec.Root (Rewards external ctx lido maximum) before outcome after trace ↔
      run (Vaults.rewards external ctx lido maximum) before = ⟨outcome, after, trace⟩ :=
  root_corresponds _ _ (rewards_corresponds external ctx lido maximum) before after outcome trace

theorem withdrawals_root_corresponds (external : External) (ctx : Context) (lido : Address) (amount : Word)
    (before after : World) (outcome : Except Fault Unit) (trace : List Attempt) :
    VaultSpec.Root (Withdrawals external ctx lido amount) before outcome after trace ↔
      run (Vaults.withdrawals external ctx lido amount) before = ⟨outcome, after, trace⟩ :=
  root_corresponds _ _ (withdrawals_corresponds external ctx lido amount) before after outcome trace

end LidoSRv3.Audit.Source.TrioReserve1.VaultRules
