# Lido SRv3 Proof Closure

Executable evidence package for the Lido SRv3 accounting proof-closure report.
The repository contains the report, a deterministic Verity-style economic model,
reference test copies, executable model tests, proof target registers, and local
reproducibility commands.

## Build

```bash
make bootstrap
make test
make prove
make report
```

The compiled PDF is written to:

```text
dist/lido-srv3-formal-methods-report.pdf
```

## Contents

- `report.tex`: report entrypoint and metadata.
- `content/`: formal-methods report sections.
- `verity/`: executable SRv3 economic model and target manifests.
- `tests/solidity-reference/`: relevant Lido reference tests copied from PR
  #1811 source material.
- `tests/verity/`: executable tests that mirror the reference behavior.
- `proofs/`: lockfile, proof target files, and generated proof logs.
- `style/`: local copy of the Verity/Unlink report style, adjusted for a formal
  methods proof-closure report.
- `assets/`: LFG Labs and Verity PDF marks.
- `dist/`: compiled deliverable PDF.
