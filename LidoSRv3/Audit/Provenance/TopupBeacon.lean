import LidoSRv3.Audit.Verity.TopupTx
import LidoSRv3.Audit.Guarantees.PTopup1
import LidoSRv3.Audit.Guarantees.PDeposit1

/-!
# G-TOPUP: Verity beacon literal equals the production pin

Unregistered provenance children. They show that the executable top-up
model already uses the same Nat as `PTopup1.canonicalBeaconDepositAddress`,
and that that pin is the same Nat as the deposit-side canonical.

`A-TOPUP-BEACON-ADDRESS` stays OPEN. Equality of two model literals is not
the deployed immutable identity, and these theorems do not discharge that
assumption. No new guarantee ID. No top-up `LinksSource`.
-/

namespace LidoSRv3.Audit.Provenance.TopupBeacon

open LidoSRv3.Audit.Guarantees

/-- The Verity top-up model target is the production beacon pin as a Nat.
This is model-literal agreement, not a deployed-artifact identity. -/
theorem topup_verity_beacon_is_production_pin :
    LidoSRv3.Audit.Verity.TopupTx.beaconAddress.toNat =
      PTopup1.canonicalBeaconDepositAddress := by
  decide

/-- Top-up and deposit canonical pins are the same Nat. Both remain model
pins; neither statement identifies a deployed immutable. -/
theorem topup_canonical_eq_deposit_canonical :
    PTopup1.canonicalBeaconDepositAddress =
      PDeposit1.canonicalDepositContractAddress :=
  rfl

end LidoSRv3.Audit.Provenance.TopupBeacon
