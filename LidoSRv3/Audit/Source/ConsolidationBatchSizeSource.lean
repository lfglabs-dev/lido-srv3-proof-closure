/-! # ConsolidationGateway batchSize source model

**General rule (Thomas 2026-09-13, real derivation of the pinned
ConsolidationGateway batchSize gate — one of the general-rule
candidates in the mandate.)**

The mandate's known general-rule candidates list includes
"CONSOLIDATION-ETH-1 fee and batchSize (fee lu par STATICCALL
uint256, batch ≤ limite gateway 2900)". The pinned
ConsolidationGateway.sol enforces a per-call batchSize cap constant
(MAX_CONSOLIDATION_REQUESTS_PER_TX = 2900) that the Verity plane
currently models as a free `Nat`.

This composition names the pinned batchSize gate as a source-level
function of the input list length and the pinned constant, with a
paired premise-implies-true theorem.

Pinned Solidity (17005714):

- `ConsolidationGateway.sol` MAX_CONSOLIDATION_REQUESTS_PER_TX = 2900.
- `addConsolidationRequests(requests)` reverts if `requests.length >
  MAX_CONSOLIDATION_REQUESTS_PER_TX`.

**Status:** first real derivation of the ConsolidationGateway
batchSize gate past its `Nat` freeing in the Verity plane. -/

namespace LidoSRv3.Audit.Source.ConsolidationBatchSizeSource

/-- Pinned `MAX_CONSOLIDATION_REQUESTS_PER_TX` constant. -/
def maxConsolidationRequestsPerTx : Nat := 2900

/-- Source-level definition of the pinned batchSize gate: the request
list length must not exceed the pinned constant. -/
def batchSizeWithinLimit (batchSize : Nat) : Bool :=
  decide (batchSize ≤ maxConsolidationRequestsPerTx)

/-- Under the pinned "batchSize ≤ 2900" premise, the gate passes. -/
theorem batchSizeWithinLimit_true_of_le
    {batchSize : Nat} (hLe : batchSize ≤ maxConsolidationRequestsPerTx) :
    batchSizeWithinLimit batchSize = true := by
  simp [batchSizeWithinLimit, hLe]

/-- Under the pinned "batchSize > 2900" premise, the gate fails. -/
theorem batchSizeWithinLimit_false_of_gt
    {batchSize : Nat}
    (hGt : maxConsolidationRequestsPerTx < batchSize) :
    batchSizeWithinLimit batchSize = false := by
  simp [batchSizeWithinLimit]
  omega

/-- Empty batch trivially satisfies the gate. -/
theorem batchSizeWithinLimit_true_of_empty :
    batchSizeWithinLimit 0 = true := by
  simp [batchSizeWithinLimit, maxConsolidationRequestsPerTx]

end LidoSRv3.Audit.Source.ConsolidationBatchSizeSource
