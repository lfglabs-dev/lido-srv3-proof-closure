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

/-- The word bounds needed by the suffix are consequences of the successful
ABI execution, not caller-supplied hypotheses. -/
theorem deposit_execution_word_bounds
    (layout : Layout) (storage : Storage) (oracle : StaticOracle) (config : Config)
    (requested : Word) (before after : Transcript) (moduleId : Word)
    (limits : DepositLimits) (obtainDepositData : ObtainDepositData)
    (depositSize : Nat) (values : DepositValues)
    (executed : depositValuesABI layout storage oracle config requested before moduleId
      limits obtainDepositData depositSize = (.ok values, after)) :
    values.lidoPullWei < Verity.Core.UINT256_MODULUS ∧
      values.actualKeys < Verity.Core.UINT256_MODULUS := by
  have composed := abi_success_composes_deposit_values layout storage oracle config
    requested before after moduleId limits obtainDepositData depositSize values executed
  unfold depositValuesABI at executed
  split at executed <;> try simp_all
  next allocation allocAfter allocEq =>
    split at executed <;> try simp_all
    next moduleIndex indexEq =>
      split at executed <;> try simp_all
      next selected selectedEq =>
        unfold maxDepositsCount at executed
        split at executed <;> try simp_all
        next nonzero =>
          split at executed <;> try simp_all
          next target targetEq =>
            split at executed <;> try simp_all
            next nonzeroTarget =>
              split at executed <;> try simp_all
              next moduleData moduleEq =>
                split at executed <;> try simp_all
                next aligned =>
                  rcases executed with ⟨rfl, rfl⟩
                  constructor
                  · exact Nat.lt_of_le_of_lt composed.1 selected.isLt
                  · dsimp [composeValues]
                    have targetBound : target ≤ selected.val / config.maxEBType1.val := by
                      split at nonzero
                      · simp_all
                      · have targetValue : min limits.maxDepositsPerBlock
                            (selected.val / config.maxEBType1.val) = target :=
                          Except.ok.inj nonzero
                        rw [← targetValue]
                        exact Nat.min_le_right _ _
                    exact Nat.lt_of_le_of_lt
                      (Nat.le_trans aligned
                        (Nat.le_trans targetBound (Nat.div_le_self _ _)))
                      selected.isLt

/-- Successful deposit-value execution fixes the withdrawal amount and proves
that it cannot exceed the selected allocation. -/
theorem amount_from_deposit_execution
    (layout : Layout) (storage : Storage) (oracle : StaticOracle) (config : Config)
    (requested : Word) (before after : Transcript) (moduleId : Word)
    (limits : DepositLimits) (obtainDepositData : ObtainDepositData)
    (depositSize : Nat) (values : DepositValues)
    (executed : depositValuesABI layout storage oracle config requested before moduleId
      limits obtainDepositData depositSize = (.ok values, after)) :
    (amount values).val = values.lidoPullWei ∧
      (amount values).val ≤ values.selectedAllocationWei := by
  have composed := abi_success_composes_deposit_values layout storage oracle config
    requested before after moduleId limits obtainDepositData depositSize values executed
  have widths := deposit_execution_word_bounds layout storage oracle config requested before
    after moduleId limits obtainDepositData depositSize values executed
  have hval : (amount values).val = values.lidoPullWei := by
    exact Nat.mod_eq_of_lt widths.1
  constructor
  · exact hval
  · rw [hval]
    exact composed.1

/-- Successful deposit-value execution composes with the exact conditional
suffix.  In the nonzero arm this supplies the complete source-ordered Lido
relation with both arguments and their widths derived from the ABI execution. -/
theorem deposit_execution_composes_suffix
    (layout : Layout) (storage : Storage) (oracle : StaticOracle) (config : Config)
    (requested : Word) (before after : Transcript) (moduleId : Word)
    (limits : DepositLimits) (obtainDepositData : ObtainDepositData)
    (depositSize : Nat) (values : DepositValues)
    (executed : depositValuesABI layout storage oracle config requested before moduleId
      limits obtainDepositData depositSize = (.ok values, after))
    (external : External) (ctx : Context) (world : World) :
    let result := Live.run (suffix external ctx values) world
    DescribesSuffix external ctx values world result.world result.outcome result.attempts := by
  have composed := abi_success_composes_deposit_values layout storage oracle config
    requested before after moduleId limits obtainDepositData depositSize values executed
  have widths := deposit_execution_word_bounds layout storage oracle config requested before
    after moduleId limits obtainDepositData depositSize values executed
  by_cases hzero : values.actualKeys = 0
  · simp only [suffix, DescribesSuffix, hzero, if_pos]
    refine ⟨rfl, rfl, rfl⟩
  · simp only [suffix, DescribesSuffix, hzero, if_false]
    refine ⟨Nat.mod_eq_of_lt widths.1, Nat.mod_eq_of_lt widths.2, ?_⟩
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
