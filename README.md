# Lido SRv3 Proof Closure

Start with [the delivery scope and validation results](report/DELIVERY-20260921.md).
The eleven guarantees, assumptions and reproduction commands below describe the
current candidate. Independent review remains pending. Older audit dossiers are
retained as evidence and do not override the current registry or validation receipt.

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
> - **Every row below still has open fidelity gaps — 85 in total.** The last
>   column counts them per row; `audit/guarantees.yaml` names each one.
> - **`CHECKED` is conditional, and one gap has no theorem to compose.** Every
>   row is proved under named premises — the named-premises table below gives
>   them per row, and `A-SHA256-FFI` and `A-EIP4788-AUTHENTIC` are HIGH severity. The `P-ADDRESS-1` live
>   equivariance of the `transferFrom`, `requestWithdrawals` and `unwrap`
>   bodies is a named gap, not a discharged one.

This repo holds Lean evidence for eleven Staking Router v3 guarantees on that
pinned source. The table below is the status. Not every row is closed.

Lean theorems decide what is proved. `audit/guarantees.yaml` only classifies
them.

Each guarantee is proved in three layers, except where a guarantee notes otherwise:

1. **Abstract Lean 4 model** — the high-level algorithm, used to prove the invariant.
2. **Verity Lean library** — a Lean program of the Solidity control flow that uses the Verity Lean library (`uint256`, overflow, revert). When it succeeds, its results match the abstract model.
3. **Verity Executable Contract** — the same logic as a Verity contract over a `ContractState` (`Contract.run`). Its observables match the Verity Lean library program, and a revert restores the pre-call state.

We do not claim to have verified the bytecode. `CHECKED` means the named Lean theorem builds; `audit/guarantees.yaml` `fidelity.missing` lists the live Lido surfaces that theorem does not cover. If the Verity Executable Contract cannot close, the registry names one gap. Yul, EVM, runtime bytecode, and deployment provenance needed by the registered claims remain required and open. The current delivery uses kernel-checked compiler witnesses. The complete dependency audit accepts only `propext`, `Classical.choice` and `Quot.sound`; no native proof exception is used. This does not prove the Solidity compiler correct or establish deployed-runtime correspondence. See [compiler trust](audit/I-TRUST-COMPILER-KERNEL.md) and the [validation receipt](audit/receipts/delivery-20260921/validation.json).

The **Fidelity gaps** column is the count of `fidelity.missing` entries the
registry records for that row: live Lido surfaces the CHECKED theorem does
*not* cover. It is never zero, so no row is finished. `scripts/audit_metadata.py
check` fails closed if a count here drifts from the registry.

| # | ID | Abstract Lean | Verity Executable Contract | Fidelity gaps |
| --- | --- | --- | --- | --- |
| 1 | `P-ALLOC-1` | CHECKED | CHECKED | 7 open |
| 2 | `P-ALLOC-2` | CHECKED | CHECKED | 4 open |
| 3 | `P-DEPOSIT-1` | CHECKED | CHECKED — actual DSM/module/withdrawal/beacon execution | 4 open |
| 4 | `P-TOPUP-1` | CHECKED | CHECKED | 5 open |
| 5 | `P-ACCOUNT-1` | CHECKED | CHECKED | 6 open |
| 6 | `P-RESERVE-1` | CHECKED | CHECKED | 5 open |
| 7 | `P-CONSOLIDATION-ETH-1` | CHECKED | CHECKED | 19 open |
| 8 | `P-ADDRESS-1` | CHECKED | CHECKED | 6 open |
| 9 | `P-TOPUP-2` | CHECKED | CHECKED | 14 open |
| 10 | `P-CONSOLIDATION-1` | CHECKED | CHECKED | 6 open |
| 11 | `P-SSZ-1` | CHECKED | CHECKED | 9 open |

Wording, assumptions, source spans, next gates: `audit/guarantees.yaml`.
Generated views: `audit/STATUS.md`, `audit/ROADMAP.md`, `audit/REPRODUCE.md`.
Per-guarantee display records: `audit/ux2/<ID>.json`, one per row above, each
carrying the registry wording, the two registered theorems with their exact
Lean statement, file and lines, the assumptions, the open fidelity gaps, the
pinned source spans, and the model-vs-deployed boundary; `scripts/generate_ux2.py
check` fails closed if a record says anything the registry or Lean does not.
The current generated candidate report is `audit/CANDIDATE-ASSURANCE-REPORT.md`;
it records pending review and remaining limitations.
`audit/R1-FINAL-AUDITOR-REPORT.md` is retained historical output and does not
validate this candidate or establish deployment, bytecode, or audit acceptance.

## Named premises and the remaining not-proven gap

`CHECKED` above means the named Lean theorem builds *under the premises the
registry records for that row*. `audit/assumptions.yaml` states each premise's
risk, severity, violation impact and removal path; the table below is the
per-row membership, so a reader meets it beside the status table instead of only
in the registry. `scripts/check_assumption_presentation.py` fails closed if a
cell here drifts from `audit/guarantees.yaml`.

| ID | Named premises the row is proved under |
| --- | --- |
| `P-ALLOC-1` | `A-SOURCE-SHAPED`, `A-VERITY-SCAFFOLD`, `A-SOLC-TRUSTED`, `A-RUNTIME-PROVENANCE`, `A-SUPPORTED-MODULES` |
| `P-ALLOC-2` | `A-VERITY-SCAFFOLD`, `A-SOLC-TRUSTED`, `A-RUNTIME-PROVENANCE` |
| `P-DEPOSIT-1` | `A-SOURCE-SHAPED`, `A-VERITY-SCAFFOLD`, `A-SOLC-TRUSTED`, `A-RUNTIME-PROVENANCE`, `A-NO-REENTRY` |
| `P-TOPUP-1` | `A-ABSTRACT-TX`, `A-SOURCE-SHAPED`, `A-VERITY-SCAFFOLD`, `A-SOLC-TRUSTED`, `A-RUNTIME-PROVENANCE`, `A-NO-REENTRY` |
| `P-ACCOUNT-1` | `A-SOURCE-SHAPED`, `A-VERITY-SCAFFOLD`, `A-SOLC-TRUSTED`, `A-RUNTIME-PROVENANCE` |
| `P-RESERVE-1` | `A-SOURCE-SHAPED`, `A-VERITY-SCAFFOLD`, `A-SOLC-TRUSTED`, `A-RUNTIME-PROVENANCE`, `A-NO-REENTRY` |
| `P-CONSOLIDATION-ETH-1` | `A-ABSTRACT-TX`, `A-SOURCE-SHAPED`, `A-VERITY-SCAFFOLD`, `A-SOLC-TRUSTED`, `A-RUNTIME-PROVENANCE`, `A-NO-REENTRY`, `A-SHA256-FFI`, `A-EIP4788-AUTHENTIC` |
| `P-ADDRESS-1` | `A-SOURCE-SHAPED`, `A-VERITY-SCAFFOLD`, `A-SOLC-TRUSTED`, `A-RUNTIME-PROVENANCE`, `A-NO-REENTRY` |
| `P-TOPUP-2` | `A-SOURCE-SHAPED`, `A-VERITY-SCAFFOLD`, `A-SOLC-TRUSTED`, `A-RUNTIME-PROVENANCE` |
| `P-CONSOLIDATION-1` | `A-SOURCE-SHAPED`, `A-VERITY-SCAFFOLD`, `A-SOLC-TRUSTED`, `A-RUNTIME-PROVENANCE`, `A-SHA256-FFI`, `A-EIP4788-AUTHENTIC` |
| `P-SSZ-1` | `A-SHA256-FFI`, `A-MULTI-NODE-TRANSPORT`, `A-SOLC-TRUSTED`, `A-RUNTIME-PROVENANCE`, `A-EIP4788-AUTHENTIC` |

`A-SOLC-TRUSTED` and `A-RUNTIME-PROVENANCE` carry every row. HIGH-severity premises on the table: `A-EIP4788-AUTHENTIC`, `A-SHA256-FFI`.
Beacon-history authenticity is assumed; digest-value and proof-verification
claims fail if SHA-256 behavior differs from the abstract oracle, and the
`SszSha256Isolation` attempt is recorded as reclassing that premise, not
discharging it. `A-NO-REENTRY` and `A-SUPPORTED-MODULES` are the premises the
2026-09-17/19 not-proven retirement added (both named 2026-09-17): the rows
they carry were strengthened by naming a hypothesis, not by removing one, and
`audit/guarantees.yaml` names on each affected row the gap the premise carries
and what it derives there.

### The remaining not-proven gap

One `P-ADDRESS-1` gap is carried by no premise above and cannot be closed by
adding one. Live sender/owner renaming is registered for the claim batch only
(`PAddress1LiveRenaming.runClaimWithdrawalsTo_rename`,
`actual_claim_batch_rename`). The tree holds no live-body renaming theorem for
`transferFrom`, `requestWithdrawals` or `unwrap`, so there is nothing to compose
them from; those writers keep source-shaped projection coverage whose four-input
projection still carries environment booleans. Closing this needs new live-body
proofs. No named assumption can honestly discharge it, because the missing
content is the theorem itself — so the not-proven bullet stays published rather
than being retired into a premise. `audit/guarantees.yaml` records it as the
2026-09-21 named gap on the `P-ADDRESS-1` row, and
`audit/OPEN-INDEPENDENT-VALIDATION.md` carries the exact-head receipt context.

A second gap is **named, not retired**, on the bonus `P-ORACLE-SUPPLY-1` row.
Half of its first not-proven bullet was retired on 2026-09-21: the pinned
`AccountingOracle.submitReportData` contract-version, consensus-version,
ref-slot and processing-deadline checks are now executed rather than assumed,
because `POracleSupply1EntryGuards` composes caveat C4's executed ladder
(`PAccount1SubmitReportGuards`) with that row's entry parent on the same
`SubmitReportData`, making `senderAllowed` and `consensusHashMatches`
conclusions instead of hypotheses. What stays published as not proven: the
consensus hash is compared as an opaque word (`consensusHashMatches d` is
`d.dataHash == d.consensusHash`), no `keccak256` preimage of the ABI-encoded
report calldata is modeled, and extra-data processing remains outside the
modeled body. No named assumption discharges either residual — a premise
asserting the preimage would assert the missing content — so both stay on the
row rather than being retired into a premise.

## Reproduce

Needs [elan](https://github.com/leanprover/elan), Lean 4.31.0, Python 3.10+
and Bash 4+. The standard `make test` also executes Solidity/Verity differential
tests: install Foundry (`forge`) and initialize the pinned `lido-core` submodule.
Foundry must have Solidity 0.8.25 available (or network access to obtain that
compiler on the first build). The differential harness uses FFI to invoke the
local Lean runner. Put these tools on `PATH`; macOS's system Bash and Python
may be older than the required versions.

Use a clone with complete Git history: audit checks read the recorded review
basis with `git show`. A depth-one checkout omits that basis; run
`git fetch --unshallow origin` when starting from a shallow clone.

Before running the gates, provision and check their dependencies:

```bash
git submodule update --init --recursive
python3 --version
bash --version
forge --version
lake env lean --version
FOUNDRY_PROFILE=minfirst_source forge build
```

The Forge build checks compiler availability without running the FFI tests.
See [the differential harness scope](audit/MINFIRST-SOURCE-ENTRY.md) for its
prerequisites, observables and exclusions.

```bash
lake build         # production library (no Tests, Legacy, or Trust)
lake build LidoSRv3Test   # mutants, vectors, nested Verity tests
make audit-check   # registry, pins, source map, generated views
make test          # Solidity/Verity differential tests, metadata, trust, import DAG, LidoSRv3Test
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
