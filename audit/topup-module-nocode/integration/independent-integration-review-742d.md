# Independent TOPUP no-code integration review

**CLEAN — final frozen commit `742da800c59aa91a00189b2acc5613e428880b9d`.** Review began at `7e591bb824652d055ebdb3a80429bec5b33425c5`; one documentation finding was corrected in the final successor. No unresolved source, integration or receipt findings.

Checkout `/tmp/lido-topup-nocode-integrated`; root integration writer stopped before each frozen review. Date 2026-09-10. Reviewer `/root/topup_root_call_batch` authored neither the no-code candidate nor its integration. Reviewer authored previously accepted #315 substrate; this is disclosed in the complete source review retained verbatim at `audit/topup-module-nocode/integration/independent-source-review-4fd8.md`.

## Exact union and preservation

Verified both reviewed source `4fd86cd2c53b6e1c06a05a3488d9a46bc65ad4ac` and accepted main `808db8a02694c1b0268f0480513466b03761491f` are ancestors of the integration. Merge union is `09a09ad875f8e1519586a04932efd4dbacdf713f`.

Compared the entire accepted-main Git tree, not just a selected diff: every existing main path is preserved byte-for-byte except the intended three no-code source/test modifications and the two additive public wiring files. All accepted ACCOUNT #302 sources, guarantees, tests, history, Lake provider wiring, manifests and pins are preserved. The new fourth Lean path is `PTopup2ModuleFailure.lean`. All four candidate Lean bodies remain exactly those independently reviewed and normally kernel-checked at 4fd8.

The integration adds only an import of `PTopup2ModuleFailure` to AllGuarantees, the same import to Trust and active axiom queries for both new public failure theorems. Existing successful public statements and execution definitions receive no further integration changes. No shadow module or extra ACCOUNT provider is introduced.

## Actual providers and reuse

Independently checked all 1,285 recorded source-body SHA256 identities against this checkout and all 11 actual package HEAD pins against the manifest and source packet. Checked all 17 source-packet hashes and all five integration receipt hashes. The copied independent 4fd8 review is byte-for-byte identical to the original external report.

Inspected actual integration setup import artifacts for TopupModuleCall, PTopup2ModuleFailure and TopupBatchRootCallsRegression: their transitive providers resolve to bodies matching the reviewed source identities. AllGuarantees and Trust setup imports resolve the new failure guarantee, consumed TopupModuleCall and actual-root batch to this integration's local build, not a stale parallel source provider. Setup options are empty. Normal build trace invocations target this checkout's AllGuarantees/Trust sources with Lean 4.31.0, no kernel bypass option.

TopupModuleCallMutants is a separately validated target at 4fd8 and is not present in the integration Trust import closure. Its exact source and dependency identities are unchanged; its earlier independent normal-kernel checks remain valid. No claim is made that the integration All/Trust build rebuilt that target.

## Receipt and checks

Reused the root's successful `lake build LidoSRv3.Audit.AllGuarantees LidoSRv3.Audit.Trust` receipt: 1,686 jobs. Its retained log shows the affected module, committed continuation, old batch consumers, actual-root batch, new public guarantee, batch regression, facade and Trust built successfully. The receipt also records a fresh normal `python3 scripts/check_trust_axioms.py` pass, which recomputes dependencies from the built environment and re-evaluates disclosed native claims.

Independently reconciled the retained full Trust reports against the unchanged checker and allowlist: exactly 29 global disclosed axioms, all active printed theorem names present, both new public consumers dependent only on foundations. The global 29 are three foundations plus the existing 23 test/mutant native-decision axioms and three production exceptions; this is not mislabeled globally foundations-only. The no-code packet's 26 separately recomputed theorem axiom sets remain foundations-only by unchanged source/dependency identity.

No redundant Lake build, full trust reevaluation, source kernel check or Solidity recompilation was run for this integration review. The independent 4fd8 checks already include 1,302 targeted build jobs, normal kernel checks on four files, full validator replay, 28 compiler source SHA/keccak checks, exact reproduction of all 5,165 optimized IR lines and the targeted Foundry PASS. Their exact source, package and packet identities were re-established here. Integration credits no new Solidity run.

`git diff --check` passed. Final HEAD is exactly 742da800 and the worktree is clean. The final successor changes only the integration README sentence and the corresponding SHA256 in its receipt; all source, dependencies and build/trust logs match reviewed 7e59.

## Corrected finding and scope

At 7e59, integration README incorrectly said existing Trust imports consume both changed regression modules. Actual Trust/setup imports consume TopupBatchRootCallsRegression but not TopupModuleCallMutants. Root corrected this to state explicitly that the module mutant target's separate normal-kernel validation at 4fd8 is reused through exact identities. Reviewed the entire correction and updated hash; finding resolved without changing code or adding unnecessary builds.

The final dossier retains the source-review limitations: ordinary EOA/undeployed target only, with precompile exclusion an inherited interpretation boundary rather than a formal codeSize classifier; typed covered phase rather than full gateway/router admission or compiled execution equivalence. The consumed zero-value transport accepts empty, its actual decoder rejects, retained root/module attempts describe the attempted calls, and the model restores the entry World without a successful-root-prefix premise. Positive-code successful execution domain and arbitrary external effects remain intact.

Foundry's injected non-contract diagnostic is not credited as byte-exact empty revert data; the independently reproduced compiler IR separately supports `revert(0,0)` at the empty-return decoder guard. No integration wording expands that claim.

CLEAN applies to exact 742da800 and these scopes. Root owns publication/merge and any later changed bytes. Reviewer made no candidate edits and is stopped after this report.
