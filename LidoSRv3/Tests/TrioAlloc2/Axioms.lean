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
