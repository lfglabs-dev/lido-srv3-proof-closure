# Certora → Lido PR #1811 → Verity Mapping

Week-1 deliverable for the *Lido Evergreen Formal Methods Pilot (V3)*: a
truth-maintenance map from prior Certora assurance and the PR #1811 changed
surface to the Verity/Lean targets in this repository. It records what is
already covered, what is covered only under named assumptions, and what remains
a follow-on lane.

This is not marketing. Each row separates four things: what Certora already
covered, what Certora simplified or summarized, what PR #1811 changes, and what
the current Verity/Lean model actually checks. Where a real-world guarantee is
delegated to an external interface, the row names the assumption instead of
claiming a proof.

## 0. Status enum

| Status | Meaning |
| --- | --- |
| `covered-by-current-model` | The economic law is a machine-checked theorem in the pinned model; residual premises are generic (arithmetic domain, accepted-report validation). |
| `covered-under-assumptions` | The theorem is checked, but a load-bearing part of the real guarantee is delegated to a specific named external-interface assumption. |
| `mapped-not-proved-yet` | Surface is mapped to anchors and a target id, but no checked artifact exists yet. |
| `follow-on-lane` | Adjacent SRv3 risk surface named in the proposal for a later week/lane; not required to support the P0 accounting claims. |
| `not-in-pilot` | Out of the current 4-week scope. |

The word `closed` is intentionally not used. Statuses reflect the model at the
pinned Verity commit below. A concurrent branch task may be refining
proof-fidelity details; treat `covered-*` rows as "checked in the pinned model,
subject to in-flight fidelity review" rather than as a final on-chain
refinement claim.

**Scope tier.** Independently of the status enum above, each in-model target
group carries a scope tier recorded in
[`srv3-proof-targets.json`](./srv3-proof-targets.json) (`scope` block). The
signed P0 economic scope of the 4-week pilot is the six P0 candidate
economic-conservation properties SRV3-P1--P6 (matching the executive-summary
headline claim). SRV3-P8 (top-up) and SRV3-P9 (allocation-capacity) are internal
economic decomposition of the deposit/allocation surface --- executable
supporting targets, not additional signed acceptance commitments. SRV3-P7 and
SRV3-P10--P15 are executable operational / module-configuration lanes carried as
follow-on / internal work, not current acceptance commitments. This tiering does
not change any row's `Status`; it records which checked rows the pilot presents
as signed acceptance versus decomposition/follow-on. The P0-boundary review
question in §4 remains open for client confirmation.

## 1. Source inventory

### 1.1 Prior Certora assurance (referenced, not vendored)

These baselines are **referenced from prior Lido assurance context**, not
copied into this repository. They frame the delta; they are not evidence
produced here.

| Baseline | Characterization used for this map | In repo? |
| --- | --- | --- |
| Certora V2 (StakingRouter-era FV) | Covered many StakingRouter-style invariants but under bounded-loop assumptions; surfaced issues around duplicate modules and exited/deposited-count consistency. | No — external reference |
| Certora V3 (stVault/VaultHub FV & security assessment) | Focused on the stVault/VaultHub stack; assumed at most two staking modules with constant parameters; summarized `StakingRouter.deposit()` and `StakingRouter.reportRewardsMinted()` as nondeterministic. | No — external reference |

If Lido shares the V2/V3 report PDFs/specs, they should be pinned here by
title, date, and commit/hash so this inventory becomes reproducible. Until
then, the characterizations above are the working baseline agreed for the
delta, not a re-derivation of Certora's results.

### 1.2 Lido PR #1811 pinned source

| Field | Value |
| --- | --- |
| Repository | `lidofinance/core` |
| PR | #1811 |
| Pinned commit (source-map + lockfile) | `d088bbc2deac9913b68036d73d35c37aa6279b90` |

Source anchors per target are in
[`source-map.json`](./source-map.json); line-level correspondence is in
[`solidity-correspondence.md`](./solidity-correspondence.md).

### 1.3 Verity / local PR #1 artifacts

| Field | Value |
| --- | --- |
| Verity pinned commit | `33722270d996c7a3a520a71ecee42d7d232da100` |
| Model | [`../../LidoSRv3/Model.lean`](../../LidoSRv3/Model.lean) |
| Theorems | [`../../LidoSRv3/SpecProofs.lean`](../../LidoSRv3/SpecProofs.lean) |
| Target manifest | [`srv3-proof-targets.json`](./srv3-proof-targets.json) |
| Trust boundary | [`trust-boundary.json`](./trust-boundary.json) |
| Proof log | [`../../proofs/logs/proof-report.json`](../../proofs/logs/proof-report.json) |
| Proof command | `lake build LidoSRv3` (via `make prove`) |

## 2. Mapping table

Columns: prior Certora / assurance area → PR #1811 changed surface → Verity
target(s) → status → load-bearing assumption IDs (see
[`trust-boundary.json`](./trust-boundary.json)).

| # | Certora / prior area | PR #1811 changed surface | Verity target(s) | Status | Assumptions |
| --- | --- | --- | --- | --- | --- |
| 1 | V2 deposit-availability bounds | Deposit reserve / buffered-ether separation (`Lido.sol::_getBufferedEtherAllocation`, `getDepositableEther`, `_spendDepositableEther`) | SRV3-P1; SRV3-P2d/P2j (reserves unchanged/spent) | `covered-by-current-model` | A-ARITH-05, A-LIDO-06 |
| 2 | V2 deposit-availability bounds (bounded) | StakingRouter initial deposits, pull-deposit exactness (`StakingRouter.sol::deposit`, `Lido.sol::withdrawDepositableEther`) | SRV3-P2 + P2a–P2n | `covered-under-assumptions` | A-DEP-02, A-MOD-07, A-LIDO-06, A-ARITH-05 |
| 3 | V2 validator-count accounting | Module balance reports & router-wide balance sum (`SRLib.sol::_reportValidatorBalancesByStakingModule`, `SRTypes.sol::RouterStateAccounting`) | SRV3-P3 + P3a–P3g | `covered-by-current-model` | A-ORC-03, A-ID-04 |
| 4 | (new PR #1811 ordering) | Report-before-reward consistency (`AccountingOracle.sol::submitReportData` → `getStakingRewardsDistribution`) | SRV3-P4, P4a | `covered-by-current-model` | A-ORC-03 |
| 5 | V2/V3 reward-distribution checks | Reward / fee distribution over accepted balances (`StakingRouter.sol::getStakingRewardsDistribution`, `_computeModuleFee`) | SRV3-P5 + P5a–P5h | `covered-by-current-model` | A-REWARD-09, A-ID-04 |
| 6 | Router status-gating assertions | Active / stopped / deposits-paused status gating (`SRTypes.sol::StakingModuleStatus`, `deposit`, `getStakingRewardsDistribution`) | SRV3-P6, P6a | `covered-by-current-model` | A-GOV-14 |
| 7 | V3 bounded module-array specs (≤2 modules, const params) | Allocation capacity / dynamic module arrays (`SRLib.sol::_getDepositAllocations`, `_getModulesAllocationAndCapacity`) | SRV3-P9 + P9a–P9f | `covered-under-assumptions` | A-ALLOC-12, A-MOD-11, A-ID-04 |
| 8 | (new PR #1811 surface) | Top-up / 0x02 validator allocation + witness assumptions (`StakingRouter.sol::topUp`, `IStakingModuleV2.allocateDeposits`) | SRV3-P8 + P8a–P8l | `covered-under-assumptions` | A-DEP-02, A-MOD-10, A-MOD-11, A-LIDO-06, A-ARITH-05 |
| 9 | V2 exited/deposited-count consistency (issue area) | Exited-count correctness / MaxEB-aware exit accounting (`StakingRouter.sol::updateExitedValidatorsCountByStakingModule`, `IStakingModule.getStakingModuleSummary`) | SRV3-P7 + P7a–P7e | `covered-under-assumptions` | A-MOD-08, A-ID-04 |
| 10 | V3 `reportRewardsMinted()` summarized nondeterministic | reportRewardsMinted ordering / row alignment (`SRLib.sol::_reportRewardsMinted`) | SRV3-P10 + P10a–P10g | `covered-by-current-model` | A-ID-04 |
| 11 | (module-config plumbing, partly V2) | Module fee / share / status / config update consistency (`updateAllStakingModulesFees`, `updateStakingModule`, `setStakingModuleStatus`, `updateStakingModulesShares`) | SRV3-P11, P12, P13, P15 (+ sub-rows) | `covered-by-current-model` | A-GOV-14, A-ARITH-05 |
| 12 | (module-config plumbing) | Add-module initialization consistency (`StakingRouter.sol::addStakingModule`, `SRLib.sol::_addModule`) | SRV3-P14 + P14a–P14g | `covered-by-current-model` | A-GOV-14 |
| 13 | V3 MaxEB / consolidation scope | Consolidation fee conservation, source/target binding (`ConsolidationMigrator.sol` and related) | — | `follow-on-lane` | out of P0 model |
| 14 | V3 migration/deployment scope | SRv3 storage migration refinement (`SRLib.sol::_migrateStorage`) | — | `follow-on-lane` | out of P0 model |
| 15 | V3 stVault/VaultHub FV | VaultHub F-01/F-02/F-03 lane | — | `follow-on-lane` / `not-in-pilot` | out of P0 model |
| 16 | (new PR #1811 surface) | ExitBus authorization, replay/duplicate resistance, triggerable-exit fee/refund exactness (`ValidatorsExitBus*.sol`) | — | `follow-on-lane` | out of P0 model |

Notes on discipline:

- Row 8 (top-up): the SRv3-owned allocation loop, Gwei alignment, per-key
  limits, budget bound, and exact beacon-sink transfer are checked. Key
  ownership, the returned allocation array contents, and CL-side witness
  validity are **not** proved — they are assumptions A-MOD-10 / A-MOD-11 and are
  a named follow-on binding (Appendix D, item 3 in the report).
- Row 9 (exited counts): the model checks that update rows name existing
  modules, cannot decrease stored exited counts, and cannot exceed the
  deposited-validator count. The deposited-validator count itself comes from
  `getStakingModuleSummary` and is assumption A-MOD-08. Full MaxEB
  balance-partial-exit *economics* (beyond count monotonicity/bounds) is a
  follow-on lane, not this row.
- Row 7 (allocation capacity): row alignment, module-order preservation, and
  the WC01/WC02 capacity bounds are checked. The external
  `MinFirstAllocationStrategy` that runs *after* these rows is assumption
  A-ALLOC-12 and is not proved here.

## 3. Assumption map

Each target above leans on named premises registered in
[`trust-boundary.json`](./trust-boundary.json). The load-bearing IDs per row
are in the table's last column. Summary of the 14 assumption IDs:

| ID | One-line premise |
| --- | --- |
| A-ARITH-05 | Wei/Gwei/bps arithmetic over bounded non-negative integers; overflow → rejected state. |
| A-DEP-02 | Beacon sink consumes exactly 32 ETH per initial deposit / exact allocation per top-up; deposit-root, BLS, dummy-sig, SSZ out of lane. |
| A-EXT-01 | External callbacks/sinks mutate no unlisted SRv3 accounting state. |
| A-GOV-14 | Governance authorization, calldata authorship, registration, address/interface validation, events for module management are out of lane. |
| A-ID-04 | Module IDs unique; accepted report arrays align with router module order. |
| A-LIDO-06 | `LIDO.withdrawDepositableEther` makes exactly the requested depositable amount available; does not consume withdrawal-reserved ETH. |
| A-MOD-07 | `obtainDepositData` returns the modeled pubkey count; mutates no router accounting except via the explicit transition. |
| A-MOD-08 | `getStakingModuleSummary` returns the deposited-validator count used by exited-count validation; operator internals out of lane. |
| A-MOD-10 | `IStakingModuleV2.allocateDeposits` returns the modeled top-up allocation array; key ownership / module internals out of lane. |
| A-MOD-11 | `IStakingModuleV2.getTotalModuleStake` returns the modeled total module stake for WC02 allocation. |
| A-MOD-13 | `onRewardsMinted` callback effects, revert bytes, events, gas out of lane; only SRLib loop guards modeled. |
| A-ORC-03 | Accepted reports passed off-chain oracle validation; model still checks array length, router-order IDs, and Gwei range. |
| A-REWARD-09 | Reward-fee arithmetic stays within Solidity precision/cast domains, incl. `totalFee ≤ FEE_PRECISION_POINTS`. |
| A-ALLOC-12 | External `MinFirstAllocationStrategy` and governance target-limit admissibility satisfy their contracts; only SRv3-owned array construction modeled. |

### 3.1 Explicit non-claims

The following are **out-of-model** and are not asserted by any row above:

- Oracle truthfulness of the underlying beacon-chain state (A-ORC-03 accepts
  reports post-validation; it does not certify the off-chain data).
- BLS signatures, SSZ encoding, Merkle proofs, EIP-4788 beacon-root access
  (folded into A-DEP-02 / general plumbing).
- External module callbacks beyond listed SRv3 state effects (A-EXT-01,
  A-MOD-13).
- Governance / config / deployment authorization and role graph (A-GOV-14).
- Packed storage layout equivalence and exact cast encoding.
- Gas accounting, event semantics, revert strings, liveness, and full
  deployed-system refinement.

## 4. Review questions for Week-1 confirmation

1. **Target commit**: is `d088bbc2deac9913b68036d73d35c37aa6279b90` still the
   release commit/branch/tag to target, or should we re-pin to a newer PR #1811
   head or a tagged release candidate?
2. **P0 set**: should the P0 scope include top-up (row 8), exited-count (row 9),
   consolidation (row 13), and migration (row 14) swaps, or keep those as
   follow-on lanes?
3. **Assumption sign-off**: who signs off the 14 assumptions (Yuri / George /
   Gregory), and is A-DEP-02 / A-MOD-10 witness delegation acceptable for the
   Week-1 boundary?
4. **Certora baselines**: can Lido share the V2 and V3 report artifacts so
   §1.1 can be pinned by hash instead of characterization?
5. **Format / cadence**: expected deliverable format and review cadence for
   Weeks 2–4 (memo + checked artifacts + reproducible command per the
   proposal)?

## 5. Provenance

- Certora baselines: external references, not vendored (see §1.1).
- PR #1811 source: `lidofinance/core@d088bbc2deac9913b68036d73d35c37aa6279b90`.
- Verity: `33722270d996c7a3a520a71ecee42d7d232da100`.
- Rebuild: `make prove` runs `lake build LidoSRv3` and writes
  [`../../proofs/logs/proof-report.json`](../../proofs/logs/proof-report.json).
