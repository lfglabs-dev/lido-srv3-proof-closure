import LidoSRv3.Audit.Guarantees.PAllocExec1

/-!
# N1 allocation-execution fail-closed vector

The mutant copies raw validator counts into the wei amount fields.  The
two-key input starts with the existing skewed amount `65`; honest execution
recomputes it as `2 * 32`, while the mutant writes only `2`.
-/

namespace LidoSRv3.Tests.PackN1AllocExecMutants

open LidoSRv3.Audit.Spec
open LidoSRv3.Audit.Spec.AllocExecCorrespondence
open LidoSRv3.Audit.SolidityDeposit
open LidoSRv3.Audit.Verity.DepositParentTx
open LidoSRv3.Audit.Guarantees.PAllocExec1

private def witnessCfg : SourceDepositConfig :=
  { maxEBType1 := 32
    depositSize := 32
    pubkeyLength := 48
    publicKeyLength := 48
    signatureLength := 96 }

private def skewedInputs : Inputs :=
  { canonicalInputs with
    first := { batchA with amount := 65 }
    second := { batchB with amount := 95 } }

private def firstAllocation : Allocation :=
  { moduleId := 7, capacity := ⟨2⟩, amount := ⟨2⟩ }

private def secondAllocation : Allocation :=
  { moduleId := 9, capacity := ⟨3⟩, amount := ⟨3⟩ }

/-- Mutant batch materialization: validator count is mislabelled as wei. -/
def materializeBatchRawCount (batch : Batch) : Batch :=
  { batch with amount := batch.keys }

/-- Mutant two-batch execution with the unit multiplication removed. -/
def executeAllocatedAmountsRawCount (inputs : Inputs) : Inputs :=
  { inputs with
    first := materializeBatchRawCount inputs.first
    second := materializeBatchRawCount inputs.second }

/-- The skewed input is recomputed by the honest model.  Its stale `65`-wei
first amount is neither assumed nor copied into the conclusion. -/
theorem skewed_witness_honest_equality :
    (executeAllocatedAmounts skewedInputs).first.amount.val =
        firstAllocation.amount.value * witnessCfg.depositSize ∧
      (executeAllocatedAmounts skewedInputs).second.amount.val =
        secondAllocation.amount.value * witnessCfg.depositSize ∧
      skewedInputs.first.amount.val = 65 := by
  have hHonest := allocated_amount_times_deposit_size witnessCfg skewedInputs
    firstAllocation secondAllocation (by decide) (by decide) (by decide)
    (by decide) (by decide)
  exact ⟨hHonest.1, hHonest.2, by decide⟩

/-- Parent-shaped kill-line.  Retaining every parent premise while replacing
the execution model by raw validator counts falsifies the exact universal
amount equalities. -/
theorem raw_validator_count_kill_line_refutes_parent :
    ¬ (∀ (cfg : SourceDepositConfig) (inputs : Inputs)
        (firstAllocation secondAllocation : Allocation),
          inputs.depositSize.val = cfg.depositSize →
          firstAllocation.amount.value = inputs.first.keys.val →
          secondAllocation.amount.value = inputs.second.keys.val →
          firstAllocation.amount.value * cfg.depositSize <
            _root_.Verity.Core.Uint256.modulus →
          secondAllocation.amount.value * cfg.depositSize <
            _root_.Verity.Core.Uint256.modulus →
          (executeAllocatedAmountsRawCount inputs).first.amount.val =
              firstAllocation.amount.value * cfg.depositSize ∧
            (executeAllocatedAmountsRawCount inputs).second.amount.val =
              secondAllocation.amount.value * cfg.depositSize) := by
  intro mutantParent
  have hMutant := mutantParent witnessCfg skewedInputs
    firstAllocation secondAllocation (by decide) (by decide) (by decide)
    (by decide) (by decide)
  exact absurd hMutant.1 (by decide)

end LidoSRv3.Tests.PackN1AllocExecMutants
