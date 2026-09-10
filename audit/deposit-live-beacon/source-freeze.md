# P-DEPOSIT-1 actual-callee composition candidate — freeze receipt

Frozen by mission-19405e46 under exclusive DEPOSIT ownership (after dd0e10b8 ACK; dd0 not resumed).

## Frozen SHA

- Repository: `/workspaces/mission-f253848d/temp/lido-deposit-a582` (branch `deposit/live-beacon-a582`)
- Commit: `2741475f298bfda8d20a778dd9f407ded0517e25`
- Tree: `3004dd11658a4250b88610d8a130581dc47bc323`
- Parent: `02b53a157e5e6e2049faced7f26009cbc55eb932` ("Merge PR #293: derive actual SHA effects in raw witness consumer")
- Scope: `audit/trio/deposit/` only (10 files, +1076/-5). No SSZ/TOPUP/site/registry/trust changes.

## Pinned source (unchanged)

- Solidity pin: `lidofinance/core@17005714f151e5502c559932319a3f2f74ac2436` (PIN 17005714 preserved)

## Preserved artifacts (sha256, verified inside the frozen commit)

- `LiveBeacon.lean`: `a8baf4087e56e43b5156b22d0c34581c1304ca3efc01af57dbbc6200bbbd4429` (a8baf408)
- `Tests/Verity/LiveBeacon.lean`: `71f6ba81327a25eab7b645aac2c2a3137cc9dcf42708e6bb453679670947157a` (71f6ba81)
- `RouterDeposit.lean`: `fc1ee497cf7e2984e87df390256571903c54d0aed6e2f8f42f265fe81f1dfa28`
- `Deposit.lean`: `9fb5b55477fef0cedd4733fd5c144446a31ad49ec7c749e5f2079b2efa83759d`
- Build log (probe evidence, "Build completed successfully (1318 jobs)"):
  `1054f0adbe7d15819fb3f45b694285ae67d1283d68d52c3213a4b83f6d962289` (1054f0ad)

## Evidence class

Probe evidence only. `lake build TrioDeposit` (isolated slice) succeeded. Universal theorems
are kernel-clean ([propext, Quot.sound], +Classical.choice for `positive_success`). Fixture
`prepared_eq` and the six fixture theorems are `native_decide` — NOT kernel
(`prepared_eq._native.native_decide.ax_1_1`). `LiveBeaconKernelProbe.lean` documents the open
kernel question and is not a delivered target (its standalone build fails; excluded from the
TrioDeposit globs).

No github_pr created. remote-lean-build not used (prior remote-lean-build job already terminated).
