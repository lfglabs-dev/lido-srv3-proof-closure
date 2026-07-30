# Lean 4.31 / Verity main migration receipt

## Scope

Mechanical migration from immutable repository base
`ee2e65cd807e913ea245ae6fd7987a7f1d962800`. This migration does not include
the metadata registry/scanner work from PR #7 and does not claim source/EVM/E2E
audit closure.

## Toolchain and dependency graph

- Lean: `leanprover/lean4:v4.24.0` → `leanprover/lean4:v4.31.0`
- Verity: `538c4a9ce2baa25b56062bdc727eb0191ad9e67f` →
  `6cfc41fe4129e2c56f130bab9617a0c677ce60ae`
- `evmyul`: `f7e4ee0dc8f8d5265ce822a937ab5be771f182e9`
  (one inherited instance, supplied by Verity; no direct duplicate)
- `mathlib`: `fabf563a7c95a166b8d7b6efca11c8b4dc9d911f`
- `plausible`: `63045536fe95024e6c18fc7b48e03f506701c5bc`
- `LeanSearchClient`: `c5d5b8fe6e5158def25cd28eb94e4141ad97c843`
- `importGraph`: `5c7542ed018c78194f1e2b903eaf6a792b74c03d`
- `proofwidgets`: `24b0d9dc081c5423f8eec7e866c441e5184f29d9`
- `aesop`: `e3cb2f741431ce31bf73549fb52316a57368b06f`
- `Qq`: `f46324995fca5f0483b742e4eb4daec7f4ee50d2`
- `batteries`: `fa08db58b30eb033edcdab331bba000827f9f785`
- `Cli`: `92564e5770e4d09f2d86dfbf8ada1e9c715b384c`

## Mechanical changes

- Updated `lean-toolchain`.
- Updated the Verity git pin in `lakefile.lean`.
- Regenerated `lake-manifest.json` with Lake 4.31.
- Updated the Verity provenance revision emitted by
  `scripts/write_proof_report.sh`.
- No Lean theorem statement, definition, proof, model, or test source needed an
  API compatibility edit.

## Verification

Commands are run with the Lean 4.31 toolchain `bin` first on `PATH`.

- `lake update`: passed. An initial invocation with an unrelated `lean` earlier
  on `PATH` failed in mathlib's post-update hook with `leantar not found`;
  correcting `PATH` made the same source and dependency graph pass.
- `lake build LidoSRv3`: passed (26 jobs); one existing
  `unnecessarySimpa` linter warning.
- `lake build`: passed (26 jobs); same warning.
- `make test`: passed after the migration checkpoint commit; provenance guards,
  executable MinFirst vectors, and legacy Solidity reference fixture checks
  passed.
- `make prove`: passed after the migration checkpoint commit; rebuilt
  `LidoSRv3` and emitted the proof report under Lean 4.31.
- `lake build LidoSRv3.Audit.Trust`: passed; this is the repository's actual
  PrintAxioms entrypoint. Output contains only the documented Lean foundations
  `propext` and `Quot.sound`, with several theorems reporting no axioms.
- Forbidden proof-escape scan: passed after confirming the only raw token hits
  were explanatory comments in `LidoSRv3/Audit/Trust.lean`; there are no
  `axiom`/`unsafe` declarations or `sorry`/`admit` proof terms.
- Dependency-deduplication scan: passed; exactly one inherited `evmyul` package
  resolves at the required revision.

## Limitations

A green migration establishes DEV-431-READY only. It does not establish
source correspondence, bytecode/EVM equivalence, end-to-end coverage, or audit
closure.
