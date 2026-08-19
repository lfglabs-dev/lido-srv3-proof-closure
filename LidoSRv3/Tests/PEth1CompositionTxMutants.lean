import LidoSRv3.Audit.Verity.PEth1CompositionTx
import LidoSRv3.Audit.Guarantees.PEth1

/-!
Discriminating mutants for the composed P-ETH-1 transaction.

Each mutant is the *same* ensemble and the *same* dispatcher under a mutated
`Wiring` (or, for the rollback mutant, under the projection that drops
atomicity).  A mutant is killed when its outcome observable differs from the
reference run, so none of these can be satisfied by weakening the parent
statement.

## Wave 2 scope kill-lines

`LidoSRv3.Audit.Guarantees.PEth1.verity_tx_composes_value_flow_and_rollback`
is a finite conjunction over five concrete `(msgValue, batchSize,
feePerRequest)` tuples — not a `∀` theorem over funded batches. The two
theorems in the "Wave 2 kill-lines" section below are executable
counterexamples to two different ways a reader could over-generalize that
registered parent: one funded-but-underfunded-relative-to-batch tuple that
reverts instead of repartitioning, and one funded, guard-passing tuple that
exhausts the dispatcher's fixed fuel budget instead of succeeding. Neither
failure mode is a `Wiring` mutation; both arise from the honest wiring on
inputs the registered parent does not mention.
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

/-! ## Wave 2 kill-lines — the registered Verity parent is a finite witness
bundle over five `(msgValue, batchSize, feePerRequest)` tuples, not a `∀`
theorem over funded batches (report/P-ETH-1.md issue 2). Each theorem below
is a concrete batch the registered parent never mentions, whose outcome a
naive `∀`-reading of the parent would get wrong. -/

/-- Counterexample to reading the registered Verity theorem as `∀` batches
that succeed whenever `n * fee ≤ msgValue`. An underfunded `(10, 4, 3)` does
not deliver `4 * 3` to the request predeploy even though a caller could
believe (from the abstract `eth_flow_parent` split law) that the total is
just repartitioned; the Gateway reverts in the model itself and the entry
sheet is restored, so no such split exists for this tuple. -/
theorem underfunded_batch_is_not_a_repartition :
    observe (run honest 10 4 3) ≠
      ⟨.success, 6, ⟨0, 0, 0, 0, 0, 12, 0⟩⟩ := by
  decide +kernel

/-- Counterexample to reading the registered Verity theorem as `∀` batches
that succeed whenever the Gateway/Vault fee guards pass. `(30, 29, 1)` is
funded (`29 * 1 = 29 ≤ 30`, no overflow) and every guard the compiled bodies
check is satisfied, yet the batch needs `3 + 29 + 1 = 33` dispatched frames
(Bus, Gateway, Vault, 29 per-request calls, one refund) against
`fuelBudget = 32`. The dispatcher reports `TxControl.exhausted`, a control
value none of the registered parent's five witnesses ever produce and that
`eth_flow_parent`'s `GatewayRevert` cases do not mention either — this is
report/P-ETH-1.md issue 9 (`fuelBudget` silently bounds the theorem's
meaning), made executable. This refutes generalizing the registered parent
to "every funded batch succeeds with the fee/refund split", not just to
"every batch the Gateway's own guards accept". -/
theorem large_funded_batch_exhausts_fuel_budget :
    (run honest 30 29 1).control = .exhausted := by decide +kernel

/-! ## Wave 1 kill-line mutants — the registered parent must reject these -/

open LidoSRv3.Audit.Guarantees.PEth1

private def testApproved : ApprovedSet :=
  { consolidationContract := 100
    refundRecipient := 200 }

/-- Kill-line: a journal entry to an unapproved address makes the parent fail.
The `classifyJournal` function maps address 999 to `.other 999`, so
`parentApproved` is `False`. -/
theorem rejects_unapproved_journal_entry :
    let moves := [{ amount := 5, destination := classifyJournal testApproved 999 : EthMove }]
    ¬ (∀ m, m ∈ moves → parentApproved m.destination) := by
  simp [classifyJournal, testApproved, parentApproved]

/-- Kill-line: `msg.value = 0` produces a `ZeroArgument` revert, not success. -/
theorem rejects_zero_msg_value :
    gatewayExecute testApproved 0 2 3 = .reverted .zeroArgument := by
  rfl

end LidoSRv3.Tests.PEth1CompositionTxMutants
