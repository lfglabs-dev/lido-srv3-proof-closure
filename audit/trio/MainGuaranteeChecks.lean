import LidoSRv3.Audit.Verity.AllocationTx
import LidoSRv3.Audit.Source.TrioComposition.CacheStores
import LidoSRv3.Audit.Source.TrioAlloc1.CapacitySpec
import LidoSRv3.Audit.Source.TrioAlloc1.Determinism
import LidoSRv3.Audit.Source.TrioAlloc1.VerityProducer
import LidoSRv3.Audit.Source.TrioComposition.FinalMemoryStoredParent
import LidoSRv3.Audit.Source.TrioComposition.FinalMemoryStoredProducer
import LidoSRv3.Audit.Source.TrioComposition.ReserveLeafSpend
import LidoSRv3.Audit.Source.TrioComposition.VerityParent
import LidoSRv3.Audit.Source.TrioReserve1.PhysicalReserve
import LidoSRv3.Audit.Source.TrioReserve1.WithdrawalSpec

/-! Trust inspection of the registered main source-model results. -/

#print axioms LidoSRv3.Audit.Source.TrioAlloc1.Relational.producer_iff
#print axioms LidoSRv3.Audit.Source.TrioAlloc1.producer_math_view
#print axioms LidoSRv3.Audit.Source.TrioComposition.FinalMemoryStoredProducer.success
#print axioms LidoSRv3.Audit.Source.TrioAlloc1.VerityProducer.world_producer_correspondence
#print axioms LidoSRv3.Audit.Source.TrioComposition.FinalMemoryStoredParent.public_iff
#print axioms LidoSRv3.Audit.Source.TrioComposition.FinalMemoryStoredParent.success
#print axioms LidoSRv3.Audit.Source.TrioComposition.VerityParent.stored_correspondence
#print axioms LidoSRv3.Audit.Source.TrioReserve1.PhysicalReserve.success_preserves
#print axioms LidoSRv3.Audit.Source.TrioComposition.ReserveLeafSpend.withdrawal_corresponds
#print axioms LidoSRv3.Audit.Source.TrioReserve1.WithdrawalSpec.failure_restores

#print axioms LidoSRv3.Audit.Verity.AllocationTx.live_injected_after_writes_rolls_back
