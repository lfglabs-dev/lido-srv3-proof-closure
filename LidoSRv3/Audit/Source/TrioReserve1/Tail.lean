import LidoSRv3.Audit.Source.TrioReserve1.TailSpec
import LidoSRv3.Audit.Source.TrioReserve1.Lookup

namespace LidoSRv3.Audit.Source.TrioReserve1.Tail
open Live

/-- Seed arithmetic is independent; its physical write projection retains the
uint128 packing and full checked-count event from the source layout. -/
def Seeds (ctx : Context) (seeds : Word) (before : World) : Except Fault Unit → World → Prop :=
  TailSpec.Seeds (.reason "MATH_ADD_OVERFLOW") Verity.Core.UINT256_MODULUS seeds.val
    (fun w => (w.core.readContractSlot ctx.self.val seedSlot).val % width)
    (WithdrawalTail.seedWorld ctx seeds) before

theorem seed_source (ctx : Context) (seeds : Word) (before after : World) (outcome : Except Fault Unit)
    (h : Seeds ctx seeds before outcome after) :
    WithdrawalTail.updateSeeds ctx seeds before = ⟨outcome, after, []⟩ := by
  cases h with
  | zero hz => exact WithdrawalTail.seeds_zero ctx seeds before hz
  | updated hn hb => exact WithdrawalTail.seeds_success ctx seeds before hn hb
  | overflow hn hb => exact WithdrawalTail.seeds_overflow ctx seeds before hn hb

theorem seed_exists (ctx : Context) (seeds : Word) (before : World) :
    ∃ outcome after, Seeds ctx seeds before outcome after := by
  by_cases hz : seeds.val = 0
  · exact ⟨_, _, .zero hz⟩
  · by_cases hb : (before.core.readContractSlot ctx.self.val seedSlot).val % width + seeds.val < Verity.Core.UINT256_MODULUS
    · exact ⟨_, _, .updated (by omega) hb⟩
    · exact ⟨_, _, .overflow (by omega) (by omega)⟩

def Describes (external : External) (ctx : Context) (router : Address) (amount seeds : Word) (before : World) :
    Except Fault Unit → World → List Attempt → Prop :=
  TailSpec.Finishes (Seeds ctx seeds)
    (fun w outcome after trace => call external ctx router 0x13ae8460 amount w = ⟨outcome, after, trace⟩) before

theorem of_spec (external : External) (ctx : Context) (router : Address) (amount seeds : Word)
    (before after : World) (outcome : Except Fault Unit) (trace : List Attempt)
    (h : Describes external ctx router amount seeds before outcome after trace) :
    WithdrawalTail.finish external ctx router amount seeds before = ⟨outcome, after, trace⟩ := by
  cases h with
  | seed_error hs =>
    simp [WithdrawalTail.finish, bind, bindExec, seed_source ctx seeds _ _ _ hs]
  | receiver_error hs hc =>
    simp [WithdrawalTail.finish, bind, bindExec, seed_source ctx seeds _ _ _ hs, hc]
  | success hs hc =>
    simp [WithdrawalTail.finish, bind, bindExec, seed_source ctx seeds _ _ _ hs, hc, pure, pureExec]

theorem exists_spec (external : External) (ctx : Context) (router : Address) (amount seeds : Word) (before : World) :
    ∃ outcome after trace, Describes external ctx router amount seeds before outcome after trace := by
  obtain ⟨seedOutcome, seeded, hs⟩ := seed_exists ctx seeds before
  cases seedOutcome with
  | error fault => exact ⟨_, _, _, .seed_error hs⟩
  | ok value =>
    cases value
    generalize hc : call external ctx router 0x13ae8460 amount seeded = callResult
    rcases callResult with ⟨callOutcome, after, trace⟩
    cases callOutcome with
    | error fault => exact ⟨_, _, _, .receiver_error hs hc⟩
    | ok data => exact ⟨_, _, _, .success hs hc⟩

theorem to_spec (external : External) (ctx : Context) (router : Address) (amount seeds : Word)
    (before after : World) (outcome : Except Fault Unit) (trace : List Attempt)
    (h : WithdrawalTail.finish external ctx router amount seeds before = ⟨outcome, after, trace⟩) :
    Describes external ctx router amount seeds before outcome after trace := by
  obtain ⟨otherOutcome, otherWorld, otherTrace, hd⟩ := exists_spec external ctx router amount seeds before
  have he := of_spec external ctx router amount seeds before otherWorld otherOutcome otherTrace hd
  have hi : otherOutcome = outcome ∧ otherWorld = after ∧ otherTrace = trace := by
    simpa only [Result.mk.injEq] using he.symm.trans h
  obtain ⟨rfl, rfl, rfl⟩ := hi
  exact hd

theorem corresponds (external : External) (ctx : Context) (router : Address) (amount seeds : Word)
    (before after : World) (outcome : Except Fault Unit) (trace : List Attempt) :
    Describes external ctx router amount seeds before outcome after trace ↔
      WithdrawalTail.finish external ctx router amount seeds before = ⟨outcome, after, trace⟩ :=
  ⟨of_spec external ctx router amount seeds before after outcome trace,
   to_spec external ctx router amount seeds before after outcome trace⟩

/-- Withdrawal with complete status/lookup and seed/receiver-tail rules. Spending
and CALL/deployed primitive interpretation are the remaining direct boundaries. -/
def Withdrawal (external : External) (ctx : Context) (amount seeds : Word) (before : World) :
    Except Fault Unit → World → List Attempt → Prop :=
  WithdrawalSpec.Executes (.reason "CAN_NOT_DEPOSIT") (.reason "APP_AUTH_FAILED") (.reason "ZERO_AMOUNT")
    ctx.sender (amount.val ≠ 0)
    (fun w outcome after trace => Lookup.Status external ctx w outcome after trace)
    (fun w outcome after trace => Lookup.Describes external ctx 0xef6c064c w outcome after trace)
    (fun w outcome after trace => spendDepositableEther external ctx amount w = ⟨outcome, after, trace⟩)
    (fun router w outcome after trace => Describes external ctx router amount seeds w outcome after trace)
    before

theorem withdrawal_corresponds (external : External) (ctx : Context) (amount seeds : Word)
    (before after : World) (outcome : Except Fault Unit) (trace : List Attempt) :
    Withdrawal external ctx amount seeds before outcome after trace ↔
      run (withdrawDepositableEther external ctx amount seeds) before = ⟨outcome, after, trace⟩ := by
  have he : (fun router w outcome after trace => Describes external ctx router amount seeds w outcome after trace) =
      (fun router w outcome after trace => WithdrawalTail.finish external ctx router amount seeds w = ⟨outcome, after, trace⟩) := by
    funext router w outcome after trace
    exact propext (corresponds external ctx router amount seeds w after outcome trace)
  unfold Withdrawal
  rw [he]
  exact Lookup.withdrawal_corresponds external ctx amount seeds before after outcome trace

end LidoSRv3.Audit.Source.TrioReserve1.Tail
