import LidoSRv3.Audit.Source.TrioReserve1.Queue
import LidoSRv3.Audit.Source.TrioReserve1.Erasure
import LidoSRv3.Audit.Source.TrioReserve1.PhysicalPacking
import LidoSRv3.Audit.Source.TrioReserve1.Writers

/-! Owned inspection, pending coordinated canonical Trust registration. -/
open LidoSRv3.Audit.Source.TrioReserve1
#print axioms Queue.unfinalized_corresponds
#print axioms Queue.cumulative_bound
#print axioms Erasure.erase_bind
#print axioms Erasure.erase_pure
#print axioms Erasure.erase_run
#print axioms Erasure.failure_restores_world
#print axioms Erasure.replacing_attempts_preserves_observables
#print axioms PhysicalPacking.pack_matches_bitwise
#print axioms PhysicalPacking.physical_low_bound
#print axioms PhysicalPacking.physical_high_bound
#print axioms PhysicalPacking.low_pack
#print axioms PhysicalPacking.high_pack

#print axioms Writers.target_corresponds
#print axioms Writers.rebalance_corresponds
#print axioms Writers.target_observations
#print axioms Writers.rebalance_observations
