/-!
# GWEI unit and the leftover-budget walk (source layer)

Lower-layer home for the two P-TOPUP-2 building blocks that source-plane
consumers need: the gwei unit the gateway aligns to, and the left-to-right
`consumeBudget` walk.  They live here so source modules (for example
`LidoSRv3.Audit.Source.TopupWeiAlloc`) can cite them without a
Source → Guarantees import edge.  `LidoSRv3.Audit.Guarantees.PTopup2`
re-exports both names; its registered theorems are unchanged.

Pinned `lidofinance/core@17005714f151e5502c559932319a3f2f74ac2436`:

* `TopUpGateway.sol:226` `topUpLimits[i] = _evaluateTopUpLimit(...) * 1 gwei`
* `StakingRouter.sol:696` `maxTopUpPerBlockWei = maxTopUpPerBlockGwei * 1 gwei`
* `StakingRouter.sol:706` / `:724` `amount % 1 gwei` alignment
-/

namespace LidoSRv3.Audit.Source.TopupBudget

/-- One Gwei in wei.  The gateway rejects values not aligned to this unit. -/
def GWEI : Nat := 10 ^ 9

/-- Consume `budget` from left to right.  This is the state transition from
per-validator candidate amounts to actual allocations. -/
def consumeBudget : Nat → List Nat → List Nat
  | _, [] => []
  | budget, amount :: amounts =>
      let allocated := min amount budget
      allocated :: consumeBudget (budget - allocated) amounts

end LidoSRv3.Audit.Source.TopupBudget
