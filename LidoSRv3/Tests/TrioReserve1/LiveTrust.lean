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
import LidoSRv3.Audit.Source.TrioReserve1.ConsensusCalls
import LidoSRv3.Audit.Source.TrioReserve1.Pipeline
import LidoSRv3.Audit.Source.TrioReserve1.PhysicalReserve
import LidoSRv3.Audit.Source.TrioReserve1.PhysicalSequence

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

#print axioms ConsensusCalls.compute_bounds
#print axioms ConsensusCalls.static_success
#print axioms ConsensusCalls.static_rejection
#print axioms ConsensusCalls.decode_reference
#print axioms ConsensusCalls.oracle_frame
#print axioms ConsensusCalls.oracle_rejection
#print axioms ConsensusCalls.oracle_overflow
#print axioms ConsensusCalls.oracle_no_code
#print axioms ConsensusCalls.independent_rules
#print axioms ConsensusCalls.lido_frame

#print axioms Pipeline.read_other_slot
#print axioms Pipeline.prepared_locator
#print axioms Pipeline.prepared_consensus
#print axioms Pipeline.frame_result
#print axioms Pipeline.status_result
#print axioms Pipeline.router_result
#print axioms Pipeline.allocation_result
#print axioms Pipeline.before_tail
#print axioms Pipeline.seed_result
#print axioms Pipeline.final_code
#print axioms Pipeline.final_balances
#print axioms Pipeline.receiver
#print axioms Pipeline.receiver_rejection
#print axioms Pipeline.receiver_shortage
#print axioms Pipeline.success
#print axioms Pipeline.rejected
#print axioms Pipeline.shortage

#print axioms PhysicalReserve.committed_fields
#print axioms PhysicalReserve.admitted
#print axioms PhysicalReserve.committed_protection
#print axioms PhysicalReserve.committed_other_account
#print axioms PhysicalReserve.committed_queue
#print axioms PhysicalReserve.success_preserves

#print axioms SequenceSpec.target_protection
#print axioms SequenceSpec.rebalance_partition
#print axioms PhysicalSequence.committed_step
#print axioms PhysicalSequence.corresponds
#print axioms PhysicalSequence.target_protection
#print axioms PhysicalSequence.rebalance_partition
#print axioms PhysicalSequence.other_account
#print axioms PhysicalSequence.queue_preserved
#print axioms PhysicalSequence.concrete_success_step
