import LidoSRv3.Audit.Source.TrioReserve1.ReportRules
import LidoSRv3.Audit.Source.TrioReserve1.ReportCalls
import LidoSRv3.Audit.Source.TrioReserve1.ReportParent
import LidoSRv3.Audit.Source.TrioReserve1.ReportAccounting
import LidoSRv3.Audit.Source.TrioReserve1.Report
import LidoSRv3.Audit.Source.TrioReserve1.AuthorizationBalance
import LidoSRv3.Audit.Source.TrioReserve1.WithdrawalBalance
import LidoSRv3.Audit.Source.TrioReserve1.CalleeBalance
import LidoSRv3.Audit.Source.TrioReserve1.Balance
import LidoSRv3.Audit.Source.TrioReserve1.WithdrawalCalls
import LidoSRv3.Audit.Source.TrioReserve1.CallFlow
import LidoSRv3.Audit.Source.TrioReserve1.AllocationFlow
import LidoSRv3.Audit.Source.TrioReserve1.FrameRead
import LidoSRv3.Audit.Source.TrioReserve1.Spend
import LidoSRv3.Audit.Source.TrioReserve1.Tail
import LidoSRv3.Audit.Source.TrioReserve1.Lookup
import LidoSRv3.Audit.Source.TrioReserve1.Status
import LidoSRv3.Audit.Source.TrioReserve1.WithdrawalParent
import LidoSRv3.Audit.Source.TrioReserve1.Target
import LidoSRv3.Audit.Source.TrioReserve1.ACLPermission
import LidoSRv3.Audit.Source.TrioReserve1.ACLLeaf
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
import LidoSRv3.Audit.Source.TrioReserve1.Aragon
import LidoSRv3.Audit.Source.TrioReserve1.Kernel
import LidoSRv3.Audit.Source.TrioReserve1.ACLCalls
import LidoSRv3.Audit.Source.TrioReserve1.ACLBounds
import LidoSRv3.Audit.Source.TrioReserve1.ACLLogic
import LidoSRv3.Audit.Source.TrioReserve1.ACLTree

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

#print axioms AragonSpec.exclusive
#print axioms Aragon.prefix_corresponds
#print axioms Aragon.uninitialized
#print axioms Aragon.absent_kernel
#print axioms Aragon.kernel_reply
#print axioms Aragon.kernel_rejection
#print axioms Aragon.kernel_no_code
#print axioms Aragon.kernel_short_reply
#print axioms Aragon.denied
#print axioms Aragon.permission_failure
#print axioms Aragon.allowed
#print axioms Aragon.target_from_kernel_reply

#print axioms Kernel.no_acl
#print axioms Kernel.no_acl_code
#print axioms Kernel.acl_rejection
#print axioms Kernel.decoded_word
#print axioms Kernel.acl_reply
#print axioms Kernel.aragon_from_acl
#print axioms Kernel.target_from_acl

#print axioms Kernel.acl_reply_traced
#print axioms Kernel.aragon_from_acl_traced
#print axioms ACL.compare_corresponds
#print axioms ACL.no_permission
#print axioms ACL.unconditional_specific
#print axioms ACL.unconditional_wildcard
#print axioms ACL.oracle_rejection_is_false
#print axioms ACL.oracle_wrong_size_is_false
#print axioms ACL.grants_corresponds
#print axioms ACLCalls.canPerform
#print axioms ACLCalls.unconditional_specific

#print axioms ACLBounds.bind_extends
#print axioms ACLBounds.eval_succ
#print axioms ACLBounds.eval_mono
#print axioms ACLBounds.permission_mono
#print axioms ACLBounds.dispatch_stable
#print axioms ACLBounds.eval_unique
#print axioms ACLBounds.permission_unique

#print axioms ACLLogicSpec.exists_route
#print axioms ACLLogicSpec.unique
#print axioms ACLLogic.corresponds
#print axioms ACLLogic.out_of_bounds
#print axioms ACLLogic.invalid_before_children
#print axioms ACLLogic.first_failure

#print axioms ACLTree.of_spec
#print axioms ACLTree.of_spec_stable
#print axioms ACLTree.derivations_agree
#print axioms ACLTree.to_spec
#print axioms ACLTree.corresponds

#print axioms ACLLeafSpec.input_exists
#print axioms ACLLeaf.finish_corresponds
#print axioms ACLLeaf.input_source
#print axioms ACLLeaf.nonoracle_corresponds
#print axioms ACLLeaf.oracle_reply_source
#print axioms ACLLeaf.oracle_corresponds
#print axioms ACLLeaf.describes_source
#print axioms ACLLeaf.describes_complete
#print axioms ACLLeaf.tree_corresponds

#print axioms ACLPermission.attempt_of_spec
#print axioms ACLPermission.attempt_to_spec
#print axioms ACLPermission.attempt_lift
#print axioms ACLPermission.selection_source
#print axioms ACLPermission.of_spec
#print axioms ACLPermission.to_spec
#print axioms ACLPermission.corresponds
#print axioms ACLPermission.of_spec_stable
#print axioms ACLPermission.canPerform_traced
#print axioms ACLPermission.target_allowed
#print axioms ACLPermission.target_denied

#print axioms Target.writer_success
#print axioms Target.accounting
#print axioms Target.balances
#print axioms Target.other_slot
#print axioms Target.other_account
#print axioms Target.success
#print axioms Target.queue_preserved
#print axioms Target.sequence_step

#print axioms Target.after_authorization
#print axioms Target.complete
#print axioms Target.prefix_denied
#print axioms Target.kernel_no_code

#print axioms WithdrawalSpec.failure_restores
#print axioms WithdrawalSpec.success_nonzero
#print axioms WithdrawalParent.of_spec
#print axioms WithdrawalParent.exists_spec
#print axioms WithdrawalParent.to_spec
#print axioms WithdrawalParent.corresponds
#print axioms WithdrawalParent.complete

#print axioms Status.of_spec
#print axioms Status.exists_spec
#print axioms Status.to_spec
#print axioms Status.corresponds
#print axioms Status.withdrawal_denied
#print axioms Status.withdrawal_failure
#print axioms Status.withdrawal_corresponds

#print axioms Lookup.address_narrowing
#print axioms Lookup.of_spec
#print axioms Lookup.exists_spec
#print axioms Lookup.to_spec
#print axioms Lookup.corresponds
#print axioms Lookup.status_corresponds
#print axioms Lookup.withdrawal_corresponds

#print axioms Tail.seed_source
#print axioms Tail.seed_exists
#print axioms Tail.of_spec
#print axioms Tail.exists_spec
#print axioms Tail.to_spec
#print axioms Tail.corresponds
#print axioms Tail.withdrawal_corresponds

#print axioms Spend.frame_failed
#print axioms Spend.of_spec
#print axioms Spend.exists_spec
#print axioms Spend.to_spec
#print axioms Spend.corresponds
#print axioms Spend.withdrawal_corresponds

#print axioms FrameRead.of_spec
#print axioms FrameRead.exists_spec
#print axioms FrameRead.to_spec
#print axioms FrameRead.corresponds
#print axioms FrameRead.spending_corresponds
#print axioms FrameRead.withdrawal_corresponds

#print axioms AllocationFlow.allocation_spec
#print axioms AllocationFlow.allocation_unique
#print axioms AllocationFlow.of_spec
#print axioms AllocationFlow.exists_spec
#print axioms AllocationFlow.to_spec
#print axioms AllocationFlow.corresponds
#print axioms AllocationFlow.spending_corresponds
#print axioms AllocationFlow.withdrawal_corresponds

#print axioms CallSpec.failure_restores
#print axioms CallSpec.success_funded
#print axioms CallFlow.transfer_balances
#print axioms CallFlow.transfer_frame
#print axioms CallFlow.of_spec
#print axioms CallFlow.exists_spec
#print axioms CallFlow.to_spec
#print axioms CallFlow.corresponds

#print axioms WithdrawalCalls.call_observations
#print axioms WithdrawalCalls.corresponds
#print axioms WithdrawalCalls.complete
#print axioms WithdrawalCalls.failure_restores
#print axioms WithdrawalCalls.success_nonzero

#print axioms BalanceSpec.member_bound
#print axioms BalanceSpec.account_bound
#print axioms BalanceSpec.mass_equation
#print axioms BalanceSpec.include_member
#print axioms BalanceSpec.include_retains
#print axioms BalanceSpec.include_bounded
#print axioms BalanceSpec.preserves
#print axioms Balance.transfer_preserves
#print axioms Balance.transfer_uint256
#print axioms Balance.transfer_finite
#print axioms Balance.transfer_finite_uint256

#print axioms CalleeBalance.locator
#print axioms CalleeBalance.queue
#print axioms CalleeBalance.router
#print axioms CalleeBalance.oracle_frame
#print axioms CalleeBalance.oracle
#print axioms CalleeBalance.pipeline
#print axioms CalleeBalance.call_conserves
#print axioms CalleeBalance.call_uint256
#print axioms CalleeBalance.pipeline_call_uint256

#print axioms WithdrawalBalance.unchanged
#print axioms WithdrawalBalance.bind_preserves
#print axioms WithdrawalBalance.call_preserves
#print axioms WithdrawalBalance.withdrawal
#print axioms WithdrawalBalance.root_preserves
#print axioms WithdrawalBalance.withdrawal_uint256
#print axioms WithdrawalBalance.pipeline_withdrawal
#print axioms WithdrawalBalance.target
#print axioms WithdrawalBalance.rebalance

#print axioms AuthorizationBalance.acl
#print axioms AuthorizationBalance.decoded
#print axioms AuthorizationBalance.kernel_permission
#print axioms AuthorizationBalance.kernel
#print axioms AuthorizationBalance.external
#print axioms AuthorizationBalance.permission_call
#print axioms AuthorizationBalance.can_perform
#print axioms AuthorizationBalance.set_target
#print axioms AuthorizationBalance.concrete_target

#print axioms CallData.selector_call
#print axioms Report.stopped

#print axioms ReportAccountingSpec.total
#print axioms ReportAccountingSpec.unique
#print axioms ReportAccountingSpec.success_bound
#print axioms ReportAccounting.of_spec
#print axioms ReportAccounting.exists_spec
#print axioms ReportAccounting.corresponds
#print axioms ReportAccounting.complete
#print axioms ReportAccounting.failure_restores
#print axioms ReportAccounting.committed_balances

#print axioms ReportStages.source_decomposition
#print axioms ReportSpec.failure_restores
#print axioms ReportSpec.success_active
#print axioms ReportParent.accounting_observations
#print axioms ReportParent.of_spec
#print axioms ReportParent.exists_spec
#print axioms ReportParent.to_spec
#print axioms ReportParent.corresponds
#print axioms ReportParent.complete
#print axioms ReportParent.failure_restores

#print axioms ReportCalls.of_spec
#print axioms ReportCalls.exists_spec
#print axioms ReportCalls.corresponds
#print axioms ReportCalls.rewards_corresponds
#print axioms ReportCalls.withdrawals_corresponds
#print axioms ReportCalls.finalize_corresponds
#print axioms ReportCalls.parent_corresponds
#print axioms ReportCalls.complete
#print axioms ReportCalls.failure_restores

#print axioms CallDataFlow.of_spec
#print axioms CallDataFlow.exists_spec
#print axioms CallDataFlow.to_spec
#print axioms CallDataFlow.corresponds
#print axioms ReportLookup.getter_observations
#print axioms ReportLookup.of_spec
#print axioms ReportLookup.exists_spec
#print axioms ReportLookup.corresponds
#print axioms ReportRules.lookup_observations
#print axioms ReportRules.call_observations
#print axioms ReportRules.stage_observations
#print axioms ReportRules.corresponds
#print axioms ReportRules.complete
#print axioms ReportRules.failure_restores
#print axioms ReportRules.success_active
