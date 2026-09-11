# Independent ACCOUNT physical-pause integration review

Verdict: **CLEAN for exact `d9546e3a8c921f7bbd197e393155dfddbc14fdd9`** in `/tmp/lido-account-physical-pause-integrated`. No unresolved correctness, integration, evidence-identity or claim-scope finding. This verdict covers the added physical-pause consumer and its aggregate integration, within the inherited boundaries below; it is not whole ACCOUNT closure.

The source author and root integration writer were stopped during this review. HEAD and clean status were checked. Source contribution is `62669fad69b4bae620458eff7130b2d5e0017720`; final union is `ee6e49ecd77017fcbe796e579d5e13e2dad3a16b`, incorporating main `66c699faabb5d9a248108f6cf6f7032c1e4da58b`. Build union `3b72bb5096634caca8f1473902a18ed8e927fd40` and final union have the identical tree `57ff5d016f3e242ff1d8019e208223fe22b37e0d`. The final integration changes only the three intended registration/import/query files and adds nine evidence files.

## Independence and review method

I authored none of this ACCOUNT source contribution or its integration. I did author an earlier, separate DEPOSIT module-call contribution, frozen at `80f391eedea92824327edefffe3f75635e1d271e`; this report does not independently approve that contribution or any other code I authored. Existing aggregate content is checked for preservation and wiring, not newly certified by this review.

I read all three new Lean files completely: `ReportFeePhysicalPause.lean` (198 lines), `PAccount1PhysicalPause.lean` (23), and `AccountPhysicalPause.lean` (92). I read the complete retained independent source/Solidity report `independent-source-review-6266.md`, the relevant prior 324 source and integration reviews, the entire consumed ReportFeeTreasuryCall/TreasuryCall public and implementation bodies, and ReportFeeDistribution. I followed the relevant ReportFeeMint, StETHMintShares and FeeDistribution execution, effect and chain definitions/proofs. I also read the source/integration READMEs, build and validation scripts, receipts, identity records, compiler fixture sources/metadata, passing test log, and the aggregate evidence.

All additional verification was read-only. I reconstructed identity checks directly rather than running dossier-writing validators. I did not rebuild Lean modules, recompile Solidity, rerun Forge, generate new axiom probes, or mutate candidate files, caches, pinned sources or site content. The normal build, scoped/global axiom checks and Solidity test results below are explicitly reused evidence, checked against their exact inputs and retained artifacts.

## Actual public composition

`execute` obligatorily calls the entire prior 324 `ReportFeeTreasuryCall.execute e x (project before)`. The projection replaces only the legacy StETH `activeFlag` metadata with nonzero interpretation of the physical pause word. Router, physical storage, abstract shares, self address and supplied accounting identity remain unchanged. Consistency is established by construction on the input actually executed; it is not an assumed equality supplied by the caller.

The public success theorem has only the whole new runner's successful execution equation as its premise. Its conclusion retains `OldEffect` in conjunction with `PhysicalEffect`. I compared `OldEffect` with the prior 324 public theorem: it keeps the complete actual report/mint equation, ReportFeeDistribution.Success, pointwise Ledger, and the zero-attempt or positive actual distribution/ReadEffects/event-concatenation alternatives. The prior entry is explicitly `project before` throughout. No old arbitrary-flag public theorem or domain is edited.

| Required obligation | Checked executed derivation |
| --- | --- |
| Physical bool interpretation | `active` tests the entire StorageWord value for nonzero. `projection` proves consistency of the state actually passed into the old executor. |
| Mint preservation and admission | `mint_frame` inverts actual `mintShares` success, derives its executed active guard, and proves the actual total-share write leaves the pause word unchanged. |
| Slot separation | `total_slot_distinct` computes inequality of the actual two pinned literal slots with `decide +kernel`; no caller nonalias premise is added. |
| Actual payment intermediates | `chain_physical` inducts over the executed PaymentChain. Each enhanced Payments constructor retains the actual transfer equation and TransferEffect, actual intermediate state, entry pause word and derived physical admission. |
| Exact treasury input | `module_world_invariant` applies to every actual successful module result. The retained ReadEffects contains the corresponding actual module equality, so the invariant applies to the exact middle state supplied to TreasuryCall. The readonly environment receives this ACCOUNT World and has no mutable post-World return channel. |
| Final successful state | PhysicalEffect retains the actual mint equation, minted and final consistency, unchanged physical pause word, actual complete payment chain and ordered events. Positive mint derives physical activity; zero mint remains allowed. |
| Whole root failure | `failure_restores` returns the original complete incoming World, including contradictory legacy flag metadata, while preserving diagnostic payments and attempts. It does not merely return the projected World. |

Internal frame and consistency helper hypotheses are discharged by projection, actual mint/transfer execution and chain induction. No new activeFlag/storage equality, active input, positive-fee, frame, nonalias, successful-stage, funding or external-read-success assumption appears in the public consumer theorem.

Zero fee may normalize nonphysical flag metadata while skipping mint, payments and treasury calls. The source, public comment, README and regression agree on this behavior. They do not claim successful output equality with the old unprojected World. Likewise the pure entry projection is a state interpretation, not an asserted extra early EVM SLOAD instruction. The stopped physical word is consequently allowed for zero-fee success.

## Source/compiler fidelity and evidence reuse

I read the full independent 6266 source/Solidity review and verified the identities needed to reuse its complete relevant source and compiler-path examination. Core remains `17005714f151e5502c559932319a3f2f74ac2436`. All six recorded complete core bodies and their pin match. I independently recomputed both literal Keccaks: `lido.Pausable.activeFlag` and the total-shares position. The pause literal is `0x644132c4ddd5bb6f0655d5fe2870dcec7870e6be4758890f366b83441f9fdece`; total shares is `0x6038150aecaa250d524370a0fdcdec13f2690e0723eaf277f41d7cae26b359e6`.

The prior full source review establishes that the inherited Aragon getter and actual Lido assembly use the full SLOAD result with ISZERO/ISZERO admission, rather than a low-byte mask or equality to one. Raw2 and high-bit words are therefore active. It also checks actual authentication-before-pause mint order, transfer recipient guards before pause, sequential share updates and events. I verified exact full-Lido assembly/deployment identity and all 37 metadata input Keccaks against the accepted provider, so this reuse does not substitute a small bool or mint implementation for the original Lido artifact.

All 111 inherited quote-provider receipt hashes match exact provider commit `ee24f9dc158ed25cec118a8ab8cd3a4fc59942f1` and current files. Fresh fixture snapshots for DistributionHarness, PhysicalPauseTest and Locator match source metadata Keccaks, artifact identities and the retained caller assembly. The distribution wrapper change from the prior fixture is exactly `mintSetup` to actual `mintShares`; the relevant Accounting distribution body is unchanged. The actual full Lido artifact, not an overridden pause/mint/transfer/rate model, is deployed by the fixture.

Compiler profiles remain explicit: original Lido solc0.4.24+e67f0147, fresh fixture solc0.8.9+e5eed63a, optimizer200 and Byzantium. No production-profile bytecode equivalence follows. I did not repeat the complete assembly review performed by the independent source reviewer; its complete report and the exact artifact/source identities are the stated reuse basis.

The author-run Solidity log is hash-verified and records 13 passing cases, including 1024 arbitrary-word fuzz runs. I inspected those tests. They cover actual full-Lido physical bool/mint/transfer behavior, guard priority, module balances observed by the treasury locator, late zero-recipient rollback, forbidden SSTORE under STATICCALL and zero-mint skip. These fixture cases do not execute the entire deployed Accounting oracle-report entry. The large forbidden-static gas number is not a gas result. No fresh Forge run is claimed.

## Integration and normal proof evidence

Independent identity checks passed:

- All 40 source-contribution paths remain byte-identical to exact 6266 Git blobs. All 39 source receipt hashes and all 8 integration receipt hashes match current files and their relevant commits.
- All 40 recorded source identities, 11 dependency pins and six pinned core bodies match. Both recorded prerequisite setup closures select matching actual current local sources and cached oleans, including cross-worktree providers.
- The manifest and toolchain are unchanged. The lakefile contains exactly the added `ReportFeePhysicalPause` root in the existing AccountAddressChecks provider; its integrated configuration hash and the other two configuration hashes match the receipt.
- The only previously existing main files modified are lakefile, AllGuarantees and Trust. AllGuarantees imports the new public consumer; Trust imports the new test module and adds exactly seven intended queries. All other roots and prior imports/queries remain present.
- Three actual integrated normal oleans match the integration identity record. Their setups/traces are ordinary, nonsynthetic builds of the correct source modules. Public imports select the actual current flat olean, AllGuarantees selects the current public olean, and Trust selects the current test olean.
- The complete retained AllGuarantees/Trust log finishes successfully at 1769 jobs. It records active builds of the flat source, public module, tests and both aggregators. The source-side manual olean hashes differ from the registered integration artifacts; I do not conflate the two build modes or claim identical trace bytes.
- The build-union/final-union tree equality supports reuse after the later main merge: no tracked source, dependency, configuration or wiring input changed between those unions. The three current registered olean identities also match the integrated record.
- All nine retained ordinary scoped axiom sets match the source dossier and contain only propext, Classical.choice and Quot.sound (with smaller sets for some helpers and none for literal-slot inequality). These include public success, rollback and both public test instances. The retained fresh global check reports 29 existing disclosed axioms: 23 test/mutant native-decision exceptions, three production exceptions and foundations. The entire aggregate is not foundation-only. I verified and reused these records rather than claiming another fresh axiom computation.

Formal regression credit is 16 kernel computations: 15 in the test file and the source literal-slot inequality. There is one nonempty public success instance and one late public rollback instance. The positive case deliberately contradicts physical word and incoming metadata and requires the treasury interpreter to observe the projected physical state and actual module payments. Zero-fee normalization, raw0/2/highbit, modulo-word construction, guard priority and forbidden readonly state change are exercised. These are actual public-composition instances, not merely independent helper tests.

The unused test pattern-binding warnings and existing prerequisite warnings remain disclosed. Failed development logs with errors and temporary sorryAx output are preserved as failed history and receive no passing proof credit. The exact current normal builds and scoped results support the candidate.

`git diff --check ee6e49ecd77017fcbe796e579d5e13e2dad3a16b HEAD` passes. The unqualified main-to-candidate check exits2 only for the two previously disclosed raw compiler EOF blank lines, DistributionHarness.asm:1609 and Lido.asm:16951. Those snapshots are unchanged exact compiler/provider outputs; this is not reported as blanket whitespace success.

## Scope and disposition

The increment removes independent legacy activeFlag choice for this executed physical interpretation, retains the complete prior 324 effect on the explicit projected entry, and derives the physical invariant through mint, real payments and the treasury-observed module state. Abstract share mapping, deployed identities and separation of modeled router/StETH components, supplied locatorAccounting authorization context, the complete report prefix and reward/rebase suffix, full ABI/memory/gas and universal instruction/bytecode refinement remain inherited boundaries. The proof of distinct literal total/pause slots is not a universal Keccak share-mapping noncollision proof.

No blocking finding remains. **CLEAN for exact d954 integration**, within this scope and with the precise raw-output whitespace exceptions above. Only this external review report was written. Root may archive it and perform the final archive-only delta check. Reviewer STOP; no candidate changes or publication performed.
