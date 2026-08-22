import LidoSRv3.Audit.Spec
import LidoSRv3.Audit.Verity.DepositParentTx

/-!
# Node 1: Spec.Allocation → executed-wei bridge interface

`Spec.Allocation.amount` is a validator count (Wave 0 frozen interface); the
wei an allocation stands for is `amount * depositSize`, where `depositSize`
is the existing per-key configuration field
(`SourceDepositConfig.depositSize` / `Inputs.depositSize`), not a claimed
32-ether deployment fact -- `A-DEPOSIT-32-ETHER` stays OPEN.

`ExecutesAllocation` is the caller-side bridge from two Spec allocations to
the executable transaction's two batch legs.  It carries exactly two facts
per leg: the allocation amount is the leg's key count, and the leg's wei is
the allocation amount times the per-key deposit size.  The already-proved
ALLOC ↛ `LinksSource` separation (`spec_amounts_do_not_imply_linkssource`)
shows the key-count half alone is not enough; the unit multiply is the
missing, falsifiable half (see
`LidoSRv3.Tests.PackN1AllocExecMutants.skewed_wei_falsifies_bridge`).

This file is data-only: it states nothing about post-states or observables,
so it cannot smuggle the deposit parent's conclusions in.  The composition
parent that consumes it is
`LidoSRv3.Audit.Guarantees.PAllocExec1.allocated_amount_times_deposit_size`.
-/

namespace LidoSRv3.Audit.Spec.AllocExecCorrespondence

open LidoSRv3.Audit.Spec
open LidoSRv3.Audit.Verity.DepositParentTx

/-- The wei a Spec allocation stands for once a per-key deposit size is
fixed: `amount` is a validator count, wei is `amount * depositSize`. -/
def allocationWei (a : Allocation) (depositSize : Nat) : Nat :=
  a.amount.value * depositSize

/-- Bridge from two Spec allocations to the executable transaction's two
batch legs.  Each leg's key count is the allocation amount, and each leg's
wei is the allocation amount times the transaction's per-key
`Inputs.depositSize` -- the unit multiply that validator counts alone do not
provide.  The bridge deliberately repeats none of `LinksSource`'s
`firstAmount`/`secondAmount` conjuncts in key-count form; those become
theorems of the composition parent. -/
structure ExecutesAllocation (inputs : Inputs) (first second : Allocation) :
    Prop where
  firstKeys : first.amount.value = inputs.first.keys.val
  secondKeys : second.amount.value = inputs.second.keys.val
  firstWei : inputs.first.amount.val = allocationWei first inputs.depositSize.val
  secondWei : inputs.second.amount.val = allocationWei second inputs.depositSize.val

/-- Wei of two allocations at one deposit size is the summed validator count
times that deposit size. -/
theorem allocationWei_add (a b : Allocation) (depositSize : Nat) :
    allocationWei a depositSize + allocationWei b depositSize
      = (a.amount.value + b.amount.value) * depositSize :=
  (Nat.add_mul a.amount.value b.amount.value depositSize).symm

end LidoSRv3.Audit.Spec.AllocExecCorrespondence
