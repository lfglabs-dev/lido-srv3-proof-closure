import LidoSRv3.Audit.Arithmetic
import LidoSRv3.Audit.Guarantees.Registry

namespace LidoSRv3.Audit.Guarantees.PAlloc2

def guarantee : Guarantee := ⟨.pAlloc2, [.model]⟩

/-- Checked-quantity model fact; Solidity correspondence remains open. -/
def checkedDiv_zero {unit : Type} := @LidoSRv3.Audit.Quantity.checkedDiv_zero unit

end LidoSRv3.Audit.Guarantees.PAlloc2
