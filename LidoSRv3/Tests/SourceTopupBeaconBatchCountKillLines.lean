import LidoSRv3.Audit.Source.TopupBeaconBatch

/-!
Kill-lines pinning `Source.TopupBeaconBatch` `nonzeroCount`
definition and empty/mismatch-length loop base cases.
-/

namespace LidoSRv3.Tests.SourceTopupBeaconBatchCountKillLines

open LidoSRv3.Audit.Source.TopupBeaconBatch

/-! ## `nonzeroCount` — count of nonzero amounts. -/

theorem nonzeroCount_empty : nonzeroCount [] = 0 := rfl

theorem nonzeroCount_all_zero :
    nonzeroCount [0, 0, 0] = 0 := by decide

theorem nonzeroCount_mixed :
    nonzeroCount [0, 5, 0, 10] = 2 := by decide

theorem nonzeroCount_all_positive :
    nonzeroCount [1, 2, 3] = 3 := by decide

/-! ## `nonzeroCount` filter definition. -/

theorem nonzeroCount_reduces (amounts : List Nat) :
    nonzeroCount amounts = (amounts.filter fun a => a ≠ 0).length := rfl

end LidoSRv3.Tests.SourceTopupBeaconBatchCountKillLines
