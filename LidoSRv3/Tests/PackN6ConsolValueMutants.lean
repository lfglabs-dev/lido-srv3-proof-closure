import LidoSRv3.Audit.Guarantees.PConsolidationValue1

/-! Node 6 kill-line for zero-value consolidation request frames. -/

namespace LidoSRv3.Tests.PackN6ConsolValueMutants

open _root_.Verity
open LidoSRv3.Audit.SolidityConsolidation
open LidoSRv3.Audit.Verity.ConsolidationValueTx
open LidoSRv3.Audit.Guarantees

@[simp] theorem zeroValueCall_value_val (call : CallObs) :
    (zeroValueCall call).value.val = 0 := rfl

theorem zero_value_call_sum (calls : List CallObs) :
    callValueSum (calls.map zeroValueCall) = 0 := by
  simp [callValueSum, Function.comp_def]

/-- Parent-shaped kill-line.  The source commit keeps gateway authorization,
48-byte validation, multiplication bounds, and exact-fee equality.  The mutant
then executes the same request count and payloads with zero-value
`externalCallBindTo` frames.  It retains the vault's incoming value and cannot
forward exactly the nonzero `msg.value`. -/
theorem zero_value_calls_refute_exact_forwarding
    (inputs : Inputs) (before : ContractState) (obs : Observables)
    (hGatewayAdmittedNonzero : inputs.caller = inputs.gateway →
      inputs.msgValue.val ≠ 0)
    (hSource : sourceRun inputs = .committed obs) :
    ∃ after,
      (executeZeroValueMutant inputs).run before = .success () after ∧
      inputs.caller = inputs.gateway ∧
      (∃ requests,
        zipRequests inputs.sources inputs.targets
          inputs.sourceLens inputs.targetLens = some requests ∧
        requests.all validRequest = true ∧
        requests.length * inputs.fee.val ≤ Verity.Core.MAX_UINT256 ∧
        inputs.msgValue.val = requests.length * inputs.fee.val) ∧
      after.selfBalance = before.selfBalance ∧
      ¬ forwardedValue before after = inputs.msgValue.val := by
  obtain ⟨requests, hZip, hCaller, _, hValid, hProduct, hExactFee, _,
      _⟩ :=
    (PConsolidation1.source_consolidation_preserves_eligibility_value_atomicity
        inputs hGatewayAdmittedNonzero).1 obs hSource
  let mutantCalls := obs.calls.map zeroValueCall
  let after := afterCalls mutantCalls before
  have hZero : callValueSum mutantCalls = 0 := by
    exact zero_value_call_sum obs.calls
  have hMutant :
      (executeZeroValueMutant inputs).run before = .success () after := by
    unfold executeZeroValueMutant
    rw [hSource]
    exact forwardCalls_run mutantCalls before (by rw [hZero]; omega)
  have hBalance : after.selfBalance = before.selfBalance := by
    apply Verity.Core.Uint256.ext
    rw [show after.selfBalance.val =
        before.selfBalance.val - callValueSum mutantCalls by
      exact afterCalls_balance_val mutantCalls before (by rw [hZero]; omega)]
    rw [hZero]
    omega
  have hForwardedZero : forwardedValue before after = 0 := by
    exact (afterCalls_forwardedValue mutantCalls before).trans hZero
  have hMsgNonzero : inputs.msgValue.val ≠ 0 :=
    hGatewayAdmittedNonzero hCaller
  refine ⟨after, hMutant, hCaller,
    ⟨requests, hZip, hValid, hProduct, hExactFee⟩, hBalance, ?_⟩
  intro hForwarded
  exact hMsgNonzero (hForwarded.symm.trans hForwardedZero)

end LidoSRv3.Tests.PackN6ConsolValueMutants
