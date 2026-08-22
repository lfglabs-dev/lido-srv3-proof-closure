import LidoSRv3.Audit.Spec.AllocExecCorrespondence
import LidoSRv3.Audit.Guarantees.PDeposit1

/-!
# Node 1 composition parent: allocated validator counts to executed wei

`Spec.Allocation.amount` is a validator count.  This parent proves the
equality

  executed deposit wei = `Spec.Allocation.amount` * `depositSize`

where `depositSize` is the existing configuration field
(`SourceDepositConfig.depositSize` / `Inputs.depositSize`), not a claimed
32-ether deployment fact -- `A-DEPOSIT-32-ETHER` stays OPEN, and no pin is
invented to discharge it.

The bridge replaces the `firstAmount`/`secondAmount` conjuncts of
`PDeposit1.LinksSource`: under `ExecutesAllocation` (allocation amounts are
the batch key counts, batch wei is the allocation amount times the per-key
deposit size) plus the already-proved key-count partition, both wei
conjuncts -- and hence all of `LinksSource` -- become theorems rather than
independent caller hypotheses.  The already-proved ALLOC ↛ `LinksSource`
separation is untouched: validator counts alone still do not determine wei;
the unit multiply carried by `ExecutesAllocation` is exactly what was
missing, and it is falsifiable
(`LidoSRv3.Tests.PackN1AllocExecMutants.skewed_wei_falsifies_bridge`).

Unregistered until the integrator writes the supplemental YAML row; no
guarantee ID is invented here and `Registry.lean` / `AllGuarantees.lean` are
untouched.
-/

namespace LidoSRv3.Audit.Guarantees.PAllocExec1

open LidoSRv3.Audit
open LidoSRv3.Audit.SolidityDeposit
open LidoSRv3.Audit.Verity.DepositParentTx
open LidoSRv3.Audit.Spec.AllocExecCorrespondence

/--
Composition parent for Node 1.  For every source deposit configuration and
call input `(cfg, inp)`, executable transaction input `inputs`, and pair of
Spec allocations `(first, second)` bridged by `ExecutesAllocation` -- with
the transaction's per-key wei pinned to `cfg.depositSize`, the two key
counts partitioning `actualDepositsCount` (`StakingRouter.sol` line 967),
and the two batch wei fields below the `uint256` modulus -- the named
conclusion is the executed-wei equality, on both planes:

* per batch, the executable leg's wei is the allocation amount times
  `cfg.depositSize`;
* the executable total (`totalAmount`, the wei the two beacon legs move) is
  the summed allocation amount times `cfg.depositSize`;
* the pinned-source loop total (`pushedValue`,
  `BeaconChainDepositor.sol` lines 53--63) is the same summed allocation
  amount times `cfg.depositSize` -- proved through `loopPushed_eq` and the
  key-count partition, not by definition;
* `LinksSource cfg inp inputs` holds: its `firstAmount`/`secondAmount` wei
  conjuncts are now consequences of the allocation equality plus the unit
  multiply, no longer independent caller hypotheses;
* on every committed run of the pinned source model, the wei actually
  pulled from Lido (source line 983) and pushed to the beacon deposit
  contract (`BeaconChainDepositor.sol` line 57) both equal the summed
  allocation amount times `cfg.depositSize` -- the pulled half additionally
  routes through the line 996 assert gate
  (`committed_deposits_spec`), so neither is a definitional conjunct.

Scope, stated rather than hidden: `ExecutesAllocation` is a caller-side
bridge hypothesis about how allocation amounts were turned into batch wei;
it is not a proof that the pinned Solidity produces those two legs, and it
does not revive any claim that the ALLOC parents alone imply `LinksSource`
-- without the unit multiply they do not
(`Spec.AllocationCorrespondence.spec_amounts_do_not_imply_linkssource`).
`depositSize` is the configuration field, so nothing here discharges
`A-DEPOSIT-32-ETHER`.
-/
theorem allocated_amount_times_deposit_size
    (cfg : SourceDepositConfig) (inp : SourceDepositInput)
    (inputs : Inputs) (first second : Spec.Allocation)
    (hBridge : ExecutesAllocation inputs first second)
    (hSize : inputs.depositSize.val = cfg.depositSize)
    (hKeys : inputs.first.keys.val + inputs.second.keys.val
      = actualDepositsCount cfg inp)
    (hNoWrap : inputs.first.amount.val + inputs.second.amount.val
      < _root_.Verity.Core.Uint256.modulus) :
    (inputs.first.amount.val = first.amount.value * cfg.depositSize ∧
        inputs.second.amount.val = second.amount.value * cfg.depositSize) ∧
      (totalAmount inputs).val
        = (first.amount.value + second.amount.value) * cfg.depositSize ∧
      pushedValue cfg inp
        = (first.amount.value + second.amount.value) * cfg.depositSize ∧
      PDeposit1.LinksSource cfg inp inputs ∧
      (∀ keys pulled pushed balanceAfter,
        run cfg inp = .committedDeposits keys pulled pushed balanceAfter →
          (run cfg inp).pulled
              = (first.amount.value + second.amount.value) * cfg.depositSize ∧
            (run cfg inp).pushed
              = (first.amount.value + second.amount.value) * cfg.depositSize) := by
  have hFirst : inputs.first.amount.val = first.amount.value * cfg.depositSize := by
    rw [hBridge.firstWei, allocationWei, hSize]
  have hSecond : inputs.second.amount.val = second.amount.value * cfg.depositSize := by
    rw [hBridge.secondWei, allocationWei, hSize]
  have hTotal : (totalAmount inputs).val
      = (first.amount.value + second.amount.value) * cfg.depositSize := by
    rw [total_val inputs hNoWrap, hFirst, hSecond, Nat.add_mul]
  have hPushed : pushedValue cfg inp
      = (first.amount.value + second.amount.value) * cfg.depositSize := by
    rw [pushedValue, loopPushed_eq, ← hKeys, ← hBridge.firstKeys, ← hBridge.secondKeys]
  refine ⟨⟨hFirst, hSecond⟩, hTotal, hPushed,
    { depositSize := hSize
      keys := hKeys
      firstAmount := by rw [hFirst, hBridge.firstKeys]
      secondAmount := by rw [hSecond, hBridge.secondKeys] }, ?_⟩
  intro keys pulled pushed balanceAfter hCommit
  obtain ⟨-, -, hPulledVal, hPushedVal, hMoved, -⟩ := committed_deposits_spec hCommit
  constructor
  · rw [hCommit]
    exact (hMoved.trans hPushedVal).trans hPushed
  · rw [hCommit]
    exact hPushedVal.trans hPushed

/-! ## Non-vacuity

A composition parent with unsatisfiable hypotheses proves nothing.  The
witnesses below discharge `ExecutesAllocation` and every side premise
simultaneously on the canonical five-key deployment
(`PDeposit1.canonicalSourceConfig` / `canonicalSourceInput` /
`canonicalInputs`), where the source model actually *commits*, so the
committed-run conjunct fires rather than being vacuously true. -/

/-- Spec allocation for the first canonical batch leg: module `7`, two
validators allocated (and two of capacity used, matching the leg). -/
def canonicalFirstAllocation : Spec.Allocation :=
  { moduleId := 7, capacity := ⟨2⟩, amount := ⟨2⟩ }

/-- Spec allocation for the second canonical batch leg: module `9`, three
validators allocated. -/
def canonicalSecondAllocation : Spec.Allocation :=
  { moduleId := 9, capacity := ⟨3⟩, amount := ⟨3⟩ }

/-- The canonical two-batch inputs execute the two canonical allocations:
keys `2`/`3` match the amounts, and wei `64`/`96` are exactly
`2 * 32` / `3 * 32`. -/
theorem canonical_executes_allocation :
    ExecutesAllocation canonicalInputs
      canonicalFirstAllocation canonicalSecondAllocation where
  firstKeys := by decide
  secondKeys := by decide
  firstWei := by decide
  secondWei := by decide

/-- Every hypothesis of the parent holds at once on the canonical five-key
deployment, the source model commits `5` keys / `160` wei, and the executed
wei really is the summed allocation amount (`5` validators) times the
configured deposit size (`32`): both planes land on `160`.  `LinksSource`
is *derived* here, not assumed. -/
theorem canonical_allocation_composition_witness :
    ExecutesAllocation canonicalInputs
        canonicalFirstAllocation canonicalSecondAllocation ∧
      Preconditions canonicalInputs canonicalState ∧
      run PDeposit1.canonicalSourceConfig PDeposit1.canonicalSourceInput
        = .committedDeposits 5 160 160 0 ∧
      (totalAmount canonicalInputs).val = 160 ∧
      (canonicalFirstAllocation.amount.value
            + canonicalSecondAllocation.amount.value)
          * PDeposit1.canonicalSourceConfig.depositSize = 160 ∧
      PDeposit1.LinksSource PDeposit1.canonicalSourceConfig
        PDeposit1.canonicalSourceInput canonicalInputs := by
  obtain ⟨-, hTotal, -, hLink, -⟩ :=
    allocated_amount_times_deposit_size
      PDeposit1.canonicalSourceConfig PDeposit1.canonicalSourceInput
      canonicalInputs canonicalFirstAllocation canonicalSecondAllocation
      canonical_executes_allocation (by decide) (by decide)
      canonical_preconditions.noWrap
  refine ⟨canonical_executes_allocation, canonical_preconditions,
    by decide, ?_, by decide, hLink⟩
  rw [hTotal]
  decide

end LidoSRv3.Audit.Guarantees.PAllocExec1
