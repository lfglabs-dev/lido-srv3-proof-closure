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

`LiveBeacon.lean` is the live-callee suffix. After the same executed
allocation/module prefix, the Lido pull runs as the delivered RESERVE-1
executor with the nonzero seed `actualDepositsCount`, and every beacon deposit
is an actual CALL to the accepted PR273 source callee
(`TopupBeaconCallee.dispatch sha256`) in the same `Live.World`, through PR273's
`TopupBeaconBatch.loop`. There is no Boolean beacon acceptance oracle, no
manual router debit/beacon credit and no auxiliary balance counter: the router
balance is the live ledger entry, and the line 996 assertion reads it.
`LinksSource` is now derived from the executed prefix
(`Deposit.prepareDepositABI_composes_beacon_values`,
`RouterDeposit.linksSource_of_prepareDepositABI`,
`RouterDeposit.execute_ok_conservation_derived`), not supplied by the caller.
`LiveBeacon.positive_success` derives, from source/physical inputs only:
Lido debit and beacon credit of `actualKeys * DEPOSIT_SIZE`, restoration of
the arbitrary old router balance, preservation of every other account, the
beacon count increment, one chronological journal (receiver callback, then one
accepted CALL per key with the serialized source payload and the pinned value)
and the per-deposit branch/event effect chain. `failure_restores` is the root
rollback; the executable regressions include a late tree-full rejection after
an accepted first deposit and a `maxEBType1 ≠ DEPOSIT_SIZE` run that reaches
and fails the modeled assertion. The signature batch width, beacon capacity,
beacon code and account distinctness are explicit success-domain conditions;
the returned public-key width is derived.

## Remaining composition obligations

The executable relation now binds allocation, returned keys, the live Lido
withdrawal, and beacon calls in one source-ordered root transition. Remaining
gaps are correspondence from this mixed source model to one compiled EVM
transaction, physical router storage for the abstract allocation transcript and
router metadata, the SHA-256/precompile boundary (opaque `sha256`), the
generated ABI decoder of the deposit contract, and deployed contract/code
identity. `RouterDeposit.beaconLoop` keeps its Boolean acceptance oracle and
router counters as the previously accepted data-only model; `LiveBeacon` is the
live replacement, not a rewrite of it.

The rollback theorem establishes the behavior of the model wrapper, which
restores its input World on failure; it is not an EVM rollback correspondence
proof. Before that wrapper restores the snapshot, the raw result retains every
successful beacon-call prefix when a later beacon call fails. Deposit-data roots use the existing source computation model; its
cryptographic/SSZ correspondence and deployed target identity are separate
obligations. This increment improves the model and its conditional producer
link, without closing the full P-DEPOSIT-1 guarantee.
