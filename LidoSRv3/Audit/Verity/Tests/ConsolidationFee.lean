import LidoSRv3.Audit.Verity.ConsolidationFee

namespace LidoSRv3.Audit.Verity.Tests.ConsolidationFee

open Compiler.CompilationModel.DenoteExternalCalls
open LidoSRv3.Audit.Verity.ConsolidationFee

def sourceKey : Pubkey := List.replicate 48 11
def targetKey : Pubkey := List.replicate 48 21
def request : Request := { source := sourceKey, target := targetKey }

theorem test_function_spec_compiles :
    (Compiler.CompilationModel.compile spec [addConsolidationRequestsSelector]).isOk = true := by
  exact function_spec_compiles

/-- The regression follows the source fee formula and exact-value guard instead
of reviving the removed prepaid-balance model. -/
theorem test_function_spec_contains_checked_exact_fee_guards :
    (.letVar "requiredFee" (.mul (.localVar "requestsCount") (.localVar "fee")) :
        Compiler.CompilationModel.Stmt) ∈ addConsolidationRequests.body ∧
      (.require
          (.eq (.div (.localVar "requiredFee") (.localVar "requestsCount"))
            (.localVar "fee"))
          "Panic(0x11): checked multiplication overflow" :
        Compiler.CompilationModel.Stmt) ∈ addConsolidationRequests.body ∧
      (.require (.eq .msgValue (.localVar "requiredFee")) "IncorrectFee" :
        Compiler.CompilationModel.Stmt) ∈ addConsolidationRequests.body := by
  simp [addConsolidationRequests]

/-- The bounded memory witness accepts exact 48-byte source and target keys. -/
def test_exact_key_lengths_are_accepted : Bool :=
  validRequest (encodeRequest request)

#guard test_exact_key_lengths_are_accepted

/-- Negative length mutants are rejected before a request call can be formed. -/
def test_key_length_mutants_are_rejected : Bool :=
  !validRequest (encodeRequest { request with source := sourceKey.drop 1 }) &&
    !validRequest (encodeRequest { request with target := targetKey ++ [22] })

#guard test_key_length_mutants_are_rejected

/-- The request calldata is source first, target second, with no fabricated
registry or prepaid-balance state. -/
def test_payload_is_source_then_target : Bool :=
  payloadBytes (encodeRequest request) == sourceKey ++ targetKey

#guard test_payload_is_source_then_target

/-- The fee read and fee-bearing request use the immutable request target,
with the exact call kinds, value, and 96-byte payload represented by the model. -/
def test_call_sites_are_source_shaped : Bool :=
  let fee := feeSite 0x7251
  let requestCall := requestSite 0x7251 3 0 (encodeRequest request)
  decide (fee.kind = .staticcall ∧ fee.target = 0x7251 ∧ fee.value = 0 ∧
    requestCall.kind = .call ∧ requestCall.target = 0x7251 ∧
    requestCall.value = 3 ∧ requestCall.calldata.length = 96)

#guard test_call_sites_are_source_shaped

/-- Authorization remains a pre-call guard in the handwritten bounded trace. -/
theorem test_unauthorized_caller_observes_no_external_calls
    (adversary : AdversaryModel) (state : CallState) :
    ObservedCalls (batchCalls 6 7 0x7251 3 [sourceKey] [targetKey]) adversary state = [] := by
  exact caller_guard_precedes_all_external_calls
    6 7 0x7251 3 [sourceKey] [targetKey] adversary state (by decide)

/-- Empty and mismatched arrays remain pre-call failures, preserving the OPEN
scaffold's honest separation from whole-transaction rollback. -/
theorem test_array_shape_mutants_observe_no_external_calls
    (adversary : AdversaryModel) (state : CallState) :
    ObservedCalls (batchCalls 7 7 0x7251 0 [] []) adversary state = [] ∧
      ObservedCalls (batchCalls 7 7 0x7251 3 [sourceKey] []) adversary state = [] := by
  constructor
  · exact array_shape_guards_precede_all_external_calls
      7 0x7251 0 [] [] adversary state (Or.inl rfl)
  · exact array_shape_guards_precede_all_external_calls
      7 0x7251 3 [sourceKey] [] adversary state (Or.inr (by decide))

/-- Keep both unproved adequacy boundaries explicit in the regression. -/
theorem test_open_scaffold_boundary_is_explicit :
    spec.fields = [] ∧
      addConsolidationRequests.localObligations.map
          (fun obligation => (obligation.name, obligation.proofStatus)) =
        [("bytes_array_offsets_and_lengths", .unchecked),
         ("whole_transaction_rollback_after_prior_success", .unchecked)] := by
  native_decide

end LidoSRv3.Audit.Verity.Tests.ConsolidationFee
