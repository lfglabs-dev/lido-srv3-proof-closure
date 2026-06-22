# Lido SRv3 Formal Methods Report Specimen

Private-repo-style LaTeX package for a Lido SRv3 final-report specimen.
The structure and typography are adapted from the `unlink-audit` LaTeX tooling:
`report.tex`, `content/*.tex`, shared `style/*.sty`, LFG/Verity assets, and a
`latexmk` Makefile.

This is a mock final report specimen. It shows how selected P0 properties would
be explained, scoped, and evidenced once real proof artifacts exist.

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
