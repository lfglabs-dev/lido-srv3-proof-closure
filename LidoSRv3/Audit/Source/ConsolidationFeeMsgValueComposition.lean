import LidoSRv3.Audit.Source.ConsolidationFeeLiveStaticcallSource
import LidoSRv3.Audit.Source.ConsolidationMsgValueSource
import LidoSRv3.Audit.Source.ConsolidationBatchSizeSource

/-! # ConsolidationGateway fee-STATICCALL / msgValue / batchSize composition

**General rule (Thomas 2026-09-13, real derivation composing the
three chantier-1/5 pinned source models for CONSOLIDATION-ETH-1's
fee-batchSize claim.)**

The pinned ConsolidationGateway executes the following per-call:
1. STATICCALL the EIP-7251 predeploy for the per-request fee.
2. Compute msgValue = batchSize * fee.
3. Enforce batchSize ≤ MAX_CONSOLIDATION_REQUESTS_PER_TX (2900).
4. Pass msgValue to the vault.

This composition combines the three previously-registered source
models (ConsolidationFeeLiveStaticcallSource,
ConsolidationMsgValueSource, ConsolidationBatchSizeSource) into
a single named derivation of the pinned vault-received amount as a
source-level function of the live env, batchSize, and pinned max.

**Status:** first composition of the three chantier-1/5 source
models — the vault-received value is a named source-level function
of `(env, batchSize, max)`, not a caller-supplied opaque. -/

namespace LidoSRv3.Audit.Source.ConsolidationFeeMsgValueComposition

open LidoSRv3.Audit.Source.ConsolidationFeeStaticcallSource
open LidoSRv3.Audit.Source.ConsolidationFeeLiveStaticcallSource
open LidoSRv3.Audit.Source.ConsolidationMsgValueSource
open LidoSRv3.Audit.Source.ConsolidationBatchSizeSource

/-- Composite: derive the pinned vault-received msgValue as a
function of the live EVM STATICCALL env and batchSize. -/
def vaultMsgValueFromLiveEnv
    (env : EVMStaticcallEnv) (batchSize : Nat) : Nat :=
  msgValueForBatch batchSize
    (consolidationFeeFromStaticcall (executeStaticcall env))

/-- Under the pinned gate-passing premise (batchSize ≤ MAX and
nonzero) and a nonzero live fee, the vault-received msgValue is
nonzero. Real derivation. -/
theorem vaultMsgValue_pos_of_gates_pass_and_fee_pos
    {env : EVMStaticcallEnv} {batchSize : Nat}
    (hBatchPos : 0 < batchSize)
    (_hBatchLe : batchSize ≤ maxConsolidationRequestsPerTx)
    (hFeePos : 0 < consolidationFeeFromStaticcall (executeStaticcall env)) :
    0 < vaultMsgValueFromLiveEnv env batchSize := by
  unfold vaultMsgValueFromLiveEnv
  exact msgValueForBatch_pos_of_nonzero hBatchPos hFeePos

/-- Under the pinned zero-fee premise, the vault-received msgValue
is zero regardless of the batch size — the A-CONSOLIDATION-GATEWAY-
NONZERO edge case. Real derivation. -/
theorem vaultMsgValue_zero_of_fee_zero
    {env : EVMStaticcallEnv} {batchSize : Nat}
    (hFeeZero : consolidationFeeFromStaticcall (executeStaticcall env) = 0) :
    vaultMsgValueFromLiveEnv env batchSize = 0 := by
  unfold vaultMsgValueFromLiveEnv
  rw [hFeeZero]
  exact msgValueForBatch_zero_of_fee_zero batchSize

/-- Under the pinned gate-failing premise (batchSize > MAX), the
batchSize guard fails. -/
theorem batchSize_gate_fails_of_gt
    {batchSize : Nat}
    (hBatchGt : maxConsolidationRequestsPerTx < batchSize) :
    batchSizeWithinLimit batchSize = false :=
  batchSizeWithinLimit_false_of_gt hBatchGt

end LidoSRv3.Audit.Source.ConsolidationFeeMsgValueComposition
