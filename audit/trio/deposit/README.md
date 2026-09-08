# P-DEPOSIT-1 trio composition

This directory composes the already-delivered ALLOC-1/ALLOC-2 interface at the
exact repository base `caad1ef5e297202636e6fe643afa88fe8a62d618`.

Pinned Solidity source: `lidofinance/core@17005714f151e5502c559932319a3f2f74ac2436`.

This first slice consumes the accepted ABI parent and executes the deposit join
through `_getModuleIndexById`, `allocated[moduleIdx]`, the named per-block/key
limits, and the independently supplied `obtainDepositData` interface.  It derives
the returned key count only after the pinned 48-byte alignment check, rejects a
module result above `min(maxDepositsPerBlock, allocation/maxEBType1)`, and derives
the Lido-pull bound from those executed guards rather than from a link premise.
The success theorem is stated over the composed executor, so it cannot be proved
by restating an ALLOC equality without running the module call.
It accepts the documented trio limitations
and does not claim compiler-memory, deployed-bytecode, or deployment identity.

Pinned constructor source admits arbitrary nonzero caller-supplied values. The
checked `0xDEAD` / `64 ether` counterexample therefore keeps
`A-DEPOSIT-CONTRACT` and `A-DEPOSIT-32-ETHER` explicit. No ALLOC-1, ALLOC-2,
RESERVE-1, registry, YAML, trust, or `AllGuarantees` file is changed.

Production Lean lives beside this file.  Executable regressions live under
`Tests/Verity` and are selected by the local Lake target.
