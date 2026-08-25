import LidoSRv3.Audit.Model.EthWorld

/-!
# ETH-world inventory mutant tests

Concrete witnesses demonstrating that the owner/treasury/ops mutant
preserves the modeled inventory and that the inventory is non-vacuous.

Every test is discharged by `native_decide` over a concrete flow list
that mixes authorized frames with owner, treasury, and ops transfers
at non-trivial values.
-/

namespace LidoSRv3.Tests.EthWorldMutants

open LidoSRv3.Audit.Model.EthWorld

/-! ## Witness flow list -/

private def witnessFlows : List GeneralFlow :=
  [ .authorized ⟨.consolidationFee, 3⟩
  , .ownerWithdrawal 42 100
  , .authorized ⟨.vaultToLido, 7⟩
  , .treasuryMint 50
  , .authorized ⟨.depositBeaconDeposit, 32⟩
  , .opsTransfer 25 ]

/-! ## Non-vacuity: authorized frames are present -/

theorem witness_has_authorized_frames :
    (authorizedFrames witnessFlows).length = 3 := by native_decide

/-! ## Mutant witness: zeroing preserves frames -/

theorem witness_mutant_preserves_frames :
    authorizedFrames (witnessFlows.map zeroUnmodeled) =
      authorizedFrames witnessFlows := by native_decide

theorem witness_mutant_frames_concrete :
    authorizedFrames (witnessFlows.map zeroUnmodeled) =
      [ ⟨.consolidationFee, 3⟩
      , ⟨.vaultToLido, 7⟩
      , ⟨.depositBeaconDeposit, 32⟩ ] := by native_decide

/-! ## Mutant witness: zeroing eliminates non-modeled value -/

private def totalUnmodeledValue : List GeneralFlow → Nat
  | [] => 0
  | .ownerWithdrawal _ v :: rest => v + totalUnmodeledValue rest
  | .treasuryMint v :: rest => v + totalUnmodeledValue rest
  | .opsTransfer v :: rest => v + totalUnmodeledValue rest
  | _ :: rest => totalUnmodeledValue rest

theorem witness_has_unmodeled_value :
    totalUnmodeledValue witnessFlows = 175 := by native_decide

theorem witness_mutant_zeroes_unmodeled :
    totalUnmodeledValue (witnessFlows.map zeroUnmodeled) = 0 := by native_decide

/-! ## Value preservation: inventory total unchanged -/

theorem witness_inventory_value :
    inventoryValue witnessFlows = 42 := by native_decide

theorem witness_mutant_inventory_value :
    inventoryValue (witnessFlows.map zeroUnmodeled) = 42 := by native_decide

/-! ## Route coverage: every route is inhabited by a positive-value frame -/

private def routeWitness : ValueRoute → AuthorizedValueFrame
  | .depositLidoPull        => ⟨.depositLidoPull, 32⟩
  | .depositBeaconDeposit   => ⟨.depositBeaconDeposit, 32⟩
  | .topupLidoPull          => ⟨.topupLidoPull, 1⟩
  | .topupBeaconDeposit     => ⟨.topupBeaconDeposit, 1⟩
  | .consolidationFee       => ⟨.consolidationFee, 3⟩
  | .consolidationRefund    => ⟨.consolidationRefund, 7⟩
  | .vaultConsolidationCall => ⟨.vaultConsolidationCall, 1⟩
  | .vaultWithdrawalCall    => ⟨.vaultWithdrawalCall, 1⟩
  | .vaultToLido            => ⟨.vaultToLido, 10⟩
  | .vaultToWithdrawalQueue => ⟨.vaultToWithdrawalQueue, 5⟩

theorem every_route_positive :
    ∀ r : ValueRoute, (routeWitness r).isPositive := by
  intro r; cases r <;> decide

theorem every_route_witness_matches :
    ∀ r : ValueRoute, (routeWitness r).route = r := by
  intro r; cases r <;> rfl

/-! ## Destination classification is total -/

theorem every_route_has_destination :
    ∀ r : ValueRoute, ∃ d : Destination, r.destination = d := by
  intro r; exact ⟨r.destination, rfl⟩

/-! ## Parent coverage is total -/

theorem every_route_has_parent :
    ∀ r : ValueRoute, ∃ p : CoveringParent, r.primaryParent = p := by
  intro r; exact ⟨r.primaryParent, rfl⟩

end LidoSRv3.Tests.EthWorldMutants
