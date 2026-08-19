import LidoSRv3.Audit.Source.ReserveCorrespondence
import LidoSRv3.Audit.Guarantees.Registry

namespace LidoSRv3.Audit.Guarantees.PReserve1

open Verity
open LidoSRv3.Audit.SolidityReserve

def guarantee : Guarantee := ⟨.pReserve1, [.model, .source, .verityTx]⟩

/-- Any committed `_spendDepositableEther` satisfies
`withdrawalPartitionSpendInvariant`: the amount came from
`depositsReserve + unreserved`, `buffered` is the checked subtraction,
`storedDepositsReserve` follows the pinned `> amount ? − : 0` update, and
`unfinalizedStETH` is unchanged. Lido's nonzero-amount and
`buffered ≥ storedDepositsReserve` guards are not required for this
formula — they are source call-site facts, not used here. -/
theorem source_spend_preserves_withdrawal_reserve
    (before after : ReserveState) (amount : Word)
    (h : spendDepositableEther before amount = .committed after) :
    withdrawalPartitionSpendInvariant before after amount :=
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
    observeVerity state ((ReserveContract.withdrawWithGuards inputs amount).run state) =
      specTx inputs (decode state) amount ∧
    ∀ reason rollback,
      (ReserveContract.withdrawWithGuards inputs amount).run state = .revert reason rollback →
      rollback = state :=
  ⟨verity_execution_simulates_spec state amount inputs,
    fun reason rollback h =>
      verity_revert_rolls_back inputs state amount reason rollback h⟩

/-- On a committing executable Verity transition, the prohibited reserve state
is observationally unchanged. -/
theorem verity_tx_preserves_withdrawal_reserve
    (inputs : WithdrawInputs) (state after : ContractState) (amount : Word)
    (h : (ReserveContract.withdrawWithGuards inputs amount).run state = .success () after) :
    withdrawalPartitionSpendInvariant (decode state) (decode after) amount :=
  verity_commit_preserves_withdrawal_reserve inputs state after amount h

end LidoSRv3.Audit.Guarantees.PReserve1
