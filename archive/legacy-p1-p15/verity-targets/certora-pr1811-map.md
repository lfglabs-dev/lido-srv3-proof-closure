# Lido SRv3 pilot assumption map

## Scope and reading rule

This map compares two assurance baselines with the audited SRv3 snapshot:

- **Certora Lido V2** (April 2023; final audited commit `e45c4d6`) — the primary StakingRouter-era baseline.
- **Certora Lido V3 FV** (December 2025; audited commit `b98371488eb9479cf072bd6c2b682a59c5dd71d8`) — a secondary system baseline focused mainly on VaultHub/stVaults.
- **SRv3 target** — `lidofinance/core@af095e48bbc1c3841c2c9936219c8461af01056b`.
- **Proof toolchain** — `lfglabs-dev/verity@6cfc41fe4129e2c56f130bab9617a0c677ce60ae`.

Three statements must stay separate:

1. **Baseline coverage:** an older Certora rule was checked on older code.
2. **Semantic carry-over:** the same safety objective still makes sense for SRv3.
3. **Current coverage:** the pinned Lean model checks a claim under the named premises in [`trust-boundary.json`](./trust-boundary.json).

An old proof is never treated as a proof of `af095e48`; a model theorem is never treated as a full Solidity refinement proof.

## 1. What remains applicable

These are still valid **safety objectives**, not inherited proofs.

1. **Module registry and configuration integrity.** Module ids/indexes, uniqueness, fee/share bounds, and localized lifecycle/configuration updates remain necessary. V2 checked this class of rules and found duplicate-module weaknesses (pp. 24–26). The current artifact checks related update loops in SRV3-P11–P15, but those are follow-on/internal targets rather than the signed P0 claim.
   - **Falsifier:** a valid SRv3 transition duplicates or reorders a module, exceeds a configured bound, or mutates an unrelated module.

2. **Exited-count guards.** Exited counts must remain monotone and must not exceed deposited validators. V2's `exited ≤ deposited` router rule was **violated** (M-03), so this is a carried objective—not carried assurance. It no longer characterizes stake after MaxEB or partial exits. The current model checks the count guard in SRV3-P7 under `A-MOD-08` and `A-ID-04`.
   - **Falsifier:** an accepted update decreases exited count or makes `exited > deposited` for a module.

3. **Allocation conservation and capacity bounds.** SRV3-P9 checks initial-deposit allocation under `A-ALLOC-12`; SRv3 still needs a separate form for variable-value `0x02` top-ups.
   - **Falsifier:** allocations exceed the router budget, module capacity, or the top-up per-block cap.

## 2. What depends on assumptions

1. **Reserve separation and exact initial-deposit transfer (SRV3-P1/P2).** The model checks that withdrawal-reserved ETH is excluded and that a successful initial deposit pulls and sinks exactly `32 ETH × processed validators`. The deployed guarantee still depends on `LIDO.withdrawDepositableEther`, module deposit data, arithmetic, and the beacon sink behaving as modeled (`A-LIDO-06`, `A-MOD-07`, `A-DEP-02`, `A-ARITH-05`, `A-EXT-01`).
   - **Falsifier:** the same call spends withdrawal-reserved ETH, pulls a different amount, or leaves/duplicates value at the router.

2. **One accepted report drives balances and fees (SRV3-P3/P4/P5).** The model checks router balance aggregation, report-before-reward ordering, and bounded recipient-aligned fees. Reports rely on validation-accepted, structurally re-checked inputs—not oracle truthfulness—under `A-ORC-03` and `A-ID-04`; fees rely on `A-REWARD-09` and `A-ID-04`. `A-MOD-13` applies to P10 callbacks, not P5.
   - **Falsifier:** fees mix report epochs, omit/duplicate/reorder a module, or pair an amount with the wrong recipient.

3. **Lifecycle and top-up enforcement (SRV3-P6/P8).** Deposit/status gates are P0; top-up conservation is supporting evidence, not a signed P0 commitment. P6 relies on governance/configuration (`A-GOV-14`). P8 additionally relies on module-returned allocations/stake, Lido and sink exactness, and arithmetic (`A-MOD-10`, `A-MOD-11`, `A-LIDO-06`, `A-DEP-02`, `A-ARITH-05`); the mutable cap remains under `A-GOV-14`.
   - **Falsifier:** a paused/stopped module receives a forbidden deposit/reward, or a top-up exceeds its accepted allocations, limits, budget, or per-block cap.

## 3. What no longer carries over

1. **Validator-count rules do not establish SRv3 balance accounting.** The router still computes and enforces `maxDepositsCount`; what disappeared is V2's caller-supplied `depositCount`. The realized count now comes from `obtainDepositData` within the router cap under `A-MOD-07`. None of this covers reported balances, MaxEB value, or variable top-ups.

2. **Bounded or summarized proofs do not generalize.** V2 unrolled loops to at most three modules and replaced the 32 ETH beacon call with an optimistic transfer (pp. 24–26). V3 assumed at most two modules with constant parameters and summarized `deposit()` and `reportRewardsMinted()` as `NONDET` (pp. 27–29). Those results cannot support unbounded dynamic arrays, mutable parameters, or end-to-end deposit/reward claims in SRv3.

3. **V3 VaultHub/stVault/PDG properties are adjacent, not router evidence.** They may remain valid for their own components, but they neither prove nor refute SRv3 router accounting, top-ups, exits, or migration.

## 4. What should be verified next

Ordered by risk reduction:

1. **Bind the model to Solidity at `af095e48`.** Add executable refinement/correspondence checks for P1–P6, including revert branches and state writes; today the correspondence register is reviewed evidence, not a machine-checked refinement.
2. **Stress the report → balance → reward chain with dynamic modules and mutable parameters.** Prove no stale/mixed snapshot is possible across add/update/status/report/reward sequences.
3. **Close the top-up interface boundary.** Bind module-returned keys/allocations to ownership and limits, and bind exact value to the real beacon top-up sink, including zero-target and per-block-cap paths.
4. **Model balance-aware and partial exits.** Extend beyond exited-count monotonicity to MaxEB value conservation, partial-exit accounting, authorization, replay resistance, and fee/refund exactness.
5. **Cover consolidation and migration.** Prove source/target binding, request/fee conservation, replay/limit handling, and storage/role/accounting preservation.

## Evidence index

| Area | Baseline anchor | Audited SRv3 anchor | Current artifact |
| --- | --- | --- | --- |
| Registry/status/fees | V2 pp. 24–26 | `SRLib::_addModule`, `_updateModuleParams`, `_setModuleStatus`; `StakingRouter` update entry points | SRV3-P6, P11–P15 |
| Reserve and initial deposit | V2 `integrityOfDeposit`; optimistic beacon-transfer assumption | `Lido::_getBufferedEtherAllocation`, `_spendDepositableEther`, `withdrawDepositableEther`; `StakingRouter::deposit` | SRV3-P1/P2 |
| Balance report snapshot | V2 count/report integrity; V3 router calls summarized | `SRLib::_reportValidatorBalancesByStakingModule`; `RouterStateAccounting` | SRV3-P3/P4 |
| Fee distribution | V2 fee aggregation; V3 accounting fee arithmetic summary | `StakingRouter::getStakingRewardsDistribution`, `_computeModuleFee` | SRV3-P5 |
| Top-up | Not covered by the router baselines | `StakingRouter::topUp`, `_validateTopUpInputs`; `IStakingModuleV2::allocateDeposits` | SRV3-P8 (supporting) |
| Exits/consolidation/migration | Older count guards; adjacent V3 scope | exit-bus, consolidation, and storage-migration surfaces | P7 count guard only; remainder follow-on |

Line-level source correspondence is in [`solidity-correspondence.md`](./solidity-correspondence.md); theorem handles are in [`srv3-proof-targets.json`](./srv3-proof-targets.json).

## Explicit non-claims

The current artifact does **not** establish oracle truthfulness, BLS/SSZ/Merkle correctness, external module honesty, governance/role configuration, packed-storage equivalence, liveness/gas/event behavior, consolidation, full partial-exit economics, or whole-program Solidity refinement.

All P1–P15 are Lean-checked; scope still differs: P1–P6 are the signed economic core, P8/P9 are P0 decompositions, and P7/P10–P15 are follow-on lanes until their interface and refinement gaps are closed.
