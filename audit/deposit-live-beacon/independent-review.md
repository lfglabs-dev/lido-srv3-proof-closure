# Independent source review — P-DEPOSIT-1 actual-callee composition candidate

Reviewer: mission-19405e46 (independent of authors mission-0d2f56a0 / f253848d / dd0e10b8).
Subject SHA: `2741475f298bfda8d20a778dd9f407ded0517e25` (tree `3004dd11658a4250b88610d8a130581dc47bc323`),
repo `/workspaces/mission-f253848d/temp/lido-deposit-a582`, branch `deposit/live-beacon-a582`.
Solidity pin reviewed against: `lidofinance/core@17005714f151e5502c559932319a3f2f74ac2436` (PIN 17005714 preserved).
Evidence class: probe evidence only (isolated `lake build TrioDeposit`, log sha256 1054f0ad, 1318 jobs, no errors, no sorry warnings).

## Scope of the change (vs parent 02b53a15)

`audit/trio/deposit/` only: Deposit.lean (+54), RouterDeposit.lean (+47/-2), README.md, lakefile.lean,
hash-router-deposit.sh; new LiveBeacon.lean (616 lines), Tests/Verity/LiveBeacon.lean (187),
Tests/Verity/LiveBeaconKernelProbe.lean (not a delivered target), slice lake-manifest.json / lean-toolchain.
No SSZ/TOPUP/site/registry/trust-surface files touched. Exclusive DEPOSIT scope respected.

## Findings

1. **LinksSource is now derived, not supplied — soundly.** Chain:
   `Deposit.prepareDepositABI_composes_beacon_values` (Deposit.lean:317) unfolds the executed
   `prepareDepositABI` prefix and proves `beaconPerKeyWei = depositSize`,
   `beaconTotalWei = actualKeys * depositSize`, pull/checksum facts, and `0 < maxEBType1`.
   `RouterDeposit.linksSource_of_prepareDepositABI` (RouterDeposit.lean:474) projects exactly the
   `LinksSource` fields from it. `execute_ok_conservation_derived` (RouterDeposit.lean:494) obtains the
   executed prefix from `execute_ok_conservation` (7-component existential shape matches) and rewrites the
   beacon credit via `hLink.total ▸ hBeacon`. The de-privatization of `rootInput`/`makeCall` is required by
   LiveBeacon's reuse and widens no assumptions.
2. **LiveBeacon is a genuine live-callee composition.** Beacon deposits are actual CALLs dispatched to the
   accepted PR273 callee (`TopupBeaconBatch.loop` / `TopupBeaconCallee.dispatch sha256`) in one `Live.World`;
   the line 996 assertion reads the live ledger (`finish`); rollback (`execute` wrapper restoring `before` on
   any fault) is proved by `failure_restores`. `positive_success` derives Lido debit, beacon credit of
   `actualKeys * DEPOSIT_SIZE`, router-balance restoration, other-account preservation, count increment,
   chronological journal and effect chain from source/physical inputs, with `maxEBType1 = DEPOSIT_SIZE`
   (`A-DEPOSIT-32-ETHER`) kept as an explicit hypothesis — consistent with the still-OPEN artifact-identity
   assumptions. Honest scoping throughout (docstrings name the remaining gaps: SHA-256/precompile boundary,
   ABI decoder, deployed identity, physical router storage).
3. **No sorry / admit / user axioms** in any delivered file (grep clean; build log has no sorry warnings).
4. **Axiom profile matches the native_decide-not-kernel constraint.** Per the frozen build log:
   `prepareDepositABI_composes_beacon_values`, `linksSource_of_prepareDepositABI`,
   `execute_ok_conservation_derived`, `failure_restores` depend on [propext, Quot.sound];
   `positive_success` adds Classical.choice. Fixture `prepared_eq` and the six fixture theorems carry
   `prepared_eq._native.native_decide.ax_1_1` — native_decide, **not kernel** — and Tests/Verity/LiveBeacon.lean:178
   states this explicitly. `LiveBeaconKernelProbe.lean` (`by decide`, `by decide +kernel`, `by rfl`) is excluded
   from the TrioDeposit globs; its standalone build fails (mission-6dba19da log), so the kernel question
   remains honestly open. No kernel claim is made anywhere.
5. **Executable regressions cover the load-bearing paths**: success fixture (2 keys, ledger/count/journal/log
   assertions), late tree-full rejection after an accepted first deposit (raw keeps the effect, wrapper rolls
   back), `maxEBType1 ≠ DEPOSIT_SIZE` run reaching and failing Panic(0x01), and three pre-CALL guard rollbacks.
   Mutant-style negative controls are `#eval` probes (native execution), consistent with the evidence class.
6. **Preserved artifacts verified in the commit**: LiveBeacon.lean a8baf408…, Tests/Verity/LiveBeacon.lean
   71f6ba81…, RouterDeposit.lean fc1ee497… — byte-identical to the dd0-evidenced slice.

## Reservations (non-blocking, all pre-existing and named)

- `A-DEPOSIT-CONTRACT` / `A-DEPOSIT-32-ETHER` remain OPEN artifact-identity assumptions (correctly kept as
  hypotheses, not silently discharged).
- Fixture-level equality rests on native_decide; a kernel-checked fixture remains future work (KernelProbe).
- Model-vs-compiled-EVM correspondence, physical router storage, and deployment identity remain open per README.

## Verdict

**ACCEPT** the frozen SHA `2741475f298bfda8d20a778dd9f407ded0517e25` as the P-DEPOSIT-1 actual-callee
composition candidate at probe-evidence strength. P-DEPOSIT remains OPEN (Stage C gates: correspondence,
deployment artifacts), but the candidate is sound, honestly scoped, and correctly frozen.
