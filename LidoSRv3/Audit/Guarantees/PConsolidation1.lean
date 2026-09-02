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

/-! ## Vocabulary

Readable names for the two arms of the registered source parent and for the
registered Verity statement. Every name is an `abbrev`, so each unfolds
definitionally to the exact clause it stands for (same conjuncts, same order,
same nesting): the registered theorems below are the very same propositions as
before, only spelled the way the English guarantee reads. -/

/-- "All the vault guards pass for this batch, and then `rest`": the caller is
the gateway, the arrays are nonempty and zipped by index, every key is 48
bytes, `count * fee` fits `uint256`, and `msg.value = count * fee`
(`_requireExactFee`). The continuation `rest` keeps the original right-nested
conjunction shape so projections and kill-lines are unchanged. -/
abbrev AllGuardsPassAnd (inputs : Inputs) (requests : List Request) (rest : Prop) : Prop :=
  zipRequests inputs.sources inputs.targets
      inputs.sourceLens inputs.targetLens = some requests ∧
    inputs.caller = inputs.gateway ∧
    inputs.sources.length ≠ 0 ∧
    requests.all validRequest = true ∧
    requests.length * inputs.fee.val ≤ Verity.Core.MAX_UINT256 ∧
    inputs.msgValue.val = requests.length * inputs.fee.val ∧
    rest

/-- "Some batch passes every vault guard": the shape the reverted arm negates
(caller = gateway, nonempty sources, and a zipped, 48-byte-valid, non-wrapping,
exactly-paid request list). -/
abbrev AllGuardsPassForSomeBatch (inputs : Inputs) : Prop :=
  inputs.caller = inputs.gateway ∧
    inputs.sources.length ≠ 0 ∧
    ∃ requests,
      zipRequests inputs.sources inputs.targets
          inputs.sourceLens inputs.targetLens = some requests ∧
        requests.all validRequest = true ∧
        requests.length * inputs.fee.val ≤ Verity.Core.MAX_UINT256 ∧
        inputs.msgValue.val = requests.length * inputs.fee.val

/-- "A batch commits only if every guard passes, the fee is nonzero, and the
observables are exactly one CALL and one event per pair, source then target." -/
abbrev CommitsOnlyWhenAllGuardsPass (inputs : Inputs) : Prop :=
  ∀ obs, sourceRun inputs = .committed obs →
    ∃ requests,
      AllGuardsPassAnd inputs requests
        (inputs.fee.val ≠ 0 ∧
          obs = commitObservables inputs.requestTarget inputs.fee
            inputs.msgValue requests)

/-- "A batch reverts only if some guard fails." -/
abbrev RevertsOnlyWhenSomeGuardFails (inputs : Inputs) : Prop :=
  ∀ reason, sourceRun inputs = .reverted reason →
    ¬ AllGuardsPassForSomeBatch inputs

/-- "What Verity observes of `addRequests` (the fresh CALLs and events plus the
count/fee slots) is exactly `sourceView` of the same `sourceRun`." -/
abbrev ObservesSourceView (inputs : Inputs) (state : Verity.ContractState) : Prop :=
  observe state ((addRequests inputs).run state) =
    sourceView inputs (state.readSlot countSlot).val

/-- **P-CONSOLIDATION-1, source plane.** A consolidation batch commits only if
every vault guard passes (caller = gateway, nonempty aligned 48-byte keys, the
product fits, `msg.value = count * fee`) with a nonzero fee, and then produces
exactly one CALL and one event per pair; it reverts only if some guard fails.

`sourceRun` commits only when caller = gateway, arrays are nonempty and
aligned, every key is 48 bytes, the product fits `uint256`, and
`msg.value` equals `count * fee` (`_requireExactFee`). In isolation `fee = 0`
with `msg.value = 0` commits `sourceRun`; under the caller-supplied
`hGatewayAdmittedNonzero` premise this parent additionally derives
`inputs.fee.val ≠ 0` for every committed run (the gateway entrypoint rejects
`msg.value = 0` before this vault call is ever reached, and the committed
branch's own `msg.value = count * fee` equality then forces a nonzero fee).
A revert implies the un-strengthened conjunction is false. Not beacon
eligibility and not the Bus.

**Outer-gateway premise, recorded as `A-CONSOLIDATION-GATEWAY-NONZERO`.**
`hGatewayAdmittedNonzero` is forwarded to the source theorem and used to
derive the `inputs.fee.val ≠ 0` conjunct above, so the premise excludes the
free-batch arm from this parent's committed case. The premise nevertheless
names the **outer gateway `msg.value` surface** (and the
`P-CONSOLIDATION-ETH-1` fee/refund plane), not the vault's forwarded
`totalFee` call. It is therefore classified at that boundary rather than
presented as a vault-local fact. Two kill-lines pin the present claim:
`gateway_admitted_nonzero_kill_line` is premise-necessity evidence (dropped,
the same conjunct is false of `sourceRun` on a concrete free batch that
violates the premise), and `fee_blind_commit_kill_line_refutes_parent` is
the parent-refuting kill-line (on the mutant interpreter `sourceRunFeeBlind`
with the exact-fee guard dropped, a batch that SATISFIES the premise commits
while this parent's committed-arm conjunction is false of that commit). -/
theorem source_consolidation_preserves_eligibility_value_atomicity
    (inputs : Inputs)
    (hGatewayAdmittedNonzero : inputs.caller = inputs.gateway →
      inputs.msgValue.val ≠ 0) :
    CommitsOnlyWhenAllGuardsPass inputs ∧
    RevertsOnlyWhenSomeGuardFails inputs :=
  SolidityConsolidation.source_consolidation_preserves_eligibility_value_atomicity
    inputs hGatewayAdmittedNonzero

/-- **Premise-necessity evidence for the registered `hGatewayAdmittedNonzero`
premise** (not the parent-refuting kill-line). If a future edit drops the
premise (or stops threading it into the source theorem, making it decorative
again), the strengthened "every committed run has a nonzero fee" claim is
false: a gateway-authorized, nonempty, 48-byte-aligned batch with `fee = 0`
and `msg.value = 0` still commits `sourceRun` (pinned `_requireExactFee(0)`
passes). Scope note: that free-batch witness violates the parent's premise
(`caller = gateway` but `msg.value = 0`), so this theorem refutes the
hypothesis-FREE projection of the parent's committed arm; under the
hypothesis the witness is out of scope. The parent-refuting kill-line is
`fee_blind_commit_kill_line_refutes_parent` below. -/
theorem gateway_admitted_nonzero_kill_line :
    ¬ (∀ (inputs : Inputs) (obs : Observables),
        sourceRun inputs = .committed obs → inputs.fee.val ≠ 0) :=
  SolidityConsolidation.gateway_admitted_nonzero_kill_line

/-- **Kill-line refuting the registered parent on a mutant of its own
model.** `sourceRunFeeBlind` is `sourceRun` with the exact-fee guard
(`inputs.msgValue.val = requests.length * inputs.fee.val`, pinned
`_requireExactFee`) dropped. The witness below SATISFIES the registered
parent's `hGatewayAdmittedNonzero` premise (`caller = gateway`,
`msg.value = 1 ≠ 0`), the mutant commits the batch, every fee-independent
conjunct of the parent's committed arm still holds (zip, caller, nonempty,
48-byte-valid, `uint256` bound, canonical observables), yet
`inputs.fee.val = 0` -- so the parent's hypothesis-conditioned committed-arm
conjunction, evaluated on the mutant model, is false. This is the
parent-refuting kill-line; `gateway_admitted_nonzero_kill_line` above is
premise-necessity evidence only. -/
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
  SolidityConsolidation.fee_blind_commit_kill_line_refutes_parent

/-- **P-CONSOLIDATION-1, Verity plane.** If the four memory arrays decode and
the entry credit does not wrap, what Verity observes of `addRequests` equals
`sourceView` of the same `sourceRun`.

If the four memory arrays decode to the `Inputs` fields and the
frame-entry payable credit does not wrap the `Uint256` balance, `observe`
(suffix of `state.calls` / `state.events` plus count/fee slots) equals
`sourceView` of the same `sourceRun`. The entry no-wrap premise is the
executed-plane funding condition: a wrapping credit is turned away at
entry (`entry_credit_overflow_reverts`) rather than committed as wrapping
CALL debits. Not 96-byte packed calldata. -/
theorem verity_tx_simulates_consolidation (inputs : Inputs)
    (state : Verity.ContractState)
    (hCountBound : (state.readSlot countSlot).val + inputs.sources.length <
      Verity.Core.Uint256.modulus)
    (hEntry : state.selfBalance.val + inputs.msgValue.val <
      Verity.Core.Uint256.modulus)
    (hSources : readArray state "sources" sourcesBase inputs.sources.length =
      some inputs.sources)
    (hTargets : readArray state "targets" targetsBase inputs.targets.length =
      some inputs.targets)
    (hSourceLens : readArray state "sourceLens" sourceLensBase
      inputs.sourceLens.length = some inputs.sourceLens)
    (hTargetLens : readArray state "targetLens" targetLensBase
      inputs.targetLens.length = some inputs.targetLens) :
    ObservesSourceView inputs state :=
  verity_tx_simulates_pinned_source inputs state hCountBound hEntry
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

/-- **Value-bearing CALLs (lift of the formerly named
`preservesEthBalance` gap).** On every committed run the executed
transaction forwards exactly `msg.value` across its journaled CALL
frames — one `.success` CALL frame per request to the consolidation
request target, each carrying the per-request fee, the frame values
summing to `msg.value` (the pinned `_requireExactFee` guard exported onto
the CALL journal). The pre-lift wording of this gap ("current success
stubs move no wei") no longer applies: the executed model's CALLs now
move wei on the vault balance. -/
theorem verity_tx_journal_forwards_msg_value
    (inputs : Inputs) (state : Verity.ContractState)
    (hSources : readArray state "sources" sourcesBase inputs.sources.length =
      some inputs.sources)
    (hTargets : readArray state "targets" targetsBase inputs.targets.length =
      some inputs.targets)
    (hSourceLens : readArray state "sourceLens" sourceLensBase
      inputs.sourceLens.length = some inputs.sourceLens)
    (hTargetLens : readArray state "targetLens" targetLensBase
      inputs.targetLens.length = some inputs.targetLens)
    (result : Result) (after : Verity.ContractState)
    (h : (addRequests inputs).run state = .success result after) :
    let frames := after.calls.drop state.calls.length
    frames.length = result.requestCount ∧
      (∀ f ∈ frames, f.kind = .call ∧ f.control = .success ∧
        f.target = inputs.requestTarget.val ∧ f.value = inputs.fee.val) ∧
      (frames.map (fun f => f.value)).sum = inputs.msgValue.val :=
  Verity.ConsolidationTx.committed_journal_forwards_msg_value inputs
    state hSources hTargets hSourceLens hTargetLens result after h

/-- **`preservesEthBalance` (`WithdrawalVault.sol:81--85`), vault side.**
After the modeled frame-entry payable credit of `msg.value` and the
per-request CALL debits, every committed run restores the vault's
pre-call `selfBalance` — the modifier's `assert` in the model of record.
Every revert restores the whole pre-call snapshot
(`verity_tx_revert_restores_snapshot`), balance included. What remains
outside this plane is the counterparty credit at the request predeploy
(another contract's balance; `P-CONSOLIDATION-VALUE-1` /
`P-CONSOLIDATION-ETH-1` own the multi-contract side) and 96-byte packed
pubkey calldata, both named in `fidelity.missing`. -/
theorem verity_tx_preserves_eth_balance
    (inputs : Inputs) (state : Verity.ContractState)
    (hSources : readArray state "sources" sourcesBase inputs.sources.length =
      some inputs.sources)
    (hTargets : readArray state "targets" targetsBase inputs.targets.length =
      some inputs.targets)
    (hSourceLens : readArray state "sourceLens" sourceLensBase
      inputs.sourceLens.length = some inputs.sourceLens)
    (hTargetLens : readArray state "targetLens" targetLensBase
      inputs.targetLens.length = some inputs.targetLens)
    (result : Result) (after : Verity.ContractState)
    (h : (addRequests inputs).run state = .success result after) :
    after.selfBalance = state.selfBalance :=
  Verity.ConsolidationTx.committed_preserves_eth_balance inputs state
    hSources hTargets hSourceLens hTargetLens result after h

end LidoSRv3.Audit.Guarantees.PConsolidation1
