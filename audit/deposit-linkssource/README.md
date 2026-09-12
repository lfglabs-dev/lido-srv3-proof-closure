# P-DEPOSIT-1 — LinksSource derived from the pinned router

## CLAIM

- **Guarantee:** `P-DEPOSIT-1`
- **fidelity.missing entry:** `LinksSource is a caller-supplied hypothesis: Wave 4 kill-line alloc_derived_linkssource_kill_line_refutes_bridge shows P-ALLOC-1 CheckedBounds and P-ALLOC-2 step premises plus key-count composition still do not imply LinksSource, because ALLOC does not constrain per-batch wei (firstAmount) and does not constrain publicKeysBatchLength`
- **Branch:** `grok/lido-deposit-linkssource-20260912`
- **Base:** `origin/main` @ `0debc40f5f7b1a1b687782710484397eaa7f781b`
- **Pinned Solidity:** `17005714f151e5502c559932319a3f2f74ac2436`
- **Claimed by:** grok cloud agent, 2026-09-12
- **Status:** claimed — implementing

This lot does **not** claim the closed ACCOUNT / ADDRESS / RESERVE fidelity
entries (PRs #402, #403, #404). Spark `lido-deposit-*-registration` branches
register existing DEPOSIT consumers; they do not close this LinksSource
hypothesis.

## Targeted gap

Establish what the pinned router actually imposes on `firstAmount` and
`publicKeysBatchLength`, prove the derivable part, and honestly shrink the
remainder (stated in this README). Additive files only; no parent / yaml /
Trust edits.
