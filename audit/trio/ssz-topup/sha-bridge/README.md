# SHA-bridge structural blockers

Three structural blockers for the P-SSZ-1 / P-TOPUP-1 / P-TOPUP-2 trio.
Each blocker is OPEN until discharged from code; naming the hypothesis alone
does not satisfy it.

Solidity pin: `lidofinance/core@17005714f151e5502c559932319a3f2f74ac2436`.

## Blocker 1: SHA-256 sequential acceptance (P-SSZ-1)

**Status: DISCHARGED**

`PSsz1.verity_tx_with_sequential_digest_acceptance` composes the
universal `sequential_digest_acceptance` (proved for ALL `Inputs`, not
just 20 test vectors) with the Verity transaction's structural
properties.  `SequentialDigestAcceptance` is strictly stronger than
`DigestChainIsExact`: it additionally proves DAG connectivity — each
intermediate digest feeds into the right preimage position of the next
call.  `sequential_acceptance_strictly_stronger` witnesses the
implication.

## Blocker 2: Production SSZ gindex encoding (P-SSZ-1)

**Status: DISCHARGED**

**Part 1 — General log2 characterization:**
`PSsz1.log2_eq_of_le_lt` provides `2^k ≤ n → n < 2^(k+1) → Nat.log2 n = k`,
filling an infrastructure gap in `Init.Data.Nat.Log2` (which has only
`log2_def` and `log2_le_self`).  `log2_pow2_eq` derives `Nat.log2 (2^k) = k`.

**Part 2 — Universal depth/pivot for ALL vi < 2^40:**
`PSsz1.validatorGIndex_in_production_band` proves all gindices lie in
[2^47, 2^48).  `validatorGIndex_log2_47` proves `Nat.log2 = 47` for all vi.
`validatorGI_pivot` proves `pivot = 2^47` for all vi.
`validatorGI_branchPath_length` proves path length = 47 for all vi.

Differential: previous state had only the base case (vi=0) via `decide`;
new state covers ALL 2^40 validator indices via general inductive proofs.

**Part 3 — General path reconstruction:**
`PSsz1.pathOffset_pathAux_add_pivot` proves by induction on fuel that
`pathOffset (pathAux d v) + 2^(log2 v) = v` for all `v < 2^(d+1)`.
`branchPath_reconstructs` uses this to prove
`indexFromPivotPath (pivot gi) (branchPath gi) = gi.value` for ANY
generalized index — the path encoding is a faithful inverse of bit
decomposition.

**Part 4 — Full HasGeneralizedIndex for all validators:**
`PSsz1.validatorGI_hasGeneralizedIndex` composes Parts 2–3 to prove
`HasGeneralizedIndex gi (2^47) (branchPath gi)` for ALL vi < 2^40:
pivot match, path length match, and index reconstruction.

**Part 5 — sourceConcat binding:**
`PSsz1.sourceConcat_stateRoot_validatorTree` proves the production
`concat(GI_STATE_ROOT, validatorTreeGI)` succeeds and produces the
expected concatenated value (5526 * 2^40 at pow=40), with
`stateRootGIndex` binding `GI_STATE_ROOT` = (index=43, pow=0) and
packed 0x2B00.

## Blocker 3: allocateDeposits ABI fidelity (P-TOPUP-1)

**Status: DISCHARGED**

**Part 1 — Full five-argument calldata model:**
`AllocateDepositsArgs` carries all five production arguments
(roundedTargetGwei, pubkeys, keyIndices, operatorIds, topUpLimits).
`sourceAllocateDepositsArgs` constructs a complete record from production
inputs with pubkeys threaded explicitly.
`argsToTopupCall` maps the full ABI record to the executable's
`TopupCall`, showing which fields the router inspects after the module
returns.  `executable_calldata_from_args` confirms the executable frame's
`[evmWord keyCount]` calldata is the expected projection.

**Part 2 — Callee observable effects → P-TOPUP-2 budget model:**
`CalleeEffects` captures the per-index bound (`alloc[i] ≤ limit[i]`).
`calleeEffects_sum_bounded` proves the callee's allocation sum is at most
the limits sum (via `Forall₂ → sum` inequality).
`callee_and_transition_compose` composes `CalleeEffects` with P-TOPUP-2's
`interCallConsistent` and `aggregate_bounded_by_block_cap` to show
accepted allocations respect the per-block budget cap.
`full_allocation_constraint` combines both: the callee's return is
per-key bounded by limits AND aggregate bounded by the block cap.
