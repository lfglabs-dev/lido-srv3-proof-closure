import LidoSRv3.Audit.Spec.AllocExecCorrespondence
import LidoSRv3.Audit.Source.DepositCorrespondence

/-!
# P-ALLOC-EXEC-1: allocation counts become executed deposit wei

This composition parent joins the frozen `Spec.Allocation` validator-count
interface to the two-batch deposit amount execution.  The source and execution
configuration fields are linked explicitly; no fixed deployment value is
assumed for `depositSize`.
-/

namespace LidoSRv3.Audit.Guarantees.PAllocExec1

open LidoSRv3.Audit.Spec
open LidoSRv3.Audit.Spec.AllocExecCorrespondence
open LidoSRv3.Audit.SolidityDeposit
open LidoSRv3.Audit.Verity.DepositParentTx

/-- **Composition parent.** For every source deposit configuration, executable
input, and pair of Spec allocations whose validator counts match the two
batches, executing the amount materialization produces exactly
`Spec.Allocation.amount * depositSize` wei on each batch.

The two product bounds state the executable word's arithmetic boundary.  The
right-hand sides remain mathematical `Nat` wei and therefore cannot silently
wrap. -/
theorem allocated_amount_times_deposit_size
    (cfg : SourceDepositConfig) (inputs : Inputs)
    (firstAllocation secondAllocation : Allocation)
    (hDepositSize : inputs.depositSize.val = cfg.depositSize)
    (hFirstCount :
      firstAllocation.amount.value = inputs.first.keys.val)
    (hSecondCount :
      secondAllocation.amount.value = inputs.second.keys.val)
    (hFirstNoWrap :
      firstAllocation.amount.value * cfg.depositSize <
        _root_.Verity.Core.Uint256.modulus)
    (hSecondNoWrap :
      secondAllocation.amount.value * cfg.depositSize <
        _root_.Verity.Core.Uint256.modulus) :
    (executeAllocatedAmounts inputs).first.amount.val =
        firstAllocation.amount.value * cfg.depositSize ∧
      (executeAllocatedAmounts inputs).second.amount.val =
        secondAllocation.amount.value * cfg.depositSize := by
  constructor
  · change (materializeBatch inputs.depositSize inputs.first).amount.val =
      firstAllocation.amount.value * cfg.depositSize
    have hBound :
        inputs.first.keys.val * inputs.depositSize.val <
          _root_.Verity.Core.Uint256.modulus := by
      simpa [← hFirstCount, hDepositSize] using hFirstNoWrap
    rw [materializeBatch_amount inputs.depositSize inputs.first hBound,
      ← hFirstCount, hDepositSize]
  · change (materializeBatch inputs.depositSize inputs.second).amount.val =
      secondAllocation.amount.value * cfg.depositSize
    have hBound :
        inputs.second.keys.val * inputs.depositSize.val <
          _root_.Verity.Core.Uint256.modulus := by
      simpa [← hSecondCount, hDepositSize] using hSecondNoWrap
    rw [materializeBatch_amount inputs.depositSize inputs.second hBound,
      ← hSecondCount, hDepositSize]

end LidoSRv3.Audit.Guarantees.PAllocExec1
