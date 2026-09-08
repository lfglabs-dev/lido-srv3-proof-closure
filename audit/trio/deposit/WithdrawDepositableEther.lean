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

/-- Successful deposit-value execution fixes the withdrawal amount and proves
that it cannot exceed the selected allocation. -/
theorem amount_from_deposit_execution
    (layout : Layout) (storage : Storage) (oracle : StaticOracle) (config : Config)
    (requested : Word) (before after : Transcript) (moduleId : Word)
    (limits : DepositLimits) (obtainDepositData : ObtainDepositData)
    (depositSize : Nat) (values : DepositValues)
    (executed : depositValuesABI layout storage oracle config requested before moduleId
      limits obtainDepositData depositSize = (.ok values, after))
    (hwidth : values.lidoPullWei < Verity.Core.UINT256_MODULUS) :
    (amount values).val = values.lidoPullWei ∧
      (amount values).val ≤ values.selectedAllocationWei := by
  have composed := abi_success_composes_deposit_values layout storage oracle config
    requested before after moduleId limits obtainDepositData depositSize values executed
  have hval : (amount values).val = values.lidoPullWei := by
    exact Nat.mod_eq_of_lt hwidth
  constructor
  · exact hval
  · rw [hval]
    exact composed.1

/-- The suffix uses the complete source-ordered withdrawal relation, including
pause/auth/zero guards, reserve spending, seed accounting, the value-bearing
router call, and rollback on every failure. -/
theorem executes_withdrawal (external : External) (ctx : Context)
    (values : DepositValues) (seeds : Word) (before : World) :
    let result := Live.run
      (Live.withdrawDepositableEther external ctx (amount values) seeds) before
    WithdrawalCalls.Describes external ctx (amount values) seeds before
      result.outcome result.world result.attempts := by
  exact WithdrawalCalls.complete external ctx (amount values) seeds before

/-- A described failed suffix restores the complete pre-call world. -/
theorem failure_rolls_back (external : External) (ctx : Context)
    (values : DepositValues) (seeds : Word) (before after : World)
    (fault : Live.Fault) (trace : List Live.Attempt)
    (h : WithdrawalCalls.Describes external ctx (amount values) seeds before
      (.error fault) after trace) : after = before :=
  WithdrawalCalls.failure_restores external ctx (amount values) seeds before after fault trace h

#print axioms amount_from_deposit_execution
#print axioms executes_withdrawal
#print axioms failure_rolls_back

end audit.trio.deposit.WithdrawDepositableEther
