# Site corrections for lfg_marketing #426 (chantier 8, mandate 2026-09-12)

This file lists the cards to correct before publishing lfg_marketing
#426. **Do not modify the site.** This audit-side record is the
authoritative pre-publication punch list; the site edits are handled
in the marketing repo.

Each card below identifies the misleading claim, the honest reading
under the post-chantier registered parents / disclosures, and the
exact registered artifact (theorem name or `fidelity.missing` entry)
the site copy must reflect.

## RESERVE-1 — single writer of the four in the partition

**Misleading claim on site:** framed as if the P-RESERVE-1 registered
parent covers ALL four writers in the ETH-reserve balance partition
(module deposits, top-up pull, consolidation vault credit, refund).

**Honest reading:** the registered parent
`LidoSRv3.Audit.Guarantees.PReserve1.source_spend_preserves_withdrawal_reserve`
covers ONE writer — the top-up spend path (`Lido.withdrawDepositableEther`
at `Lido.sol:869-886`).  The three other writers in the ETH-reserve
partition are NOT composed into the parent and each remains an open
sub-obligation:

1. **`setDepositsReserveTarget`** — the reserve-target update surface
   (Lido admin call).  Currently absent from the model.
2. **Report-time rebalance** via `_updateBufferedEtherAllocation`
   (invoked from Lido's oracle report handler).  Not modeled.
3. **Withdrawal-queue finalization** (`WithdrawalQueue.finalize`
   updating `unfinalizedStETH`) — the source of the `freshQueueCache`
   hypothesis; the WQ writer itself is outside the P-RESERVE-1
   parent's scope.

Chantier 2 mandate: "modélise les trois autres écrivains de la
partition (setDepositsReserveTarget, rééquilibrage au rapport
`_updateBufferedEtherAllocation`, finalisation WQ) ou, si hors portée,
rétrécis honnêtement la carte et note-le dans SITE-CORRECTIONS.md".
This card is the honest-narrowing option: the parent covers exactly
the top-up spend writer; the other three remain open follow-ups.

Additional signal chantier 1 (mandate 2026-09-12) reinstated as
`fidelity.missing`:

> live `WithdrawalQueue.unfinalizedStETH()` STATICCALL —
> `LidoSRv3/Audit/Source/ReserveUnfinalizedCall.lean` is a consumer
> that derives `freshQueueCache` from a live STATICCALL, but the
> registered parent still takes `freshQueueCache` as a hypothesis.
> RECLASSED not discharged (PR #408 was a rename, not a change to
> the parent's ENUNCE).

Additional signal chantier 2 Piste A (2026-09-13, PR #559 + PR #589):

> **Both free Booleans on `WithdrawInputs` eliminated at the parent's
> ENUNCE level.**  `WithdrawInputs` no longer carries `canDeposit :
> Bool` nor `authorizedRouter : Bool` as free caller fields.  It
> carries `lidoState : LidoStakingState { isStakingPaused,
> isBunkerActive }` (shared with TOPUP-1) and `acl :
> AragonACLSource.ACLState { stakingRouterRole, topUpGatewayApp :
> Bool }` (a two-boolean source-model of the Aragon ACL registry
> restricted to the two role queries the audit uses).
> `WithdrawInputs.canDeposit` is a `@[reducible, simp] def` computing
> `canDepositFromStorage inputs.lidoState` per `Lido.sol:815-816`;
> `WithdrawInputs.authorizedRouter` is a `@[reducible, simp] def`
> computing `isAuthorizedRouter inputs.acl` = `inputs.acl.stakingRouterRole`
> per `Lido.sol:872`.  Callers can no longer instantiate either
> boolean independently of a named pinned storage/ACL state.
> Residual: the four `LidoStakingState` + `ACLState` component
> booleans still stand in for live pause / bunker / ACL-role storage
> reads.

**Site fix:** narrow the RESERVE-1 card to name exactly the one
writer covered, list the other three as open (setDepositsReserveTarget,
report-time rebalance, WQ finalization — see the four-writer
enumeration above), and reference `audit/guarantees.yaml`
P-RESERVE-1 `fidelity.missing` for the disclosed gaps.  Also
reflect that BOTH `canDeposit` and `authorizedRouter` on
`WithdrawInputs` are now derived from pinned source states.

## TOPUP-1 — Verity plane ENUNCE promises match the code (chantier 2)

**Misleading claim on site (pre-chantier 2):** the Verity parent
`verity_tx_simulates_source_with_nonzero_wrap_close` was described as
delivering the wrap-close and pulled=pushed correspondence its NAME
promised, but its previous ENUNCE returned only `hCall` plus a
five-tuple of `executeGuarded` frame lemmas.

**Honest reading (post-chantier 2, mandate 2026-09-12):** the
registered Verity parent now returns a **four-conjunct** proposition
that actually delivers what the name promises:

1. `SourceTopupCallCorresponds cfg inp call`.
2. `VerityGuardedReturndataSimulation cfg call state` (five
   `executeGuarded` frame lemmas).
3. `NonzeroWrapRevertsAndRestores state` — universal nonzero-wrap
   close on the LEGACY `Verity.TopupTx.execute` plane.
4. Curried
   `hLen → hAmt → hCommit → VerityCommittingSimulation cfg inp state`
   — pulled=pushed / observation-equality / rollback correspondence
   on the LEGACY plane.

**Also disclosed (chantier 2 `fidelity.missing`):**

- `lidoPull` **now** journals both arguments `[(total : Uint256),
  (0 : Uint256)]` of the pinned `LIDO.withdrawDepositableEther(amount,
  0)` at `StakingRouter.sol:744`.  The journal-shape half of Grok
  differential #414 D-CALL-1 was discharged in Piste-A chantier 1
  (PR #554, 2026-09-13); `pullEntry` + `pullEntry_calldata` + the
  source-observable `sourceObservables` all carry the two-word
  calldata.  What remains open is the prefix-then-suffix half of
  D-CALL-1: `Verity.TopupTx.executeGuarded` still starts at
  `allocateDeposits` (line 717); the full-journal comparison over
  the 686-756 span (`allocateDeposits`-then-`withdrawDepositableEther`
  -then-per-key-`deposit`) is not yet exercised on the executable
  plane.
- Conjuncts 3–4 are proved on the legacy `execute` plane, not on
  `executeGuarded`; the guarded-plane analogue is open.
- **All four `SourceTopupInput` free Bools eliminated at the parent's
  ENUNCE level** (Piste-A chantier 1, PR #562 + PR #583, 2026-09-13):
  `SourceTopupInput` no longer carries `lidoCanDeposit`,
  `callerIsTopUpGateway`, `moduleExists`, or `wcTypeIsType2` as free
  caller fields.  It carries `lidoState : LidoStakingState
  { isStakingPaused, isBunkerActive }` (PR #562) and `srCtx :
  SRTopupCallerContext { callerIsGatewayFromRead,
  moduleExistsFromRead, wcTypeIsType2FromRead }` (PR #583).  Each of
  the four booleans becomes a `@[reducible, simp] def` accessor over
  one of the two embedded source states: `lidoCanDeposit` reduces
  to `canDepositFromStorage inp.lidoState` per `Lido.sol:815-816`;
  the three SR-context booleans reduce to the corresponding source
  functions in `SRStorageSourceModel` per StakingRouter.sol:686
  (`_checkAppAuth(_getTopUpGateway())`), SRUtils.sol:46
  (`SRStorage.isModuleExists`), and SRUtils.sol:42
  (`WithdrawalCredentials.isType2`).  30 construction sites migrated
  in Piste-A test/verity files.  Callers of `SourceTopupInput` can
  no longer instantiate any of the four booleans independently of
  named pinned source states.
- **D-ADDR-1 fully discharged (both halves)** (Piste-A chantier 1,
  PR #604, 2026-09-13): `Verity.TopupTx.lidoAddress` is no longer
  the `0xF00D` placeholder — it is anchored to the deployed
  `StakingRouter` runtime `LIDO` immutable inlined at seven
  `push20_payload_enumeration` byte offsets (6332, 9021, 9656, 9739,
  10386, 12237, 15321, each width 20) via new provenance module
  `LidoSRv3/Audit/Provenance/LidoAddress.lean`.  Value:
  `0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84`, the canonical Lido
  proxy mainnet address.  The beacon-address half of D-ADDR-1 was
  already covered by `BeaconDepositAddress.lean` (PR #391); both
  halves now discharged down to `A-RUNTIME-PROVENANCE`.
- **Executable Contract.run rollback theorems registered in the
  P-TOPUP-1 namespace** (Piste-A chantier 1, PR #576, 2026-09-13):
  `verity_tx_guarded_revert_restores_snapshot` (for
  `Verity.TopupTx.executeGuarded cfg call failure`) and
  `verity_tx_legacy_revert_restores_snapshot` (for
  `Verity.TopupTx.execute allocations failure`), each proving
  `state = rollback` on any revert.  Underlying proofs unfold
  `Contract.run` and case-split on the wrapper's success/revert
  branches.  Registered as executable-plane companions of the
  A-ABSTRACT-TX-backed `RevertRestoresSnapshot` conjunct in
  `source_topup_conserves_and_rolls_back`.  Retiring A-ABSTRACT-TX
  from the parent's ENUNCE (rewriting the 5-conjunct signature) is
  still open.

**Site fix:** update the TOPUP-1 card to describe the four-conjunct
Verity parent honestly, disclose the D-CALL-1 residual
(prefix-then-suffix half of the executable-plane extension), reflect
that **all four** SourceTopupInput booleans (`lidoCanDeposit`,
`callerIsTopUpGateway`, `moduleExists`, `wcTypeIsType2`) are now
derived from pinned source states (`LidoStakingState` +
`SRTopupCallerContext`), mention the two new executable Contract.run
rollback theorems `verity_tx_guarded_revert_restores_snapshot` /
`verity_tx_legacy_revert_restores_snapshot` (noting the abstract
A-ABSTRACT-TX conjunct is still in the registered parent), and
reflect that **both halves of D-ADDR-1** (beacon and Lido addresses)
are anchored to the deployed StakingRouter runtime bytecode via
`BeaconDepositAddress.lean` and `LidoAddress.lean`.

## TOPUP-2 — narrowing signal is 'exact under gateway-shape premise, wrapped otherwise' (chantier 4bis)

**Misleading claim on site (pre-chantier 4):** the P-TOPUP-2
registered abstract parent was framed as an unconditional block-cap
bound `(transition b cfg).sum ≤ cfg.maxTopUpPerBlockGwei`.

**Honest reading (post-chantier 4bis, Thomas 2026-09-12):** two
successive corrections apply.

- Chantier 4 (mandate 2026-09-12) changed the registered abstract
  parent from `aggregate_bounded_by_block_cap` (a fact about
  `consumeBudget`, a leftover-budget walk `StakingRouter.topUp` does
  not execute; also carried a sourceless `valueWei/GWEI` term
  because `topUp` is not payable) to `router_source_cap_within_block_cap`,
  which bounds the WRAPPED accumulator (`allocSumUnchecked`, mod
  2^256) under the router's aggregate guard at `StakingRouter.sol:737`.
- Chantier 4bis (Thomas 2026-09-12) further strengthened the parent
  to `router_exact_sum_bounded_under_gateway_shape`, which proves the
  EXACT-sum bound under the `GatewayShapedInput` premise (the two
  bounds the pinned `TopUpGateway.sol:226` construction enforces:
  `allocations.length ≤ uint64Max`; each `a ≤ uint64Max * GWEI`).

**Narrowing signal: 'exact under gateway-shape premise, wrapped
otherwise'.** Under any non-gateway caller the wrapped-sum bound is
the honest statement; under the pinned gateway construction, wrap is
unreachable and the exact sum is bounded.

**Residual (`fidelity.missing`):** the `GatewayShapedInput` premise
assumes the caller matches the pinned `TopUpGateway`. Under
`StakingRouter.topUp:686` (`_checkAppAuth(_getTopUpGateway())`), the
top-up gateway is the only admitted caller today — but composing the
router's caller-admission chain into the parent's statement is the
remaining follow-up.

**Site fix:** update the TOPUP-2 card to reflect the exact-sum bound
under gateway-shape premise; do NOT describe it as unconditional; do
NOT reference `consumeBudget` or `transitionBudget`; do NOT reference
`valueWei / GWEI` (topUp is not payable).

## SSZ-1 — Verity parent is the compiled `_verifyValidator` (chantier 3)

**Misleading claim on site (pre-chantier 3):** the P-SSZ-1 registered
Verity parent was `verity_tx_simulates_ssz_encoding`, which operates
on a **dummy validator at gindex 2 with an injective `Nat.pair`
combine** — an object `CLValidatorVerifier._verifyValidator` never
checks.

**Honest reading (post-chantier 3, mandate 2026-09-12):** the
registered Verity parent is now
`LidoSRv3.Audit.Guarantees.PSsz1.actual_compiled_cl_entry_complete_declared_branch`
at `LidoSRv3/Audit/Guarantees/PSsz1DeclaredSiblings.lean:10-83`, which
runs the **compiled harness of `_verifyValidator` (selector
`0x2e77b4ba`)** and yields, on a successful whole-entry run plus the
inherited `SszProofCommitted.ShaWidth` side condition:

- calldata-decoded slot / proposer at words 36 / 68;
- one BEACON_ROOTS STATICCALL with reply-guard on `external` and
  `world.core.codeSize`;
- typed `sourceWrapper` generalized index (word 132);
- `_validatorHashTreeRoot` layout at pinned offsets (48-byte key
  octets; `FieldsMatch` decoding; credential from word 164);
- independent Merkle branch fold `Fold.Branch (SszProofCalldataStep
  .ffiPair)` from `validatorLeaf` to the returned `firstWord`;
- complete ABI-declared sibling sequence (`declaredWords =
  proofWords`; length = declared branch length = `log2 gindex`; `3 ≤
  length ≤ 247`; penultimate = paired slot/proposer chunk digest);
- typed-digest branch equivalence via `treeDigest`, `validatorTree`,
  `SszTypedFfiBridge.branch_transport`.

The demoted `verity_tx_simulates_ssz_encoding` is preserved as the
subordinate row `P-SSZ-1.encoding-simulation` — regression evidence
only; **must not be re-promoted**.

**Also disclosed (chantier 3 `fidelity.missing`):**

- Demoted parent's dummy-validator-at-gindex-2 status.
- `ShaWidth` is an inherited output-width side condition on opaque
  `Compiler.Sha256.Engine.sha256`; SHA-256 functional correctness
  stays `A-SHA256-FFI`.
- EIP-4788 history-ring authenticity is not represented; BEACON_ROOTS
  callee is `StaticCall.External` on typed `Live.World`.
- Also named in `fidelity.missing`: `SSZ.verifyProof` on production
  gindices, `_validatorHashTreeRoot` layout, EIP-4788, SHA-256 all
  remain distinct open items — the compiled-entry parent covers the
  layout on the pinned calldata offsets, not the general
  `verifyProof` surface.

**Site fix:** update the SSZ-1 card to name the compiled `_verifyValidator`
parent, describe the six-fact conjunct explicitly, list the four
distinct named-open items (verifyProof on production gindices,
`_validatorHashTreeRoot` layout distinct from calldata offsets,
EIP-4788, SHA-256), and DO NOT describe the dummy-validator model as
the registered parent.

## ALLOC-1 — Chantier 3 progress (Piste A, 2026-09-13)

**No misleading site claim was flagged for ALLOC-1.**  This section
records the honest posture of P-ALLOC-1 after three Piste-A chantier-3
PRs.

- **`checked_execute_under_pinned_shape`** (PR #557):  new bridge
  parent in `LidoSRv3.Audit.Guarantees.PAlloc1` composes
  `PinnedStakingModuleTypeBounds` (real Nat.mul_le_mul + decide
  derivation of the `target_multiplication` conjunct from pinned
  uint16 `shareLimit` + uint64 `totalValidators`) with
  `PinnedSRAllocationBoundsShape` (naming scaffold for
  `active_subtraction`/`total_addition`/`available_arithmetic`), and
  applies `checked_execute` to the composed `CheckedBounds`.  Real
  derivation for one out of five conjuncts; the other three remain
  pass-through invariants (residual open until live-SRStorage source
  models land).
- **`verity_tx_live_revert_restores_snapshot`** (PR #571):  new
  registered theorem in `PAlloc1` re-exports
  `Verity.AllocationTx.live_revert_restores_snapshot` — every revert
  of `allocateLiveFromStorage` (the actual live-summary entry wired
  into the P-ALLOC-1 Verity parent) restores the pre-call snapshot.
  Includes the injected late-failure path
  `live_injected_after_writes_rolls_back` (revert reason
  `INJECTED_AFTER_WRITES` fired after every summary/stake staticcall +
  all observation writes).  The prior `fidelity.missing` entry that
  flagged rollback coverage for `allocate` only is retired.
- **Hoisting + flat-slot disclosures** (PR #574): two new
  `fidelity.missing` entries in P-ALLOC-1: (a) `bindLiveAll` hoists
  all `_getStakingModuleSummary` / `getTotalModuleStake` staticcalls
  out of the pinned `SRLib.sol:508-533` interleaved allocation loop,
  so no equivalence is claimed for full outcomes or call traces; (b)
  the Verity model uses flat `Nat` slot indices
  (`modulesCountSlot = 29`, `moduleIdSlot = 30`, `moduleConfigSlot = 31`)
  whereas pinned `SRStorage.sol` uses ERC-7201-style keccak-derived
  namespaced slots.

**Site fix:** if the ALLOC-1 card presents `CheckedBounds` as fully
derived, narrow it to "target_multiplication derived from pinned
type bounds; other three CheckedBounds conjuncts remain pinned-shape
premises".  If the ALLOC-1 card presents storage identity between the
Verity model and the deployed layout, narrow it to "model plane
pattern/order, no byte-level identity claimed".  If the ALLOC-1 card
presents `Contract.run` rollback as unconditional across all entry
points, note that both `allocate` (legacy planted maps) and
`allocateLiveFromStorage` (live-summary entry) are covered by
namespace-registered theorems.

## DEPOSIT-1 — Chantier 1 progress (Piste B, 2026-09-13)

**No misleading site claim was flagged for DEPOSIT-1.**  This section
records the honest posture of P-DEPOSIT-1 after six Piste-B chantier-1
PRs that discharge Grok #412 differential divergences in the registered
`DepositNFrameTx.execute` executor.

- **D-EMPTY-PULL** (PR #553): `DepositNFrameTx.execute` now gates the
  pull + per-batch push + line-996 assert behind an inlined
  `shouldPull inputs := decide (exactKeys inputs.batches ≠ 0)`
  predicate mirroring pinned `StakingRouter.sol:978`
  `if (actualDepositsCount == 0) return;`. On empty batches the model
  no longer journals a `withdrawDepositableEther` frame.
- **D-REVERT-1** (PR #561): `execute` and `executePullPushAssertTail`
  emit the pinned Solidity selector-name / Panic-selector strings
  (`NotAuthorized()`, `StakingModuleNotActive()`, `ZeroDeposits()`,
  `Panic(0x11)`, `Panic(0x01)`) instead of the earlier model-name
  strings.
- **D-SKEW-1** (PR #564): `Inputs` split into `depositSize` (per-key
  constant, `BeaconChainDepositor.DEPOSIT_SIZE`) and `maxEBType1`
  (constructor-time immutable,
  `StakingRouter.MAX_EFFECTIVE_BALANCE_WC_TYPE_01`); `execute`'s pull
  uses `wordKeys * maxEBType1` per StakingRouter.sol:972 while the
  push aggregate stays at `wordTotal = wordKeys * depositSize`; new
  `Preconditions.conserving : maxEBType1 = depositSize` premise makes
  the line-996 balance assert genuinely load-bearing on skewed
  deployments (previously vacuous).
- **D-NFRAME-1** (PR #566): in-body
  `require (decide ((batches.map fun batch => batch.moduleId).Nodup))
  "DuplicateModuleId"` guard added to `execute` after the
  word-overflow guard; duplicate `moduleId` inputs now revert at the
  executor rather than silently breaking the parent premise; kill-line
  `duplicate_module_input_reverts_at_in_body_guard` in
  `DepositNFrameTxMutants` exercises the guard.
- **D-CALL-1 two-argument-pull half** (PR #568): `pullFromLido`
  widened to two arguments `[wordTotal, wordKeys]` matching pinned
  `LIDO.withdrawDepositableEther(depositsValue, actualDepositsCount)`
  at StakingRouter.sol:983.
- **Task 8** (PR #572): `PDeposit1.verity_tx_revert_restores_snapshot`
  moved from the retired `DepositParentTx.execute` (2-batch legacy
  plane) to the registered `DepositNFrameTx.execute`, backed by new
  `DepositNFrameTx.revert_restores_snapshot` and
  `.revert_observes_idle` lemmas.

**Additional Piste B progress (2026-09-13, five Preconditions
relaxations widening the registered parent's admissible input set):**

- **`Preconditions.entryBalance = 0` retired** (PR #587): relaxed to
  `entryBalanceNoWrap : state.selfBalance.val + exactTotal inputs.batches
  < Uint256.modulus`. Deployments with a nonzero router `selfBalance` (e.g.
  partial `receiveDepositableEther` refund state) now compose under the
  registered parent. The old premise strictly implied the new one via
  `foldStable_bound`, so no previously-admitted input is excluded.
- **`Preconditions.funded` retired** (PR #590): unconditional Lido funding
  bound `wordTotal ≤ state.readSlot lidoDepositableSlot` relaxed to
  conditional `shouldPull inputs = true → wordTotal ≤ ...`. On empty-batch
  inputs the executor never reads `lidoDepositableSlot`, so no funding
  constraint is needed. Underfunded-Lido empty-batch inputs now compose.
- **`Preconditions.lidoCallOk` retired** (PR #591): unconditional
  `inputs.lidoCallOk = true` relaxed to conditional `shouldPull inputs = true →
  inputs.lidoCallOk = true`. On empty-batch inputs `pullFromLido` is never
  invoked, so the receiver-selection premise is not needed. Failing-Lido
  empty-batch inputs now compose.
- **`Preconditions.conserving` retired** (PR #595): unconditional
  `inputs.maxEBType1 = inputs.depositSize` conserving-deployment premise
  relaxed to conditional `shouldPull inputs = true → maxEBType1 = depositSize`.
  On empty-batch inputs `executePullPushAssertTail` is not invoked, so
  `maxEBType1` never enters the pull quantity. Skewed-deployment
  (`maxEBType1 ≠ depositSize`) empty-batch inputs now compose.
- **`Preconditions.entryBalanceNoWrap` further relaxed** (PR #597): the
  non-wrap premise from #587 further relaxed to conditional
  `shouldPull inputs = true → state.selfBalance.val + exactTotal <
  Uint256.modulus`. On empty-batch inputs the executor never touches
  `selfBalance` through the pull+push+assert tail. Arbitrary router
  `selfBalance` (up to `Uint256.modulus - 1`) now admits an empty-batch
  call.

**Site fix:** if the DEPOSIT-1 card presents the executable model as
mirroring the pinned executor call chain byte-for-byte, add the two
remaining residual disclosures: (a) D-CALL-1 per-key-push half
(`pushBatch` still emits one aggregate `depositToBeacon` frame per
batch rather than `batch.keys.val` per-key `IDepositContract.deposit`
frames); (b) D-SLOT-1 (model uses model-local slots 0-4 rather than
the pinned ERC-7201 `ModuleState.deposits` keyed layout indexed by
`moduleId`, and no `StakingRouterETHDeposited` event is emitted).
Remaining free-boolean `Preconditions` retirements (authorized /
moduleActive / allocationValid) require full DSM + router composition
(these three are checked BEFORE the pinned `shouldPull` early return,
so conditional-on-shouldPull relaxation is unsound); see
`audit/TRACK-B-REQUESTS.md` for the full obligations map, and the
Grok #412 harness integration into `make test`.

## Global signals

- **Fidelity total:** 102 open (was 78 pre-mandate; each chantier
  disclosure added honestly-named gaps; no assumption was silently
  retired).
- **Trust axiom envelope:** unchanged at 36 (30 test/mutant-only
  native-decision axioms + 3 production exceptions + foundations).
- **Registered CHECKED semantics on the site:** must be described as
  "the named Lean theorem is buildable on the pinned model plane"
  and not as "audited, verified on chain, or closed". README carries
  this qualification; the site cards must not soften it.

## Reference

- Mandate: `~/work/goals/lido-mandate-20260912.md`.
- Chantier 1 correction receipt:
  `audit/findings/CORRECTION-2026-09-12-reclassings.md`.
- All chantier PRs (this repo, `main` branch history):
  #427 (chantier 1), #428 (chantier 2), #429 (chantier 3),
  #430 (chantier 4, narrowing), #431 (chantier 5), #432 (chantier 6),
  #433 (chantier 7), #434 (chantier 4bis, exact-sum composition).
- Post-mandate general-rule follow-up (Thomas 2026-09-12): apply the
  same real-form-premise composition pattern to the six identified
  candidates (RESERVE-1 `canDeposit`/`authorizedRouter`; DEPOSIT-1
  LinksSource `firstAmount`/`publicKeysBatchLength`; TOPUP-1
  boolean guards; ADDRESS-1 `externalCallSucceeds`; ALLOC-1
  `CheckedBounds`; CONSOLIDATION-ETH-1 fee STATICCALL / batchSize).
  Goal never ends as long as any such free boolean or free input
  remains in a registered parent.
