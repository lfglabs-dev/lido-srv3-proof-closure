# P-ALLOC-2 official loop-semantics blocker

P-ALLOC-2 has no source-to-official loop simulation.

Pin `1fe0218863a4c8d6113e6cdd4de3766a54df81c7` contains
`Verity.Proofs.LoopSimulation`. This slice does not use it. Presence of the
module is not a proof.

The slice stops at MODEL/SOURCE, checked `Uint256` writes, and candidate
correspondence. It does not add `runVerity`, an interpreter, `unsafeYul`, or
an axiom. The SOURCE-to-official-semantics bridge stays OPEN.
