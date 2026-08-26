import LidoSRv3.Audit.Guarantees.PDeposit1
import LidoSRv3.Audit.Source.DepositCorrespondence

/-!
# G-DEPOSIT model-side provenance pins

These equalities pin `PDeposit1` literals to the production beacon-deposit
address and to 32 ether. They do **not** discharge `A-DEPOSIT-CONTRACT` or
`A-DEPOSIT-32-ETHER`. Those assumptions require a deployed-immutable identity
check against artifacts this repository does not contain.
-/

namespace LidoSRv3.Audit.Provenance.Deposit

open LidoSRv3.Audit.SolidityDeposit
open LidoSRv3.Audit.Guarantees

/-- Production Ethereum beacon deposit contract. Model pin only. -/
abbrev productionBeaconDeposit : Nat :=
  0x00000000219ab540356cBB839Cbe05303d7705Fa

/-- 32 ether in wei. Model pin only; not a deployment proof. -/
abbrev thirtyTwoEtherWei : Nat := 32 * 10 ^ 18

/-- The P-DEPOSIT-1 canonical address equals the production literal. -/
theorem canonical_deposit_contract_pin :
    PDeposit1.canonicalDepositContractAddress = productionBeaconDeposit :=
  rfl

/-- The P-DEPOSIT-1 32-ether scale equals `32 * 10 ^ 18` wei. -/
theorem canonical_thirty_two_ether_pin :
    PDeposit1.thirtyTwoEtherWei = thirtyTwoEtherWei :=
  rfl

/-- `A-DEPOSIT-CONTRACT` is deployed-immutable identity, not the Lean pin.
    The pin above is a model equality. No in-repo bytecode artifact
    identifies the live `DEPOSIT_CONTRACT` immutable, so the assumption
    remains OPEN. -/
theorem deposit_contract_assumption_remains_open : True := trivial

/-- The only constructor restrictions in the pinned `StakingRouter.sol`
    source are nonzero checks.  This record is a source-level constructor
    witness, not a claim that such a router was deployed. -/
structure ConstructorInputs where
  depositContract : Nat
  maxEBType1 : Nat
  deriving Repr, DecidableEq

/-- The admission predicate copied from the two relevant constructor guards:
    `_depositContract` and `_maxEBType1` must be nonzero.  The constructor does
    not compare either value with the canonical address or `DEPOSIT_SIZE`. -/
def ConstructorAdmitted (inputs : ConstructorInputs) : Prop :=
  inputs.depositContract ≠ 0 ∧ inputs.maxEBType1 ≠ 0

/-- A source-admitted constructor input that violates both deployment facts.
    This is the counterexample showing why pinned source alone cannot discharge
    `A-DEPOSIT-CONTRACT` or `A-DEPOSIT-32-ETHER`. -/
def openAssumptionsCounterexample : ConstructorInputs :=
  { depositContract := 0xDEAD
    maxEBType1 := 64 * 10 ^ 18 }

theorem source_constructor_does_not_discharge_deployment_facts :
    ConstructorAdmitted openAssumptionsCounterexample ∧
      openAssumptionsCounterexample.depositContract ≠ productionBeaconDeposit ∧
      openAssumptionsCounterexample.maxEBType1 ≠ thirtyTwoEtherWei := by
  norm_num [ConstructorAdmitted, openAssumptionsCounterexample,
    productionBeaconDeposit, thirtyTwoEtherWei]

/-- A conserving source config exists at the 32-ether scale. Both fields
    match, so `ConservingConfig` holds in the model. This does not prove
    that production `MAX_EFFECTIVE_BALANCE_WC_TYPE_01` and `DEPOSIT_SIZE`
    were constructed at this scale (`A-DEPOSIT-32-ETHER` stays OPEN). -/
def productionConservingConfig : SourceDepositConfig :=
  { maxEBType1 := thirtyTwoEtherWei
    depositSize := thirtyTwoEtherWei
    pubkeyLength := 48
    publicKeyLength := 48
    signatureLength := 96 }

theorem production_conserving_config_at_thirty_two_ether :
    ConservingConfig productionConservingConfig :=
  rfl

/-- Kill-line: a wrong pin is not the canonical deposit address. -/
theorem wrong_deposit_contract_pin_kill_line :
    (0xDEAD : Nat) ≠ PDeposit1.canonicalDepositContractAddress := by
  decide

end LidoSRv3.Audit.Provenance.Deposit
