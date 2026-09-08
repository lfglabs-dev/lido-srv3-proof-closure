import PAddress1

namespace AccountAddress.Tests.Verity.PAddress1Test
open AccountAddress.PAddress1

def transferBefore : TransferState :=
  { lastRequestId := 8, requestWord := 77 * two160 + 3
    tokenApproval := 9, ownerSetRemoveSucceeds := true
    ownerSetAddSucceeds := true }

def transferInput : TransferInput :=
  { caller := 3, fromAddr := 3, to := 5, requestId := 2
    approvedForAll := false }

example : transferFrom transferInput transferBefore = .committed
    { transferBefore with requestWord := 77 * two160 + 5, tokenApproval := 0 } () := by
  native_decide

example : transferFrom { transferInput with to := 0, requestId := 0 } transferBefore =
    .reverted .transferToZeroAddress transferBefore := by native_decide

example : writeOwnerChecked transferBefore.requestWord two160 = none := by
  native_decide

example : writeOwnerChecked transferBefore.requestWord (two160 + 7) = none := by
  native_decide

def claimBefore : ClaimState :=
  { lastFinalizedRequestId := 10, requestWord := 23 * two201 + 3
    lockedEther := 100, ownerSetRemoveSucceeds := true }

def claimInput : ClaimInput :=
  { caller := 3, recipient := 8, requestIds := [5], hints := [2]
    lastCheckpointIndex := 4, checkpointFrom := 4, nextCheckpointFrom := 6
    claimableEther := 40, sendSucceeds := true }

example : claimWithdrawalsTo claimInput claimBefore = .committed
    (ClaimState.mk 10 (setClaimed claimBefore.requestWord) 60 true) 40 := by
  native_decide

example : claimWithdrawalsTo { claimInput with recipient := 0, hints := [] } claimBefore =
    .reverted .zeroRecipient claimBefore := by native_decide

def unwrapBefore : UnwrapState := { wstBalance := 10, stEthBalance := 2 }
def unwrapInput : UnwrapInput :=
  { caller := 7, amount := 4, stEthQuote := 5, transferSucceeds := true }

example : unwrap unwrapInput unwrapBefore =
    .committed { wstBalance := 6, stEthBalance := 7 } 5 := by native_decide

example : unwrap { unwrapInput with transferSucceeds := false } unwrapBefore =
    .reverted .stETHTransferFailed unwrapBefore := by native_decide

/-- Fixed-owner mutant: unlike the caller-relative source guard, it rejects a
uniformly renamed owner/caller pair. -/
def fixedOwnerMutant (i : TransferInput) (s : TransferState) :=
  if i.caller != 3 then Result.reverted (.notOwnerOrApproved i.caller) s
  else transferFrom i s

theorem fixed_owner_mutant_killed :
    (match transferFrom { transferInput with caller := 4, fromAddr := 4 }
      { transferBefore with requestWord := 77 * two160 + 4 } with
      | .committed _ _ => true | _ => false) = true ∧
    (match fixedOwnerMutant { transferInput with caller := 4, fromAddr := 4 }
      { transferBefore with requestWord := 77 * two160 + 4 } with
      | .reverted _ _ => true | _ => false) = true := by native_decide

end AccountAddress.Tests.Verity.PAddress1Test
