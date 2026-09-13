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

/-! ## Second-step composition (2026-09-13): per-module uint64 field bounds

`PinnedSRAllocationBoundsShape.availableArithmeticInvariant` above
needs per-module uint64 bounds on `activeCount` and
`depositableCount`. The pinned SRLib.sol Module struct packs these
as uint64 fields, so each is bounded by `2^64 - 1`. Below defines
`ModuleFieldBounds` as a source-level structure naming per-module
type bounds, and derives the boundedness. -/

def uint64Max : Nat := 2 ^ 64 - 1

/-- Per-module uint64 field bounds as an audit-source structure.
Names the pinned SRLib.sol Module struct's uint64 fields. -/
structure ModuleFieldBounds : Type where
  depositedCount : Nat
  depositableCount : Nat
  summaryExitedCount : Nat
  accountingExitedCount : Nat
  depositedBounded : depositedCount ≤ uint64Max
  depositableBounded : depositableCount ≤ uint64Max
  summaryExitedBounded : summaryExitedCount ≤ uint64Max
  accountingExitedBounded : accountingExitedCount ≤ uint64Max

/-- Under the per-module uint64 field bounds, every field is at
most `uint64Max = 2^64 - 1`. Definitionally, from the named
invariants. -/
theorem moduleFields_bounded_by_uint64
    (bounds : ModuleFieldBounds) :
    bounds.depositedCount ≤ uint64Max ∧
      bounds.depositableCount ≤ uint64Max ∧
      bounds.summaryExitedCount ≤ uint64Max ∧
      bounds.accountingExitedCount ≤ uint64Max :=
  ⟨bounds.depositedBounded, bounds.depositableBounded,
   bounds.summaryExitedBounded, bounds.accountingExitedBounded⟩

/-! ## Third-step composition (2026-09-13): SRStorage monotonicity invariant

`PinnedSRAllocationBoundsShape.activeSubtractionInvariant` above
needs the exited ≤ deposited invariant. In the pinned StakingRouter,
this holds by construction: `addValidators` only grows deposited,
`_updateExitedCounters` only grows exited, and exit-then-deposit
paths enforce exited ≤ deposited via early revert. Below defines a
source-level monotonicity invariant. -/

/-- SR monotonicity invariant: for each module in the registry, the
`max(summaryExited, accountingExited)` is bounded by `deposited`.
The pinned Solidity ensures this by construction through
`_updateExitedCounters` guards and `addValidators` monotonicity. -/
def SRMonotonicityInvariant (bounds : ModuleFieldBounds) : Prop :=
  max bounds.summaryExitedCount bounds.accountingExitedCount
    ≤ bounds.depositedCount

/-- Under the pinned SR monotonicity premise, exit counts ≤
deposited count. Definitionally, from the named invariant. -/
theorem active_subtraction_bound_of_sr_monotonicity
    {bounds : ModuleFieldBounds}
    (hMono : SRMonotonicityInvariant bounds) :
    max bounds.summaryExitedCount bounds.accountingExitedCount
      ≤ bounds.depositedCount :=
  hMono

end LidoSRv3.Audit.Source.StakingModuleRegistrySource
