import LidoSRv3.Audit.Provenance.TopupBeacon
import LidoSRv3.Audit.Verity.TopupTx
import LidoSRv3.Audit.Guarantees.PTopup1
import LidoSRv3.Audit.Guarantees.PDeposit1

/-!
Kill-lines pinning `Provenance.TopupBeacon` model-literal identities.
These theorems pin the two `theorem`s already discharged in that
module: `topup_verity_beacon_is_production_pin` (Verity beacon literal
matches the PTopup1 canonical pin) and `topup_canonical_eq_deposit_canonical`
(top-up and deposit canonical Nats coincide). Also pins that the canonical
Nat is exactly `0x00000000219ab540356cBB839Cbe05303d7705Fa` as a natural
number literal, and that the address fits in 160 bits.
-/

namespace LidoSRv3.Tests.ProvenanceTopupBeaconKillLines

open LidoSRv3.Audit.Guarantees

/-- Canonical Beacon deposit contract address (Mainnet, EIP-2982). -/
theorem canonical_beacon_deposit_address_value :
    PTopup1.canonicalBeaconDepositAddress =
      0x00000000219ab540356cBB839Cbe05303d7705Fa := by
  decide

/-- Canonical deposit contract address matches the beacon canonical. -/
theorem canonical_deposit_matches_beacon :
    PDeposit1.canonicalDepositContractAddress =
      PTopup1.canonicalBeaconDepositAddress :=
  rfl

/-- The two 160-bit pins agree as Nats. -/
theorem topup_beacon_and_deposit_pins_agree :
    PTopup1.canonicalBeaconDepositAddress =
      PDeposit1.canonicalDepositContractAddress :=
  rfl

/-- The canonical beacon deposit address fits in 160 bits. -/
theorem canonical_beacon_deposit_address_fits_160 :
    PTopup1.canonicalBeaconDepositAddress < 2 ^ 160 := by
  decide

/-- Verity top-up model target as `Nat` equals the canonical pin. -/
theorem topup_model_target_is_canonical :
    LidoSRv3.Audit.Verity.TopupTx.beaconAddress.toNat =
      PTopup1.canonicalBeaconDepositAddress := by
  decide

/-- Verity top-up model target as `Nat` equals the deposit canonical. -/
theorem topup_model_target_is_deposit_canonical :
    LidoSRv3.Audit.Verity.TopupTx.beaconAddress.toNat =
      PDeposit1.canonicalDepositContractAddress := by
  decide

/-- The canonical Nat is nonzero (the beacon contract is not the zero
address). -/
theorem canonical_beacon_deposit_address_nonzero :
    PTopup1.canonicalBeaconDepositAddress ≠ 0 := by
  decide

end LidoSRv3.Tests.ProvenanceTopupBeaconKillLines
