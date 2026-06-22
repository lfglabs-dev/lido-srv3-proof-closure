# Lido SRv3 Proof Closure

Private LaTeX package for the Lido SRv3 accounting proof-closure report.
The structure and typography are adapted from the `unlink-audit` LaTeX tooling:
`report.tex`, `content/*.tex`, shared `style/*.sty`, LFG/Verity assets, and a
`latexmk` Makefile.

This repository is named for the final deliverable shape: report, Verity model,
Lean proof artifacts, proof register, and reproducibility scripts. The current
package contains the polished report and build system; the actual Verity/Lean
artifacts are not included yet.

## Build

```bash
make
```

The compiled PDF is written to:

```text
dist/lido-srv3-formal-methods-report.pdf
```

## Contents

- `report.tex`: report entrypoint and metadata.
- `content/`: concise formal-methods report sections.
- `verity/`: reserved for the SRv3 Verity model.
- `lean/`: reserved for Lean specifications and proofs.
- `proofs/`: reserved for proof logs, build manifests, and theorem registers.
- `style/`: local copy of the Verity/Unlink report style, adjusted for a formal
  methods proof-closure report.
- `assets/`: LFG Labs and Verity PDF marks.
- `dist/`: compiled deliverable PDF.
