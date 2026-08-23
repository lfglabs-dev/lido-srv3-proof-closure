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

The two-batch router construction `routerDepositInputs` is the pinned
deposit path that produces those two legs.  The composition parent that
consumes it is
`LidoSRv3.Audit.Guarantees.PAllocExec1.router_produces_executes_allocation`.
This file still states nothing about post-states or observables.
-/

namespace LidoSRv3.Audit.Spec.AllocExecCorrespondence

open LidoSRv3.Audit.Spec
open LidoSRv3.Audit.SolidityDeposit
open LidoSRv3.Audit.Verity.DepositParentTx
open _root_.Verity.Core

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

/-- The pinned two-batch deposit path: each allocation amount becomes that
leg's key count, and each leg's wei is `amount * cfg.depositSize`.
`A-DEPOSIT-32-ETHER` stays named; `depositSize` is the configuration
field. This is not an n-frame lift. -/
def routerDepositInputs (cfg : SourceDepositConfig) (template : Inputs)
    (first second : Allocation) : Inputs :=
  { template with
    depositSize := .ofNat cfg.depositSize
    first := { template.first with
      keys := .ofNat first.amount.value
      amount := .ofNat (first.amount.value * cfg.depositSize) }
    second := { template.second with
      keys := .ofNat second.amount.value
      amount := .ofNat (second.amount.value * cfg.depositSize) } }

theorem ofNat_val_of_lt {n : Nat} (h : n < Uint256.modulus) :
    (Uint256.ofNat n).val = n := by
  simp [Uint256.val_ofNat, Nat.mod_eq_of_lt h]

/-- Word-bound premises under which the router construction is encodable. -/
structure RouterWordBounds (cfg : SourceDepositConfig)
    (first second : Allocation) : Prop where
  firstKeys : first.amount.value < Uint256.modulus
  secondKeys : second.amount.value < Uint256.modulus
  firstWei : first.amount.value * cfg.depositSize < Uint256.modulus
  secondWei : second.amount.value * cfg.depositSize < Uint256.modulus
  depositSize : cfg.depositSize < Uint256.modulus
  noWrap : first.amount.value * cfg.depositSize +
      second.amount.value * cfg.depositSize < Uint256.modulus

/-- The router construction yields `ExecutesAllocation`: keys are the
allocation amounts and wei is `amount * depositSize`. -/
theorem router_executes_allocation
    (cfg : SourceDepositConfig) (template : Inputs)
    (first second : Allocation) (h : RouterWordBounds cfg first second) :
    ExecutesAllocation (routerDepositInputs cfg template first second)
      first second where
  firstKeys := by
    change first.amount.value = (Uint256.ofNat first.amount.value).val
    rw [ofNat_val_of_lt h.firstKeys]
  secondKeys := by
    change second.amount.value = (Uint256.ofNat second.amount.value).val
    rw [ofNat_val_of_lt h.secondKeys]
  firstWei := by
    change (Uint256.ofNat (first.amount.value * cfg.depositSize)).val =
      first.amount.value * (Uint256.ofNat cfg.depositSize).val
    rw [ofNat_val_of_lt h.firstWei, ofNat_val_of_lt h.depositSize]
  secondWei := by
    change (Uint256.ofNat (second.amount.value * cfg.depositSize)).val =
      second.amount.value * (Uint256.ofNat cfg.depositSize).val
    rw [ofNat_val_of_lt h.secondWei, ofNat_val_of_lt h.depositSize]

/-- Deposit-size pin of the router construction. -/
theorem router_depositSize
    (cfg : SourceDepositConfig) (template : Inputs)
    (first second : Allocation) (h : RouterWordBounds cfg first second) :
    (routerDepositInputs cfg template first second).depositSize.val =
      cfg.depositSize := by
  change (Uint256.ofNat cfg.depositSize).val = cfg.depositSize
  rw [ofNat_val_of_lt h.depositSize]

/-- Key-count partition of the router construction, once the allocations
sum to `actualDepositsCount`. -/
theorem router_keys
    (cfg : SourceDepositConfig) (inp : SourceDepositInput)
    (template : Inputs) (first second : Allocation)
    (h : RouterWordBounds cfg first second)
    (hCount : first.amount.value + second.amount.value =
      actualDepositsCount cfg inp) :
    (routerDepositInputs cfg template first second).first.keys.val +
        (routerDepositInputs cfg template first second).second.keys.val =
      actualDepositsCount cfg inp := by
  change (Uint256.ofNat first.amount.value).val +
      (Uint256.ofNat second.amount.value).val =
    actualDepositsCount cfg inp
  rw [ofNat_val_of_lt h.firstKeys, ofNat_val_of_lt h.secondKeys, hCount]

/-- The constructed batch wei sum stays inside one word. -/
theorem router_noWrap
    (cfg : SourceDepositConfig) (template : Inputs)
    (first second : Allocation) (h : RouterWordBounds cfg first second) :
    (routerDepositInputs cfg template first second).first.amount.val +
        (routerDepositInputs cfg template first second).second.amount.val <
      Uint256.modulus := by
  change (Uint256.ofNat (first.amount.value * cfg.depositSize)).val +
      (Uint256.ofNat (second.amount.value * cfg.depositSize)).val <
    Uint256.modulus
  rw [ofNat_val_of_lt h.firstWei, ofNat_val_of_lt h.secondWei]
  exact h.noWrap

end LidoSRv3.Audit.Spec.AllocExecCorrespondence
