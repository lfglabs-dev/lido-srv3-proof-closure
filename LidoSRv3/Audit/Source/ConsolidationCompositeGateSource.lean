import LidoSRv3.Audit.Source.ConsolidationRoleViaOracleSource
import LidoSRv3.Audit.Source.ConsolidationPauseSlotViaOracleSource
import LidoSRv3.Audit.Source.ConsolidationQuotaSlotViaOracleSource
import LidoSRv3.Audit.Source.ConsolidationBatchSizeSource

/-! # P-CONSOLIDATION-ETH-1 composite entry-gate source model

**General rule (Thomas 2026-09-13, chantier 5): compose the four
pinned entry-gate source models (role + pause + quota + batchSize)
into a single named composite gate for
`ConsolidationGateway.addConsolidationRequests`.**

Under the pinned entry-gate premises (ADD_CONSOLIDATION_REQUESTS_ROLE
granted, gateway not paused, per-window quota satisfied, batchSize
≤ 2900), the composite gate passes and downstream state transitions
apply.

**Status:** first real composition of the four chantier-5
disclosures (role/pause/quota/batchSize) into a single named
entry-gate function. -/

namespace LidoSRv3.Audit.Source.ConsolidationCompositeGateSource

open LidoSRv3.Audit.Source.KeccakConcreteCommitmentSource
open LidoSRv3.Audit.Source.ConsolidationRoleViaOracleSource
open LidoSRv3.Audit.Source.ConsolidationPauseSlotViaOracleSource
open LidoSRv3.Audit.Source.ConsolidationQuotaSlotViaOracleSource
open LidoSRv3.Audit.Source.ConsolidationBatchSizeSource

/-- Composite entry gate: all four pinned checks must pass. -/
def entryGatePasses
    (oracle : KeccakOracle)
    (aclBaseSlot pauseBaseSlot pauseSlotKey
       quotaBaseSlot windowIndex newRequests maxRequestsPerWindow
       batchSize : Nat) : Bool :=
  hasAddConsolidationRequestsRoleFromOracle oracle aclBaseSlot
    && whenResumedGuardFromOracle oracle pauseBaseSlot pauseSlotKey
    && quotaCheckFromOracle oracle quotaBaseSlot windowIndex
         newRequests maxRequestsPerWindow
    && batchSizeWithinLimit batchSize

/-- Under all four pinned premises, the composite entry gate passes. -/
theorem entryGatePasses_true_of_all_premises
    {oracle : KeccakOracle}
    {aclBaseSlot pauseBaseSlot pauseSlotKey
       quotaBaseSlot windowIndex newRequests maxRequestsPerWindow
       batchSize : Nat}
    (hRole : hasAddConsolidationRequestsRoleFromOracle oracle aclBaseSlot
              = true)
    (hPause : whenResumedGuardFromOracle oracle pauseBaseSlot pauseSlotKey
              = true)
    (hQuota : quotaCheckFromOracle oracle quotaBaseSlot windowIndex
                newRequests maxRequestsPerWindow = true)
    (hBatch : batchSizeWithinLimit batchSize = true) :
    entryGatePasses oracle aclBaseSlot pauseBaseSlot pauseSlotKey
      quotaBaseSlot windowIndex newRequests maxRequestsPerWindow batchSize
      = true := by
  simp [entryGatePasses, hRole, hPause, hQuota, hBatch]

end LidoSRv3.Audit.Source.ConsolidationCompositeGateSource
