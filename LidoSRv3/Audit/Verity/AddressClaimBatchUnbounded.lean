import LidoSRv3.Audit.Verity.AddressClaimBatchTx

/-!
# P-ADDRESS-1 — unbounded live claim-batch observe receipt

Pinned source: `lidofinance/core@17005714f151e5502c559932319a3f2f74ac2436`,
`WithdrawalQueue.claimWithdrawalsTo` (`WithdrawalQueue.sol:244-256`) and
`WithdrawalQueueBase._claim` (`WithdrawalQueueBase.sol:460-480`).

The live `AddressClaimBatchTx` loop already iterates arbitrary request/hint
lists. The previously checked observe receipt (packed request/checkpoint
reads, claimed bit, locked-ETH decrement, ordered `_sendValue` CALLs) was
fixed at two items. This module proves the receipt for every successful
list by induction: the batch observe is the ordered map of the unit
`_claim` receipt. The two-item parent shape `[1, 2]` / hints `[1, 1]` /
payouts `[30, 40]` is that instance. A mutant that reorders the payout
CALLs is refused.

The live storage transition does not itself journal CALLs (those sit on
`AddressRecipientCallBridge`). The unit receipt therefore records the
exact `_sendValue` frame that `_claim` line 477 issues:
`payoutEntry recipient payout`, in loop order.

The concrete physical `twoClaimState` finite run is the known
kernel-opaque keccak boundary (`audit/address-actual-consumer/legacy-unproved-statements.md`):
`decide +kernel` does not reduce `mappingSlotLocation`, and `native_decide`
needs the evmyul FFI (`ffi.ByteArray.zeroes`). This module does not replace
that physical path with a `mapUint` surrogate and does not claim a kernel
decision of `twoClaimState`.
-/

namespace LidoSRv3.Audit.Verity.AddressClaimBatchUnbounded

open LidoSRv3.Audit.Verity.AddressClaimBatchTx
open _root_.Verity
open _root_.Verity.EVM.Uint256
open Contracts

/-- One `_claim` iteration receipt: packed pre-state reads, post claimed bit,
locked ETH after the decrement, the returned payout, and the ordered
`_sendValue` CALL. -/
structure UnitReceipt where
  requestId : Nat
  packedAmounts : Uint256
  packedMetadata : Uint256
  claimed : Bool
  payout : Nat
  lockedAfter : Nat
  call : ExternalCall
  deriving DecidableEq, Repr

def unitReceiptOf (state after : ContractState) (requestId : Nat)
    (recipient : Address) (payout : Nat) : UnitReceipt where
  requestId := requestId
  packedAmounts := requestAmountsWord state requestId
  packedMetadata := requestMetadataWord state requestId
  claimed := requestClaimed (requestMetadataWord after requestId)
  payout := payout
  lockedAfter := (after.readSlot lockedEtherAmountPosition).val
  call := payoutEntry recipient payout

/-- Successful batch as the ordered map of unit `_claim` receipts. -/
inductive BatchUnits : ContractState → List Nat → List Nat → Address →
    List UnitReceipt → ContractState → Prop
  | nil (state recipient) : BatchUnits state [] [] recipient [] state
  | cons {state mid after recipient requestId hint requestIds hints payout receipts} :
      claimOne requestId hint recipient state = .success payout mid →
      BatchUnits mid requestIds hints recipient receipts after →
      BatchUnits state (requestId :: requestIds) (hint :: hints) recipient
        (unitReceiptOf state mid requestId recipient payout :: receipts) after

theorem lengths_of_units {state after : ContractState} {recipient : Address}
    {requestIds hints : List Nat} {receipts : List UnitReceipt}
    (h : BatchUnits state requestIds hints recipient receipts after) :
    requestIds.length = hints.length ∧ requestIds.length = receipts.length := by
  induction h with
  | nil => simp
  | cons _ _ ih =>
      constructor
      · simpa using congrArg Nat.succ ih.1
      · simpa using congrArg Nat.succ ih.2

theorem ids_of_units {state after : ContractState} {recipient : Address}
    {requestIds hints : List Nat} {receipts : List UnitReceipt}
    (h : BatchUnits state requestIds hints recipient receipts after) :
    receipts.map UnitReceipt.requestId = requestIds := by
  induction h with
  | nil => rfl
  | cons _ _ ih =>
      simp [unitReceiptOf, ih]

theorem calls_of_units {state after : ContractState} {recipient : Address}
    {requestIds hints : List Nat} {receipts : List UnitReceipt}
    (h : BatchUnits state requestIds hints recipient receipts after) :
    receipts.map UnitReceipt.call =
      receipts.map (fun r => payoutEntry recipient r.payout) := by
  induction h with
  | nil => rfl
  | cons _ _ ih =>
      simp [unitReceiptOf, ih]

theorem map_payoutEntry_eq {recipient : Address} :
    ∀ receipts : List UnitReceipt,
      receipts.map (fun r => payoutEntry recipient r.payout) =
        (receipts.map UnitReceipt.payout).map (payoutEntry recipient)
  | [] => rfl
  | _ :: rest => by simp [map_payoutEntry_eq (recipient := recipient) rest]

/-- Packed pre-reads, claimed bit, locked decrement and `_sendValue` frame
of one successful `_claim` (`WithdrawalQueueBase.sol:460-480`). -/
theorem unit_receipt_reads (state after : ContractState) (requestId : Nat)
    (recipient : Address) (payout : Nat) :
    let r := unitReceiptOf state after requestId recipient payout
    r.packedAmounts = requestAmountsWord state requestId ∧
      r.packedMetadata = requestMetadataWord state requestId ∧
      r.claimed = requestClaimed (requestMetadataWord after requestId) ∧
      r.payout = payout ∧
      r.lockedAfter = (after.readSlot lockedEtherAmountPosition).val ∧
      r.call = payoutEntry recipient payout :=
  ⟨rfl, rfl, rfl, rfl, rfl, rfl⟩

theorem claimLoop_cons_success
    {requestId : Nat} {requestIds : List Nat} {hint : Nat} {hints : List Nat}
    {recipient : Address} {state after : ContractState}
    (h : claimLoop (requestId :: requestIds) (hint :: hints) recipient state =
      .success () after) :
    ∃ payout mid,
      claimOne requestId hint recipient state = .success payout mid ∧
      claimLoop requestIds hints recipient mid = .success () after := by
  simp [claimLoop, Bind.bind, _root_.Verity.bind] at h
  cases hc : claimOne requestId hint recipient state with
  | «revert» reason rollback => simp [hc] at h
  | success payout mid =>
      exact ⟨payout, mid, rfl, by simpa [hc] using h⟩

theorem units_of_claimLoop {state after : ContractState} {recipient : Address} :
    ∀ {requestIds hints : List Nat},
      claimLoop requestIds hints recipient state = .success () after →
      ∃ receipts, BatchUnits state requestIds hints recipient receipts after
  | [], [], h => by
      simp [claimLoop, _root_.Verity.pure] at h
      cases h
      exact ⟨[], BatchUnits.nil state recipient⟩
  | [], _ :: _, h => by simp [claimLoop] at h
  | _ :: _, [], h => by simp [claimLoop] at h
  | requestId :: requestIds, hint :: hints, h => by
      obtain ⟨payout, mid, h1, h2⟩ := claimLoop_cons_success h
      obtain ⟨receipts, ht⟩ := units_of_claimLoop (state := mid) h2
      exact ⟨unitReceiptOf state mid requestId recipient payout :: receipts,
        BatchUnits.cons h1 ht⟩

theorem claimLoop_of_units {state after : ContractState} {recipient : Address}
    {requestIds hints : List Nat} {receipts : List UnitReceipt}
    (h : BatchUnits state requestIds hints recipient receipts after) :
    claimLoop requestIds hints recipient state = .success () after := by
  induction h with
  | nil => rfl
  | cons h1 _ ih =>
      simp [claimLoop, Bind.bind, _root_.Verity.bind, h1, ih]

theorem execute_of_units {state after : ContractState} {recipient : Address}
    {requestIds hints : List Nat} {receipts : List UnitReceipt}
    (h : BatchUnits state requestIds hints recipient receipts after)
    (hrecipient : recipient ≠ zeroAddress) :
    (executeClaimWithdrawalsTo requestIds hints recipient).run state =
      .success () after := by
  have hlength := (lengths_of_units h).1
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
      .success () after
  unfold Contract.run _root_.Verity.bind _root_.Verity.require
  simp [hrecipient', hlength, claimLoop_of_units h]

/-- Observe of a successful batch is the ordered map of unit receipts:
claimed bits and locked ETH are the post-state reads, and the `_sendValue`
CALL journal is `map payoutEntry` of the unit payouts, in loop order. -/
theorem observe_eq_map_unit {state after : ContractState} {recipient : Address}
    {requestIds hints : List Nat} {receipts : List UnitReceipt}
    (h : BatchUnits state requestIds hints recipient receipts after)
    (hrecipient : recipient ≠ zeroAddress) :
    observe requestIds
        ((executeClaimWithdrawalsTo requestIds hints recipient).run state) =
      ⟨.committed,
        requestIds.map (fun id => requestClaimed (requestMetadataWord after id)),
        (after.readSlot lockedEtherAmountPosition).val, after.calls⟩ ∧
    receipts.map UnitReceipt.call =
      receipts.map (fun r => payoutEntry recipient r.payout) ∧
    receipts.map UnitReceipt.requestId = requestIds :=
  ⟨by rw [execute_of_units h hrecipient]; rfl, calls_of_units h, ids_of_units h⟩

/-- Collect the unit payouts of a successful loop. Used to name the two-item
parent as an instance of the inductive receipt. -/
def claimLoopPayouts : List Nat → List Nat → Address → Contract (List Nat)
  | [], [], _ => Verity.pure []
  | requestId :: requestIds, hint :: hints, recipient => do
      let payout ← claimOne requestId hint recipient
      let rest ← claimLoopPayouts requestIds hints recipient
      Verity.pure (payout :: rest)
  | _, _, _ => fun state => .revert "ArraysLengthMismatch" state

theorem units_of_payouts {state after : ContractState} {recipient : Address} :
    ∀ {requestIds hints payouts : List Nat},
      claimLoopPayouts requestIds hints recipient state = .success payouts after →
      ∃ receipts,
        BatchUnits state requestIds hints recipient receipts after ∧
          receipts.map UnitReceipt.payout = payouts
  | [], [], payouts, h => by
      simp [claimLoopPayouts, _root_.Verity.pure] at h
      rcases h with ⟨rfl, rfl⟩
      exact ⟨[], BatchUnits.nil state recipient, rfl⟩
  | [], _ :: _, _, h => by simp [claimLoopPayouts] at h
  | _ :: _, [], _, h => by simp [claimLoopPayouts] at h
  | requestId :: requestIds, hint :: hints, payouts, h => by
      simp [claimLoopPayouts, Bind.bind, _root_.Verity.bind] at h
      cases hc : claimOne requestId hint recipient state with
      | «revert» reason rollback => simp [hc] at h
      | success payout mid =>
          simp [hc] at h
          cases ht : claimLoopPayouts requestIds hints recipient mid with
          | «revert» reason rollback => simp [ht] at h
          | success rest last =>
              simp [ht, _root_.Verity.pure] at h
              rcases h with ⟨rfl, rfl⟩
              obtain ⟨receipts, hUnits, hMap⟩ :=
                units_of_payouts (state := mid) ht
              exact ⟨unitReceiptOf state mid requestId recipient payout :: receipts,
                BatchUnits.cons hc hUnits, by simp [unitReceiptOf, hMap]⟩

/-- Two-item parent: the checked `[1, 2]` / hints `[1, 1]` / payouts
`[30, 40]` receipt is the length-two instance of `BatchUnits`. CALL order
is the `_claim` / `_sendValue` pair `(30, 40)`. This is the parent shape,
not a kernel evaluation of physical `twoClaimState`. -/
theorem two_item_parent_instance
    {state after : ContractState} {recipient : Address} {receipts : List UnitReceipt}
    (h : BatchUnits state [1, 2] [1, 1] recipient receipts after)
    (hrecipient : recipient ≠ zeroAddress)
    (hp : receipts.map UnitReceipt.payout = [30, 40]) :
    receipts.map UnitReceipt.call =
      [payoutEntry recipient 30, payoutEntry recipient 40] ∧
    observe [1, 2]
        ((executeClaimWithdrawalsTo [1, 2] [1, 1] recipient).run state) =
      ⟨.committed,
        [1, 2].map (fun id => requestClaimed (requestMetadataWord after id)),
        (after.readSlot lockedEtherAmountPosition).val, after.calls⟩ := by
  constructor
  · have hcalls := calls_of_units h
    calc receipts.map UnitReceipt.call
        = receipts.map (fun r => payoutEntry recipient r.payout) := hcalls
      _ = (receipts.map UnitReceipt.payout).map (payoutEntry recipient) :=
        map_payoutEntry_eq receipts
      _ = [30, 40].map (payoutEntry recipient) := by rw [hp]
      _ = [payoutEntry recipient 30, payoutEntry recipient 40] := rfl
  · exact (observe_eq_map_unit h hrecipient).1

/-- Mutant journal that pays the same amounts to the same recipient but
reverses CALL order. The inductive receipt refuses it. -/
def reorderedCalls (payouts : List Nat) (recipient : Address) : List ExternalCall :=
  payouts.reverse.map (payoutEntry recipient)

theorem reordered_calls_refute_two_item :
    reorderedCalls [30, 40] (2 : Address) ≠
      [payoutEntry (2 : Address) 30, payoutEntry (2 : Address) 40] := by
  decide

#print axioms observe_eq_map_unit
#print axioms two_item_parent_instance
#print axioms reordered_calls_refute_two_item

end LidoSRv3.Audit.Verity.AddressClaimBatchUnbounded
