import LidoSRv3.Audit.Source.TrioComposition.ParentABI

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

/-- Deposit data independently returned by the selected staking module. -/
structure ModuleDepositData where
  actualKeys : Nat
  deriving DecidableEq, Repr

/-- Source-shaped values at the ALLOC/deposit join. -/
structure DepositValues where
  selectedAllocationWei : Nat
  actualKeys : Nat
  lidoPullWei : Nat
  beaconPerKeyWei : Nat
  beaconTotalWei : Nat
  deriving DecidableEq, Repr

def composeValues (selected : Word) (config : TrioAlloc1.Config)
    (moduleData : ModuleDepositData) (depositSize : Nat) : DepositValues :=
  { selectedAllocationWei := selected.val
    actualKeys := moduleData.actualKeys
    lidoPullWei := moduleData.actualKeys * config.maxEBType1.val
    beaconPerKeyWei := depositSize
    beaconTotalWei := moduleData.actualKeys * depositSize }

/-- A data-carrying selection from the ALLOC router-order output. -/
structure SelectedAllocation (allocation : ParentOutput) (moduleIndex : Nat) where
  selected : Word
  selected_eq : allocation.allocated[moduleIndex]? = some selected

/-- Residual source link. ALLOC supplies the selected maximum; the later module
call independently supplies `actualKeys`. No post-state conclusion is assumed. -/
structure LinksSource (config : TrioAlloc1.Config) (moduleData : ModuleDepositData)
    (selection : SelectedAllocation allocation moduleIndex) : Prop where
  nonzeroUnit : config.maxEBType1.val ≠ 0
  moduleReturnWithinTarget :
    moduleData.actualKeys ≤ selection.selected.val / config.maxEBType1.val

theorem linked_values (allocation : ParentOutput) (config : TrioAlloc1.Config)
    (moduleIndex : Nat) (moduleData : ModuleDepositData) (depositSize : Nat)
    (selection : SelectedAllocation allocation moduleIndex)
    (_link : LinksSource config moduleData selection) :
    let values := composeValues selection.selected config moduleData depositSize
    values.selectedAllocationWei = selection.selected.val ∧
      values.actualKeys = moduleData.actualKeys ∧
      values.lidoPullWei = moduleData.actualKeys * config.maxEBType1.val ∧
      values.beaconPerKeyWei = depositSize ∧
      values.beaconTotalWei = moduleData.actualKeys * depositSize := by
  simp [composeValues]

/-- Consume the accepted ABI success without strengthening it. The module-key
link remains caller-supplied because the module call occurs afterwards. -/
theorem abi_success_composes_deposit_values
    (layout : TrioAlloc1.Layout) (storage : TrioAlloc1.Storage)
    (oracle : TrioAlloc1.StaticOracle) (config : TrioAlloc1.Config)
    (amount : Word) (before after : TrioAlloc1.Transcript)
    (allocation : ParentOutput) (moduleIndex : Nat)
    (moduleData : ModuleDepositData) (depositSize : Nat)
    (_executed : getDepositAllocationsABI layout storage oracle config amount false before =
      (.ok allocation, after))
    (selection : SelectedAllocation allocation moduleIndex)
    (_link : LinksSource config moduleData selection) :
    (composeValues selection.selected config moduleData depositSize).lidoPullWei =
        moduleData.actualKeys * config.maxEBType1.val ∧
      (composeValues selection.selected config moduleData depositSize).beaconTotalWei =
        moduleData.actualKeys * depositSize := by
  simp [composeValues]

end audit.trio.deposit
