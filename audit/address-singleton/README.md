# P-ADDRESS-1 — live singleton-actor exclusion

## CLAIM

- **Guarantee:** `P-ADDRESS-1`
- **fidelity.missing entry:** `singleton-actor exclusion is by omission: singletonActorEntryPoint is False for every modeled tag, so the parent carries no live exclusion proof`
- **Branch:** `grok/lido-address-singleton-20260912`
- **Base:** `origin/main` @ `0debc40f5f7b1a1b687782710484397eaa7f781b`
- **Pinned Solidity:** `17005714f151e5502c559932319a3f2f74ac2436`
- **Claimed by:** grok cloud agent, 2026-09-12
- **Status:** claimed — implementing

This lot does **not** claim the ACCOUNT fee-computation entry (PR #402) and
does **not** claim Trust registration of existing ADDRESS consumers
(`spark/lido-address-*-registration-20260911`).

## Targeted gap

Parent `singletonActorEntryPoint` is definitionally `False` for every
`EntryPoint` (`AddressCorrespondence.lean:110-111`). That excludes
singleton-actor writers by omission. This lot adds a **live** exclusion
beside the parent: for each modeled tag, either no fixed owner/admin is
required, or a precise pinned-Solidity counterexample.

The parent `singletonActorEntryPoint`, `universal_address_writer_equivariance`,
and `guarantees.yaml` are not edited.
