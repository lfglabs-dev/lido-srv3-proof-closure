import LidoSRv3.Audit.Model.AllocCapacity
import LidoSRv3.Audit.Source.NodeOperatorsRegistry.CounterBounds
import LidoSRv3.Audit.Source.SRStorageExitedMonotonicity
import LidoSRv3.Audit.Guarantees.PAlloc1TargetMultBounded
import LidoSRv3.Audit.Guarantees.PAlloc1TotalAdditionBounded
import LidoSRv3.Audit.Guarantees.PAlloc1AvailableArithmeticBounded
import LidoSRv3.Audit.Guarantees.PAlloc1

/-! # P-ALLOC-1 `CheckedBounds` from supported modules (A-SUPPORTED-MODULES)

**Assumption A-SUPPORTED-MODULES (Thomas 2026-09-17, step 1a of the
"not proven" cleanup):** the router's registered modules are the pinned
`NodeOperatorsRegistry` and `CSModule` at their deployed addresses, and their
storage is reachable only through the admitted writers.

This module names that assumption as the premise `SupportedModules` and
composes three existing results into the five-field `CheckedBounds` premise
consumed by the registered abstract parent `PAlloc1.checked_execute`:

- `NodeOperatorsRegistry.counterSum_lt_word` (NOR's 200-operator cap,
  `NodeOperatorsRegistry.sol:93`): the registry's packed counter sum fits one
  word, so the `uint256` summary reply is that sum exactly, without wrap.
- `SRStorageExitedMonotonicity.reachable_state_is_monotone`: every counter
  state reached from genesis by the admitted `addValidators` /
  `_updateExitedCounters` writers satisfies `exited ≤ deposited`, which is the
  `active_subtraction` conjunct.
- `PAlloc1TargetMultBounded`, `PAlloc1TotalAdditionBounded` and
  `PAlloc1AvailableArithmeticBounded`: the pinned uint16/uint64 type bounds and
  `MAX_STAKING_MODULES_COUNT = 32` derive the three arithmetic conjuncts.

**Status:** the premise is an accepted registry assumption
(`audit/assumptions.yaml`, `A-SUPPORTED-MODULES`), not a theorem about the
deployed modules. Binding the enumerated operator ids, the registry storage and
every writer of CSM/NOR to the deployed runtimes remains the assumption's
removal path. -/

namespace LidoSRv3.Audit.Guarantees.PAlloc1CheckedBoundsFromModules

open Verity
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
    m.depositedCount = Uint256.ofNat (counterSum s 3 ids) ∧
    m.summaryExitedCount = Uint256.ofNat (counterSum s 1 ids) ∧
    applyOperations genesis ops = some c ∧
    (c.depositedCount : Nat) = counterSum s 3 ids ∧
    (c.summaryExitedCount : Nat) = counterSum s 1 ids ∧
    c.accountingExitedCount = m.accountingExitedCount

/-- The A-SUPPORTED-MODULES premise for one allocation call: nonzero
`maxEBType1`, every registered module supported, and the pinned type bounds of
`SRLib.sol`'s module struct and allocation entry. -/
structure SupportedModules (cfg : Config) (modules : List Module)
    (depositsToAllocate : Uint256) (isTopUp : Bool) : Prop where
  maxEBType1_nonzero : cfg.maxEBType1 ≠ 0
  supported : ∀ m ∈ modules, SupportedModule m
  typeBounds : PAlloc1TargetMultBounded.PinnedStakingModuleTypeBounds
    cfg modules depositsToAllocate
  entryBounds : PAlloc1TotalAdditionBounded.PinnedAllocationEntryBounds
    cfg modules depositsToAllocate
  availableBounds : PAlloc1AvailableArithmeticBounded.PinnedAvailableArithmeticBounds
    cfg modules isTopUp

/-- Two words with equal values are equal. -/
theorem uint256_ext {a b : Uint256} (h : a.val = b.val) : a = b := by
  cases a
  cases b
  simp only at h
  subst h
  rfl

/-- `counterSum_lt_word`: under the 200-operator cap the packed sum fits one
word, so the `uint256` reply carries the registry sum exactly. -/
theorem counter_reply_exact (s : RegistryState) (field : Fin 4) (ids : List RegistryWord)
    (hcap : ids.length ≤ operatorCap) :
    (Uint256.ofNat (counterSum s field ids)).val = counterSum s field ids :=
  Nat.mod_eq_of_lt
    (LidoSRv3.Audit.Source.NodeOperatorsRegistry.counterSum_lt_word s field ids hcap)

/-- `reachable_state_is_monotone` transported to the module's replies: a
supported module satisfies the `active_subtraction` conjunct. -/
theorem active_subtraction_of_supported (m : Module) (h : SupportedModule m) :
    (wordMax m.summaryExitedCount m.accountingExitedCount : Nat) ≤ (m.depositedCount : Nat) := by
  obtain ⟨s, ids, ops, c, hcap, hdep, hexit, hops, hcdep, hcexit, hcacc⟩ := h.registry
  have hmono : (wordMax c.summaryExitedCount c.accountingExitedCount : Nat) ≤
      (c.depositedCount : Nat) :=
    reachable_state_is_monotone ops c hops
  have hd : m.depositedCount = c.depositedCount := by
    apply uint256_ext
    rw [hdep, counter_reply_exact s 3 ids hcap, hcdep]
  have he : m.summaryExitedCount = c.summaryExitedCount := by
    apply uint256_ext
    rw [hexit, counter_reply_exact s 1 ids hcap, hcexit]
  rw [hd, he, ← hcacc]
  exact hmono

/-- The composition: A-SUPPORTED-MODULES yields all five `CheckedBounds` fields. -/
theorem checkedBounds_of_supportedModules {cfg : Config} {modules : List Module}
    {depositsToAllocate : Uint256} {isTopUp : Bool}
    (h : SupportedModules cfg modules depositsToAllocate isTopUp) :
    CheckedBounds cfg modules depositsToAllocate isTopUp where
  maxEBType1_nonzero := h.maxEBType1_nonzero
  active_subtraction := fun m hm => active_subtraction_of_supported m (h.supported m hm)
  total_addition :=
    PAlloc1TotalAdditionBounded.total_addition_under_pinned_bounds h.entryBounds
  available_arithmetic :=
    PAlloc1AvailableArithmeticBounded.available_arithmetic_under_pinned_bounds h.availableBounds
  target_multiplication :=
    PAlloc1TargetMultBounded.target_multiplication_under_pinned_type_bounds h.typeBounds

/-- Registered P-ALLOC-1 consumer under A-SUPPORTED-MODULES: checked execution
succeeds and its capacity column equals the independent `MathView`
specification. This is `PAlloc1.checked_execute` with `CheckedBounds` derived
from `SupportedModules` instead of supplied by the caller. -/
theorem checked_execute_under_supported_modules
    (cfg : Config) (modules : List Module) (depositsToAllocate : Uint256) (isTopUp : Bool)
    (h : SupportedModules cfg modules depositsToAllocate isTopUp) :
    ∃ rows, SolidityAllocCapacity.execute cfg modules depositsToAllocate isTopUp = some rows ∧
      rows.map (fun row => (row.capacity : Nat)) =
        MathView.capacities cfg modules depositsToAllocate isTopUp :=
  PAlloc1.checked_execute cfg modules depositsToAllocate isTopUp
    (checkedBounds_of_supportedModules h)

end LidoSRv3.Audit.Guarantees.PAlloc1CheckedBoundsFromModules
