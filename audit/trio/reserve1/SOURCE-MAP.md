# Owned source map and remaining writer closure

All source references use submodule `17005714f151e5502c559932319a3f2f74ac2436`.
No canonical source-map or guarantee entries are changed.

| Body | Source | Executable / evidence | Boundary |
| --- | --- | --- | --- |
| allocation | `contracts/0.4.24/Lido.sol:605-616` | `Live.getBufferedEtherAllocation` | Allocation.successful_queue_observation relates maximality to actual CALL bytes and saved physical locals; full withdrawal composition open |
| canDeposit | `Lido.sol:815-816` | `Live.canDeposit` | Admission.live_status/live_status_false bind bunker bytes and post-call pause read; enclosing writer admission remains open |
| spending | `Lido.sol:839-859` | `Live.spendDepositableEther` | Spending.success_corresponds/SpendingSpec; exact worlds, events and failures around frame CALL; whole-parent specification open |
| withdrawal | `Lido.sol:869-886` | `Live.withdrawDepositableEther` | Pipeline.success/rejected/shortage compose concrete full execution; exhaustive independent parent and physical reserve corollaries open |
| target writer | `Lido.sol:670-680` | `Live.setDepositsReserveTarget`, `Writers` | internal helper; external ACL at 656-659 remains open |
| report rebalance | `Lido.sol:1125-1132` | `Live.updateBufferedEtherAllocation`, `Writers` | internal helper; report parent at 1072-1121 remains open |
| packed setters | `contracts/0.4.24/utils/UnstructuredStorageExt.sol:20-46` | `PhysicalPacking` | bitwise pair-packer equivalence and projections checked; all parent writer correspondences not closed |
| queue demand | `contracts/0.8.9/WithdrawalQueueBase.sol:143-146` | `Queue.unfinalized_corresponds` / `QueueSpec` | physical current ids/rows, numeric return/panic relation; cryptographic primitive parameter |
| bunker getter | `contracts/0.8.9/WithdrawalQueue.sol:346-354` | `Queue.isBunkerModeActive`; inherited Solidity execution | actual timestamp/max sentinel; writer ACL closure open |
| locator getters | `contracts/0.8.9/LidoLocator.sol:46-56,78-88` | Locator.dispatch/getter proofs; inherited 0.8.9 constructor/getters executed | queue/router/oracle immutable values; deployment binding remains explicit |
| oracle frame | `contracts/0.8.9/oracle/AccountingOracle.sol:439-442,561-563`; `BaseOracle.sol:357-360` | `Oracle.frame_success`, `timestamp_corresponds`, `frame_preserves`; inherited source execution | actual physical consensus pointer, nested STATICCALL, malformed/rejected bytes and checked timestamp; complete getter binding via ConsensusCalls; deployment/full parent open |
| consensus frame | `contracts/0.8.9/oracle/HashConsensus.sol:307-312,644-719` | `Consensus.compute_success` / independent `FrameSpec`; compiler-derived physical frame slot | uint64 frame-span multiplication, uint256 remaining arithmetic, initial-epoch and divide-by-zero failures; raw writer setup is not production admission |
| router receipt | `contracts/0.8.25/sr/StakingRouter.sol:665-669` | Router/RouterSpec auth, event and CALL theorems; inherited 0.8.25 Cancun execution | exact-selector receiver composition; full router parent/bytecode refinement open |

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

Nested callee traces, reentrancy/callback composition, complete deployment
binding, full consensus/oracle writer interpretation, Aragon ACL and complete
report/writer composition remain open. Locator getters, router receiver, AccountingOracle/BaseOracle and the
HashConsensus frame getter now have source implementations and finite composed executions; full withdrawal
correspondence is not implied. World balances
use Nat. Transfers proves debit/credit, self-call identity, conservation and
a conditional credit bound from aggregate available ETH. Deriving that aggregate
bound and the complete bounded EVM world relation remains open; it is not
inferred from the finite small-balance cases. The generic
external interpreter permits rejection, arbitrary bytes, and successful world
effects; that permissiveness is not itself a proof of production behavior.
Fixtures are finite test data, not successful-callee proof premises.

Compiler/runtime/primitive correctness are explicit assumptions. Full bytecode,
gas/deployment-size correctness, cryptographic injectivity, full consensus-state
truth, and public-chain deployment claims are excluded.

The current oracle suite additionally compares nested STATICCALL target/value/payload,
relative depth, success status and returned bytes. Every vector timestamp is
checked against the actual transaction block. The physical frame-config slot
is checked against compiler storageLayout and the inherited harness slot query.
An executed failure found and corrected the model's first uint256 treatment of
`config.epochsPerFrame * SLOTS_PER_EPOCH`: both operands are uint64, so that
subexpression must panic on uint64 overflow before the following uint256 add.
A separate case executes uint64 deadline narrowing after a valid span product.

`ABI.decode_encode` proves arbitrary-width byte reduction; `decode_word` and
`decode_second_word` bind actual word decoding with trailing bytes. These are
conversion proofs over Live.encode/decodeWord, not compiler/bytecode refinement.

`CallResults.queue_lookup` composes the physical locator pointer, code guard,
immutable getter and ABI address cast. `frame_reply`, `adjusted_frame`,
`frame_call_failure` and `frame_short_reply` retain actual call worlds/traces.
`WithdrawalTail.source_decomposition` binds the source final block; seed outcomes,
actual_receiver and tail_failure_rolls_back cover its concrete effects.
`after_spend` still needs the full independent spending correspondence upstream.

`Spending.allocation_bounds` derives admission bounds from actual allocation;
`accounting_add_bound` and `adjusted_next_bound` discharge uint256 accounting
overflow without assuming uint128 output bounds. `WithdrawalComposition.after_frame`
composes actual allocation/frame executions through spending into the tail;
spending_failure and late_failure retain full rollback and ordered traces.

`QueueCalls.status`, `allocation_success` and `allocation_panic` compose the
physical pointer and actual queue dispatch through returned bytes. `live_allocation_spec`
uses the identical physical Queue.StateRel. CallResults covers router/oracle
lookups too. OracleCalls binds Oracle.frame through the concrete dispatch chain
to getCurrentFrame success or bubbled rejection, including nested attempts.
Code-presence/address-separation and complete consensus/deployment bindings remain
explicit obligations; no arbitrary successful-callee premise is substituted.

`ConsensusCalls.static_success/static_rejection` bind the source getter to the
actual STATICCALL. oracle_frame/rejection/overflow/no_code bind the physical
consensus pointer and checked timestamp, preserving nested attempts. lido_frame
composes both ABI decoders to exact reference/time values; independent_rules
uses the same physical frame word and immutable source inputs. Constructor/layout
and primitive relations remain explicit upstream deployment obligations.

`Pipeline` composes the source callee chain into complete successful withdrawal
and concrete receiver-rejection/ETH-shortage rollback. Pointer/code preservation
across accounting writes is proved. Bound contains physical address/code inputs,
not successful call flags; receiver immutable authorization is checked separately.
The differential runner selects Pipeline.external for complete source configs.
Exhaustive independent parent and upstream deployment/writer/world relations remain open.


## Enclosing report body (source implementation, correspondence open)

- `Report.collect`: pinned Lido.sol:1072-1119, including `_whenNotStopped`
  (utils/Pausable.sol:18-19), address `_auth` (Lido.sol:1394-1395), captured
  locator getters and conditional calls. Nonpayable/ABI entry dispatch remains open.
- `Report.afterCalls`: Lido.sol:1103-1119, `_setBufferedEther` at 1499-1501,
  packed low-half update and `_updateBufferedEtherAllocation` at 1125-1132.
- `CallData.invoke`: argument-complete variant of the existing high-level CALL
  model, with selector-only equality checked. Deployed primitive binding remains open.
- `receipts/report-source-selectors.json`: ethers 6.14.4 signature hashes and
  pinned source hashes for report getter/vault/finalize selector literals.
- `ReportCases`: seven executed source-interpreter cases; no report EVM claim.


## Report EVM comparisons and ignored-return decoding

- `Report.collect` also decodes the reward-vault return word: Lido.sol:40 declares
  `withdrawRewards(uint256) returns (uint256 amount)`. Its value is ignored by the
  report arithmetic, but short replies revert in the inherited compiler output.
- `ReportDifferential` / `execute-report.cjs`: sixteen inherited pinned report-body
  comparisons with explicit CallFixture boundaries; no production vault/queue claim.
  `report-execution-summary.json` retains the first failing ABI regression and the
  passing immutable source/command/artifact/trace evidence.


## Independent report accounting

`ReportAccountingSpec.Computes` defines executor-independent ordered arithmetic.
`ReportAccounting.corresponds` and `complete` bind it to the exact result and
physical world of `Report.afterCalls` (Lido.sol:1103-1119 and its packed/rebalance
helpers). `failure_restores` is a stage-failure property before any tail write;
root rollback of earlier external effects belongs to the enclosing report relation.
See report-accounting-summary.json for immutable component and trust evidence.


## Independent enclosing report order

`ReportStages.source_decomposition` factors Lido.sol:1072-1119 without changing the
captured locator or reward-return validation order. `ReportSpec.Executes` states
executor-independent parent transaction rules. `ReportParent.corresponds` and
`complete` bind every source outcome/world/ordered attempt list to those rules,
using independent report accounting. Conditional callee-stage internals remain
explicit source observations for subsequent independent expansion.


## Independent conditional report stages

`OptionalCallSpec.Executes` describes amount-based skipping, lookup and CALL
failures, optional return-word validation and success independently of executors.
`ReportCalls` binds these rules to the three report stages (Lido.sol:1089-1101)
and substitutes them into the parent. Reward decoding retains the Lido.sol:40
return-type requirement. Saved-locator decoding and raw primitive CALL observation
are the remaining stage boundaries; concrete vault/queue binding is not claimed.


## Report primitive observation expansion

`CallDataFlow` gives independent CALL correspondence for full ABI bytes.
`ReportLookup` relates saved-locator getter results to independent call and typed
reply decoding rules. `ReportRules.corresponds`/`complete` substitute both through
the report parent, conditional stages and accounting; the expanded predicate has
no source stage executor or source CALL. The explicit raw external interpreter
still requires concrete deployed vault/queue/callback and resource binding.

## Vault and callback source models

- `Vaults.rewards`: LidoExecutionLayerRewardsVault.sol:85-95, immutable LIDO
  authorization, current balance cap, positive-only callback and uint256 result.
- `Vaults.withdrawals`: WithdrawalVault.sol:107-122, NotLido/ZeroAmount/NotEnoughEther
  guards and exact value callback. Dispatch preserves nonpayability and minimum
  one-word calldata length while accepting trailing bytes.
- `VaultCallbacks`: Lido.sol:517-533, fresh vault address lookups, payable callback
  admission, checked cumulative reward write and callback events.
- `ReplyABI`: Error(string)/custom/bubbled bytes and ordered nested trace conversion.
  `VaultCases`: nine composed model executions; real vault/callback bytecode
  correspondence and independent callee specification remain open. Selector
  provenance is in receipts/vault-source-selectors.json.

## Production vault runtime comparison

`compile-vaults.cjs` compiles the two unmodified pinned 0.8.9 vault entries and
retains every resolved import hash, compiler/settings and artifact hashes in a
new evidence directory. `execute-vaults.cjs` deploys them with explicit immutable
constructor arguments alongside the unchanged inherited Lido artifact. Runtime
code and constructor bindings are recorded. `VaultDifferential` runs the composed
Report/Vaults/VaultCallbacks model on the same twelve inputs. Comparison includes
raw failure bytes, nested CALL data/value/result, state, four balances and events.
The locator and finalization receiver remain CallFixture boundaries. Evidence:
receipts/vault-execution-summary.json. No all-path or proxy/resource claim follows.

## Independent vault correspondence

`VaultSpec.Capped` is the greatest quantity bounded by observed balance and caller
maximum. Independent Rewards/Withdrawals relations specify source guard order,
callback skipping and every callback outcome for the pinned vault bodies mapped
above. `VaultRules` substitutes CallFlow.Describes, proving bidirectional body and
root outcome/world/attempt correspondence plus existence. `VaultSpec.Root` gives
success commit and original-world failure restoration independently of executors.
The raw callback interpreter and dispatch/deployment binding remain boundaries.
Evidence: receipts/vault-rules-summary.json; unchanged runtime sources retain their
twelve production-vault comparisons without a new EVM execution claim.

## Independent Lido callback correspondence

`CallbackSpec.Receives` gives fresh lookup, address admission and update ordering;
`RewardUpdate` gives post-lookup checked addition and write/event commitment.
`CallbackRules` binds these to Lido.sol:517-533 with physical locator, independent
CALL and typed reply rules. Body and root correspondences and existence cover both
callbacks. Counter/commit lemmas retain the full bounded sum and explicit core/
balance preservation. Entry dispatch/reply encoding and enclosing report composition
remain open. Evidence: receipts/callback-rules-summary.json; existing runtime suite
sources remain unchanged, with no new execution run claimed.

## Entry selection and replies

`EntrySpec.Dispatch` specifies ordered target/selector matches, shared admission,
invalid replies and fallback. `EntrySpec.Returns` derives successful/rejected replies
from complete transaction observations. `EntryRules` proves exact correspondence
and completeness for Vaults.dispatch and VaultCallbacks.dispatch using the prior
independent body/root specifications. These source-level dispatchers map the pinned
vault one-word entries and Lido no-argument payable callback entries; ABI helper
correctness and deployed compiler dispatch coverage remain explicit obligations.
See receipts/entry-rules-summary.json. No new runtime execution is claimed.

## Composed independent callee/report relation

`CalleeRules.Calls` uses independent code/funds/provisional-transfer/response rules
with a callee reply witness only on invoked paths. `ReportVaults.CallbackReplies`
uses independent callback entry rules; RewardBody/WithdrawalBody substitute those
through their CALL observations. VaultReplies then supplies independent vault entry
observations to every enclosing report CALL/lookup/optional stage. Correspondence,
completeness and failure restoration cover the full composed report. The modified
VaultDifferential uses that exact interpreter, with twelve fresh runtime comparisons
in receipts/report-vaults-summary.json. Delegated locator/queue services and raw
primitive/deployment/codec/resource obligations are not discharged by this step.
