import LidoSRv3.Audit.Source.AragonACLSource

/-! # Kill-lines for `AragonACLSource`

**Chantier 2 (Piste A, Thomas 2026-09-13) mutant kill-lines pinning
the pinned Aragon ACL source-model semantics.**

`AragonACLSource.ACLState` groups the two named role booleans
(`stakingRouterRole`, `topUpGatewayApp`) with `deriving DecidableEq,
Repr`.  Pattern-matched `hasRole` returns the correct field for the
STAKING_ROUTER_ROLE / TOP_UP_GATEWAY_APP roles.  `isAuthorizedRouter`
and `isTopUpGatewayCaller` are the two @[reducible, simp] def
accessors.

These kill-lines pin the exact semantics and demonstrate boundary
cases. -/

namespace LidoSRv3.Tests.AragonACLSourceKillLines

open LidoSRv3.Audit.Source.AragonACLSource

/-- **Kill-line: isAuthorizedRouter projects stakingRouterRole.** -/
theorem isAuthorizedRouter_projection (state : ACLState) :
    isAuthorizedRouter state = state.stakingRouterRole := rfl

/-- **Kill-line: isAuthorizedRouter true iff stakingRouterRole true.** -/
theorem isAuthorizedRouter_true_at_witness :
    isAuthorizedRouter ⟨true, false⟩ = true := rfl

/-- **Kill-line: isAuthorizedRouter false when stakingRouterRole false.** -/
theorem isAuthorizedRouter_false_at_witness :
    isAuthorizedRouter ⟨false, true⟩ = false := rfl

/-- **Kill-line: hasRole picks the correct field for STAKING_ROUTER_ROLE.** -/
theorem hasRole_staking_router_at_witness :
    ACLState.hasRole ⟨true, false⟩ "STAKING_ROUTER_ROLE" = true := rfl

/-- **Kill-line: hasRole picks the correct field for TOP_UP_GATEWAY_APP.** -/
theorem hasRole_top_up_gateway_at_witness :
    ACLState.hasRole ⟨false, true⟩ "TOP_UP_GATEWAY_APP" = true := rfl

/-- **Kill-line: hasRole returns false on unknown role names.** -/
theorem hasRole_unknown_role :
    ACLState.hasRole ⟨true, true⟩ "UNKNOWN_ROLE" = false := rfl

/-- **Kill-line: hasRole distinguishes the two named roles.** -/
theorem hasRole_distinguishes_roles :
    ACLState.hasRole ⟨true, false⟩ "STAKING_ROUTER_ROLE" ≠
      ACLState.hasRole ⟨true, false⟩ "TOP_UP_GATEWAY_APP" := by decide

/-- **Kill-line: ACLState with both roles is distinct from
either-role-only.** -/
theorem ACLState_distinctness :
    (⟨true, true⟩ : ACLState) ≠ ⟨true, false⟩ := by decide

#print axioms isAuthorizedRouter_projection
#print axioms isAuthorizedRouter_true_at_witness
#print axioms isAuthorizedRouter_false_at_witness
#print axioms hasRole_staking_router_at_witness
#print axioms hasRole_top_up_gateway_at_witness
#print axioms hasRole_unknown_role
#print axioms hasRole_distinguishes_roles
#print axioms ACLState_distinctness

end LidoSRv3.Tests.AragonACLSourceKillLines
