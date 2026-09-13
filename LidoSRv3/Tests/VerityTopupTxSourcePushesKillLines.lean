import LidoSRv3.Audit.Verity.TopupTx

/-! # Kill-lines for `Verity.TopupTx.sourcePushes` and `evmWord`

**Chantier 1 (Piste A, Thomas 2026-09-13) mutant kill-lines pinning
the pinned BeaconChainDepositor.sol:89 `if (amount == 0) continue`
skip and per-loop-iteration index accumulation. -/

namespace LidoSRv3.Tests.VerityTopupTxSourcePushesKillLines

open LidoSRv3.Audit.Verity.TopupTx

/-- **Kill-line: empty allocations yields no pushes.** -/
theorem sourcePushes_empty (index : Nat) :
    sourcePushes [] index = [] := rfl

/-- **Kill-line: single-zero amount is skipped.**

A mutant that dropped the `if amount = 0` skip would push a
zero-value beacon frame. -/
theorem sourcePushes_single_zero :
    sourcePushes [0] 5 = [] := rfl

/-- **Kill-line: single non-zero amount is pushed with its index.** -/
theorem sourcePushes_single_nonzero :
    sourcePushes [7] 3 = [(3, 7)] := rfl

/-- **Kill-line: two-item list zero-then-nonzero skips index 0.**

Index continues past the skipped item; the retained pair uses the
skipped item's index+1. -/
theorem sourcePushes_zero_nonzero :
    sourcePushes [0, 5] 0 = [(1, 5)] := rfl

/-- **Kill-line: two-item list nonzero-then-zero retains only the first.** -/
theorem sourcePushes_nonzero_zero :
    sourcePushes [5, 0] 0 = [(0, 5)] := rfl

/-- **Kill-line: two nonzeros produce two pairs in order.** -/
theorem sourcePushes_two_nonzero :
    sourcePushes [3, 4] 0 = [(0, 3), (1, 4)] := rfl

/-- **Kill-line: `evmWord n = n % 2^256`.**

A mutant that changed the modulus would refute the pinned Solidity
EVM word semantics. -/
theorem evmWord_composition (n : Nat) :
    evmWord n = n % (2 ^ 256) := rfl

/-- **Kill-line: `evmWord 0 = 0`.** -/
theorem evmWord_zero : evmWord 0 = 0 := rfl

/-- **Kill-line: `evmWord (2^256) = 0` (wrap boundary).**

Concrete witness of modular wrapping at the EVM word boundary. -/
theorem evmWord_wraps :
    evmWord (2 ^ 256) = 0 := by decide

#print axioms sourcePushes_empty
#print axioms sourcePushes_single_zero
#print axioms sourcePushes_zero_nonzero
#print axioms sourcePushes_two_nonzero
#print axioms evmWord_composition
#print axioms evmWord_wraps

end LidoSRv3.Tests.VerityTopupTxSourcePushesKillLines
