import LidoSRv3.Audit.Source.TrioReserve1.WithdrawalSpec
import LidoSRv3.Audit.Source.TrioReserve1.WithdrawalComposition

namespace LidoSRv3.Audit.Source.TrioReserve1.WithdrawalParent
open Live

/-- Source stage observations instantiate the independent parent relation.
This adapter leaves stage-internal and deployed primitive correspondence explicit. -/
def Describes (external : External) (ctx : Context) (amount seeds : Word) (before : World) :
    Except Fault Unit → World → List Attempt → Prop :=
  WithdrawalSpec.Executes (.reason "CAN_NOT_DEPOSIT") (.reason "APP_AUTH_FAILED") (.reason "ZERO_AMOUNT")
    ctx.sender (amount.val ≠ 0)
    (fun w outcome after trace => canDeposit external ctx w = ⟨outcome, after, trace⟩)
    (fun w outcome after trace => stakingRouter external ctx w = ⟨outcome, after, trace⟩)
    (fun w outcome after trace => spendDepositableEther external ctx amount w = ⟨outcome, after, trace⟩)
    (fun target w outcome after trace => WithdrawalTail.finish external ctx target amount seeds w = ⟨outcome, after, trace⟩)
    before

theorem of_spec (external : External) (ctx : Context) (amount seeds : Word) (before after : World)
    (outcome : Except Fault Unit) (trace : List Attempt)
    (h : Describes external ctx amount seeds before outcome after trace) :
    run (withdrawDepositableEther external ctx amount seeds) before = ⟨outcome, after, trace⟩ := by
  cases h <;>
    simp_all [run, WithdrawalTail.source_decomposition, bind, bindExec, require, pure, pureExec, fail, List.append_assoc]

theorem exists_spec (external : External) (ctx : Context) (amount seeds : Word) (before : World) :
    ∃ outcome after trace, Describes external ctx amount seeds before outcome after trace := by
  generalize hs : canDeposit external ctx before = statusResult
  rcases statusResult with ⟨statusOutcome, statusWorld, statusTrace⟩
  cases statusOutcome with
  | error fault => exact ⟨_, _, _, .status_error hs⟩
  | ok allowed =>
    cases allowed with
    | false => exact ⟨_, _, _, .status_denied hs⟩
    | true =>
      generalize hr : stakingRouter external ctx statusWorld = routerResult
      rcases routerResult with ⟨routerOutcome, routerWorld, routerTrace⟩
      cases routerOutcome with
      | error fault => exact ⟨_, _, _, .router_error hs hr⟩
      | ok target =>
        by_cases ha : ctx.sender = target
        · by_cases hn : amount.val ≠ 0
          · generalize hp : spendDepositableEther external ctx amount routerWorld = spendResult
            rcases spendResult with ⟨spendOutcome, spentWorld, spendTrace⟩
            cases spendOutcome with
            | error fault => exact ⟨_, _, _, .spend_error hs hr ha hn hp⟩
            | ok value =>
              cases value
              generalize ht : WithdrawalTail.finish external ctx target amount seeds spentWorld = tailResult
              rcases tailResult with ⟨tailOutcome, finalWorld, tailTrace⟩
              cases tailOutcome with
              | error fault => exact ⟨_, _, _, .tail_error hs hr ha hn hp ht⟩
              | ok value => cases value; exact ⟨_, _, _, .finished hs hr ha hn hp ht⟩
          · exact ⟨_, _, _, .zero hs hr ha hn⟩
        · exact ⟨_, _, _, .unauthorized hs hr ha⟩

theorem to_spec (external : External) (ctx : Context) (amount seeds : Word) (before after : World)
    (outcome : Except Fault Unit) (trace : List Attempt)
    (h : run (withdrawDepositableEther external ctx amount seeds) before = ⟨outcome, after, trace⟩) :
    Describes external ctx amount seeds before outcome after trace := by
  obtain ⟨otherOutcome, otherWorld, otherTrace, hd⟩ := exists_spec external ctx amount seeds before
  have he := of_spec external ctx amount seeds before otherWorld otherOutcome otherTrace hd
  have hi : otherOutcome = outcome ∧ otherWorld = after ∧ otherTrace = trace := by
    simpa only [Result.mk.injEq] using he.symm.trans h
  obtain ⟨rfl, rfl, rfl⟩ := hi
  exact hd

/-- Bidirectional exact withdrawal-parent correspondence. All status, lookup,
authorization, zero-amount, spending and tail outcomes are covered, without
requiring observations for stages skipped by an earlier guard or fault. -/
theorem corresponds (external : External) (ctx : Context) (amount seeds : Word) (before after : World)
    (outcome : Except Fault Unit) (trace : List Attempt) :
    Describes external ctx amount seeds before outcome after trace ↔
      run (withdrawDepositableEther external ctx amount seeds) before = ⟨outcome, after, trace⟩ :=
  ⟨of_spec external ctx amount seeds before after outcome trace,
   to_spec external ctx amount seeds before after outcome trace⟩

/-- Every source execution satisfies the independent parent rules, instantiated
with actual stage observations. Stage-internal source/specification and deployed
primitive binding remain separate obligations. -/
theorem complete (external : External) (ctx : Context) (amount seeds : Word) (before : World) :
    let result := run (withdrawDepositableEther external ctx amount seeds) before
    Describes external ctx amount seeds before result.outcome result.world result.attempts := by
  apply to_spec
  rfl

end LidoSRv3.Audit.Source.TrioReserve1.WithdrawalParent
