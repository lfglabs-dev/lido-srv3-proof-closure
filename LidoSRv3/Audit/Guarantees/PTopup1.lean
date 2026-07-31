import LidoSRv3.Audit.Allocation
import LidoSRv3.Audit.Guarantees.Registry

namespace LidoSRv3.Audit.Guarantees.PTopup1

def guarantee : Guarantee := ⟨.pTopup1, [.model]⟩

/-- Source-shaped allocation-model ordering fact; extraction is not established. -/
def valid_result_preserves_router_order
    {snapshot : LidoSRv3.Audit.AllocationSnapshot}
    {result : LidoSRv3.Audit.AllocationResult} :=
  @LidoSRv3.Audit.valid_result_preserves_router_order snapshot result

end LidoSRv3.Audit.Guarantees.PTopup1
