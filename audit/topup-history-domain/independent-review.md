I'll run an independent exact-head review of PR #285 in this workspace: inspect the 10-file candidate, imported history/bounds, harness, and pinned Solidity identities without mutating git or rebuilding.PR #285 objects aren't local yet. I'll pull the 10-file candidate read-only and start reading source, harness, and pins.Fetched PR head `2db21492` on base `bc108ac`. Next I'll extract the 10 files and read Lean, Solidity, harness, and pin identities.Candidate files are in. Next I'll read the imported Lean models, the #278 harness, and the pinned TopUpGateway source.I'll machine-check import-closure hashes, pin 23 Solidity inputs to `17005714`, and re-read the remaining source-order and pause/root-age paths.Continuing the exact-head review from the extracted PR files: remaining source-order comparison, pin identities, import closure, then an independent verdict.I'll re-read the Lean theorems and remaining TopUpGateway guards, then machine-check hashes and the 23 compiler pins.I'll dump the Lean theorems, remaining Solidity guards, and run identity/hash checks without rebuilding.Next I'll pin Solidity identities, dump `_verifyRootAge`, and machine-check the 532-file closure.Fetched `191a807` (receipt validation head). Next I'll compare trees, pin the 23 Solidity inputs, and machine-check the identity closure.I'll pin the 23 Solidity inputs to `17005714`, hash-check the 10-file candidate and ~480-file closure, and finish the source-order math review.Identity and source-order checks are complete. Issuing the independent verdict.Independent exact-head review of [lfglabs-dev/lido-srv3-proof-closure#285](https://github.com/lfglabs-dev/lido-srv3-proof-closure/pull/285) DRAFT.

| Pin | Value |
|---|---|
| Head | `2db21492d2d39f3199ce25f0deea9225190d6485` |
| Parent / base | `bc108ac37b9bffb744e30df1378e05a5aa9f3e20` (exact parent) |
| Solidity pin | `17005714f151e5502c559932319a3f2f74ac2436` (lido-core HEAD) |
| Diff | 10 files only |
| Writer | false (no merge/push/comment/source edit) |

This increment is a **uint32 history-domain diagnostic**. It is **not** authenticated consensus, **not** an actual router/module/beacon ETH cap breach, **not** a deployed vulnerability, **not** delivered TOPUP-2, and it **does not close** any of the eight open guarantees. **P-TOPUP-1 and P-TOPUP-2 stay OPEN.**

## Candidate (10 files) + imports

PR blobs at `2db21492` match receipt hashes. Imported [TopupCallHistory.lean](/workspaces/mission-35839bb3/temp/pr285/LidoSRv3/Audit/Source/TopupCallHistory.lean) / [TopupWeiBounds.lean](/workspaces/mission-35839bb3/temp/pr285/LidoSRv3/Audit/Source/TopupWeiBounds.lean) and inherited [TopupGatewayWitnessBatch.t.sol](/workspaces/mission-35839bb3/temp/pr285/audit/topup-gateway-witness-batch/solidity/TopupGatewayWitnessBatch.t.sol) are **byte-identical to base**.

Lean ([TopupHistoryDomain.lean](/workspaces/mission-35839bb3/temp/pr285/LidoSRv3/Audit/Source/TopupHistoryDomain.lean)): 3 public theorems, 3 `#print axioms`.

| Theorem | Claim |
|---|---|
| `truncated_blocks_reopen` | ∀ state, ∀ `blockNumber ≥ 2^32`, ∀ `total > 0`: post-`finish` distance check is `some true` |
| `truncated_timestamp_is_older` | ∀ `timestamp ≥ 2^32`, stored `uint32` word is strictly older than the full timestamp |
| `configured_does_not_give_unrestricted_exclusion` | setter/update `Configured` does **not** imply unrestricted same-block post-return exclusion |

Recorded axiom queries (validation.log hash matches head): `propext` + `Quot.sound` only (`truncated_timestamp_is_older` is `propext` alone). Targeted 496-job / 2.4s source is recorded, not rebuilt.

Solidity ([TopupHistoryDomain.t.sol](/workspaces/mission-35839bb3/temp/pr285/audit/topup-history-domain/solidity/TopupHistoryDomain.t.sol)): 3 tests inherit `#278` harness; recorded Forge 3/3 pass (solc 0.8.25 / viaIR / opt 200 / Cancun). Not rebuilt.

## Source-faithful guards / update / order

Pinned `TopUpGateway.topUp` order at 17005714:

1. `onlyRole(TOP_UP_ROLE)` + `whenResumed`
2. array / max-validator guards
3. `_requireBlockDistancePassed` (`lastTopUpBlock == 0 \|\| block.number - lastTopUpBlock >= minBlockDistance`)
4. `_verifyRootAge` (maxRootAge; `childBlockTimestamp <= lastTopUpTimestamp` → `RootPrecedesLastTopUp`)
5. WC / pubkey / sort / activation / SSZ
6. **`stakingRouter.topUp` first** (line 232)
7. then if `totalLimits > 0`: `_setLastTopUpData` with **`uint32(block.timestamp)` / `uint32(block.number)`** (340–345)

Lean `finish` / `distancePassed` / `setDistance` match those casts, the zero-sentinel, checked subtraction, and the uint16 setter (`0` and `> 65535` rejected). Router-before-write is documented in TopupCallHistory and preserved.

`truncated_blocks_reopen` is the **full** domain `blockNumber ≥ 2^32` and every representable uint16 delay (`distance.isLt`), not only the zero sentinel. Independent Nat check: reopen holds on `{2^32, 2^32+1, 2^32+123, 2^33-1, …}` for delays `{1, 65535}`; within `0 < b < 2^32` the existing same-block reject still holds.

Tests keep `minBlockDistance = 1`. At `2^32-1` the second same-block call reverts `MinBlockDistanceNotMet` (one router commit). At `2^32` and `2^32+123` the truncating write reopens the guard (two router commits). Timestamp `1606824023 + 12*n` fits `uint64`; truncated last timestamp is older than the supplied child, so root-age is satisfied **without** bypassing `_verifyRootAge`.

## Harness / no bypass

- `GatewayWitnessHarness` inherits `TopUpGateway` with **no** `override` of `topUp`, `_setLastTopUpData`, `_isBlockDistancePassed`, or `_verifyRootAge`.
- Constructor uses existing internal setters + `TOP_UP_ROLE` grant (standalone fixture, not a production proxy).
- Router is an explicit recorder; EIP-4788 root is `vm.mockCall`; synthetic header **slot 4096** and opaque state fields are unchanged.
- Diagnostic tests do **not** `vm.store` last-top-up slots, skip pause/role/input/root-age/credential/SSZ, or forge history.
- Parent `testFuzz_actualConfigWordReads` still uses `vm.store` on the config namespace; that is the accepted #278 harness, unused by these three tests.

## Identity (532 checker)

`check_receipt.py` formula: 32 validated + 5 evidence + 480 closure + 11 package pins + 4 selected Lean core = **532**.

| Bucket | Result |
|---|---|
| 10-file candidate @ `2db21492` | hashes match receipt |
| 17 `lido-core/` compiler inputs | byte-equal to `17005714` (sha256) |
| 23 compiler inputs | sha256 + keccak256 all match (OZ v5.2.0 recovered independently) |
| Lake closure 480 | 480/480 sha256 (aesop 132, batteries 67, mathlib 230, … + 2 local Lean sources) |
| Package pins 11 | exact revs including batteries `fa08db58…`, Cli `92564e57…` |
| Lean v4.31.0 selected Init/Omega | 4/4 |

No Lean/Forge rebuild of unchanged artifacts.

Receipt `checkout_head_at_validation` is `191a807d` (unrelated tree), not PR head `2db21492`. The **10 candidate blobs** still match. Process note only; not a source mismatch.

## Scope retained (do not relabel)

- uint32 block/timestamp truncation **invalidates unrestricted post-return same-block exclusion** in this source fixture.
- **Not** authenticated consensus, actual router/module/beacon ETH cap breach, or a deployed vulnerability.
- Harness remains root mock / router recorder / synthetic slot 4096.
- **Not** delivered TOPUP-2; eight complete guarantees remain **OPEN**.
- Internal full history/funding obligations remain **OPEN**. External scope remains external.
- **P-TOPUP-1** and **P-TOPUP-2** remain **OPEN** regardless of increment quality.

VERDICT: CLEAN
