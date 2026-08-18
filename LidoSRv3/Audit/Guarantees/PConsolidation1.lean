import LidoSRv3.Audit.Source.ConsolidationCorrespondence
import LidoSRv3.Audit.Verity.ConsolidationTx
import LidoSRv3.Audit.Guarantees.Registry

namespace LidoSRv3.Audit.Guarantees.PConsolidation1

open Verity
open LidoSRv3.Audit.SolidityConsolidation
open LidoSRv3.Audit.Verity.ConsolidationTx

/-- The pinned source forwards public-key pairs, not ETH amounts. -/
abbrev ValidatorPubkey := Nat

structure ConsolidationRequest where
  sourcePubkey : ValidatorPubkey
  targetPubkey : ValidatorPubkey
  deriving DecidableEq, Repr

abbrev FeePerConsolidation := Nat
abbrev PrepaidBalance := Nat

/-- Transaction-plane state relevant to consolidation. The external call
world is modeled separately by Verity's `CallProgram`; this snapshot contains
the operator's prepaid balance and the validator public-key map. -/
structure ValidatorRegistry where
  prepaidBalance : PrepaidBalance
  pubkeyMapping : List (ValidatorPubkey × Nat)
  deriving DecidableEq, Repr

def mapping_invariant (registry : ValidatorRegistry) : Prop :=
  registry.pubkeyMapping.Pairwise fun left right => left.1 ≠ right.1

/-- The only value guard in consolidation: one fee per public-key pair. -/
def consolidation_fee_valid (requests : List ConsolidationRequest)
    (fee : FeePerConsolidation) (balance : PrepaidBalance) : Prop :=
  requests.length * fee ≤ balance

/-- Consolidation does not rewrite the validator public-key map. -/
def pubkey_mapping_preserved (pre post : ValidatorRegistry)
    (_requests : List ConsolidationRequest) : Prop :=
  post.pubkeyMapping = pre.pubkeyMapping ∧ mapping_invariant post

/-- Marker emitted by the snapshot rollback branch. -/
def consolidation_reverted (post snapshot : ValidatorRegistry) : Prop :=
  post = snapshot

def guarantee : Guarantee := ⟨.pConsolidation1, [.model, .source, .verityTx]⟩

/-- Abstract parent: a committed vault consolidation is eligible, conserves
the exact fee product, and binds one CALL plus one event per `source ‖ target`
pair. A revert exposes none of those effects. -/
theorem source_consolidation_preserves_eligibility_value_atomicity
    (inputs : Inputs) :
    (∀ obs, sourceRun inputs = .committed obs →
      ∃ requests,
        zipRequests inputs.sources inputs.targets
          inputs.sourceLens inputs.targetLens = some requests ∧
        inputs.caller = inputs.gateway ∧
        inputs.sources.length ≠ 0 ∧
        requests.all validRequest = true ∧
        requests.length * inputs.fee.val ≤ Verity.Core.MAX_UINT256 ∧
        inputs.msgValue.val = requests.length * inputs.fee.val ∧
        obs = commitObservables inputs.requestTarget inputs.fee
          inputs.msgValue requests) ∧
    (∀ reason, sourceRun inputs = .reverted reason →
      ¬ (inputs.caller = inputs.gateway ∧
          inputs.sources.length ≠ 0 ∧
          ∃ requests,
            zipRequests inputs.sources inputs.targets
              inputs.sourceLens inputs.targetLens = some requests ∧
            requests.all validRequest = true ∧
            requests.length * inputs.fee.val ≤ Verity.Core.MAX_UINT256 ∧
            inputs.msgValue.val = requests.length * inputs.fee.val)) :=
  SolidityConsolidation.source_consolidation_preserves_eligibility_value_atomicity
    inputs

/--
Faithful VERITY_TX closure for P-CONSOLIDATION-1. This theorem starts with the
actual `Verity.Contract.run` result of the source-shaped consolidation
transaction: it decodes memory-backed key/length arrays, journals one CALL and
one event per pair, persists payloads with `writeMapUint` and counts with
`writeSlot`, and proves that the committed/reverted observables are the
pinned-source consolidation transaction. Every guard failure and the injected
post-write failure observes Verity's pre-call rollback state.

This is not an EVM theorem: storage-slot numbers are a model-local projection,
and no Solidity compiler, Yul, runtime bytecode, proxy layout, deployed code,
or multi-contract EVM semantics is claimed.
-/
theorem verity_tx_simulates_consolidation (inputs : Inputs)
    (state : Verity.ContractState)
    (hSources : readArray state "sources" sourcesBase inputs.sources.length =
      some inputs.sources)
    (hTargets : readArray state "targets" targetsBase inputs.targets.length =
      some inputs.targets)
    (hSourceLens : readArray state "sourceLens" sourceLensBase
      inputs.sourceLens.length = some inputs.sourceLens)
    (hTargetLens : readArray state "targetLens" targetLensBase
      inputs.targetLens.length = some inputs.targetLens) :
    observe (state.readSlot countSlot).val ((addRequests inputs).run state) =
      sourceView inputs (state.readSlot countSlot).val :=
  verity_tx_simulates_pinned_source inputs state
    hSources hTargets hSourceLens hTargetLens

/-- Every revert of the consolidation transaction, including failure after
intermediate call/event/memory writes, restores the pre-call snapshot. -/
theorem verity_tx_revert_restores_snapshot
    (inputs : Inputs) (inject : Bool) (state rollback : Verity.ContractState)
    (reason : String)
    (h : (addRequests inputs inject).run state = .revert reason rollback) :
    rollback = state :=
  revert_restores_snapshot inputs inject state rollback reason h

end LidoSRv3.Audit.Guarantees.PConsolidation1
