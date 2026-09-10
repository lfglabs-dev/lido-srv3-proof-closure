# DEPOSIT-1: necessary live-ledger composition

This increment consumes the successful `LiveBeacon.execute` result in the
registered public theorem `PDeposit1.actual_live_pipeline_conservation`.
It closes the supplementary executor's missing Lido-withdrawal / beacon-ledger
connection. It does **not** close full DEPOSIT-1 source correspondence.

The source pin remains `lidofinance/core@17005714f151e5502c559932319a3f2f74ac2436`:
`StakingRouter.deposit` and `_deposit` through the final balance assertion,
`BeaconChainDepositor`'s 32-ether deposit loop, and `Lido.withdrawDepositableEther`
(Lido.sol:869–886) with its concrete locator/queue/oracle/router callees.

## Promise, consumer and derivation

The useful value promise is that successful deposits move the same value from
Lido to beacon while restoring the router balance. The source-shaped root
consumer derives its executed preparation and nonempty suffix; it does not
take a supplied prepared transcript or withdrawal receipt as a premise.

`WithdrawalLedger.pipeline_withdrawal_success_ledger` follows the actual
withdrawal stages. The source locator, queue and oracle routes preserve the
needed balance frame. The oracle result is independent of arbitrary fallback
behavior: `pipeline_frame_other_irrel` proves equality of the **complete**
current-frame results before an internal rejecting comparison callee is used.
The literal payable receiver selector reaches `Router.receiveDepositableEther`
through the dispatcher chain. No global balance-preservation premise about
arbitrary callees remains in the pipeline theorem. Successful CALL derives
funding; the preceding source checks derive router authorization.

`LiveBeaconCommitted.execute_pipeline_success_conservation` consumes that
withdrawal result and the existing actual beacon-loop ledger/count result in
the same live world. The executed preparation supplies the checked pull
product and its uint256 bound. At the router account, the withdrawal credit,
beacon debit and final balance assertion imply
`lidoPullWei = actualKeys * DEPOSIT_SIZE`. For nonzero keys, cancellation then
**derives** `maxEBType1 = DEPOSIT_SIZE`; it is no longer a caller hypothesis.
The pointwise balances compose for every account. Zero-key success is kept
and makes no per-key configuration claim.

The new public theorem consumes this composed executor directly. It is
imported by AllGuarantees, queried by Trust and registered through the existing
`audit/trio/main-guarantees.json` / UX2 mechanism. All eleven IDs and historical
abstract/Verity theorem pairs remain intact. No equality with a different
historical synthetic program is claimed.

## Exact remaining conditions and internal gaps

The theorem retains the existing `Pipeline.Bound`: physical locator/consensus
address bindings, locator/queue/oracle separation and code presence for the
locator, queue, oracle and consensus accounts. It also states distinct Lido /
router and router / beacon roles. This increment does not establish their
initialization or deployed identities. Static-call interpretation and the
arbitrary fallback remain universally quantified; no new callee frame premise,
funding bound, successful stage assumption or 32-ether premise replaces the
resolved obligations.

Required full-entry correspondence remains OPEN:

* The allocation/module prefix still takes a storage/oracle/transcript view and
  an `obtainDepositData` result separately from the live world. Actual physical
  module calls, arguments and effects must be connected to that prefix.
* Physical module metadata and event order are not yet modeled correctly as a
  single source transition. Solidity records them before withdrawal;
  `LiveBeacon.execute` assembles separate metadata after the suffix.
* The Lido withdrawal is invoked through its typed source executor. Outer
  router-to-Lido ABI/error bytes and the complete entry's observable rollback
  still need their actual source connection. The existing model rollback
  theorem is not a claim about omitted Solidity effects.

The accepted general compiler, declared Verity semantics, cryptographic,
general gas and consensus boundaries are unchanged. These named Lido-specific
gaps are not moved into them. ALLOC-1, ALLOC-2 and RESERVE-1 are unchanged and
remain outside the improvement queue.

## Validation scope

The final facade/composition target and full Trust check are retained with
source/dependency identities in this directory. The new production results use
ordinary Lean axioms only. The full Trust inventory still has its 23 previously
declared native fixture axioms and three production exceptions; this is not a
claim that the full repository is kernel-only.

The four `Tests.Verity.LiveBeaconCommitted` declarations exercise consumer
shapes, zero-key and root-failure consequences. They are not four new concrete
execution fixtures. The original PR301 executable fixtures use `native_decide`
and are not relabeled as kernel proofs. The actual LiveBeacon/Deposit/
RouterDeposit source programs used there are unchanged by this increment, so
no fresh Forge run or positive execution test is claimed here.

Failed local attempts are diagnostic only: missing import artifacts were
built; let-bound match expressions were reduced before inversion; pointwise
balance cancellation split the relevant address equalities. No failing
compilation or `sorryAx` diagnostic is counted as accepted evidence.
