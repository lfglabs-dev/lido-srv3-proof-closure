import ReportWriteFee

/-! Kernel-checked vectors for the physical ACCOUNT slice at pin 17005714. -/

-- Core `Except` has no decidable equality; kernel `decide` needs one.
deriving instance DecidableEq for Except

namespace AccountAddress.Tests.Verity.ReportWriteFeeTest

open AccountAddress.PAccount1 AccountAddress.ReportWriteFee

/-- Concrete stand-in for the keccak-derived layout: four words per module,
six for the router struct. -/
def layout : Layout := ⟨1000, fun id => 2000 + 16 * id⟩

def registered : List Nat := [1, 4]

theorem layout_separated : layout.Separated registered := ⟨by decide, by decide⟩

/-- Active module at address 170, 5%/5% fees, limits 100%, wc type 1. -/
def cfgActive : StorageWord :=
  ⟨6905860170954932047623353801283588218236670836378154544886775384375466, by decide⟩

/-- Same as `cfgActive` at address 187 with status Stopped (2). -/
def cfgStopped : StorageWord :=
  ⟨6959780064289233327212687831457627479583945125223235689848982604873915, by decide⟩

/-- Exited counts 7 / 9 sit above the balances 4 / 5; the router word carries 11
above the total 6. -/
def before : Core :=
  { slots := [(layout.moduleConfigSlot 1, cfgActive),
      (layout.moduleAccountingSlot 1, ⟨7 * two64 + 4, by decide⟩),
      (layout.moduleConfigSlot 4, cfgStopped),
      (layout.moduleAccountingSlot 4, ⟨9 * two64 + 5, by decide⟩),
      (layout.routerAccountingSlot, ⟨11 * two64 + 6, by decide⟩)] }

def afterReport : ReportOutcome :=
  reportValidatorBalances layout registered [1, 4] [20, 30] before

def postCore : Core :=
  match afterReport with
  | .committed post => post
  | .reverted _ rollback => rollback

example : (match afterReport with
    | .committed _ => true
    | .reverted _ _ => false) = true := by decide

/-- SRLib 886/891: low uint64 rewritten, exited counts and router tail kept. -/
example : (postCore.read (layout.moduleAccountingSlot 1)).val = 7 * two64 + 20 := by decide
example : (postCore.read (layout.moduleAccountingSlot 4)).val = 9 * two64 + 30 := by decide
example : (postCore.read layout.routerAccountingSlot).val = 11 * two64 + 50 := by decide

/-- Config words are outside the report's write set. -/
example : postCore.read (layout.moduleConfigSlot 1) = cfgActive := by decide
example : postCore.read (layout.moduleConfigSlot 4) = cfgStopped := by decide

/-- StakingRouter 808-873 on the words the report wrote: shares 4e19 / 6e19 of
1e20, fees 2e18 / 3e18 each; the Stopped module records no module fee but its
4e18 still enters the total. -/
example : getStakingRewardsDistribution layout registered postCore =
    .ok ⟨[170, 187], [1, 4], [2000000000000000000, 0], 10000000000000000000,
      FEE_PRECISION_POINTS⟩ := by decide

/-- 839: an unregistered-looking id with a zero word is skipped, arrays shrink. -/
example : getStakingRewardsDistribution layout [1, 4, 7] postCore =
    .ok ⟨[170, 187], [1, 4], [2000000000000000000, 0], 10000000000000000000,
      FEE_PRECISION_POINTS⟩ := by decide

/-- 820, 828-829: zero router total is the empty success even with modules. -/
example : getStakingRewardsDistribution layout registered
    (before.write layout.routerAccountingSlot ⟨11 * two64, by decide⟩) =
    .ok ⟨[], [], [], 0, FEE_PRECISION_POINTS⟩ := by decide

/-- `cfgActive` with status byte 3, outside the three-member enum. -/
def cfgStatus3 : StorageWord :=
  ⟨6986740010956383967007354846544647110257582269645776262330086215123114, by decide⟩

example : cfgStatus3.val = cfgActive.val + 3 * two224 := by decide

/-- 843: an out-of-range status byte is a panic, not a treasury payout. -/
example : getStakingRewardsDistribution layout registered
    (postCore.write (layout.moduleConfigSlot 1) cfgStatus3) =
    .error (.statusOutOfRange 1 3) := by decide

/-- 862: 655.35% + 655.35% fee weights on a full-allocation module fail the cap. -/
def cfgMax : StorageWord := ⟨170 + 65535 * two160 + 65535 * two176, by decide⟩

example : getStakingRewardsDistribution layout [1]
    { slots := [(layout.moduleConfigSlot 1, cfgMax),
        (layout.moduleAccountingSlot 1, ⟨20, by decide⟩),
        (layout.routerAccountingSlot, ⟨20, by decide⟩)] } =
    .error .totalFeeAboveCap := by decide

/-- 892: the uint96 cast is load-bearing on inconsistent storage (module word
above the router total); on report-consistent words see the HOLD in README. -/
example : two96 ≤ (two64 - 1) * 1000000000 * FEE_PRECISION_POINTS / 1000000000 * 65535 /
    TOTAL_BASIS_POINTS := by decide

example : (computeModuleFee ((two64 - 1) * 1000000000) 1000000000 ⟨170, 65535, 65535, 0⟩).moduleFee =
    44642003085559411534374961152 := by decide

/-- SRLib 853-870 errors roll the physical storage back. -/
example : reportValidatorBalances layout registered [1, 4] [20, maxValueGwei + 1] before =
    .reverted (.invalidAmountGwei (maxValueGwei + 1)) before := by decide

example : reportValidatorBalances layout registered [1, 5] [20, 30] before =
    .reverted (.unexpectedModuleId 4 5) before := by decide

example : reportValidatorBalances layout registered [1] [20] before =
    .reverted .arraysLengthMismatch before := by decide

/-- Accounting 265-358 on the same words: 100 ETH of rewards at 10% total fee
gives 10 ETH of fee ether; 5025125628140703517 shares split 1/5 to the active
module, nothing to the Stopped module, remainder to treasury. -/
def report : ReportWei :=
  ⟨1000 * 10 ^ 18, 0, 0, 900 * 10 ^ 18, 0, 2000 * 10 ^ 18, 1000 * 10 ^ 18⟩

example : calculateProtocolFees layout registered postCore report =
    .ok ⟨5025125628140703517, [170, 187], [1, 4], [1005025125628140703, 0],
      4020100502512562814⟩ := by decide

/-- 322: a non-profitable report mints nothing and returns empty distribution. -/
example : calculateProtocolFees layout registered postCore
    { report with principalClBalance := 1000 * 10 ^ 18 } =
    .ok ⟨0, [], [], [], 0⟩ := by decide

/-- 331: fee ether above post ether is the checked-subtraction panic. -/
example : calculateProtocolFees layout registered postCore
    { report with postInternalEther := 1 } =
    .error (.feeExceedsPostEther 10000000000000000000 1) := by decide

end AccountAddress.Tests.Verity.ReportWriteFeeTest
