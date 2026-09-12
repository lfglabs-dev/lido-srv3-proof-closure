# Actual SSZ calldata and scratch checks

The harness imports unmodified `SSZ.sol` and `GIndex.sol` from
`lidofinance/core@17005714f151e5502c559932319a3f2f74ac2436`. It sets only the initial
scratch words before calling `SSZ.verifyProof`; no verifier/hash body is duplicated
or overridden, and there are no mocks, cheat codes or replacement precompiles.

A preceding dynamic byte argument varies the real compiler-produced proof offset.
The test checks that offset against the independently calculated ABI head/tail
size, along with the root word at offset 0, residual input word at offset 32, and
preservation of the free-memory pointer word at offset 64. This is a finite check
of that memory word, not the whole-memory or world frame theorem.

The reference has four explicit positions (4–7) in a two-level tree and uses real
SHA. One fuzz property runs 1,024 times with arbitrary words, all four available
positions, metadata bytes and prefix lengths in 0–160. No complete random-input
histogram is claimed. A separate 256-iteration test covers every one-hot bit and
every metadata byte in coupled fixtures, varying position and prefix length; it
does not exhaust their Cartesian product.

Deterministic controls check empty/extra/missing-item error priority and reject
finite wrong-side, reversed-sibling and one-byte-stride roots. The latter roots
are computed by deliberately wrong references; the production source is unchanged.
Distinctness of those chosen finite hashes is checked, not assumed as a universal
cryptographic property. The harness executes two full source iterations, whereas
the new universal Lean result currently composes only one primitive iteration.

These tests do not establish universal Solidity/EVM/FFI correspondence, consensus
anchoring, gas sufficiency, hostile precompile behavior, all ABI malformations or
deployed state provenance. The exact command, compiler configuration, source
hashes and successful output are retained in the accompanying receipt and log.
