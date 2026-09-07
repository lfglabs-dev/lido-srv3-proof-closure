import LidoSRv3.Audit.Source.TrioReserve1.Queue
import LidoSRv3.Audit.Source.TrioReserve1.Erasure
import LidoSRv3.Audit.Source.TrioReserve1.PhysicalPacking
import LidoSRv3.Audit.Source.TrioReserve1.Writers
import LidoSRv3.Audit.Source.TrioReserve1.Allocation
import LidoSRv3.Audit.Source.TrioReserve1.Router
import LidoSRv3.Audit.Source.TrioReserve1.Locator
import LidoSRv3.Audit.Source.TrioReserve1.Transfers
import LidoSRv3.Audit.Source.TrioReserve1.Oracle
import LidoSRv3.Audit.Source.TrioReserve1.Consensus

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

#print axioms AllocationSpec.unique
#print axioms AllocationSpec.two_live_spends
#print axioms Allocation.success_corresponds
#print axioms Allocation.successful_queue_observation
#print axioms Router.source_rule
#print axioms Router.authorized_call
#print axioms Router.unauthorized_call
#print axioms Locator.queue_getter
#print axioms Locator.router_getter
#print axioms Locator.oracle_getter
#print axioms Transfers.conserves
#print axioms Transfers.self_transfer_balance
#print axioms Transfers.credit_bound_from_aggregate
#print axioms Erasure.call_nested_erasure
#print axioms StaticCall.state_change_rejected
#print axioms Oracle.timestamp_corresponds
#print axioms Oracle.frame_preserves
#print axioms Oracle.frame_success
#print axioms Consensus.compute_success
#print axioms FrameSpec.unique
