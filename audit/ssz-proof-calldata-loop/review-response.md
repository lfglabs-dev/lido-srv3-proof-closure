# Integration response to the independent SSZ review

The exact PR280 candidate a9f097c81db661dbd413dae298c7162ede248572
and stacked PR282 candidate c3cd5450af78a73daed221082b6d368fa9d18e90
were reviewed by Grok 4.6 mission a5b20c8c-062e-4d1e-9324-196da0a86c8b.
Observed CLI: 0.1.211, revision 2f2cd6d5c. The complete original report,
reviewer's integration supplement and final event 4210 are preserved here.

The original verdict remains BLOCKED. The reviewer separately concluded
that no implementation, proof or evidence defect inside either README/receipt
domain requires correction before bounded integration. This supports these
incremental proof lots; it does not close SSZ-1 or any complete guarantee.
No review verdict is relabeled CLEAN. The documentary successor changes no
candidate source, test, receipt, configuration, dependency pin or retained log.
Final documentary review is a separate integration gate.

## Findings and corrected facts

F1 retains complete entry, production/deployed binding and campaign work.
F2 retains surrounding opcode, memory and control gas: 2684*n+1 covers only
CALL/precompile charges in the modeled interpreter. F3 retains opaque SHA
trust. F4 retains supplied ABI/layout/count/depth/memory/FFI32 domains. F5
retains World/account frame and rollback. F6 retains revert ABI. F7 discloses
ordinary Lean axioms. None of these boundaries is discharged by this response.
The typed bridge connects the final verifier using the same opaque FFI;
it does not establish independent SHA cryptography or execute the raw entry.

The reviewer's supplement corrects two factual errors in the original report:
280's three new Lean files are absent at validation parent 28a11871; they were
validated as worktree files, committed at b27f19da, and retained byte-for-byte
in log-only successor a9f097c8 and stacked c3cd5450. Before/after validation
hashes bind those committed files. F8/F9 are validation-parent labeling notes,
not evidence of mismatched sources. Eight OPEN denotes DEPOSIT1, TOPUP1,
TOPUP2, ACCOUNT1, ADDRESS1, CONSOL1, CONSOLETH1 and SSZ1, not eight SSZ bugs.
Every substantive SSZ residual remains open regardless of that count.

No returndata-size guard exists in the Solidity source. The review supplement
explicitly states that this is not a requested source patch. FFI32 remains
an explicit model-trust/domain condition.

## Access and validation limits

The initial 54-file transport archive omitted the complete GasConstants body.
It was already in both validated package-source closures at SHA256
906cda79711e73ca637184256f6b53f5f444918ced2952ead4296797c2503fa8.
The separate supplement supplied all 47 lines, and the reviewer read and
verified them against both manifests. That body and transport metadata are
retained here. The original archive was not rewritten. Source access is
resolved; this does not prove surrounding opcode gas.

The reviewer read complete primary modules, relevant dependent definitions,
tests and harnesses; checked candidate lineage, receipt/evidence/source hashes,
and reconstructed 1195/1207 comparison counts. It did not independently rehash
all 1113/1115 package-source bodies, run the complete checker, rebuild Lean,
or rerun Forge. Those executions remain root's source-bound receipts reused
by identity. Root reran each lot's checker before this documentary commit;
the exact result is retained in review-input-check.json. This is file/pin
comparison, not a fresh proof or EVM execution. PR282 adds no Forge run.
Historical ACP failure and predecessor review-loop failures receive no credit.

Only the bounded results described in the original READMEs are eligible for
integration after final documentary review. All eight complete guarantees
remain OPEN, including source-to-compiled execution, full World/rollback,
complete entry and authenticated deployed/consensus provenance where relevant.
