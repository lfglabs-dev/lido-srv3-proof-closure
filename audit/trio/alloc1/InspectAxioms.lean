import LidoSRv3.Audit.Source.TrioAlloc1.CapacitySpec
import LidoSRv3.Audit.Source.TrioAlloc1.Memory
import LidoSRv3.Audit.Source.TrioAlloc1.Determinism
import LidoSRv3.Audit.Source.TrioAlloc1.ShareWriter
import LidoSRv3.Audit.Source.TrioAlloc1.WriterInvariant
import LidoSRv3.Audit.Source.TrioAlloc1.AdmissionChecks
import LidoSRv3.Audit.Source.TrioAlloc1.EnumerationWriter
import LidoSRv3.Audit.Source.TrioAlloc1.AdmissionWriter
import LidoSRv3.Audit.Source.TrioAlloc1.AdmissionFacts
import LidoSRv3.Audit.Source.TrioAlloc1.AllocationMemory
import LidoSRv3.Audit.Source.TrioAlloc1.VerityProducer
import LidoSRv3.Tests.TrioAlloc1.Correspondence

#print axioms LidoSRv3.Audit.Source.TrioAlloc1.producer_router_order
#print axioms LidoSRv3.Audit.Source.TrioAlloc1.producer_total_bound
#print axioms LidoSRv3.Audit.Source.TrioAlloc1.outputBytes_related
#print axioms LidoSRv3.Audit.Source.TrioAlloc1.Relational.producer_iff
#print axioms LidoSRv3.Audit.Source.TrioAlloc1.CallTree.producer_correspondence
#print axioms LidoSRv3.Audit.Source.TrioAlloc1.VerityProducer.world_producer_correspondence
#print axioms LidoSRv3.Audit.Source.TrioAlloc1.ShareWriter.execute_revert_restores
#print axioms LidoSRv3.Audit.Source.TrioAlloc1.ShareWriter.execute_stored_share_bound
#print axioms LidoSRv3.Audit.Source.TrioAlloc1.WriterInvariant.share_writer_preserves
#print axioms LidoSRv3.Audit.Source.TrioAlloc1.WriterInvariant.parameter_writer_preserves
#print axioms LidoSRv3.Audit.Source.TrioAlloc1.ParameterWriter.helper_stored_share_bound
#print axioms LidoSRv3.Audit.Source.TrioAlloc1.ParameterWriter.execute_revert_restores
#print axioms LidoSRv3.Audit.Source.TrioAlloc1.AdmissionChecks.check_success
#print axioms LidoSRv3.Audit.Source.TrioAlloc1.AdmissionChecks.nextId_success
#print axioms LidoSRv3.Audit.Source.TrioAlloc1.AdmissionWriter.revert_restores
#print axioms LidoSRv3.Audit.Source.TrioAlloc1.AdmissionFacts.success_stored_share
#print axioms LidoSRv3.Audit.Source.TrioAlloc1.AdmissionFacts.public_preserves
#print axioms LidoSRv3.Audit.Source.TrioAlloc1.AdmissionWriter.successful_entry_bound_and_freshness
#print axioms LidoSRv3.Audit.Source.TrioAlloc1.StringStorage.writeShort_stored
#print axioms LidoSRv3.Audit.Source.TrioAlloc1.EnumerationWriter.insertion_preserves_consistency
#print axioms LidoSRv3.Audit.Source.TrioAlloc1.EnumerationWriter.oversized_absent
#print axioms LidoSRv3.Audit.Source.TrioAlloc1.AllocationMemory.bounded_array_allocates
#print axioms LidoSRv3.Tests.TrioAlloc1.prefetch_trace_refutes_relational_parent
#print axioms LidoSRv3.Tests.TrioAlloc1.target_only_refutes_relational_parent
