# Verity d2d4a18a migration receipt

## Pin and toolchain

- Migration branch base: `campaign/lido-minimal-11` at
  `8bdf1c49e78b569c2956961d7325b72930d8282a`.
- Verity: `6cfc41fe4129e2c56f130bab9617a0c677ce60ae` ->
  `d2d4a18a4d7021adcd90d4b03e619affe506dd54`.
- Lean: `leanprover/lean4:v4.31.0` (unchanged; running Lean 4.31.0,
  commit `68218e876d2a38b1985b8590fff244a83c321783`).
- `lake-manifest.json` has exactly one EVMYulLean entry, at
  `f7e4ee0dc8f8d5265ce822a937ab5be771f182e9`.

## Dependency review

Reviewed the 29-commit target delta, including `Compiler.lean`, main-test and
calls-test updates, the new backend-neutral and Yul execution-summary modules,
generic-induction call bridges, and `PrintAxioms.lean`.  This adds typed
execution-summary projection APIs and seven audited compiler lemmas; it does
not alter the stable `Verity.Core`, `Verity.EVM.Uint256`, `Verity.Stdlib.Math`,
or `Verity.Proofs.Stdlib.Automation` APIs imported by LidoSRv3.

No compatibility fixes were needed.  No theorem statement, model definition,
proof, assurance claim, or public-guarantee count changed.

## Gate evidence

All commands used the unchanged Lean 4.31.0 toolchain.

| Gate | Result | Evidence |
| --- | --- | --- |
| `lake update` | PASS | Verity resolves to target revision; one EVMYulLean manifest entry. |
| `lake build LidoSRv3` | PASS | 46 jobs completed successfully; no new sorry. |
| `lake build` | PASS | 46 jobs completed successfully. |
| `lake build LidoSRv3.Audit.Trust` | PASS | Only `propext` and `Quot.sound` reported. |
| `make test` | PASS | Metadata/provenance guards, optimized negative mutants, MinFirst and SSZ vectors, and five Solidity fixtures pass. |
| `make prove` | PASS | Rebuilds `LidoSRv3` and writes `proofs/logs/proof-report.json` under Lean 4.31.0. |
| `python3 scripts/audit_metadata.py check` | PASS | Exact minimal-11 metadata, pins, source-map, and generated views validated. |
| Forbidden escape scan | PASS | No new `sorry`, `admit`, `axiom`, or `unsafe` occurrence in LidoSRv3 Lean proof files. |

The Makefile's metadata-mutant suite is the available negative-mutant check and
is included in `make test`.
