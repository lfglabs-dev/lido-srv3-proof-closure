# Lido SRv3 Proof Closure

Evidence package for the Lido SRv3 accounting audit. The repository holds a
Lean model of the SRv3 economic surface, the eleven public guarantees claimed
over it, the source and pin evidence those guarantees rest on, and the commands
that reproduce all of it locally.

The registry is the authority. Lean theorem statements and their proofs are what
actually close a guarantee; the metadata in `audit/` describes and constrains
them but does not itself prove anything.

- Canonical registry: `audit/guarantees.yaml`
- Lean facade: `LidoSRv3/Audit/AllGuarantees.lean`
- Source mapping: `audit/source-map.yaml`
- Assumptions and exclusions: `audit/assumptions.yaml`, `audit/exclusions.yaml`
- Campaign recovery and branch policy: `audit/CAMPAIGN-RECOVERY.md`

`main` is the only active integration branch. The former
`campaign/lido-minimal-11` line is preserved as merged history and an archival
reference; new branches and pull requests must target `main`.

## The eleven guarantees

These eleven IDs are the entire public claim surface. The facade in
`LidoSRv3/Audit/AllGuarantees.lean` carries a machine-checked regression that
fixes both the count and this exact order, so the set cannot drift silently.

| # | ID | Abstract Lean | Faithful Verity |
| --- | --- | --- | --- |
| 1 | `P-ALLOC-1` | CHECKED | PARTIAL |
| 2 | `P-ALLOC-2` | CHECKED | PARTIAL — needs proof-backed mutable memory arrays |
| 3 | `P-DEPOSIT-1` | CHECKED | PARTIAL — linked calls not yet faithfully executed |
| 4 | `P-TOPUP-1` | CHECKED under `A-TOPUP-NOWRAP` | PARTIAL |
| 5 | `P-ACCOUNT-1` | CHECKED | PARTIAL — no distinct stateful execution yet |
| 6 | `P-RESERVE-1` | CHECKED | CHECKED |
| 7 | `P-ETH-1` | OPEN | OPEN |
| 8 | `P-ADDRESS-1` | OPEN | PARTIAL subordinate evidence |
| 9 | `P-TOPUP-2` | CHECKED | PARTIAL — aggregate `CallProgram` evidence only |
| 10 | `P-CONSOLIDATION-1` | OPEN | PARTIAL subordinate evidence |
| 11 | `P-SSZ-1` | CHECKED structural model | PARTIAL |

`P-SSZ-1.deposit-data-root` is a subordinate child claim of row 11, not a
twelfth public guarantee: it narrows part of P-SSZ-1's scope and is carried by
`LidoSRv3.Audit.Source.DepositDataRootCorrespondence.source_pinned_config_discharges_deposit_data_root`.
`P-SSZ-1.gindex-concat` is likewise subordinate evidence for the pure mapped
`GIndex.concat` helper. It does not close the parent, `SSZ.verifyProof`, its
wrappers, or SHA-256 correctness.
The public claim surface stays at the eleven numbered IDs above, matching the
checked `AllGuarantees.all.length = 11` facade.

## Assurance contract

The project has exactly two general proof objectives per public guarantee:

1. a clear abstract Lean property with a checked theorem; and
2. a behaviorally faithful Verity model with a checked refinement theorem.

Faithfulness means the guarantee-relevant inputs, guards, state reads/writes,
indices, arithmetic, external-call target/kind/value/calldata/order/multiplicity,
success/revert behavior, and rollback are represented whenever they are
observable for that guarantee. It does **not** require modeling unrelated
contract behavior.

When the Verity proof cannot be completed, the registry must classify the
primary gap as exactly one of:

- `VERITY_FEATURE_REQUIRED`, with the missing upstream feature and a minimal
  consumer test;
- `PROPERTY_FALSE`, with a reproducible counterexample;
- `ASSUMPTION_REQUIRED`, linked to a justified risk record; or
- `IMPLEMENTATION_PENDING`, when the required Verity feature already exists.

General Yul refinement, EVM semantics, runtime-bytecode identity, and deployment
provenance are outside this project's assurance objective. They are not hidden
open lanes and do not block a guarantee. `A-SOLC-TRUSTED` records the explicit
compiler boundary when an artifact is produced.

SSZ has one narrow exception: because its implementation imports a substantial
Yul fragment, the registry carries a targeted, currently open check that this
imported fragment is the fragment used by the deployed contract. This identity
check does not reopen a general source-to-EVM chain. SHA-256 functional
correctness remains separately explicit under `A-SHA256-FFI`.

Read the exact per-guarantee status, fidelity coverage/missing dimensions,
classification, assumptions, and next gate from `audit/guarantees.yaml` rather
than from prose summaries, including this one.
Generated views of the same data live in `audit/STATUS.md`, `audit/ROADMAP.md`,
and `audit/REPRODUCE.md`; regenerate them with `make audit-generate`.

## Reproducing

```bash
make audit-check   # validate the registry, pins, source map, and generated views
make test          # metadata mutants, receipt, guards, executable regressions
make prove         # Lean theorem checking; writes a legacy SRV3-P1--P15 compatibility report
```

`make audit-check` is fail-closed: it rejects a registry that has drifted from
the eleven IDs, that loses a pin, or whose generated views are stale.
`make test` additionally runs the metadata validator against deliberate mutants
and re-derives the validation receipt, so a silent edit to the evidence tree
fails the build.

`proofs/logs/proof-report.json` is a build receipt for the superseded
SRV3-P1--P15 lane only (`target_scope: legacy-srv3-p1-p15-superseded`). It is
not evidence for the eleven current guarantees; their authoritative theorem
names, statuses, and reproduction commands are the canonical registry above.

To check a single guarantee, use its reproduction command from
`audit/guarantees.yaml`, for example:

```bash
lake build LidoSRv3.Audit.Guarantees.PAlloc2
```

The report PDF is built separately with `make report` and is written to
`dist/lido-srv3-formal-methods-report.pdf`.

## Layout

- `LidoSRv3/Audit/`: the guarantee facade, model, allocation strategy, and
  proofs. `LidoSRv3/Audit/AllGuarantees.lean` is the single entry point.
- `LidoSRv3/Tests/`: executable falsifier vectors and structural regressions.
  Deliberately outside the public facade's import closure, so test code cannot
  contribute to a guarantee.
- `LidoSRv3/Legacy/`: the earlier SRv3 economic state machine, retained as model
  context.
- `audit/`: canonical registry, source map, assumptions, exclusions, pins, and
  the generated views.
- `verity/targets/`: source map and trust boundary consumed by the Lean model,
  plus the target manifest.
- `proofs/`: lockfile, source anchors, and generated proof logs.
- `fixtures/solidity-reference/`: Lido reference files copied from the pinned PR
  source as source-facing fixtures. Nothing in this repository executes them.
- `scripts/`: the metadata validator, receipt check, and provenance guards.
- `content/`, `report.tex`, `style/`, `assets/`, `dist/`: the report and its
  build inputs.
- `archive/legacy-p1-p15/`: the superseded legacy dossiers and target files from
  the earlier fifteen-property lane. Historical record only. Nothing there is
  validated by `make audit-check` or `make test`, and nothing there backs a
  current guarantee.
