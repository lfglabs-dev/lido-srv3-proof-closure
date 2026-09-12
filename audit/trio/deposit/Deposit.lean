import LidoSRv3.Audit.Source.TrioComposition.ParentABI
import LidoSRv3.Audit.Source.TrioAlloc1.ShareWriter
import LidoSRv3.Audit.Source.DepositDataRootCorrespondence

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
/-- `BeaconChainDepositor.DEPOSIT_SIZE` at the pinned source line 24. -/
def DEPOSIT_SIZE : Nat := thirtyTwoEtherWei
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
  publicKeysBatch : TrioAlloc1.Bytes
  signaturesBatch : TrioAlloc1.Bytes
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
  moduleId : Word
  maxEBType1 : Word
  moduleData : ModuleDepositData
  values : DepositValues
  withdrawal : Option WithdrawalArguments
  deriving DecidableEq, Repr

/-- The values produced by the allocation and staking-module prefix, before
the source reaches the conditional Lido withdrawal.  This is an intermediate
value of an executor, not evidence supplied to the router suffix. -/
structure PreparedDeposit where
  moduleId : Word
  maxEBType1 : Word
  moduleData : ModuleDepositData
  values : DepositValues
  deriving DecidableEq, Repr

def composeValues (selected : Word) (config : TrioAlloc1.Config)
    (actualKeys depositSize : Nat) : DepositValues :=
  { selectedAllocationWei := selected.val
    actualKeys := actualKeys
    lidoPullWei := actualKeys * config.maxEBType1.val
    beaconPerKeyWei := depositSize
    beaconTotalWei := actualKeys * depositSize }

/-- Solidity 0.8 checked multiplication, retaining the mathematical value on
success instead of silently reducing it modulo `2^256`. -/
def checkedMulNat (a b : Nat) : Option Nat :=
  if a * b < 2 ^ 256 then some (a * b) else none

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
  | arithmeticOverflow
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

/-- Execute the pinned allocation/module prefix through the checked
`depositsValue` multiplication.  The caller must continue directly with the
conditional Lido call; no withdrawal result is accepted at this boundary. -/
def prepareDepositABI
    (layout : TrioAlloc1.Layout) (storage : TrioAlloc1.Storage)
    (oracle : TrioAlloc1.StaticOracle) (config : TrioAlloc1.Config)
    (amount : Word) (before : TrioAlloc1.Transcript) (moduleId : Word)
    (limits : DepositLimits) (obtainDepositData : ObtainDepositData)
    (depositSize : Nat) :
    Except DepositFailure PreparedDeposit × TrioAlloc1.Transcript :=
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
            if moduleData.publicKeysBatch.length % pubkeyLength ≠ 0 then
              (.error .wrongPubkeyLength, after)
            else
              let actualKeys := moduleData.publicKeysBatch.length / pubkeyLength
              if actualKeys > target then (.error .moduleReturnExceedTarget, after)
              else if actualKeys * config.maxEBType1.val ≥ 2 ^ 256 then
                (.error .arithmeticOverflow, after)
              else
                let values := composeValues selected config actualKeys depositSize
                (.ok ⟨moduleId, config.maxEBType1, moduleData, values⟩, after)

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
            if moduleData.publicKeysBatch.length % pubkeyLength ≠ 0 then
              (.error .wrongPubkeyLength, after)
            else
              let actualKeys := moduleData.publicKeysBatch.length / pubkeyLength
              if actualKeys > target then (.error .moduleReturnExceedTarget, after)
              else
                if actualKeys * config.maxEBType1.val ≥ 2 ^ 256 then
                  (.error .arithmeticOverflow, after)
                else
                  let values := composeValues selected config actualKeys depositSize
                  match conditionalWithdrawal values withdraw with
                  | .error reason => (.error reason, after)
                  | .ok withdrawal =>
                    (.ok ⟨moduleId, config.maxEBType1, moduleData, values, withdrawal⟩, after)

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
      execution.values.beaconTotalWei = execution.values.actualKeys * depositSize ∧
      execution.values.lidoPullWei < 2 ^ 256 ∧
      execution.values.actualKeys < 2 ^ 256 := by
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
                  split at executed <;> try simp_all
                  next withinTarget =>
                    split at executed <;> try simp_all
                    next productFits =>
                      rcases executed with ⟨rfl, rfl⟩
                      refine ⟨?_, ?_, withinTarget, ?_⟩
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
                      · have maxPositive : 0 < config.maxEBType1.val := by
                          by_cases h : config.maxEBType1 = 0
                          · simp [h] at nonzero
                          · exact Nat.pos_of_ne_zero (by
                              intro hz
                              apply h
                              exact Fin.ext hz)
                        exact lt_of_le_of_lt (Nat.le_mul_of_pos_right _ maxPositive) withinTarget

#print axioms abi_success_composes_deposit_values

/-- A successful `prepareDepositABI` prefix composes beacon charges from the
literal `depositSize` argument (`composeValues`), not from ALLOC. Instantiating
`depositSize` with pinned `DEPOSIT_SIZE` yields `perKey = DEPOSIT_SIZE` and
`total = actualKeys * DEPOSIT_SIZE`. The returned-key count is the aligned
public-key batch length, and the Lido pull is the checked product with the
configured `maxEBType1`, which the executed division guard keeps nonzero. -/
theorem prepareDepositABI_composes_beacon_values
    (layout : TrioAlloc1.Layout) (storage : TrioAlloc1.Storage)
    (oracle : TrioAlloc1.StaticOracle) (config : TrioAlloc1.Config)
    (amount : Word) (before after : TrioAlloc1.Transcript)
    (moduleId : Word) (limits : DepositLimits)
    (obtainDepositData : ObtainDepositData) (depositSize : Nat)
    (prepared : PreparedDeposit)
    (executed : prepareDepositABI layout storage oracle config amount before moduleId
      limits obtainDepositData depositSize = (.ok prepared, after)) :
    prepared.values.beaconPerKeyWei = depositSize ∧
      prepared.values.beaconTotalWei = prepared.values.actualKeys * depositSize ∧
      prepared.moduleData.publicKeysBatch.length =
        prepared.values.actualKeys * pubkeyLength ∧
      prepared.values.lidoPullWei = prepared.values.actualKeys * config.maxEBType1.val ∧
      prepared.values.lidoPullWei < 2 ^ 256 ∧
      prepared.maxEBType1 = config.maxEBType1 ∧
      prepared.moduleId = moduleId ∧
      0 < config.maxEBType1.val := by
  unfold prepareDepositABI at executed
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
                  split at executed <;> try simp_all
                  next withinTarget =>
                    obtain ⟨rfl, rfl⟩ := executed
                    have maxPositive : 0 < config.maxEBType1.val := by
                      by_cases h : config.maxEBType1 = 0
                      · simp [h] at nonzero
                      · exact Nat.pos_of_ne_zero (fun hz => h (Fin.ext hz))
                    refine ⟨rfl, rfl, ?_, rfl, withinTarget, rfl, rfl, maxPositive⟩
                    exact (Nat.div_mul_cancel (Nat.dvd_of_mod_eq_zero moduleEq)).symm

#print axioms prepareDepositABI_composes_beacon_values
end audit.trio.deposit
