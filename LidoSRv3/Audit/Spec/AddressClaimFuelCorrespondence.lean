import LidoSRv3.Audit.Verity.AddressClaimBatchTx

/-!
# Fuel-bounded live claim-batch correspondence

This module gives the live `claimWithdrawalsTo` loop a list-inductive
precondition.  Each constructor checks one request against the state produced
by the preceding constructor, so the predicate covers every request and hint
in the batch rather than only fixed numeral witnesses.

Recipient-renaming equivariance remains open in this slice. The registered
parent is the payout-equals-entry-read correspondence below; it does not
replace that gap with a vacuous proposition.
-/

namespace LidoSRv3.Audit.Spec.AddressClaimFuelCorrespondence

open LidoSRv3.Audit.Verity.AddressClaimBatchTx
open _root_.Verity
open _root_.Verity.EVM.Uint256
open Contracts

/-- The exact successful state transition of one live `_claim` iteration. -/
def claimSuccessState (state : ContractState) (requestId payout : Nat)
    (recipient : Address) : ContractState :=
  let dirty :=
    (state.writeMapUint (queuePosition + 1) (.ofNat requestId)
      (markClaimed (requestMetadataWord state requestId))).writeSlot
        lockedEtherAmountPosition
        (.ofNat ((state.readSlot lockedEtherAmountPosition).val - payout))
  { dirty with
    selfBalance := dirty.selfBalance - .ofNat payout
    calls := dirty.calls ++ [payoutEntry recipient payout] }

/-- Guard-complete well-formedness for one request in the live loop. -/
structure ClaimReady (state : ContractState) (requestId hint payout : Nat) : Prop where
  requestId_ne_zero : requestId ≠ 0
  finalized :
    requestId ≤ (state.readSlot lastFinalizedRequestIdPosition).val
  unclaimed : (readRequest state requestId hint).claimed = false
  owned : (readRequest state requestId hint).owner = state.sender
  hint_ne_zero : hint ≠ 0
  hint_in_range : hint ≤ (state.readSlot lastCheckpointIndexPosition).val
  checkpoint_starts_before :
    (readRequest state requestId hint).checkpointFrom ≤ requestId
  checkpoint_ends_after :
    ¬ (hint < (state.readSlot lastCheckpointIndexPosition).val ∧
      (checkpointFromWord state (hint + 1)).val ≤ requestId)
  steth_monotone :
    (readRequest state requestId hint).previousCumulativeStETH ≤
      (readRequest state requestId hint).cumulativeStETH
  shares_monotone :
    (readRequest state requestId hint).previousCumulativeShares ≤
      (readRequest state requestId hint).cumulativeShares
  payout_read :
    claimableEther (readRequest state requestId hint) = some payout
  mark_sets_claimed :
    requestClaimed (markClaimed (requestMetadataWord state requestId)) = true
  locked_funded :
    payout ≤ (state.readSlot lockedEtherAmountPosition).val
  balance_funded : (.ofNat payout : Uint256) ≤ state.selfBalance

/-- One guard-complete request takes exactly the successful storage/CALL step. -/
theorem claimOne_of_ready (state : ContractState) (requestId hint payout : Nat)
    (recipient : Address) (h : ClaimReady state requestId hint payout) :
    claimOne requestId hint recipient state =
      .success () (claimSuccessState state requestId payout recipient) := by
  rcases h with
    ⟨hid, hfinal, hunclaimed, howner, hhint, hhintLast, hfrom, hnext,
      hsteth, hshares, hpayout, hmarked, hlocked, hbalance⟩
  have hfinal' :
      ¬ (state.readSlot lastFinalizedRequestIdPosition).val < requestId := by
    omega
  have hhintLast' :
      ¬ (state.readSlot lastCheckpointIndexPosition).val < hint := by
    omega
  have hfrom' : ¬ requestId < (readRequest state requestId hint).checkpointFrom := by
    omega
  have hsteth' :
      ¬ (readRequest state requestId hint).cumulativeStETH <
        (readRequest state requestId hint).previousCumulativeStETH := by
    omega
  have hshares' :
      ¬ (readRequest state requestId hint).cumulativeShares <
        (readRequest state requestId hint).previousCumulativeShares := by
    omega
  have hlocked' :
      ¬ (state.readSlot lockedEtherAmountPosition).val < payout := by
    omega
  have hbalance' : payout % Core.Uint256.modulus ≤ state.selfBalance.val := hbalance
  simp only [claimOne]
  simp [hid, hfinal', hunclaimed, howner, hhint, hhintLast', hfrom', hnext,
    hsteth', hshares', hpayout, hlocked', hbalance', claimSuccessState,
    externalCallBindTo, payoutEntry, externalCallStubSuccess,
    ContractState.writeMapUint]

/-- A successful, guard-complete batch, indexed by its storage-derived payouts. -/
inductive BatchReady : ContractState → List Nat → List Nat → Address → List Nat → Prop
  | nil (state recipient) : BatchReady state [] [] recipient []
  | cons {state recipient requestId hint payout requestIds hints payouts}
      (head : ClaimReady state requestId hint payout)
      (tail : BatchReady (claimSuccessState state requestId payout recipient)
        requestIds hints recipient payouts) :
      BatchReady state (requestId :: requestIds) (hint :: hints) recipient
        (payout :: payouts)

theorem BatchReady.lengths {state requestIds hints recipient payouts}
    (h : BatchReady state requestIds hints recipient payouts) :
    requestIds.length = hints.length ∧ requestIds.length = payouts.length := by
  induction h with
  | nil => simp
  | cons _ _ ih =>
      constructor
      · simpa using congrArg Nat.succ ih.1
      · simpa using congrArg Nat.succ ih.2

/-- Apply an indexed payout trace to the pure successful-step transformer. -/
def batchSuccessState : ContractState → List Nat → List Nat → Address → ContractState
  | state, requestId :: requestIds, payout :: payouts, recipient =>
      batchSuccessState (claimSuccessState state requestId payout recipient)
        requestIds payouts recipient
  | state, _, _, _ => state

/-- Source-side pre-state reads, kept in request/hint order. -/
def sourcePayouts : ContractState → List Nat → List Nat → List (Option Nat)
  | state, requestId :: requestIds, hint :: hints =>
      claimableEther (readRequest state requestId hint) ::
        sourcePayouts state requestIds hints
  | _, _, _ => []

/-- A successful claim changes no later request read when its encoded key is
distinct. -/
theorem readRequest_claimSuccessState_other (state : ContractState)
    (requestId payout otherId hint : Nat) (recipient : Address)
    (hkey : (.ofNat otherId : Uint256) ≠ .ofNat requestId) :
    readRequest (claimSuccessState state requestId payout recipient) otherId hint =
      readRequest state otherId hint := by
  have hcheckpointQueue :
      checkpointsPosition ≠ queuePosition := by decide
  have hcheckpointMetadata :
      checkpointsPosition ≠ queuePosition + 1 := by decide
  simp [readRequest, requestAmountsWord, requestMetadataWord,
    checkpointFromWord, checkpointRateWord, claimSuccessState,
    ContractState.readMapUint, ContractState.storageMapUint,
    ContractState.writeMapUint, hkey, hcheckpointQueue, hcheckpointMetadata,
    ContractState.writeSlot]

theorem sourcePayouts_claimSuccessState_other (state : ContractState)
    (requestId payout : Nat) (recipient : Address) (requestIds hints : List Nat)
    (hkeys : ∀ otherId ∈ requestIds,
      (.ofNat otherId : Uint256) ≠ .ofNat requestId) :
    sourcePayouts (claimSuccessState state requestId payout recipient)
        requestIds hints =
      sourcePayouts state requestIds hints := by
  induction requestIds generalizing hints with
  | nil => simp [sourcePayouts]
  | cons otherId requestIds ih =>
      cases hints with
      | nil => simp [sourcePayouts]
      | cons hint hints =>
          simp only [sourcePayouts]
          rw [readRequest_claimSuccessState_other state requestId payout otherId
            hint recipient (hkeys otherId (by simp))]
          rw [ih hints (by
            intro item hmem
            exact hkeys item (by simp [hmem]))]

/-- Distinct encoded request keys make every indexed payout equal the
corresponding `claimableEther` read from the entry snapshot. -/
theorem BatchReady.source_payouts {state requestIds hints recipient payouts}
    (h : BatchReady state requestIds hints recipient payouts)
    (hnodup : (requestIds.map fun id => (.ofNat id : Uint256)).Nodup) :
    sourcePayouts state requestIds hints = payouts.map some := by
  induction h with
  | nil => rfl
  | @cons state recipient requestId hint payout requestIds hints payouts head tail ih =>
      simp only [sourcePayouts, List.map_cons]
      rw [head.payout_read]
      have htail :
          (requestIds.map fun id => (.ofNat id : Uint256)).Nodup := by
        simpa using hnodup.tail
      rw [← sourcePayouts_claimSuccessState_other state requestId payout recipient
        requestIds hints]
      · exact congrArg (List.cons (some payout)) (ih htail)
      · intro otherId hmem hEq
        exact hnodup.notMem (List.mem_map.mpr ⟨otherId, hmem, hEq⟩)

/-- The pure successful trace appends exactly the storage-derived payout CALLs. -/
theorem BatchReady.final_calls {state requestIds hints recipient payouts}
    (h : BatchReady state requestIds hints recipient payouts) :
    (batchSuccessState state requestIds payouts recipient).calls =
      state.calls ++ payouts.map (payoutEntry recipient) := by
  induction h with
  | nil => simp [batchSuccessState]
  | @cons state recipient requestId hint payout requestIds hints payouts head tail ih =>
      change
        (batchSuccessState (claimSuccessState state requestId payout recipient)
          requestIds payouts recipient).calls =
        state.calls ++ payoutEntry recipient payout ::
          payouts.map (payoutEntry recipient)
      rw [ih]
      have hcalls :
          (state.writeMapUint (queuePosition + 1) (.ofNat requestId)
            (markClaimed (requestMetadataWord state requestId))).calls =
            state.calls := rfl
      simp [claimSuccessState, List.append_assoc, hcalls]

theorem claimSuccessState_locked (state : ContractState) (requestId payout : Nat)
    (recipient : Address) :
    ((claimSuccessState state requestId payout recipient).readSlot
      lockedEtherAmountPosition).val =
        (state.readSlot lockedEtherAmountPosition).val - payout := by
  have hlt :
      (state.readSlot lockedEtherAmountPosition).val - payout <
        Core.Uint256.modulus :=
    Nat.lt_of_le_of_lt (Nat.sub_le _ _) (state.readSlot _).isLt
  have hlt' :
      (state.storageWords (.slot lockedEtherAmountPosition)).val - payout <
        Core.Uint256.modulus := by
    simpa [ContractState.readSlot, ContractState.storage] using hlt
  simp [claimSuccessState, ContractState.readSlot, ContractState.storage,
    ContractState.writeSlot, ContractState.writeMapUint,
    Core.Uint256.val_ofNat, Nat.mod_eq_of_lt hlt']

/-- Locked ETH decreases by the sum of all storage-derived payouts. -/
theorem BatchReady.final_locked {state requestIds hints recipient payouts}
    (h : BatchReady state requestIds hints recipient payouts) :
    ((batchSuccessState state requestIds payouts recipient).readSlot
      lockedEtherAmountPosition).val =
        (state.readSlot lockedEtherAmountPosition).val - payouts.sum := by
  induction h with
  | nil => simp [batchSuccessState]
  | @cons state recipient requestId hint payout requestIds hints payouts head tail ih =>
      change
        ((batchSuccessState (claimSuccessState state requestId payout recipient)
          requestIds payouts recipient).readSlot lockedEtherAmountPosition).val =
        (state.readSlot lockedEtherAmountPosition).val -
          (payout :: payouts).sum
      rw [ih, claimSuccessState_locked]
      simp [Nat.sub_sub]

theorem claimSuccessState_marks (state : ContractState) (requestId payout : Nat)
    (recipient : Address)
    (hmarked :
      requestClaimed (markClaimed (requestMetadataWord state requestId)) = true) :
    requestClaimed
        (requestMetadataWord
          (claimSuccessState state requestId payout recipient) requestId) =
      true := by
  simp [claimSuccessState, requestMetadataWord, ContractState.readMapUint,
    ContractState.storageMapUint, ContractState.writeMapUint]
  simpa [requestMetadataWord, ContractState.readMapUint,
    ContractState.storageMapUint] using hmarked

theorem requestClaimed_claimSuccessState_other (state : ContractState)
    (requestId payout otherId : Nat) (recipient : Address)
    (hkey : (.ofNat otherId : Uint256) ≠ .ofNat requestId) :
    requestClaimed
        (requestMetadataWord
          (claimSuccessState state requestId payout recipient) otherId) =
      requestClaimed (requestMetadataWord state otherId) := by
  have hread :=
    congrArg RequestRead.claimed
      (readRequest_claimSuccessState_other state requestId payout otherId 0
        recipient hkey)
  simpa [readRequest] using hread

theorem requestClaimed_batchSuccessState_other (state : ContractState)
    (requestIds payouts : List Nat) (recipient : Address) (otherId : Nat)
    (hkeys : ∀ requestId ∈ requestIds,
      (.ofNat otherId : Uint256) ≠ .ofNat requestId) :
    requestClaimed
        (requestMetadataWord
          (batchSuccessState state requestIds payouts recipient) otherId) =
      requestClaimed (requestMetadataWord state otherId) := by
  induction requestIds generalizing state payouts with
  | nil => simp [batchSuccessState]
  | cons requestId requestIds ih =>
      cases payouts with
      | nil => simp [batchSuccessState]
      | cons payout payouts =>
          simp only [batchSuccessState]
          rw [ih (claimSuccessState state requestId payout recipient) payouts
            (by
              intro item hmem
              exact hkeys item (by simp [hmem]))]
          exact requestClaimed_claimSuccessState_other state requestId payout
            otherId recipient (hkeys requestId (by simp))

/-- Every distinct request key is marked claimed in the final live-loop state. -/
theorem BatchReady.final_claimed {state requestIds hints recipient payouts}
    (h : BatchReady state requestIds hints recipient payouts)
    (hnodup : (requestIds.map fun id => (.ofNat id : Uint256)).Nodup) :
    requestIds.map
        (fun id =>
          requestClaimed
            (requestMetadataWord
              (batchSuccessState state requestIds payouts recipient) id)) =
      List.replicate requestIds.length true := by
  induction h with
  | nil => rfl
  | @cons state recipient requestId hint payout requestIds hints payouts head tail ih =>
      have htail :
          (requestIds.map fun id => (.ofNat id : Uint256)).Nodup := by
        simpa using hnodup.tail
      have hheadKey : ∀ item ∈ requestIds,
          (.ofNat requestId : Uint256) ≠ .ofNat item := by
        intro item hmem hEq
        exact hnodup.notMem
          (List.mem_map.mpr ⟨item, hmem, hEq.symm⟩)
      change
        requestClaimed
            (requestMetadataWord
              (batchSuccessState
                (claimSuccessState state requestId payout recipient)
                requestIds payouts recipient) requestId) ::
          requestIds.map
            (fun id =>
              requestClaimed
                (requestMetadataWord
                  (batchSuccessState
                    (claimSuccessState state requestId payout recipient)
                    requestIds payouts recipient) id)) =
        true :: List.replicate requestIds.length true
      congr 1
      · rw [requestClaimed_batchSuccessState_other
          (claimSuccessState state requestId payout recipient)
          requestIds payouts recipient requestId hheadKey]
        exact claimSuccessState_marks state requestId payout recipient
          head.mark_sets_claimed
      · exact ih htail

/-- The recursive predicate executes the actual live loop to its indexed state. -/
theorem claimLoop_of_ready {state requestIds hints recipient payouts}
    (h : BatchReady state requestIds hints recipient payouts) :
    claimLoop requestIds hints recipient state =
      .success () (batchSuccessState state requestIds payouts recipient) := by
  induction h with
  | nil => rfl
  | @cons state recipient requestId hint payout requestIds hints payouts head tail ih =>
      change
        _root_.Verity.bind (claimOne requestId hint recipient)
            (fun _ => claimLoop requestIds hints recipient) state =
          .success ()
            (batchSuccessState (claimSuccessState state requestId payout recipient)
              requestIds payouts recipient)
      unfold _root_.Verity.bind
      rw [claimOne_of_ready state requestId hint payout recipient head]
      exact ih

/-- Guard-complete batches run through the actual external entrypoint. -/
theorem execute_of_ready {state requestIds hints recipient payouts}
    (h : BatchReady state requestIds hints recipient payouts)
    (hrecipient : recipient ≠ zeroAddress) :
    (executeClaimWithdrawalsTo requestIds hints recipient).run state =
      .success () (batchSuccessState state requestIds payouts recipient) := by
  have hlength := h.lengths.1
  have hrecipient' : recipient ≠ (0 : Address) := by
    simpa [zeroAddress] using hrecipient
  change
    (_root_.Verity.bind
      (_root_.Verity.require (recipient != zeroAddress) "ZeroRecipient")
      (fun _ =>
        _root_.Verity.bind
          (_root_.Verity.require (requestIds.length == hints.length)
            "ArraysLengthMismatch")
          (fun _ => claimLoop requestIds hints recipient))).run state =
      .success () (batchSuccessState state requestIds payouts recipient)
  unfold Contract.run _root_.Verity.bind _root_.Verity.require
  simp [hrecipient', hlength, claimLoop_of_ready h]

/-- Fuel-bounded source/observe correspondence for the live
`executeClaimWithdrawalsTo` loop.

The theorem is universal over request and hint lists. `BatchReady` is the
well-formed pre-state predicate: every constructor retains the live guards for
one unclaimed finalized request, its valid hint, its storage-derived payout,
and both locked-ETH and account-balance funding checks. Distinct encoded keys
ensure later claimed writes do not change any entry-snapshot read. -/
theorem fuel_bounded_live_claim_batch_correspondence
    (fuel : Nat) (state : ContractState) (requestIds hints payouts : List Nat)
    (recipient : Address)
    (hfuel : requestIds.length ≤ fuel)
    (hlength : requestIds.length = hints.length)
    (hnodup : (requestIds.map fun id => (.ofNat id : Uint256)).Nodup)
    (hready : BatchReady state requestIds hints recipient payouts)
    (hrecipient : recipient ≠ zeroAddress) :
    sourcePayouts state requestIds hints = payouts.map some ∧
      observe requestIds
          ((executeClaimWithdrawalsTo requestIds hints recipient).run state) =
        ⟨.committed, List.replicate requestIds.length true,
          (state.readSlot lockedEtherAmountPosition).val - payouts.sum,
          state.calls ++ payouts.map (payoutEntry recipient)⟩ := by
  have _ := hfuel
  have _ := hlength
  constructor
  · exact hready.source_payouts hnodup
  · rw [execute_of_ready hready hrecipient]
    change
      (⟨.committed,
        requestIds.map
          (fun id =>
            requestClaimed
              (requestMetadataWord
                (batchSuccessState state requestIds payouts recipient) id)),
        ((batchSuccessState state requestIds payouts recipient).readSlot
          lockedEtherAmountPosition).val,
        (batchSuccessState state requestIds payouts recipient).calls⟩ : View) =
      _
    rw [hready.final_claimed hnodup, hready.final_locked, hready.final_calls]

/-- Existing transaction-boundary rollback, re-exported rather than re-proved. -/
theorem every_revert_restores_snapshot (requestIds hints : List Nat)
    (recipient : Address) (state rollback : ContractState) (reason : String)
    (h : (executeClaimWithdrawalsTo requestIds hints recipient).run state =
      .revert reason rollback) : rollback = state :=
  LidoSRv3.Audit.Verity.AddressClaimBatchTx.every_revert_restores_snapshot
    requestIds hints recipient state rollback reason h

end LidoSRv3.Audit.Spec.AddressClaimFuelCorrespondence
