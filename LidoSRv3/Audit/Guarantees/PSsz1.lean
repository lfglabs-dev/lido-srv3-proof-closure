import LidoSRv3.Audit.Guarantees.Registry

namespace LidoSRv3.Audit.Guarantees.PSsz1

/-- Structural-only SSZ evidence; no full SSZ, crypto, EVM, or E2E claim. -/
def guarantee : Guarantee := ⟨.pSsz1, []⟩

end LidoSRv3.Audit.Guarantees.PSsz1
