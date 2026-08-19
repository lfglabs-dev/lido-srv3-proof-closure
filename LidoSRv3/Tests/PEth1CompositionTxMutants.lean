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

## Wave 4 parent kill-lines

The Wave 1 theorems at the bottom of this file were originally registered as
kill-lines but refuted nothing: one quantified over a hand-built move list the
registered abstract parent never mentions, and the other *confirmed* the
honest model's zero guard, which the parent already requires. They are kept
under honest names (`confirms_*`). The actual kill-lines factor the
registered parent's per-outcome predicate out as `parentOutcomePredicate`,
prove it is definitionally the conclusion of
`LidoSRv3.Audit.Guarantees.PEth1.eth_flow_parent`, and then exhibit two
mutants of `gatewayExecute` itself — a misrouted fee journal and a
guard-free gateway that pays fees at zero `msg.value` — on whose success
outputs that exact predicate is false.
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

/-! ## Wave 1 honest-model confirmations (renamed — these are not kill-lines)

The two theorems in this section were registered in Wave 1 as kill-lines.
They are not: the first quantifies over a hand-built one-move list that
`eth_flow_parent` never mentions (the parent quantifies over `gatewayExecute`'s
*output*, not over arbitrary lists), and the second *confirms* the honest
model's own zero guard — the parent's first clause already requires exactly
that behaviour of `gatewayExecute`. They are kept as regression checks on the
classifier and the honest guards; the parent kill-lines are the Wave 4
theorems in the next section. -/

open LidoSRv3.Audit.Guarantees.PEth1

private def testApproved : ApprovedSet :=
  { consolidationContract := 100
    refundRecipient := 200 }

/-- Confirmation: an address outside the ApprovedSet is classified to the
lateral `.other` tag, which `parentApproved` rejects. A property of
`classifyJournal` on a hand-built list, not a refutation of the parent. -/
theorem confirms_lateral_journal_entry_is_not_parent_approved :
    let moves := [{ amount := 5, destination := classifyJournal testApproved 999 : EthMove }]
    ¬ (∀ m, m ∈ moves → parentApproved m.destination) := by
  simp [classifyJournal, testApproved, parentApproved]

/-- Confirmation: the honest `gatewayExecute` reverts `ZeroArgument` at
`msgValue = 0` — exactly what the parent's first clause requires of the honest
model, so nothing is refuted here. -/
theorem confirms_zero_msg_value_reverts :
    gatewayExecute testApproved 0 2 3 = .reverted .zeroArgument := by
  rfl

/-! ## Wave 4 kill-lines — the parent's own predicate, refuted on mutants of
`gatewayExecute` itself -/

/-- The registered parent's per-outcome predicate, factored out of
`eth_flow_parent` (`Guarantees/PEth1.lean`): a zero-argument revert happens
only at `msgValue = 0`, an overflow revert only when `n * fee ≥ 2^256`, an
insufficient-value revert only when `n * fee > msgValue`, and on success every
move is `parentApproved` with `totalAmount moves = msgValue`. -/
def parentOutcomePredicate (msgValue n fee : Nat) (result : GatewayResult) : Prop :=
  match result with
  | .reverted .zeroArgument => msgValue = 0
  | .reverted .overflowPanic => n * fee ≥ 2^256
  | .reverted .insufficientValue => n * fee > msgValue
  | .success moves =>
      (∀ m, m ∈ moves → parentApproved m.destination) ∧
      totalAmount moves = msgValue

/-- The factored predicate is exactly the registered parent's conclusion:
applied to the honest model it holds on every input, by `eth_flow_parent`
itself. The kill-lines below refute this same predicate on mutants. -/
theorem parentOutcomePredicate_is_eth_flow_parent_conclusion (msgValue n fee : Nat) :
    parentOutcomePredicate msgValue n fee (gatewayExecute testApproved msgValue n fee) := by
  unfold parentOutcomePredicate
  exact eth_flow_parent testApproved (by decide) msgValue n fee

/-- An address outside `testApproved`'s ApprovedSet, standing in for an
operator-supplied fee sink (report/P-ETH-1.md issue 1's scenario). -/
def rogueFeeSink : LidoSRv3.Audit.Guarantees.PEth1.Address := 999

/-- Mutant of `gatewayExecute`: identical revert guards and fee/refund split,
but the per-request fee moves are journaled to `rogueFeeSink` instead of the
approved consolidation contract, so `classifyJournal` maps them to
`.other rogueFeeSink`. -/
def gatewayExecuteMisrouted (approved : ApprovedSet) (msgValue n fee : Nat) : GatewayResult :=
  if msgValue = 0 then .reverted .zeroArgument
  else if n * fee ≥ 2^256 then .reverted .overflowPanic
  else if n * fee > msgValue then .reverted .insufficientValue
  else
    let totalFee := n * fee
    let refund := msgValue - totalFee
    let feeMoves := List.replicate n
      { amount := fee, destination := classifyJournal approved rogueFeeSink }
    let refundMoves := if refund = 0 then []
      else [{ amount := refund
              destination := classifyJournal approved approved.refundRecipient }]
    .success (feeMoves ++ refundMoves)

/-- **Kill-line.** The funded success case `(10, 2, 3)` on the misrouted
mutant produces two 3-wei fee legs classified `.other 999` plus the 4-wei
approved refund, so the registered parent's exact success conjunct is false on
the mutant's output: conservation still holds (`3 + 3 + 4 = 10`), but
`∀ m, m ∈ moves → parentApproved m.destination` does not. -/
theorem misrouted_journal_kill_line_refutes_parent :
    ∃ moves, gatewayExecuteMisrouted testApproved 10 2 3 = .success moves ∧
      ¬ ((∀ m, m ∈ moves → parentApproved m.destination) ∧ totalAmount moves = 10) := by
  refine ⟨[{ amount := 3, destination := .other rogueFeeSink },
           { amount := 3, destination := .other rogueFeeSink },
           { amount := 4, destination := .refundRecipient }], rfl, ?_⟩
  intro h
  have hNotApproved : ¬ parentApproved (EthDestination.other rogueFeeSink) := by
    simp [parentApproved]
  exact hNotApproved (h.1 { amount := 3, destination := .other rogueFeeSink } (by decide))

/-- Mutant of `gatewayExecute`: the `ZeroArgument` and `InsufficientValue`
value guards are dropped, so a zero-value call *succeeds*, issuing the
per-request fee moves paid from the gateway's own balance. The saturating
refund `0 - n * fee = 0` emits no refund leg. -/
def gatewayExecuteUnguarded (approved : ApprovedSet) (msgValue n fee : Nat) : GatewayResult :=
  if n * fee ≥ 2^256 then .reverted .overflowPanic
  else
    let totalFee := n * fee
    let refund := msgValue - totalFee
    let feeMoves := List.replicate n
      { amount := fee, destination := classifyJournal approved approved.consolidationContract }
    let refundMoves := if refund = 0 then []
      else [{ amount := refund
              destination := classifyJournal approved approved.refundRecipient }]
    .success (feeMoves ++ refundMoves)

/-- **Kill-line.** On the unguarded mutant the zero-value call `(0, 2, 3)`
succeeds and emits two 3-wei fee moves to the approved consolidation contract,
so the registered parent's success conjunct at `msgValue = 0` is false: every
destination is approved, but `totalAmount moves = 6 ≠ 0`. This is the
parent-killing form of the Wave 1 zero-value check: a gateway that lets a
zero-value call move wei violates the conservation half of the parent's
success clause. -/
theorem zero_value_success_kill_line_refutes_parent :
    ∃ moves, gatewayExecuteUnguarded testApproved 0 2 3 = .success moves ∧
      ¬ ((∀ m, m ∈ moves → parentApproved m.destination) ∧ totalAmount moves = 0) := by
  refine ⟨[{ amount := 3, destination := .consolidationContract },
           { amount := 3, destination := .consolidationContract }], rfl, ?_⟩
  intro h
  exact absurd h.2 (by decide)

end LidoSRv3.Tests.PEth1CompositionTxMutants
