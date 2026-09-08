import LidoSRv3.Audit.Guarantees.PAddress1

namespace LidoSRv3.Tests.PAddress1Vectors

open LidoSRv3.Audit.Guarantees.PAddress1
open LidoSRv3.Audit.Verity.AddressTransferTx

/-- Caller-swap vectors: the renaming swaps the two callers and fixes every
other address. -/
example : address_renaming 1 2 1 = 2 := by decide

example : address_renaming 1 2 2 = 1 := by decide

example : address_renaming 1 2 7 = 7 := by decide

/-- The swap is involutive on a fixed-point-free address. -/
example : address_renaming 3 5 (address_renaming 3 5 4) = 4 := by decide

/-- Input-rename vector: the caller-indexed balance observation is transported
to the renamed caller. -/
example : ∀ inp : LidoSRv3.Audit.Guarantees.PAddress1.Input,
    (rename_input (address_renaming 1 2) inp).balances 1 = inp.balances 2 := by
  intro inp; rfl

/-- A succeeding single-item `transferFrom` source witness: the caller owns
the request and the recipient is a fresh nonzero address. -/
private def witnessInput : LidoSRv3.Audit.SolidityAddress.Input :=
  { entryPoint := .transferFrom
    caller := 1
    senderFrom := 1
    recipient := 3
    requestOwner := 1
    amount := 5
    requestId := 7
    paused := false
    requestExists := true
    requestClaimed := false
    requestFinalized := true
    hintValid := true
    callerIsApprovedForAll := false
    callerIsTokenApproved := false
    amountInRange := true
    callerBalanceSufficient := true
    callerAllowanceSufficient := true
    externalCallSucceeds := true }

open LidoSRv3.Audit.SolidityAddress in
/-- Source-plane admission vector: the witness commits the source-shaped
post-state. -/
example : run witnessInput = .committed ⟨3, 3, 1, 3⟩ := by decide

open LidoSRv3.Audit.SolidityAddress in
/-- Concrete instance of the registered admission parent: swapping callers
`1` and `2` preserves admission on the witness. -/
example : succeeds (run (renameInput 1 2 witnessInput)) =
    succeeds (run witnessInput) :=
  source_admission_nondiscriminatory 1 2 (by decide) (by decide) witnessInput

open LidoSRv3.Audit.SolidityAddress in
/-- Concrete instance of the registered post-state parent: the committed
post-state renames under the same caller swap. -/
example : run (renameInput 1 2 witnessInput) =
    .committed (renamePost 1 2 ⟨3, 3, 1, 3⟩) :=
  source_success_post_state_equivariant 1 2 (by decide) (by decide)
    witnessInput ⟨3, 3, 1, 3⟩ (by decide)

open LidoSRv3.Audit.SolidityAddress in
/-- Caller discrimination is load-bearing at the source plane: a caller that
is neither owner nor approved is rejected on the otherwise eligible
witness. -/
example : run { witnessInput with caller := 9 } = .reverted := by decide

/-- A succeeding wave-5 `claimWithdrawalsTo` witness: the caller-relative
request-owner gate renames with the caller. -/
private def claimInput : LidoSRv3.Audit.SolidityAddress.Input :=
  { entryPoint := .claimWithdrawalsTo
    caller := 4
    senderFrom := 9
    recipient := 6
    requestOwner := 4
    amount := 0
    requestId := 11
    paused := false
    requestExists := true
    requestClaimed := false
    requestFinalized := true
    hintValid := true
    callerIsApprovedForAll := false
    callerIsTokenApproved := false
    amountInRange := true
    callerBalanceSufficient := true
    callerAllowanceSufficient := true
    externalCallSucceeds := true }

open LidoSRv3.Audit.SolidityAddress in
/-- The `claimWithdrawalsTo` projection commits with the caller as owner and
the chosen recipient as payout target. -/
example : run claimInput = .committed ⟨4, 6, 4, 6⟩ := by decide

open LidoSRv3.Audit.SolidityAddress in
/-- Renaming callers `4` and `7` transports the owner gate and the committed
post-state together. -/
example : run (renameInput 4 7 claimInput) =
    .committed (renamePost 4 7 ⟨4, 6, 4, 6⟩) :=
  source_success_post_state_equivariant 4 7 (by decide) (by decide)
    claimInput ⟨4, 6, 4, 6⟩ (by decide)

/-- TX-plane vector under the official Denote: a fresh owner-operated handoff
commits the two source-prescribed writes. -/
example : observe (run 5 5 8 5 4) = (true, 8, 0) := by decide

/-- TX-plane negative control: the same eligible state and arguments revert
when the sender is not the owner, leaving both slots untouched. -/
example : observe (run 6 5 8 5 4) = (false, 5, 4) := by decide

/-- Registry surface: the universal registered P-ADDRESS-1 parent applies to
the witness input of this file. -/
example : LidoSRv3.Audit.SolidityAddress.succeeds (LidoSRv3.Audit.SolidityAddress.run
      (LidoSRv3.Audit.SolidityAddress.renameInput 1 2 witnessInput)) =
      LidoSRv3.Audit.SolidityAddress.succeeds (LidoSRv3.Audit.SolidityAddress.run witnessInput) ∧
    ∀ post, LidoSRv3.Audit.SolidityAddress.run witnessInput = .committed post →
      LidoSRv3.Audit.SolidityAddress.run (LidoSRv3.Audit.SolidityAddress.renameInput
        1 2 witnessInput) =
        .committed (LidoSRv3.Audit.SolidityAddress.renamePost 1 2 post) :=
  universal_address_writer_equivariance 1 2 (by decide) (by decide) witnessInput

end LidoSRv3.Tests.PAddress1Vectors
