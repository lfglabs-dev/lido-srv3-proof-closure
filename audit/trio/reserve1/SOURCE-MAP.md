# Owned source map and remaining writer closure

All source references use submodule `17005714f151e5502c559932319a3f2f74ac2436`.
No canonical source-map or guarantee entries are changed.

| Body | Source | Executable / evidence | Boundary |
| --- | --- | --- | --- |
| allocation | `contracts/0.4.24/Lido.sol:605-616` | `Live.getBufferedEtherAllocation` | saves total/deposit partition before locator/queue CALL; full correspondence open |
| canDeposit | `Lido.sol:815-816` | `Live.canDeposit` | bunker CALL before local pause read; source-shaped executor plus differential evidence |
| spending | `Lido.sol:839-859` | `Live.spendDepositableEther` | packed writes/events before frame CALL; full correspondence open |
| withdrawal | `Lido.sol:869-886` | `Live.withdrawDepositableEther` | caller/config admission, seeds, ETH CALL; full correspondence open |
| target writer | `Lido.sol:670-680` | `Live.setDepositsReserveTarget`, `Writers` | internal helper; external ACL at 656-659 remains open |
| report rebalance | `Lido.sol:1125-1132` | `Live.updateBufferedEtherAllocation`, `Writers` | internal helper; report parent at 1072-1121 remains open |
| packed setters | `contracts/0.4.24/utils/UnstructuredStorageExt.sol:20-46` | `PhysicalPacking` | bitwise pair-packer equivalence and projections checked; all parent writer correspondences not closed |
| queue demand | `contracts/0.8.9/WithdrawalQueueBase.sol:143-146` | `Queue.unfinalized_corresponds` / `QueueSpec` | physical current ids/rows, numeric return/panic relation; cryptographic primitive parameter |
| bunker getter | `contracts/0.8.9/WithdrawalQueue.sol:346-354` | `Queue.isBunkerModeActive`; inherited Solidity execution | actual timestamp/max sentinel; writer ACL closure open |
| locator getters | `contracts/0.8.9/LidoLocator.sol:46-56,78-88` | external interpreter boundary | actual immutable constructor bindings still to compose |
| oracle frame | `contracts/0.8.9/oracle/AccountingOracle.sol:439-442` | external interpreter boundary | BaseOracle consensus/ref-slot/time helpers still to compose |
| router receipt | `contracts/0.8.25/sr/StakingRouter.sol:665-669` | external interpreter boundary | actual LIDO auth and DepositableEthReceived event still to compose; source compiler 0.8.25 |

## Writer inventory requiring composition

Lido reserve-target initialization occurs in `initialize` (276-288) and
`finalizeUpgrade_v4` (296-308). Migration `_migrateStorage_v3_to_v4` writes the
buffer/post pair at 328. External target setter admission is Aragon
`canPerform(msg.sender, role, [])` via `_auth(bytes32)` at 1389-1391, distinct
from the direct equality `_auth(address)` at 1394-1395 used by withdrawal.

Other buffer/accounting writers are `rebalanceExternalEtherToInternal`
(978-995), `processClStateUpdate` (1012-1024),
`collectRewardsAndProcessWithdrawals` (1072-1110), `_submit` (1253-1262), and
`_bootstrapInitialHolder` (1459-1466). Raw compact setters are at 1499-1513.
The report path withdraws rewards, withdraws vault funds, finalizes/sends ETH
to the queue, computes the new buffer, and then rebalances reserve. It cannot
be replaced by a supplied post-report buffer/queue without a correspondence.

Queue enqueue and finalization mutate the current ids and cumulative rows;
the harness executes these real internal bodies as sequence setup, but their
complete production authorization and writer proofs remain open. No theorem
here assumes all cumulative rows are monotone or that reserve <= buffer.
Physical projection bounds hold for arbitrary words, while untruncated
accounting invariants need their writer analysis and overflow/truncation policy.

## Observations and explicit exclusions

The finite differential relation matches selected input physical cells and
balances, exact return/revert bytes, direct Lido-issued call target/value/payload
order, and committed ABI events. Queue mapping preimages are computed with
ethers keccak and provided to Lean; missing current-row preimages fail the driver.
The trace is outside contract state; erasure is checked compositionally.

Nested callee traces, reentrancy/callback composition, production immutable
locator binding, actual consensus/oracle interpretation, actual router receipt,
Aragon ACL and complete report/writer composition remain open. World balances
use Nat; the bounded EVM account relation and credit behavior remain to be tied
to source execution, not inferred from the finite small-balance cases. The generic
external interpreter permits rejection, arbitrary bytes, and successful world
effects; that permissiveness is not itself a proof of production behavior.
Fixtures are finite test data, not successful-callee proof premises.

Compiler/runtime/primitive correctness are explicit assumptions. Full bytecode,
gas/deployment-size correctness, cryptographic injectivity, full consensus-state
truth, and public-chain deployment claims are excluded.
