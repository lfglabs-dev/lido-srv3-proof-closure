import LidoSRv3.Audit.Guarantees.Registry

namespace LidoSRv3.Audit.Guarantees.PConsolidation1

/-- SHA-256 primitive correctness is an explicit bounded assumption; exact request
bytes, lengths, offsets, order, padding, calls, and digest composition remain proof
obligations, so no crypto-closure theorem is claimed. -/
def guarantee : Guarantee := ⟨.pConsolidation1, []⟩

end LidoSRv3.Audit.Guarantees.PConsolidation1
