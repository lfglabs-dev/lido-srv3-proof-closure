# P-ALLOC-2 official loop-semantics blocker

The repository pins `lfglabs-dev/verity` at
`d2d4a18a4d7021adcd90d4b03e619affe506dd54`. That revision does not contain
`Verity.Proofs.LoopSimulation`.

The proposed official loop framework is Verity PR
[#2231](https://github.com/lfglabs-dev/verity/pull/2231), head
`2a380049fb7033c6b7bd2154b7f4becf62bf7e5e` (`proof/phase1k/loop-simulation`).
It was still **OPEN and unmerged** when this slice was built, so it is not an
independently verified dependency available at the repository pin.

Accordingly this component stops at independent MODEL/SOURCE representations,
checked-`Uint256` mutation obligations, and candidate correspondence. It does
not add `runVerity`, an interpreter, `unsafeYul`, or a substitute axiom. A
SOURCE-to-official-semantics bridge remains blocked until the loop framework is
merged, reviewed, and deliberately repinned by the repository.
