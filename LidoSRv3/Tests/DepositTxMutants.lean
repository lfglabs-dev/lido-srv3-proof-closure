import LidoSRv3.Audit.Verity.DepositTx

namespace LidoSRv3.Tests.DepositTxMutants

open LidoSRv3.Audit.Verity.DepositTx

open _root_.Verity

def doubleSendMutant (before : Balances) (amount : Nat) : Contract Balances :=
  _root_.Verity.pure { committedBalances before amount with
    beaconSink := before.beaconSink + amount + amount }

/-- Reject the classic double-send mutant: its beacon delta cannot equal one
bounded deposit unit when that unit is positive. -/
theorem double_beacon_send_rejected (before : Balances) (amount : Nat)
    (snapshot : ContractState) (hPositive : 0 < amount) :
    (observe snapshot before ((doubleSendMutant before amount).run snapshot)).balancesAfter ≠
      committedBalances before amount := by
  intro hEq
  have hBeacon := congrArg Balances.beaconSink hEq
  simp [doubleSendMutant, observe, Contract.run, _root_.Verity.pure,
    committedBalances] at hBeacon
  omega

end LidoSRv3.Tests.DepositTxMutants
