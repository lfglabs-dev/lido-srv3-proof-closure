import LidoSRv3.Audit.Source.TrioAlloc2.LoopCorrespondence
import LidoSRv3.Audit.Source.TrioAlloc2.SpecProgress
import LidoSRv3.Audit.Source.TrioAlloc2.StepCorrespondence
import LidoSRv3.Audit.Source.TrioAlloc2.ChoiceCorrespondence
import LidoSRv3.Audit.Source.TrioAlloc2.Errors
import LidoSRv3.Audit.Source.TrioAlloc2.LoopTotality
import LidoSRv3.Audit.Source.TrioAlloc2.Totality
import LidoSRv3.Audit.Source.TrioAlloc2.Arithmetic
import LidoSRv3.Audit.Source.TrioAlloc2.Selection
import LidoSRv3.Audit.Source.TrioAlloc2.ScanCorrespondence
import LidoSRv3.Audit.Source.TrioAlloc2.ScanBounds
import LidoSRv3.Audit.Source.TrioAlloc2.Conservation
import LidoSRv3.Audit.Source.TrioAlloc2.Spec

/- Supplemental owned-slice inspection. This does not replace the shared
LidoSRv3Audit trust target or authorize any additional assumptions. -/
open LidoSRv3.Audit.Source.TrioAlloc2

#print axioms allocateLoop
#print axioms allocate_zero_demand
#print axioms step_invariants
#print axioms allocateLoop_amount_between
#print axioms allocate_amount_le_demand
#print axioms allocateLoop_preserves_length
#print axioms allocate_preserves_length
#print axioms Spec.Distributes.preserves_length

#print axioms bucketTotal_set
#print axioms step_conserves
#print axioms allocateLoop_conserves
#print axioms allocate_conserves
#print axioms allocate_twice_conserves

#print axioms firstScan_count_bound
#print axioms initialScan_count_bound
#print axioms secondScan_upper_bound

#print axioms firstScan_index_bound
#print axioms initialScan_index_bound

#print axioms firstScan_minimum
#print axioms secondScan_higher_minimum

#print axioms firstScan_tie_count
#print axioms initialScan_tie_count

#print axioms firstScan_first_index
#print axioms initialScan_first_index

#print axioms initialScan_minimum_option
#print axioms initialScan_no_candidate_iff

#print axioms ceilDiv_success
#print axioms ceilDiv_zero_denominator
#print axioms ceilDiv_formula

#print axioms initialScan_success
#print axioms secondScan_success

#print axioms initialScan_selected_row
#print axioms secondScan_above_best

#print axioms step_success

#print axioms allocateLoop_success
#print axioms allocate_success

#print axioms firstScan_short_error
#print axioms step_short_error
#print axioms allocate_short_error
#print axioms allocate_success_iff

#print axioms choose_of_scans

#print axioms step_refines

#print axioms Spec.choose_positive

#print axioms allocateLoop_refines
#print axioms allocate_refines
#print axioms distribution_exists
