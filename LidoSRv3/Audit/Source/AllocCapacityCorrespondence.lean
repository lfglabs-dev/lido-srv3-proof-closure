import LidoSRv3.Legacy.Model

/-!
Pinned source correspondence for the SRv3 allocation-capacity computation at
`lidofinance/core@af095e48bbc1c3841c2c9936219c8461af01056b`,
`contracts/0.8.25/sr/SRLib.sol`, `_getModulesAllocationAndCapacity`,
lines 493--559.

`StakingRouter.getDepositAllocations` (`contracts/0.8.25/sr/StakingRouter.sol`,
lines 929--936) forwards to `SRLib._getDepositAllocations` (`SRLib.sol`, lines
391--431), which obtains `(allocated, capacities)` from
`_getModulesAllocationAndCapacity` before running
`MinFirstAllocationStrategy.allocate`.  The capacity array produced by lines
493--559 is the economic transition modelled here.

The definitions below are the source-shaped presentation of that function:

* lines 506, 521--532 -- the first loop, which computes each module's
  current-allocation equivalent and accumulates `totalValidators`;
* lines 539--558 -- the second loop, which for an *active* module computes an
  uncapped capacity (lines 543--549), computes
  `targetValidators = (shareLimit * totalValidators) / TOTAL_BASIS_POINTS`
  (line 552), and clamps with `Math.min` (line 554); an inactive module keeps
  `_allocations[i]` unchanged (lines 541, 557).

Scope.  This module is capacity-only.  It makes no claim about the proportional
allocation amounts computed by `MinFirstAllocationStrategy.allocate` (that slice
is P-ALLOC-2, `LidoSRv3.Audit.Source.MinFirstCorrespondence`), and no claim about
Yul or deployed-bytecode behaviour.

Arithmetic.  Solidity `uint256` `+`, `*`, and `/` are modelled by unbounded `Nat`
operations.  `Nat` division truncates exactly as EVM `DIV` does, but the `Nat`
encoding cannot observe `uint256` overflow, so this is a correspondence under the
no-overflow reading of the pinned spans, recorded as `A-SOURCE-SHAPED` in
`audit/assumptions.yaml`.  Storage reads, the `IStakingModule` external calls at
lines 516--517 and 529, and array allocation are interface facts, not modelled
here.
-/

namespace LidoSRv3.Audit.SolidityAllocCapacity

open LidoSRv3

/--
Per-module data the pinned loops read.  Each field names the exact source
expression it stands for; nothing else in `_getModulesAllocationAndCapacity`
influences `_capacities[i]`.
-/
structure SourceModule where
  /-- `stateConfig.stakeShareLimit`, cached at source line 513. -/
  shareLimit : Nat
  /-- `cache[i].status == StakingModuleStatus.Active`, source lines 514 and 542. -/
  isActive : Bool
  /-- `WithdrawalCredentials.isType2(...)`, source lines 515, 527, and 543. -/
  isType2 : Bool
  /-- `depositableValidatorsCount` from `_getStakingModuleSummary`, source line 518. -/
  depositableCount : Nat
  /-- `depositedValidatorsCount` from `_getStakingModuleSummary`, source line 516. -/
  depositedCount : Nat
  /-- `exitedValidatorsCount` from `_getStakingModuleSummary`, source line 516. -/
  summaryExitedCount : Nat
  /-- `moduleState.accounting.exitedValidatorsCount`, source line 522. -/
  accountingExitedCount : Nat
  /-- `getIStakingModuleV2().getTotalModuleStake()`, source line 529. -/
  totalModuleStake : Nat
  deriving Repr

/-- `SRUtils.TOTAL_BASIS_POINTS`, the divisor at source line 552. -/
def totalBasisPoints : Nat := 10000

/-- `cache[i].activeCount`, source lines 521--525. -/
def activeCount (s : SourceModule) : Nat :=
  s.depositedCount - max s.summaryExitedCount s.accountingExitedCount

/--
OpenZeppelin `Math.ceilDiv` (`@openzeppelin/contracts-v5.2`), as called at
source line 529.  This is the library's own branch shape, not the Lean model's.
-/
def mathCeilDiv (a b : Nat) : Nat :=
  if a = 0 then 0 else (a - 1) / b + 1

/-- `_allocations[i]` after the first loop, source lines 521--531. -/
def allocationEntry (maxEBType1 : Nat) (s : SourceModule) : Nat :=
  if s.isType2 then mathCeilDiv s.totalModuleStake maxEBType1 else activeCount s

/-- `totalValidators` after the first loop, source lines 506 and 532. -/
def totalValidators (maxEBType1 depositsToAllocate : Nat) (srcs : List SourceModule) : Nat :=
  depositsToAllocate + (srcs.map (allocationEntry maxEBType1)).sum

/-- `targetValidators`, source line 552. -/
def targetValidators (total : Nat) (s : SourceModule) : Nat :=
  s.shareLimit * total / totalBasisPoints

/-- The active-module capacity before the `Math.min` clamp, source lines 543--549. -/
def uncappedCapacity (maxEBType1 maxEBType2 : Nat) (isTopUp : Bool) (s : SourceModule) : Nat :=
  if isTopUp && s.isType2 then
    activeCount s * maxEBType2 / maxEBType1
  else
    allocationEntry maxEBType1 s + s.depositableCount

/-- `_capacities[i]`: the whole second-loop body, source lines 540--557. -/
def capacityEntry (maxEBType1 maxEBType2 : Nat) (isTopUp : Bool) (total : Nat)
    (s : SourceModule) : Nat :=
  if s.isActive then
    min (targetValidators total s) (uncappedCapacity maxEBType1 maxEBType2 isTopUp s)
  else
    allocationEntry maxEBType1 s

/-- The returned `_capacities` array, source lines 534--558. -/
def capacities (maxEBType1 maxEBType2 : Nat) (isTopUp : Bool) (depositsToAllocate : Nat)
    (srcs : List SourceModule) : List Nat :=
  srcs.map
    (capacityEntry maxEBType1 maxEBType2 isTopUp
      (totalValidators maxEBType1 depositsToAllocate srcs))

/--
Field-level correspondence between one pinned-source module record and one
`LidoSRv3.Module` of the Lean model.

`activeCounts` is the honest place where the two representations differ: the
pinned source takes `Math.max` of the module-summary and accounting exited
counts (source line 522), while the Lean model carries a single
`exitedValidatorsCount`.  Correspondence therefore *assumes* the model's field
already holds that maximum.
-/
structure ModuleCorresponds (cfg : AllocationConfig) (m : Module) (s : SourceModule) : Prop where
  shareLimits : s.shareLimit = m.stakeShareLimitBps
  statuses : s.isActive = decide (m.status = ModuleStatus.active)
  credentialTypes : s.isType2 = m.supportsTopUp
  depositables : s.depositableCount = m.depositableValidators
  activeCounts : activeCount s = moduleActiveValidators m
  stakes : s.totalModuleStake = m.totalModuleStakeWei

/-- Router-order correspondence: the two lists describe the same modules in the
same index order that `SRStorage.getModuleIdAt` walks at source line 509. -/
def RowsCorrespond (cfg : AllocationConfig) : List Module → List SourceModule → Prop
  | [], [] => True
  | m :: ms, s :: ss => ModuleCorresponds cfg m s ∧ RowsCorrespond cfg ms ss
  | _, _ => False

theorem rowsCorrespond_nil_cons (cfg : AllocationConfig) (s : SourceModule)
    (ss : List SourceModule) : ¬ RowsCorrespond cfg [] (s :: ss) :=
  fun h => h

theorem rowsCorrespond_cons_nil (cfg : AllocationConfig) (m : Module) (ms : List Module) :
    ¬ RowsCorrespond cfg (m :: ms) [] :=
  fun h => h

/-- The OpenZeppelin branch shape and the model's `ceilDiv` agree on a nonzero
divisor.  `_cfg.maxEBType1` is the max effective balance of a type-1 validator,
so `maxEBType1 = 0` is outside the pinned configuration. -/
theorem mathCeilDiv_eq_ceilDiv {a b : Nat} (hb : b ≠ 0) :
    mathCeilDiv a b = ceilDiv a b := by
  have hbpos : 0 < b := Nat.pos_of_ne_zero hb
  unfold mathCeilDiv ceilDiv
  rw [if_neg hb]
  cases a with
  | zero =>
      simp only [Nat.zero_add]
      exact (Nat.div_eq_of_lt (by omega)).symm
  | succ n =>
      rw [if_neg (by omega)]
      have hrw : n + 1 + b - 1 = n + b := by omega
      rw [hrw, Nat.add_div_right n hbpos]
      simp

theorem allocationEntry_eq {cfg : AllocationConfig} {m : Module} {s : SourceModule}
    (hCfg : cfg.maxEBType1 ≠ 0) (h : ModuleCorresponds cfg m s) :
    allocationEntry cfg.maxEBType1 s = moduleCurrentAllocationEquivalent cfg m := by
  unfold allocationEntry moduleCurrentAllocationEquivalent
  rw [h.credentialTypes]
  cases m.supportsTopUp with
  | false => simpa using h.activeCounts
  | true => simp [h.stakes, mathCeilDiv_eq_ceilDiv hCfg]

theorem sum_allocationEntry_eq {cfg : AllocationConfig} (hCfg : cfg.maxEBType1 ≠ 0) :
    ∀ {modules : List Module} {srcs : List SourceModule}, RowsCorrespond cfg modules srcs →
      (srcs.map (allocationEntry cfg.maxEBType1)).sum
        = (modules.map (moduleCurrentAllocationEquivalent cfg)).sum := by
  intro modules
  induction modules with
  | nil =>
      intro srcs hRows
      cases srcs with
      | nil => rfl
      | cons s ss => exact absurd hRows (rowsCorrespond_nil_cons cfg s ss)
  | cons m ms ih =>
      intro srcs hRows
      cases srcs with
      | nil => exact absurd hRows (rowsCorrespond_cons_nil cfg m ms)
      | cons s ss =>
          simp only [List.map_cons, List.sum_cons]
          rw [allocationEntry_eq hCfg hRows.1, ih hRows.2]

/-- The first loop's `totalValidators` accumulator (source lines 506, 532) equals
the model's `allocationTotalValidators`. -/
theorem totalValidators_eq {cfg : AllocationConfig} {modules : List Module}
    {srcs : List SourceModule} {depositsToAllocate : Nat}
    (hCfg : cfg.maxEBType1 ≠ 0) (hRows : RowsCorrespond cfg modules srcs) :
    totalValidators cfg.maxEBType1 depositsToAllocate srcs
      = allocationTotalValidators cfg modules depositsToAllocate := by
  unfold totalValidators allocationTotalValidators
  rw [sum_allocationEntry_eq hCfg hRows, Nat.add_comm]

/-- The share-limit target at source line 552 equals the model's
`moduleTargetValidators`; `SRUtils.TOTAL_BASIS_POINTS` and `bpsDenominator` are
both 10000. -/
theorem targetValidators_eq {cfg : AllocationConfig} {m : Module} {s : SourceModule}
    {modules : List Module} {depositsToAllocate total : Nat}
    (hTotal : total = allocationTotalValidators cfg modules depositsToAllocate)
    (h : ModuleCorresponds cfg m s) :
    targetValidators total s = moduleTargetValidators cfg modules depositsToAllocate m := by
  unfold targetValidators moduleTargetValidators totalBasisPoints
  rw [hTotal, h.shareLimits]
  rfl

/-- The pre-clamp active capacity at source lines 543--549 equals the model's
`moduleAvailableCapacityEquivalent`. -/
theorem uncappedCapacity_eq {cfg : AllocationConfig} {m : Module} {s : SourceModule}
    {isTopUp : Bool} (hCfg : cfg.maxEBType1 ≠ 0) (h : ModuleCorresponds cfg m s) :
    uncappedCapacity cfg.maxEBType1 cfg.maxEBType2 isTopUp s
      = moduleAvailableCapacityEquivalent cfg isTopUp m := by
  unfold uncappedCapacity moduleAvailableCapacityEquivalent
  rw [h.credentialTypes]
  cases isTopUp <;> cases m.supportsTopUp <;>
    simp [h.activeCounts, h.depositables, allocationEntry_eq hCfg h]

/--
Pinned-source capacity correspondence, stated for a fixed `totalValidators`.

The source-shaped second-loop body of `SRLib._getModulesAllocationAndCapacity`
(lines 540--557) returns exactly the Lean model's `allocationCapacityRow`
capacity for the corresponding module.
-/
theorem capacityEntry_eq_of_total {cfg : AllocationConfig} {m : Module} {s : SourceModule}
    {modules : List Module} {depositsToAllocate total : Nat} {isTopUp : Bool}
    (hCfg : cfg.maxEBType1 ≠ 0)
    (hTotal : total = allocationTotalValidators cfg modules depositsToAllocate)
    (h : ModuleCorresponds cfg m s) :
    capacityEntry cfg.maxEBType1 cfg.maxEBType2 isTopUp total s
      = (allocationCapacityRow cfg modules depositsToAllocate isTopUp m).capacity := by
  unfold capacityEntry allocationCapacityRow
  rw [h.statuses]
  by_cases hActive : m.status = ModuleStatus.active
  · rw [targetValidators_eq hTotal h, uncappedCapacity_eq hCfg h]
    simp [hActive]
  · simp only [decide_eq_true_eq, if_neg hActive]
    exact allocationEntry_eq hCfg h

/--
Pinned-source capacity correspondence for a single active or inactive module.

Given router-order correspondence for the whole module list (needed because
`totalValidators` at source line 532 is a global accumulator) and field
correspondence for one module, `SRLib._getModulesAllocationAndCapacity`
(lines 493--559) assigns that module exactly the capacity the Lean model's
`allocationCapacityRow` assigns.

This is capacity-only: it excludes the proportional allocation amounts computed
downstream by `MinFirstAllocationStrategy.allocate`.
-/
theorem capacityEntry_eq_model_capacity {cfg : AllocationConfig} {m : Module}
    {s : SourceModule} {modules : List Module} {srcs : List SourceModule}
    {depositsToAllocate : Nat} {isTopUp : Bool}
    (hCfg : cfg.maxEBType1 ≠ 0)
    (hRows : RowsCorrespond cfg modules srcs)
    (h : ModuleCorresponds cfg m s) :
    capacityEntry cfg.maxEBType1 cfg.maxEBType2 isTopUp
        (totalValidators cfg.maxEBType1 depositsToAllocate srcs) s
      = (allocationCapacityRow cfg modules depositsToAllocate isTopUp m).capacity :=
  capacityEntry_eq_of_total hCfg (totalValidators_eq hCfg hRows) h

/-- Pointwise mapping lemma for the second loop at a fixed `totalValidators`
accumulator.  `fullModules` stays fixed because the target share at source line
552 is computed from the global accumulator, not from the loop suffix. -/
theorem map_capacityEntry_eq {cfg : AllocationConfig} {fullModules : List Module}
    {depositsToAllocate total : Nat} {isTopUp : Bool}
    (hCfg : cfg.maxEBType1 ≠ 0)
    (hTotal : total = allocationTotalValidators cfg fullModules depositsToAllocate) :
    ∀ {ms : List Module} {ss : List SourceModule}, RowsCorrespond cfg ms ss →
      ss.map (capacityEntry cfg.maxEBType1 cfg.maxEBType2 isTopUp total)
        = (ms.map (allocationCapacityRow cfg fullModules depositsToAllocate isTopUp)).map
            AllocationCapacityRow.capacity := by
  intro ms
  induction ms with
  | nil =>
      intro ss hRows
      cases ss with
      | nil => rfl
      | cons s ss' => exact absurd hRows (rowsCorrespond_nil_cons cfg s ss')
  | cons m ms' ih =>
      intro ss hRows
      cases ss with
      | nil => exact absurd hRows (rowsCorrespond_cons_nil cfg m ms')
      | cons s ss' =>
          simp only [List.map_cons]
          rw [capacityEntry_eq_of_total hCfg hTotal hRows.1, ih hRows.2]

/-- Whole-array version: the pinned `_capacities` return value equals the Lean
model's capacity column, in router order. -/
theorem capacities_eq_model_capacities {cfg : AllocationConfig} {modules : List Module}
    {srcs : List SourceModule} {depositsToAllocate : Nat} {isTopUp : Bool}
    (hCfg : cfg.maxEBType1 ≠ 0) (hRows : RowsCorrespond cfg modules srcs) :
    capacities cfg.maxEBType1 cfg.maxEBType2 isTopUp depositsToAllocate srcs
      = allocatedCapacityValues
          (modulesAllocationAndCapacity cfg modules depositsToAllocate isTopUp) :=
  map_capacityEntry_eq hCfg (totalValidators_eq hCfg hRows) hRows

end LidoSRv3.Audit.SolidityAllocCapacity
