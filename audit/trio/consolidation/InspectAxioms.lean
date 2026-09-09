import audit.trio.consolidation.Bus
import audit.trio.consolidation.Codec
import audit.trio.consolidation.Gateway
import LidoSRv3.Audit.Verity.TrioConsolidation.Correspondence
import LidoSRv3.Audit.Verity.TrioConsolidation.Memory

/-! Lane-local trust inspection. This is intentionally not wired into global Trust. -/

#print axioms audit.trio.consolidation.preparePairs_length
#print axioms audit.trio.consolidation.prepared_zip
#print axioms audit.trio.consolidation.validateVaultAdd_prepared
#print axioms audit.trio.consolidation.encodePackedRequest_length
#print axioms audit.trio.consolidation.encodePackedRequest_injective
#print axioms audit.trio.consolidation.pubkeyOctets_injective
#print axioms audit.trio.consolidation.integerBE48_collides_unbounded
#print axioms audit.trio.consolidation.pubkeyOctets_rejects_modulus_collision
#print axioms LidoSRv3.Audit.Source.TopupBeaconEffects.encode_decode_bytes
#print axioms audit.trio.consolidation.integerBE_as_bytes
#print axioms audit.trio.consolidation.pubkeyOctets_pubkeyOfBytes
#print axioms audit.trio.consolidation.distinct_raw_bytes_distinct_identities
#print axioms audit.trio.consolidation.wrap_encode_eq
#print axioms audit.trio.consolidation.encodePackedRequest_of_bytes
#print axioms audit.trio.consolidation.checkFee_additive
#print axioms audit.trio.consolidation.committed_vault_payloads
#print axioms audit.trio.consolidation.committed_payloads_are_packed
#print axioms audit.trio.consolidation.add_revert_restores
#print axioms audit.trio.consolidation.execute_revert_restores
#print axioms audit.trio.consolidation.execute_committed_deletes
#print axioms LidoSRv3.Audit.Verity.TrioConsolidation.Correspondence.zipRequests_prepared
#print axioms LidoSRv3.Audit.Verity.TrioConsolidation.Memory.decode_stateForGroups
#print axioms LidoSRv3.Audit.Verity.TrioConsolidation.Memory.grouped_tx_simulates
