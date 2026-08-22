import LidoSRv3.Audit.Verity.PConsolidationEth1RefundTx

/-!
Discriminating mutants for the retired P-CONSOLIDATION-ETH-1a refund/withdraw `Contract.run` ledger
(unregistered auxiliary; not a P-CONSOLIDATION-ETH-1 child claim).

Each `#guard` executes the shipped `Contract.run` entrypoint and checks that a
disagreeing mutant ledger is not the observed result.
-/

namespace LidoSRv3.Tests.PConsolidationEth1RefundTxMutants

open _root_.Verity
open LidoSRv3.Audit.Verity.PConsolidationEth1RefundTx

private def before : Ledger := ⟨10, 1, 4, 7⟩

/-- Double-refund mutant: remainder is credited twice. -/
def doubleRefundMutant (before : Ledger) (msgValue fee : Nat) : Ledger :=
  let refund := msgValue - fee
  { before with
    vault := before.vault + fee
    refundDest := before.refundDest + refund + refund }

theorem double_refund_rejected :
    observe ((gatewayRefund (word 5) (word 3) true true).run
      (stateFor before defaultState)) ≠
      ⟨.committed, doubleRefundMutant before 5 3⟩ := by decide

#guard decide
  (observe ((gatewayRefund (word 5) (word 3) true true).run
      (stateFor before defaultState)) ≠
    ⟨.committed, doubleRefundMutant before 5 3⟩)

/-- Wrong-party mutant: remainder is credited to Lido instead of the refund dest. -/
def refundToLidoMutant (before : Ledger) (msgValue fee : Nat) : Ledger :=
  { before with
    vault := before.vault + fee
    lido := before.lido + (msgValue - fee) }

/-- Refund-misroute kill-line: crediting the remainder to Lido instead of the
resolved refund destination is distinguishable at the registered executable
observation boundary. -/
theorem refund_misroute_kill_line :
    observe ((gatewayRefund (word 5) (word 3) true true).run
        (stateFor before defaultState)) ≠
      ⟨.committed, refundToLidoMutant before 5 3⟩ := by
  decide

/-- Leak-on-failure mutant: keeps the vault fee when the refund call fails. -/
def leakVaultOnRefundFailure (before : Ledger) (fee : Nat) : Ledger :=
  { before with vault := before.vault + fee }

theorem leak_on_refund_failure_rejected :
    observe ((gatewayRefund (word 5) (word 3) true false).run
      (stateFor before defaultState)) ≠
      ⟨.reverted, leakVaultOnRefundFailure before 3⟩ := by decide

#guard decide
  (observe ((gatewayRefund (word 5) (word 3) true false).run
      (stateFor before defaultState)) ≠
    ⟨.reverted, leakVaultOnRefundFailure before 3⟩)

#guard decide
  (observe ((withdrawToLido (word 5) false).run
      (stateFor ⟨10, 8, 4, 7⟩ defaultState)) ≠
    ⟨.committed, ⟨10, 3, 4, 12⟩⟩)

#check refund_failure_restores_snapshot
#check withdraw_failure_restores_snapshot

end LidoSRv3.Tests.PConsolidationEth1RefundTxMutants
