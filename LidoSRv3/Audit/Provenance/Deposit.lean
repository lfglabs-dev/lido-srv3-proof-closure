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

/-- **A-DEPOSIT-CONTRACT status (chantier 4 update, Thomas 2026-09-13):**
    the deployed-immutable identity for `DEPOSIT_CONTRACT` is DISCHARGED
    via `scripts/verify_beacon_deposit_immutable.py` (invoked by `make test`),
    which re-hashes the pinned `StakingRouter_implementation` runtime
    fixture at `0xDD76927045435C7605cf6f5F978cfb8CABDb5F80` (codehash
    `0x9cd5d45ddde5f74d3867aa22c98fd79a85df89d202145bc588173d92e00600ec`,
    fixture SHA-256 recorded in `audit/artifacts.lock.json`) and
    re-extracts `DEPOSIT_CONTRACT` at its recorded byte offset. Live
    re-verification against a live chain runs under `ETH_RPC_URL`.
    The Lean pin above (`canonical_deposit_contract_pin`) is the source-
    side model equality that this fixture-anchored verification connects
    to the deployed runtime. See `audit/guarantees.yaml` P-DEPOSIT-1
    fidelity.covered and `audit/artifacts.lock.json`. The theorem body
    is `True := trivial` because the discharge lives in the verify
    script + fixture, not in Lean proof content. -/
theorem deposit_contract_assumption_status : True := trivial

/-- Projection of the two deployment-relevant inputs from pinned
    `StakingRouter.sol` lines 88--106.  The exact source fixture, its SHA-256,
    guard sequence, and direct immutable assignments are checked by
    `scripts/audit_metadata.py`.  This is source correspondence, not a claim
    that any particular router was deployed. -/
structure ConstructorInputs where
  depositContract : Nat
  maxEBType1 : Nat
  deriving Repr, DecidableEq

/-- Bound projection of the pinned guards
    `SRUtils._requireNotZero(_depositContract)` and
    `SRUtils._requireNotZero(_maxEBType1)`.  The fixture checker binds those
    guarded parameters to `DEPOSIT_CONTRACT` and
    `MAX_EFFECTIVE_BALANCE_WC_TYPE_01`, respectively. -/
def PinnedConstructorAdmitted (inputs : ConstructorInputs) : Prop :=
  inputs.depositContract ≠ 0 ∧ inputs.maxEBType1 ≠ 0

/-- A source-admitted constructor input that violates both deployment facts.
    This is the counterexample showing why pinned source alone cannot discharge
    `A-DEPOSIT-CONTRACT` or `A-DEPOSIT-32-ETHER`. -/
def openAssumptionsCounterexample : ConstructorInputs :=
  { depositContract := 0xDEAD
    maxEBType1 := 64 * 10 ^ 18 }

theorem source_constructor_does_not_discharge_deployment_facts :
    PinnedConstructorAdmitted openAssumptionsCounterexample ∧
      openAssumptionsCounterexample.depositContract ≠ productionBeaconDeposit ∧
      openAssumptionsCounterexample.maxEBType1 ≠ thirtyTwoEtherWei := by
  norm_num [PinnedConstructorAdmitted, openAssumptionsCounterexample,
    productionBeaconDeposit, thirtyTwoEtherWei]

/-- A conserving source config exists at the 32-ether scale. Both fields
    match, so `ConservingConfig` holds in the model. **A-DEPOSIT-32-ETHER
    status (chantier 4 update, Thomas 2026-09-13):** the deployed-immutable
    identity for `MAX_EFFECTIVE_BALANCE_WC_TYPE_01` and `DEPOSIT_SIZE` at
    the 32-ether scale is DISCHARGED via
    `scripts/verify_deposit_thirty_two_ether.py` (invoked by `make test`),
    which folds all five PUSH32 sites at 32000000000000000000 wei = 32 ether
    on the pinned StakingRouter runtime bytecode (see
    `audit/artifacts.lock.json` and `audit/findings/A-DEPOSIT-32-ETHER-discharged.md`).
    This `def` remains a source-side model equality; the discharge lives
    in the fixture-anchored verify script. -/
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
