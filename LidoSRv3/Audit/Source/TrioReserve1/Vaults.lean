import LidoSRv3.Audit.Source.TrioReserve1.VaultCallbacks

namespace LidoSRv3.Audit.Source.TrioReserve1.Vaults
open Live

/-- Pinned LidoExecutionLayerRewardsVault.sol:85-95. The amount is capped by
actual current balance, not assumed equal to the report input. A zero result
skips Lido's callback and returns an encoded zero word. -/
def rewards (external : External) (ctx : Context) (lido : Address) (maximum : Word) : Exec Word := do
  require (ctx.sender = lido) (.reason "ONLY_LIDO_CAN_WITHDRAW")
  let balance ← (fun w => (⟨.ok (w.balances ctx.self), w, []⟩ : Result Nat))
  let amount := min balance maximum.val
  if amount > 0 then
    let _ ← call external ctx lido 0x4ad509b2 (word amount)
    pure ()
  pure (word amount)

/-- Pinned WithdrawalVault.sol:107-122. Admission precedes zero/funds checks.
Custom-error arguments retain requested and observed balance in that order. -/
def withdrawals (external : External) (ctx : Context) (lido : Address) (amount : Word) : Exec Unit := do
  require (ctx.sender = lido) (.bubbled (encode 4 0x25a81d75))
  require (amount.val ≠ 0) (.bubbled (encode 4 0x1f2a2005))
  let balance ← (fun w => (⟨.ok (w.balances ctx.self), w, []⟩ : Result Nat))
  require (amount.val ≤ balance) (.bubbled (encode 4 0x41ba67b6 ++ encode 32 amount.val ++ encode 32 balance))
  let _ ← call external ctx lido 0x78ffcfe2 amount
  pure ()

/-- Nonpayable single-word entry dispatch. ABI-short calls fail before bodies;
trailing bytes are accepted. The immutable LIDO binding is an explicit config. -/
def dispatch (external : External) (rewardVault withdrawalVault lido : Address) (other : External) : External := fun req w =>
  if req.target = rewardVault ∧ req.payload.take 4 = encode 4 0x9342c8f4 then
    if req.value.val ≠ 0 ∨ req.payload.length < 36 then .rejected []
    else
      let maximum := word (decode ((req.payload.drop 4).take 32))
      ReplyABI.reply (fun value => encode 32 value.val) (rewards external ⟨rewardVault, req.caller⟩ lido maximum) w
  else if req.target = withdrawalVault ∧ req.payload.take 4 = encode 4 0x3194528a then
    if req.value.val ≠ 0 ∨ req.payload.length < 36 then .rejected []
    else
      let amount := word (decode ((req.payload.drop 4).take 32))
      ReplyABI.reply (fun _ => []) (withdrawals external ⟨withdrawalVault, req.caller⟩ lido amount) w
  else other req w

/-- The capped reward fits the return/value word and is funded even when the
explicit world's raw Nat balance is larger than a machine word. -/
theorem reward_amount_bound (balance : Nat) (maximum : Word) :
    (word (min balance maximum.val)).val = min balance maximum.val ∧
      (word (min balance maximum.val)).val ≤ balance := by
  have hbound : min balance maximum.val < Verity.Core.UINT256_MODULUS :=
    Nat.lt_of_le_of_lt (Nat.min_le_right balance maximum.val) maximum.isLt
  have he : (word (min balance maximum.val)).val = min balance maximum.val := by
    exact Nat.mod_eq_of_lt hbound
  refine ⟨he, ?_⟩
  rw [he]
  exact Nat.min_le_left balance maximum.val

end LidoSRv3.Audit.Source.TrioReserve1.Vaults
