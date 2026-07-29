import LidoSRv3.Audit.Allocation
import LidoSRv3.Audit.StrategyProofs

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
