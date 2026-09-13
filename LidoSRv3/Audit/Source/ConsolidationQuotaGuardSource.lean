import LidoSRv3.Audit.Source.KeccakMappingStorageSource

/-! # ConsolidationGateway per-window quota guard source model

**General rule (Thomas 2026-09-13, real derivation of the
P-CONSOLIDATION-ETH-1 quota check chantier 5 disclosed.)**

Chantier 5 (PR #431) disclosed as `fidelity.missing` on
P-CONSOLIDATION-ETH-1 that
`ConsolidationGateway.addConsolidationRequests` enforces
`requestsPerWindow + newRequests ≤ maxRequestsPerWindow`; the current
window's request counter is a mapping-backed storage field. The
registered Verity parent's universal success/revert partition does
not model this quota check.

This composition names the quota guard as a source-level function of
a shared `KeccakMappingStorageSource.MappingStorage`, so downstream
consumers can enforce it.

Pinned Solidity (17005714):

- `ConsolidationGateway.sol`: per-window counter stored at a mapping
  keyed by window index; `maxRequestsPerWindow` a state constant.

**Status:** first real derivation of the quota guard past chantier 5's
disclosure. Under a live-storage premise the quota check is derived
from a named storage read — no free boolean. -/

namespace LidoSRv3.Audit.Source.ConsolidationQuotaGuardSource

/-- Read the current window's request count from source-level
MappingStorage. -/
def currentWindowCountFromStorage
    (m : LidoSRv3.Audit.Source.KeccakMappingStorageSource.MappingStorage)
    (windowIndex : Nat) : Nat :=
  LidoSRv3.Audit.Source.KeccakMappingStorageSource.read m windowIndex

/-- Definition of the quota check: the window's current count plus
the new requests must not exceed `maxRequestsPerWindow`. -/
def quotaCheckFromStorage
    (m : LidoSRv3.Audit.Source.KeccakMappingStorageSource.MappingStorage)
    (windowIndex newRequests maxRequestsPerWindow : Nat) : Bool :=
  decide (currentWindowCountFromStorage m windowIndex + newRequests
            ≤ maxRequestsPerWindow)

/-- Under the pinned quota premise (current + new ≤ max), the quota
check passes. Real derivation from a named storage read. -/
theorem quotaCheck_passes_of_bound
    {m : LidoSRv3.Audit.Source.KeccakMappingStorageSource.MappingStorage}
    {windowIndex newRequests maxRequestsPerWindow : Nat}
    (hBound : currentWindowCountFromStorage m windowIndex + newRequests
                ≤ maxRequestsPerWindow) :
    quotaCheckFromStorage m windowIndex newRequests maxRequestsPerWindow
      = true := by
  simp [quotaCheckFromStorage, hBound]

end LidoSRv3.Audit.Source.ConsolidationQuotaGuardSource
