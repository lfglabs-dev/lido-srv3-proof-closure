import LidoSRv3.Legacy.Model
import LidoSRv3.Audit.Guarantees.Registry

namespace LidoSRv3.Audit.Guarantees.PAlloc1

def guarantee : Guarantee := ⟨.pAlloc1, [.model]⟩

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

end LidoSRv3.Audit.Guarantees.PAlloc1
