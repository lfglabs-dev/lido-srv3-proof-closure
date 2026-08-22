import LidoSRv3.Audit.Verity.AddressAdmission
import LidoSRv3.Audit.Verity.AddressTx
import LidoSRv3.Audit.Verity.AddressClaimBatchTx

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
`Input` / `Outcome` / `renameInput` the parent is stated over.
`fixed_owner_gate_kill_line_refutes_parent` negates the parent's FULL
predicate shape on that mutant (the nonzero-caller binders and BOTH
conclusion conjuncts; the wave-4 `addressEquivarianceEntryScope` premise was
retired in wave 5 when the scope widened to all four modeled writers);
`fixed_owner_gate_not_admission_equivariant` is the weaker
admission-projection sibling, retained as compact supporting evidence. -/

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

/-- Witness for the parent kill-line: an otherwise-eligible `requestWithdrawals`
input from caller `1`, the mutant's fixed owner.  `requestWithdrawals` is one
of the four modeled address-bearing writers (in `addressEquivarianceEntryScope`
under both the wave-4 and the widened wave-5 scope). -/
private def fixedOwnerGateWitness : Input :=
  { entryPoint := .requestWithdrawals, caller := 1, senderFrom := 1, recipient := 0,
    requestOwner := 1, amount := 1, requestId := 0, paused := false, requestExists := true,
    requestClaimed := false, requestFinalized := false, hintValid := false,
    callerIsApprovedForAll := false, callerIsTokenApproved := false, amountInRange := true,
    callerBalanceSufficient := true, callerAllowanceSufficient := true,
    externalCallSucceeds := true }

/-- **Kill-line refuting the registered P-ADDRESS-1 parent
(`PAddress1.universal_address_writer_equivariance`) on a mutant of its own
model.**  The negated statement is the parent's exact predicate shape with the
mutant `runFixedOwnerGated` substituted for `run`: the same nonzero-caller
binders and BOTH conclusion conjuncts (admission-bit equality and
committed-post renaming).  (The wave-4 parent carried an
`addressEquivarianceEntryScope` premise; wave 5 widened the scope to all four
modeled writers, retiring the premise as vacuous, so the negated shape carries
no scope implication.)  On the witness `fixedOwnerGateWitness` with callers
`1` (the fixed owner) and `2`, the mutant admits caller `1` and commits
`⟨1, 1, 1, 1⟩`, while the `1 ↔ 2`-swapped input is rejected
(`2 ≠ fixedOwner`) -- so the admission bits differ AND the swapped run cannot
commit the renamed post `⟨2, 2, 2, 2⟩`.  Both conjunct failures are
`decide`-checked in `hBoth`; the refutation closes through the post-state
conjunct.  This is the fact
`AddressAdmission.ownerGated_not_admission_equivariant` could not supply,
since that theorem is stated over a disconnected toy `FunctionSpec` that never
mentions `SolidityAddress.run`. -/
theorem fixed_owner_gate_kill_line_refutes_parent :
    ¬ ∀ (a₁ a₂ : Address), a₁ ≠ 0 → a₂ ≠ 0 → ∀ (inp : Input),
        succeeds (runFixedOwnerGated (renameInput a₁ a₂ inp)) =
          succeeds (runFixedOwnerGated inp) ∧
        ∀ post, runFixedOwnerGated inp = .committed post →
          runFixedOwnerGated (renameInput a₁ a₂ inp) =
            .committed (renamePost a₁ a₂ post) := by
  intro h
  have hcex := h 1 2 (by decide) (by decide) fixedOwnerGateWitness
  have hBoth :
      (succeeds (runFixedOwnerGated (renameInput 1 2 fixedOwnerGateWitness)) ≠
          succeeds (runFixedOwnerGated fixedOwnerGateWitness)) ∧
        runFixedOwnerGated (renameInput 1 2 fixedOwnerGateWitness) ≠
          .committed (renamePost 1 2 ⟨1, 1, 1, 1⟩) :=
    ⟨by decide, by decide⟩
  exact hBoth.2 (hcex.2 ⟨1, 1, 1, 1⟩ (by decide))

/-- **Sibling evidence: admission projection only.**  Refutes the parent's
first conclusion conjunct on the same fixed-owner-gated mutant, WITHOUT the
parent's `addressEquivarianceEntryScope` premise and WITHOUT the post-state
conjunct -- the shape of the sibling `source_admission_nondiscriminatory`,
not of the registered parent.  Subsumed by
`fixed_owner_gate_kill_line_refutes_parent` above, which negates the parent's
full predicate shape; retained as a compact, fully `decide`-checked statement
of the admission-bit failure on its own. -/
theorem fixed_owner_gate_not_admission_equivariant :
    ¬ ∀ (a₁ a₂ : Address), a₁ ≠ 0 → a₂ ≠ 0 → ∀ (inp : Input),
        succeeds (runFixedOwnerGated (renameInput a₁ a₂ inp)) =
          succeeds (runFixedOwnerGated inp) := by
  intro h
  have hcex := h 1 2 (by decide) (by decide) fixedOwnerGateWitness
  revert hcex
  decide

/-! ## Write-side parent kill-line

The admission-gate mutant above can falsify both parent conjuncts by rejecting
the renamed call.  This second mutant leaves `admitted` untouched and changes
only a committed address write, so it isolates the post-state half of the
registered parent. -/

/-- Mutant post-state: retain the honest recipient and balance-key writes but
stomp the owner field with an unrenamed fixed address. -/
def successfulPostFixedOwnerWriter (inp : Input) : PostState :=
  { successfulPost inp with owner := fixedOwner }

def runFixedOwnerWriter (inp : Input) : Outcome :=
  if admitted inp then .committed (successfulPostFixedOwnerWriter inp) else .reverted

/-- **Write-side kill-line refuting the registered parent.** Admission remains
equivariant because it is the honest `admitted`; on the eligible unwrap witness
both calls commit.  The renamed call nevertheless writes owner `1`, while
renaming the original committed post requires owner `2`.  Thus the full parent
shape is false solely through its committed-post conjunct. -/
theorem fixed_owner_writer_kill_line_refutes_parent :
    ¬ ∀ (a₁ a₂ : Address), a₁ ≠ 0 → a₂ ≠ 0 → ∀ (inp : Input),
        succeeds (runFixedOwnerWriter (renameInput a₁ a₂ inp)) =
          succeeds (runFixedOwnerWriter inp) ∧
        ∀ post, runFixedOwnerWriter inp = .committed post →
          runFixedOwnerWriter (renameInput a₁ a₂ inp) =
            .committed (renamePost a₁ a₂ post) := by
  intro h
  have hcex := h 1 2 (by decide) (by decide) (eligibleUnwrap 1)
  have hcommit :
      runFixedOwnerWriter (eligibleUnwrap 1) = .committed ⟨1, 1, 1, 1⟩ := by
    decide
  have hne :
      runFixedOwnerWriter (renameInput 1 2 (eligibleUnwrap 1)) ≠
        .committed (renamePost 1 2 ⟨1, 1, 1, 1⟩) := by
    decide
  exact hne (hcex.2 ⟨1, 1, 1, 1⟩ hcommit)

/-- Retained for the denote-admission subordinate row only: the disconnected
toy `AddressAdmission.ownerGated` mutant is not a kill-line for the registered
`PAddress1` parent (see `fixed_owner_gate_kill_line_refutes_parent` above for
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

/-! ## Live claim-batch payout kill-line -/

open LidoSRv3.Audit.Verity.AddressClaimBatchTx in
def claimLoopFixedPayout : List Nat → List Nat → Address → Contract Unit
  | [], [], _ => Verity.pure ()
  | requestId :: requestIds, hint :: hints, recipient => do
      claimOne requestId hint (9 : Address)
      claimLoopFixedPayout requestIds hints recipient
  | _, _, _ => fun state => .revert "ArraysLengthMismatch" state

open LidoSRv3.Audit.Verity.AddressClaimBatchTx in
def executeFixedPayoutRecipient (requestIds hints : List Nat) (recipient : Address) :
    Contract Unit := do
  require (recipient != zeroAddress) "ZeroRecipient"
  require (requestIds.length == hints.length) "ArraysLengthMismatch"
  claimLoopFixedPayout requestIds hints recipient

open LidoSRv3.Audit.Verity.AddressClaimBatchTx

/-- Kill-line for the new live-batch observable: keeping all request reads,
packed writes, values, and loop order but routing `_sendValue` to a fixed
unrenamed address is detected by the execution-derived CALL journal. -/
theorem fixed_payout_recipient_mutant_kill_line :
    observe [1, 2]
        ((executeFixedPayoutRecipient [1, 2] [1, 1] (2 : Address)).run twoClaimState) ≠
      ⟨.committed, [true, true], 0,
        [payoutEntry (2 : Address) 30, payoutEntry (2 : Address) 40]⟩ := by
  decide +kernel

#check LidoSRv3.Audit.Verity.AddressTx.composed_verity_tx_address_equivariance
#check source_admission_nondiscriminatory
#check source_success_post_state_equivariant

end LidoSRv3.Tests.AddressSourceMutants
