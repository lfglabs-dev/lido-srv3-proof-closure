# Independent wrapped ADDRESS integration review

Verdict: **CLEAN** for exact commit `bebc810ee7868357065d4d06d0304f45428e021b`, tree `ef355e8b33a8172121bf6b33a54da199707ce313`, clean frozen checkout `/tmp/lido-address-wrapped-integrated`. Root writer was stopped. No project mutation, rebuild, Forge/FFI execution, publication or merge was performed by this reviewer.

## Union and exact source preservation

Union `751500a2f558a63bd8905bd4b8db79ddad71ba5b` combines reviewed source `19c52ff56f40e374b568eba38658c15067f76abe` with accepted DEPOSIT326 main `b77355c3245910348f8eb46f46ba47d88e225612`. I compared complete recursive Git trees, including modes and object identities: every accepted-main object is unchanged in the union; the union adds exactly the source candidate's 47 new objects, each identical to 19c5. There is no further union-only path. This preserves ADDRESS325's corrected canonical bridge and documentation attribution, ACCOUNT324, and DEPOSIT326 without reconstructing or weakening their earlier changes.

Relative to the union, the final integration changes exactly two existing files and adds seven archives. AllGuarantees adds the wrapped public import. Trust adds the wrapped regression import and four scoped theorem queries. No executor, theorem body, dependency pin, lake provider, public domain, old import or old query is changed. The existing source/guarantee and test providers discover the new modules through their established globs. This is not a second provider or shadow implementation.

The complete independent source/Solidity review of 19c5 is reused after source identity, and its archive `integration/independent-source-review-19c5.md` is byte-for-byte identical to my external report. I inspected the complete integration README, receipt, identities and scoped-axiom packet, the complete code delta, actual registered setup/provider metadata, and validation logs. All 46 source receipt hashes and all six integration receipt hashes independently pass. `identities.json` equals the receipt's identity object.

## Effective public composition and boundaries

The AllGuarantees consumer still derives its relation from actual whole-run success: WSTETH transferFrom with the original wrapped amount, then WSTETH unwrap on the first returned world, admission of the actual decoded stETH word, STETH quote with that same word on the second returned world, and the existing physical enqueue/events with the same values/state. The static quote has no returned mutable world. There is no second STETH transferFrom or use of the old standalone unwrap adapter. Canonical false transfer bool and trailing bytes remain accepted; short/noncanonical replies fail; shares truncate modulo 2^128 while admitted amount fit is derived. Entry block TIMESTAMP is captured independently of arbitrary returned model metadata. Late report reading, checked additions, high-byte preservation and wrapping owner-set insertion remain the exact previously reviewed source expressions. Root failure restores the full entry world; chronological attempts remain observations.

Neither integration nor the public theorem introduces funding, stage-success, supplied reply, frame, nonalias, shares-fit or nonzero wrapped-input premises. The accepted-main consumers retain their own statements; merely importing them together does not claim a new DEPOSIT-to-ADDRESS transaction composition.

The README accurately limits this claim to the typed one-item queue caller with arbitrary external token implementations and the existing storage lens. Real WstETH burn, balances/allowances, token-conservation and deployed immutable authenticity, initial pause/permit/batch/dispatcher, raw memory/gas/returndata allocation, complete error/LOG byte encoding and arbitrary EVM static execution remain outside. This is compatible with the source review, including actual WstETH's separate nonzero guard and the caller's deliberately broader arbitrary-callee domain.

## Normal environment and validation evidence

I independently rechecked the 1,246 retained imported/new source hashes and eleven package Git heads. The actual registered regression setup contains 1,245 imports plus the test itself; each selected import source matches the manifest, and each selected local olean equals the normal local artifact. This verifies actual provider consumption rather than only a list of unrelated source names.

All three recorded normal olean SHA256 values match current bytes:

- Source AddressWrappedRequestCalls: `21484d43d7389e40bc25530c0e170de09430f8c7504d5793690af57e6a887e7e`.
- Public PAddress1WrappedRequestCalls: `553aed10e7d0abe8e8dbc3e0e0f335e5a04be81c72be253e0d19a551af0b0a31`.
- Tests AddressWrappedRequestCalls: `bb0db7046abc82d344e36af0045c82a013a7d6a76ae08a1f18cc4219bf8c9567`.

AllGuarantees and Trust's actual setup import tables contain the wrapped and accepted DEPOSIT326 consumers/regressions. Their setup options and plugins, and those of all three new modules, are empty; traces are nonsynthetic with no skipKernelTC setting. The packet does not require an unsupported cross-worktree artifact identity claim.

The combined normal build log ends successfully at 1,725 jobs. I parsed every Trust query report and compared it with current source declarations, including multiline `#print axioms` declarations: exactly 496 distinct theorem names match. The observed union equals precisely the current 26 disclosed nonfoundational names plus propext/Classical.choice/Quot.sound, totaling 29. The fresh retained global gate reports dependency recomputation and native-claim re-evaluation. This is explicitly not a foundations-only global environment.

All five retained freshly recomputed scoped sets equal the independently verified source sets and use only foundations; unwrap_success uses propext and Quot.sound. The four new Trust queries print the expected ordinary source/public results, and the test import brings the 18 kernel examples and public rollback instance into normal integration. The prior source review's direct ordinary compiles and fresh scoped checks are reused by the verified source/provider identities. No redundant build or global native rerun was needed here. My initial log-comparison expression counted only single-line source declarations; correcting it to include existing multiline declarations resolves the comparison exactly, without any source or log change.

Nine original Solidity tests including 1,024 fuzz cases, four native diagnostics, four queue preimages/three selectors, sixteen original dependencies and seventeen actual compiler inputs retain their reviewed source-packet bytes. They are inherited validations, not new integration executions. The full compiler assembly remains the actual reviewed legacy solc0.8.9 optimizer200 London fixture output, explicitly distinguished from production Istanbul. Native diagnostics remain executable checks rather than positive kernel theorems.

## Formatting, publication scope and final state

The complete integration-only delta passes `git diff --check`. The inherited source packet's sole new raw assembly blank EOF remains intentionally preserved and disclosed; older raw-output exceptions are also retained unchanged. No blanket whole-history diff-check PASS is claimed.

The integration includes no site or deployment change. The independently frozen hourly site at DEPOSIT326 intentionally excludes this increment; that does not alter this exact proof-integration verdict.

Final checkout is clean at bebc810ee7868357065d4d06d0304f45428e021b. The complete accepted-main tree, source bodies, scoped claims, active consumers and receipt identities are preserved as stated. **Reviewer STOP.**
