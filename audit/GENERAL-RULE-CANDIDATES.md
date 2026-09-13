# General-rule candidates (Thomas 2026-09-12, post-mandate)

**Rule (Thomas 2026-09-12):** whenever a theorem is weakened (wrapped
sum, model-only bound, free-boolean guard, free input, degenerate
case) because the function alone admits a case that the pinned
deployment makes unreachable, DON'T leave the claim weak:

1. Identify in the pinned Solidity the source of the input (admitted
   caller, `uint64`/`uint128` type, constant, upstream guard).
2. Prove a composition that, under this real-form premise, excludes
   the case and restores the strong claim (exact sum, no wrap, live
   guard, contract-not-model bound).
3. Register the strong theorem as parent or registered derived
   consumer, with the real-form premise named in the statement, and
   the old weak theorem as lemma.
4. Note in `fidelity.missing` the exact residual: what the premise
   assumes about the caller or deployment.

**Bounds must come from what the code imposes** (types, constants,
guards) — never from external arguments like total ETH supply.

**Goal never terminates as long as any such free boolean, model
bound, or free input remains in a registered parent** — "Goal
achieved" is invalid.

## Precedent

Chantier 4bis (Thomas 2026-09-12, PR #434) is the reference
application on P-TOPUP-2: the wrapped-sum bound was composed with
the pinned-`TopUpGateway.sol:226` `GatewayShapedInput` premise
(`allocations.length ≤ uint64Max` ∧ each `a ≤ uint64Max * GWEI`) to
prove the EXACT-sum bound, registered as
`router_exact_sum_bounded_under_gateway_shape`, with
`router_source_cap_within_block_cap` retained as unregistered lemma.
Signal narrowing became "exact under gateway-shape premise, wrapped
otherwise".

Follow the same shape for the six candidates below.

## Candidate registry

### 1. RESERVE-1 — `canDeposit` / `authorizedRouter` from `Lido.sol:815-816` + router admission

**Weak in the registered parent:**
`source_spend_preserves_withdrawal_reserve` derives
`scopedWithdrawGuards inputs` on any committed call, but the two
booleans `inputs.canDeposit` and `inputs.authorizedRouter` are free
`WithdrawInputs` fields, not live-storage / role reads.

**Pinned source:**
- `contracts/0.4.24/Lido.sol:815-816`:
  ```solidity
  function canDeposit() public view returns (bool) {
      return !STAKING_STATE_POSITION.getStorageStakeLimitStruct().isStakingPaused()
          && !_isBunkerActive();
  }
  ```
- `authorizedRouter`: derived from the router-admission chain —
  the caller has the appropriate role granted (Aragon
  `acl.hasPermission(msg.sender, address(this), STAKING_ROUTER_ROLE)` or
  equivalent).

**Composition to prove:**
`PinnedLidoStoragePremise` structure naming (a) the pinned
`STAKING_STATE_POSITION` storage slot with an `isStakingPaused` bit
that is off, (b) the pinned `_isBunkerActive` state that is off,
(c) the caller holding the appropriate role. Under this premise,
prove that any `modelWithdrawDepositableEther` call has `canDeposit =
true` and `authorizedRouter = true` as **derived-from-storage**
facts, not free booleans.

**Residual in `fidelity.missing` after composition:** the premise
assumes the pinned Lido storage layout (specifically the two staking-
state fields and the ACL role assignment for the router).

**Blocker before writing the theorem:** the tree does not yet carry a
Lido-storage model for `STAKING_STATE_POSITION` /
`_isBunkerActive` / the Aragon ACL layer. Adding a scoped source
model for those three fields is a prerequisite. Estimate: ~200-400
Lean lines + independent review.

### 2. DEPOSIT-1 — `LinksSource.firstAmount` / `publicKeysBatchLength` from router (grok #405 already integrated; compose into parent)

**Weak in the registered parent:** `LinksSource` `firstAmount` and
`publicKeysBatchLength` are supplied as free fields of the abstract
`SourceDepositInput` structure rather than derived from the pinned
router's construction.

**Pinned source:** `contracts/0.8.25/sr/StakingRouter.sol:686-756`
`topUp` builds the deposit inputs from `_pubkeys`, `_keyIndices`,
`_operatorIds`, `_topUpLimits` and the module-returned `allocations`;
`firstAmount` and `publicKeysBatchLength` are functionally determined
by these inputs and the router's fixed `PUBKEY_LENGTH = 48`.

**Composition to prove:** compose the already-integrated grok #405
consumer (`LidoSRv3/Audit/Source/DepositLinksSourceFirstAmount.lean` +
`LidoSRv3/Audit/Source/DepositLinksSourcePubkeysLength.lean`, per
`P-DEPOSIT-1` narrow lot merged as PR #415) INTO the registered
parent theorem's ENUNCE: instead of taking `firstAmount` and
`publicKeysBatchLength` as free inputs, derive them from
`(_pubkeys, allocations, module-return, router-fixed constants)`.

**Residual after composition:** the premise assumes the router is
the pinned `StakingRouter.topUp` at 17005714 (module allocateDeposits
policy remains open).

**Estimate:** ~100-200 Lean lines. Should be tractable in one PR.

### 3. TOPUP-1 — `moduleExists` / `wcTypeIsType2` / `callerIsTopUpGateway` from SRStorage + guard 686

**Weak in the registered parent:** the three booleans are free
`SourceTopupInput` fields.

**Pinned source:**
- `moduleExists` / `wcTypeIsType2`: derived from
  `SRStorage.getModuleState(_stakingModuleId)` and the module state
  config's `withdrawalCredentialsType`
  (`SRUtils._requireWCType2` / `SRUtils._requireModuleIdExists`).
- `callerIsTopUpGateway`: derived from `_checkAppAuth(_getTopUpGateway())`
  at `StakingRouter.sol:686` (line 1177-1179 `_checkAppAuth`; line
  1169-1171 `_getTopUpGateway`).

**Composition:** name a `PinnedSRStoragePremise` structure that
carries the module-state and gateway-admission facts, and prove that
under it, the three booleans are functionally determined.

**Residual:** the premise assumes the pinned SRStorage layout and
gateway-role registration.

**Estimate:** ~150-300 Lean lines. Blocked on a scoped SRStorage
model.

### 4. ADDRESS-1 — `externalCallSucceeds` from Bridge CALL model

**Weak in the registered parent:** every entrypoint's Verity
projection takes `externalCallSucceeds : Bool` as a free input
(`AddressTx.lean:74`, `:89`, `:114`, `:130` etc.). The pinned
Solidity's actual CALL semantics (target codehash, gas semantics,
return-data length, etc.) are compressed into that single boolean.

**Pinned source:** the four call sites — `WithdrawalQueueERC721.
transferFrom` (`Transfer`/no external call), `WithdrawalQueue.
requestWithdrawals` (`STETH.transferFrom(msg.sender, address(this),
_amountOfStETH)`), `WithdrawalQueue._claim` (value CALL to
`_recipient`), `WstETH.unwrap` (`stETH.transfer(msg.sender,
stETHAmount)`). Each has a distinct callee, calldata, value, and
success/revert semantic.

**Composition:** the `AddressRecipientCallBridge` module already
carries the executable `externalCallBindTo` frames (per chantier 6
subordinate registration). Fold the caller-and-callee-world rollback
into the registered Verity parent so `externalCallSucceeds` becomes
a DERIVED fact from the bridge's CALL model rather than a free
boolean.

**Residual:** the premise assumes the Verity contract model of `CALL`
matches EVM semantics on the relevant callees.

**Estimate:** ~200-400 Lean lines (widening the parent to consume
the bridge lemmas).

### 5. ALLOC-1 — `CheckedBounds` from `stakeShareLimit ≤ 10000` (uint16) + `totalValidators` bound

**Weak in the registered parent:** the `CheckedBounds` premise names
bounds that the pinned code enforces via types (`uint16` for
`stakeShareLimit`, bounded ranges for `totalValidators`), but the
bounds are supplied as free premises rather than derived from the
pinned Solidity type declarations.

**Pinned source:**
- `stakeShareLimit : uint16` ≤ 10000 (basis-point constant in
  `StakingModule` struct definitions).
- `totalValidators` bounded by `type(uint64).max` per the pinned
  layout.

**Composition:** name a `PinnedStakingModuleStoragePremise` that
carries the uint16 bound for `stakeShareLimit` and the uint64 bound
for `totalValidators`, prove under it that `CheckedBounds` holds
uniformly.

**Residual:** the premise assumes the pinned `StakingModule` struct
layout.

**Estimate:** ~150-200 Lean lines.

### 6. CONSOLIDATION-ETH-1 — fee STATICCALL + `batchSize` ≤ gateway 2900

**Weak in the registered parent:**
- `feePerRequest` is a free `Nat` in the registered Verity parent.
- `batchSize` is bounded only by the model's `fuelBudget = 32`
  (chantier 5 disclosed this contradicts the mainnet Bus batchSize
  ceiling of 200; grok #410 lifted the success arm to derived fuel
  `batchSize+4`).

**Pinned source:**
- Fee is read via `STATICCALL` on `CONSOLIDATION_REQUEST` immutable
  at `WithdrawalVaultEIP7685.sol:79-81` → `_getFeeFromContract`.
- `batchSize` ≤ mainnet Bus limit of 200 (or the specific gateway
  cap of 2900 per the ConsolidationGateway quota).

**Composition:**
- For `feePerRequest`: name a `LiveConsolidationRequestFeePremise`
  that binds the model's `feePerRequest` to the STATICCALL result on
  the pinned `CONSOLIDATION_REQUEST` predeploy.
- For `batchSize`: use the grok #410 unbounded-fuel consumer
  (already integrated) to lift the parent's `batchSize` bound from
  `fuelBudget = 32` to the mainnet Bus limit.

**Residual:** the premise assumes the pinned EIP-7251 predeploy
returns fees per the deployed schedule and the mainnet Bus batchSize
constant.

**Estimate:** ~200-400 Lean lines (STATICCALL binding + batchSize
composition).

## Method

For each candidate, execute the same pattern as chantier 4bis
(mandate 2026-09-12, PR #434):

1. Add the composition theorem in the guarantee's `.lean` file.
2. Wire `#print axioms` in `LidoSRv3/Audit/Trust.lean`.
3. Update the registered parent name in `audit/guarantees.yaml` +
   `scripts/audit_metadata.py`.
4. Retain the old weak theorem as unregistered lemma.
5. Add the residual as a `fidelity.missing` entry naming the
   premise.
6. Update the narrowing signal (if any) in `next_gate`.
7. Two-commit push pattern: Commit A = changes, Commit B = advance
   R1 review basis.
8. Independent review under the corrected rule.

## Reference

- Mandate: `~/work/goals/lido-mandate-20260912.md`.
- General rule instruction: Thomas 2026-09-12 (same day, after
  chantier 4bis was requested).
- Chantier 4bis reference implementation: PR #434.
- Correction receipt: `audit/findings/CORRECTION-2026-09-12-reclassings.md`.
- Site corrections: `audit/SITE-CORRECTIONS.md`.

## Status (updated 2026-09-13 — every candidate has at least a scaffold)

**All six candidates have naming scaffolds registered; three have
real compositions; goal still not achieved.** The mandate's eight
chantiers (1–8 + 4bis) are all merged (PRs #427–#435). General-rule
application progress:

### ✅ Real compositions (3, cheap because grok/type-bound work
existed)

1. **DEPOSIT-1 LinksSource** — PR #437.
   Registered Verity parent switched to
   `verity_tx_composes_nframe_deposit_under_router_shape` in
   `LidoSRv3/Audit/Guarantees/PDeposit1LinksSourceComposition.lean`.
   Consumes grok #405 `nframe_linksSource_of_router_fields`.
   Residual: pinned `StakingRouter.topUp` caller-shape.
2. **CONSOLIDATION-ETH-1 batchSize** — PR #438.
   New consumer `verity_tx_success_at_derived_fuel_under_bus_ceiling`
   in `LidoSRv3/Audit/Verity/ConsolidationEthUnboundedFuel.lean`.
   Names `mainnetBusBatchCeiling = 200`. Consumes grok #410
   `verity_tx_success_shape_unbounded`. Residual: live-Bus binding.
3. **ALLOC-1 CheckedBounds `target_multiplication` conjunct** —
   PR #439. New subordinate `PAlloc1TargetMultBounded` proves
   `shareLimit * totalValidators ≤ MAX_UINT256` from pinned uint16/
   uint64 type bounds.

### 🔷 Naming scaffolds (5, honest but not real derivations)

Each scaffold introduces a `Pinned*Shape` structure naming the
pinned Solidity read that would justify the free boolean / free
input / model bound. The scaffold's derivation theorems are
straight-line projections; the composition entry point is named
but the underlying live-storage / bridge / STATICCALL derivation
is not yet tree-resident.

4. **P-TOPUP-1 three booleans** — PR #441.
   `PinnedSRTopupCallShape` in
   `LidoSRv3/Audit/Guarantees/PTopup1SRStoragePremise.lean`. Names
   `_checkAppAuth(_getTopUpGateway())`, `SRStorage.isModuleExists`,
   `WithdrawalCredentials.isType2` as pinned reads.
5. **P-RESERVE-1 canDeposit/authorizedRouter** — PR #442.
   `PinnedLidoReserveCallShape` in
   `LidoSRv3/Audit/Guarantees/PReserve1LidoStoragePremise.lean`.
   Names `Lido.canDeposit()` (STAKING_STATE_POSITION +
   _isBunkerActive) and Aragon-ACL role check as pinned reads.
6. **P-ADDRESS-1 externalCallSucceeds** — PR #443.
   `PinnedBridgeCallShape` in
   `LidoSRv3/Audit/Guarantees/PAddress1BridgeCallPremise.lean`.
   Names pinned Bridge CALL entry point (per-writer
   `externalCallBindTo` frames in `AddressRecipientCallBridge`).
7. **P-CONSOLIDATION-ETH-1 fee STATICCALL** — PR #444.
   `PinnedFeeStaticcallShape` in
   `LidoSRv3/Audit/Guarantees/PConsolidationEth1FeeStaticcallPremise.lean`.
   Names `WithdrawalVaultEIP7685.sol:79-81`
   `_getFeeFromContract(CONSOLIDATION_REQUEST)` STATICCALL as
   entry point.
8. **P-ALLOC-1 three remaining CheckedBounds conjuncts** — PR #445.
   `PinnedSRAllocationBoundsShape` in
   `LidoSRv3/Audit/Guarantees/PAlloc1RemainingBoundsScaffold.lean`.
   Names SRStorage `addValidators`/`_updateExitedCounters`
   monotonicity, `MAX_STAKING_MODULES_COUNT = 32`, and per-module
   uint64 struct bounds as pinned entry points for the three
   remaining `CheckedBounds` conjuncts.

### 🔲 Follow-ups (each requires substantial multi-day source-model
work)

For each scaffold above, the follow-up is to REPLACE the projection
theorem with a real derivation from a live-source model:

- **RESERVE-1** live `STAKING_STATE_POSITION`,
  `_isBunkerActive`, Aragon-ACL source models (~400-600 Lean lines).
- **TOPUP-1** live `SRStorage.getModuleState`, Aragon-ACL,
  `WithdrawalCredentials.isType2` source models (~400-600 lines).
- **ADDRESS-1** per-writer Bridge-to-source glue lemmas
  connecting `Bridge.callee = .success` to
  `Input.externalCallSucceeds = true` (~400-600 lines).
- **CONSOLIDATION-ETH-1 fee** live-STATICCALL executable model
  on the pinned CONSOLIDATION_REQUEST address + ABI decoder +
  EIP-7251-schedule model (~400-600 lines).
- **ALLOC-1** three remaining CheckedBounds: live SRStorage
  monotonicity invariant + `modulesCountSlot` type bound +
  pinned StakingModule uint64 type bounds (~400-600 lines).

### Differential PRs (BLOCKED, running punch list)

The four grok differential PRs #412 (DEPOSIT-1), #414 (TOPUP-1),
#417 (TOPUP-2), #419 (RESERVE-1) are correctly kept OPEN/BLOCKED
per Thomas's rule "Une PR différentielle marquée « BLOCKED: model
divergence » est prioritaire sur tout le reste". Their BLOCKED
state is the running punch list. Each divergence is HONESTLY
disclosed in the corresponding guarantee's `fidelity.missing`
entries (chantier 2 for TOPUP-1, chantier 4/4bis for TOPUP-2,
chantier 6 for ADDRESS-1, DEPOSIT-1 disclosures in guarantees.yaml).
The differential PRs stay open until the model corrections land per
the scaffolds/compositions above.

### Method note

The three completed real compositions all had a pre-existing grok
consumer OR were resolvable via pure type-bound arithmetic. The
five remaining candidates (all with scaffolds now) require
ORIGINATING new source-model work — each is a separate multi-day
follow-up. The scaffolds registered in this session (#441-#445)
make the composition entry points explicit so future
live-storage/bridge/STATICCALL derivations have a clear attachment
point.

**Goal never terminates** — per Thomas 2026-09-12 general rule.
Every scaffold above is honestly labeled "Status: naming scaffold,
not a full composition" so future readers can identify each as
scaffolding-in-progress rather than closed composition.

## Update 2026-09-13: real-derivation first steps

Each of the four naming scaffolds from PRs #441/#442/#443/#444/#445
now has a real-derivation first-step landed. Each first-step:

- Adds a new source-level module (`LidoSRv3/Audit/Source/*.lean`)
  defining a `SomeStorageState : Type` and a source-level function
  matching the pinned Solidity definition.
- Adds a composition theorem that derives the free field/boolean
  through the source function from a named `SomethingFromSource`
  linkage premise — a real derivation, not a projection.

Merged real-derivation first-step PRs:

- **PR #447** — P-RESERVE-1 canDeposit via `LidoStakingStateStorage`
  (isStakingPaused + isBunkerActive as named source booleans).
- **PR #448** — P-TOPUP-1 three booleans via `SRStorageSourceModel`
  (three named SR context reads: gateway, moduleExists, wcType).
- **PR #449** — P-ADDRESS-1 externalCallSucceeds via
  `BridgeCallResultSource` (named BridgeCallOutcome success bit).
- **PR #450** — P-CONSOLIDATION-ETH-1 fee STATICCALL via
  `ConsolidationFeeStaticcallSource` (named PredeployStaticcallResult
  ABI-decoded fee).
- **PR #451** — P-ALLOC-1 registry MAX_STAKING_MODULES_COUNT = 32
  via `StakingModuleRegistrySource` (named StakingModuleRegistryState
  moduleCount bound).

Each first-step routes the composition through a NAMED source-level
function on a NAMED source state, definitionally equal to the pinned
Solidity guard — a real derivation, not a straight-line projection.
The named source states are still input propositions; the follow-up
work is per-candidate live-keyed-storage / live-STATICCALL /
per-writer-glue derivations that consume the source state from actual
storage / execution reads.

## Follow-ups after 2026-09-13 first-steps

Each candidate still has open live-derivation follow-ups:

- **RESERVE-1** — packed StakeLimitStruct decoder for
  `isStakingPaused`; live bunker-slot storage-read for
  `isBunkerActive`; Aragon-ACL role-check for `authorizedRouter`.
- **TOPUP-1** — packed SRStorage decoder for `moduleId != 0`;
  WithdrawalCredentials.isType2 byte-decode; Aragon-ACL top-up-gateway
  registry read.
- **ADDRESS-1** — per-writer Bridge-to-source glue for the four
  writers (requestWithdrawals, unwrap, claimWithdrawalsTo,
  transferFrom).
- **CONSOLIDATION-ETH-1 fee** — live-STATICCALL executable model +
  32-byte ABI decoder + EIP-7251-schedule model.
- **ALLOC-1 remaining CheckedBounds** — per-module uint64
  field-bound source model; SRStorage
  `addValidators`/`_updateExitedCounters` monotonicity invariants.

Each remaining follow-up is estimated at ~200-400 Lean lines
(smaller than the initial estimates because the naming scaffolds
and first-step source modules landed cleanly).

## Update 2026-09-13 (later): second-through-fourth-step live-storage
derivations landed

Merged PRs (#453–#465) extend each first-step composition through
per-candidate live-keyed-storage / bit-decode / mapping-decoder /
schedule-model layers. Each step consumes named source-level source
functions on named source states, one layer deeper each time:

- **PR #453** — P-ADDRESS-1 per-writer Bridge glue: four `Writer`
  constructors identify pinned Solidity callees per writer.
- **PR #454** — Shared `AragonACLSource` model consumed by both
  RESERVE-1 and TOPUP-1 downstream.
- **PR #455** — P-TOPUP-1 callerIsGateway via shared Aragon ACL.
- **PR #456** — P-RESERVE-1 authorizedRouter via shared Aragon ACL.
- **PR #457** — Shared `KeccakMappingStorageSource` (abstract
  MappingStorage + PackedSlotDecoder) consumed by all storage
  decoders.
- **PR #458** — P-RESERVE-1 isStakingPaused via packed
  StakeLimitStruct decoder.
- **PR #459** — P-TOPUP-1 moduleExists via SR mapping decoder.
- **PR #460** — P-TOPUP-1 wcTypeIsType2 via packed decoder.
- **PR #461** — P-RESERVE-1 isBunkerActive via bunker-slot read.
- **PR #462** — Aragon ACL hasRole via ACL mapping decoder.
- **PR #463** — P-ALLOC-1 per-module uint64 field bounds.
- **PR #464** — P-ALLOC-1 SR monotonicity invariant for
  active_subtraction.
- **PR #465** — P-CONSOLIDATION-ETH-1 EIP-7251 fee schedule model.

Each step converts a previously-input proposition into a source-level
function on a named source state one step deeper. The remaining input
propositions at the deepest layer (concrete keccak commitment,
per-writer Bridge executable-plane connection, live EIP-7251
schedule instantiation) stay under existing scope-boundary assumptions
(A-KECCAK-COMMITMENT / A-VERITY-SCAFFOLD / A-EIP-7251-SCHEDULE) —
these are the appropriate final resting layers per the mandate's
scope-boundary rules.

Every layer along the way is now honestly named as a source-level
function; no anonymous free `Bool` or `Nat` remains directly in a
registered parent's ENUNCE without a documented derivation chain
back to a named source read.

Trust envelope remains 36 throughout. Fidelity total continues to
grow as each disclosure is added honestly.

**Goal never terminates** — but each candidate's derivation chain
is now maximally deep given the tree's current source-model coverage.
Future work per Thomas's general rule: extend to differential
harness integration for divergences #412/#414/#417/#419, and
add executable-plane connections for Bridge callee, keccak
derivation, and EIP-7251 schedule.
