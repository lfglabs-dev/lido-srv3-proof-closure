# Independent DEPOSIT actual module CALL integration review

Verdict: **CLEAN** for exact frozen commit `03d2363452b67a08d520a75e181e91861b769a77` in `/tmp/lido-deposit-module-integrated`. Root's writer was stopped. I authored none of this DEPOSIT increment or integration. The candidate remained clean and exact; this review wrote only this external report.

## Complete union and source preservation

Union `476abdbe1fb7b9b14c0162b484e91cd50ea534af` joins independently reviewed source `80f391eedea92824327edefffe3f75635e1d271e` with accepted main `3b818d143fc7ef730d8b249f333d11c4251ef898`, including CONSOL320, ACCOUNT319 and TOPUP318. Both are ancestors. Recursive comparison of complete Git trees preserves every accepted-main object outside the three explicitly reviewed wiring files: lakefile, AllGuarantees and Trust. No prior executor, proof, dependency pin or accepted audit object changes. `git diff --check` passes.

All four new Lean files and the complete original source packet are byte-identical to 80f3. All 23 source-packet hashes and six integration-receipt hashes match. The integration source review is a verbatim copy of my external full source/Solidity/IR report. I read all integration changes and the seven-file integration dossier. The 115 scoped local source identities and 11 actual package revisions still match. The six pinned Solidity sources and seven compiler-input SHA-256 identities remain unchanged. The previous exact source review therefore applies without repeating its expensive validation.

## Effective providers and consumers

Root adds three explicit module globs to the existing single TrioDepositCommitted provider: `audit.trio.deposit.ModuleCall`, `audit.trio.deposit.ModulePhysicalMetadata`, and `audit.trio.deposit.Tests.Verity.ModulePhysicalMetadataTest`. Existing roots/globs remain. There is no additional provider, package or dependency pin.

AllGuarantees imports `LidoSRv3.Audit.Guarantees.PDeposit1ModuleCalls`. Trust imports the actual regression module and adds four active queries: both public success/failure consumers, ModuleCall.decodeReturn_size_bounds and ModulePhysicalMetadata.success_effects. Existing aggregate imports and queries are preserved.

I checked actual setup files and normal build traces for the four new modules plus AllGuarantees and Trust. Each has its intended module identity, empty options and no plugins or kernel-skipping flag. Every recorded local scoped import resolves to this checkout's actual local artifact. AllGuarantees consumes the new public module; Trust consumes both it and the real regression module. The registered test import therefore reaches the kernel examples, positive public instance and runtime checks rather than merely referring to their names in documentation.

## Registered artifacts and validation

Normal Lake artifacts differ from the source candidate's manual compile. I verified all four current recorded SHA-256 hashes against actual bytes and confirmed each differs from its historical candidate olean hash:

- ModuleCall: `d52cd5a93e298ee242b13a206d760e56355b26813e7b8d7c475e6c156c60d6ab`.
- ModulePhysicalMetadata: `c072a7300f1277293ed32f29644964e337c8c22c6cd7211cb651940c1a52bd3c`.
- PDeposit1ModuleCalls: `289c4e0b26707c175d7dd0a46848483ce28d24eb4cffb1283a87b6a10af5c753`.
- ModulePhysicalMetadataTest: `07806167b3ea3de2405d9f3be868a483f633c5174a516aa461d888e86c667566`.

The README and scoped receipt explicitly distinguish these current artifacts from historical candidate cache identities. They make no false byte-identical olean reuse claim. Source bodies and public statements remain identical.

The retained normal AllGuarantees/Trust build completes 1,704 jobs successfully and includes the four newly registered modules and actual aggregate consumers. I parsed the complete Trust messages: every active Trust query is represented, and their union is exactly the unchanged 29 disclosed axioms, comprising 23 native test/mutant axioms, three production exceptions and three foundations. The fresh retained gate records dependency recomputation and native-claim re-evaluation. This is not a globally foundations-only claim.

The scoped receipt and complete scoped log agree on all 26 newly named theorems: 15 production and 11 regression. Their sets agree with the prior independently reviewed source semantics and contain foundations only. I also independently recomputed all 26 sets from the actual registered test environment using the trust checker's environment-dependency probe. Exact equality passed. This probe does not rely on the candidate's printed log. No new axiom, reduction escape or supplied-success premise enters through registration.

No aggregate build or Solidity execution was repeated by this review. The source's four normal-kernel rechecks, 11 named regression theorems, 16 unnamed kernel examples, two runtime checks and fresh 64-vector export remain valid by source identity. The eight Forge tests, 256 seeded fuzz cases and 64 vector comparisons remain retained source evidence with unchanged pinned solc 0.8.25/optimizer200/viaIR/Cancun inputs; integration does not claim a fresh Solidity run.

## Public scope retained

The public success result still comes from one actual root execution: physical address/cap and real payload, arbitrary module reply/world, executed raw dual-bytes scalar allocator and signed/unsigned bounds, checked count/value preparation, physical metadata/event on the module-returned world, then the real withdrawal/beacon suffix. Its Commitment provides the exact executed stages and journal, not new caller-supplied stage facts. Zero returned keys commit the module world plus metadata/event with no suffix calls. Any root failure restores the whole initial world while retaining diagnostic attempts.

The supplied selected allocation and CALL-buffer cursor remain explicit phase inputs. Earlier allocation/admission/config/credentials and cursor provenance, memory-copy/gas semantics, immutable/deployment correspondence, complete event/revert ABI and the EVM journal remain outside. The ordinary-no-code rule excludes precompile dispatch. No global conservation is asserted across arbitrary module behavior, and the separate accepted locator-bound metadata/withdrawal theorem keeps its own scope. Registration does not broaden any of these source boundaries.

No actionable integration or scope finding remains. Root owns the archive-only final commit, PR and merge. Review stopped after writing this external receipt; no candidate mutation or archive-copy loop was performed.
