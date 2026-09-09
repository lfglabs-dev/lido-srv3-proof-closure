# P-DEPOSIT-1 trio composition

This directory composes the already-delivered ALLOC-1/ALLOC-2 interface at the
exact repository base `caad1ef5e297202636e6fe643afa88fe8a62d618`.

Pinned Solidity source: `lidofinance/core@17005714f151e5502c559932319a3f2f74ac2436`.

This first slice consumes the accepted ABI parent and executes the deposit join
through `_getModuleIndexById`, `allocated[moduleIdx]`, the named per-block/key
limits, and the independently supplied `obtainDepositData` interface.  It derives
the returned key count from the returned public-key bytes only after the pinned
48-byte alignment check, retains both returned byte batches, rejects a
module result above `min(maxDepositsPerBlock, allocation/maxEBType1)`, and derives
the Lido-pull bound from those executed guards rather than from a link premise.
The execution then models the source order at `StakingRouter.sol:978`: a
zero-key module result returns without calling Lido; a nonempty result calls the
injected Lido boundary with `(actualKeys * maxEBType1, actualKeys)`, so the
deprecated seed-count ABI argument is derived from the returned keys rather
than supplied as an arbitrary word.
The success theorem is stated over the composed executor, so it cannot be proved
by restating an ALLOC equality without running the module call.
The `WithdrawDepositableEther` suffix returns before the Lido call when the
module returned zero keys.  On the nonzero path, one theorem composes successful
deposit ABI execution with the complete RESERVE-1 `withdrawDepositableEther`
relation, derives both the pull and seed-count arguments from the returned key
count, and proves their word widths from the executed guards. The linked live
withdrawal retains its pause, router-auth and zero-amount guards, reserve
accounting, seed counter update and value-bearing callback. Its successful live
world and observed callback now supply the router balance consumed by the
deposit suffix; the suffix no longer manufactures that credit.
It accepts the documented trio limitations
and does not claim compiler-memory, deployed-bytecode, or deployment identity.

`RouterDeposit.lean` adds a conditional source-shaped suffix covering:
router authorization, active-module and credential guards; the timestamp/block
writer and event before the zero-key return; exact 48/96-byte helper validation;
the per-key selected public key and signature, credentials, deposit-contract
address, source-computed deposit-data root, and 32-ether value transfer; root
rollback on every modeled external failure; and the router-balance assert.
Its public `executeRaw` boundary accepts a successful `depositValuesABI` package,
so module ID, actual count, immutable max balance and batches are taken from
that package. A nonzero execution additionally carries the successful live Lido
withdrawal and callback-balance receipt for those same derived arguments.
Solidity 0.8 checked multiplication is explicit
for `actualDepositsCount * maxEBType1`, `48 * actualDepositsCount`, and
`96 * actualDepositsCount`.
The `maxEBType1 = DEPOSIT_SIZE` deployment identity remains deliberately
separate: a mismatch reaches and fails the modeled Solidity assertion.

Pinned constructor source admits arbitrary nonzero caller-supplied values. The
checked `0xDEAD` / `64 ether` counterexample therefore keeps
`A-DEPOSIT-CONTRACT` and `A-DEPOSIT-32-ETHER` explicit. No ALLOC-1, ALLOC-2,
RESERVE-1, registry, YAML, trust, or `AllGuarantees` file is changed.

Production Lean lives beside this file.  Executable regressions live under
`Tests/Verity` and are selected by the local Lake target.

## Remaining composition obligations

The producer transcript/storage and router suffix Context/World are not yet
bound to one shared Solidity execution. In particular the producer's abstract
withdrawal result and the now-linked live withdrawal are two executions of the
same derived arguments; the packaging still does not prove their source call
order in a single root transaction. The router and Lido balance boundary is
linked, while the remaining storage and before/after states still need a common
execution relation.

The rollback theorem establishes the behavior of the model wrapper, which
restores its input World on failure; it is not an EVM rollback correspondence
proof. Deposit-data roots use the existing source computation model; its
cryptographic/SSZ correspondence and deployed target identity are separate
obligations. This increment improves the model and its conditional producer
link, without closing the full P-DEPOSIT-1 guarantee.
