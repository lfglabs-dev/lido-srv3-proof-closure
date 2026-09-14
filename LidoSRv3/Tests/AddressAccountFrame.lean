import LidoSRv3.Audit.Verity.AddressRecipientCallBridge
import LidoSRv3.Audit.Source.TrioReserve1.QueueFinalize

namespace LidoSRv3.Tests.AddressAccountFrame
open Verity
open LidoSRv3.Audit.Source.TrioReserve1
open Live
open LidoSRv3.Audit.Verity.AddressClaimBatchTx
open LidoSRv3.Audit.Verity.AddressRecipientCallBridge

/-- The literal physical finalized word used by both producer and consumer is
identical, not a separately assumed storage binding. -/
theorem finalized_position_agrees : lastFinalizedRequestIdPosition = Queue.finalizedSlot := rfl

theorem locked_position_agrees : lockedEtherAmountPosition = QueueFinalize.lockedSlot := rfl

/-- The actual Live write primitive used by QueueFinalize is immediately
visible in the claim frame, for every world/account/value. -/
theorem finalization_write_reaches_claim_frame (ctx : Live.Context) (before : Live.World)
    (value : Live.Word) :
    (AccountFrame.enter ctx (Live.write ctx Queue.finalizedSlot value before).world.core).readSlot
      lastFinalizedRequestIdPosition = value := by
  exact AccountFrame.enter_after_write ctx before.core Queue.finalizedSlot value

theorem locked_write_reaches_claim_frame (ctx : Live.Context) (before : Live.World)
    (value : Live.Word) :
    (AccountFrame.enter ctx (Live.write ctx QueueFinalize.lockedSlot value before).world.core).readSlot
      lockedEtherAmountPosition = value := by
  exact AccountFrame.enter_after_write ctx before.core QueueFinalize.lockedSlot value

private def context : Live.Context := ⟨7, 8⟩
private def wrongChannel : Live.World :=
  { core := defaultState.writeSlot lastFinalizedRequestIdPosition 9
    balances := fun _ => 100 }

/-- Mutation witness: the legacy unqualified view sees 9, while the executing
queue has never finalized a request. The real claim must fail before any hash,
owner-set access or recipient callback. No native-decision axiom is used. -/
theorem unrelated_unqualified_word_is_not_queue_state :
    wrongChannel.core.readSlot lastFinalizedRequestIdPosition = 9 ∧
    (AccountFrame.enter context wrongChannel.core).readSlot lastFinalizedRequestIdPosition = 0 := by
  decide +kernel

theorem claim_rejects_unqualified_finalization :
    (runClaimWithdrawalsTo acceptingCallee context [1] [1] 10 wrongChannel).outcome =
      .error (.reason "RequestNotFoundOrNotFinalized") ∧
    (runClaimWithdrawalsTo acceptingCallee context [1] [1] 10 wrongChannel).attempts = [] := by
  decide +kernel

/-- The structural frame law includes account zero, rather than requiring all
participants to be nonzero or reducing the world to one actor. -/
theorem foreign_account_preserved (ctx : Live.Context) (before localState : ContractState)
    (other slot : Nat) (different : other ≠ ctx.self.val) :
    (AccountFrame.commit ctx.self before localState).readContractSlot other slot =
      before.readContractSlot other slot :=
  AccountFrame.commit_other_account ctx.self before localState other slot different

#print axioms finalization_write_reaches_claim_frame
#print axioms locked_write_reaches_claim_frame
#print axioms unrelated_unqualified_word_is_not_queue_state
#print axioms claim_rejects_unqualified_finalization
end LidoSRv3.Tests.AddressAccountFrame
