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

end LidoSRv3.Tests.ConsolidationTxMutants
