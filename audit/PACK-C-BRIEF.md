# Pack C brief — hash identification and structural verifyProof/gindex

One node, one PR. Not Best-of-N. No new guarantee IDs. No deployed SHA-256
or Yul claim. EIP-4788 / consolidation gateway stays OPEN.

## Frozen interfaces used

`Spec.SszWitness` from Wave 0. Deposit uniqueness remains
`PerfectDepositEncoding`. The two Lean SHA symbols stay distinct until the
named hyp identifies them.

## Work

1. Named hyp `HashIdentification`: opaque source `sha256` and
   `Sha256Engine.sha256` agree as octet functions. Not discharged. Not a
   claim that either is deployed SHA-256 or the address-2 precompile.
2. Unregistered structural child: `Ssz.verifyProof = true` implies
   `HasGeneralizedIndex`, matching branch arity, and `traverseBranch`
   reconstruction. No SHA.
3. GIndex concat remains the existing SOURCE child
   `source_concat_matches_spec`. Pack C does not restyle it as a live
   verifier.
4. EIP-4788 / gateway binding stays OPEN. Structural `Nat.pair` / gindex
   does not inhabit it.

## Kill-lines

- Mutant `verifyProof` that skips the gindex/pivot/path checks can accept a
  witness that fails `HasGeneralizedIndex`.
- A one-byte mutant of `Sha256Engine.sha256` disagrees with the engine, so
  `HashIdentification` names a specific pair, not an arbitrary function.

## Out of scope

Deployed SHA/Yul, EIP-4788 parent-root, consolidation gateway/bus, Join.
