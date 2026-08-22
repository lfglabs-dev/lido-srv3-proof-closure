import LidoSRv3.Audit.Provenance.TopupBeacon
import LidoSRv3.Audit.Verity.TopupTx
import LidoSRv3.Audit.Guarantees.PTopup1
import Contracts.Common

/-!
# Pack G-TOPUP fail-closed vectors

A mutant model whose beacon target is `0xDEAD` disagrees with the
production pin. `A-TOPUP-BEACON-ADDRESS` stays OPEN.
-/

namespace LidoSRv3.Tests.PackGTopupProvenanceMutants

open Verity
open LidoSRv3.Audit.Guarantees
open LidoSRv3.Audit.Provenance.TopupBeacon

/-- Mutant top-up model: beacon destination is `0xDEAD`. -/
def mutantBeaconAddress : Address := (0xDEAD : Address)

/-- Kill-line: a `0xDEAD` beacon disagrees with the production pin and with
the honest Verity literal. -/
theorem dead_beacon_model_kill_line_disagrees_with_pin :
    mutantBeaconAddress.toNat ≠ PTopup1.canonicalBeaconDepositAddress ∧
      mutantBeaconAddress.toNat ≠
        LidoSRv3.Audit.Verity.TopupTx.beaconAddress.toNat := by
  native_decide

/-- Honest pin remains the production literal; the mutant is not that pin. -/
example :
    LidoSRv3.Audit.Verity.TopupTx.beaconAddress.toNat =
      PTopup1.canonicalBeaconDepositAddress :=
  topup_verity_beacon_is_production_pin

end LidoSRv3.Tests.PackGTopupProvenanceMutants
