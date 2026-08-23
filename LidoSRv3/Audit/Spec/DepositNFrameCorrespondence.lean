import LidoSRv3.Audit.Spec
import LidoSRv3.Audit.Guarantees.PDeposit1

/-!
# List Spec.Allocation to n-frame deposit router

One executable batch is produced per allocation.  The validator-count-to-wei
multiply is explicit, so this does not merge an ALLOC parent into DEPOSIT.
-/

namespace LidoSRv3.Audit.Spec.DepositNFrameCorrespondence

open LidoSRv3.Audit.Spec
open LidoSRv3.Audit.SolidityDeposit
open LidoSRv3.Audit.Verity
open LidoSRv3.Audit.Verity.DepositNFrameTx
open _root_.Verity.Core

def allocationWei (allocation : Allocation) (depositSize : Nat) : Nat :=
  allocation.amount.value * depositSize

def routerBatch (cfg : SourceDepositConfig) (template : Batch)
    (allocation : Allocation) : Batch :=
  { template with
    moduleId := .ofNat allocation.moduleId
    keys := .ofNat allocation.amount.value
    amount := .ofNat (allocationWei allocation cfg.depositSize) }

/-- Generalized router: `List Spec.Allocation` replaces the old pair. -/
def routerDepositInputs (cfg : SourceDepositConfig)
    (inputTemplate : DepositNFrameTx.Inputs) (batchTemplate : Batch)
    (allocations : List Allocation) : DepositNFrameTx.Inputs :=
  { inputTemplate with
    depositSize := .ofNat cfg.depositSize
    batches := allocations.map (routerBatch cfg batchTemplate) }

structure RouterWordBounds (cfg : SourceDepositConfig)
    (allocations : List Allocation) : Prop where
  depositSize : cfg.depositSize < Uint256.modulus
  moduleIds : ∀ allocation ∈ allocations, allocation.moduleId < Uint256.modulus
  keys : ∀ allocation ∈ allocations, allocation.amount.value < Uint256.modulus
  wei : ∀ allocation ∈ allocations,
    allocationWei allocation cfg.depositSize < Uint256.modulus
  totalWei : (allocations.map fun allocation =>
    allocationWei allocation cfg.depositSize).sum < Uint256.modulus

theorem ofNat_val_of_lt {n : Nat} (h : n < Uint256.modulus) :
    (Uint256.ofNat n).val = n := by
  simp [Uint256.val_ofNat, Nat.mod_eq_of_lt h]

theorem router_batches_length (cfg : SourceDepositConfig)
    (inputTemplate : DepositNFrameTx.Inputs) (batchTemplate : Batch)
    (allocations : List Allocation) :
    (routerDepositInputs cfg inputTemplate batchTemplate allocations).batches.length =
      allocations.length := by
  simp [routerDepositInputs]

theorem router_exactKeys (cfg : SourceDepositConfig)
    (inputTemplate : DepositNFrameTx.Inputs) (batchTemplate : Batch)
    (allocations : List Allocation) (h : RouterWordBounds cfg allocations) :
    exactKeys (routerDepositInputs cfg inputTemplate batchTemplate allocations).batches =
      (allocations.map fun allocation => allocation.amount.value).sum := by
  simp only [routerDepositInputs, exactKeys, List.map_map]
  apply congrArg List.sum
  apply List.map_congr_left
  intro allocation hAllocation
  simp [routerBatch, ofNat_val_of_lt (h.keys allocation hAllocation)]

theorem router_exactTotal (cfg : SourceDepositConfig)
    (inputTemplate : DepositNFrameTx.Inputs) (batchTemplate : Batch)
    (allocations : List Allocation) (h : RouterWordBounds cfg allocations) :
    exactTotal (routerDepositInputs cfg inputTemplate batchTemplate allocations).batches =
      (allocations.map fun allocation => allocationWei allocation cfg.depositSize).sum := by
  simp only [routerDepositInputs, exactTotal, List.map_map]
  apply congrArg List.sum
  apply List.map_congr_left
  intro allocation hAllocation
  simp [routerBatch, ofNat_val_of_lt (h.wei allocation hAllocation)]

/-- Spec → Source → Verity bridge for arbitrary finite arity. -/
theorem router_links_source
    (cfg : SourceDepositConfig) (inp : SourceDepositInput)
    (inputTemplate : DepositNFrameTx.Inputs) (batchTemplate : Batch)
    (allocations : List Allocation) (hBounds : RouterWordBounds cfg allocations)
    (hCount : (allocations.map fun allocation => allocation.amount.value).sum =
      actualDepositsCount cfg inp) :
    LidoSRv3.Audit.Guarantees.PDeposit1.NFrame.LinksSource cfg inp
      (routerDepositInputs cfg inputTemplate batchTemplate allocations) where
  depositSize := by
    change (Uint256.ofNat cfg.depositSize).val = cfg.depositSize
    exact ofNat_val_of_lt hBounds.depositSize
  keys := by
    rw [router_exactKeys cfg inputTemplate batchTemplate allocations hBounds, hCount]
  batchAmounts := by
    intro batch hBatch
    simp only [routerDepositInputs] at hBatch
    obtain ⟨allocation, hAllocation, rfl⟩ := List.mem_map.mp hBatch
    change (Uint256.ofNat (allocationWei allocation cfg.depositSize)).val =
      (Uint256.ofNat allocation.amount.value).val * cfg.depositSize
    rw [ofNat_val_of_lt (hBounds.wei allocation hAllocation),
      ofNat_val_of_lt (hBounds.keys allocation hAllocation)]
    rfl

theorem router_foldStable
    (cfg : SourceDepositConfig) (inputTemplate : DepositNFrameTx.Inputs)
    (batchTemplate : Batch) (allocations : List Allocation)
    (h : RouterWordBounds cfg allocations) :
    FoldStable 0
      (routerDepositInputs cfg inputTemplate batchTemplate allocations).batches := by
  apply foldStable_of_bound
  rw [Nat.zero_add, router_exactTotal cfg inputTemplate batchTemplate allocations h]
  exact h.totalWei

end LidoSRv3.Audit.Spec.DepositNFrameCorrespondence
