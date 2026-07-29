import LidoSRv3.Audit.Allocation

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
#print axioms LidoSRv3.Audit.positive_increment_respects_capacity
#print axioms LidoSRv3.Audit.positive_committed_payment_is_eligible
#print axioms LidoSRv3.Audit.firstOpenModule_deterministic
