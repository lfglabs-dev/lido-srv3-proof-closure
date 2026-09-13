import LidoSRv3.Audit.Source.TopupBeaconCommitted

/-!
Kill-lines pinning `Source.TopupBeaconCommitted.guarded_amount_fits`
witness — the executed uint64-gwei guard implies wei ≤ uint256.
-/

namespace LidoSRv3.Tests.SourceTopupBeaconCommittedFitsKillLines

open LidoSRv3.Audit.Source.TopupBeaconCommitted
open LidoSRv3.Audit.SolidityTopup

/-! ## `guarded_amount_fits` — restated. -/

theorem guarded_amount_fits_restated (a : Nat) (h : a / 10^9 ≤ 2^64-1) :
    a < uint256Modulus :=
  guarded_amount_fits a h

/-! ## Concrete witness at zero. -/

theorem guarded_amount_fits_zero :
    (0 : Nat) < uint256Modulus := by decide

/-! ## Concrete witness at max-guarded (uint64-gwei = 2^64-1 * 10^9). -/

theorem guarded_amount_fits_max :
    ((2^64 - 1) * 10^9 : Nat) < uint256Modulus := by decide

end LidoSRv3.Tests.SourceTopupBeaconCommittedFitsKillLines
