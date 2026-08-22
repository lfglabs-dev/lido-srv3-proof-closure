import LidoSRv3.Audit.Spec
import LidoSRv3.Audit.Guarantees.PAlloc1
import LidoSRv3.Audit.Guarantees.PAlloc2
import LidoSRv3.Audit.Guarantees.PTopup2
import LidoSRv3.Audit.Guarantees.PDeposit1
import LidoSRv3.Audit.Verity.DepositParentTx
import LidoSRv3.Audit.Source.DepositCorrespondence

/-!
# Pack A: Spec.Allocation projections

Unregistered children. They do not replace the registered ALLOC / DEPOSIT /
TOPUP parents, do not discharge `LinksSource`, and do not invent a
composition guarantee ID.
-/

namespace LidoSRv3.Audit.Spec.AllocationCorrespondence

open LidoSRv3.Audit
open LidoSRv3.Audit.Common
open LidoSRv3.Audit.AllocCapacity
open LidoSRv3.Audit.MinFirstAllocation
open LidoSRv3.Audit.Guarantees
open LidoSRv3.Audit.SolidityDeposit
open LidoSRv3.Audit.Verity.DepositParentTx

/-- ALLOC-1 row as a Spec allocation: capacity is the checked capacity
column; `amount` is the current allocation, not an executed wei total. -/
def specOfAlloc1Row (r : Row) : Allocation where
  moduleId := (r.moduleId : Nat)
  capacity := ⟨(r.capacity : Nat)⟩
  amount := ⟨(r.currentAllocation : Nat)⟩

/-- ALLOC-2 step as a Spec allocation. `moduleId` is the router index: the
MinFirst row type is not module-id-keyed. `amount` is the checked increment. -/
def specOfAlloc2Step (idx : Nat) (best : Source.Row) (delta : Nat) : Allocation where
  moduleId := idx
  capacity := ⟨best.capacity.val⟩
  amount := ⟨delta⟩

/-- Unregistered ALLOC-1 child: under `CheckedBounds` the source executor
succeeds and the Spec capacity column equals `MathView`. -/
theorem alloc1_spec_capacity_correspondence
    (cfg : Config) (modules : List Module) (depositsToAllocate : Verity.Uint256)
    (isTopUp : Bool) (hBounds : CheckedBounds cfg modules depositsToAllocate isTopUp) :
    ∃ rows, SolidityAllocCapacity.execute cfg modules depositsToAllocate isTopUp = some rows ∧
      (rows.map specOfAlloc1Row).map (fun a => a.capacity.value) =
        MathView.capacities cfg modules depositsToAllocate isTopUp ∧
      (rows.map specOfAlloc1Row).map (fun a => a.moduleId) =
        rows.map (fun r => (r.moduleId : Nat)) := by
  obtain ⟨rows, hExec, hCap⟩ :=
    PAlloc1.checked_execute cfg modules depositsToAllocate isTopUp hBounds
  refine ⟨rows, hExec, ?_, ?_⟩
  · have hProj :
        (rows.map specOfAlloc1Row).map (fun a => a.capacity.value) =
          rows.map (fun row => row.capacity.val) := by
      simp [specOfAlloc1Row]
    exact hProj.trans hCap
  · simp [specOfAlloc1Row]

/-- Unregistered ALLOC-2 child: a successful proportional step is a Spec
allocation whose amount is the checked increment and stays inside capacity. -/
theorem alloc2_spec_step_amount_correspondence
    (model : List Model.Bucket) (source : List Source.Row)
    (best : Source.Row) (allocationSize w : Source.Word) (idx : Nat)
    (hRows : RowsCorrespond model source)
    (hCand : Source.candidate? source = some best)
    (hOpen : Source.hasFreeSpace best = true)
    (hLen : source.length < Verity.Core.Uint256.modulus)
    (hDemand : allocationSize.val ≠ 0)
    (hAmount : Source.checkedAmount source allocationSize best = some w) :
    let a := specOfAlloc2Step idx best w.val
    a.amount.value = w.val ∧
      a.capacity.value = best.capacity.val ∧
      a.amount.value + best.allocation.val ≤ a.capacity.value := by
  have hStep :=
    (PAlloc2.step_correspondence_and_full_loop_conservation.1
      model source best allocationSize w hRows hCand hOpen hLen hDemand hAmount)
  refine ⟨rfl, rfl, ?_⟩
  have hBound : best.allocation.val + w.val ≤ best.capacity.val := hStep.2.2.2.2
  simpa [specOfAlloc2Step, Nat.add_comm] using hBound

/-- TOPUP wrap / per-key stay on P-TOPUP-1 / P-TOPUP-2. Spec.Allocation is
validator counts; this child only re-states the existing per-key gwei bound
so Pack A does not stuff gwei into `Validators`. -/
theorem topup2_per_key_remains_gwei (b : PTopup2.TopupBatch) (cfg : PTopup2.TopupConfig) :
    List.Forall₂ (fun alloc cand => alloc ≤ cand)
      (PTopup2.transition b cfg) (PTopup2.candidates b cfg) :=
  PTopup2.per_key_bounded_by_candidate b cfg

/-- Named `LinksSource` child, Spec-shaped: validator-count Spec amounts equal
to per-batch key counts still do not determine `LinksSource.firstAmount`
(wei). This is the honest ALLOC ↛ LinksSource fact. -/
def specAmountsFromKeys (firstKeys secondKeys : Nat) : List Allocation :=
  [ { moduleId := 0, capacity := ⟨0⟩, amount := ⟨firstKeys⟩ }
  , { moduleId := 1, capacity := ⟨0⟩, amount := ⟨secondKeys⟩ } ]

/-- Validator-count Spec amounts matching the two batch key counts still do
not imply `LinksSource`. The witness keeps keys `2` and `3` and uses skewed
per-batch wei `(65, 95)`, so `65 ≠ 2 * 32`. -/
theorem spec_amounts_do_not_imply_linkssource :
    ¬ (∀ (specRows : List Allocation)
        (cfg : SourceDepositConfig) (inp : SourceDepositInput)
        (inputs : Inputs),
          specRows.map (fun a => a.amount.value) =
            [inputs.first.keys.val, inputs.second.keys.val] →
          PDeposit1.LinksSource cfg inp inputs) := by
  intro h
  let inputs : Inputs :=
    { canonicalInputs with
      first := { batchA with amount := 65 }
      second := { batchB with amount := 95 } }
  have hEq : (specAmountsFromKeys 2 3).map (fun a => a.amount.value) = [2, 3] := rfl
  have hKeys : [inputs.first.keys.val, inputs.second.keys.val] = [2, 3] := by decide
  have hLink := h (specAmountsFromKeys 2 3) PDeposit1.canonicalSourceConfig
    PDeposit1.canonicalSourceInput inputs (hEq.trans hKeys.symm)
  exact absurd hLink.firstAmount (by decide)

end LidoSRv3.Audit.Spec.AllocationCorrespondence
