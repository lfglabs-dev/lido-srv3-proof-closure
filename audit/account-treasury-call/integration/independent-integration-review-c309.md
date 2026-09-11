# Independent ACCOUNT treasury integration review — CLEAN

Exact reviewed head: `c309d14408f627adb4943a12804e346426a49b65`.
Checkout: `/tmp/lido-account-treasury-integrated`.
Source: `a7ea281e72298cc09239ed8a5e94f92eae2d03ce`.
Accepted main: `10e2b693d00cbbeab65f60cd8964ced87297336a`.
Union: `0e9116c415e687dd9b322549bfdcbe88fa86500d`.
Reviewer: `/root/topup_memory_exact_review`, independently reviewing after the root writer stopped. I authored neither the source candidate nor this integration. All checkout operations were read-only; this external report is the only durable review write.

**Verdict: CLEAN for this exact integrated typed ACCOUNT treasury-call claim. No blocking finding.** The complete source/Solidity review of a7ea is reusable by verified unchanged source, actual dependency and evidence identity. Registration and public/trust imports now resolve to the correct integrated modules. No proof scope, execution semantics or accepted boundary was strengthened.

## Complete commit and union

Verified actual union parents are source a7ea and accepted main10e2, in that order. Every source-candidate addition, including four complete Lean source bodies and its complete original dossier, remains byte-identical to a7ea. Every inherited main tracked file remains unchanged except the three explicitly reviewed wiring files. The complete integration delta from union is three wiring files plus seven new integration archive files.

Reviewed `lakefile.lean`: the existing AccountAddressChecks provider retains its source directory and all existing roots, adding only TreasuryCall, ReportFeeTreasuryCall and Tests.Verity.ReportFeeTreasuryCallTest. No package dependency, provider semantics, options, source redirection or old root is replaced. AllGuarantees adds the public PAccount1TreasuryCall import. Trust adds the actual regression import and four intended queries: both public theorems, TreasuryCall.call_success and ReportFeeTreasuryCall.distribute_success.

The four new normal module setup files and the AllGuarantees/Trust setup files were inspected through independent path/hash checks. They resolve local artifacts to this integrated worktree, and local source bodies to the same reviewed source set. Reconstructed closure is exactly the recorded 37 source identities, without extra changed dependency bodies. All eleven manifest/package HEAD pins agree. The canonical AllGuarantees import resolves the public theorem, and canonical Trust includes the full regression consumer. No detached adapter or substitute implementation is wired in.

## Evidence identity and normal build receipts

Independently recomputed and matched all 28 original candidate hashes and all six integration packet hashes. The archived `independent-source-review-a7ea.md` is byte-identical to my external a7ea review. All four recorded normal olean SHA256 values match the actual integrated artifacts; their traces are normal/nonsynthetic and name the integrated checkout. Cross-worktree olean byte identity is neither needed nor asserted. The identities packet exactly equals the integration receipt's identities field.

The complete original a7ea proof/Solidity evidence is reused only after these identities: four independently kernel-reelaborated sources, 12 kernel regressions/public consumer checks, 18 independently recomputed foundations-only axiom closures, five complete pinned Solidity source bodies, 29 retained dependencies, 32 metadata compiler-input Keccaks, four artifact snapshots, complete relevant assembly review, consumed storage constants and selector checks, and nine author-run actual Solidity cases. The accepted prerequisite build and prior full-source conclusions were not relabeled as a fresh integration source proof.

The hash-verified integration AllGuarantees/Trust build records 1,716 successful jobs and contains all four intended new Trust query outputs. The retained fresh root global check records 29 existing exact disclosed axioms: 23 test/mutant native-decision exceptions, three production exceptions (Phase-3 capacity, consolidation flow, SSZ digest), and foundations; dependencies were recomputed and native claims re-evaluated. The separate fresh root normal-environment 18-scope packet is byte-identical to the source-reviewed axiom file and foundations-only. This is not a claim that the entire global Trust environment is foundations-only. No redundant build, probe or Forge run was needed in this review because all covered bodies and receipts were unchanged and valid.

`git diff --check union HEAD` passes. Relative to main10e2, the sole diagnostic is the previously reviewed `DistributionHarness.asm:1609: new blank line at EOF`. That raw compiler stdout preserves one extra terminal newline versus the artifact assembly string; its exact source-reviewed hash is unchanged. This explicit formatting exception is nonblocking and is not presented as unconditional whole-delta diff-check success.

## Actual public composition and unchanged boundaries

The same report/getter/checked-fee/mint execution supplies fee shares and the real minted ACCOUNT World. Actual sequential module transfers update that World's StETH component. The positive treasury branch then sends the single readonly treasury request to the explicit locator on precisely the post-module ACCOUNT World, with zero logical value and selector 0x61d027b3. Executed code-presence and canonical160-bit ABI guards precede the actual payment to the decoded address. Caller width and untruncated request-caller equality are derived from successful transfer execution, not supplied as new premises.

The old resolver is fixed to this call in a proof-level extensional projection. The executable does not invoke an extra call to prove its result. The same actual raw return, intermediate World and recipient feed the retained ACCOUNT322 Success and pointwise Ledger, exact ordered payments/events and minted-share conservation. Both zero skips, accepted/rejected diagnostic attempts, actual failed-read bytes and entire incoming-World rollback remain intact. Duplicate/self-recipient semantics remain unchanged.

The integration README preserves the source review's limits: supplied immutable locator and code metadata are context rather than deployment proofs; the readonly external remains arbitrary; ACCOUNT uses its existing separate router/StETH components and abstract share map; earlier locatorAccounting authorization is distinct; raw ABI byte-view guards do not establish memory allocator/copy/pointer/aliasing or full compiled-report execution. Omitted callbacks/rebase/report prefixes and accepted compiler/declared Verity/cryptographic/gas/consensus boundaries remain outside. No general Ethereum proof, whole-memory simulation or production bytecode-profile equivalence is introduced.

The reused Solidity evidence is the exact Accounting distribution fragment and inherited StETH with explicit setup/mint/rate overrides, solc0.8.9 plus StETH0.4.24, optimizer200, Byzantium fixture profile. There are zero fresh root/integration Solidity tests; all nine source-run tests retain their reviewed scope, including no-code rejection/rollback rather than intercepted exact revert-byte claims. No website/publication changes are included.

Final HEAD is exactly c309d14408f627adb4943a12804e346426a49b65 and the checkout is clean. This exact integration is clear for the root's authorized next step. Review complete; stopped without editing the checkout or publishing externally.
