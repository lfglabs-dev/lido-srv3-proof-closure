import audit.trio.consolidation.Bus
import LidoSRv3.Audit.Verity.TrioConsolidation.Correspondence

/-! Lane-local trust inspection. This is intentionally not wired into global Trust. -/

#print axioms audit.trio.consolidation.preparePairs_length
#print axioms audit.trio.consolidation.prepared_zip
#print axioms audit.trio.consolidation.validateVaultAdd_prepared
#print axioms audit.trio.consolidation.add_revert_restores
#print axioms audit.trio.consolidation.execute_revert_restores
#print axioms audit.trio.consolidation.execute_committed_deletes
#print axioms LidoSRv3.Audit.Verity.TrioConsolidation.Correspondence.zipRequests_prepared
