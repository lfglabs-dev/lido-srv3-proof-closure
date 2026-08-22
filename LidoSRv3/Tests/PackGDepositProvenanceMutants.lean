import LidoSRv3.Audit.Provenance.Deposit

/-!
# Pack G-DEPOSIT fail-closed vectors

A wrong beacon-deposit pin is not the production literal. This does not
discharge `A-DEPOSIT-CONTRACT` or `A-DEPOSIT-32-ETHER`.
-/

namespace LidoSRv3.Tests.PackGDepositProvenanceMutants

open LidoSRv3.Audit.Provenance.Deposit

/-- Kill-line: `0xDEAD` is not the production beacon deposit address. -/
theorem wrong_beacon_pin_kill_line :
    (0xDEAD : Nat) ≠ productionBeaconDeposit := by
  decide

end LidoSRv3.Tests.PackGDepositProvenanceMutants
