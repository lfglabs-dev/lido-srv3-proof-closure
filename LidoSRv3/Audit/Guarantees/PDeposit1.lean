import LidoSRv3.Audit.Trace
import LidoSRv3.Audit.Guarantees.Registry

namespace LidoSRv3.Audit.Guarantees.PDeposit1

def guarantee : Guarantee := ⟨.pDeposit1, [.model, .abstractTx]⟩

/-- Abstract transaction rollback, not an executable EVM trace. -/
def revert_restores_state_value_and_logs {State : Type} :=
  @LidoSRv3.Audit.revert_restores_state_value_and_logs State

end LidoSRv3.Audit.Guarantees.PDeposit1
