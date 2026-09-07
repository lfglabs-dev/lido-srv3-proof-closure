# Decoder word-copy proof and blocked final validation

Not a completion or certification claim.

The resumed existing job `bf503ac6-7b36-4242-9958-2aa4ea637f0a` on `nippur`
completed with exit 0 (75 targets). No new Lean build was submitted.
`lake build audit.trio.alloc2.runtime.ByteWordCopy` used Lean 4.31.0,
base c7adae04416704a839d56333efad003f0a0f46b7, tree
27834bd59a19f789b2fb9d06f9de01b47af123c2 and the 59-file overlay
recorded in byte-abi/source-identity.json. Every overlay file hash was
recomputed against this checkout (producer files against its recorded SHA).
Content digest: f12aae6c2c31508678936ad2f953339bc1240b4d0acc8eb7f9077812be52ce30.
Validation bundle digest: f89350815cce33a8caa93963c2ca8040bcc8e1fe36829c1507da2296b7eb3e46.
The receipt is a focused overlay build, not a complete-source final-head gate.

ByteWordCopy proves terminating recursive copying, destination equality to
original source words, preservation outside the destination interval, and an
mload/mstore primitive trace. The source coverage and fresh destination premises
remain explicit. Axiom inspections report only propext, Classical.choice and
Quot.sound. The full compiler allocation schedule must derive those premises;
this module alone does not establish it. The untracked ByteWordCopyVectors and
DecoderCopy Solidity/JavaScript harness remain preserved WIP and are not part
of this passing build or an executed differential claim.

Final validation is blocked by the existing complete-source server rejection,
archived verbatim in full-source-admission-blocker.json. Durable job
c5928cd0-419e-4db2-ac3c-b5b044501caa exited 1: HTTP 422, server maximum
16777216 bytes, rejection encountered at 16783561 bytes. The measured complete
tracked snapshot was 21466155 bytes. The requested command was `make prove test`
on babylon, with the reviewed full-source wrapper and a 33554432 client limit.
No remote job was admitted; no compiler ran. This is infrastructure failure,
not evidence of a false theorem. The rejected snapshot is e312a7472c32be8536c2284975eaee64d29251f5,
tree ab3a9d54fee62136ac87b72e0386779530b45c08; it does not validate later heads.
No source/evidence was removed and no gate was weakened to fit the limit.

The explicit producer-success premise theorem already derives consumer length
and count bounds without lifecycle bounds assumed from migration/version.
Enclosing canonical entrypoint composition, the complete compiler allocation
schedule, new word-copy differential vectors, and immutable-head full Lean,
trust/native UX2 gates still require completion. The +1 algorithm stays separate.
