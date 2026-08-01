import LidoSRv3.Audit.StrategyProofs
import LidoSRv3.Audit.Guarantees.Registry

namespace LidoSRv3.Audit.Guarantees.PAlloc2

def guarantee : Guarantee := ⟨.pAlloc2, [.algorithm]⟩

/--
The executable MinFirst control rule selects an open bucket with no larger
allocation than any other open input bucket. This is an ALG theorem for the
handwritten `Nat` model; Solidity and EVM refinement remain open.
-/
theorem selects_least_open_bucket
    (h : MinFirst.candidate? rows = some selected)
    (hOther : other ∈ rows) (hOpen : other.open = true) :
    selected.allocation ≤ other.allocation := by
  exact MinFirst.candidate_minimal h hOther hOpen

end LidoSRv3.Audit.Guarantees.PAlloc2
