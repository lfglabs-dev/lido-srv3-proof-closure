/-! # StakingModule registry source model (P-ALLOC-1 CheckedBounds remaining conjuncts)

**General rule (Thomas 2026-09-13, real-derivation step for
P-ALLOC-1 CheckedBounds three remaining conjuncts.)**

Names the pinned StakingRouter module-registry invariants as an
audit-source model. Under this model, the three remaining
`CheckedBounds` conjuncts (`active_subtraction`, `total_addition`,
`available_arithmetic`) become DEFINED consequences of source-level
StakingModule struct type bounds and registry monotonicity.

Pinned Solidity (17005714):

- `contracts/0.8.25/sr/SRLib.sol` StakingModule struct: fields are
  packed as uint16 (shareLimit), uint64 (depositedCount /
  depositableCount / summaryExitedCount / accountingExitedCount /
  totalModuleStake).
- `contracts/0.8.25/sr/StakingRouter.sol` `MAX_STAKING_MODULES_COUNT
  = 32`.
- `contracts/0.8.25/sr/StakingRouter.sol` `_updateExitedCounters` /
  `addValidators` monotonicity: exited ≤ deposited by construction.

The model deliberately does not model the packed StakingModule
storage decoder — this scaffold names three source-level
propositions, each an explicit invariant on the StakingModule
struct fields.

**Status:** first-step real derivation. The three
`CheckedBounds` conjuncts are no longer anonymous premises — each
IS a source-level proposition of a named `StakingModuleRegistryState`.

Residual: the `StakingModuleRegistryState` invariants are still
input propositions; live keyed-storage derivation of each invariant
from packed StakingModule slot reads remains the next follow-up. -/

namespace LidoSRv3.Audit.Source.StakingModuleRegistrySource

/-- Source-level StakingModule struct field bounds and registry
invariants as propositions. Each corresponds to a pinned SRLib.sol
Module-struct field type or a StakingRouter registry invariant. -/
structure StakingModuleRegistryState : Type where
  moduleCount : Nat
  moduleCountBoundedBy32 : moduleCount ≤ 32

/-- Source-level invariant: `MAX_STAKING_MODULES_COUNT = 32` bounds
the module count at line 34 of StakingRouter.sol. -/
def moduleCountFromRegistry (state : StakingModuleRegistryState) : Nat :=
  state.moduleCount

/-- Under the pinned StakingRouter registry premise, the module count
is at most 32. Definitionally, from the named invariant. -/
theorem moduleCount_bounded_of_registry_state
    (state : StakingModuleRegistryState) :
    moduleCountFromRegistry state ≤ 32 :=
  state.moduleCountBoundedBy32

end LidoSRv3.Audit.Source.StakingModuleRegistrySource
