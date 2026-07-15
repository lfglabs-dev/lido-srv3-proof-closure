import Verity.Core
import Verity.EVM.Uint256

namespace LidoSRv3

/-!
  A small Verity/Lean model of the SRv3 economic state machine.

  The model is intentionally narrower than the deployed system. It captures the
  accounting transitions named in the report: reserve splitting, router deposit
  pulls, accepted module-balance reports, reward composition, and status gates.
  Solidity correspondence is tracked in `verity/targets/source-map.json`.
-/

abbrev Wei := Nat
abbrev Gwei := Nat
abbrev Bps := Nat
abbrev ModuleId := Nat
abbrev Address := Nat
abbrev ValidatorsCount := Nat

def oneEthWei : Wei := 1000000000000000000
def oneGweiWei : Wei := 1000000000
def validatorDepositWei : Wei := 32 * oneEthWei
def bpsDenominator : Nat := 10000
def maxValueGwei : Gwei := 1000000000000000000
def feePrecisionPoints : Nat := 100000000000000000000
def uint64Max : Nat := 18446744073709551615

inductive ModuleStatus
  | active
  | depositsPaused
  | stopped
  | inactive
  deriving DecidableEq, Repr

structure Module where
  id : ModuleId
  status : ModuleStatus
  stakeShareLimitBps : Bps
  priorityExitShareThresholdBps : Bps
  depositableValidators : Nat
  maxDepositsPerBlock : Nat
  minDepositBlockDistance : Nat
  lastDepositWei : Wei
  depositedValidatorsCount : ValidatorsCount
  exitedValidatorsCount : ValidatorsCount
  validatorsBalanceGwei : Gwei
  totalModuleStakeWei : Wei
  supportsTopUp : Bool
  moduleFeeBps : Bps
  treasuryFeeBps : Bps
  rewardRecipient : Address
  deriving Repr

structure AllocationConfig where
  maxEBType1 : Wei
  maxEBType2 : Wei
  deriving Repr

structure AllocationCapacityRow where
  moduleId : ModuleId
  currentAllocation : Nat
  capacity : Nat
  targetValidators : Nat
  activeValidators : Nat
  deriving Repr

structure RewardDistributionRow where
  moduleId : ModuleId
  recipient : Address
  validatorsBalanceGwei : Gwei
  moduleFee : Nat
  treasuryFee : Nat
  paidModuleFee : Nat
  deriving Repr

structure RewardMintedReportRow where
  moduleId : ModuleId
  totalShares : Nat
  deriving DecidableEq, Repr

structure State where
  bufferedEther : Wei
  depositReserve : Wei
  withdrawalReserve : Wei
  routerEthBalanceWei : Wei
  beaconDepositSinkWei : Wei
  routerBalanceGwei : Gwei
  modules : List Module
  lastAcceptedReport : Option (List (ModuleId × Gwei))
  deriving Repr

def depositReserveUsed (s : State) : Wei :=
  min s.bufferedEther s.depositReserve

def withdrawalReserveUsed (s : State) : Wei :=
  min (s.bufferedEther - depositReserveUsed s) s.withdrawalReserve

def unreservedEther (s : State) : Wei :=
  s.bufferedEther - depositReserveUsed s - withdrawalReserveUsed s

def depositableEther (s : State) : Wei :=
  depositReserveUsed s + unreservedEther s

def isDepositEligible (m : Module) : Prop :=
  m.status = ModuleStatus.active

def isRewardEligible (m : Module) : Prop :=
  m.status ≠ ModuleStatus.stopped

/-!
  Router-order deposit allocation.

  `_getDepositAllocations`/`MinFirstAllocationStrategy` split one router deposit
  budget across modules, producing a per-module allocated count. The model
  represents that result as a list of `(module, allocated)` rows: `allocated` is
  the amount routed to *that* module, not the router total. Only active modules
  may receive a positive count, matching the deposit gate. `allocatedDeposits`
  gates a single row's own amount, and `totalAllocatedDeposits` sums the per-row
  amounts so the router total is conserved as the sum of module deltas rather
  than scaling with the active-module count.
-/

def allocatedDeposits (m : Module) (allocated : Nat) : Nat :=
  if m.status = ModuleStatus.active then allocated else 0

def depositAllocationWellFormed (rows : List (Module × Nat)) : Prop :=
  ∀ row ∈ rows, row.fst.status ≠ ModuleStatus.active → row.snd = 0

def totalAllocatedDeposits (rows : List (Module × Nat)) : Nat :=
  (rows.map (fun row => allocatedDeposits row.fst row.snd)).sum

def depositPullWei (actualDeposits : Nat) : Wei :=
  validatorDepositWei * actualDeposits

def roundDownToGwei (amount : Wei) : Wei :=
  amount - (amount % oneGweiWei)

def depositAllowed (s : State) (actualDeposits : Nat) : Prop :=
  depositPullWei actualDeposits ≤ depositableEther s

def ceilDiv (n d : Nat) : Nat :=
  if d = 0 then 0 else (n + d - 1) / d

/-!
  `StakingRouter.deposit` translation surface.

  The Solidity body is modeled as a router-local transition with explicit
  interfaces for the external calls:

  * `moduleAllocationWei` is the value returned by SRv3 allocation logic for
    `_getModuleDepositAllocation(_stakingModuleId, depositableEther, false)`.
  * `actualDeposits` is the number of pubkeys returned by
    `IStakingModule.obtainDepositData`; signature bytes, pubkey bytes, and BLS
    validity are intentionally outside this economic model.
  * `LIDO.withdrawDepositableEther` is represented by subtracting exactly the
    pulled amount from the Lido buffer and stored deposit reserve, saturating
    the reserve at zero, when `depositAllowed` holds.
  * `BeaconChainDepositor.makeBeaconChainDeposits32ETH` is represented as a
    value sink that receives exactly the pulled amount.

  Authorization, calldata decoding, withdrawal credentials encoding, event
  emission, revert strings, and exact call-stack behavior remain trust-boundary
  facts documented in `verity/targets/trust-boundary.json`.
-/

def depositMaxCount (m : Module) (moduleAllocationWei : Wei) : Nat :=
  min m.maxDepositsPerBlock (moduleAllocationWei / validatorDepositWei)

def moduleActiveValidators (m : Module) : ValidatorsCount :=
  m.depositedValidatorsCount - m.exitedValidatorsCount

def moduleCurrentAllocationEquivalent (cfg : AllocationConfig) (m : Module) : Nat :=
  if m.supportsTopUp then
    ceilDiv m.totalModuleStakeWei cfg.maxEBType1
  else
    moduleActiveValidators m

def moduleAvailableCapacityEquivalent
    (cfg : AllocationConfig) (isTopUp : Bool) (m : Module) : Nat :=
  if isTopUp && m.supportsTopUp then
    moduleActiveValidators m * cfg.maxEBType2 / cfg.maxEBType1
  else
    moduleCurrentAllocationEquivalent cfg m + m.depositableValidators

def allocationTotalValidators
    (cfg : AllocationConfig) (modules : List Module) (depositsToAllocate : Nat) :
    Nat :=
  (modules.map (moduleCurrentAllocationEquivalent cfg)).sum + depositsToAllocate

def moduleTargetValidators
    (cfg : AllocationConfig) (modules : List Module) (depositsToAllocate : Nat)
    (m : Module) : Nat :=
  m.stakeShareLimitBps *
      allocationTotalValidators cfg modules depositsToAllocate /
    bpsDenominator

def allocationCapacityRow
    (cfg : AllocationConfig) (modules : List Module) (depositsToAllocate : Nat)
    (isTopUp : Bool) (m : Module) : AllocationCapacityRow :=
  let currentAllocation := moduleCurrentAllocationEquivalent cfg m
  let activeValidators := moduleActiveValidators m
  let targetValidators := moduleTargetValidators cfg modules depositsToAllocate m
  let capacity :=
    if m.status = ModuleStatus.active then
      min targetValidators (moduleAvailableCapacityEquivalent cfg isTopUp m)
    else
      currentAllocation
  { moduleId := m.id,
    currentAllocation := currentAllocation,
    capacity := capacity,
    targetValidators := targetValidators,
    activeValidators := activeValidators }

def modulesAllocationAndCapacity
    (cfg : AllocationConfig) (modules : List Module) (depositsToAllocate : Nat)
    (isTopUp : Bool) : List AllocationCapacityRow :=
  modules.map (allocationCapacityRow cfg modules depositsToAllocate isTopUp)

def allocatedCapacityValues (rows : List AllocationCapacityRow) : List Nat :=
  rows.map AllocationCapacityRow.capacity

def moduleExists (modules : List Module) (moduleId : ModuleId) : Bool :=
  (modules.find? (fun m => m.id = moduleId)).isSome

def shareParamsValid (stakeShareLimit priorityExitShareThreshold : Bps) : Bool :=
  (stakeShareLimit <= bpsDenominator) &&
    (priorityExitShareThreshold <= bpsDenominator) &&
      (stakeShareLimit <= priorityExitShareThreshold)

def moduleFeeSum (m : Module) : Nat :=
  m.moduleFeeBps + m.treasuryFeeBps

def otherModulesFeeSumConsistent
    : List Module → ModuleId → Nat → Bool
  | [], _, _ => true
  | m :: ms, moduleId, expectedFeeSum =>
      (if m.id = moduleId then
        true
      else
        moduleFeeSum m == expectedFeeSum) &&
        otherModulesFeeSumConsistent ms moduleId expectedFeeSum

def feeRowsValidFromExpected (expectedFeeSum : Nat) :
    List Bps → List Bps → Bool
  | [], [] => true
  | moduleFee :: moduleFees, treasuryFee :: treasuryFees =>
      (moduleFee + treasuryFee <= bpsDenominator) &&
        (moduleFee + treasuryFee == expectedFeeSum) &&
          feeRowsValidFromExpected expectedFeeSum moduleFees treasuryFees
  | _, _ => false

def allModuleFeesConsistent : List Bps → List Bps → Bool
  | [], [] => true
  | moduleFee :: moduleFees, treasuryFee :: treasuryFees =>
      let expectedFeeSum := moduleFee + treasuryFee
      (expectedFeeSum <= bpsDenominator) &&
        feeRowsValidFromExpected expectedFeeSum moduleFees treasuryFees
  | _, _ => false

def updateAllModuleFeesInModules : List Module → List Bps → List Bps → List Module
  | [], _, _ => []
  | m :: ms, moduleFee :: moduleFees, treasuryFee :: treasuryFees =>
      { m with moduleFeeBps := moduleFee, treasuryFeeBps := treasuryFee } ::
        updateAllModuleFeesInModules ms moduleFees treasuryFees
  | modules, _, _ => modules

def moduleFeeSumsWithinBps : List Module → Bool
  | [] => true
  | m :: ms =>
      (m.moduleFeeBps + m.treasuryFeeBps <= bpsDenominator) &&
        moduleFeeSumsWithinBps ms

def singleModuleParamsValid
    (modules : List Module) (moduleId : ModuleId)
    (stakeShareLimit priorityExitShareThreshold moduleFee treasuryFee : Bps)
    (maxDepositsPerBlock minDepositBlockDistance : Nat) : Bool :=
  shareParamsValid stakeShareLimit priorityExitShareThreshold &&
    (moduleFee + treasuryFee <= bpsDenominator) &&
      otherModulesFeeSumConsistent modules moduleId (moduleFee + treasuryFee) &&
        (minDepositBlockDistance != 0) &&
          (minDepositBlockDistance <= uint64Max) &&
            (maxDepositsPerBlock != 0) &&
              (maxDepositsPerBlock <= uint64Max)

def updateModuleParamsInModules
    (moduleId : ModuleId) (stakeShareLimit priorityExitShareThreshold : Bps)
    (moduleFee treasuryFee : Bps) (maxDepositsPerBlock minDepositBlockDistance : Nat)
    : List Module → List Module
  | [] => []
  | m :: ms =>
      (if m.id = moduleId then
        { m with
          stakeShareLimitBps := stakeShareLimit,
          priorityExitShareThresholdBps := priorityExitShareThreshold,
          moduleFeeBps := moduleFee,
          treasuryFeeBps := treasuryFee,
          maxDepositsPerBlock := maxDepositsPerBlock,
          minDepositBlockDistance := minDepositBlockDistance }
      else
        m) ::
        updateModuleParamsInModules moduleId stakeShareLimit
          priorityExitShareThreshold moduleFee treasuryFee maxDepositsPerBlock
          minDepositBlockDistance ms

/-!
  `SRLib._updateModuleParams` translation surface.

  The Solidity function validates stake-share parameters, checks the new
  module-plus-treasury fee sum, requires that fee sum to match all other modules,
  validates the uint64 deposit-distance and max-deposit bounds, and then updates
  the selected module's config/deposit fields. Role authorization, event
  emission, calldata representation, and storage packing remain trust-boundary
  facts.
-/

def updateModuleParamsTransition
    (s : State) (moduleId : ModuleId)
    (stakeShareLimit priorityExitShareThreshold moduleFee treasuryFee : Bps)
    (maxDepositsPerBlock minDepositBlockDistance : Nat) : Option State :=
  match s.modules.find? (fun m => m.id = moduleId) with
  | none => none
  | some _ =>
      if singleModuleParamsValid s.modules moduleId stakeShareLimit
          priorityExitShareThreshold moduleFee treasuryFee maxDepositsPerBlock
          minDepositBlockDistance then
        some
          { s with
            modules :=
              updateModuleParamsInModules moduleId stakeShareLimit
                priorityExitShareThreshold moduleFee treasuryFee
                maxDepositsPerBlock minDepositBlockDistance s.modules }
      else
        none

def updateModuleStatusInModules
    (moduleId : ModuleId) (status : ModuleStatus) : List Module → List Module
  | [] => []
  | m :: ms =>
      (if m.id = moduleId then { m with status := status } else m) ::
        updateModuleStatusInModules moduleId status ms

/-!
  `SRLib._setModuleStatus` translation surface.

  The public Solidity path checks that the selected module exists, rejects an
  unchanged status, and then updates only that module's router-stored status.
  The model keeps the router-order module loop explicit and proves that status
  changes do not alter validator-balance accounting. Governance authorization,
  packed storage, event emission, and internal harness no-op behavior remain
  trust-boundary facts.
-/

def updateModuleStatusTransition
    (s : State) (moduleId : ModuleId) (status : ModuleStatus) : Option State :=
  match s.modules.find? (fun m => m.id = moduleId) with
  | none => none
  | some m =>
      if m.status = status then
        none
      else
        some
          { s with modules := updateModuleStatusInModules moduleId status s.modules }

def addModuleConfigValid
    (modules : List Module) (moduleId : ModuleId)
    (stakeShareLimit priorityExitShareThreshold moduleFee treasuryFee : Bps)
    (maxDepositsPerBlock minDepositBlockDistance : Nat) : Bool :=
  (! moduleExists modules moduleId) &&
    singleModuleParamsValid modules moduleId stakeShareLimit
      priorityExitShareThreshold moduleFee treasuryFee maxDepositsPerBlock
      minDepositBlockDistance

def newModuleFromConfig
    (moduleId : ModuleId)
    (stakeShareLimit priorityExitShareThreshold moduleFee treasuryFee : Bps)
    (maxDepositsPerBlock minDepositBlockDistance : Nat)
    (supportsTopUp : Bool) (rewardRecipient : Address) : Module :=
  { id := moduleId,
    status := ModuleStatus.active,
    stakeShareLimitBps := stakeShareLimit,
    priorityExitShareThresholdBps := priorityExitShareThreshold,
    depositableValidators := 0,
    maxDepositsPerBlock := maxDepositsPerBlock,
    minDepositBlockDistance := minDepositBlockDistance,
    lastDepositWei := 0,
    depositedValidatorsCount := 0,
    exitedValidatorsCount := 0,
    validatorsBalanceGwei := 0,
    totalModuleStakeWei := 0,
    supportsTopUp := supportsTopUp,
    moduleFeeBps := moduleFee,
    treasuryFeeBps := treasuryFee,
    rewardRecipient := rewardRecipient }

/-!
  `SRLib._addModule` translation surface.

  The Solidity function creates a fresh staking-module entry after validating
  the same share, fee-sum, consistency, and deposit-parameter guards used by
  config updates. The model appends one active module with zero initial
  accounting fields. Module contract registration, address type checks,
  locator plumbing, event emission, packed storage, and governance authorization
  remain trust-boundary facts.
-/

def addModuleTransition
    (s : State) (moduleId : ModuleId)
    (stakeShareLimit priorityExitShareThreshold moduleFee treasuryFee : Bps)
    (maxDepositsPerBlock minDepositBlockDistance : Nat)
    (supportsTopUp : Bool) (rewardRecipient : Address) : Option State :=
  if addModuleConfigValid s.modules moduleId stakeShareLimit
      priorityExitShareThreshold moduleFee treasuryFee maxDepositsPerBlock
      minDepositBlockDistance then
    some
      { s with
        modules :=
          s.modules ++
            [newModuleFromConfig moduleId stakeShareLimit
              priorityExitShareThreshold moduleFee treasuryFee maxDepositsPerBlock
              minDepositBlockDistance supportsTopUp rewardRecipient] }
  else
    none

/-!
  `SRLib._updateAllModuleFees` translation surface.

  The Solidity function checks that the module-fee and treasury-fee arrays both
  match the router module count, returns on the empty-module case, validates
  every row's fee sum against `TOTAL_BASIS_POINTS`, requires all row sums to
  equal the first row's sum, and then updates every module config in router
  order. Authorization, event emission, calldata representation, and the
  `uint16` cast domain remain trust-boundary facts.
-/

def updateAllModuleFeesTransition
    (s : State) (moduleFees treasuryFees : List Bps) : Option State :=
  if moduleFees.length = s.modules.length ∧ treasuryFees.length = s.modules.length then
    if allModuleFeesConsistent moduleFees treasuryFees then
      some
        { s with
          modules := updateAllModuleFeesInModules s.modules moduleFees treasuryFees }
    else
      none
  else
    none

def allModuleSharesValid : List Bps → List Bps → Bool
  | [], [] => true
  | stakeShare :: stakeShares, priorityExitShare :: priorityExitShares =>
      shareParamsValid stakeShare priorityExitShare &&
        allModuleSharesValid stakeShares priorityExitShares
  | _, _ => false

def updateAllModuleSharesInModules : List Module → List Bps → List Bps → List Module
  | [], _, _ => []
  | m :: ms, stakeShare :: stakeShares, priorityExitShare :: priorityExitShares =>
      { m with
        stakeShareLimitBps := stakeShare,
        priorityExitShareThresholdBps := priorityExitShare } ::
        updateAllModuleSharesInModules ms stakeShares priorityExitShares
  | modules, _, _ => modules

/-!
  `SRLib._updateModuleShares` translation surface.

  The Solidity function checks that the stake-share-limit and priority-exit
  threshold arrays both match router module count, validates each row using the
  same share-ordering guard as single-module config updates, and then updates
  every module in router order. Governance authorization, calldata authorship,
  event emission, storage packing, and cast representation remain trust-boundary
  facts.
-/

def updateAllModuleSharesTransition
    (s : State) (stakeShares priorityExitShares : List Bps) : Option State :=
  if stakeShares.length = s.modules.length ∧
      priorityExitShares.length = s.modules.length then
    if allModuleSharesValid stakeShares priorityExitShares then
      some
        { s with
          modules :=
            updateAllModuleSharesInModules s.modules stakeShares priorityExitShares }
    else
      none
  else
    none

/-!
  `SRLib._getModulesAllocationAndCapacity` translation surface.

  This is the SRv3-owned loop that prepares the `allocated` and `capacities`
  arrays before the external `MinFirstAllocationStrategy` runs. The model keeps
  the finite router-order module loop and the accounting-relevant branches:

  * current allocation is active validator count for WC01-style modules;
  * current allocation is `ceil(totalModuleStake / maxEBType1)` for WC02-style
    modules;
  * inactive modules keep capacity equal to current allocation;
  * active initial-deposit capacity is bounded by current allocation plus
    depositable validators and by stake-share target;
  * active top-up capacity for WC02-style modules is bounded by active
    validators scaled by `maxEBType2 / maxEBType1` and by stake-share target.

  The external MinFirst allocation strategy, exact target-limit governance
  admissibility, storage-cache layout, and `getTotalModuleStake` truthfulness are
  explicit trust-boundary facts. The conservation targets consume only the
  checked allocation rows or a single-module allocation selected from them.
-/

def updateModuleById (moduleId : ModuleId) (f : Module → Module) :
    List Module → List Module
  | [] => []
  | m :: ms =>
      (if m.id = moduleId then f m else m) :: updateModuleById moduleId f ms

def recordModuleLastDeposit
    (moduleId : ModuleId) (depositsValue : Wei) (modules : List Module) :
    List Module :=
  updateModuleById moduleId (fun m => { m with lastDepositWei := depositsValue }) modules

def depositTransition
    (s : State) (stakingModuleId : ModuleId) (moduleAllocationWei : Wei)
    (actualDeposits : Nat) : Option State :=
  match s.modules.find? (fun m => m.id = stakingModuleId) with
  | none => none
  | some m =>
      if m.status = ModuleStatus.active then
        let maxDepositsCount := depositMaxCount m moduleAllocationWei
        if maxDepositsCount = 0 then
          none
        else if actualDeposits ≤ maxDepositsCount then
          let depositsValue := depositPullWei actualDeposits
          let modules' := recordModuleLastDeposit stakingModuleId depositsValue s.modules
          if actualDeposits = 0 then
            some { s with modules := modules' }
          else if depositPullWei actualDeposits ≤ depositableEther s then
            some
              { s with
                bufferedEther := s.bufferedEther - depositsValue,
                depositReserve := s.depositReserve - depositsValue,
                beaconDepositSinkWei := s.beaconDepositSinkWei + depositsValue,
                modules := modules' }
          else
            none
        else
          none
      else
        none

def moduleBalanceSum (modules : List Module) : Gwei :=
  (modules.map (fun m => m.validatorsBalanceGwei)).sum

def reportIds (r : List (ModuleId × Gwei)) : List ModuleId :=
  r.map Prod.fst

def moduleIds (modules : List Module) : List ModuleId :=
  modules.map Module.id

def reportBalances (r : List (ModuleId × Gwei)) : List Gwei :=
  r.map Prod.snd

def reportAligned (s : State) (r : List (ModuleId × Gwei)) : Prop :=
  reportIds r = moduleIds s.modules

def reportBalancesWithinRange (r : List (ModuleId × Gwei)) : Bool :=
  r.all (fun row => row.snd ≤ maxValueGwei)

def reportWellFormed (s : State) (r : List (ModuleId × Gwei)) : Prop :=
  r.length = s.modules.length ∧
    reportAligned s r ∧
    reportBalancesWithinRange r = true

def applyReportToModules (modules : List Module) (r : List (ModuleId × Gwei)) : List Module :=
  modules.zipWith (fun m row => { m with validatorsBalanceGwei := row.snd }) r

def acceptReport (s : State) (r : List (ModuleId × Gwei)) : State :=
  let modules' := applyReportToModules s.modules r
  { s with
    modules := modules',
    routerBalanceGwei := (reportBalances r).sum,
    lastAcceptedReport := some r }

/-!
  `SRLib._validateReportValidatorBalancesByStakingModule` and
  `SRLib._reportValidatorBalancesByStakingModule` translation surface.

  The Solidity report path first checks that both arrays cover exactly the
  current router module set, in router iteration order, and that each submitted
  Gwei amount fits the SRv3 range accepted by `_ensureAmountGwei`. Only after
  those checks does it loop over every row, write each module's
  `validatorsBalanceGwei`, accumulate `totalValidatorsBalanceGwei`, and write
  the router aggregate.

  The model keeps that validation/update split explicit. It abstracts storage
  slot plumbing and the concrete `uint64` cast, while preserving the array
  shape checks and the conservation law relating the router aggregate to the
  updated module balances.
-/

def reportValidatorBalancesTransition
    (s : State) (r : List (ModuleId × Gwei)) : Option State :=
  if r.length = s.modules.length then
    if reportIds r = moduleIds s.modules then
      if reportBalancesWithinRange r = true then
        some (acceptReport s r)
      else
        none
    else
      none
  else
    none

/-!
  `SRLib._updateExitedValidatorsCountByStakingModule` translation surface.

  The Solidity loop accepts arbitrary same-length arrays of module IDs and
  reported exited counts. For each row it requires that the module exists,
  reads the router-stored previous exited count, rejects decreases, obtains the
  staking-module deposited count through `getStakingModuleSummary`, rejects
  reports above that deposited count, accumulates the increase, and writes the
  new router-stored exited count. Duplicate module IDs, if supplied, are
  processed sequentially because each row sees the state written by earlier
  rows.

  The model keeps that sequential loop behavior. It abstracts the staking module
  summary call into the per-module `depositedValidatorsCount` field and omits
  the warning event emitted when module-internal exited totals lag the
  router-stored count.
-/

def recordModuleExitedCount
    (moduleId : ModuleId) (newExited : ValidatorsCount) (modules : List Module) :
    List Module :=
  updateModuleById moduleId (fun m => { m with exitedValidatorsCount := newExited }) modules

def exitedCountUpdateRowsValid
    (modules : List Module) : List (ModuleId × ValidatorsCount) → Prop
  | [] => True
  | (moduleId, newExited) :: rows =>
      ∃ m,
        modules.find? (fun candidate => candidate.id = moduleId) = some m ∧
          m.exitedValidatorsCount ≤ newExited ∧
          newExited ≤ m.depositedValidatorsCount ∧
          exitedCountUpdateRowsValid
            (recordModuleExitedCount moduleId newExited modules) rows

def updateExitedCountInModules
    (modules : List Module) :
    List (ModuleId × ValidatorsCount) → Option (List Module × ValidatorsCount)
  | [] => some (modules, 0)
  | (moduleId, newExited) :: rows =>
      match modules.find? (fun m => m.id = moduleId) with
      | none => none
      | some m =>
          if m.exitedValidatorsCount ≤ newExited then
            if newExited ≤ m.depositedValidatorsCount then
              let modules' := recordModuleExitedCount moduleId newExited modules
              let delta := newExited - m.exitedValidatorsCount
              match updateExitedCountInModules modules' rows with
              | none => none
              | some (finalModules, laterDelta) => some (finalModules, delta + laterDelta)
            else
              none
          else
            none

def updateExitedValidatorsTransition
    (s : State) (rows : List (ModuleId × ValidatorsCount)) :
    Option (State × ValidatorsCount) :=
  match updateExitedCountInModules s.modules rows with
  | none => none
  | some (modules', newlyExited) => some ({ s with modules := modules' }, newlyExited)

def allocationsGweiAligned (allocations : List Wei) : Bool :=
  allocations.all (fun allocation => allocation % oneGweiWei = 0)

def allocationsWithinLimits (allocations limits : List Wei) : Bool :=
  allocations.length == limits.length &&
    (allocations.zip limits).all (fun row => row.fst ≤ row.snd)

def topUpAllocationsWellFormed
    (allocations limits : List Wei) (target : Wei) : Prop :=
  allocations.length = limits.length ∧
    allocationsGweiAligned allocations = true ∧
    allocationsWithinLimits allocations limits = true ∧
    allocations.sum ≤ target

def maxTopUpPerBlockWei (maxTopUpPerBlockGwei : Gwei) : Wei :=
  maxTopUpPerBlockGwei * oneGweiWei

/--
  The effective top-up budget: the module's target-share allocation capped by
  the router-global per-block top-up limit, rounded down to Gwei. Mirrors
  `Math.min(_getModuleDepositAllocation(...), maxTopUpPerBlockWei)` followed by
  `smDepositableEthAmount - (smDepositableEthAmount % 1 gwei)`.
-/
def topUpTargetWei (moduleAllocationWei : Wei) (maxTopUpPerBlockGwei : Gwei) : Wei :=
  roundDownToGwei (min moduleAllocationWei (maxTopUpPerBlockWei maxTopUpPerBlockGwei))

/-!
  `StakingRouter.topUp` translation surface.

  The Solidity path is modeled as a router-local transition around the explicit
  `IStakingModuleV2.allocateDeposits` interface. The interface returns one
  top-up allocation per key. A successful transition preserves the Solidity
  checks that the original key/operator/limit/pubkey arrays are nonempty and
  equal-length, that the returned allocation array has the same length, that
  each allocation is Gwei-aligned and not above the corresponding top-up limit,
  and that the allocation sum does not exceed the module target capped by the
  router-global per-block Gwei limit (`maxTopUpPerBlockGwei`) and rounded down
  to Gwei.

  When the capped, rounded target is zero the Solidity path still calls the
  module to advance its deposit queue, but only if `LIDO.canDeposit()` holds;
  otherwise it reverts with `LidoDepositsPaused`. The model represents that
  Lido protocol gate as the explicit `lidoCanDeposit` interface input: a
  zero-target transition requires `lidoCanDeposit = true`. On the positive
  path, `LIDO.withdrawDepositableEther` enforcing the same protocol pause
  internally remains part of the A-LIDO-06 boundary.

  If the allocation sum is positive, `LIDO.withdrawDepositableEther` is modeled
  as making exactly that amount available to the router while subtracting the
  same amount from the Lido buffer and stored deposit reserve, and
  `BeaconChainDepositor.makeBeaconChainTopUp` is modeled as a value sink
  consuming exactly the same amount. Pubkey ownership, BLS/signature dummy data,
  deposit-data-root construction, minimum deposit enforcement inside the
  deposit contract, gateway authorization, per-block cap governance
  configuration, the `StakingRouterETHTopUp` event, calldata encoding, and
  event/revert details remain explicit trust-boundary facts.
-/

def topUpTransition
    (s : State) (stakingModuleId : ModuleId) (moduleAllocationWei : Wei)
    (maxTopUpPerBlockGwei : Gwei) (lidoCanDeposit : Bool)
    (keyCount nodeOperatorCount pubkeyCount : Nat)
    (topUpLimits allocations : List Wei) : Option State :=
  match s.modules.find? (fun m => m.id = stakingModuleId) with
  | none => none
  | some m =>
      if m.status = ModuleStatus.active then
        if m.supportsTopUp then
          if keyCount = 0 then
            none
          else if nodeOperatorCount = keyCount then
            if topUpLimits.length = keyCount then
              if pubkeyCount = keyCount then
                if allocations.length = keyCount then
                  let target := topUpTargetWei moduleAllocationWei maxTopUpPerBlockGwei
                  if target = 0 ∧ lidoCanDeposit = false then
                    none
                  else if allocationsGweiAligned allocations then
                    if allocationsWithinLimits allocations topUpLimits then
                      let amount := allocations.sum
                      if amount ≤ target then
                        if amount = 0 then
                          some s
                        else if amount ≤ depositableEther s then
                          some
                            { s with
                              bufferedEther := s.bufferedEther - amount,
                              depositReserve := s.depositReserve - amount,
                              beaconDepositSinkWei := s.beaconDepositSinkWei + amount }
                        else
                          none
                      else
                        none
                    else
                      none
                  else
                    none
                else
                  none
              else
                none
            else
              none
          else
            none
        else
          none
      else
        none

/-!
  `StakingRouter.getStakingRewardsDistribution` translation surface.

  The Solidity implementation uses the current router total validators balance.
  If that total is zero it returns empty arrays with `FEE_PRECISION_POINTS`.
  Otherwise it loops over modules in router order, skips zero-balance modules,
  writes the module ID and module address recipient for each rewarded row,
  computes module and treasury fee points from the module balance share, writes
  module fee points only when the module is not stopped, and accumulates total
  fee as `treasuryFee + moduleFee` even for stopped modules.

  This model preserves the accounting-relevant loop shape and abstracts memory
  array preallocation/shrinking, address typing, the `uint96` casts, and the
  final Solidity `assert(totalFee <= precisionPoints)` into explicit arithmetic
  assumptions.
-/

def rewardShare (totalValidatorsBalanceGwei : Gwei) (m : Module) : Nat :=
  m.validatorsBalanceGwei * feePrecisionPoints / totalValidatorsBalanceGwei

def computedModuleFee (totalValidatorsBalanceGwei : Gwei) (m : Module) : Nat :=
  rewardShare totalValidatorsBalanceGwei m * m.moduleFeeBps / bpsDenominator

def computedTreasuryFee (totalValidatorsBalanceGwei : Gwei) (m : Module) : Nat :=
  rewardShare totalValidatorsBalanceGwei m * m.treasuryFeeBps / bpsDenominator

def rewardDistributionRow (totalValidatorsBalanceGwei : Gwei) (m : Module) :
    RewardDistributionRow :=
  let moduleFee := computedModuleFee totalValidatorsBalanceGwei m
  let treasuryFee := computedTreasuryFee totalValidatorsBalanceGwei m
  { moduleId := m.id,
    recipient := m.rewardRecipient,
    validatorsBalanceGwei := m.validatorsBalanceGwei,
    moduleFee := moduleFee,
    treasuryFee := treasuryFee,
    paidModuleFee := if m.status = ModuleStatus.stopped then 0 else moduleFee }

def rewardDistributionLoop (totalValidatorsBalanceGwei : Gwei) :
    List Module → List RewardDistributionRow
  | [] => []
  | m :: ms =>
      if m.validatorsBalanceGwei = 0 then
        rewardDistributionLoop totalValidatorsBalanceGwei ms
      else
        rewardDistributionRow totalValidatorsBalanceGwei m ::
          rewardDistributionLoop totalValidatorsBalanceGwei ms

def stakingRewardsDistributionRows (modules : List Module) :
    List RewardDistributionRow :=
  let totalValidatorsBalanceGwei := moduleBalanceSum modules
  if totalValidatorsBalanceGwei = 0 then
    []
  else
    rewardDistributionLoop totalValidatorsBalanceGwei modules

def rewardDistributionTotalFee (rows : List RewardDistributionRow) : Nat :=
  (rows.map (fun row => row.moduleFee + row.treasuryFee)).sum

def rewardMintedReportRows (stakingModuleIds totalShares : List Nat) :
    List RewardMintedReportRow :=
  (stakingModuleIds.zip totalShares).map
    (fun row => { moduleId := row.fst, totalShares := row.snd })

def rewardMintedRowsValid
    (modules : List Module) : List RewardMintedReportRow → Bool
  | [] => true
  | row :: rows =>
      (row.totalShares == 0 || moduleExists modules row.moduleId) &&
        rewardMintedRowsValid modules rows

/-!
  `SRLib._reportRewardsMinted` translation surface.

  The Solidity loop first checks that `_stakingModuleIds` and `_totalShares`
  have the same length, then skips zero-share rows before requiring that each
  nonzero row names an existing staking module. The external
  `IStakingModule.onRewardsMinted` callback, low-level revert bytes, event
  emission, and gas-estimation behavior are kept outside this economic model.
-/

def reportRewardsMintedTransition
    (s : State) (stakingModuleIds totalShares : List Nat) :
    Option (List RewardMintedReportRow) :=
  if totalShares.length = stakingModuleIds.length then
    let rows := rewardMintedReportRows stakingModuleIds totalShares
    if rewardMintedRowsValid s.modules rows then
      some rows
    else
      none
  else
    none

def rewardRecipientsAligned (modules : List Module) : Prop :=
  ∀ row ∈ stakingRewardsDistributionRows modules,
    ∃ m ∈ modules, row.recipient = m.rewardRecipient

def rewardsUseAcceptedReport (s : State) : Prop :=
  ∃ r, s.lastAcceptedReport = some r ∧ reportBalances r = s.modules.map Module.validatorsBalanceGwei

end LidoSRv3
