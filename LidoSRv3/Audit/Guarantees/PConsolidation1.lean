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

/-- `sourceRun` commits only when caller = gateway, arrays are nonempty and
aligned, every key is 48 bytes, the product fits `uint256`, and
`msg.value` equals `count * fee` (`_requireExactFee`). `fee = 0` with
`msg.value = 0` commits. A revert implies that conjunction is false.
Not beacon eligibility and not the Bus.

**Wave 1 premise.** This vault entry is only reached if the gateway
admitted nonzero `msg.value`. The `fee = 0 ∧ msg.value = 0` arm stays a
correct vault fact but is no longer user-reachable. -/
theorem source_consolidation_preserves_eligibility_value_atomicity
    (inputs : Inputs)
    (hGatewayAdmittedNonzero : inputs.caller = inputs.gateway →
      inputs.msgValue.val ≠ 0) :
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

/-- If the four memory arrays decode to the `Inputs` fields, `observe`
(suffix of `state.calls` / `state.events` plus count/fee slots) equals
`sourceView` of the same `sourceRun`. Not 96-byte packed calldata. -/
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
    observe state ((addRequests inputs).run state) =
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

/-- **Kill-line: packing order.** If source ≠ target, a swapped
target then source concat produces a different observation than the
canonical source then target. One pair suffices. -/
theorem packing_order_kills_swapped_concat
    (target fee msgValue : SolidityConsolidation.Word) (r : Request)
    (h : r.source ≠ r.target) :
    commitObservables target fee msgValue [r] ≠
      swappedCommitObservables target fee msgValue [r] := by
  exact commitObservables_ne_swapped target fee msgValue [r] rfl
    (fun x hx => by simp [List.mem_cons, List.mem_nil_iff] at hx; subst hx; exact h)

/-- **Named gap: preservesEthBalance.** The Solidity modifier
(WithdrawalVault.sol:201) snapshots address(this).balance and reverts
if it changed after the loop. Closing the gap requires value-bearing
CALL frames, not the current success stubs with empty returndata. -/
abbrev preservesEthBalance_gap : String :=
  "preservesEthBalance (requires value-bearing CALL frames, not success stubs)"

end LidoSRv3.Audit.Guarantees.PConsolidation1
