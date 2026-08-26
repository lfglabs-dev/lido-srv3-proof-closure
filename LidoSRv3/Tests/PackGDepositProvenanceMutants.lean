import LidoSRv3.Audit.Provenance.Deposit

/-!
# Pack G-DEPOSIT fail-closed vectors

A wrong beacon-deposit pin is not the production literal. This does not
discharge `A-DEPOSIT-CONTRACT` or `A-DEPOSIT-32-ETHER`.
-/

namespace LidoSRv3.Tests.PackGDepositProvenanceMutants

open LidoSRv3.Audit.Provenance.Deposit

/-- Kill-line: `0xDEAD` is not the production beacon deposit address. -/
theorem wrong_beacon_pin_kill_line :
    (0xDEAD : Nat) ≠ productionBeaconDeposit := by
  decide

/-- Source-backed negative control: the pinned constructor accepts nonzero
    values without enforcing either deployment-provenance identity. -/
theorem open_assumptions_counterexample_is_admitted :
    PinnedConstructorAdmitted openAssumptionsCounterexample ∧
      openAssumptionsCounterexample.depositContract ≠ productionBeaconDeposit ∧
      openAssumptionsCounterexample.maxEBType1 ≠ thirtyTwoEtherWei :=
  source_constructor_does_not_discharge_deployment_facts

/-- Parent-shaped guard-drop mutant: retaining only the deposit-contract guard
    admits a zero `_maxEBType1`; the bound pinned-source predicate rejects it. -/
def dropsMaxEBType1Guard (inputs : ConstructorInputs) : Prop :=
  inputs.depositContract ≠ 0

def droppedMaxEBType1GuardWitness : ConstructorInputs :=
  { depositContract := 0xDEAD, maxEBType1 := 0 }

theorem parent_shaped_mutant_refutes_bound_source_predicate :
    dropsMaxEBType1Guard droppedMaxEBType1GuardWitness ∧
      ¬ PinnedConstructorAdmitted droppedMaxEBType1GuardWitness := by
  norm_num [dropsMaxEBType1Guard, droppedMaxEBType1GuardWitness,
    PinnedConstructorAdmitted]

end LidoSRv3.Tests.PackGDepositProvenanceMutants
