import LidoSRv3.Audit.Verity.AddressTx

namespace LidoSRv3.Tests.AddressSourceMutants

open Verity
open LidoSRv3.Audit.SolidityAddress

private def eligibleUnwrap (caller : Address) : Input :=
  { entryPoint := .unwrap, caller := caller, senderFrom := caller, recipient := caller,
    requestOwner := caller
    amount := 1, requestId := 0, paused := false, requestExists := true
    requestClaimed := false, requestFinalized := true, hintValid := true
    callerIsApprovedForAll := false, callerIsTokenApproved := false, amountInRange := true
    callerBalanceSufficient := true, callerAllowanceSufficient := true
    externalCallSucceeds := true }

private def eligibleTransfer : Input :=
  { entryPoint := .transferFrom, caller := 1, senderFrom := 1, recipient := 2,
    requestOwner := 1, amount := 0, requestId := 7, paused := false,
    requestExists := true, requestClaimed := false, requestFinalized := false,
    hintValid := false, callerIsApprovedForAll := false,
    callerIsTokenApproved := false, amountInRange := false,
    callerBalanceSufficient := false, callerAllowanceSufficient := false,
    externalCallSucceeds := false }

private def wrongRecipientProgram : Contract Unit :=
  setMappingUint
    LidoSRv3.Audit.Verity.AddressTx.AddressTxContract.recipients 1
    (addressToWord (2 : Address))

private def fixedOwnerWriterProgram : Contract Unit := do
  setMappingUint LidoSRv3.Audit.Verity.AddressTx.AddressTxContract.recipients 7
    (addressToWord (2 : Address))
  setMappingUint LidoSRv3.Audit.Verity.AddressTx.AddressTxContract.owners 7
    (addressToWord (9 : Address))

/-- Counterexample: a caller-address allowlist would reject an otherwise eligible peer. -/
theorem privileged_caller_mutant_counterexample :
    let privileged : Address := 1
    let mutant := fun (inp : Input) => if inp.caller = privileged then run inp else .reverted
    succeeds (mutant (eligibleUnwrap 1)) ≠ succeeds (mutant (eligibleUnwrap 2)) := by
  decide

/-- Counterexample: leaving the successful recipient unrenamed breaks post-state equivariance. -/
theorem address_stomp_mutant_counterexample :
    let inp := eligibleUnwrap 1
    let stomp : PostState := ⟨1, 1, 1, 1⟩
    run inp = .committed stomp ∧ succeeds (run (renameInput 1 2 inp)) = true ∧
      run (renameInput 1 2 inp) ≠ .committed stomp := by
  decide

/-- Wrong-recipient mutant: the renamed successful outcome cannot retain the
old caller as payout recipient.  Only outcome observables are compared. -/
theorem wrong_recipient_mutant_rejected :
    let inp := eligibleUnwrap (1 : Address)
    let renamed := renameInput (1 : Address) (2 : Address) inp
    let wrong : PostState := ⟨2, 1, 2, 2⟩
    run renamed ≠ .committed wrong := by decide

/-- Executable wrong-recipient mutation disagrees with the pinned-source
address-write observation, without comparing the surrounding storage state. -/
theorem verity_wrong_recipient_mutant_rejected :
    let inp := eligibleUnwrap (1 : Address)
    let state := { defaultState with sender := (1 : Address) }
    LidoSRv3.Audit.Verity.AddressTx.observeAddress inp
        (wrongRecipientProgram.run state) ≠
      LidoSRv3.Audit.Verity.AddressTx.sourceAddressView inp := by
  decide

/-- Address-writer abuse: replacing the caller-relative owner with a fixed
singleton is detected by universal post-state equivariance. -/
theorem fixed_owner_writer_mutant_rejected :
    let inp := eligibleUnwrap (1 : Address)
    let fixed : PostState := ⟨1, 1, 1, 1⟩
    run (renameInput (1 : Address) (2 : Address) inp) ≠ .committed fixed := by
  decide

/-- Executable address-writer abuse is rejected at the same outcome boundary:
the recipient write is plausible, but the fixed owner write is observable. -/
theorem verity_fixed_owner_writer_mutant_rejected :
    let inp := eligibleTransfer
    LidoSRv3.Audit.Verity.AddressTx.observeAddress inp
        (fixedOwnerWriterProgram.run defaultState) ≠
      LidoSRv3.Audit.Verity.AddressTx.sourceAddressView inp := by
  decide

/-- Admission-boundary mutant: changing `amount != 0` to unconditional
admission accepts the zero-amount redemption rejected by the pinned source. -/
theorem zero_amount_admission_mutant_rejected :
    let inp := { eligibleUnwrap (1 : Address) with amount := 0 }
    run inp = .reverted ∧
      (if true then .committed (successfulPost inp) else .reverted) ≠ run inp := by
  decide

/-- The executable boundary independently rejects the same zero-amount case. -/
theorem verity_zero_amount_rejected :
    let caller := (1 : Address)
    let state := { Verity.defaultState with sender := caller }
    (LidoSRv3.Audit.Verity.AddressTx.AddressTxContract.redeem 0 true).run state =
      .revert "ZeroAmount" state := by
  rfl

#check LidoSRv3.Audit.Verity.AddressTx.composed_verity_tx_address_equivariance
#check source_admission_nondiscriminatory
#check source_success_post_state_equivariant

end LidoSRv3.Tests.AddressSourceMutants
