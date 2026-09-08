import PAccount1

namespace AccountAddress.Tests.Verity.PAccount1Test
open AccountAddress.PAccount1

def before : State :=
  { modules := [{ word := 7 * two64 + 4 }, { word := 9 * two64 + 5 }]
    router := { word := 11 * two64 + 6 } }

def valid : Input :=
  { registeredModuleIds := [1, 4], reportedModuleIds := [1, 4]
    balancesGwei := [20, 30] }

example : reportValidatorBalances valid before = .committed
    { modules := [{ word := 7 * two64 + 20 }, { word := 9 * two64 + 30 }]
      router := { word := 11 * two64 + 50 } } := by native_decide

example : reportValidatorBalances { valid with reportedModuleIds := [1, 5] } before =
    .reverted (.unexpectedModuleId 4 5) before := by native_decide

example : reportValidatorBalances { valid with balancesGwei := [20, maxValueGwei + 1] } before =
    .reverted (.invalidAmountGwei (maxValueGwei + 1)) before := by native_decide

/-- Dropping the uint64 checked-add guard admits a value the source rejects. -/
def uncheckedAdd64 (a b : Nat) : Nat := (a + b) % two64

theorem checked_add_mutant_killed :
    checkedAdd64 uint64Max 1 = .error .arithmeticOverflow ∧
    uncheckedAdd64 uint64Max 1 = 0 := by
  constructor <;> rfl

end AccountAddress.Tests.Verity.PAccount1Test
