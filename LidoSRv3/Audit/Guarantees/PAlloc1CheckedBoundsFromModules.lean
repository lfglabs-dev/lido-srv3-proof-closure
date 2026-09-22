import LidoSRv3.Audit.Model.AllocCapacity
import LidoSRv3.Audit.Source.NodeOperatorsRegistry.CounterBounds
import LidoSRv3.Audit.Source.SRStorageExitedMonotonicity
import LidoSRv3.Audit.Guarantees.PAlloc1TargetMultBounded
import LidoSRv3.Audit.Guarantees.PAlloc1TotalAdditionBounded
import LidoSRv3.Audit.Guarantees.PAlloc1AvailableArithmeticBounded
import LidoSRv3.Audit.Guarantees.PAlloc1

/-! # CheckedBounds from an assumed module representation

SupportedModules is an explicit premise, not a theorem about deployed modules.
It requires NOR-style counter sums over at most 200 operators and admitted
counter histories for each module, plus per-call arithmetic bounds. Applying
that representation to NOR, CSM and CuratedModuleV2 remains unproved.

The composition uses the registry counter-sum and monotonicity lemmas to
justify subtraction, and the three arithmetic lemmas to bound uint256
operations. The numeric premises include uint16 shares, uint64 counts,
allocation entries and totals, and uint128 maxEBType2 in wei; they are not
all consequences of Solidity field widths.
-/

namespace LidoSRv3.Audit.Guarantees.PAlloc1CheckedBoundsFromModules

open Verity.Stdlib.Math
open LidoSRv3.Audit.AllocCapacity
open LidoSRv3.Audit.Source.SRStorageExitedMonotonicity

/-- NOR registry state (packed per-operator counters). -/
abbrev RegistryState := LidoSRv3.Audit.Source.NodeOperatorsRegistry.State

/-- Operator id words of the registry enumeration. -/
abbrev RegistryWord := LidoSRv3.Audit.Source.TrioAlloc1.Word

/-- Packed counter sum of one field over the registry enumeration
(`NodeOperatorsRegistry.counterSum`; field 3 is `totalDepositedKeys`, field 1
is `totalExitedKeys`). -/
abbrev counterSum := LidoSRv3.Audit.Source.NodeOperatorsRegistry.counterSum

/-- NOR's source cap (`NodeOperatorsRegistry.sol:93`, enforced at line 289). -/
abbrev operatorCap : Nat := 200

/-- One registered module is a supported module: its summary replies are the
registry's packed counter sums over at most `operatorCap` operators, returned
as `uint256` words, and the router-side counters it reports were reached from
genesis by a successful history of the admitted writers. -/
structure SupportedModule (m : Module) : Prop where
  registry : ∃ (s : RegistryState) (ids : List RegistryWord)
      (ops : List Operation) (c : ExitedCounters),
    ids.length ≤ operatorCap ∧
    m.depositedCount = Verity.Core.Uint256.ofNat (counterSum s 3 ids) ∧
    m.summaryExitedCount = Verity.Core.Uint256.ofNat (counterSum s 1 ids) ∧
    applyOperations genesis ops = some c ∧
    c.depositedCount.val = counterSum s 3 ids ∧
    c.summaryExitedCount.val = counterSum s 1 ids ∧
    c.accountingExitedCount = m.accountingExitedCount

/-- The A-SUPPORTED-MODULES premise for one allocation call: nonzero
`maxEBType1`, every registered module supported, and explicit representation and numeric bounds; see each structure below. -/
structure SupportedModules (cfg : Config) (modules : List Module)
    (depositsToAllocate : Verity.Core.Uint256) (isTopUp : Bool) : Prop where
  maxEBType1_nonzero : cfg.maxEBType1 ≠ 0
  supported : ∀ m ∈ modules, SupportedModule m
  typeBounds : PAlloc1TargetMultBounded.PinnedStakingModuleTypeBounds
    cfg modules depositsToAllocate
  entryBounds : PAlloc1TotalAdditionBounded.PinnedAllocationEntryBounds
    cfg modules depositsToAllocate
  availableBounds : PAlloc1AvailableArithmeticBounded.PinnedAvailableArithmeticBounds
    cfg modules isTopUp

/-- `counterSum_lt_word`: under the 200-operator cap the packed sum fits one
word, so the `uint256` reply carries the registry sum exactly. -/
theorem counter_reply_exact (s : RegistryState) (field : Fin 4) (ids : List RegistryWord)
    (hcap : ids.length ≤ operatorCap) :
    (Verity.Core.Uint256.ofNat (counterSum s field ids)).val = counterSum s field ids := by
  have hlt : counterSum s field ids < Verity.Core.Uint256.modulus :=
    LidoSRv3.Audit.Source.NodeOperatorsRegistry.counterSum_lt_word s field ids hcap
  show counterSum s field ids % Verity.Core.Uint256.modulus = counterSum s field ids
  exact Nat.mod_eq_of_lt hlt

/-- `reachable_state_is_monotone` transported to the module's replies: a
supported module satisfies the `active_subtraction` conjunct. -/
theorem active_subtraction_of_supported (m : Module) (h : SupportedModule m) :
    (wordMax m.summaryExitedCount m.accountingExitedCount).val ≤ m.depositedCount.val := by
  obtain ⟨s, ids, ops, c, hcap, hdep, hexit, hops, hcdep, hcexit, hcacc⟩ := h.registry
  have hmono : (wordMax c.summaryExitedCount c.accountingExitedCount).val ≤
      c.depositedCount.val :=
    reachable_state_is_monotone ops c hops
  have hd : m.depositedCount = c.depositedCount := by
    apply Verity.Core.Uint256.ext
    rw [hdep, counter_reply_exact s 3 ids hcap, hcdep]
  have he : m.summaryExitedCount = c.summaryExitedCount := by
    apply Verity.Core.Uint256.ext
    rw [hexit, counter_reply_exact s 1 ids hcap, hcexit]
  rw [hd, he, ← hcacc]
  exact hmono

/-- The composition: A-SUPPORTED-MODULES yields all five `CheckedBounds` fields. -/
theorem checkedBounds_of_supportedModules {cfg : Config} {modules : List Module}
    {depositsToAllocate : Verity.Core.Uint256} {isTopUp : Bool}
    (h : SupportedModules cfg modules depositsToAllocate isTopUp) :
    CheckedBounds cfg modules depositsToAllocate isTopUp :=
  { maxEBType1_nonzero := h.maxEBType1_nonzero
    active_subtraction := fun m hm => active_subtraction_of_supported m (h.supported m hm)
    total_addition :=
      PAlloc1TotalAdditionBounded.total_addition_under_pinned_bounds h.entryBounds
    available_arithmetic :=
      PAlloc1AvailableArithmeticBounded.available_arithmetic_under_pinned_bounds h.availableBounds
    target_multiplication :=
      PAlloc1TargetMultBounded.target_multiplication_under_pinned_type_bounds h.typeBounds }

/-- Registered P-ALLOC-1 consumer under A-SUPPORTED-MODULES: checked execution
succeeds and its capacity column equals the independent `MathView`
specification. This is `PAlloc1.checked_execute` with `CheckedBounds` derived
from `SupportedModules` instead of supplied by the caller. -/
theorem checked_execute_under_supported_modules
    (cfg : Config) (modules : List Module) (depositsToAllocate : Verity.Core.Uint256)
    (isTopUp : Bool)
    (h : SupportedModules cfg modules depositsToAllocate isTopUp) :
    ∃ rows, SolidityAllocCapacity.execute cfg modules depositsToAllocate isTopUp = some rows ∧
      rows.map (fun row => (row.capacity : Nat)) =
        MathView.capacities cfg modules depositsToAllocate isTopUp :=
  PAlloc1.checked_execute cfg modules depositsToAllocate isTopUp
    (checkedBounds_of_supportedModules h)

#print axioms checkedBounds_of_supportedModules
#print axioms checked_execute_under_supported_modules

end LidoSRv3.Audit.Guarantees.PAlloc1CheckedBoundsFromModules
