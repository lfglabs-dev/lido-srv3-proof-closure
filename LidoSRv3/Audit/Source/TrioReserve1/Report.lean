import LidoSRv3.Audit.Source.TrioReserve1.CallData
import LidoSRv3.Audit.Source.TrioReserve1.Writers

namespace LidoSRv3.Audit.Source.TrioReserve1.Report
open Live

structure Inputs where
  timestamp : Word
  clBalance : Word
  principal : Word
  withdrawals : Word
  rewards : Word
  lastRequest : Word
  shareRate : Word
  lockAmount : Word

/-- The report captures its locator once, before accounting authorization.
Each later getter calls that saved address, even if a callee changes the slot. -/
def lookup (external : External) (ctx : Context) (locator : Address) (selector : Nat) : Exec Address := do
  let data ← call external ctx locator selector
  let address ← decodeWord data
  pure (Verity.Core.Address.ofNat address.val)

/-- Lido.sol:1103-1119. Buffer is read after all external effects. Checked full-word
arithmetic precedes low-128 narrowing; the event retains the full computed amount.
The packed upper half is read at the write and preserved. Reserve rebalance follows. -/
def afterCalls (ctx : Context) (input : Inputs) : Exec Unit := do
  let packed ← read ctx bufferSlot
  let collectedRewards ← checkedAdd (packed.val % width) input.rewards.val
  let collectedWithdrawals ← checkedAdd collectedRewards input.withdrawals.val
  let post ← checkedSub collectedWithdrawals input.lockAmount.val
  let atWrite ← read ctx bufferSlot
  write ctx bufferSlot (pack post (atWrite.val / width))
  updateBufferedEtherAllocation ctx
  emit ctx "ETHDistributed" [input.timestamp, input.principal, input.clBalance,
    input.withdrawals, input.rewards, word post]

/-- Pinned Lido.sol:1072-1119, collectRewardsAndProcessWithdrawals body.
The ABI entry dispatch/nonpayable check and deployed vault/queue implementation
binding remain external obligations. Every body call and its ordering is explicit. -/
def collect (external : External) (ctx : Context) (input : Inputs) : Exec Unit := do
  let active ← read ctx activeSlot
  require (active.val ≠ 0) (.reason "CONTRACT_IS_STOPPED")
  let locator ← getLidoLocator ctx
  let accounting ← lookup external ctx locator 0x9624e83e
  require (ctx.sender = accounting) (.reason "APP_AUTH_FAILED")
  if input.rewards.val > 0 then
    let vault ← lookup external ctx locator 0xe441d25f
    let _ ← CallData.invoke external ctx vault
      (encode 4 0x9342c8f4 ++ encode 32 input.rewards.val)
    pure ()
  if input.withdrawals.val > 0 then
    let vault ← lookup external ctx locator 0x69d42148
    let _ ← CallData.invoke external ctx vault
      (encode 4 0x3194528a ++ encode 32 input.withdrawals.val)
    pure ()
  if input.lockAmount.val > 0 then
    let queue ← lookup external ctx locator 0x37d5fe99
    let _ ← CallData.invoke external ctx queue
      (encode 4 0xb6013cef ++ encode 32 input.lastRequest.val ++ encode 32 input.shareRate.val) input.lockAmount
    pure ()
  afterCalls ctx input

theorem stopped (external : External) (ctx : Context) (input : Inputs) (before : World)
    (h : (before.core.readContractSlot ctx.self.val activeSlot).val = 0) :
    run (collect external ctx input) before = ⟨.error (.reason "CONTRACT_IS_STOPPED"), before, []⟩ := by
  simp [collect, run, Live.read, require, bind, bindExec, fail, h]

end LidoSRv3.Audit.Source.TrioReserve1.Report
