import LidoSRv3.Audit.Spec.ConsolidationObserveCorrespondence
import LidoSRv3.Audit.Verity.ConsolidationTx

/-!
# Pack F fail-closed vectors

A mutant that rereads target-then-source disagrees with honest `observe`
when source ≠ target.
-/

namespace LidoSRv3.Tests.PackFConsolidationObserveMutants

open Verity
open LidoSRv3.Audit.SolidityConsolidation
open LidoSRv3.Audit.Verity.ConsolidationTx
open LidoSRv3.Audit.Spec.ConsolidationObserveCorrespondence

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

private def stateOf (inputs : Inputs) : ContractState :=
  stateFor inputs.sources inputs.targets inputs.sourceLens inputs.targetLens
    defaultState

/-- Mutant reread: target then source. -/
def readPayloadsSwapped (state : ContractState) :
    Nat → Nat → List (List LidoSRv3.Audit.SolidityConsolidation.Word)
  | _, 0 => []
  | index, count + 1 =>
      [state.readMapUint targetMapSlot (Verity.Core.Uint256.ofNat index),
       state.readMapUint sourceMapSlot (Verity.Core.Uint256.ofNat index)] ::
        readPayloadsSwapped state (index + 1) count

def observeSwappedMaps (before : ContractState) : ContractResult Result → View
  | .success _ state =>
      let calls := (state.calls.drop before.calls.length).map ofJournal
      let events := (state.events.drop before.events.length).map ofEvent
      let beforeCount := (before.readSlot countSlot).val
      ⟨.committed, calls, events,
        readPayloadsSwapped state beforeCount calls.length,
        state.readSlot countSlot, state.readSlot feePaidSlot⟩
  | .revert _ _ =>
      ⟨.reverted, [], [], [], before.readSlot countSlot, 0⟩

/-- Kill-line: on source `11` / target `21`, honest observe rereads
`[11, 21]` and the swapped mutant rereads `[21, 11]`. -/
theorem swapped_map_reread_kill_line_refutes_observe :
    let inputs := pair 11 21
    let before := stateOf inputs
    let run := (addRequests inputs).run before
    (observe before run).payloads = [[word 11, word 21]] ∧
      (observeSwappedMaps before run).payloads = [[word 21, word 11]] ∧
      observe before run ≠ observeSwappedMaps before run := by
  native_decide

/-- Honest observe payloads are the map reread, not a `Result` field. -/
example (before : ContractState) (result : Result) (after : ContractState) :
    (observe before (.success result after)).payloads =
      readPayloads after (before.readSlot countSlot).val
        (after.calls.drop before.calls.length).length :=
  observe_success_payloads_reread_maps before result after

end LidoSRv3.Tests.PackFConsolidationObserveMutants
