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
`msg.value` equals `count * fee` (`_requireExactFee`). In isolation `fee = 0`
with `msg.value = 0` commits `sourceRun`; under the caller-supplied
`hGatewayAdmittedNonzero` premise this parent additionally derives
`inputs.fee.val ≠ 0` for every committed run (the gateway entrypoint rejects
`msg.value = 0` before this vault call is ever reached, and the committed
branch's own `msg.value = count * fee` equality then forces a nonzero fee).
A revert implies the un-strengthened conjunction is false. Not beacon
eligibility and not the Bus.

**Wave 1 premise, made load-bearing in Wave 3.** `hGatewayAdmittedNonzero`
is now forwarded to the source theorem and used to derive the
`inputs.fee.val ≠ 0` conjunct above, so the premise actually excludes the
free-batch arm from this parent's committed case (it no longer merely sits
in the signature unused). `gateway_admitted_nonzero_kill_line` below shows
the premise is necessary: dropped, the same conjunct is false of `sourceRun`
on a concrete free batch. -/
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
        inputs.fee.val ≠ 0 ∧
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
    inputs hGatewayAdmittedNonzero

/-- **Kill-line for the registered `hGatewayAdmittedNonzero` premise.** If a
future edit drops the premise (or stops threading it into the source
theorem, making it decorative again), the strengthened "every committed run
has a nonzero fee" claim is false: a gateway-authorized, nonempty,
48-byte-aligned batch with `fee = 0` and `msg.value = 0` still commits
`sourceRun` (pinned `_requireExactFee(0)` passes). This refutes the
registered parent's own strengthened statement, not a sibling. -/
theorem gateway_admitted_nonzero_kill_line :
    ¬ (∀ (inputs : Inputs) (obs : Observables),
        sourceRun inputs = .committed obs → inputs.fee.val ≠ 0) :=
  SolidityConsolidation.gateway_admitted_nonzero_kill_line

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
