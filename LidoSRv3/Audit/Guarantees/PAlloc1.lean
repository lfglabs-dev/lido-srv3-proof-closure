import LidoSRv3.Legacy.Model
import LidoSRv3.Audit.Source.AllocCapacityCorrespondence
import LidoSRv3.Audit.Guarantees.Registry

namespace LidoSRv3.Audit.Guarantees.PAlloc1

def guarantee : Guarantee := ⟨.pAlloc1, [.model, .source]⟩

/--
For an active module, the executable SRv3 allocation-capacity row is bounded
both by the stake-share target and by the currently available capacity. This is
a legacy pure-model regression theorem; source and EVM correspondence remain
explicitly open.
-/
theorem active_capacity_bounded
    (cfg : LidoSRv3.AllocationConfig) (modules : List LidoSRv3.Module)
    (depositsToAllocate : Nat) (isTopUp : Bool) (module : LidoSRv3.Module)
    (hActive : module.status = LidoSRv3.ModuleStatus.active) :
    (LidoSRv3.allocationCapacityRow cfg modules depositsToAllocate isTopUp module).capacity ≤
        (LidoSRv3.allocationCapacityRow cfg modules depositsToAllocate isTopUp module).targetValidators ∧
      (LidoSRv3.allocationCapacityRow cfg modules depositsToAllocate isTopUp module).capacity ≤
        LidoSRv3.moduleAvailableCapacityEquivalent cfg isTopUp module := by
  constructor
  · simpa [LidoSRv3.allocationCapacityRow, hActive] using
      Nat.min_le_left
        (LidoSRv3.moduleTargetValidators cfg modules depositsToAllocate module)
        (LidoSRv3.moduleAvailableCapacityEquivalent cfg isTopUp module)
  · simpa [LidoSRv3.allocationCapacityRow, hActive] using
      Nat.min_le_right
        (LidoSRv3.moduleTargetValidators cfg modules depositsToAllocate module)
        (LidoSRv3.moduleAvailableCapacityEquivalent cfg isTopUp module)

/--
Pinned-source allocation-capacity correspondence for
`SRLib._getModulesAllocationAndCapacity` at
`lidofinance/core@af095e48bbc1c3841c2c9936219c8461af01056b`,
`contracts/0.8.25/sr/SRLib.sol`, lines 493--559 (reached from
`StakingRouter.getDepositAllocations`, lines 929--936, via
`SRLib._getDepositAllocations`, lines 391--431).

Given router-order and field correspondence, the source-shaped second loop
(lines 539--558) assigns every module exactly the capacity carried by the Lean
model's `allocationCapacityRow`, so the source `_capacities` array equals the
model's capacity column.

This theorem is deliberately capacity-only: it excludes the proportional
allocation amounts computed downstream by `MinFirstAllocationStrategy.allocate`
(source lines 391--431 tail), and it reads `uint256` arithmetic as unbounded
`Nat`, so checked-Uint256 execution and EVM correspondence remain open.
-/
theorem source_capacities_match_model
    (cfg : LidoSRv3.AllocationConfig) (modules : List LidoSRv3.Module)
    (srcs : List SolidityAllocCapacity.SourceModule)
    (depositsToAllocate : Nat) (isTopUp : Bool)
    (hCfg : cfg.maxEBType1 ≠ 0)
    (hRows : SolidityAllocCapacity.RowsCorrespond cfg modules srcs) :
    SolidityAllocCapacity.capacities cfg.maxEBType1 cfg.maxEBType2 isTopUp
        depositsToAllocate srcs
      = LidoSRv3.allocatedCapacityValues
          (LidoSRv3.modulesAllocationAndCapacity cfg modules depositsToAllocate isTopUp) :=
  SolidityAllocCapacity.capacities_eq_model_capacities hCfg hRows

/--
The pinned-source `Math.min(targetValidators, validatorsCapacity)` clamp at
`SRLib.sol` line 554 is bounded by both of its arguments for an active module.

This lifts `active_capacity_bounded` from the legacy pure model onto the
source-shaped capacity computation: the same two bounds now hold of the value
produced by the encoded Solidity loop, not only of the handwritten model row.
-/
theorem source_active_capacity_bounded
    (cfg : LidoSRv3.AllocationConfig) (modules : List LidoSRv3.Module)
    (srcs : List SolidityAllocCapacity.SourceModule)
    (depositsToAllocate : Nat) (isTopUp : Bool)
    (module : LidoSRv3.Module) (src : SolidityAllocCapacity.SourceModule)
    (hCfg : cfg.maxEBType1 ≠ 0)
    (hRows : SolidityAllocCapacity.RowsCorrespond cfg modules srcs)
    (hModule : SolidityAllocCapacity.ModuleCorresponds cfg module src)
    (hActive : module.status = LidoSRv3.ModuleStatus.active) :
    SolidityAllocCapacity.capacityEntry cfg.maxEBType1 cfg.maxEBType2 isTopUp
        (SolidityAllocCapacity.totalValidators cfg.maxEBType1 depositsToAllocate srcs) src ≤
        LidoSRv3.moduleTargetValidators cfg modules depositsToAllocate module ∧
      SolidityAllocCapacity.capacityEntry cfg.maxEBType1 cfg.maxEBType2 isTopUp
        (SolidityAllocCapacity.totalValidators cfg.maxEBType1 depositsToAllocate srcs) src ≤
        LidoSRv3.moduleAvailableCapacityEquivalent cfg isTopUp module := by
  have hEq :=
    SolidityAllocCapacity.capacityEntry_eq_model_capacity
      (depositsToAllocate := depositsToAllocate) (isTopUp := isTopUp) hCfg hRows hModule
  have hBounds :=
    active_capacity_bounded cfg modules depositsToAllocate isTopUp module hActive
  refine ⟨hEq ▸ ?_, hEq ▸ hBounds.2⟩
  simpa [LidoSRv3.allocationCapacityRow, hActive] using hBounds.1

end LidoSRv3.Audit.Guarantees.PAlloc1
