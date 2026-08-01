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

## The eleven guarantees

These eleven IDs are the entire public claim surface. The facade in
`LidoSRv3/Audit/AllGuarantees.lean` carries a machine-checked regression that
fixes both the count and this exact order, so the set cannot drift silently.

| # | ID | Named theorem or evidence |
| --- | --- | --- |
| 1 | `P-ALLOC-1` | `LidoSRv3.Audit.Guarantees.PAlloc1.active_capacity_bounded` |
| 2 | `P-ALLOC-2` | `LidoSRv3.Audit.Guarantees.PAlloc2.selects_least_open_bucket` |
| 3 | `P-DEPOSIT-1` | `LidoSRv3.Audit.Guarantees.PDeposit1.source_deposit_conserves_and_rolls_back` |
| 4 | `P-TOPUP-1` | `LidoSRv3.Audit.valid_result_preserves_router_order` |
| 5 | `P-ACCOUNT-1` | `LidoSRv3.Audit.MinFirst.totalAllocated_le_requested` |
| 6 | `P-RESERVE-1` | metadata-only; no Lean theorem claimed |
| 7 | `P-ETH-1` | metadata-only; no Lean theorem claimed |
| 8 | `P-ADDRESS-1` | metadata-only; no Lean theorem claimed |
| 9 | `P-TOPUP-2` | metadata-only; no Lean theorem claimed |
| 10 | `P-CONSOLIDATION-1` | metadata-only; no Lean theorem claimed |
| 11 | `P-SSZ-1` | `LidoSRv3.Audit.Guarantees.PSsz1.structural_witness_binding_sound` |

Each guarantee carries per-plane status across the model, algorithm, source,
transaction, Yul, EVM, and cryptographic planes. P-ALLOC-1, P-ALLOC-2, and
P-DEPOSIT-1 claim Lean-checked correspondence to their pinned Solidity spans;
no guarantee currently claims correspondence to deployed bytecode, and several
are explicitly blocked on runtime provenance. Read the exact
per-guarantee wording, status, assumptions, and next gate from
`audit/guarantees.yaml` rather than from any prose summary, including this one.
Generated views of the same data live in `audit/STATUS.md`, `audit/ROADMAP.md`,
and `audit/REPRODUCE.md`; regenerate them with `make audit-generate`.

## Reproducing

```bash
make audit-check   # validate the registry, pins, source map, and generated views
make test          # metadata mutants, receipt, guards, executable regressions
make prove         # Lean theorem checking; writes proofs/logs/proof-report.json
```

`make audit-check` is fail-closed: it rejects a registry that has drifted from
the eleven IDs, that loses a pin, or whose generated views are stale.
`make test` additionally runs the metadata validator against deliberate mutants
and re-derives the validation receipt, so a silent edit to the evidence tree
fails the build.

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
