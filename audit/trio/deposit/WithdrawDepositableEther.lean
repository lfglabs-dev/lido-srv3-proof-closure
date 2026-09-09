import audit.trio.deposit.Deposit
import LidoSRv3.Audit.Source.TrioReserve1.WithdrawalCalls

/-! DEPOSIT-1 suffix for the Lido `withdrawDepositableEther` leg.

Pinned Solidity source: lidofinance/core@17005714f151e5502c559932319a3f2f74ac2436,
`contracts/0.4.24/Lido.sol:869-886`.  This file connects the amount derived by
the deposit executor to the independently delivered RESERVE-1 withdrawal
executor; it does not replace either executor with an assumed post-state. -/
namespace audit.trio.deposit.WithdrawDepositableEther

open LidoSRv3.Audit.Source.TrioAlloc1
open LidoSRv3.Audit.Source.TrioReserve1
open audit.trio.deposit

abbrev World := Live.World
abbrev External := Live.External
abbrev Context := Live.Context

/-- The exact amount passed by `StakingRouter.deposit` to
`LIDO.withdrawDepositableEther`. -/
def amount (values : DepositValues) : Word := word values.lidoPullWei

/-- The second Lido argument is the source-derived returned-key count. -/
def seedDepositsCount (values : DepositValues) : Word := word values.actualKeys

/-- `StakingRouter.deposit` returns before the Lido call when the module returns
no keys.  Otherwise both Lido arguments are derived from that module result. -/
def suffix (external : External) (ctx : Context) (values : DepositValues) : Live.Exec Unit :=
  if values.actualKeys = 0 then pure ()
  else Live.withdrawDepositableEther external ctx (amount values) (seedDepositsCount values)

/-- Source-shaped observation of the conditional StakingRouter suffix. -/
def DescribesSuffix (external : External) (ctx : Context) (values : DepositValues)
    (before after : World) (outcome : Except Live.Fault Unit)
    (trace : List Live.Attempt) : Prop :=
  if values.actualKeys = 0 then
    outcome = .ok () ∧ after = before ∧ trace = []
  else
    (amount values).val = values.lidoPullWei ∧
      (seedDepositsCount values).val = values.actualKeys ∧
      WithdrawalCalls.Describes external ctx (amount values) (seedDepositsCount values)
        before outcome after trace

/-- Successful deposit-value execution fixes the withdrawal amount and proves
that it cannot exceed the selected allocation. -/
theorem amount_from_deposit_execution
    (layout : Layout) (storage : Storage) (oracle : StaticOracle) (config : Config)
    (requested : Word) (before after : Transcript) (moduleId : Word)
    (limits : DepositLimits) (obtainDepositData : ObtainDepositData)
    (depositSize : Nat) (withdraw : audit.trio.deposit.WithdrawDepositableEther)
    (execution : DepositExecution)
    (executed : depositValuesABI layout storage oracle config requested before moduleId
      limits obtainDepositData depositSize withdraw = (.ok execution, after))
    (hwidth : execution.values.lidoPullWei < Verity.Core.UINT256_MODULUS) :
    (amount execution.values).val = execution.values.lidoPullWei ∧
      (amount execution.values).val ≤ execution.values.selectedAllocationWei := by
  have composed := abi_success_composes_deposit_values layout storage oracle config
    requested before after moduleId limits obtainDepositData depositSize withdraw execution executed
  have hval : (amount execution.values).val = execution.values.lidoPullWei :=
    Nat.mod_eq_of_lt hwidth
  constructor
  · exact hval
  · rw [hval]
    exact composed.1

/-- Successful deposit-value execution composes with the exact conditional
suffix.  In the nonzero arm this supplies the complete source-ordered Lido
relation with both arguments and their widths derived from the ABI execution. -/
theorem deposit_execution_composes_suffix (values : DepositValues)
    (external : External) (ctx : Context) (world : World)
    (amountWidth : values.lidoPullWei < Verity.Core.UINT256_MODULUS)
    (keysWidth : values.actualKeys < Verity.Core.UINT256_MODULUS) :
    let result := Live.run (suffix external ctx values) world
    DescribesSuffix external ctx values world result.world result.outcome result.attempts := by
  by_cases hzero : values.actualKeys = 0
  · simp only [suffix, DescribesSuffix, hzero, if_pos]
    refine ⟨rfl, rfl, rfl⟩
  · simp only [suffix, DescribesSuffix, hzero, if_false]
    refine ⟨Nat.mod_eq_of_lt amountWidth, Nat.mod_eq_of_lt keysWidth, ?_⟩
    exact WithdrawalCalls.complete external ctx (amount values) (seedDepositsCount values) world

/-- A described failed suffix restores the complete pre-call world. -/
theorem failure_rolls_back (external : External) (ctx : Context)
    (values : DepositValues) (before after : World)
    (fault : Live.Fault) (trace : List Live.Attempt)
    (h : DescribesSuffix external ctx values before after (.error fault) trace) : after = before := by
  by_cases hzero : values.actualKeys = 0
  · simp [DescribesSuffix, hzero] at h
  · have withdrawal := (by simpa [DescribesSuffix, hzero] using h :
        (amount values).val = values.lidoPullWei ∧
          (seedDepositsCount values).val = values.actualKeys ∧
          WithdrawalCalls.Describes external ctx (amount values) (seedDepositsCount values)
            before (.error fault) after trace)
    exact WithdrawalCalls.failure_restores external ctx (amount values)
      (seedDepositsCount values) before after fault trace withdrawal.2.2

#print axioms amount_from_deposit_execution
#print axioms deposit_execution_composes_suffix
#print axioms failure_rolls_back

end audit.trio.deposit.WithdrawDepositableEther
