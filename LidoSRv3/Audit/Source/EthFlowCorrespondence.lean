import Contracts.Common
import Verity.Core
import Verity.EVM.Uint256
import Verity.Macro
import Verity.Stdlib.Math

namespace LidoSRv3.Audit.SolidityEthFlow

open Verity
open Verity.EVM.Uint256
open Verity.Stdlib.Math
open Contracts

/-!
# P-ETH-1 pinned-source route

This module transcribes the value-routing suffix of `lidofinance/core` at
`af095e48bbc1c3841c2c9936219c8461af01056b`:

* `ConsolidationBus.executeConsolidation`, lines 383--406;
* `ConsolidationGateway.addConsolidationRequests`, lines 185--223;
* `ConsolidationGateway._checkFee`, lines 286--293;
* `ConsolidationGateway._refundFee`, lines 295--307; and
* `WithdrawalVault.addConsolidationRequests`, lines 199--208, together with
  `WithdrawalVaultEIP7685._addConsolidationRequests`, lines 56--73.

The cryptographic witness checks, request-limit accounting, dynamic-array
flattening, deployment addresses, and callee implementations are explicitly
outside this writer.  They are named assumptions below, not silent premises.
The proved property is exact value conservation and refund-recipient selection
for a handwritten bounded route model, plus snapshot rollback for every
represented failure. The declared Verity contract below is a compiler-surface
scaffold only: the proof-facing interpreter does not execute its linked
external calls. Fee-target confinement, generated-code correspondence, and
runtime-bytecode equivalence remain open.
-/

abbrev Word := Verity.Core.Uint256

structure ScopeAssumptions where
  /-- A-SOURCE-GROUP-COUNT: the preceding source loops compute this count. -/
  sourceGroupCount : Prop
  /-- A-VALIDATED-PAIRS: witness validation and flattening preserve that count. -/
  validatedPairs : Prop
  /-- A-REQUEST-TARGET-PROVENANCE: the vault immutable denotes EIP-7251. -/
  requestTargetProvenance : Prop

structure Route where
  vaultValue : Word
  refundValue : Word
  refundRecipient : Address
  deriving DecidableEq, Repr

inductive SourceOutcome where
  | reverted (reason : String)
  | committed (route : Route)
  deriving DecidableEq, Repr

def effectiveRefundRecipient (sender requested : Address) : Address :=
  if requested = 0 then sender else requested

/-- Independent source-shaped interpreter for the five pinned spans. -/
def sourceRoute (sender : Address) (msgValue requestsCount fee : Word)
    (requestedRefund : Address) : SourceOutcome :=
  if msgValue = 0 then .reverted "ZERO_MSG_VALUE"
  else if requestsCount = 0 then .reverted "ZERO_GROUPS"
  else match safeMul requestsCount fee with
    | none => .reverted "FEE_OVERFLOW"
    | some totalFee =>
        if msgValue < totalFee then .reverted "INSUFFICIENT_FEE"
        else .committed
          { vaultValue := totalFee
            refundValue := msgValue - totalFee
            refundRecipient := effectiveRefundRecipient sender requestedRefund }

verity_contract EthRouteContract where
  storage
    routedVaultValue : Uint256 := slot 0
    routedRefundValue : Uint256 := slot 1
    routedRefundRecipient : Address := slot 2

  linked_externals
    external submitConsolidation(Uint256, Uint256)
    external refund(Uint256, Uint256)

  function allow_post_interaction_writes reentrancy_trusted route
      (requestsCount : Uint256, fee : Uint256, effectiveRecipient : Address,
       requestTarget : Address) : Unit := do
    let supplied ← msgValue
    require (supplied != 0) "ZERO_MSG_VALUE"
    require (requestsCount != 0) "ZERO_GROUPS"
    let totalFee ← requireSomeUint (safeMul requestsCount fee) "FEE_OVERFLOW"
    require (totalFee ≤ supplied) "INSUFFICIENT_FEE"
    let refundValue := supplied - totalFee
    externalCallBind [] "submitConsolidation" [addressToWord requestTarget, totalFee]
    externalCallBind [] "refund" [addressToWord effectiveRecipient, refundValue]
    setStorage routedVaultValue totalFee
    setStorage routedRefundValue refundValue
    setStorageAddr routedRefundRecipient effectiveRecipient

def decodeRoute (state : ContractState) : Route :=
  { vaultValue := state.storage EthRouteContract.routedVaultValue.slot
    refundValue := state.storage EthRouteContract.routedRefundValue.slot
    refundRecipient := state.storageAddr EthRouteContract.routedRefundRecipient.slot }

/-- Handwritten abstract transaction model for the bounded route. It deliberately
does not execute `EthRouteContract.route` or its `externalCallBind` operations,
so it supplies no VERITY_TX or fee-target-confinement evidence. -/
def abstractRouteExec (count fee : Word) (recipient : Address) : Contract Unit :=
  fun state =>
    match sourceRoute state.sender state.msgValue count fee recipient with
    | .reverted reason => .revert reason state
    | .committed route =>
        .success ()
          ((state.writeSlot EthRouteContract.routedVaultValue.slot route.vaultValue)
            |>.writeSlot EthRouteContract.routedRefundValue.slot route.refundValue
            |>.writeAddrSlot EthRouteContract.routedRefundRecipient.slot route.refundRecipient)

inductive TxOutcome where | committed | reverted
  deriving DecidableEq, Repr

structure TxObservation where
  outcome : TxOutcome
  before : Route
  after : Route
  deriving DecidableEq, Repr

def observe (before : ContractState) (result : ContractResult Unit) : TxObservation :=
  match result with
  | .revert _ rollback => ⟨.reverted, decodeRoute before, decodeRoute rollback⟩
  | .success _ after => ⟨.committed, decodeRoute before, decodeRoute after⟩

/-- P-ETH-1 MODEL/SOURCE theorem: no successful wei is lost or duplicated. -/
theorem source_route_conserves (sender : Address) (value count fee : Word)
    (recipient : Address) (route : Route)
    (h : sourceRoute sender value count fee recipient = .committed route) :
    route.vaultValue.val + route.refundValue.val = value.val := by
  simp only [sourceRoute] at h
  split at h <;> try contradiction
  split at h <;> try contradiction
  split at h <;> try contradiction
  split at h <;> try contradiction
  next totalFee hmul hfee =>
    cases h
    rw [Verity.Core.Uint256.sub_eq_of_le (Nat.le_of_not_gt hfee)]
    exact Nat.add_sub_of_le (Nat.le_of_not_gt hfee)

/-- The source-shaped model selects the explicit refund recipient, falling back
to the sender when that recipient is zero. The model does not observe or
constrain the separate fee-bearing call target. -/
theorem source_refund_recipient_matches (sender : Address) (value count fee : Word)
    (recipient : Address) (route : Route)
    (h : sourceRoute sender value count fee recipient = .committed route) :
    route.refundRecipient = effectiveRefundRecipient sender recipient := by
  simp only [sourceRoute] at h
  split at h <;> try contradiction
  split at h <;> try contradiction
  split at h <;> try contradiction
  split at h <;> try contradiction
  next totalFee hmul hfee => cases h; rfl

/-- Abstract-model rollback: all represented rejects restore the complete
pre-call state, not merely the three route slots. -/
theorem abstract_route_revert_rolls_back (state rollback : ContractState)
    (count fee : Word) (recipient : Address) (reason : String)
    (h : (abstractRouteExec count fee recipient).run state =
      .revert reason rollback) : rollback = state := by
  simp [abstractRouteExec, Contract.run] at h
  split at h <;> simp_all

/-- A successful abstract route-model transition writes exactly the
source-shaped route. This is not execution of the declared Verity function. -/
theorem abstract_route_success_matches_source (state after : ContractState)
    (count fee : Word) (recipient : Address)
    (h : (abstractRouteExec count fee recipient).run state =
      .success () after) :
    sourceRoute state.sender state.msgValue count fee recipient =
      .committed (decodeRoute after) := by
  cases hs : sourceRoute state.sender state.msgValue count fee recipient with
  | reverted reason => simp [abstractRouteExec, Contract.run, hs] at h
  | committed route =>
      simp [abstractRouteExec, Contract.run, hs] at h
      subst after
      have hSlots : EthRouteContract.routedVaultValue.slot ≠
          EthRouteContract.routedRefundValue.slot := by decide
      simpa [decodeRoute, ContractState.writeSlot, ContractState.writeAddrSlot,
        hSlots] using hs

end LidoSRv3.Audit.SolidityEthFlow
