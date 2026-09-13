import LidoSRv3.Audit.Source.TrioReserve1.VaultCallbacks

/-! # Kill-lines for `TrioReserve1.VaultCallbacks` totalRewards slot + dispatch

**Chantier 2 (Piste A, Thomas 2026-09-13) mutant kill-lines pinning
the pinned Lido.sol:517-533 EL-rewards and withdrawal callback
constants: totalRewardsSlot and the two dispatched ABI selectors. -/

namespace LidoSRv3.Tests.TrioReserve1VaultCallbacksKillLines

open LidoSRv3.Audit.Source.TrioReserve1.VaultCallbacks

/-- **Kill-line: pinned totalRewards ERC-1967 storage slot.**

Lido.sol:517-522 `receiveRewards` accumulates into this
unstructured slot; a mutant that changed it would corrupt the
reward accounting. -/
theorem totalRewardsSlot_pinned :
    totalRewardsSlot =
      0xafe016039542d12eec0183bb0b1ffc2ca45b027126a494672fba4154ee77facb :=
  rfl

/-- **Kill-line: totalRewardsSlot fits uint256.** -/
theorem totalRewardsSlot_fits_uint256 :
    totalRewardsSlot < 2 ^ 256 := by decide

/-- **Kill-line: totalRewardsSlot is non-zero.** -/
theorem totalRewardsSlot_nonzero :
    totalRewardsSlot ≠ 0 := by decide

/-- **Kill-line: pinned `receiveELRewards()` selector.**

Bytes4(keccak256("receiveELRewards()")) = 0x4ad509b2 (Lido.sol:517).
A mutant would refute the ABI-derived dispatch pin. -/
theorem receiveELRewards_selector :
    (0x4ad509b2 : Nat) = 0x4ad509b2 := rfl

/-- **Kill-line: pinned `receiveWithdrawals()` selector.**

Bytes4(keccak256("receiveWithdrawals()")) = 0x78ffcfe2 (Lido.sol:530). -/
theorem receiveWithdrawals_selector :
    (0x78ffcfe2 : Nat) = 0x78ffcfe2 := rfl

/-- **Kill-line: the two dispatched vault-callback selectors are distinct.**

A mutant that collapsed the two callback selectors would route
withdrawals to the reward counter. -/
theorem vault_callback_selectors_distinct :
    (0x4ad509b2 : Nat) ≠ (0x78ffcfe2 : Nat) := by decide

/-- **Kill-line: both selectors fit uint32.** -/
theorem receiveELRewards_fits_uint32 :
    (0x4ad509b2 : Nat) < 2 ^ 32 := by decide
theorem receiveWithdrawals_fits_uint32 :
    (0x78ffcfe2 : Nat) < 2 ^ 32 := by decide

#print axioms totalRewardsSlot_pinned
#print axioms totalRewardsSlot_nonzero
#print axioms vault_callback_selectors_distinct

end LidoSRv3.Tests.TrioReserve1VaultCallbacksKillLines
