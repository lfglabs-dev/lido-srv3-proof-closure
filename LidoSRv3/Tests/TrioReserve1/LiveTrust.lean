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
import LidoSRv3.Audit.Source.TrioReserve1.Admission
import LidoSRv3.Audit.Source.TrioReserve1.ABI
import LidoSRv3.Audit.Source.TrioReserve1.CallResults
import LidoSRv3.Audit.Source.TrioReserve1.WithdrawalTail
import LidoSRv3.Audit.Source.TrioReserve1.WithdrawalComposition
import LidoSRv3.Audit.Source.TrioReserve1.OracleCalls

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
#print axioms Admission.live_status
#print axioms Admission.live_status_false
#print axioms Admission.success_corresponds
#print axioms Admission.status_failure_stops
#print axioms Admission.cannot_deposit_stops
#print axioms Admission.router_failure_stops
#print axioms Admission.unauthorized_stops
#print axioms Admission.zero_amount_stops

#print axioms ABI.decode_encode
#print axioms ABI.decode_encode_bounded
#print axioms ABI.decode_word
#print axioms ABI.decode_second_word

#print axioms CallResults.locator_reply
#print axioms CallResults.queue_lookup
#print axioms CallResults.frame_reply
#print axioms CallResults.adjusted_frame
#print axioms CallResults.frame_call_failure
#print axioms CallResults.frame_short_reply
#print axioms WithdrawalTail.source_decomposition
#print axioms WithdrawalTail.seeds_zero
#print axioms WithdrawalTail.seeds_success
#print axioms WithdrawalTail.seeds_overflow
#print axioms WithdrawalTail.actual_receiver
#print axioms WithdrawalTail.finish_rejection
#print axioms WithdrawalTail.seed_failure_stops
#print axioms WithdrawalTail.after_spend
#print axioms WithdrawalTail.tail_failure_rolls_back

#print axioms SpendingSpec.admitted_bound
#print axioms SpendingSpec.accounting_corresponds
#print axioms Spending.allocation_bounds
#print axioms Spending.accounting_add_bound
#print axioms Spending.adjusted_next_bound
#print axioms Spending.success_world
#print axioms Spending.success_corresponds
#print axioms Spending.allocation_failure
#print axioms Spending.insufficient
#print axioms Spending.frame_failure
#print axioms WithdrawalComposition.after_frame
#print axioms WithdrawalComposition.late_failure
#print axioms WithdrawalComposition.spending_failure

#print axioms CallResults.router_lookup
#print axioms CallResults.oracle_lookup
#print axioms QueueCalls.bunker_call
#print axioms QueueCalls.status
#print axioms QueueCalls.demand_call
#print axioms QueueCalls.demand_panic
#print axioms QueueCalls.demand_bound
#print axioms QueueCalls.allocation_success
#print axioms QueueCalls.allocation_panic
#print axioms QueueCalls.live_allocation_spec
#print axioms OracleCalls.frame_call
#print axioms OracleCalls.frame_rejection
#print axioms OracleCalls.current_frame
#print axioms OracleCalls.current_frame_rejection
