# Lido SRv3 Proof Closure

This repo holds Lean evidence for eleven Staking Router v3 guarantees on
pinned `lidofinance/core@af095e48bbc1c3841c2c9936219c8461af01056b`.
The table below is the status. Not every row is closed.

Lean theorems decide what is proved. `audit/guarantees.yaml` only classifies
them.

Each guarantee needs a checked abstract Lean theorem and a behaviorally faithful Verity model with a checked refinement theorem.
If Verity cannot close, the registry names one gap. Yul, EVM, runtime bytecode,
and deployment provenance are out of scope.

| # | ID | Abstract Lean | Faithful Verity |
| --- | --- | --- | --- |
| 1 | `P-ALLOC-1` | CHECKED | CHECKED |
| 2 | `P-ALLOC-2` | CHECKED | PARTIAL |
| 3 | `P-DEPOSIT-1` | CHECKED | PARTIAL — linked calls not yet faithfully executed |
| 4 | `P-TOPUP-1` | CHECKED under `A-TOPUP-NOWRAP` | PARTIAL |
| 5 | `P-ACCOUNT-1` | CHECKED | PARTIAL — no distinct stateful execution yet |
| 6 | `P-RESERVE-1` | CHECKED | CHECKED |
| 7 | `P-ETH-1` | CHECKED | CHECKED |
| 8 | `P-ADDRESS-1` | OPEN | PARTIAL |
| 9 | `P-TOPUP-2` | CHECKED | CHECKED |
| 10 | `P-CONSOLIDATION-1` | OPEN | PARTIAL |
| 11 | `P-SSZ-1` | CHECKED | PARTIAL |

Wording, assumptions, source spans, next gates: `audit/guarantees.yaml`.
Generated views: `audit/STATUS.md`, `audit/ROADMAP.md`, `audit/REPRODUCE.md`.

## Reproduce

Needs [elan](https://github.com/leanprover/elan) and Lean 4.31.0.

```bash
make audit-check   # registry, pins, source map, generated views
make test          # mutants, receipt, provenance guards, Lean regressions
make prove         # full LidoSRv3 build; writes proofs/logs/proof-report.json
```

`proofs/logs/proof-report.json` is a build receipt for the superseded
SRV3-P1–P15 lane (`target_scope: legacy-srv3-p1-p15-superseded`). It is not
evidence for the eleven guarantees above. Use `audit/guarantees.yaml` for those.

One guarantee:

```bash
lake build LidoSRv3.Audit.Guarantees.PReserve1
```

PDF: `make report` writes `dist/lido-srv3-formal-methods-report.pdf`.

## Layout

- `LidoSRv3/Audit/` — models, source maps, Verity transactions, facade
- `LidoSRv3/Tests/` — mutants; not imported by the facade
- `audit/` — registry, source map, assumptions, pins, generated views
- `verity/targets/` — pin manifest
- `scripts/` — fail-closed checks
- `fixtures/solidity-reference/` — pinned Lido tests, not executed here
- `archive/` — old campaign and P1–P15 files; not current evidence
