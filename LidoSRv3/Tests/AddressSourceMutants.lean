import LidoSRv3.Audit.Verity.AddressAdmission
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

/-- Kill-line: appending `caller = owner` to permissionless admission breaks
caller-swap equivariance on an otherwise eligible requestWithdrawals input. -/
theorem owner_gated_admission_mutant_counterexample :
    let owner : Address := 1
    let inp :=
      { eligibleUnwrap 1 with
        entryPoint := .requestWithdrawals, requestOwner := 2, amount := 1 }
    permissionlessAdmission inp = true ∧
    (permissionlessAdmission inp && decide (inp.caller = owner)) = true ∧
    (permissionlessAdmission (renameInput 1 2 inp) &&
      decide ((renameInput 1 2 inp).caller = owner)) = false := by
  decide

/-! ## Kill-line for the registered parent

`PAddress1.universal_address_writer_equivariance` quantifies over the real
`SolidityAddress.run` / `admitted` / `renameInput`.  The disconnected toy
`AddressAdmission.claim` / `ownerGated` `FunctionSpec` never touches these
definitions, so refuting *it* does not refute the registered parent.  The
mutant below is a one-conjunct edit of the real `admitted` on the two
in-scope writers `requestWithdrawals` and `unwrap`, built from the exact
`Input` / `Outcome` / `renameInput` the parent is stated over, and it
falsifies exactly the admission conclusion the parent proves. -/

/-- A hard-coded, unrenamed address standing in for a privileged role.  Unlike
`Input.requestOwner` -- which `renameInput` renames along with `caller`, so a
`caller = requestOwner` conjunct stays equivariant -- this constant is not an
address-indexed input field, so a caller-swap never moves it. -/
def fixedOwner : Address := 1

/-- Mutant of the registered parent's `admitted`: `requestWithdrawals` and
`unwrap` additionally require the caller to equal the fixed constant
`fixedOwner`.  Every other entrypoint and every other guard is exactly
`SolidityAddress.admitted`. -/
def admittedFixedOwnerGated (inp : Input) : Bool :=
  match inp.entryPoint with
  | .requestWithdrawals =>
      decide (inp.caller = fixedOwner) &&
        !inp.paused && inp.amountInRange && inp.callerBalanceSufficient &&
          inp.callerAllowanceSufficient && inp.externalCallSucceeds
  | .unwrap =>
      decide (inp.caller = fixedOwner) &&
        decide (inp.amount ≠ 0) && inp.callerBalanceSufficient && inp.externalCallSucceeds
  | _ => admitted inp

/-- Mutant of the registered parent's `run`, built on `admittedFixedOwnerGated`
instead of `admitted`.  `successfulPost` and `renameInput` are exactly the
parent's real machinery; only the admission gate is mutated. -/
def runFixedOwnerGated (inp : Input) : Outcome :=
  if admittedFixedOwnerGated inp then .committed (successfulPost inp) else .reverted

/-- **Kill-line for the registered P-ADDRESS-1 parent
(`PAddress1.universal_address_writer_equivariance`).** A fixed-owner gate on
`requestWithdrawals` is a plausible one-conjunct mutation of the real
`admitted`, connected to the parent's own `Input` / `run` / `renameInput`.
It falsifies exactly the parent's admission conclusion: caller `1` (the fixed
owner) is admitted on an otherwise-eligible `requestWithdrawals` input, but
caller `2` is rejected on the `1 ↔ 2`-swapped input, so
`succeeds (run (renameInput a₁ a₂ inp)) = succeeds (run inp)` fails for this
mutant even though `a₁, a₂ ≠ 0`. This is the fact
`AddressAdmission.ownerGated_not_admission_equivariant` could not supply,
since that theorem is stated over a disconnected toy `FunctionSpec` that never
mentions `SolidityAddress.run`. -/
theorem fixed_owner_gate_not_admission_equivariant :
    ¬ ∀ (a₁ a₂ : Address), a₁ ≠ 0 → a₂ ≠ 0 → ∀ (inp : Input),
        succeeds (runFixedOwnerGated (renameInput a₁ a₂ inp)) =
          succeeds (runFixedOwnerGated inp) := by
  intro h
  have hcex := h 1 2 (by decide) (by decide)
    { entryPoint := .requestWithdrawals, caller := 1, senderFrom := 1, recipient := 0,
      requestOwner := 1, amount := 1, requestId := 0, paused := false, requestExists := true,
      requestClaimed := false, requestFinalized := false, hintValid := false,
      callerIsApprovedForAll := false, callerIsTokenApproved := false, amountInRange := true,
      callerBalanceSufficient := true, callerAllowanceSufficient := true,
      externalCallSucceeds := true }
  revert hcex
  decide

/-- Retained for the denote-admission subordinate row only: the disconnected
toy `AddressAdmission.ownerGated` mutant is not a kill-line for the registered
`PAddress1` parent (see `fixed_owner_gate_not_admission_equivariant` above for
that), but it remains valid evidence for
`P-ADDRESS-1.denote-admission`'s own `admission_address_equivariant` claim. -/
theorem address_admission_toy_owner_gate_not_equivariant :
    LidoSRv3.Audit.Verity.AddressAdmission.ownerGateKillLine :=
  LidoSRv3.Audit.Verity.AddressAdmission.ownerGateKillLine_holds

/-- Scoped requestWithdrawals admission omits any owner gate. -/
theorem request_withdrawals_admission_has_no_owner_gate :
    let inp :=
      { eligibleUnwrap 1 with
        entryPoint := .requestWithdrawals, requestOwner := 99, amount := 1 }
    admitted inp = permissionlessAdmission inp ∧
    ¬ (admitted inp && decide (inp.caller = inp.requestOwner)) := by
  decide

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
