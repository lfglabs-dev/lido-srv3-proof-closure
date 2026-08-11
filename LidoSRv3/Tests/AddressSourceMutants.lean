import LidoSRv3.Audit.Verity.AddressTx

namespace LidoSRv3.Tests.AddressSourceMutants

open Verity
open LidoSRv3.Audit.SolidityAddress

private def eligibleUnwrap (caller : Address) : Input :=
  { entryPoint := .unwrap, caller := caller, senderFrom := caller, recipient := caller
    amount := 1, requestId := 0, paused := false, requestExists := true
    requestClaimed := false, requestFinalized := true, hintValid := true
    callerIsOwner := true, callerIsApprovedForAll := false
    callerIsTokenApproved := false, amountInRange := true
    callerBalanceSufficient := true, callerAllowanceSufficient := true
    externalCallSucceeds := true }

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
    run (renameInput 1 2 inp) ≠ .committed stomp := by
  decide

#check LidoSRv3.Audit.Verity.AddressTx.verity_tx_simulates_source
#check source_admission_nondiscriminatory
#check source_success_post_state_equivariant

end LidoSRv3.Tests.AddressSourceMutants
