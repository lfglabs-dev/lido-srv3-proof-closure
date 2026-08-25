import LidoSRv3.Audit.Spec

/-!
# E1 ETH-world inventory model

Complete inventory of every pinned in-scope positive-value Solidity route
in the Lido SRv3 audit scope at `lidofinance/core@af095e48`.

This model classifies all value-bearing external calls into modeled routes
covered by existing ETH parents and explicitly names the routes that remain
outside the audit scope.  It does not register P-ETH-CONFINEMENT-1 and does
not widen any existing parent theorem.

## Pinned source routes

| #  | ValueRoute              | Solidity call site                                           |
|----|-------------------------|--------------------------------------------------------------|
|  1 | depositLidoPull         | Lido.withdrawDepositableEther (L869–886)                     |
|  2 | depositBeaconDeposit    | BeaconChainDepositor.makeBeaconChainDeposits32ETH (L36–64)   |
|  3 | topupLidoPull           | Lido.withdrawDepositableEther (L869–886)                     |
|  4 | topupBeaconDeposit      | BeaconChainDepositor.makeBeaconChainTopUp (L66–108)          |
|  5 | consolidationFee        | ConsolidationGateway.addConsolidationRequests (L185–223)     |
|  6 | consolidationRefund     | ConsolidationGateway._refundFee (L295–307)                   |
|  7 | vaultConsolidationCall  | WithdrawalVaultEIP7685._callAddConsolidationRequest (L113–121)|
|  8 | vaultWithdrawalCall     | WithdrawalVaultEIP7685._callAddWithdrawalRequest (L103–111)  |
|  9 | vaultToLido             | StakingVault → Lido via receiveWithdrawals                   |
| 10 | vaultToWithdrawalQueue  | StakingVault → WithdrawalQueue                               |

## Covering parents

| Route                   | Primary parent           | Composition parent  |
|-------------------------|--------------------------|---------------------|
| depositLidoPull         | P-DEPOSIT-1              | P-ETH-JOURNAL-1     |
| depositBeaconDeposit    | P-DEPOSIT-1              | P-ETH-JOURNAL-1     |
| topupLidoPull           | P-TOPUP-1                | P-ETH-JOURNAL-1     |
| topupBeaconDeposit      | P-TOPUP-1                | P-ETH-JOURNAL-1     |
| consolidationFee        | P-CONSOLIDATION-ETH-1    | P-ETH-JOURNAL-1     |
| consolidationRefund     | P-CONSOLIDATION-ETH-1    | P-ETH-JOURNAL-1     |
| vaultConsolidationCall  | P-CONSOLIDATION-VALUE-1  | P-CONSOLIDATION-1   |
| vaultWithdrawalCall     | P-CONSOLIDATION-ETH-1    | —                   |
| vaultToLido             | P-VAULT-ETH-1            | —                   |
| vaultToWithdrawalQueue  | P-VAULT-ETH-1            | —                   |

## Unsupported routes

Owner-controlled withdrawals (VaultHub.withdraw / StakingVault.withdraw),
stVault internal accounting, value-based exit bounds, governance lifecycle,
and receive()/fallback() ETH are explicitly excluded.

## Spec boundary

Six of seven destinations map onto `Spec.ApprovedDestination`.  The
withdrawal-request predeploy (EIP-7002) is approved by the
P-CONSOLIDATION-ETH-1 abstract `parentApproved` predicate but has no
constructor in `Spec.ApprovedDestination`.  This is a documented scope
boundary, not a gap: it is covered by P-CONSOLIDATION-ETH-1's source map
at `_callAddWithdrawalRequest` (WithdrawalVaultEIP7685.sol L103–111).
-/

namespace LidoSRv3.Audit.Model.EthWorld

open LidoSRv3.Audit.Spec

/-! ## Value route inventory -/

/-- Every pinned in-scope positive-value Solidity route.  Each constructor
corresponds to a distinct value-bearing external call site in the pinned
source `lidofinance/core@af095e48`. -/
inductive ValueRoute where
  | depositLidoPull
  | depositBeaconDeposit
  | topupLidoPull
  | topupBeaconDeposit
  | consolidationFee
  | consolidationRefund
  | vaultConsolidationCall
  | vaultWithdrawalCall
  | vaultToLido
  | vaultToWithdrawalQueue
  deriving DecidableEq, Repr, Inhabited

/-! ## Destination classification -/

/-- Unified destination for all modeled ETH-bearing call sites.  Seven
constructors cover every target contract or predeploy in the inventory. -/
inductive Destination where
  | lidoPull
  | beaconDeposit
  | consolidationPredeploy
  | withdrawalPredeploy
  | refundRecipient
  | vaultToLido
  | vaultToWithdrawalQueue
  deriving DecidableEq, Repr

/-- Map each value route to its target destination. -/
def ValueRoute.destination : ValueRoute → Destination
  | .depositLidoPull        => .lidoPull
  | .depositBeaconDeposit   => .beaconDeposit
  | .topupLidoPull          => .lidoPull
  | .topupBeaconDeposit     => .beaconDeposit
  | .consolidationFee       => .consolidationPredeploy
  | .consolidationRefund    => .refundRecipient
  | .vaultConsolidationCall => .consolidationPredeploy
  | .vaultWithdrawalCall    => .withdrawalPredeploy
  | .vaultToLido            => .vaultToLido
  | .vaultToWithdrawalQueue => .vaultToWithdrawalQueue

/-- Project a destination to `Spec.ApprovedDestination` where one exists.
The withdrawal-request predeploy (EIP-7002) maps to `none`: it is approved
by P-CONSOLIDATION-ETH-1's abstract `parentApproved` predicate but does not
have its own `Spec.ApprovedDestination` constructor. -/
def Destination.toSpec : Destination → Option ApprovedDestination
  | .lidoPull               => some .lidoPull
  | .beaconDeposit          => some .beaconDeposit
  | .consolidationPredeploy => some .consolidationRequest
  | .withdrawalPredeploy    => none
  | .refundRecipient        => some .refundRecipient
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

/-- Primary covering parent for each route.  Routes may be covered by
additional parents (listed in the module-level table); this records the
tightest binding. -/
def ValueRoute.primaryParent : ValueRoute → CoveringParent
  | .depositLidoPull        => .pDepositOne
  | .depositBeaconDeposit   => .pDepositOne
  | .topupLidoPull          => .pTopupOne
  | .topupBeaconDeposit     => .pTopupOne
  | .consolidationFee       => .pConsolidationEthOne
  | .consolidationRefund    => .pConsolidationEthOne
  | .vaultConsolidationCall => .pConsolidationValueOne
  | .vaultWithdrawalCall    => .pConsolidationEthOne
  | .vaultToLido            => .pVaultEthOne
  | .vaultToWithdrawalQueue => .pVaultEthOne

/-! ## Spec-layer coverage -/

/-- Every `Spec.ApprovedDestination` is reachable from at least one
modeled value route.  This does not widen the Spec type; it witnesses
surjectivity of the existing constructors. -/
theorem spec_destination_surjective (d : ApprovedDestination) :
    ∃ r : ValueRoute, r.destination.toSpec = some d := by
  cases d with
  | consolidationRequest  => exact ⟨.consolidationFee, rfl⟩
  | refundRecipient       => exact ⟨.consolidationRefund, rfl⟩
  | beaconDeposit         => exact ⟨.depositBeaconDeposit, rfl⟩
  | lidoPull              => exact ⟨.depositLidoPull, rfl⟩
  | vaultToLido           => exact ⟨.vaultToLido, rfl⟩
  | vaultToWithdrawalQueue => exact ⟨.vaultToWithdrawalQueue, rfl⟩

/-- The single destination not in `Spec.ApprovedDestination` is the
EIP-7002 withdrawal-request predeploy. -/
theorem withdrawal_predeploy_outside_spec :
    Destination.toSpec .withdrawalPredeploy = none := rfl

/-- All other destinations project into the Spec layer. -/
theorem non_withdrawal_destinations_in_spec (d : Destination)
    (h : d ≠ .withdrawalPredeploy) :
    (Destination.toSpec d).isSome = true := by
  cases d <;> simp_all [Destination.toSpec]

/-! ## Inventory enumeration -/

def allRoutes : List ValueRoute :=
  [ .depositLidoPull, .depositBeaconDeposit
  , .topupLidoPull, .topupBeaconDeposit
  , .consolidationFee, .consolidationRefund
  , .vaultConsolidationCall, .vaultWithdrawalCall
  , .vaultToLido, .vaultToWithdrawalQueue ]

def allUnsupportedRoutes : List UnsupportedRoute :=
  [ .ownerWithdrawal, .stVaultInternal, .valueBoundedExit
  , .governanceLifecycle, .fallbackReceive, .treasuryMint ]

theorem inventory_count : allRoutes.length = 10 := rfl

theorem unsupported_count : allUnsupportedRoutes.length = 6 := rfl

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
owner, treasury, and ops values are set to zero.  This demonstrates that
the unmodeled paths carry no load-bearing value for the inventory. -/
def zeroUnmodeled : GeneralFlow → GeneralFlow
  | .authorized f         => .authorized f
  | .ownerWithdrawal r _  => .ownerWithdrawal r 0
  | .treasuryMint _       => .treasuryMint 0
  | .opsTransfer _        => .opsTransfer 0

/-- Extract authorized frames from a mixed flow list.  Unmodeled flows
contribute nothing to the inventory. -/
def authorizedFrames : List GeneralFlow → List AuthorizedValueFrame
  | []                          => []
  | .authorized f :: rest       => f :: authorizedFrames rest
  | .ownerWithdrawal _ _ :: rest => authorizedFrames rest
  | .treasuryMint _ :: rest     => authorizedFrames rest
  | .opsTransfer _ :: rest      => authorizedFrames rest

/-- **Owner/treasury/ops mutant preservation.**  Zeroing all non-modeled
values does not affect the authorized frame list.  This proves that owner
withdrawals, treasury mints, and ops transfers are non-load-bearing for
the ETH-world inventory. -/
theorem zeroUnmodeled_preserves_inventory : ∀ (flows : List GeneralFlow),
    authorizedFrames (flows.map zeroUnmodeled) = authorizedFrames flows
  | [] => rfl
  | .authorized f :: rest => by
      show f :: authorizedFrames (rest.map zeroUnmodeled) =
           f :: authorizedFrames rest
      rw [zeroUnmodeled_preserves_inventory rest]
  | .ownerWithdrawal _ _ :: rest =>
      zeroUnmodeled_preserves_inventory rest
  | .treasuryMint _ :: rest =>
      zeroUnmodeled_preserves_inventory rest
  | .opsTransfer _ :: rest =>
      zeroUnmodeled_preserves_inventory rest

/-- Total value of authorized frames. -/
def inventoryValue (flows : List GeneralFlow) : Nat :=
  (authorizedFrames flows).foldl (fun acc f => acc + f.value) 0

/-- The mutant also preserves total inventory value. -/
theorem zeroUnmodeled_preserves_value (flows : List GeneralFlow) :
    inventoryValue (flows.map zeroUnmodeled) = inventoryValue flows := by
  unfold inventoryValue
  rw [zeroUnmodeled_preserves_inventory]

end LidoSRv3.Audit.Model.EthWorld
