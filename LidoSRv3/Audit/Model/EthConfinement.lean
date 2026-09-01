import LidoSRv3.Audit.Model.EthWorld
import LidoSRv3.Audit.Guarantees.Registry

/-!
# P-ETH-CONFINEMENT-1 candidate parent (NOT a registered guarantee)

This module states, and proves, the confinement conclusion that the E1
ETH-world inventory (`LidoSRv3.Audit.Model.EthWorld`) was built to support.

## Registration status

`P-ETH-CONFINEMENT-1` is **not** registered here.  It is absent from
`Guarantees.Id`, from `AllGuarantees.supplemental`, and from
`audit/guarantees.yaml`.  The canonical registry is frozen to the R1 review
basis pinned as `R1_REVIEW_BASE` in `scripts/audit_metadata.py`, and the R1
final auditor report published at that basis states that ETH confinement is
`NOT YET`.  Adding a registry row would present a changed registry as though
it carried the R1 review, which is exactly what that pin exists to prevent.
`audit/P-ETH-CONFINEMENT-1-BRIEF.md` records the blocker and the exact row
that becomes registerable once the registry reopens.

So the conclusion below is a *candidate* parent: the theorem content is
complete and kernel-checked, but no public claim surface asserts it.

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

This is not a claim that Lido never drains ETH, and not a claim about all
SRv3 ETH.  `Confined` quantifies only over `authorizedFrames`: owner,
treasury, and operations transfers carry unbounded value that this
conclusion does not bound at all, which
`confinement_does_not_bound_unmodeled_value` states as a theorem rather than
as prose.  The three residual hops remain unclassified, not discharged.

## Scope boundary: the inventory is not source-complete

Every quantifier below ranges over `EthWorld.ValueRoute`, an enumeration of
eleven modeled hops.  It does **not** range over the ETH-moving sites of the
pinned Solidity.  A site-by-site read of the fourteen in-scope files at the
pinned commit (recorded in `audit/P-ETH-CONFINEMENT-1-BRIEF.md`) found three
defects that this module cannot repair, because repairing them means editing
the inventory and the registry, both of which are currently frozen:

1. **One unclassified out-of-inventory hop.**
   `contracts/0.8.9/WithdrawalQueueBase.sol:529` (`_sendValue`), reached from
   in-scope `contracts/0.8.9/WithdrawalQueue.sol:253`, `:272`, `:285`, sends
   ETH to an arbitrary caller-supplied recipient.  It matches no `ValueRoute`
   and no `UnsupportedRoute` exclusion class.  `residualRoutes` therefore
   names the residue *of the modeled inventory*, not every unclassified ETH
   exit in the source.
2. **One misattributed route endpoint.**  Route `vaultToWithdrawalQueue` is
   documented as `Vault → WithdrawalQueue`; the only ETH-bearing call into the
   queue is `contracts/0.4.24/Lido.sol:1099–1101`, whose source is Lido.  The
   destination is right and the route is tagged `sourceShapedRuntime`, so no
   Lean statement asserts the wrong endpoint, but the prose does.
3. **One provenance under-claim.**  Route `vaultToLido` is tagged
   `sourceShapedRuntime` although `contracts/0.8.9/WithdrawalVault.sol:120` is
   a pinned call site.  Conservative, but inaccurate.

The one solid negative result behind the enumeration: the fourteen in-scope
files contain no `delegatecall`, `selfdestruct`, `create`/`create2`, inline
assembly `call`, or `.transfer`/`.send`, so the value-moving surface is
syntactically enumerable and there are no dynamically dispatched ETH exits
hiding in the pinned text.
-/

namespace LidoSRv3.Audit.Model.EthConfinement

open LidoSRv3.Audit.Spec
open LidoSRv3.Audit.Model.EthWorld

/-- The public guarantee registry's identifier type. -/
abbrev RegistryId := LidoSRv3.Audit.Guarantees.Id

/-! ## Residual hops -/

/-- The value routes this inventory places under **no** registered covering
parent, named as a literal list rather than derived from `primaryParent`.
Keeping the list independent of the coverage table is what lets
`ResidualIsExactlyTheUncoveredInventory` fail when a hop is dropped. -/
def residualRoutes : List ValueRoute :=
  [ .busToGateway, .gatewayToVault, .vaultWithdrawalCall ]

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

/-! ## Conclusion conjuncts -/

/-- Conjunct 1: no covering parent is fabricated.  Each parent string in the
E1 model is the registry text of an actual `Guarantees.Id`. -/
def CoveringParentsAreRegistered : Prop :=
  ∀ p : CoveringParent, p.id = (registryId p).text

/-- Conjunct 2: the coverage table and the frozen Spec approval table agree
route by route.  No route may be covered by a registered parent while landing
outside `Spec.ApprovedDestination`, and no route may reach an approved
destination without a registered parent behind it. -/
def CoverageAgreesWithSpecApproval : Prop :=
  ∀ r : ValueRoute, (r.primaryParent).isSome = (r.destination.toSpec).isSome

/-- Conjunct 3: the literal residual list is exactly the uncovered part of the
inventory — no unclassified hop is omitted from it, and no listed hop is
secretly covered. -/
def ResidualIsExactlyTheUncoveredInventory : Prop :=
  allRoutes.filter (fun r => (r.primaryParent).isNone) = residualRoutes

/-- Conjunct 4: the residual hops are unclassified on both planes.  This
states the gap; it does not discharge it. -/
def ResidualHopsAreUnclassified : Prop :=
  ∀ r ∈ residualRoutes, r.primaryParent = none ∧ r.destination.toSpec = none

/-- One route is confined when it is a named residual hop or has both a
registered covering parent and an approved Spec destination. -/
def RouteConfined (r : ValueRoute) : Prop :=
  r ∈ residualRoutes ∨
    ∃ p d, r.primaryParent = some p ∧ r.destination.toSpec = some d

/-- Trace-level confinement, universally quantified over ETH-world traces. -/
def Confined (flows : List GeneralFlow) : Prop :=
  ∀ f ∈ authorizedFrames flows, f.isPositive → RouteConfined f.route

/-- The four table-agreement conjuncts of the candidate parent. -/
def ConfinementConclusion : Prop :=
  CoveringParentsAreRegistered ∧
    CoverageAgreesWithSpecApproval ∧
      ResidualIsExactlyTheUncoveredInventory ∧
        ResidualHopsAreUnclassified

/-! ## Proofs -/

theorem coveringParentsAreRegistered : CoveringParentsAreRegistered := by
  intro p; cases p <;> rfl

theorem coverageAgreesWithSpecApproval : CoverageAgreesWithSpecApproval := by
  intro r; cases r <;> rfl

theorem residualIsExactlyTheUncoveredInventory :
    ResidualIsExactlyTheUncoveredInventory := by
  unfold ResidualIsExactlyTheUncoveredInventory
  decide

theorem residualHopsAreUnclassified : ResidualHopsAreUnclassified := by
  unfold ResidualHopsAreUnclassified
  decide

theorem route_confined (r : ValueRoute) : RouteConfined r := by
  cases r
  case depositLidoPull =>
    exact Or.inr ⟨.pDepositOne, .lidoPull, rfl, rfl⟩
  case depositBeaconDeposit =>
    exact Or.inr ⟨.pDepositOne, .beaconDeposit, rfl, rfl⟩
  case topupLidoPull =>
    exact Or.inr ⟨.pTopupOne, .lidoPull, rfl, rfl⟩
  case topupBeaconDeposit =>
    exact Or.inr ⟨.pTopupOne, .beaconDeposit, rfl, rfl⟩
  case consolidationRefund =>
    exact Or.inr ⟨.pConsolidationEthOne, .refundRecipient, rfl, rfl⟩
  case busToGateway =>
    exact Or.inl (by decide)
  case gatewayToVault =>
    exact Or.inl (by decide)
  case vaultConsolidationCall =>
    exact Or.inr ⟨.pConsolidationValueOne, .consolidationRequest, rfl, rfl⟩
  case vaultWithdrawalCall =>
    exact Or.inl (by decide)
  case vaultToLido =>
    exact Or.inr ⟨.pVaultEthOne, .vaultToLido, rfl, rfl⟩
  case vaultToWithdrawalQueue =>
    exact Or.inr ⟨.pVaultEthOne, .vaultToWithdrawalQueue, rfl, rfl⟩

/-- **P-ETH-CONFINEMENT-1 candidate parent.** Universal over ETH-world
traces: the three independently written tables agree, the residual list is
exactly the uncovered inventory, and every positive-value authorized frame is
either a named residual hop or is both parent-covered and Spec-approved.

Scope: `ValueRoute`, not the pinned Solidity.  One ETH exit in the source
(`WithdrawalQueueBase.sol:529`) is outside this enumeration entirely; see the
scope-boundary section of the module header. -/
theorem modeled_positive_value_is_confined_or_residual
    (flows : List GeneralFlow) :
    ConfinementConclusion ∧ Confined flows :=
  ⟨⟨coveringParentsAreRegistered, coverageAgreesWithSpecApproval,
      residualIsExactlyTheUncoveredInventory, residualHopsAreUnclassified⟩,
    fun f _ _ => route_confined f.route⟩

/-! ## Stated limits -/

private def unmodeledFlows : List GeneralFlow :=
  [ .ownerWithdrawal 42 1000, .treasuryMint 500, .opsTransfer 250 ]

/-- Named limit, proved rather than asserted in prose: on a trace made only of
owner, treasury, and operations transfers the confinement conclusion holds
vacuously while 1750 wei moves. `Confined` is not an all-SRv3-ETH claim. -/
theorem confinement_does_not_bound_unmodeled_value :
    Confined unmodeledFlows ∧
      totalValue unmodeledFlows = 1750 ∧
        inventoryValue unmodeledFlows = 0 :=
  ⟨fun f _ _ => route_confined f.route, rfl, rfl⟩

private def residualWitnessFlows : List GeneralFlow :=
  [ .authorized ⟨.busToGateway, 10⟩
  , .authorized ⟨.gatewayToVault, 5⟩
  , .authorized ⟨.vaultWithdrawalCall, 2⟩ ]

/-- Non-vacuity of the gap: the residual hops are inhabited by positive-value
frames carrying 17 wei that no registered parent covers, so the residual list
is a live exclusion rather than an empty formality. -/
theorem residual_hops_carry_unclassified_value :
    inventoryValue residualWitnessFlows = 17 ∧
      ∀ f ∈ authorizedFrames residualWitnessFlows,
        f.route.primaryParent = none := by
  refine ⟨rfl, ?_⟩
  decide

end LidoSRv3.Audit.Model.EthConfinement
