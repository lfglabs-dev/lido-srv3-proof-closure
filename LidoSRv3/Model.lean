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

def oneEthWei : Wei := 1000000000000000000
def validatorDepositWei : Wei := 32 * oneEthWei
def bpsDenominator : Nat := 10000

inductive ModuleStatus
  | active
  | depositsPaused
  | stopped
  | inactive
  deriving DecidableEq, Repr

structure Module where
  id : ModuleId
  status : ModuleStatus
  validatorsBalanceGwei : Gwei
  moduleFeeBps : Bps
  rewardRecipient : Address
  deriving Repr

structure State where
  bufferedEther : Wei
  depositReserve : Wei
  withdrawalReserve : Wei
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

def allocatedDeposits (_s : State) (m : Module) (count : Nat) : Nat :=
  if m.status = ModuleStatus.active then count else 0

def totalAllocatedDeposits (s : State) (count : Nat) : Nat :=
  (s.modules.map (fun m => allocatedDeposits s m count)).sum

def depositPullWei (actualDeposits : Nat) : Wei :=
  validatorDepositWei * actualDeposits

def depositAllowed (s : State) (actualDeposits : Nat) : Prop :=
  depositPullWei actualDeposits ≤ depositableEther s

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

def applyReportToModules (modules : List Module) (r : List (ModuleId × Gwei)) : List Module :=
  modules.zipWith (fun m row => { m with validatorsBalanceGwei := row.snd }) r

def acceptReport (s : State) (r : List (ModuleId × Gwei)) : State :=
  let modules' := applyReportToModules s.modules r
  { s with
    modules := modules',
    routerBalanceGwei := (reportBalances r).sum,
    lastAcceptedReport := some r }

def moduleRewardUpperBound (totalReward : Wei) (m : Module) : Wei :=
  totalReward * m.moduleFeeBps / bpsDenominator

def moduleReward (totalReward : Wei) (m : Module) : Wei :=
  if m.status ≠ ModuleStatus.stopped then moduleRewardUpperBound totalReward m else 0

def rewardRows (totalReward : Wei) (modules : List Module) : List (ModuleId × Address × Wei) :=
  modules.map (fun m => (m.id, m.rewardRecipient, moduleReward totalReward m))

def recipientsAligned (totalReward : Wei) (modules : List Module) : Prop :=
  ∀ row ∈ rewardRows totalReward modules,
    ∃ m ∈ modules,
      row = (m.id, m.rewardRecipient, moduleReward totalReward m)

def rewardsUseAcceptedReport (s : State) : Prop :=
  ∃ r, s.lastAcceptedReport = some r ∧ reportBalances r = s.modules.map Module.validatorsBalanceGwei

end LidoSRv3
