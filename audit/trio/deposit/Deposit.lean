import LidoSRv3.Audit.Source.TrioComposition.ParentABI
import LidoSRv3.Audit.Source.TrioAlloc1.ShareWriter

/-! First DEPOSIT-1 composition slice over the accepted ALLOC-1/ALLOC-2 ABI.
Pinned source: lidofinance/core@17005714f151e5502c559932319a3f2f74ac2436,
StakingRouter.sol:88-106,952-972 and BeaconChainDepositor.sol:24,53-57.
No compiler-memory, deployed-bytecode, or deployment identity is claimed. -/
namespace audit.trio.deposit

open LidoSRv3.Audit.Source
open TrioAlloc1 TrioComposition

abbrev Word := TrioAlloc1.Word
abbrev Address := TrioAlloc1.Address
def thirtyTwoEtherWei : Nat := 32 * 10 ^ 18
def canonicalDepositContract : Address :=
  ⟨0x00000000219ab540356cBB839Cbe05303d7705Fa, by native_decide⟩

/-- Values admitted by the pinned constructor source. This identifies no
deployed router or creation transaction. -/
structure ConstructorInputs where
  depositContract : Address
  maxEBType1 : Word
  deriving DecidableEq, Repr

def PinnedConstructorAdmitted (inputs : ConstructorInputs) : Prop :=
  inputs.depositContract.val ≠ 0 ∧ inputs.maxEBType1.val ≠ 0

/-- Deployment/artifact identities deliberately not derived from source. -/
structure ArtifactAssumptions (constructor : ConstructorInputs) : Prop where
  A_DEPOSIT_CONTRACT : constructor.depositContract = canonicalDepositContract
  A_DEPOSIT_32_ETHER : constructor.maxEBType1.val = thirtyTwoEtherWei

def openConstructorCounterexample : ConstructorInputs :=
  { depositContract := ⟨0xDEAD, by native_decide⟩
    maxEBType1 := ⟨64 * 10 ^ 18, by native_decide⟩ }

theorem pinned_constructor_does_not_discharge_artifact_identities :
    PinnedConstructorAdmitted openConstructorCounterexample ∧
      ¬ ArtifactAssumptions openConstructorCounterexample := by
  constructor
  · change (0xDEAD : Nat) ≠ 0 ∧ 64 * 10 ^ 18 ≠ 0
    omega
  · intro h
    have wrong : openConstructorCounterexample.depositContract ≠
        canonicalDepositContract := by native_decide
    exact wrong h.A_DEPOSIT_CONTRACT

/-- Deposit data independently returned by the selected staking module.  The
key count is deliberately not stored: the deposit entry point derives it from
the returned byte length after the 48-byte alignment guard. -/
structure ModuleDepositData where
  publicKeysBatchLength : Nat
  deriving DecidableEq, Repr

/-- Named per-module limit read by `StakingRouter.deposit` before the call. -/
structure DepositLimits where
  maxDepositsPerBlock : Nat
  deriving DecidableEq, Repr

/-- `StakingRouter.PUBKEY_LENGTH`, pinned at source line 57. -/
def pubkeyLength : Nat := 48

/-- Executable boundary for `IStakingModule.obtainDepositData(target, data)`.
The argument is the actual `maxDepositsCount` sent by the router. -/
abbrev ObtainDepositData := Nat → Except Failure ModuleDepositData

/-- Source-shaped values at the ALLOC/deposit join. -/
structure DepositValues where
  selectedAllocationWei : Nat
  actualKeys : Nat
  lidoPullWei : Nat
  beaconPerKeyWei : Nat
  beaconTotalWei : Nat
  deriving DecidableEq, Repr

/-- The exact arguments of `Lido.withdrawDepositableEther`.  In particular,
`seedDepositsCount` is not an independently chosen word: on the nonempty
branch it is the count derived from the module's returned public-key bytes. -/
structure WithdrawalArguments where
  amount : Word
  seedDepositsCount : Word
  deriving DecidableEq, Repr

/-- The Lido call boundary used by this slice.  The interface deliberately
returns a failure rather than assuming that the downstream withdrawal works. -/
abbrev WithdrawDepositableEther := Word → Word → Except Failure Unit

/-- A successful deposit entry either returned at StakingRouter.sol:978 without
calling Lido, or made the source-shaped Lido call and records its exact ABI
arguments. -/
structure DepositExecution where
  values : DepositValues
  withdrawal : Option WithdrawalArguments
  deriving DecidableEq, Repr

def composeValues (selected : Word) (config : TrioAlloc1.Config)
    (actualKeys depositSize : Nat) : DepositValues :=
  { selectedAllocationWei := selected.val
    actualKeys := actualKeys
    lidoPullWei := actualKeys * config.maxEBType1.val
    beaconPerKeyWei := depositSize
    beaconTotalWei := actualKeys * depositSize }

/-- `SRUtils._getModuleIndexById`: load the one-based inner position and
subtract one with Solidity checked arithmetic. -/
def getModuleIndexById (layout : TrioAlloc1.Layout) (storage : TrioAlloc1.Storage)
    (moduleId : Word) : Except Failure Word :=
  checkedSub (storage (TrioAlloc1.ShareWriter.modulePositionSlot layout moduleId)).val 1

/-- A data-carrying selection from the ALLOC router-order output. -/
structure SelectedAllocation (layout : TrioAlloc1.Layout) (storage : TrioAlloc1.Storage)
    (allocation : ParentOutput) (moduleId : Word) where
  moduleIndex : Word
  moduleIndex_eq : getModuleIndexById layout storage moduleId = .ok moduleIndex
  selected : Word
  selected_eq : allocation.allocated[moduleIndex.val]? = some selected

/-- Deposit-specific failures after the accepted ALLOC parent. -/
inductive DepositFailure where
  | allocation (reason : Failure)
  | moduleIndex (reason : Failure)
  | allocationIndexOutOfBounds
  | divisionByZero
  | zeroDeposits
  | moduleCall (reason : Failure)
  | wrongPubkeyLength
  | moduleReturnExceedTarget
  | lidoWithdrawal (reason : Failure)
  deriving DecidableEq, Repr

/-- `StakingRouter.sol:978` is before the Lido call at line 983.  Therefore an
empty result from `obtainDepositData` returns without a zero-value withdrawal;
otherwise both withdrawal arguments are derived from `actualKeys`. -/
def conditionalWithdrawal (values : DepositValues) (withdraw : WithdrawDepositableEther) :
    Except DepositFailure (Option WithdrawalArguments) :=
  if values.actualKeys = 0 then .ok none
  else
    let args : WithdrawalArguments :=
      ⟨word values.lidoPullWei, word values.actualKeys⟩
    match withdraw args.amount args.seedDepositsCount with
    | .ok () => .ok (some args)
    | .error reason => .error (.lidoWithdrawal reason)

def maxDepositsCount (limits : DepositLimits) (selected : Word)
    (config : TrioAlloc1.Config) : Except DepositFailure Nat :=
  if config.maxEBType1.val = 0 then .error .divisionByZero
  else .ok (min limits.maxDepositsPerBlock
    (selected.val / config.maxEBType1.val))

/-- Source-ordered execution through the module-return guard.  In particular,
this function executes both the delivered ALLOC ABI and `obtainDepositData`;
successful `DepositValues` are not assembled from an assumed link. -/
def depositValuesABI
    (layout : TrioAlloc1.Layout) (storage : TrioAlloc1.Storage)
    (oracle : TrioAlloc1.StaticOracle) (config : TrioAlloc1.Config)
    (amount : Word) (before : TrioAlloc1.Transcript) (moduleId : Word)
    (limits : DepositLimits) (obtainDepositData : ObtainDepositData)
    (depositSize : Nat) (withdraw : WithdrawDepositableEther) :
    Except DepositFailure DepositExecution × TrioAlloc1.Transcript :=
  match getDepositAllocationsABI layout storage oracle config amount false before with
  | (.error reason, after) => (.error (.allocation reason), after)
  | (.ok allocation, after) =>
    match getModuleIndexById layout storage moduleId with
    | .error reason => (.error (.moduleIndex reason), after)
    | .ok moduleIndex =>
      match allocation.allocated[moduleIndex.val]? with
      | none => (.error .allocationIndexOutOfBounds, after)
      | some selected =>
        match maxDepositsCount limits selected config with
        | .error reason => (.error reason, after)
        | .ok target =>
          if target = 0 then (.error .zeroDeposits, after)
          else match obtainDepositData target with
          | .error reason => (.error (.moduleCall reason), after)
          | .ok moduleData =>
            if moduleData.publicKeysBatchLength % pubkeyLength ≠ 0 then
              (.error .wrongPubkeyLength, after)
            else
              let actualKeys := moduleData.publicKeysBatchLength / pubkeyLength
              if actualKeys > target then (.error .moduleReturnExceedTarget, after)
              else
                let values := composeValues selected config actualKeys depositSize
                match conditionalWithdrawal values withdraw with
                | .error reason => (.error reason, after)
                | .ok withdrawal => (.ok ⟨values, withdrawal⟩, after)

/-- A successful execution derives the pull bound from the source cap and the
post-call over-target guard. -/
theorem abi_success_composes_deposit_values
    (layout : TrioAlloc1.Layout) (storage : TrioAlloc1.Storage)
    (oracle : TrioAlloc1.StaticOracle) (config : TrioAlloc1.Config)
    (amount : Word) (before after : TrioAlloc1.Transcript)
    (moduleId : Word) (limits : DepositLimits)
    (obtainDepositData : ObtainDepositData) (depositSize : Nat)
    (withdraw : WithdrawDepositableEther)
    (execution : DepositExecution)
    (executed : depositValuesABI layout storage oracle config amount before moduleId
      limits obtainDepositData depositSize withdraw = (.ok execution, after)) :
    execution.values.lidoPullWei ≤ execution.values.selectedAllocationWei ∧
      execution.values.beaconTotalWei = execution.values.actualKeys * depositSize := by
  unfold depositValuesABI at executed
  split at executed <;> try simp_all
  next allocation allocAfter allocEq =>
    split at executed <;> try simp_all
    next moduleIndex indexEq =>
      split at executed <;> try simp_all
      next selected selectedEq =>
        unfold maxDepositsCount at executed
        split at executed <;> try simp_all
        next nonzero =>
          split at executed <;> try simp_all
          next target targetEq =>
            split at executed <;> try simp_all
            next nonzeroTarget =>
              split at executed <;> try simp_all
              next moduleData moduleEq =>
                split at executed <;> try simp_all
                next aligned =>
                  unfold conditionalWithdrawal at executed
                  split at executed <;> simp_all
                  next emptyKeys =>
                    rcases executed with ⟨rfl, rfl⟩
                    constructor
                    · dsimp [composeValues]
                      have targetBound : target ≤ selected.val / config.maxEBType1.val := by
                        by_cases unitZero : config.maxEBType1 = 0
                        · simp [unitZero] at nonzero
                        · simp [unitZero] at nonzero
                          rw [← nonzero]
                          exact Nat.min_le_right _ _
                      apply Nat.le_trans
                        (Nat.mul_le_mul_right config.maxEBType1.val
                          (Nat.le_trans aligned targetBound))
                      exact Nat.div_mul_le_self selected.val config.maxEBType1.val
                    · simp [composeValues]
                  next nonemptyKeys args withdrawalEq =>
                    split at executed <;> simp_all
                    next withdrawalFailure => cases executed
                    next withdrawalSuccess =>
                      rcases executed with ⟨rfl, rfl⟩
                      constructor
                      · dsimp [composeValues]
                        have targetBound : target ≤ selected.val / config.maxEBType1.val := by
                          by_cases unitZero : config.maxEBType1 = 0
                          · simp [unitZero] at nonzero
                          · simp [unitZero] at nonzero
                            rw [← nonzero]
                            exact Nat.min_le_right _ _
                        apply Nat.le_trans
                          (Nat.mul_le_mul_right config.maxEBType1.val
                            (Nat.le_trans aligned targetBound))
                        exact Nat.div_mul_le_self selected.val config.maxEBType1.val
                      · simp [composeValues]

#print axioms abi_success_composes_deposit_values
end audit.trio.deposit
