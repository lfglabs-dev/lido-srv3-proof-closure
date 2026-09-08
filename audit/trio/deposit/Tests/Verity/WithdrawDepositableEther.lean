import audit.trio.deposit.WithdrawDepositableEther
import audit.trio.deposit.Tests.Verity.Deposit

namespace audit.trio.deposit.Tests.Verity.WithdrawDepositableEther

open LidoSRv3.Audit.Source.TrioAlloc1
open audit.trio.deposit
open audit.trio.deposit.WithdrawDepositableEther

def values : DepositValues := ⟨64, 2, 64, 32, 64⟩

example : (amount values).val = 64 := by native_decide
example : (amount values).val ≤ values.selectedAllocationWei := by native_decide

/-- The suffix amount is the pull derived from actual returned keys, not the
larger allocation request or the per-validator beacon value. -/
example : (amount values).val = values.actualKeys * 32 := by native_decide
example : (amount values).val ≠ values.beaconPerKeyWei := by native_decide

end audit.trio.deposit.Tests.Verity.WithdrawDepositableEther
