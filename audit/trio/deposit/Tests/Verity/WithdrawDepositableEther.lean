import audit.trio.deposit.WithdrawDepositableEther
import audit.trio.deposit.Tests.Verity.Deposit

namespace audit.trio.deposit.Tests.Verity.WithdrawDepositableEther

open LidoSRv3.Audit.Source.TrioAlloc1
open LidoSRv3.Audit.Source.TrioReserve1
open audit.trio.deposit
open audit.trio.deposit.WithdrawDepositableEther

def values : DepositValues := ⟨64, 2, 64, 32, 64⟩

example : (amount values).val = 64 := by native_decide
example : (amount values).val ≤ values.selectedAllocationWei := by native_decide

/-- The suffix amount is the pull derived from actual returned keys, not the
larger allocation request or the per-validator beacon value. -/
example : (amount values).val = values.actualKeys * 32 := by native_decide
example : (amount values).val ≠ values.beaconPerKeyWei := by native_decide

/-- Zero returned keys execute the router's early return: no Lido call, no
fault, no world change, and no attempted external calls. -/
def zeroValues : DepositValues := ⟨64, 0, 0, 32, 0⟩

example (external : External) (ctx : Context) (before : World) :
    Live.run (suffix external ctx zeroValues) before = ⟨.ok (), before, []⟩ := by
  rfl

/-- The nonzero suffix fixes the deprecated seed argument to the actual key
count; callers cannot choose it independently. -/
example : (seedDepositsCount values).val = values.actualKeys := by native_decide

/-- The exact source-derived suffix composes with the complete RESERVE-1 call. -/
example (external : External) (ctx : Context) (before : World) :
    let result := Live.run (suffix external ctx values) before
    DescribesSuffix external ctx values before result.world result.outcome result.attempts := by
  exact deposit_execution_composes_suffix layout storage oracle config (word 65) [] successfulAfter
    (word 7) limits exactTargetModule 32 exactWithdrawal
    successfulExecution successfulRun_eq external ctx before

end audit.trio.deposit.Tests.Verity.WithdrawDepositableEther
