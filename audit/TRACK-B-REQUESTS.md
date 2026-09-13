# Track-B-REQUESTS

Per shared rules (~/work/goals/lido-common.md rule 6): shared changes needed
across tracks are described here. Piste B (Thomas 2026-09-13 mandate: DEPOSIT-1,
TOPUP-2, ADDRESS-1) has completed six substantive PRs on Chantier 1 DEPOSIT-1
this session. The items below are the remaining Chantier 1/2/3 obligations
that cannot be closed by isolated additions per the 2026-09-13 rule (each
requires a real registered-parent-statement change or a D-* discharge that
turns a Grok vector green).

## 2026-09-13: Chantier 1 DEPOSIT-1 remaining

### D-CALL-1 per-key-push half (grok #412)

Pinned `BeaconChainDepositor.sol:57` emits one
`IDepositContract.deposit{value: 32 ether}(publicKey, ...)` per key. Model's
`DepositNFrameTx.pushBatch` still journals one aggregate `depositToBeacon`
per batch carrying `batch.keys * DEPOSIT_SIZE`. The two-argument-pull half
was discharged in PR #568 (merge commit `bfc6ad53`); the per-key-push half
is deferred.

Required change: rewrite `DepositNFrameTx.pushBatch` to a per-key
`List.mapM` loop emitting `batch.keys` individual `deposit` frames each
carrying `depositSize` wei and a per-key `depositDataRoot`. The
`depositDataRoot` currently lives on the batch level; either lift it to a
per-key field or synthesise per-key roots from a batch-level Merkle
commitment. `expectedCalls`, `afterPushes`, `execute_apply`,
`committed_calls`, `committed_balance` all case-split against
`batch.keys.val` and need re-proving.

Registered parent: `verity_tx_composes_nframe_deposit_under_router_shape`
still carries `ExecutesNFrameJournal := ParentConclusion execute`, so the
executor change flows through automatically.

### D-SLOT-1 ERC-7201 keyed storage (grok #412)

Pin uses ERC-7201 namespaced storage: `SRStorage.sol:14-16` derives
`ROUTER_STORAGE_POSITION = keccak256(abi.encode(uint256(keccak256(
"lido.StakingRouter.routerStorage")) - 1)) & ~bytes32(uint256(0xff))`;
`RouterState.moduleStates[moduleId]` is the mapping. `_updateModuleLastDepositState`
writes into `state.deposits` at the derived slot indexed by `moduleId`.

Model's `DepositNFrameTx.counterSlot := 0` is a fixed slot updated once
per `execute`. Required change: derive an ERC-7201-anchored slot
constant `moduleStatesDepositsSlot`, use `state.writeMapUint
moduleStatesDepositsSlot batch.moduleId ...` per-batch, and emit a
`StakingRouterETHDeposited` event frame. Proof cascade through
`readSlot_afterBatches` / `calls_afterBatches` / `execute_apply`.

### Retire free booleans from Preconditions (Thomas 2026-09-13)

**Partial progress (Piste B session 2026-09-13, five PRs merged):**

- **`Preconditions.entryBalance = 0` retired** (PR #587): relaxed to
  `entryBalanceNoWrap : state.selfBalance.val + exactTotal inputs.batches
  < Uint256.modulus`. Old premise strictly stronger; nonzero-selfBalance
  router states now compose.
- **`Preconditions.funded` retired** (PR #590): unconditional Lido funding
  bound relaxed to conditional `shouldPull inputs = true → wordTotal ≤ ...`.
  Underfunded-Lido empty-batch inputs now compose.
- **`Preconditions.lidoCallOk` retired** (PR #591): unconditional
  `inputs.lidoCallOk = true` relaxed to conditional
  `shouldPull inputs = true → inputs.lidoCallOk = true`. Failing-Lido
  empty-batch inputs now compose.
- **`Preconditions.conserving` retired** (PR #595): unconditional conserving
  premise relaxed to conditional `shouldPull inputs = true → maxEBType1 =
  depositSize`. Skewed-deployment empty-batch inputs now compose.
- **`Preconditions.entryBalanceNoWrap` further relaxed** (PR #597): the
  non-wrap premise from #587 further relaxed to conditional-on-shouldPull.
  Arbitrary router selfBalance (up to Uint256.modulus - 1) admits an
  empty-batch call.

**Remaining unconditional Preconditions (require full DSM+router
composition, not conditional-on-shouldPull relaxation because the pinned
guards fire BEFORE the shouldPull early return):**

- `Preconditions.authorized : inputs.authorized = true` — pinned
  `StakingRouter.sol:943` `_checkAppAuth(_getDepositSecurityModule())`
  fires before line-978 early return. Conditional-on-shouldPull relaxation
  would diverge from pin (accept unauthorized empty calls). Requires the
  DSM caller admission composition (source model exists at
  `LidoSRv3/Audit/Source/DepositDsmCall.lean` but is complex; needs a
  leaner premise API).
- `Preconditions.moduleActive : inputs.moduleActive = true` — pinned
  `:946` ModuleState config gate fires before line-978. Requires router-
  side pinned admission chain composition.
- `Preconditions.allocationValid : inputs.allocationValid = true` — pinned
  `:954-969` maxDepositsCount / ZeroDeposits / WrongPubkeyLength /
  ModuleReturnExceedTarget guards fire before line-978. Requires
  composition with the pinned allocation-validity premises.

**Structurally unconditional (relaxation would be unsound):**

- `Preconditions.distinctModules`, `.foldStable`, `.valueMatches` gate
  model-added requires on per-batch content (moduleIds, amounts) that are
  independent of the `shouldPull` aggregate. Relaxing them to
  conditional-on-shouldPull would allow inputs with e.g. duplicate
  moduleIds but exactKeys = 0 to fail the executor guard — unsound.

### Grok #412 harness integration into `make test`

`grok/lido-differential-deposit-1-20260912` (PR #412) is checked out in a
separate worktree (`~/work/lido/wt-deposit-differential-412`) and remains
untouched. Its `solidity/deposit/test/DepositDifferential.t.sol` currently
asserts that D-* divergences EXIST (e.g., `require(sol.selector !=
bytes4(keccak256("NOT_AUTHORIZED()")), "encoding divergence D-REVERT-1")`).

After D-EMPTY-PULL / D-REVERT-1 / D-SKEW-1 / D-NFRAME-1 / D-CALL-1
two-arg-pull half discharges (PRs #553 / #561 / #564 / #566 / #568), the
harness assertions must be flipped from `!=` (divergence) to `==`
(equivalence) before the harness can be merged into `make test`. This is a
Grok-branch edit; per the mandate the Grok branch is never rewritten.
Options: (a) fork the harness into `scripts/` on main and flip assertions;
(b) merge #412 as-is and edit our copy post-merge. Deferred until
D-SLOT-1 and D-CALL-1 per-key-push half also land, so a single flip
covers all six.

## 2026-09-13: Chantier 2 TOPUP-2 remaining (grok #417)

**Session shipping notes (2026-09-13, this branch)**: two slices of task #10
merged into main this session:
- PR #654 (`aa114745…` initial `98b697a9…`): reparameterized
  `verity_tx_simulates_topup2_spec` from hardcoded `≤ 32` to caller-supplied
  `maxValidators : Nat`, sourced from pinned `uint64 $.maxValidatorsPerTopUp`
  (`TopUpGateway.sol:42`, packed slot 0 of `TopupPackedStorage`). Discharges
  Thomas's mandate line "count ≤ 32 devient maxValidatorsPerTopUp uint64 de
  la config".
- PR #660 (SHA `aa114745…`): **D-SLASH-1 discharge**. Added caller-supplied
  `slashedOrExited : List Bool` gate at `evaluateTopUpLimit`, threaded
  through `sourceLimits`, `sourceRun`, `sourceRunIndependent` (+ `_eq_`
  bridge for all 8 length-mismatch cases), `Topup2DistributionTx.allocate`,
  `verity_tx_simulates_pinned_source`, `PTopup2.verity_tx_simulates_topup2_spec`,
  keccak-oracle mirror, and `TopupUnboundedCount` chain
  (`allocateAnyCount`, `allocate_eq_any_of_le`,
  `verity_tx_simulates_pinned_source_any_count`,
  `parent_verity_is_unbounded_instance`,
  `parent_verity_instance_matches_registered`). D-SLASH-1 moved from
  `fidelity.missing` to `fidelity.covered`. 1991/1991 modules build clean.

**Remaining D-* on the registered Verity parent**:

- **D-CONSUME-1**: `Verity.sourceRun` still walks `sourceConsume`
  (leftover-budget); pinned `TopUpGateway.sol:226-232` writes
  `topUpLimits[i] = _evaluateTopUpLimit(...) * 1 gwei` independently per
  index. Requires rewriting `sourceRun` to produce independent limits,
  cascading into `verity_tx_simulates_topup2_spec`'s executable-plane
  correspondence. **Scope estimate (post-PR #654/#660)**: 6-8 file touches
  (`Topup2Correspondence.lean` `sourceConsume`/`sourceRun`,
  `Topup2DistributionTx.lean` `sourceConsumeIndependent`/`sourceRunIndependent`
  + `_eq_` bridge, `TopupUnboundedCount.lean` bridge lemmas,
  `Topup2DistributionTxMutants.lean` + `TopupUnboundedCountMutants.lean` +
  `TopupKeccakOracleMutants.lean` callsites). Structural: the current
  `used`/`remaining` observables are computed from `sourceConsume` output;
  retiring the walk requires reshaping `Result`/`View` to reflect per-key
  independence and losing the leftover-cap accumulation (or splitting
  gateway-plane observables from router-plane observables).

- **D-UNITS-1**: `sourceRun` stays in gwei; pinned line 226 multiplies by
  `1 gwei` before the router call. Requires an explicit
  gwei→wei step in `sourceRun` consumed by the registered
  `verity_tx_simulates_topup2_spec`. A first attempt (adding an
  isolated `evaluated_topup_limit_wei` helper to `PTopup2.lean`) was
  correctly BLOCKED by fresh-context review as an isolated source-model
  addition (no registered parent consumes it). The real fix must
  restructure the Verity `sourceRun` executable plane.
  **Scope estimate**: 4-6 file touches, propagates through the budget
  arithmetic (`budget := minWord valueGwei (minWord moduleLimit remainingCap)` —
  the caller-supplied `valueGwei` and `moduleLimit` need to become wei so
  the min is dimensionally consistent, or a unit conversion needs to be
  documented at the boundary). The `sourceLimitsIndependent` /
  `sourceCandidatesIndependent` / `sourceConsumeIndependent` copies would
  each need parallel updates.

- **D-SLASH-1**: ✅ **DISCHARGED (PR #660, 2026-09-13)**. Caller-supplied
  `slashedOrExited : List Bool` premise now threaded through the registered
  parent and downstream chain. Moved from `fidelity.missing` to
  `fidelity.covered`.

- **D-TOTAL-1**: `Verity.used` is the leftover-consumed total; pinned
  `totalLimits +=` sits in `unchecked` and gates `_setLastTopUpData`
  (TopUpGateway.sol:234-236). Requires modeling the unchecked accumulator
  and its gate. **Scope estimate**: 5-7 file touches. Concretely: add
  `totalLimits : Word` and `didSetLastTopUpData : Bool` to `Result` and
  `View` in `Topup2DistributionTx.lean`; add a new storage slot
  (`totalLimitsSlot := 33`, `didSetSlot := 34` or similar); persist inside
  `allocate` and read inside `observe`; compute `totalLimits =
  topUpLimits.foldl (·+·) 0` (unchecked `Uint256` addition); derive
  `didSetLastTopUpData := decide (totalLimits > 0)`. Proof cascade through
  the `verity_tx_simulates_pinned_source` `simp` set (`storageArray_writeSlot`,
  `readSlot_writeSlot_same/_other`) and the keccak-oracle mirror. Mutant
  test callsites (`Topup2DistributionTxMutants.lean`,
  `TopupKeccakOracleMutants.lean`, `TopupUnboundedCountMutants.lean`) need
  updated expected `View` values in every `runView` / `runAny` / `runFrozen`
  witness (~10+ callsites).

- **D-AUTH/SORT/WC/PUBKEY/MAX prefix**: `Verity.sourceRun` sees numeric
  arrays only; pinned `:160-223` prefix guards `onlyRole(TOP_UP_ROLE)`,
  strictly-increasing indices, type-0x02 WC, 48-byte pubkeys, and
  `maxValidatorsPerTopUp` are not exercised at the Verity plane. Requires
  adding executable guards to the Verity `execute`. **Scope estimate**:
  each of the five sub-items is its own slice (Track A's approach is one
  PR per guard; see PRs #650 `D-EMPTY-1`, #663 `D-AUTH-1`, #665 `D-WC-1`,
  #668 `D-CALL-1 prefix-then-suffix` on the guarded plane, all merged from
  Piste A on the TOPUP-1 parent). The Piste B TOPUP-2 mirror should
  follow the same "add caller-supplied Bool guard, thread through parent
  premise" pattern established by PR #660 for D-SLASH-1.

The registered abstract parent `router_exact_sum_bounded_under_gateway_shape`
already takes `GatewayShapedInput` (an explicit gateway-shape premise), so
its scope is bounded; the Verity parent `verity_tx_simulates_topup2_spec`
is where each of the above D-* items needs to land. **Refactor pattern
established by PR #654 (`maxValidators : Nat`) and #660
(`slashedOrExited : List Bool`)**: add caller-supplied parameter,
thread through 5-8 files, update mutant callsites, refresh guarantees.yaml
summary + `EXPECTED_CANONICAL_DETAIL_SHA256["P-TOPUP-2"]`.

**Pre-existing gate failures on main (out of Piste B scope, not
introduced by any Piste B PR)**: `P-ALLOC-1: canonical assurance detail
differs` and `P-TOPUP-1: canonical assurance detail differs` in
`scripts/audit_metadata.py check`. Both are Track A / Piste A territory
per Thomas's forbidden-files list (`PAlloc1*`, `PTopup1*`). Fresh sessions
should not attempt to fix these from Piste B.

### Grok #407 (P-TOPUP-2 live wei conversion + allocateDeposits)

`grok/lido-topup-wei-alloc-20260912` (PR #407) adds
`LidoSRv3/Audit/Source/TopupWeiAlloc.lean` and mutants. Per Thomas's
2026-09-13 rule, these must be consumed by a registered parent to be
integrated. Direct merge as-is would introduce an unused source scaffold.
Deferred pending a registered-parent consumer for its `admittedAllocations`
fail-closed model.

## 2026-09-13: Chantier 3 ADDRESS-1 remaining

Current registered parent `PAddress1.universal_address_writer_equivariance`
(line 257 of `LidoSRv3/Audit/Guarantees/PAddress1.lean`) is a projection
over `AdmissionIsCallerBlind` and `PostStateRenamesWithCaller`, which
themselves unfold to boolean projections on `LidoSRv3.Audit.SolidityAddress.
Input`'s twelve address-facing fields (`callerBalanceSufficient`,
`callerAllowanceSufficient`, `externalCallEnvironment`, `ownership`,
`requestState`, etc.).

Per goal: replace boolean projections with real address-indexed state:

- **stETH balances/allowances** (`StETH.sol:253` for `_balances` mapping,
  `:462-466` for `_allowances`): allowance-then-balance guard order. Requires
  a source model of the stETH storage layout and a keyed-map decoder.

- **WithdrawalQueueBase owner/claimed/hint** (`WithdrawalQueueBase.sol:
  467-484`): owner → `claimed = true` → hint transition sequence. Requires
  a source model of the WQ request state machine keyed by requestId.

- **externalCallSucceeds** derived from Bridge CALL model
  (`AddressRecipientCallBridge`, `_sendValue` at `525-530`,
  `CantSendValueRecipientMayHaveReverted`). Requires composing the existing
  `PAddress1BridgeCallPremise` (already exists) into the registered parent.

Registered new parent shape (rough sketch): equivariance on an
`AddressIndexedState` structure that carries stETH balances, allowances,
WQ owner/claimed/hint, and the Bridge CALL success predicate — modulo
receiver code. `report/P-ADDRESS-1.md` must be updated accordingly.

## Session tally (this branch, 2026-09-13)

Chantier 1 DEPOSIT-1 PRs merged during this Piste B session:

### Grok #412 D-* discharges (six)

| PR | Item |
|----|------|
| #553 | D-EMPTY-PULL |
| #561 | D-REVERT-1 |
| #564 | D-SKEW-1 |
| #566 | D-NFRAME-1 |
| #568 | D-CALL-1 two-arg-pull half |
| #572 | Task 8: revert_restores_snapshot on N-frame executor |

### Preconditions retirements (five)

| PR | Retirement |
|----|-----------|
| #587 | `entryBalance = 0` → `entryBalanceNoWrap` (arithmetic relaxation) |
| #590 | `funded` → conditional-on-shouldPull |
| #591 | `lidoCallOk` → conditional-on-shouldPull |
| #595 | `conserving` → conditional-on-shouldPull |
| #597 | `entryBalanceNoWrap` → further conditional-on-shouldPull |

### Documentation / track-hand-off (four)

| PR | Item |
|----|------|
| #575 | `audit/TRACK-B-REQUESTS.md` initial track-hand-off document |
| #580 | `report/P-DEPOSIT-1.md` six-discharge preamble update |
| #581 | `audit/SITE-CORRECTIONS.md` DEPOSIT-1 Piste B progress section |
| #593 | `audit/SITE-CORRECTIONS.md` Preconditions relaxations subsection |

**Total: 15 merged PRs.**

One TOPUP-2 D-UNITS-1 attempt was BLOCKED and abandoned before merge
(fresh-context review correctly flagged it as an isolated source-model
addition per Thomas's 2026-09-13 rule). Two TOPUP-2 D-SLASH-1 attempts
abandoned mid-session due to 14-reference cascade in
`Topup2Correspondence.lean`.
