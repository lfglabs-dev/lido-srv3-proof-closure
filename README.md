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
- `LidoSRv3/`: Verity/Lean SRv3 economic model and checked theorems. The signed
  P0 scope is the six P0 candidate economic-conservation properties
  (SRV3-P1--P6), decomposed internally into finer executable target groups such
  as top-up (SRV3-P8) and allocation-capacity (SRV3-P9); the operational and
  module-configuration groups (SRV3-P7, P10--P15) are executable follow-on /
  internal lanes, not current acceptance commitments.
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
