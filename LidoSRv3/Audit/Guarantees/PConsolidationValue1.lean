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

The gateway nonzero premise remains an explicit caller-supplied premise
(`A-CONSOLIDATION-GATEWAY-NONZERO`).  This parent neither starts the Bus nor
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
`A-CONSOLIDATION-GATEWAY-NONZERO` stays a premise. -/
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

`A-CONSOLIDATION-GATEWAY-NONZERO` stays a premise in both halves.  The base
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
