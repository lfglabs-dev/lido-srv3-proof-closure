# Bounded repair following audit e776039c

Audit e776039c reported BLOCKED at `cf29cf646a796b91a200f43e010d09df91ee8c5f`.
The repair remains on PR #918's existing private integration branch. It is an
implementation proposal for a fresh independent review, not an audit verdict.

| Confirmed defect | Repair | Validation needed at the new head |
| --- | --- | --- |
| TOPUP dropped-assert vector never exercises imbalance | A Lido callback overpays one wei; honest source must panic and roll back, while the dropped-assert copy succeeds and strands one wei | TOPUP differential suite |
| TOPUP type-1 vector tests only the model | Register a real type-1 module and call pinned `topUp`; check the exact WC rejection selector | TOPUP differential suite |
| RESERVE post-report wrap never reads pinned storage | Read the pin's actual high-half value and compare modulo 2^128 against the model's exact sum | RESERVE differential suite |
| RESERVE next-report write is unobserved | Read the actual adjusted accumulator on commit and after failing receiver rollback | RESERVE differential suite |
| Dirty transitive and vendor inputs evade selected-path guards | Check all lido-core contracts at the pin and both vendor trees at candidate HEAD, including staged and ignored extra inputs | Source-guard negative regressions and differential suites |
| Relocated module names remain in current reproductions | Retarget registered SSZ and affected documented Lake commands; guard all registered module references | Registry target guard, negative control, targeted/full remote compilation |

Historical dossier validators bind historical import bodies, artifacts and
receipts. They remain preserved; their READMEs now distinguish those frozen
records from explicit current-candidate compilation commands. Their PASS labels
must not be credited to the integrated candidate or regenerated as current proof.

## Exact-head reproduction

Take the full candidate SHA from the current PR handoff, fetch that commit into
a private clean checkout, and initialize the pinned lido-core submodule. Then:

```sh
bash scripts/reproduce_candidate.sh FULL_CANDIDATE_SHA_FROM_HANDOFF
```

The argument is mandatory; the script rejects a different HEAD or dirty checkout
before submitting `lake test -- repository` to registered `dgx-spark`. That runner
uses the pinned toolchain/dependencies and compiler artifacts, runs `make prove`,
`make test` (including all differential suites), and all library targets. Inspect
any existing durable receipt before resubmission. Exit 75 denotes a pending job;
only a terminal receipt for the same full SHA can report execution success.

The separate local checks requiring no Lean/Foundry build are:

```sh
python3 scripts/test_differential_sources.py
python3 scripts/check_reproduction_targets.py
python3 scripts/test_reproduction_targets.py
python3 scripts/audit_metadata.py check
```

## Evidence classification

The [70-vector PR comment](https://github.com/lfglabs-dev/lido-srv3-proof-closure/pull/918#issuecomment-5665452153)
is an **author-reported** harness receipt for cf29cf64. It is neither independent
audit closure nor validation of a later head. Likewise author-accessible remote
job records do not establish independent review. Remote validation remains
unverified by the independent reviewer until that reviewer can access and inspect
the evidence or reproduce it. No author comment creates a CLEAN verdict.

The runtime code-size allegation is **unverified** here. No code-size limit was
raised, no deployment success was inferred from an author-reported test count,
and no contrary byte-size number is asserted. A reviewer needs the actual compiled
runtime bytes, compiler/settings identity and deployment result to resolve it.

New test execution and exact-head validation results belong in the PR handoff.
After the bounded repair, stop for a fresh independent reviewer. No merge or
certification is authorized by this report.
