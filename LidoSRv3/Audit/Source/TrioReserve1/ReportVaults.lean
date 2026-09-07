import LidoSRv3.Audit.Source.TrioReserve1.CalleeRules

namespace LidoSRv3.Audit.Source.TrioReserve1.ReportVaults
open Live

/-- Concrete composed source interpreter. Unhandled callback and vault selectors,
including locator/queue services, remain the explicit boundary interpreter. -/
abbrev callbacks (boundary : External) (self : Address) : External :=
  VaultCallbacks.dispatch boundary self boundary

abbrev external (boundary : External) (self rewardVault withdrawalVault : Address) : External :=
  Vaults.dispatch (callbacks boundary self) rewardVault withdrawalVault self boundary

def CallbackReplies (boundary : External) (self : Address) : CalleeRules.Replies :=
  EntryRules.Callbacks boundary self boundary

theorem callback_observations (boundary : External) (self : Address) (req : Request) (w : World) (reply : Reply) :
    CallbackReplies boundary self req w reply ↔ callbacks boundary self req w = reply :=
  EntryRules.callbacks_corresponds boundary self boundary req w reply

def RewardBody (boundary : External) (self : Address) (ctx : Context) (maximum : Word) (before : World) :=
  VaultSpec.Rewards (.reason "ONLY_LIDO_CAN_WITHDRAW") word (ctx.sender = self)
    (before.balances ctx.self) maximum.val
    (fun amount => CalleeRules.Calls (CallbackReplies boundary self) ctx self (encode 4 0x4ad509b2) (word amount)) before

def WithdrawalBody (boundary : External) (self : Address) (ctx : Context) (amount : Word) (before : World) :=
  VaultSpec.Withdrawals (.bubbled (encode 4 0x25a81d75)) (.bubbled (encode 4 0x1f2a2005))
    (.bubbled (encode 4 0x41ba67b6 ++ encode 32 amount.val ++ encode 32 (before.balances ctx.self)))
    (ctx.sender = self) (before.balances ctx.self) amount.val
    (CalleeRules.Calls (CallbackReplies boundary self) ctx self (encode 4 0x78ffcfe2) amount) before

theorem reward_observations (boundary : External) (self : Address) (ctx : Context) (maximum : Word) :
    RewardBody boundary self ctx maximum = VaultRules.Rewards (callbacks boundary self) ctx self maximum := by
  unfold RewardBody VaultRules.Rewards
  simp only [CalleeRules.selector_observations _ _ (callback_observations boundary self)]

theorem withdrawal_observations (boundary : External) (self : Address) (ctx : Context) (amount : Word) :
    WithdrawalBody boundary self ctx amount = VaultRules.Withdrawals (callbacks boundary self) ctx self amount := by
  unfold WithdrawalBody VaultRules.Withdrawals
  simp only [CalleeRules.selector_observations _ _ (callback_observations boundary self)]

/-- Vault entry observations contain independent callback entries through the
CALL relation; they do not assume a successful callback or vault outcome. -/
def VaultReplies (boundary : External) (self rewardVault withdrawalVault : Address)
    (req : Request) (before : World) : Reply → Prop :=
  let argument := word (decode ((req.payload.drop 4).take 32))
  EntrySpec.Dispatch (req.target = rewardVault ∧ req.payload.take 4 = encode 4 0x9342c8f4)
    (req.target = withdrawalVault ∧ req.payload.take 4 = encode 4 0x3194528a)
    (req.value.val = 0 ∧ 36 ≤ req.payload.length) (.rejected []) (boundary req before)
    (EntryRules.Returns (fun value => encode 32 value.val)
      (VaultSpec.Root (RewardBody boundary self ⟨rewardVault, req.caller⟩ argument)) before)
    (EntryRules.Returns (fun _ => [])
      (VaultSpec.Root (WithdrawalBody boundary self ⟨withdrawalVault, req.caller⟩ argument)) before)

theorem vault_observations (boundary : External) (self rewardVault withdrawalVault : Address)
    (req : Request) (before : World) (reply : Reply) :
    VaultReplies boundary self rewardVault withdrawalVault req before reply ↔
      external boundary self rewardVault withdrawalVault req before = reply := by
  unfold VaultReplies
  rw [reward_observations, withdrawal_observations]
  exact EntryRules.vaults_corresponds (callbacks boundary self) rewardVault withdrawalVault self boundary req before reply

def lookup (replies : CalleeRules.Replies) (ctx : Context) (locator : Address) (selector : Nat) :=
  LookupSpec.Returns .empty List.length Lookup.decodedAddress
    (CalleeRules.Calls replies ctx locator (encode 4 selector) (word 0))

def stage (replies : CalleeRules.Replies) (ctx : Context) (locator : Address) (amount : Nat)
    (checkWord : Bool) (lookupSelector : Nat) (payload : Bytes) (value : Word) :=
  OptionalCallSpec.Executes .empty List.length amount checkWord
    (lookup replies ctx locator lookupSelector)
    (fun target => CalleeRules.Calls replies ctx target payload value)

/-- Full report rules with concrete independent vault and nested callback entry
observations. Only delegated services, codecs and physical primitive operations
remain explicit dependencies; there is no source report/vault/callback executor
in this expanded predicate. -/
def Describes (boundary : External) (rewardVault withdrawalVault : Address)
    (ctx : Context) (input : Report.Inputs) (before : World) :
    Except Fault Unit → World → List Attempt → Prop :=
  let replies := VaultReplies boundary ctx.self rewardVault withdrawalVault
  let locator := ReportParent.captured ctx before
  ReportSpec.Executes (.reason "CONTRACT_IS_STOPPED") (.reason "APP_AUTH_FAILED")
    ((before.core.readContractSlot ctx.self.val activeSlot).val ≠ 0) ctx.sender
    (lookup replies ctx locator 0x9624e83e)
    (stage replies ctx locator input.rewards.val true 0xe441d25f
      (encode 4 0x9342c8f4 ++ encode 32 input.rewards.val) (word 0))
    (stage replies ctx locator input.withdrawals.val false 0x69d42148
      (encode 4 0x3194528a ++ encode 32 input.withdrawals.val) (word 0))
    (stage replies ctx locator input.lockAmount.val false 0x37d5fe99
      (encode 4 0xb6013cef ++ encode 32 input.lastRequest.val ++ encode 32 input.shareRate.val) input.lockAmount)
    (fun w outcome after trace => ReportAccounting.Describes ctx input w ⟨outcome, after, trace⟩) before

theorem corresponds (boundary : External) (rewardVault withdrawalVault : Address)
    (ctx : Context) (input : Report.Inputs) (before after : World)
    (outcome : Except Fault Unit) (trace : List Attempt) :
    Describes boundary rewardVault withdrawalVault ctx input before outcome after trace ↔
      run (Report.collect (external boundary ctx.self rewardVault withdrawalVault) ctx input) before =
        ⟨outcome, after, trace⟩ := by
  unfold Describes stage lookup
  simp only [CalleeRules.calls_observations _ _ (vault_observations boundary ctx.self rewardVault withdrawalVault)]
  exact ReportRules.corresponds (external boundary ctx.self rewardVault withdrawalVault) ctx input before after outcome trace

theorem complete (boundary : External) (rewardVault withdrawalVault : Address)
    (ctx : Context) (input : Report.Inputs) (before : World) :
    let r := run (Report.collect (external boundary ctx.self rewardVault withdrawalVault) ctx input) before
    Describes boundary rewardVault withdrawalVault ctx input before r.outcome r.world r.attempts :=
  (corresponds boundary rewardVault withdrawalVault ctx input before _ _ _).mpr rfl

theorem failure_restores (boundary : External) (rewardVault withdrawalVault : Address)
    (ctx : Context) (input : Report.Inputs) (before after : World) (fault : Fault) (trace : List Attempt)
    (h : Describes boundary rewardVault withdrawalVault ctx input before (.error fault) after trace) : after = before :=
  ReportSpec.failure_restores h

end LidoSRv3.Audit.Source.TrioReserve1.ReportVaults
