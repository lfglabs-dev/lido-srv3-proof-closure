# Lido SRv3 Formal Methods Report Specimen

Private-repo-style LaTeX package for a Lido SRv3 formal methods pilot report.
The structure and typography are adapted from the `unlink-audit` LaTeX tooling:
`report.tex`, `content/*.tex`, shared `style/*.sty`, LFG/Verity assets, and a
`latexmk` Makefile.

This is a mock final report specimen. It assumes the selected P0 properties were
proved so the hierarchy, tone, and delivery shape can be evaluated before real
proof artifacts exist.

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
- `style/`: local copy of the Verity/Unlink report style, adjusted for a formal
  methods proof-closure report.
- `assets/`: LFG Labs and Verity PDF marks.
- `dist/`: compiled deliverable PDF.
