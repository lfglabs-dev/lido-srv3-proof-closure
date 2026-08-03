import LidoSRv3.Audit.Guarantees.PAccount1

/-! Executable positive and mutant-sensitive negative fixtures for P-ACCOUNT-1. -/

namespace LidoSRv3.Tests.AccountingVectors

open LidoSRv3.Audit.SolidityAccounting

private def word (n : Nat) : Word := Verity.Core.Uint256.ofNat n
private def before : AccountingState := ⟨[word 1, word 2], [word 10, word 20], word 30⟩
private def valid : TxInput := ⟨true, true, ⟨[word 1, word 2], [word 40, word 50]⟩⟩

/- Positive: the two module fields and their checked aggregate commit. -/
example : sourceRun before valid =
    .committed ⟨[word 1, word 2], [word 40, word 50], word 90⟩ := by decide
example : (observeVerityTx before valid).outcome =
    .committed ⟨[word 1, word 2], [word 40, word 50], word 90⟩ := by decide

/- AccountingOracle.sol:614-616 returns before the role-gated router call. -/
private def emptyBefore : AccountingState := ⟨[], [], word 0⟩
private def emptyUnauthorized : TxInput := ⟨false, true, ⟨[], []⟩⟩
example : sourceRun emptyBefore emptyUnauthorized = .committed emptyBefore := by decide

/- Dropping SRLib.sol:866 would accept the wrong router order. -/
private def wrongOrder : TxInput :=
  { valid with report := ⟨[word 2, word 1], [word 40, word 50]⟩ }
example : sourceRun before wrongOrder = .reverted .unexpectedModuleId := by decide
example : (observeVerityTx before wrongOrder).outcome = .reverted .unexpectedModuleId := by decide

/- Replacing SRUtils.sol:79's one-billion-ether limit with a uint64 cast would
accept this value; the pinned bound rejects it. -/
private def aboveAmountLimit : Word := word (1_000_000_000 * 1_000_000_000 + 1)
example : sourceRun before
    { valid with report := ⟨[word 1, word 2], [aboveAmountLimit, word 0]⟩ }
      = .reverted .invalidAmountGwei := by decide
example : (observeVerityTx before
    { valid with report := ⟨[word 1, word 2], [aboveAmountLimit, word 0]⟩ }).outcome
      = .reverted .invalidAmountGwei := by decide

/- Making SRLib.sol:888 unchecked would wrap nineteen individually valid
maximum amounts. Checked uint64 addition reverts and restores state. -/
private def nineteen : List Word := List.replicate 19 maxAmountGwei
private def nineteenIds : List Word := (List.range 19).map (fun n => word (n + 1))
private def overflowBefore : AccountingState := ⟨nineteenIds, nineteen, word 7⟩
private def overflowInput : TxInput := ⟨true, true, ⟨nineteenIds, nineteen⟩⟩
example : sourceRun overflowBefore overflowInput = .reverted .totalBalanceOverflow := by decide
example : (observeVerityTx overflowBefore overflowInput).outcome =
    .reverted .totalBalanceOverflow := by decide
example : (observeVerityTx overflowBefore overflowInput).finalState = overflowBefore := by decide

end LidoSRv3.Tests.AccountingVectors
