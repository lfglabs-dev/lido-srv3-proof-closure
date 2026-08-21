import LidoSRv3.Audit.Allocation
import LidoSRv3.Audit.StrategyProofs
import LidoSRv3.Audit.Common.Atomicity
import LidoSRv3.Audit.Common.Bounded
import LidoSRv3.Audit.Guarantees.PAlloc1
import LidoSRv3.Audit.Guarantees.PAlloc1Phase3
import LidoSRv3.Audit.Guarantees.PAlloc2
import LidoSRv3.Audit.Guarantees.PAlloc1EugeneBound
import LidoSRv3.Audit.Guarantees.PAccount1
import LidoSRv3.Audit.Verity.HandleOracleReportTx
import LidoSRv3.Tests.HandleOracleReportTxMutants
import LidoSRv3.Audit.Guarantees.PAddress1
import LidoSRv3.Audit.Verity.AddressAdmission
import LidoSRv3.Audit.Verity.ConsolidationCallFragment
import LidoSRv3.Audit.Guarantees.PConsolidation1
import LidoSRv3.Audit.Verity.ConsolidationTx
import LidoSRv3.Tests.ConsolidationTxMutants
import LidoSRv3.Audit.Guarantees.PDeposit1
import LidoSRv3.Audit.Guarantees.PEth1
import LidoSRv3.Audit.Verity.PEth1RefundTx
import LidoSRv3.Audit.Verity.PEth1RequestTx
import LidoSRv3.Tests.PEth1RefundTxMutants
import LidoSRv3.Tests.PEth1RequestTxMutants
import LidoSRv3.Tests.PEth1CompositionTxMutants
import LidoSRv3.Audit.Guarantees.PSsz1
import LidoSRv3.Audit.Verity.SszEncodingTx
import LidoSRv3.Tests.SszEncodingTxMutants
import LidoSRv3.Audit.Source.GIndexConcatCorrespondence
import LidoSRv3.Audit.Guarantees.PTopup1
import LidoSRv3.Tests.TopupTxMutants
import LidoSRv3.Audit.Guarantees.PTopup2
import LidoSRv3.Audit.Verity.Topup2Tx
import LidoSRv3.Tests.Topup2TxMutants
import LidoSRv3.Audit.Guarantees.PReserve1
import LidoSRv3.Audit.Guarantees.PReserveRelational
import LidoSRv3.Audit.Guarantees.PReserveRelationalVerity
import LidoSRv3.Tests.ReserveRelationalTxMutants
import LidoSRv3.Tests.DepositTxMutants
import LidoSRv3.Tests.DepositParentTxMutants
import LidoSRv3.Tests.MinFirstAmountTxMutants
import LidoSRv3.Tests.MinFirstDistributionTxMutants
import LidoSRv3.Audit.Verity.AllocationTx
import LidoSRv3.Tests.AllocationTxMutants
import LidoSRv3.Tests.AddressSourceMutants
import LidoSRv3.Audit.Verity.Tests.SszTxSimulation

/-!
Machine-readable-in-build trust report for the first audit slice.

## Allowed axioms

Every theorem printed below may depend only on the three Lean foundational
axioms `propext`, `Classical.choice`, and `Quot.sound`.

`Classical.choice` is an **accepted** dependency, disclosed in
`audit/assumptions.yaml` as `A-CLASSICAL-CHOICE`: it is a standard Lean 4 /
Mathlib axiom discharged by the kernel, it makes the development classical
rather than constructive, and no project-specific claim rests on it.  It is
named here rather than folded silently into "Lean foundations" so that a
reviewer reading this report sees the same three-axiom boundary that the
assurance metadata records.

Anything outside those three is a proof escape and is *not* accepted.  In
particular `sorryAx`, `Lean.ofReduceBool`, and any project-introduced `axiom`
must not appear in the output below.  The single disclosed exception is the
canonical P-ALLOC-1 Phase-3 compilation theorems, which additionally report the
generated `consumed_summary_function_spec_compiles._native.native_decide.ax_1_1`
dependency recorded in the target manifest.

Subject to that one recorded exception, there are no undisclosed project-level
assumptions or proof escapes.
-/

#print axioms LidoSRv3.Audit.Quantity.checkedDiv_zero
#print axioms LidoSRv3.Audit.Quantity.saturatingSub_zero_of_le
#print axioms LidoSRv3.Audit.revert_restores_state_value_and_logs
#print axioms LidoSRv3.Audit.revert_may_retain_attempts
#print axioms LidoSRv3.Audit.valid_result_preserves_router_order
#print axioms LidoSRv3.Audit.Guarantees.PAlloc1.checked_execute
#print axioms LidoSRv3.Audit.Guarantees.PAlloc1.active_capacity_bounded
#print axioms LidoSRv3.Audit.Guarantees.PAlloc1.source_capacities_match_canonical
#print axioms LidoSRv3.Audit.Guarantees.PAlloc1.source_capacities_and_mapped_summary_transaction
#print axioms LidoSRv3.Audit.Guarantees.PAlloc1.verity_tx_simulates_allocation
#print axioms LidoSRv3.Audit.Guarantees.PAlloc1.verity_tx_revert_restores_snapshot
#print axioms LidoSRv3.Audit.Verity.AllocationTx.revert_restores_snapshot
#print axioms LidoSRv3.Audit.Guarantees.PAlloc1.router_order_preserved
#print axioms LidoSRv3.Audit.Guarantees.PAlloc1Phase3.mapped_summary_call_transaction
#print axioms LidoSRv3.Audit.Guarantees.PAlloc2.selects_least_open_bucket
#print axioms LidoSRv3.Audit.Guarantees.PAlloc2.verity_tx_simulates_min_first_distribution
#print axioms LidoSRv3.Audit.Verity.MinFirstDistributionTx.revert_restores_snapshot
#print axioms LidoSRv3.Audit.Guarantees.PAlloc2.source_selects_same_next_target
#print axioms LidoSRv3.Audit.Guarantees.PAlloc2.full_candidate_correspondence
#print axioms LidoSRv3.Audit.Guarantees.PAlloc2.source_amount_correspondence
#print axioms LidoSRv3.Audit.Guarantees.PAlloc2.source_pinned_expression_shape
#print axioms LidoSRv3.Audit.Guarantees.PAlloc2.source_amount_totality
#print axioms LidoSRv3.Audit.Guarantees.PAlloc2.proportional_step_correspondence_and_bounded
#print axioms LidoSRv3.Audit.Guarantees.PAlloc2.forall_proportional_step_correspondence_and_bounded
#print axioms LidoSRv3.Audit.Guarantees.PAlloc2.tx_step_matches_source
#print axioms LidoSRv3.Audit.Guarantees.PAlloc2.tx_step_is_safe
#print axioms LidoSRv3.Audit.Guarantees.PAlloc2.tx_revert_restores_snapshot
#print axioms LidoSRv3.Audit.Guarantees.PAlloc1EugeneBound.checked_amount_le_bond
#print axioms LidoSRv3.Audit.Guarantees.PAlloc1EugeneBound.operator_reward_share_le_configured_bond
#print axioms LidoSRv3.Audit.MinFirstAllocation.Model.success_conservation
#print axioms LidoSRv3.Audit.MinFirstAllocation.Model.success_capacity
#print axioms LidoSRv3.Audit.MinFirstAllocation.Model.failure_rolls_back
#print axioms LidoSRv3.Audit.MinFirstAllocation.Source.success_conservation
#print axioms LidoSRv3.Audit.MinFirstAllocation.Source.success_capacity
#print axioms LidoSRv3.Audit.MinFirstAllocation.Source.revert_rolls_back
#print axioms LidoSRv3.Audit.Guarantees.PAccount1.source_report_before_reward
#print axioms LidoSRv3.Audit.Guarantees.PAccount1.verity_tx_simulates_oracle_report
#print axioms LidoSRv3.Audit.Guarantees.PAccount1.verity_tx_revert_restores_snapshot
#print axioms LidoSRv3.Audit.Guarantees.PAccount1.mint_after_read_discipline
#print axioms LidoSRv3.Audit.Guarantees.PAccount1.mint_order_kill_line
#print axioms LidoSRv3.Audit.Verity.HandleOracleReportTx.verity_tx_simulates_pinned_source
#print axioms LidoSRv3.Audit.Verity.HandleOracleReportTx.revert_restores_snapshot
#print axioms LidoSRv3.Audit.Verity.HandleOracleReportTx.mintAfterReadDiscipline_holds
#print axioms LidoSRv3.Audit.Verity.HandleOracleReportTx.mintOrderKillLine_holds
#print axioms LidoSRv3.Tests.HandleOracleReportTxMutants.reordered_mint_read_kill_line_refutes_parent
#print axioms LidoSRv3.Audit.Verity.AddressAdmission.run_claim_success
#print axioms LidoSRv3.Audit.Verity.AddressAdmission.admission_address_equivariant
#print axioms LidoSRv3.Audit.Verity.AddressAdmission.claim_admits
#print axioms LidoSRv3.Audit.Verity.AddressAdmission.claim_rejects_empty_balance
#print axioms LidoSRv3.Audit.Verity.AddressAdmission.claim_rejects_when_paused
#print axioms LidoSRv3.Audit.Verity.AddressAdmission.ownerGated_not_admission_equivariant
#print axioms LidoSRv3.Audit.Verity.ConsolidationCallFragment.raw_call_entrypoint_always_reverts
#print axioms
  LidoSRv3.Audit.Verity.ConsolidationCallFragment.external_call_bind_entrypoint_always_reverts
#print axioms LidoSRv3.Audit.Verity.ConsolidationCallFragment.requestConsolidationBind_registered
#print axioms
  LidoSRv3.Audit.Verity.ConsolidationCallFragment.registered_external_call_bind_entrypoint_always_reverts
#print axioms LidoSRv3.Audit.Verity.ConsolidationCallFragment.guards_only_succeeds
#print axioms LidoSRv3.Audit.Verity.ConsolidationCallFragment.success_hypotheses_are_vacuous
#print axioms LidoSRv3.Audit.Guarantees.PAddress1.universal_address_writer_equivariance
#print axioms LidoSRv3.Audit.Guarantees.PAddress1.abstract_source_verity_tx_address_equivariance
#print axioms LidoSRv3.Audit.Verity.AddressTx.pinned_source_observable_correspondence
#print axioms LidoSRv3.Audit.Verity.AddressTx.executed_address_writes_follow_renamed_source
#print axioms LidoSRv3.Audit.Verity.AddressTx.every_revert_restores_snapshot
#print axioms LidoSRv3.Tests.AddressSourceMutants.verity_wrong_recipient_mutant_rejected
#print axioms LidoSRv3.Tests.AddressSourceMutants.verity_fixed_owner_writer_mutant_rejected
#print axioms LidoSRv3.Tests.AddressSourceMutants.verity_zero_amount_rejected
#print axioms LidoSRv3.Tests.AddressSourceMutants.fixed_owner_gate_not_admission_equivariant
#print axioms LidoSRv3.Tests.AddressSourceMutants.fixed_owner_gate_kill_line_refutes_parent
#print axioms LidoSRv3.Tests.AddressSourceMutants.fixed_owner_writer_kill_line_refutes_parent
#print axioms
  LidoSRv3.Audit.Guarantees.PConsolidation1.source_consolidation_preserves_eligibility_value_atomicity
#print axioms
  LidoSRv3.Audit.Guarantees.PConsolidation1.verity_tx_simulates_consolidation
#print axioms
  LidoSRv3.Audit.Guarantees.PConsolidation1.verity_tx_revert_restores_snapshot
#print axioms LidoSRv3.Audit.Verity.ConsolidationTx.function_spec_bridge_constructors
#print axioms LidoSRv3.Audit.Guarantees.PAddress1.bounded_transfer_model_source_tx
#print axioms LidoSRv3.Audit.Verity.AddressTransferTx.tx_refines_source_witness
#print axioms LidoSRv3.Audit.Source.AddressTransferCorrespondence.fixed_caller_mutant_rejected
#print axioms LidoSRv3.Audit.Guarantees.PDeposit1.source_deposit_conserves_and_rolls_back
#print axioms LidoSRv3.Audit.Guarantees.PDeposit1.source_router_balance_unchanged
#print axioms LidoSRv3.Audit.Guarantees.PDeposit1.source_reverting_branch_moves_no_ether
#print axioms LidoSRv3.Audit.Guarantees.PDeposit1.source_nonconserving_deployment_reverts
#print axioms LidoSRv3.Audit.Guarantees.PDeposit1.verity_tx_revert_restores_snapshot
#print axioms LidoSRv3.Audit.Verity.DepositTx.run_simulates_source
#print axioms LidoSRv3.Tests.DepositTxMutants.double_beacon_send_rejected
#print axioms
  LidoSRv3.Audit.Guarantees.PDeposit1.verity_tx_composes_deposit_conservation_and_rollback
#print axioms LidoSRv3.Audit.Guarantees.PDeposit1.canonical_composition_witness
#print axioms LidoSRv3.Audit.Verity.DepositParentTx.execute_observes_source
#print axioms
  LidoSRv3.Audit.Verity.DepositParentTx.revert_after_intermediate_writes_restores_snapshot
#print axioms LidoSRv3.Audit.Verity.DepositParentTx.revert_observes_idle
#print axioms LidoSRv3.Tests.DepositParentTxMutants.mutant_none_reproduces_execute
#print axioms LidoSRv3.Tests.DepositParentTxMutants.skipped_allocation_write_rejected
#print axioms LidoSRv3.Tests.DepositParentTxMutants.skipped_dynamic_data_write_rejected
#print axioms LidoSRv3.Tests.DepositParentTxMutants.skipped_root_write_rejected
#print axioms LidoSRv3.Tests.DepositParentTxMutants.misrouted_push_rejected
#print axioms LidoSRv3.Tests.DepositParentTxMutants.dropped_push_rejected
#print axioms LidoSRv3.Tests.DepositParentTxMutants.root_failure_observes_idle
#print axioms LidoSRv3.Audit.Guarantees.PEth1.eth_flow_confined
#print axioms LidoSRv3.Audit.Guarantees.PEth1.consolidation_fee_path_confined
#print axioms LidoSRv3.Audit.Guarantees.PEth1.eth_flow_parent
#print axioms LidoSRv3.Audit.Guarantees.PEth1.verity_tx_universal_success_shape
#print axioms LidoSRv3.Audit.Guarantees.PEth1.verity_tx_composes_value_flow_and_rollback
#print axioms LidoSRv3.Tests.PEth1CompositionTxMutants.rejects_dropped_refund_leg
#print axioms LidoSRv3.Tests.PEth1CompositionTxMutants.rejects_misrouted_vault_leg
#print axioms LidoSRv3.Tests.PEth1CompositionTxMutants.rejects_corrupted_refund_amount
#print axioms LidoSRv3.Tests.PEth1CompositionTxMutants.rejects_preserved_prefix_after_failed_hop
#print axioms LidoSRv3.Tests.PEth1CompositionTxMutants.rejects_single_request_for_two_request_batch
#print axioms LidoSRv3.Tests.PEth1CompositionTxMutants.universal_parent_is_predicate_at_honest
#print axioms LidoSRv3.Tests.PEth1CompositionTxMutants.dropped_refund_leg_kill_line_refutes_universal_parent
#print axioms LidoSRv3.Tests.PEth1CompositionTxMutants.misrouted_vault_kill_line_refutes_universal_parent
#print axioms LidoSRv3.Tests.PEth1CompositionTxMutants.corrupted_refund_kill_line_refutes_universal_parent
#print axioms LidoSRv3.Tests.PEth1CompositionTxMutants.single_request_kill_line_refutes_universal_parent
#print axioms LidoSRv3.Tests.PEth1CompositionTxMutants.zero_value_kill_line_refutes_dropped_positivity
#print axioms LidoSRv3.Tests.PEth1CompositionTxMutants.underfunded_kill_line_refutes_dropped_funding
#print axioms LidoSRv3.Tests.PEth1CompositionTxMutants.fuel_exhaustion_kill_line_refutes_dropped_fuel_premise
#print axioms LidoSRv3.Audit.Verity.PEth1RefundTx.gateway_refund_success_moves_value
#print axioms LidoSRv3.Audit.Verity.PEth1RefundTx.gateway_refund_failure_keeps_prefix_out
#print axioms LidoSRv3.Audit.Verity.PEth1RefundTx.withdraw_success_moves_to_lido
#print axioms LidoSRv3.Audit.Verity.PEth1RefundTx.refund_failure_restores_snapshot
#print axioms LidoSRv3.Audit.Verity.PEth1RequestTx.bus_forward_success
#print axioms LidoSRv3.Audit.Verity.PEth1RequestTx.consolidation_fee_target_success
#print axioms LidoSRv3.Audit.Verity.PEth1RequestTx.withdrawal_fee_success
#print axioms LidoSRv3.Audit.Verity.PEth1RequestTx.consolidation_second_failure_discards_prefix
#print axioms LidoSRv3.Audit.Verity.PEth1RequestTx.bus_failure_restores_snapshot
#print axioms LidoSRv3.Audit.Verity.PEth1RefundTx.sourceGateway_committed_splits_to_vault_and_refund
#print axioms LidoSRv3.Tests.PEth1RefundTxMutants.refund_misroute_kill_line
#print axioms LidoSRv3.Tests.PEth1RefundTxMutants.double_refund_rejected
#print axioms LidoSRv3.Tests.PEth1RefundTxMutants.leak_on_refund_failure_rejected
#print axioms LidoSRv3.Tests.PEth1RequestTxMutants.keep_first_consolidation_fee_rejected
#print axioms LidoSRv3.Audit.Guarantees.PTopup1.source_wrap_precludes_value_moving_commit
#print axioms LidoSRv3.Audit.Guarantees.PTopup1.source_module_guard_required
#print axioms LidoSRv3.Audit.Guarantees.PTopup1.source_wc_type2_guard_required
#print axioms LidoSRv3.Audit.Guarantees.PTopup1.source_topup_conserves_and_rolls_back
#print axioms LidoSRv3.Audit.Guarantees.PTopup1.source_router_balance_unchanged
#print axioms LidoSRv3.Audit.Guarantees.PTopup1.source_reverting_branch_moves_no_ether
#print axioms LidoSRv3.Audit.Guarantees.PTopup1.source_balance_guards_discharged
#print axioms LidoSRv3.Audit.Guarantees.PTopup1.source_unchecked_accumulation_faithful
#print axioms LidoSRv3.Audit.Guarantees.PTopup1.source_pinned_config_discharges_pubkey_guard
#print axioms LidoSRv3.Audit.Guarantees.PTopup1.verity_tx_simulates_source
#print axioms LidoSRv3.Tests.TopupTxMutants.mutant_none_reproduces_execute
#print axioms LidoSRv3.Tests.TopupTxMutants.honest_run_matches_source
#print axioms LidoSRv3.Tests.TopupTxMutants.skipped_allocation_write_rejected
#print axioms LidoSRv3.Tests.TopupTxMutants.dropped_push_rejected
#print axioms LidoSRv3.Tests.TopupTxMutants.misrouted_push_rejected
#print axioms LidoSRv3.Tests.TopupTxMutants.corrupted_amount_rejected
#print axioms LidoSRv3.Tests.TopupTxMutants.swapped_order_rejected
#print axioms LidoSRv3.Tests.TopupTxMutants.duplicated_push_rejected
#print axioms LidoSRv3.Tests.TopupTxMutants.allocation_write_failure_rolls_back
#print axioms LidoSRv3.Tests.TopupTxMutants.lido_pull_failure_rolls_back
#print axioms LidoSRv3.Tests.TopupTxMutants.first_beacon_failure_rolls_back
#print axioms LidoSRv3.Tests.TopupTxMutants.guard_discharge_at_wrapping_input
#print axioms LidoSRv3.Tests.TopupTxMutants.wrap_to_zero_commits_no_topup
#print axioms LidoSRv3.Tests.TopupTxMutants.guard_discharge_at_unregistered_module_input
#print axioms LidoSRv3.Tests.TopupTxMutants.guard_discharge_at_non_type2_wc_input
#print axioms LidoSRv3.Tests.TopupTxMutants.mutantRunNoAssert_eq_run_of_assert_passing
#print axioms LidoSRv3.Tests.TopupTxMutants.mutantRunNoAssert_commits_where_assert_fires
#print axioms LidoSRv3.Tests.TopupTxMutants.dropped_conservation_assert_kill_line_refutes_parent
#print axioms LidoSRv3.Tests.TopupTxMutants.dropped_module_guard_kill_line_refutes_parent
#print axioms LidoSRv3.Tests.TopupTxMutants.dropped_wc_guard_kill_line_refutes_parent
#print axioms LidoSRv3.Tests.TopupTxMutants.unwrapped_accumulator_kill_line_refutes_parent
#print axioms LidoSRv3.Audit.Source.Topup2.source_aggregate_bounded_by_block_cap
#print axioms LidoSRv3.Audit.Guarantees.PTopup2.aggregate_bounded_by_block_cap
#print axioms LidoSRv3.Audit.Guarantees.PTopup2.per_key_bounded_by_candidate
#print axioms LidoSRv3.Audit.Verity.Topup2Tx.tx_aggregate_bounded_by_block_cap
#print axioms LidoSRv3.Audit.Verity.Topup2Tx.tx_all_success_value_exact
#print axioms LidoSRv3.Audit.Verity.Topup2Tx.tx_revert_restores_world
#print axioms LidoSRv3.Audit.Verity.Topup2Tx.tx_committed_world_is_commit_fold
#print axioms LidoSRv3.Tests.Topup2TxMutants.over_cap_aggregate_rejected
#print axioms LidoSRv3.Tests.Topup2TxMutants.double_send_rejected
#print axioms LidoSRv3.Tests.Topup2TxMutants.reverting_adversary_cannot_leak_state
#print axioms LidoSRv3.Audit.Guarantees.PReserve1.source_spend_preserves_withdrawal_reserve
#print axioms LidoSRv3.Audit.Guarantees.PReserve1.verity_tx_simulates_reserve_spec
#print axioms LidoSRv3.Audit.Guarantees.PReserve1.verity_tx_preserves_withdrawal_reserve
#print axioms LidoSRv3.Audit.Guarantees.PReserveRelational.abstract_reserve_does_not_change_finalization
#print axioms LidoSRv3.Audit.Guarantees.PReserveRelational.source_reserve_does_not_change_finalization
#print axioms LidoSRv3.Audit.Guarantees.PReserveRelational.verity_tx_simulates_reserve_relational_spec
#print axioms LidoSRv3.Audit.Guarantees.PReserveRelational.verity_tx_reverts_on_locked_overflow
#print axioms LidoSRv3.Audit.Guarantees.PReserveRelational.verity_reserve_slot_is_not_read
#print axioms LidoSRv3.Audit.Guarantees.PReserveRelational.verity_reserve_does_not_change_finalization
#print axioms LidoSRv3.Audit.Guarantees.PReserveRelational.verity_revert_restores_snapshot
#print axioms LidoSRv3.Audit.Guarantees.PSsz1.composed_ssz_encoding
#print axioms LidoSRv3.Audit.Guarantees.PSsz1.swapped_combine_kill_line_refutes_parent
#print axioms LidoSRv3.Audit.Guarantees.PSsz1.composedEncodingOkFull_not_trivial_crossed_witness
#print axioms LidoSRv3.Audit.Guarantees.PSsz1.inconsistent_witness_kill_line
#print axioms LidoSRv3.Audit.Guarantees.PSsz1.inconsistent_operation_index_kill_line
#print axioms LidoSRv3.Audit.Guarantees.PSsz1.sourceWitness_binds_sourceNode
#print axioms LidoSRv3.Audit.Guarantees.PSsz1.verity_tx_simulates_ssz_encoding
#print axioms LidoSRv3.Audit.Guarantees.PSsz1.verity_tx_two_batch_rolls_back
#print axioms LidoSRv3.Audit.Verity.SszEncodingTx.verity_tx_simulates_pinned_source
#print axioms LidoSRv3.Audit.Verity.SszEncodingTx.encoding_commits_structural_witness
#print axioms LidoSRv3.Audit.Verity.SszEncodingTx.revert_restores_snapshot
#print axioms LidoSRv3.Audit.Source.GIndexConcatCorrespondence.source_concat_matches_spec
#print axioms LidoSRv3.Audit.Source.GIndexConcatCorrespondence.source_concat_value_of_fits
#print axioms LidoSRv3.Audit.Source.GIndexConcatCorrespondence.source_concat_depth_overflow
#print axioms LidoSRv3.Audit.Verity.SszTxSimulation.ssz_tx_simulation_correct
#print axioms LidoSRv3.Audit.Verity.SszTxSimulation.sha256_call_world_rollback
#print axioms LidoSRv3.Audit.Verity.SszTxSimulation.root_mutant_rejected
#print axioms
  LidoSRv3.Audit.Source.DepositDataRootCorrespondence.source_pinned_config_discharges_deposit_data_root
#print axioms LidoSRv3.Audit.MinFirst.candidate_mem
#print axioms LidoSRv3.Audit.MinFirst.candidate_open
#print axioms LidoSRv3.Audit.MinFirst.candidate_none_no_open
#print axioms LidoSRv3.Audit.MinFirst.candidate_minimal
#print axioms LidoSRv3.Audit.MinFirst.candidate_router_tie
#print axioms LidoSRv3.Audit.MinFirst.incrementSelected_moduleId
#print axioms LidoSRv3.Audit.MinFirst.incrementSelected_active
#print axioms LidoSRv3.Audit.MinFirst.incrementSelected_monotone
#print axioms LidoSRv3.Audit.MinFirst.incrementSelected_eq_of_ne
#print axioms LidoSRv3.Audit.MinFirst.step_preserves_length
#print axioms LidoSRv3.Audit.MinFirst.step_preserves_module_order
#print axioms LidoSRv3.Audit.MinFirst.loop_preserves_length
#print axioms LidoSRv3.Audit.MinFirst.loop_preserves_module_order
#print axioms LidoSRv3.Audit.MinFirst.allocate_preserves_length
#print axioms LidoSRv3.Audit.MinFirst.allocate_preserves_module_order
#print axioms LidoSRv3.Audit.MinFirst.run_spent_le
#print axioms LidoSRv3.Audit.MinFirst.totalAllocated_le_requested
#print axioms LidoSRv3.Audit.Common.BoundedAmount.checkedAdd_sound
#print axioms LidoSRv3.Audit.Common.revert_rolls_back_state_and_committed_effects
#print axioms LidoSRv3.Audit.Common.success_exposes_exact_committed_effects
