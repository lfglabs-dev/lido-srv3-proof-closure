import LidoSRv3.SpecProofs
import LidoSRv3.Audit.Guarantees.Registry

namespace LidoSRv3.Audit.Guarantees.PAlloc1

def guarantee : Guarantee := ⟨.pAlloc1, [.model]⟩

/-- Model-only reserve separation; this is not a source or EVM correspondence claim. -/
def reserve_separation := LidoSRv3.P1_reserve_separation

end LidoSRv3.Audit.Guarantees.PAlloc1
