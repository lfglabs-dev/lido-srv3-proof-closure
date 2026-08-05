import LidoSRv3.Audit.Verity.DepositRollback

namespace LidoSRv3.Audit.Verity.Tests.DepositRollback

open LidoSRv3.Audit
open LidoSRv3.Audit.SolidityDeposit
open LidoSRv3.Audit.Verity.DepositRollback

def cfg : SourceDepositConfig :=
  { maxEBType1 := depositSize32ETH
    depositSize := depositSize32ETH
    pubkeyLength := 48
    publicKeyLength := 48
    signatureLength := 96 }

def nominal : SourceDepositInput :=
  { callerHasDepositRole := true
    moduleActive := true
    maxDepositsPerBlock := 2
    moduleDepositableEth := 2 * depositSize32ETH
    publicKeysBatchLength := 96
    signaturesBatchLength := 192
    routerBalanceBefore := 0
    lidoCanDeposit := true
    lidoDepositableEther := 2 * depositSize32ETH }

theorem test_deposit_commit_conserves_wei :
    (run cfg nominal).pulled = 2 * depositSize32ETH ∧
      (run cfg nominal).pushed = 2 * depositSize32ETH ∧
      (run cfg nominal).pulled = (run cfg nominal).pushed := by
  native_decide

theorem test_deposit_revert_rolls_back_state :
    let unauthorized := { nominal with callerHasDepositRole := false }
    let tx := transactionObservation (depositProgram cfg unauthorized 17) 999 []
      { calls := [], ethMoves := [{ sender := 1, recipient := 2, amount := ⟨3⟩ }], logs := [] }
    tx.committedState = 17 ∧ tx.committedTrace.ethMoves = [] := by
  native_decide

theorem test_deposit_assert_failure_rolls_back :
    let badCfg := { cfg with maxEBType1 := depositSize32ETH + 1 }
    let badInp := { nominal with
      moduleDepositableEth := 2 * (depositSize32ETH + 1)
      lidoDepositableEther := 2 * (depositSize32ETH + 1) }
    let tx := transactionObservation (depositProgram badCfg badInp 41) 100 []
      { calls := [], ethMoves := [{ sender := 1, recipient := 2, amount := ⟨1⟩ }], logs := [] }
    (run badCfg badInp = .revertAssertBalanceUnchanged) ∧
      tx.committedState = 41 ∧ tx.committedTrace.ethMoves = [] := by
  native_decide

theorem test_deposit_max_effective_balance_misconfig_reverts :
    let badCfg := { cfg with maxEBType1 := depositSize32ETH + 1 }
    ¬ ConservingConfig badCfg ∧ (run badCfg nominal).reverts = true ∧
      (run badCfg nominal).pulled = 0 ∧ (run badCfg nominal).pushed = 0 := by
  native_decide

/-- Negative mutant: changing the per-iteration amount is detected. -/
theorem test_deposit_wrong_conservation_claim_fails :
    (run cfg nominal).pushed ≠ 2 * (depositSize32ETH + 1) := by
  native_decide

end LidoSRv3.Audit.Verity.Tests.DepositRollback
