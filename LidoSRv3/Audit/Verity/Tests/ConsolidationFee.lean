import LidoSRv3.Audit.Verity.ConsolidationFee

namespace LidoSRv3.Audit.Verity.Tests.ConsolidationFee

open LidoSRv3.Audit.Guarantees.PConsolidation1
open LidoSRv3.Audit.Verity.ConsolidationFee

def requests : List ConsolidationRequest :=
  [{ sourcePubkey := 11, targetPubkey := 21 },
   { sourcePubkey := 12, targetPubkey := 22 }]

def registry : ValidatorRegistry :=
  { prepaidBalance := 10
    pubkeyMapping := [(11, 101), (12, 102), (21, 201), (22, 202)] }

theorem test_consolidate_fee_debits_correctly :
    runConsolidation registry requests 3 =
      some { registry with prepaidBalance := 4 } ∧
    runConsolidation registry requests 2 ≠
      some { registry with prepaidBalance := 4 } := by
  native_decide

theorem test_consolidate_insufficient_balance_reverts :
    runConsolidation { registry with prepaidBalance := 5 } requests 3 = none ∧
    runConsolidation { registry with prepaidBalance := 6 } requests 3 ≠ none := by
  native_decide

theorem test_consolidate_rollback_preserves_state :
    consolidation_reverted registry registry ∧
    ¬ consolidation_reverted { registry with prepaidBalance := 4 } registry := by
  simp [consolidation_reverted, registry]

theorem test_consolidate_pubkey_mapping_preserved :
    pubkey_mapping_preserved registry
      { registry with prepaidBalance := 4 } requests ∧
    ¬ pubkey_mapping_preserved registry
      { registry with pubkeyMapping := [(11, 999)] } requests := by
  simp [pubkey_mapping_preserved, mapping_invariant, registry]

end LidoSRv3.Audit.Verity.Tests.ConsolidationFee
