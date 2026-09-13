import LidoSRv3.Audit.Source.TopupBeaconSumBound

/-!
Kill-lines pinning `Source.TopupBeaconSumBound.sum_le_nonzero`
witness — allocSum is bounded by nonzeroCount × uint64-gwei.
-/

namespace LidoSRv3.Tests.SourceTopupBeaconSumBoundKillLines

open LidoSRv3.Audit.Source.TopupBeaconSumBound
open LidoSRv3.Audit.SolidityTopup
open LidoSRv3.Audit.Source.TrioReserve1.Live
open LidoSRv3.Audit.Source.TopupBeaconBatch

/-! ## `sum_le_nonzero` — restated. -/

theorem sum_le_nonzero_restated
    (amounts : List Nat)
    (hb : ∀ a ∈ amounts, a < 2^64 * 10^9) :
    allocSum amounts ≤ nonzeroCount amounts * (2^64 * 10^9 - 1) :=
  sum_le_nonzero amounts hb

/-! ## Empty amounts bound is trivial. -/

theorem sum_le_nonzero_empty :
    allocSum [] ≤ nonzeroCount [] * (2^64 * 10^9 - 1) :=
  sum_le_nonzero [] (by simp)

end LidoSRv3.Tests.SourceTopupBeaconSumBoundKillLines
