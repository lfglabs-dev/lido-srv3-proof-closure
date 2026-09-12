# P-TOPUP-2 — live wei conversion + module-selected allocateDeposits

## CLAIM

- **Guarantee:** `P-TOPUP-2`
- **fidelity.missing entry:** `live wei conversion and the module-selected allocateDeposits return/policy`
- **Branch:** `grok/lido-topup-wei-alloc-20260912`
- **Base:** `origin/main` @ `1a40db36df3990da9287ac7b03b7e9a1e9bcffe4`
- **Pinned Solidity:** `17005714f151e5502c559932319a3f2f74ac2436`
- **Claimed by:** grok cloud agent, 2026-09-12
- **Status:** claimed — implementing

This lot does **not** claim the closed DEPOSIT LinksSource entry (PR #405)
or the ACCOUNT / ADDRESS / RESERVE fidelity PRs. Spark `lido-topup-*-registration`
and `lido-topup2-oracle-independence-registration` branches register existing
TOPUP consumers; they do not close this live wei / allocateDeposits entry.

## Targeted gap

Model the pinned router's live wei conversion and the module-selected
`allocateDeposits` return/policy, prove the derivable part, and honestly
shrink the remainder (stated in this README). Additive files only; no
parent / yaml / Trust edits. Do not compose with P-TOPUP-1.
