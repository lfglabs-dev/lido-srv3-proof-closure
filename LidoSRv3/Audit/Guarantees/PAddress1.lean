import LidoSRv3.Audit.Guarantees.Registry
import LidoSRv3.Audit.AddressEquivariance

namespace LidoSRv3.Audit.Guarantees.PAddress1

/-- Abstract-transaction evidence only; no Yul, bytecode, or Verity projection. -/
def guarantee : Guarantee := ⟨.pAddress1, [.abstractTx]⟩

/-- The bounded observation renamer satisfies the exact abstract equivariance relation. -/
theorem abstract_address_equivariance
    (rho : LidoSRv3.Audit.AddressEquivariance.Renaming)
    (renameState : State → State) (tx : LidoSRv3.Audit.TxObservation State) :
    LidoSRv3.Audit.AddressEquivariance.Equivariant rho renameState tx
      (LidoSRv3.Audit.AddressEquivariance.renameObservation rho renameState tx) :=
  LidoSRv3.Audit.AddressEquivariance.rename_is_equivariant rho renameState tx

end LidoSRv3.Audit.Guarantees.PAddress1
