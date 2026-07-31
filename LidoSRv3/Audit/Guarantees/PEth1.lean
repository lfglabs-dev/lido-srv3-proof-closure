import LidoSRv3.Audit.Guarantees.Registry

namespace LidoSRv3.Audit.Guarantees.PEth1

/-- DEV-431 readiness is not a certified semantic guarantee. -/
def guarantee : Guarantee := ⟨.pEth1, []⟩

end LidoSRv3.Audit.Guarantees.PEth1
