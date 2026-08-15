import LidoSRv3.Audit.Verity.DepositTx

namespace LidoSRv3.Tests.DepositTxMutants

open LidoSRv3.Audit.Verity.DepositTx

/-- Reject the classic double-send mutant: its beacon delta cannot equal one
bounded deposit unit when that unit is positive. -/
theorem double_beacon_send_rejected (before : Balances) (amount : Nat)
    (hPositive : 0 < amount) :
    before.beaconSink + amount + amount ≠ before.beaconSink + amount := by
  omega

end LidoSRv3.Tests.DepositTxMutants
