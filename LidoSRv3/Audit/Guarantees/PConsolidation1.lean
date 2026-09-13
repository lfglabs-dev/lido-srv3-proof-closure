import LidoSRv3.Audit.Source.ConsolidationCorrespondence
import LidoSRv3.Audit.Source.ConsolidationFeeStaticcallSource
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

Readable names for the two arms of the registered source parent. Every name
is an `abbrev`, so each unfolds definitionally to the exact clause it stands for (same conjuncts, same order,
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

/-- **P-CONSOLIDATION-1, source plane.** A consolidation batch commits only if
every vault guard passes (caller = gateway, nonempty aligned 48-byte keys, the
product fits, `msg.value = count * fee`) with a nonzero fee, and then produces
exactly one CALL and one event per pair; it reverts only if some guard fails.

`sourceRun` commits only when caller = gateway, arrays are nonempty and
aligned, every key is 48 bytes, the product fits `uint256`, and
`msg.value` equals `count * fee` (`_requireExactFee`). In isolation `fee = 0`
with `msg.value = 0` commits `sourceRun`; under the caller-supplied
`hGatewayAdmittedNonzero` premise this parent additionally derives
`inputs.fee.val ≠ 0` for every committed run (the premise concerns the vault input, and the committed branch's own
`msg.value = count * fee` equality then forces a nonzero fee).
A revert implies the un-strengthened conjunction is false. Not beacon
eligibility and not the Bus.

**Vault-input premise, recorded as `A-CONSOLIDATION-GATEWAY-NONZERO`.**
`hGatewayAdmittedNonzero` is forwarded to the source theorem and used to
derive the `inputs.fee.val ≠ 0` conjunct above. It requires an authorized
vault call to carry nonzero `msg.value`. The gateway forwards `count * fee`,
not its entire outer payment; a positive outer payment can therefore coexist
with zero forwarded value. Discharging the premise requires a justified
positive forwarded fee as well as the composed argument/value path.
Two kill-lines pin the present claim:
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

/-- **Chantier 2 (Thomas 2026-09-13, item a) gateway-bridge parent —
STATICCALL-derived variant.** The registered `A-CONSOLIDATION-GATEWAY-NONZERO`
caller-supplied `hGatewayAdmittedNonzero` premise is REPLACED here by three
pinned-source premises: (i) `hMsgValue` binding `inputs.msgValue` to the
gateway-side `gatewayVaultBoundary result inputs.sources.length` scalar
(ConsolidationGateway.sol:212-220 forwarding of `totalFee`); (ii)
`hCountPos : 0 < inputs.sources.length` (nonempty batch); and (iii)
`hFeeNonzero : result.abiDecodedFee ≠ 0` (nonzero STATICCALL return on the
EIP-7251 predeploy fee-read path). Under this shape, the vault-side
`hGatewayAdmittedNonzero` is DERIVED (via
`verity_tx_gateway_bridge_derives_nonzero_msg_value`) rather than caller-
supplied, and the parent conclusion follows unchanged.

**Composition value**: callers composing at the gateway plane with a
positive fee no longer need to supply `A-CONSOLIDATION-GATEWAY-NONZERO`
as an opaque implication. The premise-shape names the pinned Solidity
carrier of the forwarded value at `WithdrawalVaultEIP7685.sol:79-93`
STATICCALL directly, satisfying Thomas 2026-09-13 mandate item (a)
"compose with real form for premises".

**Residual**: `hFeeNonzero` remains caller-supplied — retiring it
requires a live-STATICCALL executable model on the pinned EIP-7251
predeploy `0x0000BBdDc7CE488642fb579F8B00f3a590007251` (multi-session
Verity model work, disclosed in `fidelity.missing`). The `fee = 0`
on-chain path is documented by `gatewayTotalFee_zero_at_fee_zero`
(source plane): `totalFee = 0` under `fee = 0`, vault admits
`msg.value = 0` under `_requireExactFee(0)`. -/
theorem source_consolidation_preserves_eligibility_value_atomicity_from_gateway
    (result : _root_.LidoSRv3.Audit.Source.ConsolidationFeeStaticcallSource.PredeployStaticcallResult)
    (inputs : Inputs)
    (hMsgValue : inputs.msgValue.val =
      (_root_.LidoSRv3.Audit.Source.ConsolidationFeeStaticcallSource.gatewayVaultBoundary
        result inputs.sources.length).msgValue)
    (hCountPos : 0 < inputs.sources.length)
    (hFeeNonzero : result.abiDecodedFee ≠ 0) :
    CommitsOnlyWhenAllGuardsPass inputs ∧
    RevertsOnlyWhenSomeGuardFails inputs := by
  refine source_consolidation_preserves_eligibility_value_atomicity inputs ?_
  intro _
  rw [hMsgValue]
  unfold _root_.LidoSRv3.Audit.Source.ConsolidationFeeStaticcallSource.gatewayVaultBoundary
  simp only
  exact _root_.LidoSRv3.Audit.Source.ConsolidationFeeStaticcallSource.gatewayTotalFee_ne_zero_of_fee_ne_zero
    result inputs.sources.length hCountPos hFeeNonzero

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

/-- **P-CONSOLIDATION-1, Verity plane (Thomas 2026-09-13 retirement).**
Under the four decode premises and the entry no-wrap premise, the
slot-free companion transaction `addRequestsSlotFree` observed via the
slot-independent `observeFromJournal` equals `sourceView`. The
registered statement no longer reads the fabricated
`sourceMapSlot`/`targetMapSlot` from the executed state (retired here);
`observeFromJournal` derives `payloads` directly from the CALL journal
(`calls.map (·.input)`), matching the pinned Solidity behaviour at
`WithdrawalVaultEIP7685.sol:114-115` (`request = source ‖ target`).

The entry no-wrap premise is the executed-plane funding condition: a
wrapping credit is turned away at entry (`entry_credit_overflow_reverts`)
rather than committed as wrapping CALL debits. Not 96-byte packed
calldata. -/
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
    observeFromJournal state ((addRequestsSlotFree inputs).run state) =
      sourceView inputs (state.readSlot countSlot).val :=
  observeFromJournal_simulates_pinned_source_slotFree inputs state hCountBound
    hEntry hSources hTargets hSourceLens hTargetLens

/-- Every revert of the consolidation transaction, including failure after
intermediate call/event/memory writes, restores the pre-call snapshot.
Registered on the slot-free companion `addRequestsSlotFree` (Thomas
2026-09-13 retirement); rollback semantics come from `Contract.run`'s
uniform revert-arm behaviour, independent of the persistence choice. -/
theorem verity_tx_revert_restores_snapshot
    (inputs : Inputs) (inject : Bool) (state rollback : Verity.ContractState)
    (reason : String)
    (h : (addRequestsSlotFree inputs inject).run state = .revert reason rollback) :
    rollback = state :=
  revert_restores_snapshot_slotFree inputs inject state rollback reason h

/-- **Chantier 2 (Thomas 2026-09-13) gateway→vault ABI/interpreter
bridge, single-path form.** Under the vault-side decode/entry-no-wrap
premises **and** the bridge premises tying `inputs.msgValue` /
`inputs.fee` to a shared `PredeployStaticcallResult` via
`gatewayVaultBoundary`, the theorem concludes **both**:
(i) the vault-side observation-plane equality
`observeFromJournal state ((addRequestsSlotFree inputs).run state) =
sourceView …`, and
(ii) the exact-fee identity anchored on the shared STATICCALL result:
`inputs.msgValue.val = inputs.sources.length * result.abiDecodedFee`.

Conjunct (ii) mentions `result.abiDecodedFee` directly — the bridge
premises `hMsgValue`/`hFee` are load-bearing on the second conjunct
and cannot be dropped without breaking the statement. Conjunct (i) is
supplied by the registered slot-free parent
`verity_tx_simulates_consolidation` (chantier-2 retirement, PR #641).

`gatewayVaultBoundary` (`LidoSRv3/Audit/Source/ConsolidationFeeStaticcallSource.lean`)
packages the two scalars that cross the gateway→vault frame boundary
at `ConsolidationGateway.sol:212-220`:
`msgValue = gatewayTotalFee result requestsCount = n * result.abiDecodedFee`
and `fee = result.abiDecodedFee`. Conjunct (ii) is the arithmetic
identity `_requireExactFee` (`WithdrawalVaultEIP7685.sol:123-127`,
`IncorrectFee` revert) enforces — under the bridge, the vault's
`IncorrectFee` branch is unreachable and the vault commits on the
count / bound / per-key-validation guards alone.

A-CONSOLIDATION-GATEWAY-NONZERO status: RETIRED from this guarantee's
assumption list via PR #699 (registered-parent statement swap to
`source_consolidation_preserves_eligibility_value_atomicity_from_gateway`).
The vault-side `hGatewayAdmittedNonzero` is DERIVED under the pinned-
source premise shape via `gatewayTotalFee_ne_zero_of_fee_ne_zero`
(`result.abiDecodedFee ≠ 0 → totalFee ≠ 0` arithmetic bridge).
`gatewayTotalFee_zero_at_fee_zero` documents the complementary `fee = 0`
on-chain case (`totalFee = 0`; the vault admits `msg.value = 0` under
`_requireExactFee(0)`). The remaining residual is the caller-supplied
`hFeeNonzero : result.abiDecodedFee ≠ 0` on the outer STATICCALL
structure, pending a live-STATICCALL executable model on the pinned
EIP-7251 predeploy.

The full `Contract.run` chain from the gateway's Verity contract
through an ABI encoder to the vault's `Contract.run` remains OPEN
(disclosed in `fidelity.missing`): this parent statement consumes the
source-plane linkage as premises; the executable-frame composition
is a separate follow-up. -/
theorem verity_tx_simulates_consolidation_from_gateway
    (result : _root_.LidoSRv3.Audit.Source.ConsolidationFeeStaticcallSource.PredeployStaticcallResult)
    (inputs : Inputs) (state : Verity.ContractState)
    (hMsgValue : inputs.msgValue.val =
      (_root_.LidoSRv3.Audit.Source.ConsolidationFeeStaticcallSource.gatewayVaultBoundary
        result inputs.sources.length).msgValue)
    (hFee : inputs.fee.val =
      (_root_.LidoSRv3.Audit.Source.ConsolidationFeeStaticcallSource.gatewayVaultBoundary
        result inputs.sources.length).fee)
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
    observeFromJournal state ((addRequestsSlotFree inputs).run state) =
      sourceView inputs (state.readSlot countSlot).val ∧
    inputs.msgValue.val = inputs.sources.length * result.abiDecodedFee := by
  refine ⟨?_, ?_⟩
  · exact verity_tx_simulates_consolidation inputs state hCountBound hEntry
      hSources hTargets hSourceLens hTargetLens
  · rw [hMsgValue]
    -- The gatewayVaultBoundary.msgValue is defined as
    -- gatewayTotalFee result requestsCount, which unfolds to
    -- requestsCount * result.abiDecodedFee.
    unfold _root_.LidoSRv3.Audit.Source.ConsolidationFeeStaticcallSource.gatewayVaultBoundary
    simp only
    exact _root_.LidoSRv3.Audit.Source.ConsolidationFeeStaticcallSource.gatewayTotalFee_eq
      result inputs.sources.length

/-- **Chantier 2 (Thomas 2026-09-13) A-CONSOLIDATION-GATEWAY-NONZERO
gateway-bridged derivation.** Under the bridge premise
`inputs.msgValue.val = gatewayVaultBoundary result inputs.sources.length`,
a positive request count `inputs.sources.length ≠ 0`, and a nonzero
STATICCALL fee `result.abiDecodedFee ≠ 0`, we DERIVE
`inputs.msgValue.val ≠ 0` — the vault-side A-CONSOLIDATION-GATEWAY-NONZERO
premise — without external assumption. This is the mandate's
"fee ≠ 0 → totalFee ≠ 0" derivation, load-bearing on the three named
premises: dropping any of them leaves `inputs.msgValue.val` arbitrary
(zero fee, empty batch, or unrelated msgValue) and the conclusion
false. The complementary `fee = 0` case is documented by
`gatewayTotalFee_zero_at_fee_zero` (source plane): the on-chain
`fee = 0` path forwards `totalFee = 0`, and the vault admits
`msg.value = 0` under `_requireExactFee(0)`. Consumers composing at
the gateway plane with a positive fee no longer need to supply
A-CONSOLIDATION-GATEWAY-NONZERO as a caller premise — this theorem
discharges it. -/
theorem verity_tx_gateway_bridge_derives_nonzero_msg_value
    (result : _root_.LidoSRv3.Audit.Source.ConsolidationFeeStaticcallSource.PredeployStaticcallResult)
    (inputs : Inputs)
    (hMsgValue : inputs.msgValue.val =
      (_root_.LidoSRv3.Audit.Source.ConsolidationFeeStaticcallSource.gatewayVaultBoundary
        result inputs.sources.length).msgValue)
    (hCountPos : 0 < inputs.sources.length)
    (hFeeNonzero : result.abiDecodedFee ≠ 0) :
    inputs.msgValue.val ≠ 0 := by
  rw [hMsgValue]
  unfold _root_.LidoSRv3.Audit.Source.ConsolidationFeeStaticcallSource.gatewayVaultBoundary
  simp only
  exact _root_.LidoSRv3.Audit.Source.ConsolidationFeeStaticcallSource.gatewayTotalFee_ne_zero_of_fee_ne_zero
    result inputs.sources.length hCountPos hFeeNonzero

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

/-- **Value-bearing CALLs, slot-free companion (chantier 2 Thomas
2026-09-13 retirement).** Registered on the slot-free companion
`addRequestsSlotFree` — the vault-side value-plane parent no longer
references the pre-retirement `addRequests` (whose `persist` writes
fabricated `sourceMapSlot`/`targetMapSlot`). On every committed run
of `(addRequestsSlotFree inputs).run state`, the executed transaction
forwards exactly `msg.value` across its journaled CALL frames — one
`.success` CALL frame per request to the consolidation request target,
each carrying the per-request fee, the frame values summing to
`msg.value` (the pinned `_requireExactFee` guard exported onto the
CALL journal). The premise `h : (addRequestsSlotFree inputs).run state =
.success result after` is load-bearing: the proof invokes
`committed_journal_forwards_msg_value_slotFree` which unpacks the
slot-free `addRequestsSlotFree` success inversion (not the pre-retirement
`addRequests` inversion). -/
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
    (h : (addRequestsSlotFree inputs).run state = .success result after) :
    let frames := after.calls.drop state.calls.length
    frames.length = result.requestCount ∧
      (∀ f ∈ frames, f.kind = .call ∧ f.control = .success ∧
        f.target = inputs.requestTarget.val ∧ f.value = inputs.fee.val) ∧
      (frames.map (fun f => f.value)).sum = inputs.msgValue.val :=
  Verity.ConsolidationTx.committed_journal_forwards_msg_value_slotFree inputs
    state hSources hTargets hSourceLens hTargetLens result after h

/-- **`preservesEthBalance` (`WithdrawalVault.sol:81--85`), slot-free
companion (chantier 2 Thomas 2026-09-13 retirement).** Registered on
`addRequestsSlotFree`. After the modeled frame-entry payable credit
of `msg.value` and the per-request CALL debits, every committed run
of `(addRequestsSlotFree inputs).run state` restores the vault's
pre-call `selfBalance`. The premise is load-bearing on the slot-free
companion (invokes `committed_preserves_eth_balance_slotFree` which
uses `persistSlotFree_selfBalance` — the slot-free closed form).
What remains outside is the counterparty credit at the request predeploy
(`P-CONSOLIDATION-VALUE-1` / `P-CONSOLIDATION-ETH-1`) and 96-byte
packed pubkey calldata, both named in `fidelity.missing`. -/
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
    (h : (addRequestsSlotFree inputs).run state = .success result after) :
    after.selfBalance = state.selfBalance :=
  Verity.ConsolidationTx.committed_preserves_eth_balance_slotFree inputs state
    hSources hTargets hSourceLens hTargetLens result after h

end LidoSRv3.Audit.Guarantees.PConsolidation1
