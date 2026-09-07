# P-RESERVE-1 — incomplete additive delivery

## Composed report, vault and callback rules

`CalleeRules` makes independent CALL semantics consume a relation describing callee
replies. `ReportVaults` substitutes independent callback entries into vault CALLs,
then independent vault entries into every report CALL, lookup and optional stage.
Exact bidirectional whole-report outcome/world/attempt correspondence, completeness
and root failure restoration are proved for the concrete composed interpreter.
The expanded predicate contains no report/vault/callback source executor; delegated
services, codecs and physical primitives remain explicit dependencies.

The differential runner now uses this exact composed interpreter. At source
`cd115f33e62b12e7253f0747860bfb16817a0a6e`, twelve fresh production-vault/inherited-Lido
comparisons pass, including raw failure bytes, physical state, four balances,
events and direct/nested CALL results. Four selected checks and seven baseline
checks pass; 104 unchanged source/olean pairs and eleven dependencies match retained
evidence, with standard inspected axioms. `receipts/report-vaults-summary.json`
links new immutable commands and compressed traces. The unchanged compiled Lido
and vault artifacts are reused with verified source/artifact provenance.

Locator/queue and unhandled services are delegated. Actual queue finalization,
remaining deployed/entry/resource/codec/bounded-world and accounting writer closure,
full remote gates and independent review remain open.

## Independent entry and reply correspondence

`EntrySpec` specifies ordered two-entry selection and replies derived from complete
transaction observations. `EntryRules` connects vault and callback specifications
to their exact dispatcher replies, including selector priority, nonpayable/short
vault calldata rejection, payable callbacks, fallback delegation, successful worlds
and encoded failure/nested traces. Completeness covers every modeled request.
ABI encoding helpers remain explicit dependencies rather than a new codec proof.

Source `c7372c3e13804848bcf9740c3b996033410aebb3`: three selected checks and seven baseline
checks pass; 103 unchanged source/olean pairs and eleven dependency revisions match.
Inspected axioms are standard. See `receipts/entry-rules-summary.json`. The prior
twelve production-vault runtime cases retain unchanged source hashes; no rerun.
Enclosing callee/report composition, deployed primitive/resource/codec binding,
actual queue finalization and other entry/writer/world obligations, full remote
gates and independent review remain open.

## Independent payable callback rules

`CallbackSpec` orders fresh address lookup, sender admission and post-lookup
updates. `CallbackRules` binds physical locator/independent CALL/ABI rules and
proves exact bidirectional body/root outcome/world/attempt correspondence and
existence for both Lido callbacks. Reward overflow precedes writes; success stores
the full bounded sum and emits. The withdrawal update preserves core storage;
both updates preserve balances relative to the lookup-returned world. Root
failure restoration follows the independently specified transaction boundary.

At source `e9003a9918662bab8f65228ddd4909120267da66`, three selected checks and seven
baseline checks pass; 101 unchanged source/olean pairs and eleven dependencies
match prior receipts. Inspected axioms are standard. See
`receipts/callback-rules-summary.json`. Runtime sources retain their twelve-case
production-vault EVM evidence with no new execution run. Dispatch and enclosing
callee/report composition, actual queue finalization, remaining entry/proxy/resource/
bounded-world and writer obligations, full gates and independent review stay open.

## Independent vault body and transaction rules

`VaultSpec` defines the greatest reward amount bounded by balance and maximum,
ordered caller/zero/funds guards, skipped callbacks and callback success/failure.
`VaultRules` substitutes independent CALL rules and proves exact bidirectional
body outcome/world/attempt correspondence for both vaults, plus existence.
Independent transaction rules commit successful worlds and restore the complete
incoming world on error while retaining attempts; both root correspondences pass.

At source `26a09e7a4872a317824aab3461d9696aec48b2eb`, three selected checks and seven
baseline checks pass. The other 99 component source/olean pairs and eleven dependency
revisions match retained receipts; inspected axioms are standard. See
`receipts/vault-rules-summary.json`. Runtime source hashes match the twelve prior
production-vault comparisons; no new execution run is claimed for these proofs.
Remaining obligations include independent callback/dispatch binding and report
composition, actual queue finalization, entry/proxy/resource/bounded-world and other
writer closure, full remote gates and independent review.

## Production vault execution comparisons

Twelve comparisons now execute the unmodified pinned reward/withdrawal vaults and
inherited Lido report/callback bodies against the composed Lean model. They compare
raw root failure bytes, packed accounting, reward counter, reserve/target, all four
balances, events and ordered direct/nested CALL values/payloads/results. Cases cover
reward capping and an empty vault, insufficient withdrawals, cumulative reward
counter overflow, zero amounts, pause/authorization, late queue rejection, report
arithmetic failure and uint128 narrowing with actual incoming rewards.

Source `86ec8bf257ad8244f1a7ef4ae6c194c22f3ba4b5` has one new selected component check and
seven baseline checks passing. The other 99 component source/olean pairs and eleven
dependency revisions match retained receipts. `receipts/vault-execution-summary.json`
links exact source, compilation, constructor/deployed code, command and compressed
trace evidence. Earlier draft evidence is retained. The unchanged Lido artifact is
reused; both vaults were compiled directly with pinned solc 0.8.9, optimizer 200,
Istanbul target, then executed on the local Hardhat Cancun backend.

Locator and queue remain fixtures in this suite. Independent callee specification,
all-path admission/ABI coverage, actual queue finalization, proxy/entry/resource and
bounded-world binding, remaining writer sequences, full remote gates and independent
review remain open. Twelve finite comparisons do not discharge those obligations.

## Source vaults and Lido callbacks

`Vaults` models pinned reward-vault balance capping, caller admission, zero/funds
withdrawal guards, custom errors and nested value-bearing callbacks. `VaultCallbacks`
uses fresh physical locator reads for callback admission, checked reward-counter
updates and the production callback events. `ReplyABI` propagates ABI failure bytes
and nested attempts. Nine composed Lean cases exercise transfers, cap/zero behavior,
nested failure rollback, callback admission and calldata/value rejection.

At source `80ae948313de296a267debed4a34792f823226a8`, five selected module checks and
seven baseline checks pass; 94 unchanged source/olean pairs and eleven dependency
revisions match retained evidence. Inspected axioms are standard. See
`receipts/vault-source-summary.json` and `receipts/vault-source-selectors.json`.
These are source-model executions, not real vault EVM comparisons. The previous
sixteen report EVM cases still use explicit callee fixtures and unchanged runtime
sources. Real vault/callback comparisons, independent callee correspondence, queue
finalization, deployment/resource binding, full gates and independent review remain open.

## Fully expanded independent report relation

`CallDataFlow` proves independent high-level CALL correspondence for arbitrary ABI
payloads, preserving exact supplied bytes and traced/untraced primitive replies.
`ReportLookup` binds the captured locator's actual reply to independent minimum
length, first-word decoding and address narrowing rules. `ReportRules` substitutes
these rules throughout accounting authorization and all conditional report stages.
Its expanded predicate contains no source report stage executor or source CALL.
Exact bidirectional root outcome/world/attempt correspondence, completeness,
original-world failure restoration and successful active-state admission are proved.

The semantic boundary is now the raw external reply interpreter, including vault,
queue and callback behavior. Concrete implementation/deployment/resource binding,
other writers/entry paths, full remote gates and independent review remain open.
At source `2d357ae43ee340d38aa5189f6cab0e40604ab05e`, four selected checks and seven baseline checks pass; 91
unchanged source/olean pairs and eleven dependency revisions match. Axioms are
standard. See `receipts/report-primitives-summary.json`. Report runtime hashes are
unchanged from its sixteen EVM comparisons. The remote wrapper hash is unchanged
and no dependency-bundle tool was discovered; no new remote job is claimed.

## Independent conditional report calls

`OptionalCallSpec` independently specifies zero-amount skipping, lookup failure,
CALL failure, short required-word return and success. The reward stage alone
validates a return word; withdrawal/finalization accept successful void replies.
No observations are required for a skipped stage. `ReportCalls` proves exact
bidirectional stage correspondence, including returned stage worlds and ordered
lookup/CALL attempts, then substitutes these rules throughout the report parent.
Full root outcome/world/trace correspondence, completeness and rollback remain.

Locator lookup internals and primitive CALL observations are still explicit
boundaries. Concrete vault/queue, entry dispatch, deployment/resource and other
integration obligations remain open. At source `63502ce2fbd0083d84e7e131d71532dc58aa766a`, three selected checks
and seven baseline/import checks pass. The other 89 source/olean pairs and eleven
dependency revisions match, with standard axioms only. See
`receipts/report-calls-summary.json`. Runtime hashes are unchanged from the sixteen
report EVM comparisons. Full gates and independent review are still required.

## Independent enclosing report sequence

`ReportSpec.Executes` independently orders the physical pause guard, accounting
lookup/address authorization, reward stage, withdrawal stage, queue-finalization
stage and accounting tail. Unvisited stages need no observations. Every failure
restores the original transaction world while preserving all visited attempts in
order. `ReportStages.source_decomposition` retains one captured locator across
all later getters and keeps reward return decoding before subsequent stages.

`ReportParent` proves exact bidirectional outcome/world/attempt correspondence and
completeness for the whole modeled report. Its accounting observation is replaced
with ReportAccounting's independent rules. Conditional external-stage internals
still use explicit source observations; their independent expansion and concrete
callee/deployment binding remain open.

At source `043a845b5db3ef538eff0cf4e6328f400375ccc8`, four selected checks and seven baseline/import checks pass.
The other 86 source/olean pairs and eleven dependency revisions match, with only
standard axioms. See `receipts/report-parent-summary.json`. Report executable
source hashes are unchanged from its sixteen EVM comparisons, which remain tied
to their original source SHA. Full implementation, remote gates and independent
review remain incomplete.

## Independent report accounting correspondence

`ReportAccountingSpec` states ordered reward-add overflow, withdrawal-add overflow,
subtraction underflow and successful post-buffer arithmetic without importing an
executor. Its rules are total, deterministic and bound the successful full result.
`ReportAccounting` proves bidirectional exact result/world/event correspondence
and completeness for Report.afterCalls. The pure post-state projection preserves
the packed companion, narrows buffer to low128, conditionally increases reserve
and emits reserve/ETHDistributed in source order with the full computed amount.
All arithmetic failures occur before writes/events and retain the stage world
with no attempted calls; committed balances are unchanged.

At source `227d440fea51aff838c3e689dc9536d042308cab`, three selected checks and seven baseline/import checks pass.
The other 84 source/olean pairs and eleven dependency revisions match, with standard
axioms only. See `receipts/report-accounting-summary.json`. Runtime source hashes
are unchanged from the sixteen report EVM comparisons at `4f2b6867518337bc12acd8806fb1b463ff19c516`;
no new runtime run is claimed. Independent parent sequencing/callee binding, other
integration, full remote gates and independent certification remain open.

## Pinned report execution comparison and ABI correction

Sixteen comparisons execute the unchanged inherited Solidity report body against
explicit locator/vault/queue fixtures and compare it with Report.collect. They
check fault/rejection bytes, exact direct CALL target/value/payload/acceptance/return
bytes, packed buffer/reserve/target storage, ordered logs and Lido/queue ETH balances.
Cases include all/zero calls, pause/auth, malformed getter and reward returns,
each external rejection, checked arithmetic failures, low128 narrowing/full event,
reserve already above target, trailing reward bytes, no-code queue and insufficient
CALL funds. These fixtures do not implement production vault or queue finalization.

The first draft found a model defect: withdrawRewards returns uint256 (Lido.sol:40),
so Solidity validates at least 32 return bytes even when ignoring its value.
Report.collect now decodes that word. The original failed comparison is retained;
the corrected source ignores the returned number for its report-input arithmetic.

At source `4f2b6867518337bc12acd8806fb1b463ff19c516`, all sixteen immutable EVM/model comparisons, four selected
Lean checks and seven baseline/import checks pass. The other 81 source/olean pairs
and eleven dependency revisions match; axioms are standard. All sixteen compressed
traces verify against compressed and decompressed hashes. See
`receipts/report-execution-summary.json`. The existing Lido artifact hash is checked,
and exact toolchain/command/source/exit context is retained. Independent report
correspondence, concrete callees, broader integration and full remote gates remain
open; this is not independent certification.

## Enclosing report source body

`Report.collect` now models pinned Lido.collectRewardsAndProcessWithdrawals:
physical pause check, one captured locator, accounting-address authorization,
conditional reward-vault and withdrawal-vault calls, conditional value-bearing
queue finalization, then buffer accounting and reserve rebalance. `CallData.invoke`
retains complete argument bytes and has exact equality with Live.call for selector-only
payloads. Buffer arithmetic reads the post-call world, checks both additions and
subtraction, narrows only the low packed half and emits the full computed amount.

Seven executed Lean model cases cover saved locator under callback mutation,
post-call buffer/high-half changes, argument bytes/order/value, queue rejection and
rollback, skipped zero amounts, arithmetic overflow/underflow, authorization and
malformed accounting data. These fixtures are not EVM report execution. Independent
report correspondence, vault/queue implementations, entry dispatch and deployment
binding remain open. Historical runtime suites cover their prior sources only.

At source `e45d4d309cd0bdafe82be8ba8caeb550b93706ad`, four selected Lean checks and seven baseline checks pass;
80 unchanged source/olean pairs and eleven dependency revisions match. Axioms are
standard. See `receipts/report-source-summary.json` and selector hashing provenance
in `receipts/report-source-selectors.json`. Full remote gates and certification are
still missing; this is implementation progress, not completion.

## Authorization and external target balance invariant

`AuthorizationBalance` proves provisional balance preservation for completed ACL
evaluation and Kernel permission dispatch, including nested oracle traces and
malformed reply decoding. Argument-complete permission CALLs and the physical
initialization/kernel prefix propagate aggregate conservation. Every external
target-setter outcome, including denial/fault and root rollback, retains the total
and incoming finite aggregate bound. Concrete ACLCalls specialization leaves
premises for unhandled requests and the explicit host-exhaustion fallback.

No host exhaustion is turned into denial, and no EVM gas, initial aggregate
reachability or general delegated/deployed execution claim is made. At source
`48a7fad44c41df1305e27c2245f3a46563b1da79`, two selected checks and seven baseline/import checks pass. The other
79 source/olean pairs and eleven dependency revisions match; axioms are standard.
See `receipts/authorization-balance-summary.json`. Runtime source and prior runtime
receipts are unchanged. Full implementation, remote gates and independent review
remain incomplete.

## Complete withdrawal balance invariant

`WithdrawalBalance` carries exact total conservation and the finite aggregate bound
through the entire source withdrawal program, including failed intermediate stages
and root rollback. The proof composes balance-preserving reads, writes, events,
guards, decoders and actual CALLs. It needs no successful-path, authorization,
ABI-validity or packed-accounting premise. Every resulting account is uint256-bounded
when the explicit incoming aggregate is below UINT256_MODULUS. The concrete pipeline
specialization discharges its handled callees; delegated code retains its premise.
Internal target and report-rebalance writers also conserve the aggregate.

This closes balance propagation through the modeled withdrawal, not initial EVM
aggregate reachability or general delegated/callback/deployment/resource behavior.
Other parent/writer obligations, canonical full gates and independent review remain
open. At source `e1fc0aebd77fe022a3548d86b6a174fdbf7e5d34`, two selected checks and seven baseline/import checks
pass; 78 unchanged source/olean pairs and eleven dependency revisions are verified.
Axioms are standard. See `receipts/withdrawal-balance-summary.json`. Runtime code
and its prior execution evidence are unchanged. These are bounded checks only.

## Concrete callee balance preservation

`CalleeBalance` proves that the handled Locator, Queue, Oracle and Router paths
preserve provisional balances on success. This covers malformed replies, arithmetic
panic, nonpayable/authorization rejection and nested STATICCALL without assumptions
on static reply bytes. Their dispatch composition retains a balance-preservation
premise only for delegated code. The CALL theorem covers code/funds failure, success
and rejection with either trace representation: every outcome conserves total
balance and preserves the explicit finite aggregate bound. The resulting per-account
uint256 bound specializes to the concrete pipeline.

Initial aggregate reachability from EVM state, general delegated/callback behavior,
deployed primitive/resource binding and remaining parent/writer integration are
still open. At source `c89787d5c6228afc04b4eb359ca66482c850144d`, two selected component checks and seven baseline
checks pass. The other 77 source/olean pairs match prior receipts; eleven dependency
revisions match and axioms are standard. `receipts/callee-balance-summary.json`
records these bounded checks. Runtime source is unchanged; no clean/full-gate or
certification claim is made. The remote wrapper hash remains unchanged and no
supported dependency-bundle tool was discovered.

## Finite aggregate balance preservation

`BalanceSpec` defines a duplicate-free finite account support, zero balances outside
that support and a strict aggregate bound. Its conservation theorem sums the
independent pointwise CALL balance rule, including aliased sender/recipient.
Support can grow to include previously absent accounts without changing initial
mass. `Balance` applies these rules to every funded provisional source transfer:
total balance is preserved, and every resulting account is below the aggregate
limit. With limit UINT256_MODULUS, this justifies unsaturated receiver credit,
including fresh recipients and self-transfers.

This is conditional on an explicit incoming aggregate invariant. Derivation from
EVM state, preservation through arbitrary callees and complete bounded-world
closure remain open. No transfer implementation or runtime fixture changed.
At source `103b65e5a730e0f46676c5646f94832b124e0697`, three selected component checks and seven baseline/import
checks pass; the other 75 source/olean pairs match prior receipts. All eleven
dependency revisions match the manifest and printed axioms are standard.
See `receipts/balance-support-rules-summary.json`. These bounded component checks
are not a clean/full build, canonical registration or independent certification.

## CALL rules substituted throughout withdrawal

`WithdrawalCalls` threads a relational CALL observer through every locator lookup,
status read, allocation query, frame query and receiver. Its final `Describes`
instantiates independent code/funds/transfer/reply rules, with no source stage
executor or Live.call in the expanded relation. Bidirectional exact correspondence
and completeness preserve full return/fault, physical world and direct/nested
attempts. Independent parent consequences still give failure restoration and
successful nonzero amount.

The remaining external boundary is the explicit raw callee interpreter, which must
still be bound to deployed bytecode/primitive behavior and resource/bounded-world
constraints. Other writers, proxy/initialization/report/queue paths, canonical gates
and independent review remain open. At source `03e0f09fd4b228a20e85b592c2a09e107cd8071c`, two selected component checks and seven baseline/import checks pass. The other 74 source/olean pairs match earlier successful receipts. See `receipts/withdrawal-calls-rules-summary.json`; only standard axioms were printed. Eleven dependency revisions match the manifest. These are bounded checks, not full gates. Runtime
execution source and historical receipts are unchanged.

## Independent high-level CALL correspondence

`CallSpec` independently orders target-code validation, balance admission and
execution in the provisionally credited world. No-code and insufficient-funds
paths need no callee observation; only the latter records a failed attempt.
Success retains the callee-returned world and nested calls; rejection restores
the incoming CALL world and preserves rejection bytes/nested attempts. Independent
consequences establish failed-call restoration and successful-call funding/code.

`CallFlow` proves bidirectional exact source CALL outcome/world/trace correspondence
against explicit raw primitive replies, normalizing traced/untraced variants.
Independent pointwise transfer accounting covers aliased self-calls, and the
provisional transfer preserves storage and committed logs. These CALL rules must
still be threaded into all expanded stage predicates; deployed primitive/bytecode
and EVM resource/bounded-world binding remain open, along with other writers and
full integration gates. At source `d2419a20db505dfde80c476407cd8b142c8e30a8`, three selected component checks and seven baseline/import checks pass. The other 72 source/olean pairs match earlier successful receipts. See `receipts/call-flow-rules-summary.json`; only standard axioms were printed. Eleven dependency revisions match the manifest. These are bounded checks, not full gates. Runtime source unchanged.

## Complete allocation flow and internal withdrawal substitution

`AllocationFlowSpec` independently orders lookup, queue CALL, demand decoding and
allocation. Buffer/reserve observations are saved before calls. Success uses the
existing maximal-priority allocation relation; uniqueness connects it to physical
source allocation, without replacing the specification by the executor's min formula.
`AllocationFlow` covers every allocation failure and success with exact returned
world and ordered calls, including arbitrary callee storage changes.

The rules are substituted through spending into `AllocationFlow.Withdrawal`, with
bidirectional exact parent correspondence. All major internal stage interfaces are
now expanded into independent control/arithmetic rules and physical projections.
The remaining source execution boundaries are CALLs: primitive and deployed-callee
binding, resource/world closure, other writers and full integration gates remain
open. At source `7d40b232ff75cf8c2d98a046b91af743278d393a`, three selected component checks and seven baseline/import checks pass. The other 70 source/olean pairs match earlier successful receipts. See `receipts/allocation-flow-rules-summary.json`; only standard axioms were printed. Eleven dependency revisions match the manifest. These are bounded checks, not full gates. Runtime execution source is unchanged.

## Complete frame getter rules substituted through spending

`FrameReadSpec` independently orders oracle lookup, oracle CALL and complete
64-byte tuple validation. `FrameRead` substitutes physical locator/address rules,
projects the two actual ABI words and proves bidirectional exact outcome/world/trace
correspondence. The whole tuple is validated before either field can be returned;
malformed successful replies retain the returned world until parent rollback.

Frame rules are substituted through spending into `FrameRead.Withdrawal`, preserving
bidirectional exact parent correspondence. Allocation remains the opaque internal
interface; CALL/deployed locator/oracle/consensus binding and resource interpretation
remain explicit. Other writers, integration gates and independent review remain open.
At source `107c6310d6d917b14e564a33181e630b5521f2d0`, three selected component checks and seven baseline/import checks pass. The other 68 source/olean pairs match earlier successful receipts. See `receipts/frame-read-rules-summary.json`; only standard axioms were printed. Eleven dependency revisions match the manifest. These are bounded checks, not full gates. Runtime execution source is unchanged.

## Complete spending rules substituted into withdrawal

`SpendSpec` independently orders allocation, amount admission, prepared accounting,
frame evaluation and commit. `Spend` proves bidirectional exact stage correspondence
for allocation failure, insufficient funds, frame failure and success. Actual
physical allocation bounds discharge intermediate checked uint256 arithmetic faults;
uint128 narrowing is retained. Saved next-report accounting and the frame-returned
world are distinct inputs to commit. The raw frame-failure world and ordered traces
are preserved until the withdrawal parent performs full rollback.

`Spend.Withdrawal` replaces spending in the already expanded status/lookup/tail
parent relation with bidirectional exact correspondence. Allocation/current-frame
semantics and CALL/deployed primitive interpretation remain explicit lower interfaces.
Remaining report/queue writers, deployment/resource closure, canonical registration
and full remote gates remain open. At source `3e5611f7cc00c60015750ad4e865f3ae8f842042`, three selected component checks and seven baseline/import checks pass. The other 66 source/olean pairs match earlier successful receipts. See `receipts/spend-rules-summary.json`; only standard axioms were printed. Eleven dependency revisions match the manifest. These are bounded checks, not full gates. Runtime
execution source and historical receipts are unchanged.

## Complete seed/receiver tail rules substituted into withdrawal

`TailSpec` independently describes zero seeds, checked seed update and overflow,
then ordered seed/receiver composition. Seed overflow does not require a receiver
observation; success discards returned receiver bytes. `Tail` binds seed arithmetic
to the physical packed update and full-count event projection, and proves exact
soundness/completeness for every tail outcome/world/trace. Stage worlds are retained
until the withdrawal parent performs transaction rollback.

`Tail.Withdrawal` replaces the opaque tail observation with these rules while
retaining the expanded status/lookup relations and bidirectional exact parent
correspondence. Spending internals and CALL/deployed primitive interpretation remain
explicit direct boundaries; remaining report/queue writers and full integration
obligations are unchanged. At source `f6356dcfdaa54baaf423dc492a5fd241427963c3`, three selected component checks and seven baseline/import checks pass. The other 64 source/olean pairs match earlier successful receipts. See `receipts/tail-rules-summary.json`; only standard axioms were printed. Eleven dependency revisions match the manifest. These are bounded checks, not full gates. Runtime source is
unchanged, with prior executions still attributed to their tested commits.

## Complete locator lookup rules substituted into status and withdrawal

`LookupSpec` independently describes call failure, malformed typed replies and
successful first-word decoding. `Lookup` binds these rules to the physical low-160
locator pointer and explicit first-word/address narrowing, with bidirectional exact
outcome/world/trace correspondence. Successful replies may contain trailing bytes;
malformed replies retain the callee world until the parent performs rollback.

`Lookup.Status` replaces queue lookup with these rules. `Lookup.Withdrawal` replaces
both queue/status and router observations, with bidirectional parent correspondence.
CALL/deployed locator and bunker binding remain explicit boundaries; spending/tail
internals, report/queue writers, deployment/resource closure and full remote gates
remain open. At source `610d88ca8b2fd6bc83a13d741e11fd80ae19d23e`, three selected component checks and seven baseline/import checks pass. The other 62 source/olean pairs match earlier successful receipts. See `receipts/lookup-summary.json`; only standard axioms were printed. Eleven dependency revisions match the manifest. These are bounded checks, not full gates. Runtime source is unchanged.

## Complete status-stage rules substituted into withdrawal

`StatusSpec` independently covers lookup/call failure, malformed ABI data, nonzero
bunker denial, post-call pause denial and allowance. `Status` projects actual bytes
and physical pause storage into these rules and proves soundness, completeness and
bidirectional exact status outcome/world/trace correspondence. The active word is
observed after the bunker call, and bunker denial requires no pause premise.
Failures are stage failures retaining the actual returned world until root rollback.

`Status.Withdrawal` replaces the parent's opaque status observation with these
independent rules; `withdrawal_corresponds` retains bidirectional exact parent
correspondence. Status denial/failure have explicit parent rollback corollaries.
Lookup/CALL primitive and deployed callee binding remain explicit, as do remaining
router/spending/tail interfaces, other writers and full remote integration gates.
At source `17ad2454bfe2b6fea97b076a9f0f078b72ee370a`, three selected component checks and seven baseline/import checks pass. The other 60 source/olean pairs match earlier successful receipts. See `receipts/status-summary.json`; only standard axioms were printed. Eleven dependency revisions match the manifest. These are bounded checks, not full gates. Runtime execution source is unchanged.

## Exhaustive withdrawal parent control relation

`WithdrawalSpec.Executes` is independent of source executors. Its eight ordered
rules cover status failure/denial, router failure, authorization denial, zero
amount, spending failure, success and tail failure. Each stage starts in the
actual prior stage's returned world, the looked-up router is retained, and
unvisited stages need no derivation. Every failure restores the original world
while ordered attempt traces survive. These facts include independent rollback
and successful-nonzero theorems.

`WithdrawalParent` gives soundness, completeness and bidirectional exact
return/world/trace correspondence for the full parent, instantiated with actual
status/router/spending/tail observations. This is exhaustive structural parent
coverage, not discharged independent internals for every stage. Existing concrete
callee/composition proofs must still discharge stage interfaces across all paths;
deployed primitive/resource binding, remaining report/queue writers and canonical
full remote integration gates remain open. At source `48c2b4c9d4dab0beadf6718353af3ff672a198ca`, three selected component checks and seven baseline/import checks pass. The other 58 source/olean pairs match earlier successful receipts. See `receipts/withdrawal-parent-summary.json`; only standard axioms were printed. Eleven dependency revisions match the manifest. These are bounded checks, not full gates.
Runtime execution source and prior execution receipts are unchanged.

## Target continuation: exhaustive after authorization

`TargetSpec.Completes` is an independent generic transaction rule with no source
imports. It covers allowed writes against the actual post-authorization world,
denial, and propagation of every authorization fault; both failing cases restore
the original world and preserve attempted calls. `Target.after_authorization`
proves a bidirectional exact result relation for every authorization result and
arbitrary callback world. `Target.complete` instantiates it with the actual source
query, without a successful-authorization premise. This closes the target parent
continuation, while the authorization result remains a separately specified interface.
`prefix_denied` derives exact APP_AUTH_FAILED/no-call rollback from the independent
initialization/kernel-prefix denial rule. `kernel_no_code` derives exact empty-revert
rollback from physical code absence. These supplement the concrete allowed/denied
ACL composition rather than claiming all deployed authorization failures closed.

At source `01cad617b9692f618a3fa869597967a23720f36f`, three selected component checks and seven baseline/import checks pass. The other 56 source/olean pairs match earlier successful receipts. See `receipts/target-parent-summary.json`; only standard axioms were printed. Eleven dependency revisions match the manifest. These are bounded checks, not full gates. Deployment/primitive/resource binding,
remaining authorization failure paths, external sequence reachability, withdrawal
parent coverage, report/queue writers and full remote integration gates remain open.

## Exact external target success

`Target.committed` describes the physical post-state without invoking an executor:
the target write/event always occurs, reserve lowering/write/event is conditional,
and all other world fields are retained. `Target.success` derives the exact complete
successful external result from independent permission derivation through concrete
Lido/Kernel/ACL dispatch, including the nested authorization trace. `accounting`
connects this state to the independent scalar target rule; other-slot/account and
queue preservation require only the stated distinctness, with no hash-injectivity
assumption. The committed state instantiates the physical sequence relation.

At source `e4858c718d7c3388f6f7f25ea7c251f723989f75`, two selected component checks and seven baseline/import checks pass. The other 56 source/olean pairs match earlier successful receipts. See `receipts/target-summary.json`; only standard axioms were printed. Eleven dependency revisions match the manifest. These are bounded checks, not full gates. Runtime implementations are unchanged.
This closes the exact successful target composition under explicit initialization,
code/pointer and primitive inputs. Exhaustive parent failures, external sequence
reachability, remaining report/queue writers, deployed primitive/resource binding,
canonical registration and full remote gates remain open.

## Ordered ACL permission correspondence and target admission

`ACLPermissionSpec` independently distinguishes absent, unconditional and graph
permissions, then selects specific before wildcard permission. Specific success
or invalid-opcode failure requires no wildcard derivation; only denial falls back,
with ordered trace concatenation. `ACLPermission` projects actual permission slots,
uses the original sender for specific evaluation and ANY_ENTITY for wildcard, and
proves both directions against completed `ACL.hasPermission`. Finite derivations
provide stable sufficient depth without assuming unvisited graphs terminate.

`canPerform_traced` composes these rules through actual Lido→Kernel→ACL dispatch,
retaining the exact nested trace and unchanged permission-call world. `target_allowed`
derives the independent target accounting rule from permission derivation;
`target_denied` derives APP_AUTH_FAILED with full original-world rollback and the
same call trace. Physical initialization/code/pointers and raw static-call
interpretation remain explicit; this is not deployed-bytecode/EVM gas certification.
At source `7f431a39a4ba306a06b02dc273d4b1c79729b9c7`, three selected component checks and seven baseline/import checks pass. The other 54 source/olean pairs match earlier successful receipts. See `receipts/acl-permission-summary.json`; only standard axioms were printed. Eleven dependency revisions match the manifest. These are bounded checks, not full gates. Earlier receipts remain attributed
to their original source commits. Full parent and writer coverage remains open.

## Atomic ACL rules and recursive leaf discharge

`ACLLeafSpec` independently describes block/timestamp/constant/uint240 argument
selection, missing-argument denial before enum conversion, RET/comparison/invalid
enum outcomes, and raw oracle acceptance. It imports no source evaluator.
`ACLLeaf` proves both non-oracle and oracle atomic correspondence, including the
oracle attempt before a later invalid enum and exact trace preservation.
Its physical `Describes` projection invokes only the explicit static-call primitive,
never `ACL.eval`. Soundness, existence and completeness discharge both atomic
premises of `ACLTree.corresponds`; `ACLLeaf.tree_corresponds` now relates the full
finite graph specification to completed source evaluations without a supplied
leaf soundness/completeness assumption. Host exhaustion remains distinct.

This is a proof-only extension. Deployed oracle/primitive interpretation, EVM gas,
full parent coverage and the remaining writer/admission/integration obligations
are still open. At source `bb40d49e8fa6ce9b644e4134d933c752a3b70626`, three selected component checks and seven baseline/import checks pass. The other 52 source/olean pairs match earlier successful receipts. See `receipts/acl-leaf-summary.json`; only standard axioms were printed. Eleven dependency revisions match the manifest. These are bounded checks, not full gates. The initial constructor-name guard failure and its successful fix are retained.
The older conditional tree theorem and historical receipts remain valid.

## Recursive ACL graph correspondence

`ACLTreeSpec` defines finite evaluation of an indexed graph without a fuel
parameter or executor imports. It includes missing/invalid nodes, first-child
failure, short-circuit completion and selected-child success/failure with exact
trace concatenation. Cycles in storage are allowed; only the evaluated paths
need finite derivations. Leaf semantics are an explicit independent relation.

`ACLTree.corresponds` proves both directions between those derivations and
completed source evaluations of the physical graph, subject to stated leaf
soundness/completeness premises. `of_spec_stable` constructs a sufficient depth
from each derivation and preserves the result for larger depths; related
derivations agree on outcome and trace. No global cutoff or global acyclicity
premise is inserted. This closes recursive structure correspondence, while the
leaf premises, primitive/deployment relation and EVM resource binding remain open.
At `35e5c6b1505236744d89ae21dfe81b887f6be266`, ACLTreeSpec, ACLTree
and updated LiveTrust pass, along with all seven baseline/import checks. The other
50 modules' source and olean hashes match prior receipts; inspected axioms are
standard. `receipts/acl-tree-summary.json` links exact evidence. Runtime code is
unchanged; prior executions retain their original source-commit attribution.

## Independent ACL logic control

`ACLLogicSpec` gives a total, unique control relation after the first child:
finish immediately, or visit exactly one selected child with an explicit bool
negation. It covers NOT, AND/OR short-circuiting, XOR and IF_ELSE, plus the source
fallback behavior for other valid enum values used as logic operators. It imports
no executor. `ACLLogic.corresponds` relates that independent control decision to
the exact physical source node, remaining evaluation and concatenated oracle trace.
Unselected children have no execution premises and contribute no attempts.

Separate proofs cover out-of-bounds parameter indices, invalid logic opcodes before
any child evaluation, and propagation of first-child failure with its trace.
These are logic-node correspondence rules; recursive whole-tree and independent
leaf/primitive/resource correspondence remain required. Runtime code is unchanged.
At `bd6f7edb93070e808bda4f45fda54a86c93b8db5`, both new modules and
updated LiveTrust pass, along with all seven baseline/import checks. The other
48 modules' source and olean hashes match prior receipts; inspected axioms are
standard. `receipts/acl-logic-summary.json` links exact evidence. Runtime sources
are unchanged; no fresh execution or full remote gate is claimed.

## ACL capacity stability

`ACLBounds` proves that increasing the evaluator's recursion depth preserves
any completed result, including invalid-opcode failure and the entire ordered
oracle trace. The proof covers parameter evaluation, specific/wildcard permission
selection and the externally visible ACL dispatch reply. Two completed runs at
arbitrary bounds must agree, by extending both to a common capacity. Host
exhaustion stays distinct from denial and source failure throughout.

This closes capacity stability and completed-result uniqueness, not termination
for arbitrary cyclic storage, independent parameter-tree correspondence, or the
relation between host depth and EVM gas/stack resources. Runtime implementations
are unchanged; the 28-case source execution remains tied to its original commit.
At `0e632f4a369f23b918b832be62821cd9a86a8ce5`, ACLBounds and updated
LiveTrust pass, along with all seven baseline/import checks. The other 47 modules'
source and olean hashes match prior receipts; inspected axioms are standard.
`receipts/acl-bounds-summary.json` links exact evidence and confirms runtime
sources are unchanged. No new execution, full remote gate or certification is claimed.

## Physical ACL evaluation and source composition

`ACL` reads specific/wildcard permission hashes and packed parameter arrays from
physical mappings. It implements comparison/RET operators, block/time/constants,
uint240 parameter narrowing, short-circuit NOT/AND/OR/XOR/IF_ELSE, invalid enum
failure and raw oracle STATICCALL. Oracle failures and return lengths other than
exactly 32 deny; raw calls have no high-level code guard. Wildcard evaluation
passes ANY_ENTITY to the oracle. Kernel lifts oracle trace depths through its
nested call. `ACLSpec` independently states comparison and grant rules;
`grants_corresponds` relates successful source parameter evaluations to selection.

The recursive evaluator has an explicit depth bound. Exhaustion is a distinct
host result delegated separately, not a source denial or a claim about EVM gas.
The differential runner rejects exhausted evaluations. Relational parameter-tree
correspondence and termination/resource binding still require proof. `ACLCalls`
composes a terminating source ACL evaluation through Kernel and Aragon; its
unconditional-specific theorem derives admission solely from physical/configuration
conditions, without a supplied ACL or kernel reply.

At `c5858d1f0af9e2132982cce5067f4eceed42857c`, 28 fresh comparisons against
actual inherited ACL/Kernel/Aragon/Lido code pass, including physical layout,
logic short-circuiting, wildcard oracle arguments, malformed oracle replies,
static writes and invalid enum values. Six selected Lean checks, seven baseline/
import checks and pinned ACL compilation pass. The other 42 modules' source and
olean hashes match prior receipts; inspected axioms are standard.
`receipts/acl-summary.json` links exact component/compiler/toolchain/runtime
receipts. Large traces are losslessly archived with verified decompressed hashes;
draft failures and the earlier draft execution remain preserved. This does not
close ACL mutation admission, proxy/deployment/primitive binding, recursive
callback interpretation, all writer sequences or the exhaustive parent relation.

## Concrete Kernel permission forwarding

`Kernel` reads the installed ACL through KernelStorage.apps' two physical
mapping hashes, using an explicit keccak primitive. Zero ACL returns false;
missing ACL code rejects without a nested CALL. Otherwise the source query
forwards the original sender/app/role/empty-parameter bytes with the kernel as
caller, decodes the ACL bool, and retains nested acceptance/rejection/return bytes
and deeper trace depths. Callee world effects remain explicit.

`aragon_from_acl` and `target_from_acl` compose that source behavior through the
Lido role decoder and external target writer. The kernel response is derived;
ACL evaluation is an explicit interpreter boundary in this component, now filled
by ACLCalls for the source path above. The dispatcher is specialized to the complete
argument tuple sent by Lido._auth, with other calls delegated.
At `4917545c7aad3093bfdd6ddfa1dda4ff2cae2618`, ten fresh pinned
Kernel/Aragon/Lido comparisons pass, checking the physical mapping against
Kernel.acl(), final storage/events and direct/nested targets, values, payloads,
acceptance, returned bytes and depths. Three selected Lean checks, seven baseline/
import checks and pinned Kernel compilation pass. The other 41 modules' source
and olean hashes match prior receipts; only standard axioms appear.
`receipts/kernel-summary.json` links exact compiler/source/toolchain/runtime
receipts. Draft failures and the earlier simpler draft comparison are retained.
The remote wrapper hash is unchanged and no supported dependency-bundle tool
was discovered; no new remote job or full-gate result is claimed.

## Aragon target-writer admission

`Aragon` implements the inherited initialization/kernel prefix and the external
Lido target writer's role check. It reads the physical initialization block and
kernel pointer, sends exact hasPermission(sender,self,role,empty-bytes) calldata,
and decodes actual reply bytes. Missing initialization/kernel, missing code,
denial, short replies and kernel rejection are distinct. Failed admission restores
the original world. Successful permission evaluation retains the callee world;
the target writer's independent relation starts from that world, so callbacks
are not silently discarded. `AragonSpec` independently describes the prefix.

Ten comparisons against pinned inherited Lido/Aragon bytecode match, covering
all these cases plus noncanonical nonzero bool and trailing return bytes. The
executed call opcode is CALL. Kernel replies are explicit boundary fixtures;
these historical ten cases do not cover Kernel/ACL source evaluation. The new
ACLCalls composition and 28-case suite above supply that implementation coverage;
parameter-tree/resource, deployment and callback correspondence remain required.

At `5ff24074eb374d5b79287991ece3e5206da95bfc`, all four selected Lean checks,
all seven baseline/import checks and the fresh ten-case execution pass. The other
38 modules' source and olean hashes match prior receipts. Only standard axioms
appear. `receipts/aragon-summary.json` links source/toolchain/commands and terminal
receipts, including artifact/compiler-input verification. Failed draft elaboration,
the failed component check at 0ec3353, and the initial fixture-setup execution
failure are retained. This adds no full remote gate or independent certification.

## Internal writer and committed withdrawal sequences

`SequenceSpec` independently distinguishes target min, rebalance max, and admitted
spending with buffer conservation, saturating reserve debit and unchanged target.
`PhysicalSequence.corresponds` relates arbitrary finite interleavings of the
internal target/rebalance writers and committed withdrawal worlds to this relation.
Each spend reads demand from its incoming physical queue. All storage of distinct
contracts is preserved throughout, so queue IDs, rows and live demand survive.
`concrete_success_step` derives the independent spend transition from the actual
Pipeline withdrawal execution and its raw configuration/numeric conditions.

Target lowering cannot reduce protection; rebalance establishes the explicitly
recomputed partition and may reduce protection. These proofs do not cover ACL
admission, enclosing report execution, queue-changing transitions or exhaustive
parent failures. Their sequence constructors describe internal/committed effects;
they are not a claim that every constructed sequence is externally executable.
At `e47b7d1720dffeb0d09a2aa52e0fd0a5335e0ecf`, SequenceSpec, PhysicalSequence
and updated LiveTrust pass (3 selected checks), along with all seven baseline/import
checks. The other 36 modules' source and olean hashes match prior receipts. Only
standard axioms appear. `receipts/physical-sequence-summary.json` records exact
evidence. Runtime sources remain unchanged; the 51-case execution is still tied
to its original source commit. No new full remote gate receipt is claimed.

## Physical reserve preservation

`PhysicalReserve.success_preserves` connects the concrete `Pipeline.success`
execution to final physical buffer/reserve subtraction and the independent
`PartitionSpec.protectedReserve` equality. It derives admission from the actual
allocation formula and proves every storage cell of a distinct contract survives
the accounting, seed and receiver effects. The resulting live queue read therefore
returns the same demand. No reserve <= buffer or mapping-hash injectivity premise
is added. Queue/Lido namespace separation is explicit. This is forward successful
withdrawal coverage, not an exhaustive parent specification or writer-sequence proof.

At `de68e309d6cef918e7153c971f2396aaa1ec8b2a`, the new module and updated
LiveTrust inspection passed (2 selected checks). Source and olean hashes for the
other 35 component modules match their prior receipts. All seven baseline/import
checks passed; inspected axioms are only propext, Classical.choice and Quot.sound.
`receipts/physical-reserve-summary.json` records this bounded evidence. Existing
51-case runtime evidence remains tied to `4b82879f28d0e1d58a9972a3db92aa5ea225d898`;
runtime sources are unchanged and were not rerun. Full remote gates remain open.

## Concrete withdrawal pipeline

`Pipeline` composes locator, queue, oracle, consensus and receiver implementations.
Physical pointer and code preservation are proved across accounting writes. Its
prefix theorem derives status, immutable router lookup, live allocation, frame
calls and spending from explicit physical/configuration inputs and numeric
checks, with no successful-callee-result premise. The successful withdrawal
returns the exact world including accounting/seed writes, logs, actual ETH
transfer and receiver event. Source receiver rejection and ETH shortage restore
the original transaction world and retain the complete attempted-call trace.
Receiver immutable authorization and code are separate from prefix bindings.

The independent component specifications remain separate from an exhaustive
whole-parent return/revert relation. Constructor/layout/code-body/primitive and
bounded-EVM-world binding, remaining failure coverage, enclosing writers and
sequence invariants remain required. This is a concrete forward source theorem,
not a full certification claim.

The differential runner now uses Pipeline.external for complete unmutated source
configurations and records sourcePipeline per case. Incomplete/adversarial
configurations retain their explicit fixtures. The execution script accepts an
owned receipt directory so fresh evidence cannot overwrite historical receipts.
All 36 Lean modules passed at `2e4b6a50f68077d65a3d716522f9818fafd50073`.
A subsequent test-only commit `4b82879f28d0e1d58a9972a3db92aa5ea225d898` added
full-pipeline receiver rejection and ETH shortage. Every checked Lean source hash
was revalidated unchanged. Fresh execution at that commit passed 51 comparisons
and seven mutant kills; nine cases use Pipeline.external.
`receipts/pipeline-summary.json` links exact source/toolchain/component/execution
evidence, six baseline checks and import-DAG validation (all 0). The earlier
49-case pipeline run and original historical runs remain retained separately.
Full remote gates remain missing; no remote bundle/node/job was created.

## Consensus-to-Lido frame composition

`ConsensusCalls` executes the actual HashConsensus dispatcher under STATICCALL,
using block timestamp and the physical frame word. It derives uint64 reference/
deadline bounds from FrameSpec, decodes the returned reference exactly, and binds
AccountingOracle's checked timestamp to that result. Independent FrameSpec and
OracleSpec relations use the same actual source inputs. Consensus rejection,
missing code, and timestamp overflow preserve the exact nested-attempt distinction:
a successful consensus call followed by oracle overflow remains an accepted
nested attempt inside the outer rejection.

`lido_frame` composes the complete getter path through Lido's physical locator,
immutable oracle lookup, BaseOracle's consensus pointer, source consensus getter,
and both ABI decoders. It returns exact natural reference/time values with the
unchanged world, two direct attempts and one nested STATICCALL. Constructor,
compiler-layout, code/address and primitive binding remain explicit obligations;
this does not establish full deployment or whole-withdrawal specification closure.

All 35 owned modules passed at `a5492850a01aefb8f188f9f172d7172348de1d38`.
`receipts/consensus-binding-summary.json` links exact source/toolchain/commands/exits,
standard-axiom inspection, six baseline checks and import-DAG validation (all 0),
dependency/wrapper identity and source delta. The differential runner and its
previously executed source remain unchanged. Full gates still lack terminal
receipts and supported complete-source/dependency transport.

## Concrete getter and callee binding

`CallResults` now proves all three immutable locator lookups through physical
pointer read, code guard, CALL, byte decoding and address cast. `QueueCalls`
composes locator and actual queue source dispatch: status uses physical bunker/
pause state; demand success and panic are exact; allocation receives the live
physical row difference through ABI decoding. Successful demand is bounded by
uint128 from physical extraction. The independent LiveDescribes relation uses
the same physically related queue state, without cached-demand or monotone-row
premises. These getters preserve the full world and exact direct-call trace.

`OracleCalls` composes locator/queue/oracle dispatch and binds actual Oracle.frame
success/rejection to the enclosing current-frame getter. Successful tuple decoding,
bubbled failures and nested STATICCALL attempts are exact. Code presence and
relevant address separation are explicit input/deployment obligations. Oracle.frame
still takes the read-only consensus interpreter: complete concrete consensus
input/deployment binding and independent whole-parent coverage remain open.

All 34 owned modules passed at `2aa7917f6223628208dd06e835b1be263b7e584b`.
`receipts/concrete-summary.json` links exact source/toolchain/commands/exit evidence,
standard-axiom inspection, six baseline checks and import-DAG validation (all 0),
dependency/wrapper identity and source delta. The differential runner and its
previously executed source remain unchanged; new composition helpers are Lean-checked.
Full gates still lack terminal receipts and a supported dependency transport.

## Spending specification and parent composition

`SpendingSpec` independently relates admitted allocation to untruncated buffer,
post-report, next-report and reserve quantities. `Spending` binds that relation
to actual live queue bytes and the actual frame execution. Exact before/after
worlds retain external effects, packed writes, event order and attempted calls.
Bounds are derived from successful allocation and physical packed reads: admitted
amounts and saved next values are below uint128; accounting additions fit uint256.
Physical uint128 truncation is retained, not ruled out by an unproved invariant.
Allocation failure, insufficiency and frame failure have exact rollback/trace
results; the checked arithmetic cannot add another failure under derived bounds.

`WithdrawalComposition.after_frame` replaces the former successful-spending
premise with actual allocation and frame executions and preserves the router
saved before spending. Spending and late-tail failure restore the original
withdrawal world with the complete attempted-call prefix. This advances source
composition; complete independent parent return/revert specification, full
source-callee deployment/primitive binding, enclosing writers and sequential
invariants remain required. No overall correspondence completion is claimed.

All 32 owned modules passed at `53878264fd7d2030afcf176d398dfe0fa5114271`.
`receipts/spending-summary.json` links exact commands/toolchain/source hashes,
standard-axiom inspection, six baseline checks and import-DAG validation (all 0),
dependency/wrapper identity and the proof-only source delta. Historical runtime
receipts retain their original source. Full remote gates remain missing.

## Getter and withdrawal-tail composition

`CallResults` binds actual locator/frame CALL results to exact return values,
worlds and traces using the ABI lemmas. The concrete queue lookup executes the
immutable locator getter from the physical pointer and its code guard. Frame
adjustment preserves the packed value saved before external calls; short/rejected
frame replies preserve exact failure and attempted-call prefixes.

`WithdrawalTail` factors the final seed/receiver block with a checked source
identity and sequencing law. Zero seeds, successful checked addition, overflow,
physical packing and the seed event are explicit. The successful tail executes
Router.dispatch with its immutable authorization, ETH transfer and receiver event.
After-spend composition retains the previously looked-up router and ordered
prefix traces. Tail failure restores the original withdrawal world, including
earlier callee effects and spending writes/events. Actual prefix executions are
premises of this composition lemma; the independent spending/whole-withdrawal
specification still must discharge them. This is not full parent completion.

All 29 owned modules passed at `3275479a6803833bc6808a7456bf9fecd3e73ebb`.
`receipts/tail-summary.json` links exact component/toolchain evidence, six baseline
checks and import-DAG validation (all 0), dependency/wrapper identity and source
delta. Inspected axioms are only propext, Classical.choice and Quot.sound.
Historical runtime receipts retain their original source; no runtime implementation
changed. Full gates remain missing, with no new remote job/bundle/node identity.

## Admission and ABI continuation

`AdmissionSpec` independently specifies ordered status, caller and nonzero-amount
admission. `Admission` relates successful withdrawal admission to actual queue
lookup, bunker CALL bytes and the physical pause word after that call. It also
relates false status to bunker/pause observations and proves exact early-failure
fault precedence, retained attempted calls and complete transaction rollback.
The external interpreter remains arbitrary; no successful-callee assumption is
introduced. These prefix theorems do not prove the later spending/seed/ETH path.

`ABI` proves byte encoder length, arbitrary-width decode/encode reduction,
bounded exact round trips, and actual `decodeWord` results for the first and
second 32-byte words with arbitrary trailing bytes. This closes the arithmetic
byte-conversion lemma, not full deployment or caller/callee composition.
`LiveTrust` inspects these new theorems. The immutable component checker now
contains 27 modules, all exit 0 at `1a56fc36b89d4acb0368471639f5d89648e8864f`.
`receipts/admission-summary.json` links the terminal component, six baseline and
import-DAG checks (all 0), dependency/wrapper identity, and proof-only source delta.
Axiom inspection reports only propext, Classical.choice and Quot.sound.
Historical 49-case/seven-mutant execution below belongs to source `0fde648`;
this proof-only continuation does not relabel it as current-head execution.

## Oracle and nested-call continuation

Validated implementation source: `0fde6481707ba16f63ff324547bc2761e1d7b136`.
`receipts/oracle-summary.json` records all 24 owned modules (exit 0), 49 matching
executions (exit 0), seven executed mutant kills, six baseline checks (all 0)
and the import-DAG check (0). `component-checks/<source SHA>/receipt.json` and
`oracle-execution-context.json` bind the commands, source/artifact hashes, toolchain
and dependency identities. Compiler input hashes were rechecked after execution.
The exact-source remote full attempt exits 2 while encoding the gitlink; no
remote job, node or completed bundle digest exists for that attempt.

`Oracle` executes the actual BaseOracle physical consensus-pointer read and
typed STATICCALL, checks tuple length, and applies checked timestamp arithmetic.
`Consensus` executes the HashConsensus frame getter from the physical packed
frame configuration and block timestamp. `OracleSpec` covers timestamp success
and overflow; `FrameSpec` independently selects slot/epoch/frame by quotient
intervals, including uint64 projections, and proves uniqueness. The source
success correspondence and oracle whole-world frame properties are checked.

Nested STATICCALL observations now retain request, relative depth, status and
returned bytes through outer rollback. `StaticCall` rejects forbidden state
operations; `Erasure.call_nested_erasure` removes nested instrumentation without
changing call return/world effects. Arbitrary recursive callback semantics and
the full withdrawal parent are not discharged by these components.

The 49-case draft run (`oracle-execute-2`, exit 0) matches actual Solidity and
Lean, including malformed/rejected static tuples, no code, actual SSTORE under
STATICCALL, initial epoch failure, zero frame length, checked timestamp overflow,
and a real frame-boundary accounting reset. The first executed failure exposed
and corrected uint64 frame-span multiplication modeled as uint256; its log is
retained. The expanded final suite adds cached-frame, static-write-success and
wide-frame-span mutants to the earlier four negative controls. Exact immutable
source validation is recorded in the subsequent oracle summary and component
receipts; do not infer full-gate success from a component description.

Solidity inherits complete pinned AccountingOracle and HashConsensus bodies.
Raw setup still bypasses production consensus-pointer/frame writer admissions.
The frame slot comes from compiler storageLayout and is checked against the
harness's inherited slot query. Vector timestamps are checked against the actual
transaction block. Full ABI/physical/deployment composition, admission/writer
and sequence proofs, bounded EVM world relation, canonical integration, remote
full gates and independent review remain open. No parent completion is claimed.

## Current source composition work

Immutable validated source: `df5a6b52d561ffa6014d6cf4cdae48481b398a3f`.
`source-composition-summary.json` records eight component checks (all exit 0),
35 matching Cancun executions (exit 0), and four executed mutant kills.
An out-of-range account-balance input is rejected with expected exit 1. Source,
artifact and compiler-input hashes were rechecked against the immutable source.
The exact-head remote full-source attempt again exits 2 before submission;
node/job/bundle identities are absent because encoding never completed.

`Allocation.successful_queue_observation` now connects the independent maximal
allocation relation to the actual locator result, queue CALL, first ABI word and
saved pre-call physical buffer/reserve locals. Arbitrary callee effects are
allowed; no freshness or preservation premise replaces the live observation.

`Router`/`RouterSpec` implement and check immutable LIDO authorization, exact
NotAuthorized rejection, DepositableEthReceived event and value-CALL effects.
`Locator` models the three immutable getters, with checked exact-selector
replies and no state effects. Pinned Solidity tests inherit these real bodies,
with linked StakingRouter libraries and the repository's 0.8.25 viaIR/Cancun
settings. The in-process test EVM is Hardhat 2.26.3 Cancun. Router forwarding
remains fixture admission; oracle/consensus behavior remains a fixture boundary.

`Transfers` proves sender debit, recipient credit, other-account frame,
self-transfer balance identity and exact ETH conservation. The credit-bound
theorem explicitly requires an aggregate balance bound. Deriving that bound
from a full bounded EVM world remains open. The JSON driver rejects account
balances outside uint256 rather than accepting them as EVM input states.

Receipts `router-execute-1` and `router-execute-2` record respectively 32 and 35
matching executions, each with two executed mutant kills. The expanded driver
adds receiver-authorization and receiver-event mutants. Final component and
execution receipts against immutable source are recorded separately under
`source-composition-immutable` and `router-composition`; consult their actual
exits rather than infer success from this description. Earlier 29-case receipts
and the 32-case comparison are retained. Component checks report standard axioms
only; they use existing imported oleans and are not clean/full build evidence.

The remote wrapper hash is unchanged from continuation-recovery.json. Its
complete-source/dependency transport blocker remains; no new remote job was
submitted. Full gates, complete withdrawal and writer/oracle/sequence composition,
canonical registration and independent review remain required. The older status
sections below retain the prior checkpoint's historical evidence and limitations.

## Continuation after recovery of fa377ac

Recovered exact head `fa377ac1372733b8781255a5e47cfde80f92e9d6` and verified
open draft PR #244 at that SHA. All eleven local dependency heads still match
the pinned manifest. `receipts/continuation-recovery.json` retains the check.

The installed remote wrapper's supported `REMOTE_BUILD_SOURCE_MODE=full`
fails locally with exit 2 on the tracked `lido-core` gitlink: it requires a
regular file. No job or bundle digest was produced. This wrapper also rejects
`.lake` path components and exposes no dependency-bundle transport. The old
remote authentication failure remains infrastructure evidence. Do not treat
either failure as proof failure or completion, or silently omit dependencies.
The wrapper's attempted `--help` was interpreted as build argv and rejected by
the node with HTTP 422 (only lake/lean commands allowed); it was not a build.

`AllocationSpec.lean` adds independent maximality/conservation allocation,
uniqueness, and two-spend protection with separately related queue observations.
Its lightweight Lean elaboration passed (`allocation-spec-2.exit` = 0), using
existing imported oleans. This is not a clean/full-build receipt. The first
elaboration failure is retained. Physical CALL/ABI and queue-writer composition
are still required; this does not close the sequence or withdrawal parent.

The old local gate runner is absent from the current process table; its retained
log has no terminal exit receipt. It is interrupted/unverified, not a live wait
or passing full gate. Heavy validation must use remote-lean-build with complete
source and dependencies once that supported transport is available.

Implementation checkpoint: `b06cf0dc0861b93592f1de80820b68ff10b6905f`.
Own draft: https://github.com/lfglabs-dev/lido-srv3-proof-closure/pull/244
Branch: `trio/reserve1-live-queue`; exact base:
`c7adae04416704a839d56333efad003f0a0f46b7`.
Solidity: `17005714f151e5502c559932319a3f2f74ac2436`.
Verity: `e977aaad6e1a9e92e0132d41b3d33a14135a4d46`.
Lean: `leanprover/lean4:v4.31.0`.

No P-RESERVE-1 parent closure or integration readiness is claimed. All changes
are under the four owned directories. Old declarations, shared Trust/build
configuration, canonical YAML/manifests/reports, and the site remain unchanged.
No other closure/site PR or branch was inspected or modified.

## Checked component properties

- `Live.lean`: handwritten executable with pinned Verity words and
  contract-indexed physical storage, real caller equality against locator router
  reply, live bunker/pause/queue calls, saved locals across external effects,
  compact accounting, actual balances and ETH transfer. External replies may
  reject, return arbitrary bytes, or produce successful world effects. This is
  not yet a complete Verity EDSL/compiled Solidity refinement theorem.
- Independent `QueueSpec.lean` and physical `Queue.StateRel`:
  `Queue.unfinalized_corresponds` proves numeric success or panic 0x11 using
  current last/finalized ids and packed cumulative rows, even malformed rows.
  `cumulative_bound` derives the physical uint128 bound. Keccak is an explicit
  primitive parameter; no freshness, monotonicity or injectivity assumption.
- `PhysicalPacking.pack_matches_bitwise` proves the executor's numeric packing
  equals the actual mask/shift/OR word expression for arbitrary inputs.
  `low_pack`, `high_pack`, `physical_low_bound`, `physical_high_bound` prove
  projections/truncation. They do not imply untruncated arithmetic sums.
- `Erasure.erase_bind`, `erase_pure`, `erase_run` prove compositional erasure
  and rollback commutation. `failure_restores_world` restores all modeled
  storage, balances and committed logs after arbitrary intermediate failure.
  These are interpreter properties, not full Solidity entrypoint correspondence.
- Independent `WriterSpec`: `Writers.target_corresponds` proves buffer unchanged,
  target=requested and reserve=min(old,requested); `rebalance_corresponds`
  proves buffer/target unchanged and reserve=max(old,target). The separate
  `target_observations` / `rebalance_observations` prove success, no external
  calls, preserved balances and exact appended event order. These are INTERNAL
  helper claims; Aragon ACL and report-parent correspondence are open.
- Earlier independent `PartitionSpec.spend_preserves`, `lowering_reserve`,
  `demand_monotone`, `two_spends` and numeric `Packing` lemmas remain. The
  two-spend lemma is for fixed demand and does not prove queue-changing sequences.

The physical reserve may exceed the buffer after rebalance. No global
storedReserve <= buffer invariant is assumed or claimed. Detailed pinned spans,
writer inventory and missing composition are in `SOURCE-MAP.md`.

## Executed evidence

Commands are from repository root; for current runs prepend the private binary
directory `audit/trio/reserve1/.local/lean4-v4.31.0/bin` to PATH.

| Command | Exit / receipt | Scope |
| --- | --- | --- |
| `lake build LidoSRv3.Tests.TrioReserve1.LiveTrust` | 0, `live-trust-final.txt/.exit` | Component modules and owned axiom inspection |
| `lake build LidoSRv3.Audit.Source.TrioReserve1.Writers` | 0, `writers-4.txt/.exit` | Scalar writer spec and observation proofs |
| `lake build LidoSRv3.Audit.Source.TrioReserve1.PhysicalPacking` | 0, `physical-packing-1.txt/.exit` | Bitwise relation and projections |
| `solidity/trio-reserve1/.tools/node-v22.15.0-linux-x64/bin/node solidity/trio-reserve1/compile.cjs` | 0, `solidity-full-queue-compile.txt/.exit` | Inherited pinned 0.4.24 Lido and 0.8.9 queue, source compiler settings |
| Same Node binary, `solidity/trio-reserve1/execute.cjs` | 0, `differential-execute-2.txt/.exit` | 29 matching cases, 2 executed mutant kills |
| Six baseline Python gates | all 0, `resumed-checks.json` | Escape, annotation, inventory, provenance, pin, metadata; not new registration |
| `python3 scripts/check_proof_escapes.py` | 0, `checkpoint-proof-escape.txt/.exit` | After final component additions |

`owned-trust-environment.txt/.exit` records exit 0: the repository dependency
probe independently confirms all 16 new reports against the built
`LidoSRv3.Tests.TrioReserve1.LiveTrust` environment. This is component evidence,
not canonical Trust registration.

Owned axiom inspection reports only standard `propext`, `Classical.choice`,
`Quot.sound`. No new axiom declarations, native decision proofs, or proof escapes.
Retained failed elaboration logs are diagnostics, superseded by named green
receipts, not hidden or interpreted as passing.

Matching inputs/outputs are in `differential-input.json`,
`differential-solidity.json`, `differential-verity.json`; the comparison is in
`differential-comparison.json`. Mutant inputs/outputs and killed comparisons have
parallel `mutation-*` filenames. Source hashes/dependency identities are in
`resumed-source-context.json`; source compiler hash inventory is in
`solidity-compilation.json`.

The differential relation compares exact root return/revert bytes, seven Lido
physical words, current queue ids/bunker/cumulative mapping words, five account
balances, ordered directly Lido-issued target/value/payload calls, and ABI
committed events. Current-row mapping preimages are computed by ethers keccak;
missing preimages fail the Lean driver. Root forwarding/nested callee traces,
gas and deployment size are excluded from this finite comparison.

Cases include live enqueue/finalization, malformed physical cumulative underflow,
unauthorized/zero/pause/bunker, malformed/trailing replies, dirty address/bool
words, 128/256-bit bounds and truncation, stale/current frame, actual ETH shortage,
recipient rejection, failures after writes, target lowering, rebalance above
buffer, and a second spend after queue growth. The two executed mutants replace
live demand with a cached word and omit rollback; both disagree with Solidity.
These are tests, not replacements for correspondence or sequential proofs.

The harness inherits the ACTUAL bunker getter and unfinalized demand. Its raw
setup/internal writer wrappers bypass production admission; locator/oracle/router
fixtures are test boundaries, not production callees or success assumptions.
Successful arbitrary callback effects are allowed by the generic interpreter but
are not covered by the finite differential suite or a full composition proof.

## Toolchains and broader gates

All eleven Lake dependency revisions were rechecked exactly in private,
non-symlink package directories. A private Lean 4.31.0 copy now resides in the
owned `.local/lean4-v4.31.0`; its version and binary hashes are recorded in
`private-lean-toolchain.txt`. The inherited toolchain path vanished during
mathlib cache extraction: `mathlib-cache.txt/.exit` retains that failure.
`mathlib-unpack-private.exit` is 0 after unpacking the already-downloaded cache
with the private toolchain. Node 22.15.0's upstream distribution hash was checked
and retained in `node-toolchain.txt`.

Earlier remote job `72e45c29-b554-4616-9fd2-cd54a38dde96` terminated FAILED,
exit 1: the pinned evmyul Git fetch failed with exit 128 for missing remote
authentication. `remote-resume-original-env.txt` is the terminal receipt.
No duplicate remote build, credential change or security-setting change.

`run-gates.sh` starts one isolated owned validation worktree per immutable SHA,
with a separate copied mutable `.lake`, runs production/test/trust followed by
`make prove` and `make test`, and records each command/exit externally in owned
receipts. It prevents duplicate invocation for the same SHA. Generated proof
reports and mutation-test outputs are confined to that disposable tree.
Current checkpoint gates were launched; terminal outcomes belong in
`full-production-test-trust`, `make-prove`, `make-test` receipts and
`gates-terminal.txt`. Until those terminal receipts exist, these gates are PENDING.

## Remaining required work

1. Full independent withdrawal state/input and return/revert/storage/balance/
   ordered-call/event correspondence, including malformed/rejected results and
   later failure. Component theorems do not discharge this parent.
2. Actual immutable locator, AccountingOracle/BaseOracle/consensus frame, and
   StakingRouter receiver composition (including receiver auth/event), and
   callback/nested-call behavior. No unconditional successful callee premise.
   World balances currently use Nat: relate EVM account-balance bounds and
   value-credit behavior explicitly rather than infer them from small fixtures.
3. Aragon target/pause admissions, initialization/migration, all report/buffer/
   accounting and queue writer surfaces needed by invariants; derive untruncated
   bounds where needed. Sequential queue/rebalance/spending proofs remain open.
4. Complete full gates and retain actual failures. New canonical Trust imports,
   guarantee/source-map/manifest/provenance registration are MISSING under the
   additive-only boundary even if baseline checks pass. Put proposed shared
   edits in owned notes; do not edit shared files without coordinated integration.
5. Keep draft PR updated with immutable source and terminal evidence; no merge,
   self-certification, publication, deployment or Lido contact.

Compiler, runtime and primitive correctness are explicit assumptions. Full
bytecode/gas/full consensus-state truth and cryptographic injectivity are excluded.
