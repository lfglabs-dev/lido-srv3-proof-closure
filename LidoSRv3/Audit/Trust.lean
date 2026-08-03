import LidoSRv3.Audit.Allocation
import LidoSRv3.Audit.StrategyProofs
import LidoSRv3.Audit.Common.Atomicity
import LidoSRv3.Audit.Common.Bounded
import LidoSRv3.Audit.Guarantees.PAlloc1
import LidoSRv3.Audit.Guarantees.PAlloc2
import LidoSRv3.Audit.Guarantees.PAccount1
import LidoSRv3.Audit.Guarantees.PDeposit1
import LidoSRv3.Audit.Guarantees.PSsz1
import LidoSRv3.Audit.Guarantees.PTopup1

/-!
Machine-readable-in-build axiom report for the first audit slice.

Expected output is only Lean foundations (`propext`, `Quot.sound`) where used;
there are no project axioms, `sorry`, or proof escapes.
-/

#print axioms LidoSRv3.Audit.Quantity.checkedDiv_zero
#print axioms LidoSRv3.Audit.Quantity.saturatingSub_zero_of_le
#print axioms LidoSRv3.Audit.revert_restores_state_value_and_logs
#print axioms LidoSRv3.Audit.revert_may_retain_attempts
#print axioms LidoSRv3.Audit.valid_result_preserves_router_order
#print axioms LidoSRv3.Audit.Guarantees.PAlloc1.active_capacity_bounded
#print axioms LidoSRv3.Audit.Guarantees.PAlloc1.source_capacities_match_model
#print axioms LidoSRv3.Audit.Guarantees.PAlloc1.source_active_capacity_bounded
#print axioms LidoSRv3.Audit.Guarantees.PAlloc2.selects_least_open_bucket
#print axioms LidoSRv3.Audit.Guarantees.PAlloc2.source_selects_same_next_target
#print axioms LidoSRv3.Audit.Guarantees.PAccount1.source_report_before_reward
#print axioms LidoSRv3.Audit.Guarantees.PAccount1.source_to_verityTx
#print axioms LidoSRv3.Audit.Guarantees.PDeposit1.source_deposit_conserves_and_rolls_back
#print axioms LidoSRv3.Audit.Guarantees.PDeposit1.source_router_balance_unchanged
#print axioms LidoSRv3.Audit.Guarantees.PDeposit1.source_reverting_branch_moves_no_ether
#print axioms LidoSRv3.Audit.Guarantees.PDeposit1.source_nonconserving_deployment_reverts
#print axioms LidoSRv3.Audit.Guarantees.PTopup1.source_topup_conserves_and_rolls_back
#print axioms LidoSRv3.Audit.Guarantees.PTopup1.source_router_balance_unchanged
#print axioms LidoSRv3.Audit.Guarantees.PTopup1.source_reverting_branch_moves_no_ether
#print axioms LidoSRv3.Audit.Guarantees.PTopup1.source_balance_guards_discharged
#print axioms LidoSRv3.Audit.Guarantees.PTopup1.source_unchecked_accumulation_faithful
#print axioms LidoSRv3.Audit.Guarantees.PTopup1.source_pinned_config_discharges_pubkey_guard
#print axioms LidoSRv3.Audit.Guarantees.PSsz1.structural_witness_binding_sound
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
