# Lido SRv3 Proof Closure

Executable evidence package for the Lido SRv3 accounting proof-closure report.
The repository contains the report, a Verity/Lean SRv3 economic model,
reference test copies, proof target registers, and local
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
- `LidoSRv3/`: Verity/Lean SRv3 economic model and checked P0 theorems.
- `verity/targets/`: source maps and target manifests, including
  `certora-pr1811-map.md`, the Certora → PR #1811 → Verity property and
  assumption map (Week-1 pilot deliverable).
- `tests/solidity-reference/`: relevant Lido reference tests copied from PR
  #1811 source material.
- `proofs/`: lockfile, proof target files, and generated Lean proof logs.
- `style/`: local copy of the Verity/Unlink report style, adjusted for a formal
  methods proof-closure report.
- `assets/`: LFG Labs and Verity PDF marks.
- `dist/`: compiled deliverable PDF.
