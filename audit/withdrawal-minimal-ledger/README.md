# Physical locator ledger composition for DEPOSIT-1 and TOPUP-1

This proof increment preserves the public claim scopes and strengthens their
actual executors. It does not modify the accepted ALLOC/RESERVE guarantees or
any pre-existing executable definition.

## Useful public consumers

`PTopup1.actual_continuation_locator_conserves` proves the same exact
Lido-to-beacon amount and restored router balance as the earlier continuation
consumer, with only its existing physical locator relation and the two role
inequalities. Eight other `Pipeline.Bound` fields are unnecessary for this
ledger result; they are removed without replacement premises.

`PDeposit1.actual_physical_metadata_conserves` now joins the actual packed
metadata writes/event to that withdrawal ledger and the actual beacon-call
ledger, in one `PhysicalMetadata.execute`. It derives the Lido-to-beacon
balance equation and restored router balance from root success. Nonempty
success also derives the configured 32-ETH deposit size; funding and successful
withdrawal/beacon stages are not supplied. The existing physical-metadata
public theorem still exposes the packed fields and event on this same executor.

## Source and composition evidence

Solidity pin: core `17005714f151e5502c559932319a3f2f74ac2436`.

- Lido.sol locator read and getter calls: actual low-160-bit physical locator
  selects the immutable locator dispatcher. Queue/router/oracle getter selectors
  are distinct from each other and from queue/frame/payable receiver selectors.
  Therefore address aliases do not route these particular calls to the arbitrary
  fallback. Success binds the decoded router to the configured receiver.
- WithdrawalQueue bunker/demand getters and AccountingOracle frame getter:
  complete incoming world preservation is derived for selected getter calls,
  including rejects, missing code, arithmetic errors and arbitrary read-only
  consensus replies. No code-presence input or arbitrary fallback frame is used.
- Lido.withdrawDepositableEther: status and allocation preserve the actual
  world; buffer writes preserve the physical locator; frame access preserves
  balances; seeds preserve balances. The actual payable receiver derives its
  authorization/funding and transfer ledger. The successful run then derives
  the complete ledger instead of assuming callee balance preservation.
- StakingRouter.sol:976-996 and SRLib.setLastDepositTimeAndBlock: the two packed
  writes occur at the router address and precede the semantic event and suffix.
  The existing `Lido != router` hypothesis proves that these writes preserve
  the Lido locator read, for every slot and either address-zero case. No
  oracle/router inequality is added. The updated world, not an auxiliary
  metadata result, enters the actual withdrawal and beacon loop.
- TOPUP StakingRouter continuation: existing guard sum, actual withdrawal,
  helper CALLs and final router assertion consume the weaker necessary ledger.
  The assertion derives the exact unwrapped allocation sum on positive success.

The eight removed conditions are the configured consensus-pointer equality;
queue/locator, oracle/locator and oracle/queue inequalities; and code presence
at the configured locator, queue, oracle and consensus addresses. This is not a
claim that source success occurs without code at its actual selected CALL
addresses. Such absence can reject; conditional ledger preservation still
holds. The configured consensus address need not equal the actual physical
pointer for a read-only reply to preserve this ledger. No claim about the
correct consensus frame value is made by the ledger proof.

The physical locator relation remains necessary: an unbound locator can reach
an arbitrary mutating fallback, which this executor intentionally retains.
The relation is transported through the actual DEPOSIT metadata writes and
Lido buffer writes. It is still supplied at the TOPUP continuation entry;
an arbitrary preceding module-call world has not been proved to preserve it.

## Checks and limits

Four new kernel regressions exercise successful withdrawal with aliased
getters, an unbound actual consensus pointer and no code at the unused configured
consensus address; prove those old conditions false; cover no-code locator
rejection without calls; and verify that the real nested consensus callback
observes updated metadata before rejecting, followed by complete modeled root
restoration of balances, metadata and logs. This latter observation is derived
from an actual callback, not a payload placed in an unrelated result.

The new source is proof/composition code over unchanged executable source
models. Existing physical-metadata and beacon/source validations are retained;
this increment does not claim a fresh full Solidity transaction test or a
new bytecode-equivalence theorem. `validate.py` checks actual imported source
bodies against base and package git pins and independently recomputes all
reported new theorem axiom sets. The facade/Trust build and repository trust
checker validate the public consumers and retain the accepted axiom inventory.

Prepared allocation/module prefix, actual deployment/code bindings, raw whole
entry ABI/error/LOG encodings and declared Live/Verity semantics retain their
existing scope. The ledger conclusion is a theorem of the stated source
execution, not unconditional deployed behavior. SHA, compiler, gas and
consensus boundaries are unchanged. The alias regression is a source-model
domain witness; it does not assert that distinct deployed bytecodes coexist
at one mainnet address. The stronger missing module-prefix/physical-state
connections remain separate work, not new hidden premises of these results.
