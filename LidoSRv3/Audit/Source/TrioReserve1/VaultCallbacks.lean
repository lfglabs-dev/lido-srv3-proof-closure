import LidoSRv3.Audit.Source.TrioReserve1.ReplyABI

namespace LidoSRv3.Audit.Source.TrioReserve1.VaultCallbacks
open Live

def totalRewardsSlot : Nat := 0xafe016039542d12eec0183bb0b1ffc2ca45b027126a494672fba4154ee77facb

/-- Lido.sol:517-522. Incoming value is already credited by CALL. This callback
has no pause/zero-value guard, looks up the authorized vault afresh, checks the
full reward-counter addition and emits only after writing that counter. -/
def receiveRewards (external : External) (ctx : Context) (value : Word) : Exec Unit := do
  let vault ← locatorAddress external ctx 0xe441d25f
  require (ctx.sender = vault) (.reason "APP_AUTH_FAILED")
  let total ← read ctx totalRewardsSlot
  let updated ← checkedAdd total.val value.val
  write ctx totalRewardsSlot (word updated)
  emit ctx "ELRewardsReceived" [value]

/-- Lido.sol:530-533. Withdrawal acquisition performs fresh address admission
and emits an event; it does not itself add to the stored pool buffer. -/
def receiveWithdrawals (external : External) (ctx : Context) (value : Word) : Exec Unit := do
  let vault ← locatorAddress external ctx 0x69d42148
  require (ctx.sender = vault) (.reason "APP_AUTH_FAILED")
  emit ctx "WithdrawalsReceived" [value]

/-- Payable no-argument callback dispatch. Extra calldata after the selector is
ignored, as for the pinned no-argument entry. Other code remains delegated. -/
def dispatch (external : External) (self : Address) (other : External) : External := fun req w =>
  if req.target = self ∧ req.payload.take 4 = encode 4 0x4ad509b2 then
    ReplyABI.reply (fun _ => []) (receiveRewards external ⟨self, req.caller⟩ req.value) w
  else if req.target = self ∧ req.payload.take 4 = encode 4 0x78ffcfe2 then
    ReplyABI.reply (fun _ => []) (receiveWithdrawals external ⟨self, req.caller⟩ req.value) w
  else other req w

end LidoSRv3.Audit.Source.TrioReserve1.VaultCallbacks
