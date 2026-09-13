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

`Preconditions.authorized` / `.moduleActive` / `.allocationValid` /
`.lidoCallOk` / `.entryBalance = 0` are currently free premises on
`inputs.<field> = true`. Retiring them requires composing with:

- DSM caller admission (source model exists at `LidoSRv3/Audit/Source/
  DepositDsmCall.lean` but is complex; needs a leaner premise API).
- Router-side pinned admission chain (`_checkAppAuth` at line 943 and the
  ModuleState config gate at :946).
- Lido callsite success under pinned Lido shape (no source model exists;
  needs a new `LidoWithdrawableCallSuccess` premise anchored to the
  deployed Lido address at 17005714).
- Router entry-balance invariant (`state.selfBalance = 0` reflects the
  pinned line-996 assert's precondition; needs a router invariant premise).

Each is a genuine parent-statement change (from free `Bool` to composed
pinned-source premise); none is a rename per Thomas's 2026-09-13
`~/work/goals/lido-common.md` rule 2.

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

- **D-CONSUME-1**: `Verity.sourceRun` still walks `sourceConsume`
  (leftover-budget); pinned `TopUpGateway.sol:226-232` writes
  `topUpLimits[i] = _evaluateTopUpLimit(...) * 1 gwei` independently per
  index. Requires rewriting `sourceRun` to produce independent limits,
  cascading into `verity_tx_simulates_topup2_spec`'s executable-plane
  correspondence.

- **D-UNITS-1**: `sourceRun` stays in gwei; pinned line 226 multiplies by
  `1 gwei` before the router call. Requires an explicit
  gwei→wei step in `sourceRun` consumed by the registered
  `verity_tx_simulates_topup2_spec`. A first attempt (adding an
  isolated `evaluated_topup_limit_wei` helper to `PTopup2.lean`) was
  correctly BLOCKED by fresh-context review as an isolated source-model
  addition (no registered parent consumes it). The real fix must
  restructure the Verity `sourceRun` executable plane.

- **D-SLASH-1**: `Verity.evaluateTopUpLimit` doesn't take `slash`/`exit`
  as inputs; pinned `_evaluateTopUpLimit` (TopUpGateway.sol:403-405)
  returns 0 for slashed or non-`FAR_FUTURE` exitEpoch. Requires input-shape
  change on the Verity plane.

- **D-TOTAL-1**: `Verity.used` is the leftover-consumed total; pinned
  `totalLimits +=` sits in `unchecked` and gates `_setLastTopUpData`
  (TopUpGateway.sol:234-236). Requires modeling the unchecked accumulator
  and its gate.

- **D-AUTH/SORT/WC/PUBKEY/MAX prefix**: `Verity.sourceRun` sees numeric
  arrays only; pinned `:160-223` prefix guards `onlyRole(TOP_UP_ROLE)`,
  strictly-increasing indices, type-0x02 WC, 48-byte pubkeys, and
  `maxValidatorsPerTopUp` are not exercised at the Verity plane. Requires
  adding executable guards to the Verity `execute`.

The registered abstract parent `router_exact_sum_bounded_under_gateway_shape`
already takes `GatewayShapedInput` (an explicit gateway-shape premise), so
its scope is bounded; the Verity parent `verity_tx_simulates_topup2_spec`
is where each of the above D-* items needs to land.

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

Chantier 1 DEPOSIT-1 PRs merged during this session:

| PR | Item | Merge SHA |
|----|------|-----------|
| #553 | D-EMPTY-PULL | 805ab538 |
| #561 | D-REVERT-1 | 32ceb74a |
| #564 | D-SKEW-1 | e40ea125 |
| #566 | D-NFRAME-1 | d15144a1 |
| #568 | D-CALL-1 two-arg-pull half | bfc6ad53 |
| #572 | Task 8 revert_restores_snapshot on N-frame executor | (merge of PR #572) |

One TOPUP-2 D-UNITS-1 attempt was BLOCKED and abandoned before merge (fresh-context review correctly flagged it as an isolated source-model addition).
