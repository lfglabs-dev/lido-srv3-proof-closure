import LidoSRv3.Audit.Model.EthWorld

/-! # Kill-lines for `Model.EthWorld.CoveringParent.id`

**Chantier (Piste A, Thomas 2026-09-13) mutant kill-lines pinning
the Piste-A CoveringParent → registered guarantee-id string
projection. -/

namespace LidoSRv3.Tests.ModelEthWorldCoveringParentIdKillLines

open LidoSRv3.Audit.Model.EthWorld

/-- **Kill-line: `pTopupOne` maps to `"P-TOPUP-1"`.**

A mutant that swapped the id string (e.g. to P-DEPOSIT-1) would
collapse the two chantiers at the public registry. -/
theorem pTopupOne_id :
    CoveringParent.pTopupOne.id = "P-TOPUP-1" := rfl

/-- **Kill-line: `pDepositOne` maps to `"P-DEPOSIT-1"`.** -/
theorem pDepositOne_id :
    CoveringParent.pDepositOne.id = "P-DEPOSIT-1" := rfl

/-- **Kill-line: `pConsolidationEthOne` maps to `"P-CONSOLIDATION-ETH-1"`.** -/
theorem pConsolidationEthOne_id :
    CoveringParent.pConsolidationEthOne.id = "P-CONSOLIDATION-ETH-1" := rfl

/-- **Kill-line: `pConsolidationOne` maps to `"P-CONSOLIDATION-1"`.** -/
theorem pConsolidationOne_id :
    CoveringParent.pConsolidationOne.id = "P-CONSOLIDATION-1" := rfl

/-- **Kill-line: `pConsolidationValueOne` maps to `"P-CONSOLIDATION-VALUE-1"`.** -/
theorem pConsolidationValueOne_id :
    CoveringParent.pConsolidationValueOne.id = "P-CONSOLIDATION-VALUE-1" := rfl

/-- **Kill-line: `pVaultEthOne` maps to `"P-VAULT-ETH-1"`.** -/
theorem pVaultEthOne_id :
    CoveringParent.pVaultEthOne.id = "P-VAULT-ETH-1" := rfl

/-- **Kill-line: `pEthJournalOne` maps to `"P-ETH-JOURNAL-1"`.** -/
theorem pEthJournalOne_id :
    CoveringParent.pEthJournalOne.id = "P-ETH-JOURNAL-1" := rfl

/-- **Kill-line: distinct constructors yield distinct id strings.**

Any two id strings must differ; a mutant that collapsed two
guarantee ids would break the registry binding. -/
theorem covering_parent_ids_distinct :
    CoveringParent.pTopupOne.id ≠ CoveringParent.pDepositOne.id ∧
    CoveringParent.pTopupOne.id ≠ CoveringParent.pVaultEthOne.id ∧
    CoveringParent.pDepositOne.id ≠ CoveringParent.pEthJournalOne.id ∧
    CoveringParent.pConsolidationOne.id ≠ CoveringParent.pConsolidationEthOne.id := by
  refine ⟨?_, ?_, ?_, ?_⟩ <;> decide

/-- **Kill-line: constructors are pairwise distinct.** -/
theorem covering_parent_distinct_ctors :
    CoveringParent.pTopupOne ≠ CoveringParent.pDepositOne := by decide

#print axioms pTopupOne_id
#print axioms pDepositOne_id
#print axioms pVaultEthOne_id
#print axioms pEthJournalOne_id
#print axioms covering_parent_ids_distinct
#print axioms covering_parent_distinct_ctors

end LidoSRv3.Tests.ModelEthWorldCoveringParentIdKillLines
