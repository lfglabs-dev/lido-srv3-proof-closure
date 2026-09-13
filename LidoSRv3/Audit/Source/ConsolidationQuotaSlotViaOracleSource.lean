import LidoSRv3.Audit.Source.ConsolidationQuotaGuardSource
import LidoSRv3.Audit.Source.MappingSlotViaOracleSource

/-! # ConsolidationGateway quota guard via realMappingStorage

**General rule (Thomas 2026-09-13, chain the quota-guard's
MappingStorage through the shared oracle-backed realMappingStorage.)**

`ConsolidationQuotaGuardSource.quotaCheckFromStorage` takes a free
`MappingStorage`. This composition specialises it to a
`realMappingStorage oracle quotaBaseSlot` so the per-window counter's
storage slot is derived through the shared A-KECCAK-COMMITMENT oracle
rather than a free `Nat → Nat`.

Pinned Solidity (17005714):

- `ConsolidationGateway.sol`: per-window counter stored at a mapping
  keyed by window index; the mapping's slot layout follows the
  standard Solidity `mapping(uint256 => uint256)` rule.

**Status:** derives the quota-counter MappingStorage from the shared
oracle, tightening the P-CONSOLIDATION-ETH-1 quota guard past a free
MappingStorage. -/

namespace LidoSRv3.Audit.Source.ConsolidationQuotaSlotViaOracleSource

open LidoSRv3.Audit.Source.KeccakConcreteCommitmentSource
open LidoSRv3.Audit.Source.MappingSlotViaOracleSource
open LidoSRv3.Audit.Source.ConsolidationQuotaGuardSource

/-- Compose `quotaCheckFromStorage` with the shared oracle-backed
mapping storage. The quota's current-window counter is now a
function of `(oracle, quotaBaseSlot, windowIndex)`. -/
def quotaCheckFromOracle
    (oracle : KeccakOracle)
    (quotaBaseSlot windowIndex newRequests maxRequestsPerWindow : Nat) : Bool :=
  quotaCheckFromStorage (realMappingStorage oracle quotaBaseSlot)
    windowIndex newRequests maxRequestsPerWindow

/-- Under the pinned quota premise (current + new ≤ max), the
oracle-backed quota check passes. Real derivation. -/
theorem quotaCheckFromOracle_passes_of_bound
    {oracle : KeccakOracle}
    {quotaBaseSlot windowIndex newRequests maxRequestsPerWindow : Nat}
    (hBound : currentWindowCountFromStorage
                (realMappingStorage oracle quotaBaseSlot) windowIndex
                + newRequests ≤ maxRequestsPerWindow) :
    quotaCheckFromOracle oracle quotaBaseSlot windowIndex newRequests
      maxRequestsPerWindow = true := by
  unfold quotaCheckFromOracle
  exact quotaCheck_passes_of_bound hBound

end LidoSRv3.Audit.Source.ConsolidationQuotaSlotViaOracleSource
