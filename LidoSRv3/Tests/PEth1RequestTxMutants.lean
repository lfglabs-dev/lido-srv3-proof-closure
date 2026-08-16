import LidoSRv3.Audit.Verity.PEth1RequestTx

/-!
Discriminating mutants for the P-ETH-1b bus/request `Contract.run` ledger.
-/

namespace LidoSRv3.Tests.PEth1RequestTxMutants

open _root_.Verity
open LidoSRv3.Audit.Verity.PEth1RequestTx

private def before : Ledger := ⟨3, 1, 20, 2, 4⟩

/-- Forward mutant: bus value is credited to the vault instead of the gateway. -/
def forwardToVaultMutant (before : Ledger) (msgValue : Nat) : Ledger :=
  { before with vault := before.vault + msgValue }

#guard decide
  (observe ((busForward (word 5) true).run
      (stateFor ⟨3, 1, 20, 0, 0⟩ defaultState)) ≠
    ⟨.committed, forwardToVaultMutant ⟨3, 1, 20, 0, 0⟩ 5⟩)

/-- Lateral-target mutant: EIP-7002 fee is credited to the consolidation sink. -/
def withdrawalFeeToConsolidationMutant (before : Ledger) (fee : Nat) : Ledger :=
  { before with
    vault := before.vault - fee
    consolidationRequest := before.consolidationRequest + fee }

#guard decide
  (observe ((sendWithdrawalFee (word 5) (word 5) true).run
      (stateFor before defaultState)) ≠
    ⟨.committed, withdrawalFeeToConsolidationMutant before 5⟩)

/-- Prefix-keep mutant: first EIP-7251 fee remains after the second call fails. -/
def keepFirstConsolidationFee (before : Ledger) (fee : Nat) : Ledger :=
  { before with
    vault := before.vault - fee
    consolidationRequest := before.consolidationRequest + fee }

theorem keep_first_consolidation_fee_rejected :
    observe ((sendTwoConsolidationFees (word 5) false).run
      (stateFor before defaultState)) ≠
      ⟨.reverted, keepFirstConsolidationFee before 5⟩ := by decide

#guard decide
  (observe ((sendTwoConsolidationFees (word 5) false).run
      (stateFor before defaultState)) ≠
    ⟨.reverted, keepFirstConsolidationFee before 5⟩)

#guard decide
  (observe ((sendWithdrawalFee (word 5) (word 4) true).run
      (stateFor before defaultState)) ≠
    ⟨.committed, { before with vault := 15, withdrawalRequest := 7 }⟩)

#check bus_failure_restores_snapshot
#check consolidation_prefix_failure_restores_snapshot

end LidoSRv3.Tests.PEth1RequestTxMutants
