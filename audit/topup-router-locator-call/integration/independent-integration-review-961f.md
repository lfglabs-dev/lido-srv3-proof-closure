# Independent TOPUP locator integration review

Verdict: **CLEAN for the bounded integration at `961f752c7393301afc434a01e4238c51431d4061`**. No unresolved finding. This accepts the additive locator-to-existing-TOPUP335 consumer and its normal integration, not whole TOPUP closure.

Exact checkout: `/tmp/lido-topup-router-locator-integrated`; tree `ac45dc6aabb7c95301368ba12bef1b892d3c6320`; sole parent `3c528f10f802036d10b5715f3c394ddf1322fe15`. HEAD and clean worktree were independently checked before and after inspection. No candidate, cache or Git mutation, compiler/Forge/native invocation or repeated Lean build was performed.

## Independence and source reuse

I authored none of the new locator source, public theorem, regressions or integration changes. My complete independent source/Solidity/IR review of `6c332904a894c51f1cc57e23c9ec8cdc969453a8` is retained byte-for-byte as `audit/topup-router-locator-call/integration/independent-source-review-6c33.md` (SHA256 `1bb422a614df27c343f87446afae5e25ddbb232e895729558129058c48638c03`). Its conclusions are reused only after exact identity checks. Some inherited DEPOSIT physical-admission bodies were authored by me; their independent correctness provenance remains the retained 39f4 source and 7305 integration reviews identified in that source report. This review does not reclassify my inspection of those inherited bodies as independent authorship review.

All 25 additions of source6c33, including the three Lean files and complete original dossier, are byte-identical in source6c33, union3c528 and final961f. The union adds exactly those 25 paths to accepted main337 `88dc7ae70ceffd463a29cc44175c58e82e2155a9`, preserving every existing main object and mode. Final961f adds exactly two wiring edits and nine integration artifacts. `lakefile.lean`, `lake-manifest.json` and `lean-toolchain` match source6c33 and main337. Both main-to-final and union-to-final diff checks pass.

## Consumed public result and wiring

I reread the complete final public module and exact wiring delta. AllGuarantees imports `PTopupRouterLocatorCall`; Trust imports its regression module and adds six active queries: both public consumers, `decode_fields`, `lookup_origin`, `run_success` and `failure_restores`. No old declaration or query is removed.

The success theorem takes successful execution of the complete new runner, rather than a successful locator-stage premise. It derives the actual gateway request, returned bytes, canonical 160-bit router, successful scalar allocation and exact next pointer. It uses that decoded router as the selected caller in the covered inner router path and passes that same next pointer into the credential getter. The returned World, suffix and ordered locator/credential/root/module observations belong to that execution. `TimingEffects` retains the complete prior335 conjunction, including intermediate physical effects, successful root/module execution, produced total and final history update on the corresponding World. The failure theorem restores the entry World. Integration changes neither these bodies nor their parameters or hypotheses.

The prior source review's correspondence remains applicable: length/configuration and temporal guards precede locator lookup; selector `ef6c064c` is issued without an EXT precheck; call failure bubbles before decoding; minimum-32 copy/allocation precedes signed-head and canonical-address checks; the decoded address and actual next pointer feed the following credentials call. The complete 2,519-line compiler IR and associated artifacts remain byte-identical and match the retained correspondence hashes. The prior source validator checks full335 conjunction identity, not merely a shortened summary.

No code-presence premise is introduced into the public theorem. Its positive code-size conclusion is derived within the explicitly ordinary-address low-level model; the scope excludes treating that ordinary no-code arm as a precompile model. No new role equality, stage success, frame, fit, funding or nonalias premise appears.

## Independent identity checks and validation reuse

Independently recomputed from current files and exact Git blobs:

- 24 original source-receipt hashes and all 8 integration artifact hashes match; the integration receipt is not counted as a self-hash. The three configuration identities also match.
- All 1,355 recorded source bodies match their SHA256 entries. All 11 package revisions agree with the exact manifest and selected package HEADs.
- The three current normal source/public/test artifacts match the integration record's source, olean, setup and trace hashes. Their options and plugins are empty; traces are nonsynthetic and contain no kernel-skip option.
- Actual regression, AllGuarantees and Trust setup imports select the new modules. Across those setups, 978 local-provider source/olean comparisons match the current checkout and normal outputs, including the new public and test bindings.
- The retained 27 scoped sets contain only `propext`, `Classical.choice` and `Quot.sound`. The source/IR/compiler evidence and original source report remain unchanged.

I read the full integration wrapper before assessing its receipt. It changes only `record('build-identities.json', ...)` to an external temporary output, because setup/trace paths differ between checkouts. Every other original validator record remains in comparison mode; the wrapper also checks the 24 source hashes and three configurations. The separate integration normal-artifact record agrees with actual current artifacts. This is an explicit path-dependent identity adjustment, not an unchecked replacement of the source validator's other comparisons.

The archived normal log reports 1,763 successful jobs and actively builds the new source (2.0s), public module (1.6s), regressions (5.9s), AllGuarantees (2.5s) and Trust (2.2s). It retains the harmless `unnecessarySimpa` suggestion at source line40. The six added Trust queries are present in that build output with ordinary foundations. The archived fresh global check retains the disclosed 29-axiom gate: 23 test/mutant native-decision axioms, three existing production exceptions and foundations. This global gate is not described as foundations-only; the 27 new scoped checks are.

Those build/global/scoped validations ran on build union `a95f5e2f2b2e5987b7324307ccbe5b60f466278f` with the current wiring. Independently confirmed: its delta to final union3c528 is only the accepted quote integration review and receipt. No source, dependency, configuration or wiring input changes. The current normal outputs also match their archived integration hashes. Reusing those validations is therefore justified; this report does not claim they were rerun after the documentary merge or by this reviewer.

Original source evidence remains precisely scoped: the 1,372-job source log replays source/public and builds tests; nineteen kernel computations plus public success/rollback, eight SHA diagnostics and eight selected Forge tests are preserved. The reused compiler correspondence binds 22 inputs; the fresh runtime fixture binds 23 inputs and three artifacts. No new compiler, Forge or FFI execution is claimed for this integration.

## Remaining boundary and final gate

The supplied immutable locator address and deployed locator implementation, role/pause, omitted outer gateway-to-router CALL/dispatch, prior router allocation and initial storage/context provenance remain explicit phase boundaries. Selecting `Context.sender` does not prove that outer call. Scalar cursor chaining is proved; full memory/copy/alias/gas and the separate module return-buffer provenance remain outside this increment. External hash/root semantics, complete LOG/error ABI and deployment/EVM refinement retain their existing limits. The actual gateway Solidity fixture's locator fallback and router recorder do not replace the independent physical-getter proof or establish a deployed locator body.

The integration README and receipt preserve these distinctions and do not strengthen the accepted source result. Exact961f is CLEAN for integration and documentary archiving. Writer/reviewer work is stopped pending the parent's separate archive-only gate.
