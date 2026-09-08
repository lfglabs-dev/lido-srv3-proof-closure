# P-SSZ-1 / P-TOPUP-1 / P-TOPUP-2 trio status

Solidity pin: `lidofinance/core@17005714f151e5502c559932319a3f2f74ac2436`
Branch: `audit/trio-ssz-topup-sha-bridge` from main `caad1ef5`
Date: 2026-09-08

## Proof IDs

| ID | File | Status |
|----|------|--------|
| P-SSZ-1 | `LidoSRv3/Audit/Guarantees/PSsz1.lean` | Transport-independent additions |
| P-TOPUP-1 | `LidoSRv3/Audit/Guarantees/PTopup1.lean` | Transport-independent additions |
| P-TOPUP-2 | `LidoSRv3/Audit/Guarantees/PTopup2.lean` | Transport-independent additions |

## Transport-independent work completed

### P-SSZ-1
- SHA-256 sequential acceptance model (`SequentialDigestAcceptance`)
  - Explicit DAG edges for all 6 producer→consumer relationships in the 7-call chain
  - Proved: `sequential_digest_acceptance` — the chain satisfies sequential acceptance
  - Proved: `sequential_acceptance_implies_exact_composition` — sequential acceptance implies `ExactDigestComposition`
- Real SSZ generalized-index encoding
  - Production constant: `GI_FIRST_VALIDATOR_CURR` = 150 * 2^40, pow = 40
  - `validatorGIndex` function mapping validator index to production gindex
  - Proved: injectivity, 248-bit bound, path depth ≤ 80
  - Connected to constructor-pin from `ProductionGindexChild`
  - General `log2_eq_of_le_lt`: Nat.log2 characterization from power-of-two band
  - `validatorGI_hasGeneralizedIndex`: full HasGeneralizedIndex for ALL vi < 2^40
  - `branchPath_reconstructs`: general path reconstruction for any generalized index
  - `sourceConcat_stateRoot_validatorTree`: production concat binding (5526 * 2^40)

### P-TOPUP-1
- Full `allocateDeposits` ABI model (`AllocateDepositsArgs`)
  - All five production arguments: roundedTargetGwei, pubkeys, keyIndices, operatorIds, topUpLimits
  - `sourceAllocateDepositsArgs` threads pubkeys as explicit parameter (source model abstracts to lengths)
  - `sourceAllocateDepositsArgs_wellFormed`: well-formedness when pubkey/limit lengths match
  - `CalleeEffects` structure preserving per-index bound and length match
  - `calleeEffects_per_index_bound`: each allocation bounded by its limit
- Sequential acceptance (`executeGuarded_returndata_is_push_input`)
  - Delegates to `Verity.TopupTx.executeGuarded_observes_source` — all four premises used
  - Asserts first journalled call name is `"allocateDeposits"`
- Callee non-triviality
  - `callee_return_reaches_push_when_guards_pass`: well-formed returns are not silently dropped

### P-TOPUP-2
- Wei/gwei conversion model
  - `weiToGwei`, `gweiToWei` with round-trip proofs under alignment
  - `transition_sum_wei_le_valueWei`: total allocated wei ≤ call value
  - `transitionBudget_uses_gwei_value`: budget is in gwei domain
- Top-up freshness model
  - `rootIsFresh`: beacon root age bounded by `maxRootAge`
  - `well_formed_pre_implies_fresh`: well-formedness implies freshness
  - Concrete counterexample: stale root rejected
- Inter-call policy model
  - `interCallConsistent`: allocations = transition(module return, limits)
  - `well_formed_batch_implies_interCallConsistent`: well-formedness implies consistency
  - `interCall_allocations_bounded`: consistent allocations bounded by block cap
- Allocation length preservation
  - `transition_length`, `well_formed_batch_allocation_length`
- Composed well-formedness
  - `well_formed_batch_composition`: freshness ∧ inter-call ∧ cap ∧ value budget

## Structural blockers (OPEN — awaiting lake build verification)

See `sha-bridge/README.md` for details. All three are now discharged from code:
1. SHA-256 sequential acceptance — `verity_tx_with_sequential_digest_acceptance` (universal closure)
2. Production SSZ gindex encoding — `validatorGI_hasGeneralizedIndex` (full `HasGeneralizedIndex` for ALL vi < 2^40) + `branchPath_reconstructs` (general path reconstruction) + `sourceConcat_stateRoot_validatorTree`
3. allocateDeposits ABI fidelity — `argsToTopupCall` + `calleeEffects_sum_bounded` + `callee_and_transition_compose` + `full_allocation_constraint`

## Constraints

- 20 finite pinned-SHA engine checks are NOT full guarantee closure
- Three structural blockers discharged from code (were OPEN)
- Independent spec; no tautology; no always-success callee stubs; no sorry
- No prod archive-forward dependency (still `4622ddd8`)
