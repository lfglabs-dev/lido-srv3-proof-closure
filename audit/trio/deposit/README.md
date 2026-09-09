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
module returned zero keys. On the nonzero path, `RouterDeposit.executeRaw`
continues directly from the executed allocation/module prefix into the
RESERVE-1 live `withdrawDepositableEther` executor with both arguments derived
from the returned key count. That execution retains its pause, router-auth and
zero-amount guards, reserve accounting, seed counter update, callback, and call
attempts. Its returned world supplies the router balance consumed by the beacon
loop; there is no abstract withdrawal callback or separately supplied receipt.
It accepts the documented trio limitations
and does not claim compiler-memory, deployed-bytecode, or deployment identity.

`RouterDeposit.lean` adds a conditional source-shaped suffix covering:
router authorization, active-module and credential guards; the timestamp/block
writer and event before the zero-key return; exact 48/96-byte helper validation;
the per-key selected public key and signature, credentials, deposit-contract
address, source-computed deposit-data root, and 32-ether value transfer; root
rollback on every modeled external failure; and the router-balance assert.
Its public `executeRaw` boundary accepts only source inputs and a root world.
It executes the allocation, module selection and returned batches itself, then
executes the conditional live Lido withdrawal and every beacon call in source
order. The allocation transcript, live Lido storage/balances, and router/beacon
state are fields of that one root world and roll back together. The deposit size
is the pinned `BeaconChainDepositor.DEPOSIT_SIZE`, not an input.
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

The executable relation now binds allocation, returned keys, the live Lido
withdrawal, and beacon calls in one source-ordered root transition. Remaining
gaps are correspondence from this mixed source model to one compiled EVM
transaction, physical router storage for the abstract allocation transcript and
router metadata, and deployed contract/code identity.

The rollback theorem establishes the behavior of the model wrapper, which
restores its input World on failure; it is not an EVM rollback correspondence
proof. Before that wrapper restores the snapshot, the raw result retains every
successful beacon-call prefix when a later beacon call fails. Deposit-data roots use the existing source computation model; its
cryptographic/SSZ correspondence and deployed target identity are separate
obligations. This increment improves the model and its conditional producer
link, without closing the full P-DEPOSIT-1 guarantee.
