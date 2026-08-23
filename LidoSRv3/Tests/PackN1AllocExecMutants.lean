import LidoSRv3.Audit.Spec.AllocExecCorrespondence
import LidoSRv3.Audit.Guarantees.PAllocExec1
import LidoSRv3.Audit.Guarantees.PDeposit1
import LidoSRv3.Audit.Verity.DepositParentTx
import LidoSRv3.Audit.Source.DepositCorrespondence

/-!
# Node 1 fail-closed vectors

One model mutant for the composition parent
`PAllocExec1.allocated_amount_times_deposit_size`: the mutant wei model
drops the `* depositSize`, reading the raw validator count as wei
(equivalently, multiplying by `1`).  The kill-line is parent-shaped -- it
negates the exact universally quantified equality with every premise
retained -- and the witness is the canonical five-key deployment, where the
honest equality holds (`160 = 5 * 32`) and the mutant equality fails
(`160 ≠ 5`).

A second vector shows the bridge's unit multiply is itself falsifiable: the
existing 2-key / 65-wei skew (keys `2`/`3`, wei `65`/`95`) satisfies the
key-count half of `ExecutesAllocation` but refutes its wei half, so the
bridge cannot be weakened back to validator counts alone -- consistent with
the already-proved ALLOC ↛ `LinksSource` separation, which this pack does
not re-document.
-/

namespace LidoSRv3.Tests.PackN1AllocExecMutants

open LidoSRv3.Audit.Spec
open LidoSRv3.Audit.Spec.AllocExecCorrespondence
open LidoSRv3.Audit.Guarantees
open LidoSRv3.Audit.Guarantees.PAllocExec1
open LidoSRv3.Audit.SolidityDeposit
open LidoSRv3.Audit.Verity.DepositParentTx

/-- Mutant wei model: the `* depositSize` is dropped, so the raw validator
count is read as wei.  Written as `* 1` to make the dropped factor
explicit. -/
def mutantAllocationWei (a : Allocation) : Nat :=
  a.amount.value * 1

/-- Parent-shaped kill-line.  The statement below is the parent
`allocated_amount_times_deposit_size` with every premise retained --
`ExecutesAllocation`, the deposit-size pin, the key-count partition, and the
no-wrap bound -- and only the model's `* depositSize` dropped from the
executed-total conclusion.  The canonical five-key witness refutes it: the
honest total is `160 = (2 + 3) * 32`, while the mutant demands
`160 = 2 + 3`. -/
theorem raw_count_as_wei_kill_line :
    ¬ (∀ (cfg : SourceDepositConfig) (inp : SourceDepositInput)
        (inputs : Inputs) (first second : Allocation),
          ExecutesAllocation inputs first second →
          inputs.depositSize.val = cfg.depositSize →
          inputs.first.keys.val + inputs.second.keys.val
            = actualDepositsCount cfg inp →
          inputs.first.amount.val + inputs.second.amount.val
            < _root_.Verity.Core.Uint256.modulus →
          (totalAmount inputs).val
            = mutantAllocationWei first + mutantAllocationWei second) := by
  intro h
  have hMutant :=
    h PDeposit1.canonicalSourceConfig PDeposit1.canonicalSourceInput
      canonicalInputs canonicalFirstAllocation canonicalSecondAllocation
      canonical_executes_allocation (by decide) (by decide)
      canonical_preconditions.noWrap
  exact absurd hMutant (by decide)

/-- The kill-line witness is non-vacuous: at the same canonical deployment
the honest wei model (`allocationWei`, the unit multiply by the configured
deposit size) really does hit the executed total, and the mutant really
does miss it. -/
theorem honest_equality_holds_where_mutant_fails :
    (totalAmount canonicalInputs).val
        = allocationWei canonicalFirstAllocation
            PDeposit1.canonicalSourceConfig.depositSize
          + allocationWei canonicalSecondAllocation
            PDeposit1.canonicalSourceConfig.depositSize ∧
      (totalAmount canonicalInputs).val
        ≠ mutantAllocationWei canonicalFirstAllocation
          + mutantAllocationWei canonicalSecondAllocation :=
  ⟨by decide, by decide⟩

/-- The existing 2-key / 65-wei skew: batch keys stay `2`/`3`, per-batch wei
is skewed to `65`/`95`. -/
def skewedInputs : Inputs :=
  { canonicalInputs with
    first := { batchA with amount := 65 }
    second := { batchB with amount := 95 } }

/-- The bridge's unit multiply is load-bearing and falsifiable: the skewed
inputs satisfy the key-count half of `ExecutesAllocation` (amounts `2`/`3`
match keys `2`/`3`) but refute its wei half, because `65 ≠ 2 * 32`.  So
`ExecutesAllocation` cannot be weakened to validator counts alone. -/
theorem skewed_wei_falsifies_bridge :
    canonicalFirstAllocation.amount.value = skewedInputs.first.keys.val ∧
      canonicalSecondAllocation.amount.value = skewedInputs.second.keys.val ∧
      ¬ ExecutesAllocation skewedInputs
          canonicalFirstAllocation canonicalSecondAllocation := by
  refine ⟨by decide, by decide, ?_⟩
  intro hBridge
  exact absurd hBridge.firstWei (by decide)

/-- Mutant router: batch wei is the raw validator count, not
`amount * depositSize`. -/
def mutantRouterDepositInputs (cfg : SourceDepositConfig) (template : Inputs)
    (first second : Allocation) : Inputs :=
  { template with
    depositSize := .ofNat cfg.depositSize
    first := { template.first with
      keys := .ofNat first.amount.value
      amount := .ofNat first.amount.value }
    second := { template.second with
      keys := .ofNat second.amount.value
      amount := .ofNat second.amount.value } }

theorem canonical_router_word_bounds :
    RouterWordBounds PDeposit1.canonicalSourceConfig
      canonicalFirstAllocation canonicalSecondAllocation := by
  constructor <;> decide

/-- Parent-shaped kill-line: same word bounds and key-count partition, but
the raw-count mutant does not produce `ExecutesAllocation`. -/
theorem raw_count_router_kill_line_refutes_parent :
    RouterWordBounds PDeposit1.canonicalSourceConfig
        canonicalFirstAllocation canonicalSecondAllocation ∧
      canonicalFirstAllocation.amount.value +
          canonicalSecondAllocation.amount.value =
        actualDepositsCount PDeposit1.canonicalSourceConfig
          PDeposit1.canonicalSourceInput ∧
      ¬ ExecutesAllocation
          (mutantRouterDepositInputs PDeposit1.canonicalSourceConfig
            canonicalInputs canonicalFirstAllocation
            canonicalSecondAllocation)
          canonicalFirstAllocation canonicalSecondAllocation := by
  refine ⟨canonical_router_word_bounds, by decide, ?_⟩
  intro hBridge
  exact absurd hBridge.firstWei (by decide)

/-- Positive control: the honest router on the canonical allocations
satisfies the registered parent. -/
theorem honest_router_parent_holds :
    ExecutesAllocation
        (routerDepositInputs PDeposit1.canonicalSourceConfig
          canonicalInputs canonicalFirstAllocation
          canonicalSecondAllocation)
        canonicalFirstAllocation canonicalSecondAllocation ∧
      PDeposit1.LinksSource PDeposit1.canonicalSourceConfig
        PDeposit1.canonicalSourceInput
        (routerDepositInputs PDeposit1.canonicalSourceConfig
          canonicalInputs canonicalFirstAllocation
          canonicalSecondAllocation) :=
  let h :=
    router_produces_executes_allocation
      PDeposit1.canonicalSourceConfig PDeposit1.canonicalSourceInput
      canonicalInputs canonicalFirstAllocation canonicalSecondAllocation
      canonical_router_word_bounds (by decide)
  ⟨h.1, h.2.1⟩

end LidoSRv3.Tests.PackN1AllocExecMutants
