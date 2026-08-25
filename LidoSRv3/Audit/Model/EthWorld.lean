import LidoSRv3.Audit.Spec

/-!
# E1 ETH-world inventory model

Complete inventory of every modeled in-scope positive-value route
in the Lido SRv3 audit scope at `lidofinance/core@af095e48`.

This model classifies all value-bearing external calls into modeled routes
covered by existing ETH parents and explicitly names the routes that remain
outside the audit scope.  It does not register P-ETH-CONFINEMENT-1 and does
not widen any existing parent theorem.

## Pinned source routes

| #  | ValueRoute              | Evidence                                                     |
|----|-------------------------|--------------------------------------------------------------|
|  1 | depositLidoPull         | Lido.withdrawDepositableEther (L869–886)                     |
|  2 | depositBeaconDeposit    | BeaconChainDepositor.makeBeaconChainDeposits32ETH (L36–64)   |
|  3 | topupLidoPull           | Lido.withdrawDepositableEther (L869–886)                     |
|  4 | topupBeaconDeposit      | BeaconChainDepositor.makeBeaconChainTopUp (L66–108)          |
|  5 | consolidationRefund     | ConsolidationGateway._refundFee (L295–307)                   |
|  6 | busToGateway            | ConsolidationBus.executeConsolidation (L383–406)             |
|  7 | gatewayToVault          | ConsolidationGateway → WithdrawalVault (totalFee forward)    |
|  8 | vaultConsolidationCall  | WithdrawalVaultEIP7685._callAddConsolidationRequest (L113–121)|
|  9 | vaultWithdrawalCall     | WithdrawalVaultEIP7685._callAddWithdrawalRequest (L103–111)  |
| 10 | vaultToLido             | WithdrawalVault → Lido.receiveWithdrawals (source-shaped; runtime endpoint) |
| 11 | vaultToWithdrawalQueue  | Vault → WithdrawalQueue (source-shaped; runtime endpoint)   |

## Covering parents

| Route                   | Primary parent           | Composition parent  |
|-------------------------|--------------------------|---------------------|
| depositLidoPull         | P-DEPOSIT-1              | P-ETH-JOURNAL-1     |
| depositBeaconDeposit    | P-DEPOSIT-1              | P-ETH-JOURNAL-1     |
| topupLidoPull           | P-TOPUP-1                | P-ETH-JOURNAL-1     |
| topupBeaconDeposit      | P-TOPUP-1                | P-ETH-JOURNAL-1     |
| consolidationRefund     | P-CONSOLIDATION-ETH-1    | P-ETH-JOURNAL-1     |
| busToGateway            | —                        | —                   |
| gatewayToVault          | —                        | —                   |
| vaultConsolidationCall  | P-CONSOLIDATION-VALUE-1  | P-ETH-JOURNAL-1; P-CONSOLIDATION-1 |
| vaultWithdrawalCall     | —                        | —                   |
| vaultToLido             | P-VAULT-ETH-1            | —                   |
| vaultToWithdrawalQueue  | P-VAULT-ETH-1            | —                   |

## Unsupported routes

Owner-controlled withdrawals (VaultHub.withdraw / StakingVault.withdraw),
stVault internal accounting, value-based exit bounds, governance lifecycle,
receive()/fallback() ETH, treasury minting, and operations transfers are
explicitly excluded.

## Spec boundary

Six of nine destinations map onto `Spec.ApprovedDestination`.  Three do
not: the withdrawal-request predeploy (EIP-7002, not covered by any
registered parent), the ConsolidationGateway (intermediate Bus→Gateway
hop), and the WithdrawalVault (intermediate Gateway→Vault hop).  These
three are documented scope boundaries, not gaps.
-/

namespace LidoSRv3.Audit.Model.EthWorld

open LidoSRv3.Audit.Spec

/-! ## Value route inventory -/

/-- Every modeled in-scope positive-value route.  The route provenance
explicitly distinguishes pinned Solidity call sites from source-shaped routes
whose endpoints are runtime inputs. -/
inductive ValueRoute where
  | depositLidoPull
  | depositBeaconDeposit
  | topupLidoPull
  | topupBeaconDeposit
  | consolidationRefund
  | busToGateway
  | gatewayToVault
  | vaultConsolidationCall
  | vaultWithdrawalCall
  | vaultToLido
  | vaultToWithdrawalQueue
  deriving DecidableEq, Repr, Inhabited

/-- Provenance available for a modeled value route.  `sourceShapedRuntime`
does not claim an extracted implementation call site or endpoint identity. -/
inductive RouteProvenance where
  | pinnedSolidityCall
  | sourceShapedRuntime
  deriving DecidableEq, Repr

/-- The two P-VAULT-ETH-1 routes are source-shaped schedules with runtime
endpoints; all other inventory routes denote pinned Solidity call sites. -/
def ValueRoute.provenance : ValueRoute → RouteProvenance
  | .vaultToLido            => .sourceShapedRuntime
  | .vaultToWithdrawalQueue => .sourceShapedRuntime
  | _                       => .pinnedSolidityCall

/-! ## Destination classification -/

/-- Unified destination for all modeled ETH-bearing call sites.  Nine
constructors cover every target contract, predeploy, or intermediate
protocol hop in the inventory. -/
inductive Destination where
  | lidoPull
  | beaconDeposit
  | consolidationPredeploy
  | withdrawalPredeploy
  | refundRecipient
  | consolidationGateway
  | withdrawalVault
  | vaultToLido
  | vaultToWithdrawalQueue
  deriving DecidableEq, Repr

/-- Map each value route to its target destination. -/
def ValueRoute.destination : ValueRoute → Destination
  | .depositLidoPull        => .lidoPull
  | .depositBeaconDeposit   => .beaconDeposit
  | .topupLidoPull          => .lidoPull
  | .topupBeaconDeposit     => .beaconDeposit
  | .consolidationRefund    => .refundRecipient
  | .busToGateway           => .consolidationGateway
  | .gatewayToVault         => .withdrawalVault
  | .vaultConsolidationCall => .consolidationPredeploy
  | .vaultWithdrawalCall    => .withdrawalPredeploy
  | .vaultToLido            => .vaultToLido
  | .vaultToWithdrawalQueue => .vaultToWithdrawalQueue

/-- Project a destination to `Spec.ApprovedDestination` where one exists.
The withdrawal-request predeploy (EIP-7002), ConsolidationGateway
(intermediate Bus→Gateway hop), and WithdrawalVault (intermediate
Gateway→Vault hop) map to `none`: they have no constructor in
`Spec.ApprovedDestination`. -/
def Destination.toSpec : Destination → Option ApprovedDestination
  | .lidoPull               => some .lidoPull
  | .beaconDeposit          => some .beaconDeposit
  | .consolidationPredeploy => some .consolidationRequest
  | .withdrawalPredeploy    => none
  | .refundRecipient        => some .refundRecipient
  | .consolidationGateway   => none
  | .withdrawalVault        => none
  | .vaultToLido            => some .vaultToLido
  | .vaultToWithdrawalQueue => some .vaultToWithdrawalQueue

/-! ## Unsupported routes -/

/-- Value-bearing paths explicitly outside the audit scope.  Each
constructor names a class of ETH movement not modeled by any registered
parent theorem. -/
inductive UnsupportedRoute where
  | ownerWithdrawal
  | stVaultInternal
  | valueBoundedExit
  | governanceLifecycle
  | fallbackReceive
  | treasuryMint
  | opsTransfer
  deriving DecidableEq, Repr

/-! ## Authorized value frame -/

/-- A value-bearing external call classified into the modeled inventory.
The `route` tag binds the call to a pinned source site; the `value` field
records the wei transferred.  Positive-value enforcement is a separate
predicate so that zero-value frames can be constructed for mutant tests. -/
structure AuthorizedValueFrame where
  route : ValueRoute
  value : Nat
  deriving DecidableEq, Repr

def AuthorizedValueFrame.isPositive (f : AuthorizedValueFrame) : Prop :=
  0 < f.value

instance : Decidable (AuthorizedValueFrame.isPositive f) :=
  inferInstanceAs (Decidable (0 < f.value))

/-! ## Covering parent registry -/

/-- Parent theorems that cover value-bearing routes in the ETH-world
inventory.  These are existing registered parents; this model does not
introduce new guarantee IDs. -/
inductive CoveringParent where
  | pDepositOne
  | pTopupOne
  | pConsolidationEthOne
  | pConsolidationOne
  | pConsolidationValueOne
  | pVaultEthOne
  | pEthJournalOne
  deriving DecidableEq, Repr

def CoveringParent.id : CoveringParent → String
  | .pDepositOne           => "P-DEPOSIT-1"
  | .pTopupOne             => "P-TOPUP-1"
  | .pConsolidationEthOne  => "P-CONSOLIDATION-ETH-1"
  | .pConsolidationOne     => "P-CONSOLIDATION-1"
  | .pConsolidationValueOne => "P-CONSOLIDATION-VALUE-1"
  | .pVaultEthOne          => "P-VAULT-ETH-1"
  | .pEthJournalOne        => "P-ETH-JOURNAL-1"

/-- Primary covering parent for each route.  Intermediate consolidation
hops (busToGateway, gatewayToVault) and the withdrawal-request predeploy
(EIP-7002) are not covered by any registered primary parent. -/
def ValueRoute.primaryParent : ValueRoute → Option CoveringParent
  | .depositLidoPull        => some .pDepositOne
  | .depositBeaconDeposit   => some .pDepositOne
  | .topupLidoPull          => some .pTopupOne
  | .topupBeaconDeposit     => some .pTopupOne
  | .consolidationRefund    => some .pConsolidationEthOne
  | .busToGateway           => none
  | .gatewayToVault         => none
  | .vaultConsolidationCall => some .pConsolidationValueOne
  | .vaultWithdrawalCall    => none
  | .vaultToLido            => some .pVaultEthOne
  | .vaultToWithdrawalQueue => some .pVaultEthOne

/-- All composition parents for routes covered by broader parent theorems
that compose the primary parent's result.  The terminal consolidation fee is
jointly represented by P-ETH-JOURNAL-1 and P-CONSOLIDATION-1. -/
def ValueRoute.compositionParents : ValueRoute → List CoveringParent
  | .depositLidoPull        => [.pEthJournalOne]
  | .depositBeaconDeposit   => [.pEthJournalOne]
  | .topupLidoPull          => [.pEthJournalOne]
  | .topupBeaconDeposit     => [.pEthJournalOne]
  | .consolidationRefund    => [.pEthJournalOne]
  | .busToGateway           => []
  | .gatewayToVault         => []
  | .vaultConsolidationCall => [.pEthJournalOne, .pConsolidationOne]
  | .vaultWithdrawalCall    => []
  | .vaultToLido            => []
  | .vaultToWithdrawalQueue => []

/-! ## Spec-layer coverage -/

/-- Every `Spec.ApprovedDestination` is reachable from at least one
modeled value route.  This does not widen the Spec type; it witnesses
surjectivity of the existing constructors. -/
theorem spec_destination_surjective (d : ApprovedDestination) :
    ∃ r : ValueRoute, r.destination.toSpec = some d := by
  cases d with
  | consolidationRequest  => exact ⟨.vaultConsolidationCall, rfl⟩
  | refundRecipient       => exact ⟨.consolidationRefund, rfl⟩
  | beaconDeposit         => exact ⟨.depositBeaconDeposit, rfl⟩
  | lidoPull              => exact ⟨.depositLidoPull, rfl⟩
  | vaultToLido           => exact ⟨.vaultToLido, rfl⟩
  | vaultToWithdrawalQueue => exact ⟨.vaultToWithdrawalQueue, rfl⟩

/-- The single destination not in `Spec.ApprovedDestination` is the
EIP-7002 withdrawal-request predeploy. -/
theorem withdrawal_predeploy_outside_spec :
    Destination.toSpec .withdrawalPredeploy = none := rfl

/-- Intermediate protocol hops also have no Spec projection. -/
theorem intermediate_hops_outside_spec :
    Destination.toSpec .consolidationGateway = none ∧
    Destination.toSpec .withdrawalVault = none := ⟨rfl, rfl⟩

/-- All destinations except the three without Spec constructors project
into the Spec layer. -/
theorem terminal_destinations_in_spec (d : Destination)
    (h1 : d ≠ .withdrawalPredeploy)
    (h2 : d ≠ .consolidationGateway)
    (h3 : d ≠ .withdrawalVault) :
    (Destination.toSpec d).isSome = true := by
  cases d <;> simp_all [Destination.toSpec]

/-! ## Inventory enumeration -/

def allRoutes : List ValueRoute :=
  [ .depositLidoPull, .depositBeaconDeposit
  , .topupLidoPull, .topupBeaconDeposit
  , .consolidationRefund
  , .busToGateway, .gatewayToVault
  , .vaultConsolidationCall, .vaultWithdrawalCall
  , .vaultToLido, .vaultToWithdrawalQueue ]

def allUnsupportedRoutes : List UnsupportedRoute :=
  [ .ownerWithdrawal, .stVaultInternal, .valueBoundedExit
  , .governanceLifecycle, .fallbackReceive, .treasuryMint, .opsTransfer ]

theorem inventory_count : allRoutes.length = 11 := rfl

theorem unsupported_count : allUnsupportedRoutes.length = 7 := rfl

theorem allRoutes_nodup : allRoutes.Nodup := by native_decide

/-! ## General flow and owner/treasury/ops mutant -/

/-- A general ETH flow that may or may not be in the modeled inventory.
Authorized frames carry a route tag; owner, treasury, and ops transfers
are untagged. -/
inductive GeneralFlow where
  | authorized (frame : AuthorizedValueFrame)
  | ownerWithdrawal (recipient : Nat) (value : Nat)
  | treasuryMint (value : Nat)
  | opsTransfer (value : Nat)
  deriving DecidableEq, Repr

/-- Zero all non-modeled values.  Authorized frames pass through unchanged;
owner, treasury, and ops values are set to zero. -/
def zeroUnmodeled : GeneralFlow → GeneralFlow
  | .authorized f         => .authorized f
  | .ownerWithdrawal r _  => .ownerWithdrawal r 0
  | .treasuryMint _       => .treasuryMint 0
  | .opsTransfer _        => .opsTransfer 0

/-- Extract authorized frames from a mixed flow list. -/
def authorizedFrames : List GeneralFlow → List AuthorizedValueFrame
  | []                          => []
  | .authorized f :: rest       => f :: authorizedFrames rest
  | .ownerWithdrawal _ _ :: rest => authorizedFrames rest
  | .treasuryMint _ :: rest     => authorizedFrames rest
  | .opsTransfer _ :: rest      => authorizedFrames rest

private theorem zeroUnmodeled_preserves_frames : ∀ (flows : List GeneralFlow),
    authorizedFrames (flows.map zeroUnmodeled) = authorizedFrames flows
  | [] => rfl
  | .authorized f :: rest => by
      show f :: authorizedFrames (rest.map zeroUnmodeled) =
           f :: authorizedFrames rest
      rw [zeroUnmodeled_preserves_frames rest]
  | .ownerWithdrawal _ _ :: rest =>
      zeroUnmodeled_preserves_frames rest
  | .treasuryMint _ :: rest =>
      zeroUnmodeled_preserves_frames rest
  | .opsTransfer _ :: rest =>
      zeroUnmodeled_preserves_frames rest

/-- Total value of authorized frames. -/
def inventoryValue (flows : List GeneralFlow) : Nat :=
  (authorizedFrames flows).foldl (fun acc f => acc + f.value) 0

/-- Total value of all flows including unmodeled owner/treasury/ops. -/
def totalValue : List GeneralFlow → Nat
  | []                            => 0
  | .authorized f :: rest         => f.value + totalValue rest
  | .ownerWithdrawal _ v :: rest  => v + totalValue rest
  | .treasuryMint v :: rest       => v + totalValue rest
  | .opsTransfer v :: rest        => v + totalValue rest

/-- Zeroing non-modeled values preserves modeled inventory value. -/
theorem zeroUnmodeled_preserves_value (flows : List GeneralFlow) :
    inventoryValue (flows.map zeroUnmodeled) = inventoryValue flows := by
  unfold inventoryValue
  rw [zeroUnmodeled_preserves_frames]

/-! ## Parent-shaped mutants -/

/-- Zero the value of every authorized frame whose route has a given
primary parent.  Used by parent-shaped mutants to show each primary
covering parent is load-bearing. -/
def zeroParentRoutes (p : CoveringParent) : GeneralFlow → GeneralFlow
  | .authorized f          =>
    if f.route.primaryParent = some p then .authorized ⟨f.route, 0⟩
    else .authorized f
  | .ownerWithdrawal r v   => .ownerWithdrawal r v
  | .treasuryMint v        => .treasuryMint v
  | .opsTransfer v         => .opsTransfer v

/-- Zero the value of every authorized frame whose route has a given
composition parent.  Used by composition-parent mutants. -/
def zeroCompositionParentRoutes (p : CoveringParent) : GeneralFlow → GeneralFlow
  | .authorized f          =>
    if p ∈ f.route.compositionParents then .authorized ⟨f.route, 0⟩
    else .authorized f
  | .ownerWithdrawal r v   => .ownerWithdrawal r v
  | .treasuryMint v        => .treasuryMint v
  | .opsTransfer v         => .opsTransfer v

end LidoSRv3.Audit.Model.EthWorld
