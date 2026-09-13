import LidoSRv3.Audit.Guarantees.PConsolidation1
import LidoSRv3.Audit.Spec.ConsolidationBridgeGap
import LidoSRv3.Audit.Spec.ConsolidationValueCorrespondence
import LidoSRv3.Audit.Verity.ConsolidationOfficialDenoteSuccess
import LidoSRv3.Audit.Guarantees.Registry

/-!
# P-CONSOLIDATION-VALUE-1

Value-conservation parent for the consolidation request path.  The registered
`PConsolidation1` parent supplies the source guards; this module adds
execution-derived value CALLs and the vault balance postcondition, and — the
campaign-product-6 discharge — official denotation success on value-bearing
request CALLs.

The official success conjunct is proved on the *official upstream* widened
call fragment `Compiler.CompilationModel.DenoteFunctionCalls.
denoteFunctionWithCalls` at the pinned Verity head (see
`LidoSRv3.Audit.Verity.ConsolidationOfficialDenoteSuccess`), for the
registered bind entrypoint and every oracle, accepting predeploy model,
transaction, and world satisfying the source guards.  The base fragment
`Denote.denoteFunction` still maps `Expr.call` / `Stmt.externalCallBind`
outside its arms and still reverts
(`ConsolidationBridgeGap.official_external_call_reverts` stays named); no
compiled-artifact behaviour is claimed.

The gateway nonzero premise was formerly caller-supplied via
`A-CONSOLIDATION-GATEWAY-NONZERO`; it is now DERIVED under the
`PredeployStaticcallResult`-shaped pinned-source premises of the
registered `..._from_gateway` variant (chantier 2 Thomas 2026-09-13
item a, PR #712 — same pattern as PR #699 on P-CONSOLIDATION-1),
and `A-CONSOLIDATION-GATEWAY-NONZERO` is retired from this
guarantee's assumption list. The residual `hFeeNonzero :
result.abiDecodedFee ≠ 0` on the outer STATICCALL structure remains
caller-supplied pending a live-STATICCALL executable model on the
pinned EIP-7251 predeploy. This parent neither starts the Bus nor
performs consensus-layer verification: `noConsensusLayerVerify` is an
explicit conjunct of the justified half, and `onlyRequestFrames` is its
denotation-plane counterpart in the official half.
-/

namespace LidoSRv3.Audit.Guarantees.PConsolidationValue1

open _root_.Verity
open Compiler.CompilationModel.Denote
open Compiler.CompilationModel.DenoteExternalCalls
open LidoSRv3.Audit.SolidityConsolidation
open LidoSRv3.Audit.Verity.ConsolidationCallFragment
open LidoSRv3.Audit.Verity.ConsolidationValueTx
open LidoSRv3.Audit.Verity.ConsolidationOfficialDenoteSuccess
open LidoSRv3.Audit.Spec.ConsolidationBridgeGap
open LidoSRv3.Audit.Spec.ConsolidationValueCorrespondence

/-- Supplemental parent: official widened-call denotation succeeds on
value-bearing request CALLs, justified interpreter forwards `msg.value`.
Registered on the gateway-bridge variant `..._from_gateway` (PR #712);
`A-CONSOLIDATION-GATEWAY-NONZERO` is retired from this guarantee's
assumption list. -/
def guarantee : Guarantee := ⟨.pConsolidationValue1, [.model, .source, .verityTx]⟩

/-- Every successful justified execution retains all registered consolidation
guards, journals exactly the committed request CALLs, forwards exactly
`msg.value`, decreases the vault by exactly that amount, and re-establishes
`preservesEthBalance`.  The only fresh frames are request frames, so no
consensus-layer verification occurs in this parent. -/
theorem justified_interpreter_forwards_exactly_msg_value
    (inputs : Inputs) (before after : ContractState)
    (hGatewayAdmittedNonzero : inputs.caller = inputs.gateway →
      inputs.msgValue.val ≠ 0)
    (hStateMsgValue : before.msgValue = inputs.msgValue)
    (hFunds : inputs.msgValue ≤ before.selfBalance)
    (hExecute : (execute inputs).run before = .success () after) :
    ∃ (obs : Observables) (requests : List Request),
      sourceRun inputs = .committed obs ∧
      zipRequests inputs.sources inputs.targets
        inputs.sourceLens inputs.targetLens = some requests ∧
      inputs.caller = inputs.gateway ∧
      inputs.sources.length ≠ 0 ∧
      requests.all validRequest = true ∧
      requests.length * inputs.fee.val ≤ Verity.Core.MAX_UINT256 ∧
      inputs.msgValue.val = requests.length * inputs.fee.val ∧
      inputs.fee.val ≠ 0 ∧
      obs = commitObservables inputs.requestTarget inputs.fee
        inputs.msgValue requests ∧
      freshCalls before after = obs.calls.map requestEntry ∧
      forwardedValue before after = inputs.msgValue.val ∧
      vaultEthDelta inputs before after ∧
      preservesEthBalance before after ∧
      noConsensusLayerVerify before after := by
  have hFundsNat : inputs.msgValue.val ≤ before.selfBalance.val := hFunds
  obtain ⟨obs, hSource, hAfter, hFresh, hForwarded, hNoVerify⟩ :=
    execute_success_corresponds_to_committed_requests
      inputs before after hFundsNat hExecute
  obtain ⟨requests, hZip, hCaller, hNonempty, hValid, hProduct,
      hExactFee, hFeeNonzero, hObs⟩ :=
    (PConsolidation1.source_consolidation_preserves_eligibility_value_atomicity
      inputs hGatewayAdmittedNonzero).1 obs hSource
  have hCallValue := committed_call_value_sum inputs obs hSource
  have hCallFunds : callValueSum obs.calls ≤ before.selfBalance.val := by
    rw [hCallValue]
    exact hFundsNat
  have hBalance :
      after.selfBalance.val =
        before.selfBalance.val - inputs.msgValue.val := by
    rw [hAfter, afterCalls_balance_val obs.calls before hCallFunds, hCallValue]
  have hDelta : vaultEthDelta inputs before after := by
    unfold vaultEthDelta
    rw [hBalance]
    omega
  have hPreserves : preservesEthBalance before after := by
    unfold preservesEthBalance
    apply Verity.Core.Uint256.ext
    rw [Verity.Core.Uint256.sub_eq_of_le]
    · simpa [hStateMsgValue] using hBalance
    · simpa [hStateMsgValue] using hFundsNat
  exact ⟨obs, requests, hSource, hZip, hCaller, hNonempty, hValid,
    hProduct, hExactFee, hFeeNonzero, hObs, hFresh, hForwarded,
    hDelta, hPreserves, hNoVerify⟩

/-- PARENT. Official denotation success on value-bearing request CALLs, and
the justified interpreter forwards exactly `msg.value`.

First conjunct (the discharged OPEN): for the registered bind entrypoint
`spec.functions[1]`, for every oracle, every accepting predeploy model,
every link target and fee, and every transaction and world satisfying the
source guards (gateway caller with admitted-nonzero `msg.value`, nonzero
aligned keys, exact `msg.value = 1 * fee`, funded non-wrapping vault), the
official upstream widened-call denotation `denoteFunctionWithCalls`
succeeds, journals exactly one fresh CALL frame carrying the nonzero fee,
forwards exactly `msg.value`, re-establishes `preservesEthBalance`, returns
the vault to its pre-credit balance, and produces only request frames
(no consensus-layer verification frame).

Second conjunct: every successful justified execution forwards exactly
`msg.value` and carries `noConsensusLayerVerify` as an explicit conjunct.

This original theorem takes `A-CONSOLIDATION-GATEWAY-NONZERO` as a
caller-supplied premise in both halves; the `..._from_gateway` variant
below (PR #712) DERIVES it under `PredeployStaticcallResult`-shaped
pinned-source premises and is the new registered form.  The base
fragment `denoteFunction` still reverts on the bind entrypoint
(`official_external_call_reverts`, kept named in `ConsolidationBridgeGap`);
no compiled-artifact behaviour is claimed.  No bus, no delay, no quota. -/
theorem official_denote_succeeds_and_justified_forwards_msg_value :
    (∀ (oracle : DenoteOracle)
        (adversary : Compiler.CompilationModel.DenoteExternalCalls.AdversaryModel)
        (target fee gateway : Nat)
        (tx : DenoteTransaction) (world : ContractState)
        (sourceKey targetKey : Nat),
      AcceptingPredeploy adversary →
      tx.args = [sourceKey, targetKey] →
      sourceKey < Verity.Core.Uint256.modulus →
      targetKey < Verity.Core.Uint256.modulus →
      sourceKey ≠ 0 →
      targetKey ≠ 0 →
      tx.sender = gateway →
      (tx.sender = gateway → tx.msgValue ≠ 0) →
      tx.msgValue = 1 * fee →
      world.selfBalance.val + fee < Verity.Core.Uint256.modulus →
      ((officialDenote (officialEnv oracle adversary target fee) tx
          world).success = true ∧
        fee ≠ 0 ∧
        ((freshCalls (Compiler.CompilationModel.DenoteFunctionCalls.withPayableCallContext world tx)
            (officialExec (officialEnv oracle adversary target fee) tx
              world).world).map (fun call => call.value)) = [fee] ∧
        forwardedValue
            (Compiler.CompilationModel.DenoteFunctionCalls.withPayableCallContext world tx)
            (officialExec (officialEnv oracle adversary target fee) tx
              world).world = tx.msgValue ∧
        preservesEthBalance
          (Compiler.CompilationModel.DenoteFunctionCalls.withPayableCallContext world tx)
          (officialExec (officialEnv oracle adversary target fee) tx
            world).world ∧
        (officialExec (officialEnv oracle adversary target fee) tx
              world).world.selfBalance.val + tx.msgValue
          = (Compiler.CompilationModel.DenoteFunctionCalls.withPayableCallContext
              world tx).selfBalance.val ∧
        (officialExec (officialEnv oracle adversary target fee) tx
            world).world.selfBalance = world.selfBalance ∧
        onlyRequestFrames target
          (Compiler.CompilationModel.DenoteFunctionCalls.withPayableCallContext world tx)
          (officialExec (officialEnv oracle adversary target fee) tx
            world).world)) ∧
    (∀ (inputs : Inputs) (before after : ContractState),
      (inputs.caller = inputs.gateway → inputs.msgValue.val ≠ 0) →
      before.msgValue = inputs.msgValue →
      inputs.msgValue ≤ before.selfBalance →
      (execute inputs).run before = .success () after →
      ∃ (obs : Observables) (requests : List Request),
        sourceRun inputs = .committed obs ∧
        zipRequests inputs.sources inputs.targets
          inputs.sourceLens inputs.targetLens = some requests ∧
        inputs.caller = inputs.gateway ∧
        inputs.sources.length ≠ 0 ∧
        requests.all validRequest = true ∧
        requests.length * inputs.fee.val ≤ Verity.Core.MAX_UINT256 ∧
        inputs.msgValue.val = requests.length * inputs.fee.val ∧
        inputs.fee.val ≠ 0 ∧
        obs = commitObservables inputs.requestTarget inputs.fee
          inputs.msgValue requests ∧
        freshCalls before after = obs.calls.map requestEntry ∧
        forwardedValue before after = inputs.msgValue.val ∧
        vaultEthDelta inputs before after ∧
        preservesEthBalance before after ∧
        noConsensusLayerVerify before after) :=
  ⟨fun oracle adversary target fee gateway tx world sourceKey targetKey
      hAccepting hArgs hSourceAligned hTargetAligned hSourceKey hTargetKey
      hCaller hGatewayAdmittedNonzero hExactValue hFunded =>
    official_denote_succeeds_on_value_bearing_request_calls
      oracle adversary target fee gateway tx world sourceKey targetKey
      hAccepting hArgs hSourceAligned hTargetAligned hSourceKey hTargetKey
      hCaller hGatewayAdmittedNonzero hExactValue hFunded,
    justified_interpreter_forwards_exactly_msg_value⟩

/-- **Chantier 2 (Thomas 2026-09-13, item a) gateway-bridge parent —
STATICCALL-derived variant of `official_denote_succeeds_and_justified_forwards_msg_value`.**
Follows the same registered-parent statement-change pattern as PR #699
(P-CONSOLIDATION-1) applied to the P-CONSOLIDATION-VALUE-1 compound
theorem: the caller-supplied `hGatewayAdmittedNonzero` premise on each
of the two conjuncts is REPLACED by pinned-source structured premises
naming the EIP-7251 CONSOLIDATION_REQUEST STATICCALL return
(`WithdrawalVaultEIP7685.sol:79-93`).

First conjunct (official denotation): a caller-supplied
`hFeeFromStaticcall : fee = result.abiDecodedFee` premise ties the free
`fee : Nat` to the STATICCALL return; combined with `hFeeNonzero` and
`hExactValue : tx.msgValue = 1 * fee`, the vault-side `tx.sender =
gateway → tx.msgValue ≠ 0` is DERIVED (`Nat.mul_ne_zero` /
`Nat.one_mul`), and the original theorem's 8 conclusions follow.

Second conjunct (justified interpreter): a caller-supplied
`hMsgValueSource` bridge premise ties `inputs.msgValue.val` to
`gatewayVaultBoundary result inputs.sources.length .msgValue`
(matching `ConsolidationGateway.sol:212-220` `totalFee` forwarding).
Combined with `hCountPos` and `hFeeNonzero`, the vault-side
`inputs.caller = inputs.gateway → inputs.msgValue.val ≠ 0` is DERIVED
via `gatewayTotalFee_ne_zero_of_fee_ne_zero`.

Under this pinned-source premise shape, `A-CONSOLIDATION-GATEWAY-NONZERO`
is retired from P-CONSOLIDATION-VALUE-1's assumption list. The
original `official_denote_succeeds_and_justified_forwards_msg_value`
is kept in-file (above) as unregistered evidence for downstream
callers not on the gateway path. Residual: `hFeeNonzero` remains
caller-supplied on the pinned STATICCALL structure; full derivation
requires the multi-session live-STATICCALL executable model on the
pinned EIP-7251 predeploy. -/
theorem official_denote_succeeds_and_justified_forwards_msg_value_from_gateway
    (result : _root_.LidoSRv3.Audit.Source.ConsolidationFeeStaticcallSource.PredeployStaticcallResult)
    (hFeeNonzero : result.abiDecodedFee ≠ 0) :
    (∀ (oracle : DenoteOracle)
        (adversary : Compiler.CompilationModel.DenoteExternalCalls.AdversaryModel)
        (target fee gateway : Nat)
        (tx : DenoteTransaction) (world : ContractState)
        (sourceKey targetKey : Nat),
      AcceptingPredeploy adversary →
      tx.args = [sourceKey, targetKey] →
      sourceKey < Verity.Core.Uint256.modulus →
      targetKey < Verity.Core.Uint256.modulus →
      sourceKey ≠ 0 →
      targetKey ≠ 0 →
      tx.sender = gateway →
      fee = result.abiDecodedFee →
      tx.msgValue = 1 * fee →
      world.selfBalance.val + fee < Verity.Core.Uint256.modulus →
      ((officialDenote (officialEnv oracle adversary target fee) tx
          world).success = true ∧
        fee ≠ 0 ∧
        ((freshCalls (Compiler.CompilationModel.DenoteFunctionCalls.withPayableCallContext world tx)
            (officialExec (officialEnv oracle adversary target fee) tx
              world).world).map (fun call => call.value)) = [fee] ∧
        forwardedValue
            (Compiler.CompilationModel.DenoteFunctionCalls.withPayableCallContext world tx)
            (officialExec (officialEnv oracle adversary target fee) tx
              world).world = tx.msgValue ∧
        preservesEthBalance
          (Compiler.CompilationModel.DenoteFunctionCalls.withPayableCallContext world tx)
          (officialExec (officialEnv oracle adversary target fee) tx
            world).world ∧
        (officialExec (officialEnv oracle adversary target fee) tx
              world).world.selfBalance.val + tx.msgValue
          = (Compiler.CompilationModel.DenoteFunctionCalls.withPayableCallContext
              world tx).selfBalance.val ∧
        (officialExec (officialEnv oracle adversary target fee) tx
            world).world.selfBalance = world.selfBalance ∧
        onlyRequestFrames target
          (Compiler.CompilationModel.DenoteFunctionCalls.withPayableCallContext world tx)
          (officialExec (officialEnv oracle adversary target fee) tx
            world).world)) ∧
    (∀ (inputs : Inputs) (before after : ContractState),
      0 < inputs.sources.length →
      inputs.msgValue.val =
        (_root_.LidoSRv3.Audit.Source.ConsolidationFeeStaticcallSource.gatewayVaultBoundary
          result inputs.sources.length).msgValue →
      before.msgValue = inputs.msgValue →
      inputs.msgValue ≤ before.selfBalance →
      (execute inputs).run before = .success () after →
      ∃ (obs : Observables) (requests : List Request),
        sourceRun inputs = .committed obs ∧
        zipRequests inputs.sources inputs.targets
          inputs.sourceLens inputs.targetLens = some requests ∧
        inputs.caller = inputs.gateway ∧
        inputs.sources.length ≠ 0 ∧
        requests.all validRequest = true ∧
        requests.length * inputs.fee.val ≤ Verity.Core.MAX_UINT256 ∧
        inputs.msgValue.val = requests.length * inputs.fee.val ∧
        inputs.fee.val ≠ 0 ∧
        obs = commitObservables inputs.requestTarget inputs.fee
          inputs.msgValue requests ∧
        freshCalls before after = obs.calls.map requestEntry ∧
        forwardedValue before after = inputs.msgValue.val ∧
        vaultEthDelta inputs before after ∧
        preservesEthBalance before after ∧
        noConsensusLayerVerify before after) := by
  refine ⟨?_, ?_⟩
  · intro oracle adversary target fee gateway tx world sourceKey targetKey
      hAccepting hArgs hSourceAligned hTargetAligned hSourceKey hTargetKey
      hCaller hFeeFromStaticcall hExactValue hFunded
    have hGatewayAdmittedNonzero : tx.sender = gateway → tx.msgValue ≠ 0 := by
      intro _
      rw [hExactValue, hFeeFromStaticcall, Nat.one_mul]
      exact hFeeNonzero
    exact official_denote_succeeds_on_value_bearing_request_calls
      oracle adversary target fee gateway tx world sourceKey targetKey
      hAccepting hArgs hSourceAligned hTargetAligned hSourceKey hTargetKey
      hCaller hGatewayAdmittedNonzero hExactValue hFunded
  · intro inputs before after hCountPos hMsgValueSource hStateMsgValue
      hFunds hExecute
    have hGatewayAdmittedNonzero :
        inputs.caller = inputs.gateway → inputs.msgValue.val ≠ 0 := by
      intro _
      rw [hMsgValueSource]
      unfold _root_.LidoSRv3.Audit.Source.ConsolidationFeeStaticcallSource.gatewayVaultBoundary
      simp only
      exact _root_.LidoSRv3.Audit.Source.ConsolidationFeeStaticcallSource.gatewayTotalFee_ne_zero_of_fee_ne_zero
        result inputs.sources.length hCountPos hFeeNonzero
    exact justified_interpreter_forwards_exactly_msg_value inputs before after
      hGatewayAdmittedNonzero hStateMsgValue hFunds hExecute

/-- Direct named projection of the Solidity modifier postcondition. -/
theorem preservesEthBalance_of_success
    (inputs : Inputs) (before after : ContractState)
    (hGatewayAdmittedNonzero : inputs.caller = inputs.gateway →
      inputs.msgValue.val ≠ 0)
    (hStateMsgValue : before.msgValue = inputs.msgValue)
    (hFunds : inputs.msgValue ≤ before.selfBalance)
    (hExecute : (execute inputs).run before = .success () after) :
    preservesEthBalance before after := by
  obtain ⟨_, _, _, _, _, _, _, _, _, _, _, _, _, _, hPreserves, _⟩ :=
    justified_interpreter_forwards_exactly_msg_value inputs before after
      hGatewayAdmittedNonzero hStateMsgValue hFunds hExecute
  exact hPreserves

end LidoSRv3.Audit.Guarantees.PConsolidationValue1
