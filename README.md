# Lido SRv3 Proof Closure

> ### These are proofs about a model, not about a deployed contract.
>
> - The subject is a **Lean model** of Staking Router v3, written against pinned
>   source `lidofinance/core@17005714f151e5502c559932319a3f2f74ac2436`.
> - **No theorem here binds to deployed bytecode, a runtime codehash, a
>   constructor, or a chain address.** The SRv3 contracts are deployed on
>   mainnet with `lidofinance/core` v4.0.0 (2026-07-24; StakingRouter proxy
>   `0xFdDf38947aFB03C621C71b06C9C70bce73f12999`, TopUpGateway proxy
>   `0x3FC2C71579D80790Aaa3fc7Be8B66ac39dC57374`); the theorems still speak
>   about the model, not about that deployment.
> - `CHECKED` means *the named Lean theorem builds*. It does not mean audited,
>   verified on chain, or closed.
> - **Every row below still has open fidelity gaps — 67 in total.** The last
>   column counts them per row; `audit/guarantees.yaml` names each one.

This repo holds Lean evidence for eleven Staking Router v3 guarantees on that
pinned source. The table below is the status. Not every row is closed.

Lean theorems decide what is proved. `audit/guarantees.yaml` only classifies
them.

Each guarantee is proved in three layers, except where a guarantee notes otherwise:

1. **Abstract Lean 4 model** — the high-level algorithm, used to prove the invariant.
2. **Verity Lean library** — a Lean program of the Solidity control flow that uses the Verity Lean library (`uint256`, overflow, revert). When it succeeds, its results match the abstract model.
3. **Verity Executable Contract** — the same logic as a Verity contract over a `ContractState` (`Contract.run`). Its observables match the Verity Lean library program, and a revert restores the pre-call state.

We do not claim to have verified the bytecode. `CHECKED` means the named Lean theorem builds; `audit/guarantees.yaml` `fidelity.missing` lists the live Lido surfaces that theorem does not cover. If the Verity Executable Contract cannot close, the registry names one gap. Yul, EVM, runtime bytecode, and deployment provenance are out of scope.

The **Fidelity gaps** column is the count of `fidelity.missing` entries the
registry records for that row: live Lido surfaces the CHECKED theorem does
*not* cover. It is never zero, so no row is finished. `scripts/audit_metadata.py
check` fails closed if a count here drifts from the registry.

| # | ID | Abstract Lean | Verity Executable Contract | Fidelity gaps |
| --- | --- | --- | --- | --- |
| 1 | `P-ALLOC-1` | CHECKED | CHECKED | 3 open |
| 2 | `P-ALLOC-2` | CHECKED | CHECKED | 4 open |
| 3 | `P-DEPOSIT-1` | CHECKED | CHECKED — composed finite list-batch executable transaction | 6 open |
| 4 | `P-TOPUP-1` | CHECKED under `A-TOPUP-NOWRAP` | CHECKED | 1 open |
| 5 | `P-ACCOUNT-1` | CHECKED | CHECKED | 7 open |
| 6 | `P-RESERVE-1` | CHECKED | CHECKED | 7 open |
| 7 | `P-CONSOLIDATION-ETH-1` | CHECKED | CHECKED | 12 open |
| 8 | `P-ADDRESS-1` | CHECKED | CHECKED | 8 open |
| 9 | `P-TOPUP-2` | CHECKED | CHECKED | 6 open |
| 10 | `P-CONSOLIDATION-1` | CHECKED | CHECKED | 7 open |
| 11 | `P-SSZ-1` | CHECKED | CHECKED | 6 open |

Wording, assumptions, source spans, next gates: `audit/guarantees.yaml`.
Generated views: `audit/STATUS.md`, `audit/ROADMAP.md`, `audit/REPRODUCE.md`.
Per-guarantee display records: `audit/ux2/<ID>.json`, one per row above, each
carrying the registry wording, the two registered theorems with their exact
Lean statement, file and lines, the assumptions, the open fidelity gaps, the
pinned source spans, and the model-vs-deployed boundary; `scripts/generate_ux2.py
check` fails closed if a record says anything the registry or Lean does not.
The generated R1 acceptance record is `audit/R1-FINAL-AUDITOR-REPORT.md`; it
covers every registered canonical and supplemental row without promoting it to
a deployment, bytecode, or audit-certification claim.

## Reproduce

Needs [elan](https://github.com/leanprover/elan) and Lean 4.31.0.

```bash
lake build         # production library (no Tests, Legacy, or Trust)
lake build LidoSRv3Test   # mutants, vectors, nested Verity tests
make audit-check   # registry, pins, source map, generated views
make test          # metadata, trust, import DAG, then LidoSRv3Test
make prove         # builds LidoSRv3 and LidoSRv3Legacy; writes proofs/logs/proof-report.json
```

`proofs/logs/proof-report.json` is a build receipt for the superseded
SRV3-P1–P15 lane (`target_scope: legacy-srv3-p1-p15-superseded`). It is not
evidence for the eleven guarantees above. Use `audit/guarantees.yaml` for those.
Those theorems live in `LidoSRv3Legacy`, so `make prove` builds it alongside the
production facade: `scripts/write_proof_report.sh` declares the target set, the
recipe builds exactly that set, and the receipt is refused unless the build log
records every declared target.

One guarantee:

```bash
lake build LidoSRv3.Audit.Guarantees.PReserve1
```

PDF: `make report` writes `dist/lido-srv3-formal-methods-report.pdf`.

## Layout

- `LidoSRv3/Audit/` — models, source maps, Verity transactions, public guarantees
- `LidoSRv3/Tests/` — mutants; not imported by the production facade
- `LidoSRv3/Audit/Trust.lean` — axiom surface; `LidoSRv3Audit` target, not the facade
- `LidoSRv3/Legacy/` — superseded P1–P15 lane; `LidoSRv3Legacy`, not a default target
- `audit/` — registry, source map, assumptions, pins, generated views
- `verity/targets/` — pin manifest
- `scripts/` — fail-closed checks
- `fixtures/solidity-reference/` — pinned Lido tests, not executed here
- `archive/` — old campaign and P1–P15 files; not current evidence
