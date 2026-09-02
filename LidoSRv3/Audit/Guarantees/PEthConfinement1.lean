import LidoSRv3.Audit.Model.EthConfinement
import LidoSRv3.Audit.Guarantees.Registry

/-!
# P-ETH-CONFINEMENT-1 candidate parent (NOT a registered guarantee)

`P-ETH-CONFINEMENT-1` is **not** registered.  It is absent from
`Guarantees.Id`, from `AllGuarantees.supplemental`, and from
`audit/guarantees.yaml`.  The canonical registry is frozen to the R1 review
basis pinned as `R1_REVIEW_BASE` in `scripts/audit_metadata.py`, and the R1
final auditor report published at that basis states that ETH confinement is
`NOT YET`.  Adding a registry row would present a changed registry as though
it carried the R1 review, which is exactly what that pin exists to prevent.
`audit/P-ETH-CONFINEMENT-1-BRIEF.md` records the blocker and the exact row
that becomes registerable once the registry reopens.

This module therefore sits next to the registered guarantee modules but is
imported by none of them: it conjoins the model-layer conjuncts of
`LidoSRv3.Audit.Model.EthConfinement` with the one conjunct that needs the
public guarantee registry, `CoveringParentsAreRegistered`.  That conjunct
cannot live in the model layer, because `scripts/check_import_dag.py` rejects
a model → guarantees import; it lives here, where importing
`LidoSRv3.Audit.Guarantees.Registry` is the ordinary direction.

## What the conclusion says

For every modeled ETH-world trace, every positive-value authorized frame is
either

* one of three explicitly named residual hops, or
* covered by a registered parent guarantee **and** landing on a frozen
  `Spec.ApprovedDestination`.

Its content is the agreement of three tables that are written independently
of each other:

1. `ValueRoute.primaryParent` — the E1 coverage table;
2. `Destination.toSpec` — the frozen Spec approval table;
3. `Guarantees.Id.text` — the public guarantee registry.

Agreement between (1) and (2) is what makes the conclusion refutable rather
than a restatement of one table, and (3) forbids naming a covering parent
that is not actually a registered guarantee.  `EthConfinementMutants` edits
one line of each table and refutes the corresponding conjunct.

## What it does not say

See `LidoSRv3.Audit.Model.EthConfinement`: `Confined` quantifies only over
`authorizedFrames`, the three residual hops remain unclassified rather than
discharged, and the inventory is `ValueRoute`, not the pinned Solidity (one
ETH exit, `WithdrawalQueueBase.sol:529`, is outside the enumeration).
-/

namespace LidoSRv3.Audit.Guarantees.PEthConfinement1

open LidoSRv3.Audit.Spec
open LidoSRv3.Audit.Model.EthWorld
open LidoSRv3.Audit.Model.EthConfinement

/-- The public guarantee registry's identifier type. -/
abbrev RegistryId := LidoSRv3.Audit.Guarantees.Id

/-! ## Registry binding -/

/-- Every covering parent the E1 model names, as an entry of the public
guarantee registry.  `CoveringParent.id` is a free-standing string table; this
is the function that forces those strings to denote real registered rows. -/
def registryId : CoveringParent → RegistryId
  | .pDepositOne            => .pDeposit1
  | .pTopupOne              => .pTopup1
  | .pConsolidationEthOne   => .pConsolidationEth1
  | .pConsolidationOne      => .pConsolidation1
  | .pConsolidationValueOne => .pConsolidationValue1
  | .pVaultEthOne           => .pVaultEth1
  | .pEthJournalOne         => .pEthJournal1

/-- Conjunct 1: no covering parent is fabricated.  Each parent string in the
E1 model is the registry text of an actual `Guarantees.Id`. -/
def CoveringParentsAreRegistered : Prop :=
  ∀ p : CoveringParent, p.id = (registryId p).text

/-- The four table-agreement conjuncts of the candidate parent; conjuncts 2
to 4 are the model-layer statements of `LidoSRv3.Audit.Model.EthConfinement`. -/
def ConfinementConclusion : Prop :=
  CoveringParentsAreRegistered ∧
    CoverageAgreesWithSpecApproval ∧
      ResidualIsExactlyTheUncoveredInventory ∧
        ResidualHopsAreUnclassified

/-! ## Proofs -/

theorem coveringParentsAreRegistered : CoveringParentsAreRegistered := by
  intro p; cases p <;> rfl

/-- **P-ETH-CONFINEMENT-1 candidate parent.** Universal over ETH-world
traces: the three independently written tables agree, the residual list is
exactly the uncovered inventory, and every positive-value authorized frame is
either a named residual hop or is both parent-covered and Spec-approved.

Scope: `ValueRoute`, not the pinned Solidity.  One ETH exit in the source
(`WithdrawalQueueBase.sol:529`) is outside this enumeration entirely; see the
scope-boundary section of `LidoSRv3.Audit.Model.EthConfinement`. -/
theorem modeled_positive_value_is_confined_or_residual
    (flows : List GeneralFlow) :
    ConfinementConclusion ∧ Confined flows :=
  ⟨⟨coveringParentsAreRegistered, coverageAgreesWithSpecApproval,
      residualIsExactlyTheUncoveredInventory, residualHopsAreUnclassified⟩,
    confined flows⟩

end LidoSRv3.Audit.Guarantees.PEthConfinement1
