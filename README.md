# Lido SRv3 Proof Closure

Lean evidence for eleven public Staking Router v3 guarantees, checked against
pinned `lidofinance/core@af095e48bbc1c3841c2c9936219c8461af01056b`.

Lean theorem statements are authoritative. `audit/guarantees.yaml` classifies
them; it does not prove them.

Each public guarantee has two objectives: a clear abstract Lean property with a
checked theorem, and a behaviorally faithful Verity model with a checked refinement theorem.
When the Verity side cannot close, the registry records exactly one gap class.
General Yul, EVM, runtime bytecode, and deployment provenance are out of scope.

| # | ID | Abstract Lean | Faithful Verity |
| --- | --- | --- | --- |
| 1 | `P-ALLOC-1` | CHECKED | PARTIAL |
| 2 | `P-ALLOC-2` | CHECKED | PARTIAL |
| 3 | `P-DEPOSIT-1` | CHECKED | PARTIAL — linked calls not yet faithfully executed |
| 4 | `P-TOPUP-1` | CHECKED | PARTIAL |
| 5 | `P-ACCOUNT-1` | CHECKED | PARTIAL — no distinct stateful execution yet |
| 6 | `P-RESERVE-1` | CHECKED | CHECKED |
| 7 | `P-ETH-1` | OPEN | OPEN — child TX ledgers only |
| 8 | `P-ADDRESS-1` | OPEN | PARTIAL |
| 9 | `P-TOPUP-2` | CHECKED | PARTIAL |
| 10 | `P-CONSOLIDATION-1` | OPEN | PARTIAL |
| 11 | `P-SSZ-1` | CHECKED | PARTIAL |

Exact wording, assumptions, source spans, and next gates: `audit/guarantees.yaml`.
Generated views: `audit/STATUS.md`, `audit/ROADMAP.md`, `audit/REPRODUCE.md`.

## Reproduce

Requires [elan](https://github.com/leanprover/elan) (Lean 4.31.0).

```bash
make audit-check   # registry, pins, source map, generated views
make test          # mutants, receipt, provenance guards, Lean regressions
make prove         # full LidoSRv3 build; writes proofs/logs/proof-report.json
```

One guarantee:

```bash
lake build LidoSRv3.Audit.Guarantees.PReserve1
```

Optional PDF report: `make report` → `dist/lido-srv3-formal-methods-report.pdf`.

## Layout

- `LidoSRv3/Audit/` — models, source correspondence, Verity transactions, facade
- `LidoSRv3/Tests/` — mutants; not imported by the public facade
- `audit/` — registry, source map, assumptions, pins, generated views
- `verity/targets/` — pin manifest consumed by the Lean project
- `scripts/` — fail-closed metadata and provenance checks
- `fixtures/solidity-reference/` — pinned Lido tests kept as source-facing fixtures
- `archive/` — superseded campaign and P1–P15 material; not current evidence
