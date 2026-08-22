import LidoSRv3.Audit.Source.AddressCorrespondence

/-!
# Wave 2 W2-SCOPE: pause admission re-export

Unregistered child. Re-exports the pinned-source fact that
`requestWithdrawals` / `unwrap` admission is pause plus caller
balance/allowance flags — no fixed owner gate. Does not invent a
guarantee ID and does not change the registered P-ADDRESS-1 parent.
-/

namespace LidoSRv3.Audit.Spec.PauseAdmissionCorrespondence

open LidoSRv3.Audit.SolidityAddress

/-- Scoped pause/balance writers admit without a `caller = owner` test.
Exact source: `LidoSRv3.Audit.SolidityAddress.pause_balance_admitted_is_permissionless`
in `Audit/Source/AddressCorrespondence.lean`. -/
theorem request_or_unwrap_pause_balance_is_permissionless
    (inp : Input)
    (hScope : inp.entryPoint = .requestWithdrawals ∨ inp.entryPoint = .unwrap) :
    admitted inp = permissionlessAdmission inp :=
  LidoSRv3.Audit.SolidityAddress.pause_balance_admitted_is_permissionless inp hScope

end LidoSRv3.Audit.Spec.PauseAdmissionCorrespondence
