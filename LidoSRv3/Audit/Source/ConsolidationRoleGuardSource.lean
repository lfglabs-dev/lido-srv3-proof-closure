import LidoSRv3.Audit.Source.AragonACLSource

/-! # ConsolidationGateway ADD_CONSOLIDATION_REQUESTS_ROLE source model

**General rule (Thomas 2026-09-13, real derivation of the
P-CONSOLIDATION-ETH-1 role guard chantier 5 disclosed.)**

Chantier 5 (mandate 2026-09-12, PR #431) disclosed as
`fidelity.missing` on P-CONSOLIDATION-ETH-1 that
`ConsolidationGateway.addConsolidationRequests` at
`contracts/0.8.25/consolidation/ConsolidationGateway.sol:185-223`
gates entry on `onlyRole(ADD_CONSOLIDATION_REQUESTS_ROLE)`. The
registered Verity parent's universal success/revert partition does
not model this role check.

This composition names the role guard as a source-level function of
a shared `AragonACLSource.ACLState`, so downstream P-CONSOLIDATION-
ETH-1 consumers can enforce it.

Pinned Solidity (17005714):

- `ConsolidationGateway.sol` `onlyRole(ADD_CONSOLIDATION_REQUESTS_ROLE)`
  modifier check via inherited access-control chain.

**Status:** first real derivation of the role guard past chantier 5's
disclosure. Under a live-ACL premise the role check is derived from
a named ACL state — no free boolean. -/

namespace LidoSRv3.Audit.Source.ConsolidationRoleGuardSource

/-- Definition of `hasAddConsolidationRequestsRole` from source-level
Aragon ACL state. -/
def hasAddConsolidationRequestsRole
    (acl : LidoSRv3.Audit.Source.AragonACLSource.ACLState) : Bool :=
  LidoSRv3.Audit.Source.AragonACLSource.hasPermission acl
    "ADD_CONSOLIDATION_REQUESTS_ROLE"

/-- Under the pinned ACL premise (role granted),
`hasAddConsolidationRequestsRole = true`. Real derivation from a
named ACL role read. -/
theorem role_granted_of_acl
    {acl : LidoSRv3.Audit.Source.AragonACLSource.ACLState}
    (hRole : acl.hasRole "ADD_CONSOLIDATION_REQUESTS_ROLE" = true) :
    hasAddConsolidationRequestsRole acl = true := by
  simp [hasAddConsolidationRequestsRole,
        LidoSRv3.Audit.Source.AragonACLSource.hasPermission, hRole]

end LidoSRv3.Audit.Source.ConsolidationRoleGuardSource
