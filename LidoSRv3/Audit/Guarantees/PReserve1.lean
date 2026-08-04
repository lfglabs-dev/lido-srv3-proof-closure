import LidoSRv3.Audit.Source.ReserveCorrespondence
import LidoSRv3.Audit.Guarantees.Registry

namespace LidoSRv3.Audit.Guarantees.PReserve1

open Verity
open LidoSRv3.Audit.SolidityReserve

def guarantee : Guarantee := ⟨.pReserve1, [.model, .source, .abstractTx]⟩

/-- The source-shaped spend cannot write the withdrawal-demand reserve. -/
theorem source_spend_preserves_withdrawal_reserve
    (before after : ReserveState) (amount : Word)
    (h : spendDepositableEther before amount = .committed after) :
    after.unfinalizedStETH = before.unfinalizedStETH :=
  committed_preserves_withdrawal_reserve before after amount h

/--
Faithful VERITY_TX closure for P-RESERVE-1. This theorem starts with the actual
`Verity.Contract.run` result of the source-shaped reserve spend and proves that
its committed/reverted observable transition is the abstract reserve
transaction. In particular, every `safeAdd`/`safeSub` failure and
`NOT_ENOUGH_ETHER` branch observes Verity's pre-call rollback state.

This is not an EVM theorem: storage-slot numbers are a model-local projection,
and no Solidity compiler, Yul, runtime bytecode, proxy layout, deployed code,
or external-call semantics is claimed.
-/
theorem verity_tx_simulates_reserve_spec (inputs : WithdrawInputs)
    (state : ContractState) (amount : Word) :
    observeVerity state ((verityWithdraw inputs amount).run state) =
      specTx inputs (decode state) amount ∧
    ∀ reason, (verityWithdraw inputs amount).run state = .revert reason state →
      ((verityWithdraw inputs amount).run state).snd = state :=
  ⟨verity_execution_simulates_spec state amount inputs,
    fun reason h => verity_revert_rolls_back inputs state amount reason h⟩

/-- On a committing executable Verity transition, the prohibited reserve state
is observationally unchanged. -/
theorem verity_tx_preserves_withdrawal_reserve
    (inputs : WithdrawInputs) (state after : ContractState) (amount : Word)
    (h : (verityWithdraw inputs amount).run state = .success () after) :
    (decode after).unfinalizedStETH = (decode state).unfinalizedStETH :=
  verity_commit_preserves_withdrawal_reserve inputs state after amount h

end LidoSRv3.Audit.Guarantees.PReserve1
