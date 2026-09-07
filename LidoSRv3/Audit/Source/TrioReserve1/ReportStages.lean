import LidoSRv3.Audit.Source.TrioReserve1.Report
import LidoSRv3.Audit.Source.TrioReserve1.WithdrawalTail

namespace LidoSRv3.Audit.Source.TrioReserve1.ReportStages
open Live

def rewards (external : External) (ctx : Context) (locator : Address) (input : Report.Inputs) : Exec Unit := do
  if input.rewards.val > 0 then
    let vault ← Report.lookup external ctx locator 0xe441d25f
    let data ← CallData.invoke external ctx vault (encode 4 0x9342c8f4 ++ encode 32 input.rewards.val)
    let _ ← decodeWord data
    pure ()

def withdrawals (external : External) (ctx : Context) (locator : Address) (input : Report.Inputs) : Exec Unit := do
  if input.withdrawals.val > 0 then
    let vault ← Report.lookup external ctx locator 0x69d42148
    let _ ← CallData.invoke external ctx vault (encode 4 0x3194528a ++ encode 32 input.withdrawals.val)
    pure ()

def finalize (external : External) (ctx : Context) (locator : Address) (input : Report.Inputs) : Exec Unit := do
  if input.lockAmount.val > 0 then
    let queue ← Report.lookup external ctx locator 0x37d5fe99
    let _ ← CallData.invoke external ctx queue
      (encode 4 0xb6013cef ++ encode 32 input.lastRequest.val ++ encode 32 input.shareRate.val) input.lockAmount
    pure ()

/-- Decomposition retains one captured locator through all later getters. The
reward stage validates its unused uint256 return before any subsequent stage. -/
theorem source_decomposition (external : External) (ctx : Context) (input : Report.Inputs) :
    Report.collect external ctx input = (do
      let active ← Live.read ctx activeSlot
      require (active.val ≠ 0) (.reason "CONTRACT_IS_STOPPED")
      let locator ← getLidoLocator ctx
      let accounting ← Report.lookup external ctx locator 0x9624e83e
      require (ctx.sender = accounting) (.reason "APP_AUTH_FAILED")
      rewards external ctx locator input
      withdrawals external ctx locator input
      finalize external ctx locator input
      Report.afterCalls ctx input) := by
  by_cases hr : input.rewards.val > 0 <;> by_cases hw : input.withdrawals.val > 0 <;>
    by_cases hl : input.lockAmount.val > 0 <;>
    simp only [Report.collect, rewards, withdrawals, finalize, hr, hw, hl,
      ite_true, ite_false, bind, WithdrawalTail.bind_assoc]

end LidoSRv3.Audit.Source.TrioReserve1.ReportStages
