# Target 4.31 validation receipt

This directory is immutable audit metadata for a proposed future root. It is
not the repository's active Lake configuration.

- Target readiness: `DEV-431-READY`
- Target `PrintAxioms`: `FAIL`
- `AUDIT-CERT=false`
- Exact command: `lake build PrintAxioms && lake env lean PrintAxioms.lean`
- Location: Verity `68f560e66c5de6123061ce5ed60261be162673d1`
- Reproduction status: previously observed upstream failure; not freshly
  independently reproduced by this M0 repair.

An owner-authorized isolated target checkout must make the target
`PrintAxioms` gate pass before any future certification claim.
