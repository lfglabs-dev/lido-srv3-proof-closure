import audit.trio.consolidation.Bus
import audit.trio.consolidation.Codec
import audit.trio.consolidation.Gateway
import audit.trio.consolidation.LiveCall
import audit.trio.consolidation.Producer
import audit.trio.consolidation.SourceExecution
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
#print axioms audit.trio.consolidation.encode_decode_raw48
#print axioms audit.trio.consolidation.encode_decode_Raw48
#print axioms audit.trio.consolidation.leading_zero_mutant
#print axioms audit.trio.consolidation.endian_mutant
#print axioms audit.trio.consolidation.raw48_nat_injective
#print axioms audit.trio.consolidation.decode_encode_bytes_element
#print axioms audit.trio.consolidation.preparePairs_of_producer
#print axioms audit.trio.consolidation.widthOk_source_is_raw48
#print axioms audit.trio.consolidation.widthOk_target_is_raw48
#print axioms audit.trio.consolidation.widthOk_payload_length
#print axioms audit.trio.consolidation.vaultCallPayload_is_packed
#print axioms audit.trio.consolidation.vaultCallPayload_is_packed_byteArray
#print axioms audit.trio.consolidation.hopRequest_is_packed
#print axioms audit.trio.consolidation.callAdd_attempt_request
#print axioms audit.trio.consolidation.callAdd_fault
#print axioms audit.trio.consolidation.callAdd_error_restores
#print axioms audit.trio.consolidation.callAdd_success
#print axioms audit.trio.consolidation.callAdd_success_funded
#print axioms audit.trio.consolidation.callAdd_no_code
#print axioms audit.trio.consolidation.callAdd_unfunded
#print axioms audit.trio.consolidation.callAdd_rejected
#print axioms audit.trio.consolidation.callAdd_accepted
#print axioms audit.trio.consolidation.callAdd_credited_balances
#print axioms audit.trio.consolidation.loop_success
#print axioms audit.trio.consolidation.loop_attempt_request
#print axioms audit.trio.consolidation.loop_success_frame
#print axioms audit.trio.consolidation.executeVault_failure_restores
#print axioms audit.trio.consolidation.executeVault_success_body
#print axioms audit.trio.consolidation.executeVault_success
#print axioms audit.trio.consolidation.executeVault_success_frame
#print axioms audit.trio.consolidation.resolveAddress_val
#print axioms audit.trio.consolidation.refund_zero
#print axioms audit.trio.consolidation.refund_attempt_request
#print axioms audit.trio.consolidation.refund_error_restores
#print axioms audit.trio.consolidation.refund_rejected
#print axioms audit.trio.consolidation.refund_accepted
#print axioms audit.trio.consolidation.refund_value_split
#print axioms audit.trio.consolidation.refund_request_is_hop
#print axioms audit.trio.consolidation.checkFee_additive
#print axioms audit.trio.consolidation.committed_vault_payloads
#print axioms audit.trio.consolidation.committed_payloads_are_packed
#print axioms audit.trio.consolidation.add_revert_restores
#print axioms audit.trio.consolidation.execute_revert_restores
#print axioms audit.trio.consolidation.execute_committed_deletes
#print axioms LidoSRv3.Audit.Verity.TrioConsolidation.Correspondence.zipRequests_prepared
#print axioms LidoSRv3.Audit.Verity.TrioConsolidation.Memory.decode_stateForGroups
#print axioms LidoSRv3.Audit.Verity.TrioConsolidation.Memory.grouped_tx_simulates
