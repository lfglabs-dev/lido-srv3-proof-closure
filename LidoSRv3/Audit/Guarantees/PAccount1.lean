import LidoSRv3.Audit.StrategyProofs
import LidoSRv3.Audit.Guarantees.Registry

namespace LidoSRv3.Audit.Guarantees.PAccount1

def guarantee : Guarantee := ⟨.pAccount1, [.model]⟩

/-- Handwritten MinFirst-model bound; no Solidity or EVM equivalence is claimed. -/
theorem totalAllocated_le_requested :
    ∀ (requested : Nat) (rows : List LidoSRv3.Audit.MinFirst.Bucket),
      LidoSRv3.Audit.MinFirst.totalAllocated requested rows ≤ requested :=
  LidoSRv3.Audit.MinFirst.totalAllocated_le_requested

end LidoSRv3.Audit.Guarantees.PAccount1
