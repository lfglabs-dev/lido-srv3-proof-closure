import LidoSRv3.Audit.Source.TrioReserve1.EntrySpec
import LidoSRv3.Audit.Source.TrioReserve1.CallbackRules

namespace LidoSRv3.Audit.Source.TrioReserve1.EntryRules
open Live

def Returns (encodeValue : α → Bytes)
    (transaction : World → Except Fault α → World → List Attempt → Prop) :=
  EntrySpec.Returns (fun value after trace => Reply.successWithTrace (encodeValue value) after (ReplyABI.nested trace))
    (fun fault trace => Reply.rejectedWithTrace (ReplyABI.fault fault) (ReplyABI.nested trace)) transaction

theorem returns_corresponds (program : Exec α) (encodeValue : α → Bytes)
    (transaction : World → Except Fault α → World → List Attempt → Prop)
    (ht : ∀ before after outcome trace,
      transaction before outcome after trace ↔ run program before = ⟨outcome, after, trace⟩)
    (before : World) (reply : Reply) :
    Returns encodeValue transaction before reply ↔ ReplyABI.reply encodeValue program before = reply := by
  constructor
  · intro h
    cases h with
    | success h => simp [ReplyABI.reply, (ht _ _ _ _).mp h]
    | failure h => simp [ReplyABI.reply, (ht _ _ _ _).mp h]
  · intro h
    generalize he : run program before = result at h
    rcases result with ⟨outcome, after, trace⟩
    have hd := (ht before after outcome trace).mpr he
    cases outcome with
    | ok value =>
      have hi : Reply.successWithTrace (encodeValue value) after (ReplyABI.nested trace) = reply := by
        simpa [ReplyABI.reply, he] using h
      rw [← hi]
      exact .success hd
    | error fault =>
      have hi : Reply.rejectedWithTrace (ReplyABI.fault fault) (ReplyABI.nested trace) = reply := by
        simpa [ReplyABI.reply, he] using h
      rw [← hi]
      exact .failure hd

theorem dispatch_corresponds {first second valid : Prop} [Decidable first] [Decidable second] [Decidable valid]
    (invalid fallback a b : Reply) (ar br : Reply → Prop)
    (ha : ∀ reply, ar reply ↔ a = reply) (hb : ∀ reply, br reply ↔ b = reply) (reply : Reply) :
    EntrySpec.Dispatch first second valid invalid fallback ar br reply ↔
      (if first then if valid then a else invalid else if second then if valid then b else invalid else fallback) = reply := by
  constructor
  · intro h
    cases h <;> simp_all
  · intro h
    by_cases hf : first
    · by_cases hv : valid
      · exact .first hf hv ((ha reply).mpr (by simpa [hf, hv] using h))
      · have he : invalid = reply := by simpa [hf, hv] using h
        rw [← he]; exact .first_invalid hf hv
    · by_cases hs : second
      · by_cases hv : valid
        · exact .second hf hs hv ((hb reply).mpr (by simpa [hf, hs, hv] using h))
        · have he : invalid = reply := by simpa [hf, hs, hv] using h
          rw [← he]; exact .second_invalid hf hs hv
      · have he : fallback = reply := by simpa [hf, hs] using h
        rw [← he]; exact .fallback hf hs

def Callbacks (external : External) (self : Address) (other : External) (req : Request) (before : World) :=
  EntrySpec.Dispatch (req.target = self ∧ req.payload.take 4 = encode 4 0x4ad509b2)
    (req.target = self ∧ req.payload.take 4 = encode 4 0x78ffcfe2) True (.rejected []) (other req before)
    (Returns (fun _ => []) (VaultSpec.Root (CallbackRules.Rewards external ⟨self, req.caller⟩ req.value)) before)
    (Returns (fun _ => []) (VaultSpec.Root (CallbackRules.Withdrawals external ⟨self, req.caller⟩ req.value)) before)

def Vaults (external : External) (rewardVault withdrawalVault lido : Address) (other : External)
    (req : Request) (before : World) :=
  let argument := word (decode ((req.payload.drop 4).take 32))
  EntrySpec.Dispatch (req.target = rewardVault ∧ req.payload.take 4 = encode 4 0x9342c8f4)
    (req.target = withdrawalVault ∧ req.payload.take 4 = encode 4 0x3194528a)
    (req.value.val = 0 ∧ 36 ≤ req.payload.length) (.rejected []) (other req before)
    (Returns (fun value => encode 32 value.val)
      (VaultSpec.Root (VaultRules.Rewards external ⟨rewardVault, req.caller⟩ lido argument)) before)
    (Returns (fun _ => [])
      (VaultSpec.Root (VaultRules.Withdrawals external ⟨withdrawalVault, req.caller⟩ lido argument)) before)

theorem callbacks_corresponds (external : External) (self : Address) (other : External)
    (req : Request) (before : World) (reply : Reply) :
    Callbacks external self other req before reply ↔ VaultCallbacks.dispatch external self other req before = reply := by
  unfold Callbacks
  rw [dispatch_corresponds _ _ _ _ _ _
    (returns_corresponds _ _ _ (CallbackRules.rewards_root_corresponds external ⟨self, req.caller⟩ req.value) before)
    (returns_corresponds _ _ _ (CallbackRules.withdrawals_root_corresponds external ⟨self, req.caller⟩ req.value) before)]
  simp only [VaultCallbacks.dispatch, if_true]

theorem vaults_corresponds (external : External) (rewardVault withdrawalVault lido : Address) (other : External)
    (req : Request) (before : World) (reply : Reply) :
    Vaults external rewardVault withdrawalVault lido other req before reply ↔
      LidoSRv3.Audit.Source.TrioReserve1.Vaults.dispatch external rewardVault withdrawalVault lido other req before = reply := by
  unfold Vaults
  rw [dispatch_corresponds _ _ _ _ _ _
    (returns_corresponds _ _ _ (VaultRules.rewards_root_corresponds external ⟨rewardVault, req.caller⟩ lido _) before)
    (returns_corresponds _ _ _ (VaultRules.withdrawals_root_corresponds external ⟨withdrawalVault, req.caller⟩ lido _) before)]
  unfold LidoSRv3.Audit.Source.TrioReserve1.Vaults.dispatch
  have he : (req.value.val ≠ 0 ∨ req.payload.length < 36) ↔
      ¬ (req.value.val = 0 ∧ 36 ≤ req.payload.length) := by omega
  simp only [he, ite_not]

theorem callbacks_complete (external : External) (self : Address) (other : External)
    (req : Request) (before : World) :
    Callbacks external self other req before (VaultCallbacks.dispatch external self other req before) :=
  (callbacks_corresponds external self other req before _).mpr rfl

theorem vaults_complete (external : External) (rewardVault withdrawalVault lido : Address) (other : External)
    (req : Request) (before : World) :
    Vaults external rewardVault withdrawalVault lido other req before
      (LidoSRv3.Audit.Source.TrioReserve1.Vaults.dispatch external rewardVault withdrawalVault lido other req before) :=
  (vaults_corresponds external rewardVault withdrawalVault lido other req before _).mpr rfl

end LidoSRv3.Audit.Source.TrioReserve1.EntryRules
