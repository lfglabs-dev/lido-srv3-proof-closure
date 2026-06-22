# Lido Deliverable Improvement Report

Status: consolidated review of the current LaTeX report package now published
as `lfglabs-dev/lido-srv3-proof-closure`.

Review inputs: four parallel sub-agent reviews were run across proof/evidence
rigor, SRv3 technical correctness, editorial clarity, and Lido delivery polish.
The requested exact model roster was not directly selectable in this tool
surface, but the review was split across the same distinct lenses and then
synthesized here.

## Executive Verdict

The current PDF looks polished, but it is not yet safe to send to Lido as a
final formal-methods deliverable. The core issue is not typography; it is claim
calibration. The report body repeatedly states that selected SRv3 accounting
properties are already machine-checked and closed, while the package README says
this is a mock final report package that assumes proofs exist before real proof
artifacts exist.

To make the deliverable credible for Lido, either attach the actual proof
repository and reproducibility evidence, or demote the entire document from
"Private Final v1.0" to a proposal/report package. Do not leave it halfway: Lido
reviewers will treat unsupported "proved" language as the main finding.

## Top Improvements To Make

### 1. Remove Unsupported Completion Language

Severity: blocker.

Evidence:

- `README.md` says: "This is a mock final report package. It assumes the
  selected P0 properties were proved so the hierarchy, tone, and delivery shape
  can be evaluated before real proof artifacts exist."
- `content/01-disclaimer.tex:4-6` says this is a "private final
  formal-methods report" and summarizes "completed Lean/Verity artifacts".
- `content/02-executive-summary.tex:24-29` says all selected P0 properties are
  closed and machine-checked.
- `content/03-proof-closure.tex:235-267` lists named Lean theorem files as
  proved, but this workspace contains no corresponding `Reserves.lean`,
  `Deposits.lean`, `Balances.lean`, `Rewards.lean`, `Status.lean`, `lakefile`,
  or `trust-boundary.json`.
- `content/05-reproducibility.tex:6-10` points to
  `git@github.com:lfglabs-dev/lido-srv3-proof-closure.git`, which is not present
  in the workspace and cannot be verified from this package.

Recommended fix:

- If proofs do not exist yet, replace every `\stsProved`, "closed", "proved",
  "machine-checked", "final", and "no counterexample" claim with "proposed",
  "targeted", or "report package".
- Rename the title/version to `SRv3 Accounting Proof-Closure Proposal` and
  `Private Draft`.
- Change "What was closed" to "What should be closed first".
- Keep a single sentence that this is a report package of the final report shape.

Better phrase:

> This document proposes a focused proof-closure lane for the PR #1811 SRv3
> economic state machine. No property is claimed closed until the companion
> repository contains a reproducible theorem/check and a registered trust
> boundary.

### 2. Restore The Full PR #1811 Architecture Surface

Severity: high.

The LaTeX report narrows the proof matrix to six properties: reserve separation,
exact deposits, module balances, reward ordering, fee bounds, and status gates.
That is a reasonable subset only if clearly labeled "selected accounting
subset". For a Lido-facing PR #1811 deliverable, it omits several surfaces that
are central to SRv3 / EIP-7251:

- allocation capacity in `SRLib._getDepositAllocations`;
- 0x02 validator top-ups through `TopUpGateway.topUp` and
  `StakingRouter.topUp`;
- `AccountingOracle._checkStakingRouterModuleBalances` ordering before router
  balance mutation;
- exited-count monotonicity and extra-data paths;
- MaxEB / withdrawal-credentials-type-aware exit balance accounting in
  `ValidatorsExitBus` and `ValidatorsExitBusOracle`;
- consolidation request conservation across `ConsolidationMigrator`,
  `ConsolidationBus`, `ConsolidationGateway`, and `WithdrawalVault`;
- storage and role migration through `finalizeUpgrade_v4` and
  `SRLib._migrateStorage`;
- VaultHub/stVault boundaries, if the report mentions or inherits any V3 scope.

Recommended fix:

Use an 11-row proposed/closed register, not a 6-row final matrix:

| ID | Property | Why Lido cares |
| --- | --- | --- |
| SRV3-R1 | Deposit reserve separation | Withdrawal reserve must not become CL-deposit spend. |
| SRV3-R2 | Pull-deposit exactness | Router pulls exactly the ETH needed for actual 0x01 deposits. |
| SRV3-R3 | Allocation capacity | Allocations respect status, shares, module capacity, and WC type. |
| SRV3-R4 | Top-up witness and limit binding | 0x02 top-ups need valid witness and per-validator bounds. |
| SRV3-R5 | Report-before-balance mutation | Sanity checks must read prior state before accepted balances overwrite router state. |
| SRV3-R6 | Per-module balance sum | Router balance equals accepted per-module balance sum. |
| SRV3-R7 | Reward distribution over accepted balances | Fees and module rewards derive from accepted balances, excluding stopped modules. |
| SRV3-R8 | Exited-count monotonicity | Counts cannot decrease or exceed deposited counts. |
| SRV3-R9 | MaxEB-aware exit accounting | Exit limits are balance-weighted, not raw validator-count weighted. |
| SRV3-R10 | Consolidation request conservation | Request count, fee, source/target flattening, and limits agree. |
| SRV3-R11 | Migration preservation | Old SR identity, roles, and baseline balances map into new storage. |

### 3. Add A Real Evidence Manifest Before Any Final Claim

Severity: high.

The current reproducibility section is aspirational. A Lido reviewer needs a
manifest that can be checked without guessing where artifacts live.

Minimum manifest:

- PR #1811 exact commit: full hash, observed date, base branch, and whether the
  PR was open/merged at review time.
- Lean toolchain version and `lake-manifest.json` / `lean-toolchain`.
- Verity commit and generation command.
- Source mapping: theorem ID -> source path/function -> model file -> theorem
  file -> assumption IDs.
- SHA-256 hashes for the generated PDF and proof/trust-boundary files.
- The exact command that rebuilds the theorem namespace and fails on `sorry`,
  `admit`, custom axioms, or missing source links.

Better phrase for the PDF:

> A row is marked `Closed` only when the companion repository contains the
> theorem/check, source cross-reference, assumption record, and reproducible
> command output.

### 4. Make The Trust Boundary More Concrete And Less Legalistic

Severity: high.

The trust-boundary section is directionally good, but it is too generic for a
Lido protocol reviewer. It should name which assumptions are interface
summaries, which are oracle/consensus premises, and which are governance/deploy
premises.

Recommended structure:

| Category | Include |
| --- | --- |
| Proved/model target | arithmetic, array alignment, state update order, reserve accounting, balance sums, fee bounds, status gates |
| Assumed interfaces | staking modules, beacon deposit contract, withdrawal vault, top-up proof verifier, Lido locator, external callbacks |
| Oracle/consensus premises | accepted report honesty, CL witness soundness, EIP-4788/beacon-root availability, BLS/SSZ/Merkle correctness |
| Governance/deployment premises | role assignment, parameter admissibility, proxy/storage migration if not separately checked |
| Explicit non-claims | gas, events, revert strings, liveness, full deployed-system equivalence |

Also avoid wording that says public summaries should use "the same claim
language" as the report. Public language should usually be weaker, shorter, and
approved only after evidence is complete.

### 5. Tighten The Certora Delta

Severity: medium-high.

The appendix currently says prior Certora coverage is "replaced" or
"strengthened" without enough specificity. That can read as dismissive or
unsupported.

The useful delta is:

- Certora V2 covered many StakingRouter-style invariants, but used bounded loop
  assumptions and found issues around duplicate modules and exited/deposited
  count consistency.
- Certora V3 focused on the stVault/VaultHub stack and explicitly assumed at
  most two staking modules with constant parameters; it summarized
  `StakingRouter.deposit()` and `StakingRouter.reportRewardsMinted()` as
  nondeterministic.
- PR #1811 changes the target: balance-based module accounting, pull deposits,
  reserve separation, 0x02 top-ups, MaxEB-aware exits, consolidation, and
  migration.

Better phrase:

> This lane does not replace Certora V2/V3. It proposes a focused continuation
> over PR #1811 deltas: moving from bounded validator-count reasoning toward
> balance-based SRv3 accounting, explicit deposit/top-up transitions, and
> MaxEB-aware exit/consolidation invariants.

### 6. Fix Ambiguous Or Potentially Wrong Math

Severity: medium.

The P1 notation uses `D` as both "deposit reserve" and a term in
`min(T,D)`. If `D` means stored reserve target, say so; if it means allocated
deposit reserve, the formula is circular.

Use simpler notation:

```text
T = bufferedEther
d = min(T, storedDepositsReserve)
w = min(T - d, unfinalizedStETH)
u = T - d - w
depositable(T) = d + u
```

The P2 theorem says `routerEthAfter = routerEthBefore`. That is only meaningful
if the transition is modeled as pull-then-deposit in one atomic step. Say that
explicitly, or state the stronger accounting relation over inflow and outflow.

Better phrase:

> Across the modeled atomic deposit transition, router ETH is unchanged because
> every pulled 32 ETH unit is immediately forwarded to the beacon deposit sink.

### 7. Reduce Decorative Proof Claims And Add Source Anchors

Severity: medium.

The diagram and theorem register repeatedly show "proved" badges. Until the
evidence exists, this creates more risk than confidence. Replace badges with
source anchors and status labels:

- `Lido.sol`: `_getBufferedEtherAllocation`, `getDepositableEther`,
  `withdrawDepositableEther`;
- `StakingRouter.sol`: `deposit`, `topUp`,
  `reportValidatorBalancesByStakingModule`,
  `updateExitedValidatorsCountByStakingModule`,
  `getStakingRewardsDistribution`;
- `SRLib.sol`: `_getDepositAllocations`, `_migrateStorage`;
- `AccountingOracle.sol`: `_checkStakingRouterModuleBalances`;
- `ValidatorsExitBus*.sol`: `_calculateTotalExitBalanceEth`;
- `ConsolidationMigrator.sol` and related bus/gateway contracts.

### 8. Make The Report Smaller And More Direct

Severity: medium.

The strongest Lido-facing version is 4-6 pages plus appendix:

1. Claim and status.
2. PR #1811 architecture map.
3. Proof target register with `Proposed` / `Partial` / `Closed`.
4. Trust boundary.
5. Certora delta.
6. Reproducibility gate / evidence manifest.

Remove or shrink:

- repeated "proof closure" prose;
- public-release language;
- theorem names unless the files exist;
- generic statements like "not every byte of implementation plumbing".

Better phrase:

> The scope is intentionally economic: conservation, ordering, array alignment,
> and balance/fee bounds. Exact bytecode equivalence, cryptographic witness
> soundness, governance parameter choice, and deployment mechanics are separate
> lanes unless named in the evidence manifest.

### 9. Correct Concrete SRv3 Technical Misstatements

Severity: high.

The technical review found several places where the current report is not just
over-claiming evidence, but can mislead about PR #1811 behavior.

#### Split Initial Deposits From Top-Ups

The report says every modeled deposit path consumes exactly `32 ETH *
actualDeposits`. That is true only for the initial `StakingRouter.deposit()`
path. `StakingRouter.topUp()` pulls gwei-aligned per-key allocations bounded by
top-up limits; those are not 32 ETH validator deposits.

Recommended fix:

- Use `initialDeposit_exact_32eth_pull` for `StakingRouter.deposit()`.
- Use `topUp_exact_allocated_wei_pull` for `StakingRouter.topUp()`.
- Do not say "every modeled deposit path" unless top-ups are explicitly out of
  scope.

Better phrase:

> Initial 0x01 deposits pull exactly `32 ETH * actualDeposits`. Top-ups are a
> separate transition: they pull the accepted gwei-aligned allocation and must
> remain below the verified per-validator top-up limits.

#### Do Not Treat VaultHub As Unrelated To Accounting

The trust-boundary section says VaultHub is out of model and not a hidden
premise. That is too strong. The local core code shows Accounting reads
VaultHub bad debt during the report path and applies bad-debt internalization
before reward/rebase processing.

Recommended fix:

- Either model VaultHub bad-debt internalization as an explicit pre-report
  transition, or mark it as a named accounting assumption.
- Do not group VaultHub with unrelated non-claims if the report claims
  accounting closure.

Better phrase:

> VaultHub bad-debt internalization is treated as an explicit pre-report
> accounting premise unless separately modeled. The accounting closure assumes
> the VaultHub amount is well-formed and its internalization conserves the stated
> ether/share relation.

#### State Stopped-Module Rewards Precisely

The report says stopped modules receive no module reward. In the PR #1811 reward
path, stopped modules receive zero module-fee shares, but their module-fee
component remains in total protocol fee and is effectively retained for treasury
distribution through the residual treasury shares.

Recommended fix:

> Stopped modules receive zero module-fee shares. Their module-fee component is
> not paid to the module; it remains in total protocol fees and is swept through
> the treasury-side residual distribution.

#### Tighten Module-Balance Report Shape

The report repeatedly says "arbitrary finite module arrays." That is only safe
as a proof-generalization statement. The accepted report shape in the core code
requires the full current router module set, in router iteration order, with
array length equal to the module count.

Recommended fix:

> The theorem may be parametric in module count, but each accepted report covers
> the full current router module set in router iteration order.

#### Do Not Let Balance Conservation Replace Exited-Count Correctness

The appendix says V2 validator-count accounting is replaced by module-balance
conservation. That misses a distinct PR #1811 exited-validator pipeline:
module-level sorted totals, sanity limits, router storage updates, extra-data
node-operator updates, and completion callbacks.

Recommended fix:

> Module-balance conservation does not replace exited-count correctness. Exited
> validator reporting needs its own lane covering monotonicity, deposited-count
> bounds, sorted module IDs, node-operator extra data, and unsafe correction
> governance boundaries.

#### Narrow The Reward-Base Claim

Module balances determine fee-distribution weights, not the total reward amount
by themselves. Total protocol reward/fee computation also depends on the full
oracle report, CL balances, pending balance, withdrawals vault transfer, EL
rewards vault transfer, principal CL balance, share state, and smoothing.

Better phrase:

> Accepted module balances determine module fee-distribution weights. Reward
> magnitude and total fee are computed by Accounting from the full accepted
> oracle report and vault-transfer context.

#### Avoid `W' = W` In Reserve Separation

The current notation says withdrawal reserve is unchanged after deposit spend.
In Lido, the effective reserve buckets are recomputed from the remaining buffer,
while stored deposit reserve decreases during `withdrawDepositableEther()`.

Better phrase:

> Deposit spend is bounded by the pre-spend `depositsReserve + unreserved`
> allocation and does not consume the pre-spend effective `withdrawalsReserve`
> bucket. Any post-state reserve statement should model recomputation explicitly.

#### Use SRv3 Reward Recipient Terminology

The report uses `feeRecipient_m`. In the local SRv3 reward path, the recipient
is the module address used for `onRewardsMinted`, not a separate fee-recipient
field.

Recommended fix:

> Rename `feeRecipient_m` to `moduleAddress_m` or
> `rewardRecipient_m = moduleAddress_m`.

### 10. Fix Handoff Path And Package Hygiene Issues

Severity: medium.

The delivery review found several handoff issues that would create avoidable
questions for Lido:

- `content/05-reproducibility.tex` references `report/final.pdf`, but this
  package builds `dist/lido-srv3-formal-methods-report.pdf`.
- The report cites an external proof repo while the current handoff package only
  contains LaTeX/PDF materials.
- The cover uses short commit `d088bbc2`; formal provenance should use the full
  PR #1811 head hash, repo, observed date, and PR state.
- The package contains build intermediates and an empty `scripts/` directory;
  either remove unused handoff material or document its role.
- The final package should include checksums for the PDF and any proof/evidence
  bundle.

Recommended fix:

> Align every handoff path in the PDF, README, and package tree. A reviewer
> should be able to follow one path from `README.md` to the exact PDF, proof
> repository, trust-boundary file, source map, and rebuild command without
> inference.

## Suggested Replacement Opening

```text
This document is a private draft/proposal for a focused formal-methods lane over
Lido PR #1811 at d088bbc2deac9913b68036d73d35c37aa6279b90.

The target is not "Lido is verified." The target is narrower: identify and, once
the companion proofs exist, close the SRv3 economic-state-machine obligations
introduced by balance-based module accounting, pull deposits, deposit reserve
separation, 0x02 top-ups, accepted module-balance reports, rewards, exits,
consolidation, and migration.

No property in this report is final unless its row is marked Closed and the
evidence manifest gives a reproducible command, source mapping, and trust-boundary
entry.
```

## Final Priority Order

1. Decide final-vs-proposal status and make every section match that status.
2. Add or remove the proof repository claims; do not cite unverifiable Lean files.
3. Expand the target register to the full PR #1811 SRv3 architecture surface.
4. Correct the concrete SRv3 misstatements around top-ups, VaultHub, stopped
   module rewards, report shape, exited-count reporting, and reward-base inputs.
5. Replace generic assumptions with source-linked trust-boundary rows.
6. Add a real evidence manifest and reproducibility gate.
7. Tighten the Certora delta as a continuation, not a replacement.
8. Simplify the math and make notation non-circular.
9. Align handoff paths, provenance, checksums, and package hygiene.
10. Shorten the PDF around claim/evidence/boundary rather than presentation
    prose.

## Applied Readability Pass: 2026-06-22

This pass focused on the user's requested reader journey: make the report take a
non-specialist by the hand while preserving formal-methods rigor.

Changes applied:

- Reframed the PDF as a `Private Report package v1.1` and aligned the disclaimer with
  the README's mock/report package status.
- Updated the cover subtitle and PDF metadata so the first page no longer
  implies final machine-checked proof evidence exists in this repository.
- Updated the README and executive summary so the report package describes intended
  final proof evidence rather than assuming selected properties are already
  proved in this repository.
- Added a short educational note explaining why theorem checking is stronger
  than example-based testing within a named model and assumption set.
- Replaced the result-first opening with a question-first executive summary:
  what PR #1811 changes, why accounting mistakes matter, and what the proof lane
  is trying to establish.
- Added a concrete "closed" criterion so proof-closure language has an evidence
  threshold instead of sounding like a slogan.
- Introduced the three-ledger mental model: buffer ledger, router ledger, and
  reward ledger.
- Defined accepted reports on first use.
- Reworked the proof section into a guided path: architecture map, plain-language
  story, then formal invariants.
- Simplified the P1 reserve notation with explicit deposit, withdrawal, and
  unreserved buckets.
- Narrowed P2 to atomic initial deposits and separated top-ups into a future
  lane.
- Tightened reward wording so accepted balances determine module fee-distribution
  weights, while total reward magnitude remains an input under assumptions.
- Renamed the notation from `feeRecipient_m` to `moduleRecipient_m` for the
  modeled reward-recipient path.
- Added theorem-to-assumption traceability expected in a real delivery package.
- Collapsed the executive matrix to remove a visually over-strong status column;
  the text now explains that the rows are targets.
- Replaced visible `Proved` labels in report package tables with claim descriptions
  and expected traceability.
- Merged the theorem register and assumption mapping into one traceability table
  with readable proof handles.
- Made explanatory table columns ragged-right to reduce awkward justification
  and hyphenation.
- Reworked the handoff section from path-heavy table rows into a description
  list that keeps artifact labels, paths, and purpose readable.
- Converted the appendix axiom/counterexample counts into expected final-package
  checks rather than factual claims about artifacts present in this repository.
- Removed top-up wording from the selected six-row claims and kept
  top-up work in follow-on lanes.
- Replaced the P1 post-state reserve equality sketch with a pre-state
  withdrawal-reserve non-consumption condition and split the formula into two
  readable obligations.
- Added a reader glossary before the technical appendices.
- Added minimum provenance fields for a real reproducibility package.
- Tightened P6 everywhere to separate deposit gating for non-active or
  deposit-paused modules from module-side reward/fee gating for stopped modules.
- Softened the trust-check wording so source anchors are required in the final
  evidence manifest, without implying this report package PDF already contains every
  concrete source-code link.
- Rendered the full PR target hash with breakable path formatting in the
  provenance table.
- Added concrete source-anchor examples for the final manifest, including Lido
  buffer/reserve functions, SRv3 deposit/reward functions, and AccountingOracle
  report validation.

Build evidence:

- `make` succeeds.
- The rebuilt PDF is `dist/lido-srv3-formal-methods-report.pdf`.
- PDF SHA-256 after this pass:
  `8d29e74099fa6826565bed0e5967e12b74b9af582054b28c40c44d9601900ad4`.

Remaining known issues:

- The PDF is still a report package. A real final deliverable requires the companion
  proof repository, source map, trust-boundary JSON, and reproducible theorem
  build.
- LaTeX emits two pre-existing cover-logo overfull warnings, one small
  proof-matrix overfull warning, and several cosmetic underfull table/list
  warnings. The build completes and the generated PDF is updated.
