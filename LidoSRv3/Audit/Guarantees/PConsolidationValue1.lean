import LidoSRv3.Audit.Guarantees.PConsolidation1
import LidoSRv3.Audit.Spec.ConsolidationValueCorrespondence

/-!
# P-CONSOLIDATION-VALUE-1

Value-conservation parent for the justified consolidation request interpreter.
The registered `PConsolidation1` parent supplies the source guards; this module
adds execution-derived value CALLs and the vault balance postcondition.

The gateway nonzero premise remains an explicit caller-supplied premise.  This
parent neither starts the Bus nor performs consensus-layer verification.
-/

namespace LidoSRv3.Audit.Guarantees.PConsolidationValue1

open _root_.Verity
open LidoSRv3.Audit.SolidityConsolidation
open LidoSRv3.Audit.Verity.ConsolidationValueTx
open LidoSRv3.Audit.Spec.ConsolidationValueCorrespondence

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
