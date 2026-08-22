# Pack S1 brief — named HashIdentification child

One node, one PR. Not Best-of-N. No new guarantee IDs. `HashIdentification`
stays named. Opaque source `sha256` and `Sha256Engine.sha256` remain
different symbols. `A-SHA256-FFI` stays.

## Frozen interfaces used

`Spec.SszWitness` from Wave 0. Pack C's `SszCorrespondence.HashIdentification`
is the named hyp this child applies. Deposit uniqueness remains
`PerfectDepositEncoding`.

## Work

1. Unregistered child `hash_identification_agrees_on_bytes`: under the
   named hyp, the two octet functions agree on every byte-bounded
   preimage. The proof is `apply h`. The hyp is not discharged.
2. `hash_identification_remains_named` records that the identification
   is still a hypothesis.
3. `hash_identification_does_not_imply_deployed_sha` records that the
   named hyp does not inhabit deployed SHA-256, Yul, address-2, or
   EIP-4788.
4. Engine mutant kill-line is the Pack C vector re-exported as
   `engine_mutant_still_disagrees`.

## Kill-lines

- Pack C's one-byte mutant of `Sha256Engine.sha256` still disagrees with
  the engine, so `HashIdentification` names a specific pair.
- The named hyp is not a registered parent conjunct.

## Out of scope

EIP-4788, Yul, live verifyProof, deployed SHA-256, address-2 precompile.
