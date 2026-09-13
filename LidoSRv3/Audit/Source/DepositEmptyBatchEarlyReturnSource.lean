/-! # StakingRouter.deposit empty-batch early return source model

**General rule (Thomas 2026-09-13, real derivation naming the
pinned StakingRouter.sol:978 empty-batch early-return semantics as a
source-level function.)**

Chantier: grok differential #412 flags D-EMPTY-PULL — the pinned
Solidity's `if (actualDepositsCount == 0) return;` at
`StakingRouter.sol:978` is not modeled by the Verity plane's
`DepositNFrameTx.execute`; the Verity plane still emits a
`pullFromLido inputs 0` frame in the empty-batch case.

This composition names the empty-batch semantics as a source-level
function of the batch count: `shouldPull` = `actualDepositsCount ≠ 0`.
Downstream consumers of a `DepositBatchContext` can gate the pull
frame emission on `shouldPull` and match the pinned source's
early-return.

Pinned Solidity (17005714):

- `StakingRouter.sol:978`: `if (actualDepositsCount == 0) return;`
  (empty-batch early return before the `withdrawDepositableEther`
  call and the per-key `deposit{value:32 ether}` frames).

**Status:** first real derivation naming the pinned line-978 early-
return semantics as a source-level function. Downstream consumers
can now gate frame emission on `shouldPull`. -/

namespace LidoSRv3.Audit.Source.DepositEmptyBatchEarlyReturnSource

/-- Source-level definition of the pinned line-978 early-return
condition: pull only when the aggregate deposit count is nonzero. -/
def shouldPull (actualDepositsCount : Nat) : Bool :=
  decide (actualDepositsCount ≠ 0)

/-- Under the pinned nonzero-count premise, `shouldPull = true`. -/
theorem shouldPull_true_of_nonzero
    {actualDepositsCount : Nat} (hNonzero : actualDepositsCount ≠ 0) :
    shouldPull actualDepositsCount = true := by
  simp [shouldPull, hNonzero]

/-- Under the pinned zero-count premise (line 978's early-return
branch), `shouldPull = false`. Real derivation of the D-EMPTY-PULL
divergence's source-level semantics. -/
theorem shouldPull_false_of_zero :
    shouldPull 0 = false := by
  simp [shouldPull]

end LidoSRv3.Audit.Source.DepositEmptyBatchEarlyReturnSource
