import LidoSRv3.Audit.Verity.PEth1CompositionTx

/-!
Discriminating mutants for the composed P-ETH-1 transaction.

Each mutant is the *same* ensemble and the *same* dispatcher under a mutated
`Wiring` (or, for the rollback mutant, under the projection that drops
atomicity).  A mutant is killed when its outcome observable differs from the
reference run, so none of these can be satisfied by weakening the parent
statement.
-/

namespace LidoSRv3.Tests.PEth1CompositionTxMutants

open _root_.Verity
open Compiler.CompilationModel.DenoteExternalCalls
open _root_.Verity.MultiContract
open LidoSRv3.Audit.Verity.PEth1CompositionTx

/-- Reference: a two-request batch at 3 wei per request funded with 10 wei. -/
def reference : TxOutcome := run honest 10 2 3

/-- Reference for the atomicity claim: the same batch against a
consolidation-request predeploy that rejects. -/
def referenceRejected : TxOutcome := run { honest with requestAccepts := false } 10 2 3

/-! ## drop — the Gateway never emits the refund leg -/

def dropRefund : TxOutcome := run { honest with emitRefund := false } 10 2 3

theorem rejects_dropped_refund_leg :
    observe dropRefund ≠ observe reference := by decide +kernel

/-! ## misroute — the Gateway's vault link points at Lido -/

def misrouteVault : TxOutcome := run { honest with vaultTarget := lidoAddr } 10 2 3

theorem rejects_misrouted_vault_leg :
    observe misrouteVault ≠ observe reference := by decide +kernel

/-! ## corrupt — the Gateway declares the whole `msg.value` as the refund -/

def corruptRefundAmount : TxOutcome := run { honest with refundWholeValue := true } 10 2 3

theorem rejects_corrupted_refund_amount :
    observe corruptRefundAmount ≠ observe reference := by decide +kernel

/-! ## rollback — the committed prefix is kept after a failing hop -/

theorem rejects_preserved_prefix_after_failed_hop :
    observeWithoutRollback referenceRejected ≠ observe referenceRejected := by
  decide +kernel

/-! ## two-batch — the Vault issues one request for a two-request batch -/

def singleRequestForBatch : TxOutcome := run { honest with perRequestCalls := false } 10 2 3

theorem rejects_single_request_for_two_request_batch :
    observe singleRequestForBatch ≠ observe reference := by decide +kernel

/-- Counterexample to reading the registered Verity theorem as `∀` batches.
An underfunded `(10, 4, 3)` does not deliver `4 * 3` to the request
predeploy; the Gateway reverts and the entry sheet is restored. -/
example :
    observe (run honest 10 4 3) ≠
      ⟨.success, 6, ⟨0, 0, 0, 0, 0, 12, 0⟩⟩ := by
  decide +kernel

end LidoSRv3.Tests.PEth1CompositionTxMutants
