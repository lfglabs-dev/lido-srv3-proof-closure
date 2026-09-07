import LidoSRv3.Audit.Model.EthWorld

/-!
# P-ETH-CONFINEMENT-1 candidate parent: model-layer conjuncts (NOT a registered guarantee)

This module states, and proves, the model-layer part of the confinement
conclusion that the E1 ETH-world inventory (`LidoSRv3.Audit.Model.EthWorld`)
was built to support: the agreement of the coverage table with the frozen
Spec approval table, the exactness of the residual list, and route-level
confinement.  The candidate parent theorem itself, together with the one
conjunct that binds the inventory's covering parents to the public guarantee
registry, lives in `LidoSRv3.Audit.Guarantees.PEthConfinement1`.  The model
layer may not import `LidoSRv3.Audit.Guarantees.Registry`
(`scripts/check_import_dag.py` rejects a model → guarantees edge), so the
registry binding sits with the guarantee modules and this module stays a
function of the inventory and the frozen Spec alone.

## Registration status

`P-ETH-CONFINEMENT-1` is **not** registered here.  It is absent from
`Guarantees.Id`, from `AllGuarantees.supplemental`, and from
`audit/guarantees.yaml`.  Registration is deliberately deferred: this is an inventory/table-agreement
result, not an execution-level confinement guarantee. The recorded input basis
may be updated with reviewed metadata; doing so is not an external audit and
cannot establish the missing source coverage. The brief records those limits.

So the conclusion is a *candidate* parent: the theorem content is complete
and kernel-checked (`PEthConfinement1.modeled_positive_value_is_confined_or_residual`),
but no public claim surface asserts it.

## What the presence-only conclusion says

For every modeled ETH-world trace, every positive-value authorized frame is
either

* one of three explicitly named residual hops, or
* labeled with a registered parent identifier **and** a frozen
  `Spec.ApprovedDestination`.

Its content is the agreement of three tables that are written independently
of each other:

1. `ValueRoute.primaryParent` — the E1 coverage table;
2. `Destination.toSpec` — the frozen Spec approval table;
3. `Guarantees.Id.text` — the public guarantee registry.

Agreement between (1) and (2) is what makes the conclusion refutable rather
than a restatement of one table, and (3) forbids naming a covering parent
that is not actually a registered guarantee.  Conjuncts over (1) and (2) are
proved here; the conjunct over (3) is proved in
`LidoSRv3.Audit.Guarantees.PEthConfinement1`, which imports the registry.
`EthConfinementMutants` edits one line of each table and refutes the
corresponding conjunct.

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
pinned Solidity. The named-site inspection at
`17005714f151e5502c559932319a3f2f74ac2436` is recorded in
`audit/P-ETH-CONFINEMENT-1-BRIEF.md`. Three limits remain:

1. `WithdrawalQueueBase.sol:529`, reached through the queue claim entrypoints,
   pays an arbitrary recipient and has no `ValueRoute` or dedicated
   `UnsupportedRoute` class. The residual list covers only the inventory.
2. The legacy name `vaultToWithdrawalQueue` denotes a route whose inspected
   source analogue is Lido → WithdrawalQueue (`Lido.sol:1099–1101`).
   Correcting that documentation does not establish executable correspondence.
3. `vaultToLido` remains `sourceShapedRuntime`: the matching call at
   `WithdrawalVault.sol:120` does not establish model/runtime correspondence.

Neither this inspection nor an opcode search constrains arbitrary callees,
callbacks, or dynamically selected destinations. No source-completeness
conclusion follows from the finite enumeration.

-/

namespace LidoSRv3.Audit.Model.EthConfinement

open LidoSRv3.Audit.Spec
open LidoSRv3.Audit.Model.EthWorld

/-! ## Residual hops -/

/-- The value routes this inventory places under **no** registered covering
parent, named as a literal list rather than derived from `primaryParent`.
Keeping the list independent of the coverage table is what lets
`ResidualIsExactlyTheUncoveredInventory` fail when a hop is dropped. -/
def residualRoutes : List ValueRoute :=
  [ .busToGateway, .gatewayToVault, .vaultWithdrawalCall ]

/-! ## Conclusion conjuncts

Conjunct 1 (`CoveringParentsAreRegistered`: no covering parent is fabricated)
needs the public guarantee registry and is stated in
`LidoSRv3.Audit.Guarantees.PEthConfinement1`. -/

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

/-! ## Exact inventory assignments

An independent literal specification binds each route to its parent label,
destination label and Spec projection. It validates these exact assignments,
not the semantic applicability of the named parent's theorem to an execution.
The earlier presence-only predicate is retained as a weaker compatibility result.
-/

def expectedAssignment : ValueRoute →
    Option CoveringParent × Destination × Option ApprovedDestination
  | .depositLidoPull => (some .pDepositOne, .lidoPull, some .lidoPull)
  | .depositBeaconDeposit => (some .pDepositOne, .beaconDeposit, some .beaconDeposit)
  | .topupLidoPull => (some .pTopupOne, .lidoPull, some .lidoPull)
  | .topupBeaconDeposit => (some .pTopupOne, .beaconDeposit, some .beaconDeposit)
  | .consolidationRefund => (some .pConsolidationEthOne, .refundRecipient, some .refundRecipient)
  | .busToGateway => (none, .consolidationGateway, none)
  | .gatewayToVault => (none, .withdrawalVault, none)
  | .vaultConsolidationCall =>
      (some .pConsolidationValueOne, .consolidationPredeploy, some .consolidationRequest)
  | .vaultWithdrawalCall => (none, .withdrawalPredeploy, none)
  | .vaultToLido => (some .pVaultEthOne, .vaultToLido, some .vaultToLido)
  | .vaultToWithdrawalQueue => (some .pVaultEthOne, .vaultToWithdrawalQueue, some .vaultToWithdrawalQueue)

/-- Parameterized over the tables so a wrong but registered/approved identity
can refute the same predicate used by the exact inventory theorem. -/
def RouteAssignmentsMatch
    (parent : ValueRoute → Option CoveringParent)
    (destination : ValueRoute → Destination)
    (approval : Destination → Option ApprovedDestination) : Prop :=
  ∀ r, (parent r, destination r, approval (destination r)) = expectedAssignment r

theorem routeAssignmentsMatch :
    RouteAssignmentsMatch ValueRoute.primaryParent ValueRoute.destination Destination.toSpec := by
  intro r
  cases r <;> rfl

/-! ## Proofs -/

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

/-- Trace-level confinement, universally quantified over ETH-world traces.
The candidate parent in `LidoSRv3.Audit.Guarantees.PEthConfinement1` conjoins
this with the four table-agreement conjuncts. -/
theorem confined (flows : List GeneralFlow) : Confined flows :=
  fun f _ _ => route_confined f.route

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
