import LidoSRv3.Audit.Guarantees.PEthConfinement1

/-!
# Kill-lines for the P-ETH-CONFINEMENT-1 candidate parent

Each section below copies one production table from
`LidoSRv3.Audit.Model.EthWorld` or `LidoSRv3.Audit.Model.EthConfinement`,
changes **exactly one line**, and proves that the corresponding conjunct of
`ConfinementConclusion` (stated in `LidoSRv3.Audit.Guarantees.PEthConfinement1`,
which also holds the registry binding `registryId`) becomes false.

Every mutant is paired with a *positive control* proving the copy agrees with
the production table on every input except the one edited case.  Without the
control a "kill" could come from a table that was mangled wholesale, which
would show nothing.

The four edits target four different tables, which is the point: the
conclusion's content is their mutual agreement, so no single table can be
rewritten to satisfy it alone.

No `native_decide` appears here.  `audit/trust-native-decide-allowlist.txt` is
pinned to the R1 review basis, so a new native-compiled proof term could not be
added to it without presenting a changed allowlist as R1-reviewed.
-/

namespace LidoSRv3.Tests.EthConfinementMutants

open LidoSRv3.Audit.Spec
open LidoSRv3.Audit.Model.EthWorld
open LidoSRv3.Audit.Model.EthConfinement
open LidoSRv3.Audit.Guarantees.PEthConfinement1

/-! ## Test-local enumerations

`EthWorld` exports `allRoutes` but no enumeration of `Destination` or
`CoveringParent`.  These are declared here rather than in the production model
so that the positive controls below do not require editing the table they are
meant to audit.  Each carries a proof that it really is exhaustive, otherwise a
control quantifying over it would be vacuously weak. -/

def allDestinations : List Destination :=
  [ .lidoPull, .beaconDeposit, .consolidationPredeploy, .withdrawalPredeploy
  , .refundRecipient, .consolidationGateway, .withdrawalVault
  , .vaultToLido, .vaultToWithdrawalQueue ]

theorem allDestinations_complete (d : Destination) : d ∈ allDestinations := by
  cases d <;> decide

def allCoveringParents : List CoveringParent :=
  [ .pDepositOne, .pTopupOne, .pConsolidationEthOne, .pConsolidationOne
  , .pConsolidationValueOne, .pVaultEthOne, .pEthJournalOne ]

theorem allCoveringParents_complete (p : CoveringParent) :
    p ∈ allCoveringParents := by
  cases p <;> decide

/-! ## Kill-line 1 — fabricate a covering parent for the Bus→Gateway hop

`busToGateway` lands on `consolidationGateway`, which has no
`Spec.ApprovedDestination`.  Claiming `P-CONSOLIDATION-1` covers it is exactly
the move that would launder a residual hop into a covered one. -/

def primaryParent_busCovered : ValueRoute → Option CoveringParent
  | .depositLidoPull        => some .pDepositOne
  | .depositBeaconDeposit   => some .pDepositOne
  | .topupLidoPull          => some .pTopupOne
  | .topupBeaconDeposit     => some .pTopupOne
  | .consolidationRefund    => some .pConsolidationEthOne
  | .busToGateway           => some .pConsolidationOne  -- EDITED (was `none`)
  | .gatewayToVault         => none
  | .vaultConsolidationCall => some .pConsolidationValueOne
  | .vaultWithdrawalCall    => none
  | .vaultToLido            => some .pVaultEthOne
  | .vaultToWithdrawalQueue => some .pVaultEthOne

theorem control_busCovered_differs_only_at_busToGateway :
    (∀ r ∈ allRoutes, r ≠ .busToGateway →
        primaryParent_busCovered r = r.primaryParent) ∧
      primaryParent_busCovered .busToGateway
        ≠ ValueRoute.primaryParent .busToGateway := by
  refine ⟨by decide, by decide⟩

theorem kill_coverageAgreesWithSpecApproval_busCovered :
    ¬ (∀ r : ValueRoute,
        (primaryParent_busCovered r).isSome = (r.destination.toSpec).isSome) := by
  intro h
  exact absurd (h .busToGateway) (by decide)

/-! ## Kill-line 2 — fabricate Spec approval for the EIP-7002 predeploy

`withdrawalPredeploy` has no constructor in `Spec.ApprovedDestination`.
Approving it would make `vaultWithdrawalCall` land on an approved destination
while no registered parent covers it. -/

def toSpec_withdrawalPredeployApproved : Destination → Option ApprovedDestination
  | .lidoPull               => some .lidoPull
  | .beaconDeposit          => some .beaconDeposit
  | .consolidationPredeploy => some .consolidationRequest
  | .withdrawalPredeploy    => some .lidoPull  -- EDITED (was `none`)
  | .refundRecipient        => some .refundRecipient
  | .consolidationGateway   => none
  | .withdrawalVault        => none
  | .vaultToLido            => some .vaultToLido
  | .vaultToWithdrawalQueue => some .vaultToWithdrawalQueue

theorem control_toSpecMutant_differs_only_at_withdrawalPredeploy :
    (∀ d ∈ allDestinations, d ≠ .withdrawalPredeploy →
        toSpec_withdrawalPredeployApproved d = d.toSpec) ∧
      toSpec_withdrawalPredeployApproved .withdrawalPredeploy
        ≠ Destination.toSpec .withdrawalPredeploy := by
  refine ⟨by decide, by decide⟩

theorem kill_coverageAgreesWithSpecApproval_predeployApproved :
    ¬ (∀ r : ValueRoute,
        (r.primaryParent).isSome
          = (toSpec_withdrawalPredeployApproved r.destination).isSome) := by
  intro h
  exact absurd (h .vaultWithdrawalCall) (by decide)

/-! ## Kill-line 3 — drop one residual hop from the literal list

The residual list is written independently of `primaryParent`.  Silently
shortening it is how an unclassified hop would disappear from the published
gap without anything covering it. -/

def residualRoutes_dropped : List ValueRoute :=
  [ .busToGateway, .vaultWithdrawalCall ]  -- EDITED (dropped `.gatewayToVault`)

theorem control_residualDropped_is_a_strict_sublist :
    residualRoutes_dropped ≠ residualRoutes ∧
      ∀ r ∈ residualRoutes_dropped, r ∈ residualRoutes := by
  refine ⟨by decide, by decide⟩

theorem kill_residualIsExactlyTheUncoveredInventory_dropped :
    ¬ (allRoutes.filter (fun r => (r.primaryParent).isNone)
        = residualRoutes_dropped) := by
  decide

/-! ## Kill-line 4 — name a parent that is not a registered guarantee

`CoveringParent.id` is a free-standing string table.  Pointing one entry at an
ID with no row in `Guarantees.Id` is the fabrication that conjunct 1 exists to
forbid. -/

def id_unregisteredVaultEth : CoveringParent → String
  | .pDepositOne            => "P-DEPOSIT-1"
  | .pTopupOne              => "P-TOPUP-1"
  | .pConsolidationEthOne   => "P-CONSOLIDATION-ETH-1"
  | .pConsolidationOne      => "P-CONSOLIDATION-1"
  | .pConsolidationValueOne => "P-CONSOLIDATION-VALUE-1"
  | .pVaultEthOne           => "P-VAULT-ETH-2"  -- EDITED (was "P-VAULT-ETH-1")
  | .pEthJournalOne         => "P-ETH-JOURNAL-1"

theorem control_idMutant_differs_only_at_pVaultEthOne :
    (∀ p ∈ allCoveringParents, p ≠ .pVaultEthOne →
        id_unregisteredVaultEth p = p.id) ∧
      id_unregisteredVaultEth .pVaultEthOne ≠ CoveringParent.id .pVaultEthOne := by
  refine ⟨by decide, by decide⟩

theorem kill_coveringParentsAreRegistered_unregisteredId :
    ¬ (∀ p : CoveringParent, id_unregisteredVaultEth p = (registryId p).text) := by
  intro h
  exact absurd (h .pVaultEthOne) (by decide)

/-! ## The production tables survive all four edits -/

theorem production_conclusion_holds : ConfinementConclusion :=
  ⟨coveringParentsAreRegistered, coverageAgreesWithSpecApproval,
    residualIsExactlyTheUncoveredInventory, residualHopsAreUnclassified⟩

end LidoSRv3.Tests.EthConfinementMutants
