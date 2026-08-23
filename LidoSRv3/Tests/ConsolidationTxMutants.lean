import LidoSRv3.Audit.Verity.ConsolidationTx

/-! P-CONSOLIDATION-1 faithful-plane fail-closed vectors. -/

namespace LidoSRv3.Tests.ConsolidationTxMutants

open Verity
open LidoSRv3.Audit.SolidityConsolidation
open LidoSRv3.Audit.Verity.ConsolidationTx

private def word (n : Nat) : LidoSRv3.Audit.SolidityConsolidation.Word :=
  Verity.Core.Uint256.ofNat n

private def key48 : LidoSRv3.Audit.SolidityConsolidation.Word := word 48

private def pair (source target : Nat) : Inputs :=
  { caller := word 7
    gateway := word 7
    requestTarget := word consolidationRequestAddress
    fee := word 3
    msgValue := word 3
    sources := [word source]
    targets := [word target]
    sourceLens := [key48]
    targetLens := [key48] }

private def twoPair (s0 t0 s1 t1 : Nat) : Inputs :=
  { caller := word 7
    gateway := word 7
    requestTarget := word consolidationRequestAddress
    fee := word 3
    msgValue := word 6
    sources := [word s0, word s1]
    targets := [word t0, word t1]
    sourceLens := [key48, key48]
    targetLens := [key48, key48] }

private def stateOf (inputs : Inputs) : Verity.ContractState :=
  stateFor inputs.sources inputs.targets inputs.sourceLens inputs.targetLens
    defaultState

private def runView (inputs : Inputs) : View :=
  observe (stateOf inputs) ((addRequests inputs).run (stateOf inputs))

private def expectedCall (source target : Nat) : CallObs :=
  { target := word consolidationRequestAddress
    value := word 3
    input := [word source, word target] }

private def expectedEvent (source target : Nat) : EventObs :=
  { topic := word consolidationRequestAddedTopic
    payload := [word source, word target] }

/-- Positive one-pair batch: one CALL, one event, source-then-target payload. -/
example :
    runView (pair 11 21) =
      ⟨.committed, [expectedCall 11 21], [expectedEvent 11 21],
        [[word 11, word 21]], word 1, word 3⟩ := by native_decide

/-- Call-drop mutant: omitting the CALL is not the source observation. -/
example :
    runView (pair 11 21) ≠
      ⟨.committed, [], [expectedEvent 11 21],
        [[word 11, word 21]], word 1, word 3⟩ := by native_decide

/-- Event-drop mutant: omitting ConsolidationRequestAdded is rejected. -/
example :
    runView (pair 11 21) ≠
      ⟨.committed, [expectedCall 11 21], [],
        [[word 11, word 21]], word 1, word 3⟩ := by native_decide

/-- Memory-drop mutant: dropping the source‖target payload is rejected. -/
example :
    runView (pair 11 21) ≠
      ⟨.committed, [expectedCall 11 21], [expectedEvent 11 21],
        [], word 1, word 3⟩ := by native_decide

/-- Double-emit mutant: two events per pair is rejected. -/
example :
    runView (pair 11 21) ≠
      ⟨.committed, [expectedCall 11 21],
        [expectedEvent 11 21, expectedEvent 11 21],
        [[word 11, word 21]], word 1, word 3⟩ := by native_decide

/-- Mismatched arity reverts before any call, event, or payload is committed. -/
example :
    runView
      { pair 11 21 with targets := [], targetLens := [] } =
      ⟨.reverted, [], [], [], 0, 0⟩ := by native_decide

example :
    runView
      { pair 11 21 with targets := [], targetLens := [] } ≠
      ⟨.committed, [expectedCall 11 21], [expectedEvent 11 21],
        [[word 11, word 21]], word 1, word 3⟩ := by native_decide

/-- Two-pair batch binds both source-then-target payloads in order. -/
example :
    runView (twoPair 11 21 12 22) =
      ⟨.committed,
        [expectedCall 11 21, expectedCall 12 22],
        [expectedEvent 11 21, expectedEvent 12 22],
        [[word 11, word 21], [word 12, word 22]], word 2, word 6⟩ := by
  native_decide

/-- A second batch starts from the first batch's count and appends. -/
example :
    let first := runView (pair 11 21)
    let secondState :=
      match (addRequests (pair 11 21)).run (stateOf (pair 11 21)) with
      | .success _ after =>
          stateFor [word 12] [word 22] [key48] [key48] after
      | .revert _ s => s
    let secondInputs : Inputs :=
      { pair 12 22 with }
    first = ⟨.committed, [expectedCall 11 21], [expectedEvent 11 21],
        [[word 11, word 21]], word 1, word 3⟩ ∧
      observe secondState ((addRequests secondInputs).run secondState) =
        ⟨.committed, [expectedCall 12 22], [expectedEvent 12 22],
          [[word 12, word 22]], word 2, word 3⟩ := by native_decide

/-- Two-batch mutant that rewrites the first batch's count instead of
appending is rejected. -/
example :
    let secondState :=
      match (addRequests (pair 11 21)).run (stateOf (pair 11 21)) with
      | .success _ after =>
          stateFor [word 12] [word 22] [key48] [key48] after
      | .revert _ s => s
    observe secondState ((addRequests (pair 12 22)).run secondState) ≠
      ⟨.committed, [expectedCall 12 22], [expectedEvent 12 22],
        [[word 12, word 22]], word 1, word 3⟩ := by native_decide

/-- Failure after call/event/memory writes is observed as a revert. The
snapshot law `revert_restores_snapshot` then restores the pre-call state. -/
example :
    observe (stateOf (pair 11 21)) ((addRequests (pair 11 21) true).run
      (stateOf (pair 11 21))) =
      ⟨.reverted, [], [], [], 0, 0⟩ := by native_decide

example (reason : String) (rollback : Verity.ContractState)
    (h : (addRequests (pair 11 21) true).run (stateOf (pair 11 21)) =
      .revert reason rollback) :
    rollback = stateOf (pair 11 21) :=
  revert_restores_snapshot _ _ _ _ _ h

/-- Empty-key length is rejected before a CALL is formed. -/
example :
    runView { pair 11 21 with sourceLens := [word 47] } =
      ⟨.reverted, [], [], [], 0, 0⟩ := by native_decide

/-- Unauthorized caller observes no calls or events. -/
example :
    runView { pair 11 21 with caller := word 6 } =
      ⟨.reverted, [], [], [], 0, 0⟩ := by native_decide

/-- Pinned `_requireExactFee(0)`: a gateway-authorized nonempty 48-byte
pair with `fee = 0` and `msg.value = 0` commits, it does not revert
`ZeroArgument(fee)`. -/
example :
    runView { pair 11 21 with fee := word 0, msgValue := word 0 } =
      ⟨.committed,
        [{ target := word consolidationRequestAddress, value := word 0
           input := [word 11, word 21] }],
        [expectedEvent 11 21], [[word 11, word 21]], word 1, word 0⟩ := by
  native_decide

/-- The registered FunctionSpec stays on the call/event/memory constructors. -/
example : function_spec_bridge_constructors =
    function_spec_bridge_constructors :=
  rfl

private def stateBal (inputs : Inputs) (bal : Nat) : Verity.ContractState :=
  { stateOf inputs with selfBalance := word bal }

/-! ## Value-plane kill-lines: CALLs must move exactly msg.value

Three model mutants of the same executed transaction (see
`ConsolidationTx.lean`): `addRequestsValueBlind` keeps the payable credit
and the journaled CALL frames but debits nothing (the pre-lift stub
behavior), `addRequestsDoubleDebit` debits twice the journaled value per
CALL, and `addRequestsJournalValueBlind` debits honestly but journals each
frame with value `0`. Each witness satisfies the same memory-decode
hypotheses as the registered parent `verity_tx_simulates_consolidation`,
so the refutations are about the value plane, not decode plumbing. -/

private def valObs : Observables :=
  commitObservables (word consolidationRequestAddress) (word 3) (word 3)
    [{ source := word 11
       target := word 21
       sourceLen := key48
       targetLen := key48 }]

private def valState : Verity.ContractState :=
  stateBal (pair 11 21) 5

private def valAfterPlain : Verity.ContractState :=
  persistPlain 0 valObs (credited valState (pair 11 21))

private def valAfterDouble : Verity.ContractState :=
  persistDoubleDebit 0 valObs (credited valState (pair 11 21))

private def valAfterJournalBlind : Verity.ContractState :=
  persistJournalValueBlind 0 valObs (credited valState (pair 11 21))

/-- **Kill-line: value-blind debit refutes `committed_preserves_eth_balance`
on a mutant of its own model.** The pre-lift stub behavior — journaled
CALLs that move no wei — leaves the credited `msg.value` stuck on the
vault: the post-run `selfBalance` is pre-call + 3, not the pre-call 5.
`sourceRun` commits the same batch, so the mutant reaches the success arm
the registered theorem talks about. -/
theorem value_blind_debit_kill_line_refutes_preserves_eth_balance :
    ∃ (inputs : Inputs) (state : Verity.ContractState)
      (result : Result) (after : Verity.ContractState),
      readArray state "sources" sourcesBase inputs.sources.length =
        some inputs.sources ∧
      readArray state "targets" targetsBase inputs.targets.length =
        some inputs.targets ∧
      readArray state "sourceLens" sourceLensBase
        inputs.sourceLens.length = some inputs.sourceLens ∧
      readArray state "targetLens" targetLensBase
        inputs.targetLens.length = some inputs.targetLens ∧
      observe state ((addRequestsValueBlind inputs).run state) =
        observe state (.success result after) ∧
      after.selfBalance ≠ state.selfBalance :=
  ⟨pair 11 21, valState, ofObservables valObs, valAfterPlain,
    by native_decide, by native_decide, by native_decide,
    by native_decide, by native_decide, by native_decide⟩

/-- **Kill-line: double debit refutes `committed_preserves_eth_balance`
on a mutant of its own model.** Debiting twice the journaled value per CALL
drains the vault: post-run `selfBalance` is pre-call + 3 − 6 = 2, not 5. -/
theorem double_debit_kill_line_refutes_preserves_eth_balance :
    ∃ (inputs : Inputs) (state : Verity.ContractState)
      (result : Result) (after : Verity.ContractState),
      readArray state "sources" sourcesBase inputs.sources.length =
        some inputs.sources ∧
      readArray state "targets" targetsBase inputs.targets.length =
        some inputs.targets ∧
      readArray state "sourceLens" sourceLensBase
        inputs.sourceLens.length = some inputs.sourceLens ∧
      readArray state "targetLens" targetLensBase
        inputs.targetLens.length = some inputs.targetLens ∧
      observe state ((addRequestsDoubleDebit inputs).run state) =
        observe state (.success result after) ∧
      after.selfBalance ≠ state.selfBalance :=
  ⟨pair 11 21, valState, ofObservables valObs, valAfterDouble,
    by native_decide, by native_decide, by native_decide,
    by native_decide, by native_decide, by native_decide⟩

/-- **Kill-line: journaled value 0 refutes
`committed_journal_forwards_msg_value` on a mutant of its own model.**
Honest debits with zero-valued journal frames leave the balance correct
(the mutant passes the balance assertion) but the journal claims no value
moved: the frame-values sum is 0, not `msg.value = 3`. -/
theorem journal_value_blind_kill_line_refutes_exact_forwarding :
    ∃ (inputs : Inputs) (state : Verity.ContractState)
      (result : Result) (after : Verity.ContractState),
      readArray state "sources" sourcesBase inputs.sources.length =
        some inputs.sources ∧
      readArray state "targets" targetsBase inputs.targets.length =
        some inputs.targets ∧
      readArray state "sourceLens" sourceLensBase
        inputs.sourceLens.length = some inputs.sourceLens ∧
      readArray state "targetLens" targetLensBase
        inputs.targetLens.length = some inputs.targetLens ∧
      observe state ((addRequestsJournalValueBlind inputs).run state) =
        observe state (.success result after) ∧
      after.selfBalance = state.selfBalance ∧
      ((after.calls.drop state.calls.length).map (·.value)).sum ≠
        inputs.msgValue.val :=
  ⟨pair 11 21, valState, ofObservables valObs, valAfterJournalBlind,
    by native_decide, by native_decide, by native_decide,
    by native_decide, by native_decide, by native_decide,
    by native_decide⟩

/-! ## Entry-credit overflow: CALL-value credit must reject Uint256 wrap

Codex P1 (PR #214, review r3839226133): when
`state.selfBalance + inputs.msgValue` exceeds `Uint256`, the frame-entry
credit used to wrap and could leave a credited balance below the
per-request fee, yet the unconditional per-CALL debits wrapped back and
the transaction still committed. The executed model now rejects such
entries (`ENTRY_CREDIT_OVERFLOW`) before decode; the regressions below
exercise the executable path at both boundaries of the wrap point. -/

/-- Overflow reject: `selfBalance = 2^256 - 2` with `msgValue = 3` would
wrap the entry credit to `1 < fee = 3`; the batch is rejected at entry and
the pre-call snapshot is restored. -/
example :
    (addRequests (pair 11 21)).run (stateBal (pair 11 21) (2^256 - 2)) =
      .revert "ENTRY_CREDIT_OVERFLOW" (stateBal (pair 11 21) (2^256 - 2)) :=
  entry_credit_overflow_reverts _ _ _ (by native_decide)

/-- The overflow reject is observed, not committed: no CALL, event,
payload, or fee survives an entry that cannot be credited. -/
example :
    observe (stateBal (pair 11 21) (2^256 - 2))
        ((addRequests (pair 11 21)).run (stateBal (pair 11 21) (2^256 - 2))) =
      ⟨.reverted, [], [], [], 0, 0⟩ := by native_decide

/-- Boundary commit: the largest admissible credit
`2^256 - 4 + 3 = MAX_UINT256` does not wrap, so the batch commits the full
honest observables. -/
example :
    observe (stateBal (pair 11 21) (2^256 - 4))
        ((addRequests (pair 11 21)).run (stateBal (pair 11 21) (2^256 - 4))) =
      ⟨.committed, [expectedCall 11 21], [expectedEvent 11 21],
        [[word 11, word 21]], word 1, word 3⟩ := by native_decide

/-- Boundary reject: one wei further, `2^256 - 3 + 3 = 2^256`, wraps and is
rejected at entry. -/
example :
    (addRequests (pair 11 21)).run (stateBal (pair 11 21) (2^256 - 3)) =
      .revert "ENTRY_CREDIT_OVERFLOW" (stateBal (pair 11 21) (2^256 - 3)) :=
  entry_credit_overflow_reverts _ _ _ (by native_decide)

/-- **Cheap mutant: swapped concat.** Journal calldata = source then target
(96 bytes). A swapped target then source concat fails observe: the
committed view with a swapped input list is not equal to the canonical
committed view. -/
example :
    runView (pair 11 21) ≠
      runView { pair 11 21 with sources := [word 21], targets := [word 11] } := by
  native_decide

/-- **Premise-necessity: `hGatewayAdmittedNonzero` is load-bearing.** The
registered parent
`PConsolidation1.source_consolidation_preserves_eligibility_value_atomicity`
derives `inputs.fee.val ≠ 0` for every committed run from this premise. Drop
the premise (equivalently: stop threading it into the source theorem) and
the same conjunct is refuted by a concrete gateway-authorized, nonempty,
48-byte-aligned batch with `fee = 0` and `msg.value = 0`: `sourceRun` still
commits it (pinned `_requireExactFee(0)` passes; see the `_requireExactFee(0)`
Verity vector above). If a future edit quietly drops the hypothesis again,
this theorem stops compiling as a proof of the un-strengthened claim.
Scope note: the free-batch witness VIOLATES the parent's premise
(`caller = gateway` but `msg.value = 0`), so this is premise-necessity
evidence, not a refutation of the hypothesis-conditioned parent; the
parent-refuting kill-line is `fee_blind_commit_kill_line_refutes_parent`
below. -/
theorem gateway_admitted_nonzero_premise_necessity :
    ¬ (∀ (inputs : Inputs) (obs : Observables),
        sourceRun inputs = .committed obs → inputs.fee.val ≠ 0) :=
  gateway_admitted_nonzero_kill_line

/-- **Kill-line refuting the registered parent on a mutant of its own
model.** `sourceRunFeeBlind` is `sourceRun` with the exact-fee guard
dropped. The concrete witness satisfies the parent's
`hGatewayAdmittedNonzero` premise (`caller = gateway`, `msg.value = 1 ≠ 0`),
the mutant commits the batch, every fee-independent conjunct of the parent's
committed arm holds of that commit, yet `inputs.fee.val = 0` -- so the
parent's hypothesis-conditioned committed-arm conjunction is false on the
mutant model. This is the parent kill-line;
`gateway_admitted_nonzero_premise_necessity` above is premise-necessity
evidence only. -/
theorem fee_blind_commit_kill_line_refutes_parent :
    ∃ (inputs : Inputs) (obs : Observables),
      (inputs.caller = inputs.gateway → inputs.msgValue.val ≠ 0) ∧
      sourceRunFeeBlind inputs = .committed obs ∧
      (∃ requests,
          zipRequests inputs.sources inputs.targets
            inputs.sourceLens inputs.targetLens = some requests ∧
          inputs.caller = inputs.gateway ∧
          inputs.sources.length ≠ 0 ∧
          requests.all validRequest = true ∧
          requests.length * inputs.fee.val ≤ Verity.Core.MAX_UINT256 ∧
          obs = commitObservables inputs.requestTarget inputs.fee
            inputs.msgValue requests) ∧
      inputs.fee.val = 0 ∧
      ¬ (∃ requests,
          zipRequests inputs.sources inputs.targets
            inputs.sourceLens inputs.targetLens = some requests ∧
          inputs.caller = inputs.gateway ∧
          inputs.sources.length ≠ 0 ∧
          requests.all validRequest = true ∧
          requests.length * inputs.fee.val ≤ Verity.Core.MAX_UINT256 ∧
          inputs.msgValue.val = requests.length * inputs.fee.val ∧
          inputs.fee.val ≠ 0 ∧
          obs = commitObservables inputs.requestTarget inputs.fee
            inputs.msgValue requests) :=
  LidoSRv3.Audit.SolidityConsolidation.fee_blind_commit_kill_line_refutes_parent

end LidoSRv3.Tests.ConsolidationTxMutants
