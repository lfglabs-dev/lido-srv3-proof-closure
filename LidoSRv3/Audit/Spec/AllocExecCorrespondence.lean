import LidoSRv3.Audit.Spec
import LidoSRv3.Audit.Verity.DepositParentTx

/-!
# Allocation-count to executed-deposit correspondence

`Spec.Allocation.amount` is a validator count.  This module gives the
two-batch deposit execution step that materializes that count as wei: each
batch key contributes the configured `Inputs.depositSize`.

The input scaffold is retained deliberately.  In particular, execution
overwrites a stale or skewed `Batch.amount`; the output amount is computed
from `Batch.keys` and the execution configuration.
-/

namespace LidoSRv3.Audit.Spec.AllocExecCorrespondence

open LidoSRv3.Audit.Verity.DepositParentTx

/-- Materialize one batch's executed wei from its validator count. -/
def materializeBatch (depositSize : Word) (batch : Batch) : Batch :=
  { batch with amount := batch.keys * depositSize }

/-- The bounded two-batch execution step for allocation amounts. -/
def executeAllocatedAmounts (inputs : Inputs) : Inputs :=
  { inputs with
    first := materializeBatch inputs.depositSize inputs.first
    second := materializeBatch inputs.depositSize inputs.second }

/-- A materialized batch contains exactly `keys * depositSize` when that
product does not wrap the execution word. -/
theorem materializeBatch_amount
    (depositSize : Word) (batch : Batch)
    (hNoWrap : batch.keys.val * depositSize.val < _root_.Verity.Core.Uint256.modulus) :
    (materializeBatch depositSize batch).amount.val =
      batch.keys.val * depositSize.val := by
  change (batch.keys.val * depositSize.val) %
    _root_.Verity.Core.Uint256.modulus = batch.keys.val * depositSize.val
  exact Nat.mod_eq_of_lt hNoWrap

end LidoSRv3.Audit.Spec.AllocExecCorrespondence
