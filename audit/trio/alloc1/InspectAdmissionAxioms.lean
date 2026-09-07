import LidoSRv3.Audit.Source.TrioAlloc1.ProxyGenesis
import LidoSRv3.Audit.Source.TrioAlloc1.Initialization

-- Init-only inspection; the complete Verity/trust driver remains remote-only.
#print axioms LidoSRv3.Audit.Source.TrioAlloc1.AdmissionFacts.success_witness
#print axioms LidoSRv3.Audit.Source.TrioAlloc1.AdmissionFacts.success_stored_share
#print axioms LidoSRv3.Audit.Source.TrioAlloc1.AdmissionFacts.success_count_bound
#print axioms LidoSRv3.Audit.Source.TrioAlloc1.AdmissionFacts.successful_record_freshness
#print axioms LidoSRv3.Audit.Source.TrioAlloc1.AdmissionFacts.public_preserves

#print axioms LidoSRv3.Audit.Source.TrioAlloc1.RecordInvariant.history_invariants

#print axioms LidoSRv3.Audit.Source.TrioAlloc1.StatusWriter.history_invariants
#print axioms LidoSRv3.Audit.Source.TrioAlloc1.StatusWriter.revert_restores

#print axioms LidoSRv3.Audit.Source.TrioAlloc1.ACLWriter.grant_preserves
#print axioms LidoSRv3.Audit.Source.TrioAlloc1.ACLWriter.grant_hasRole
#print axioms LidoSRv3.Audit.Source.TrioAlloc1.ACLWriter.grant_revert_restores

#print axioms LidoSRv3.Audit.Source.TrioAlloc1.Initialization.revert_restores
#print axioms LidoSRv3.Audit.Source.TrioAlloc1.Initialization.execute_from_empty

#print axioms LidoSRv3.Audit.Source.TrioAlloc1.Initialization.execute_records

#print axioms LidoSRv3.Audit.Source.TrioAlloc1.ProxyGenesis.initialization_invariants
