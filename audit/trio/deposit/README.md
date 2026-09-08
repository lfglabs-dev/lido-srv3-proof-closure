# P-DEPOSIT-1 trio composition

This directory composes the already-delivered ALLOC-1/ALLOC-2 interface at the
exact repository base `caad1ef5e297202636e6fe643afa88fe8a62d618`.

Pinned Solidity source: `lidofinance/core@17005714f151e5502c559932319a3f2f74ac2436`.

The composition accepts the documented trio limitations.  In particular it
does not claim compiler-memory, deployed-bytecode, constructor, or production
deployment correspondence.  `A-DEPOSIT-CONTRACT` and `A-DEPOSIT-32-ETHER`
therefore remain explicit.  No ALLOC-1, ALLOC-2, RESERVE-1, registry, YAML,
trust, or `AllGuarantees` file is changed by this package.

Production Lean lives beside this file.  Executable regressions live under
`Tests/Verity` and are selected by the local Lake target.

