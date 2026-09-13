import LidoSRv3.Audit.Verity.AllocationTx

/-!
Kill-lines pinning `Verity.AllocationTx` `persistRows` structure and
the `allocate` empty-count witness at Contract.run level.
-/

namespace LidoSRv3.Tests.VerityAllocationTxPersistExecuteKillLines

open LidoSRv3.Audit.Verity.AllocationTx
open LidoSRv3.Audit.AllocCapacity

/-! ## `persistRows` on empty rows/addresses is definitionally three
    writes to three empty arrays. -/

theorem persistRows_empty (state : Verity.ContractState) :
    persistRows [] [] state =
      ((state.writeArray allocationSlot []
        ).writeArray capacitySlot []
        ).writeArray boundAddressSlot [] := rfl

/-! ## `sourceExecute` on empty modules — computes empty rows with
    total = depositsToAllocate. -/

theorem sourceExecute_empty
    (cfg : Config) (depositsToAllocate : Word) (isTopUp : Bool) :
    sourceExecute cfg [] depositsToAllocate isTopUp =
      some ([], depositsToAllocate) := rfl

/-! ## `allocateFromStorage` reduces to `allocate` with count from slot. -/

theorem allocateFromStorage_reduces
    (cfg : Config) (depositsToAllocate : Word) (isTopUp : Bool)
    (failAfterWrites : Bool) (state : Verity.ContractState) :
    allocateFromStorage cfg depositsToAllocate isTopUp failAfterWrites state =
      allocate (min (state.readSlot modulesCountSlot).val 32)
        cfg depositsToAllocate isTopUp failAfterWrites state := rfl

/-! ## `Result` decEq on empty columns. -/

private def emptyResult (n : Word) : Result :=
  { allocations := [], capacities := [], moduleAddresses := [], totalValidators := n }

theorem emptyResult_decEq_self (n : Word) :
    (decide (emptyResult n = emptyResult n)) = true := by
  simp [emptyResult]

end LidoSRv3.Tests.VerityAllocationTxPersistExecuteKillLines
