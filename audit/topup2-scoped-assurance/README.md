# TOPUP-2: successful allocation bound, within one batch

This dossier records why the already integrated public theorem closes the
registered per-batch allocation promise. It adds no Lean theorem, axiom,
execution restriction or assumption. It does not certify TOPUP-1 conservation.
The initial independent scope review is retained beside this file. The exact
candidate containing this dossier still requires independent review before
integration and before the site records delivery.

## Promise and consumer

For one successful batch, the mathematical sum of the module's returned
allocations is at most the router's stored cap multiplied by one gwei.
The public consumer is
`LidoSRv3.Audit.Guarantees.PTopup2.actual_module_batch_bound`.
Its execution premises are `TopupBatchConsumer.run = .ok result` and
`result.outcome = .ok ()`. Its conclusion identifies the actual module CALL,
raw response, decoded allocations and their mathematical sum. It does not
bound arbitrary additional transfers by an external module.

This is the existing per-batch promise, not an accumulated allowance over
successive or nested calls. The pinned router does not subtract a same-block
remainder in `topUp`. The historical greedy allocator is not an implementation
of the arbitrary module's allocation policy and is not needed by this result.

## Pinned Solidity and the necessary value connection

Pin: `17005714f151e5502c559932319a3f2f74ac2436`, repository
`lidofinance/core`. The source identities in `source-verification.json` were
checked against the git objects at this pin, not only against working files.

| Necessary obligation | Source and consuming proof |
| --- | --- |
| Count cannot make the unchecked sum wrap | `TopUpGateway.sol:163–181` rejects an empty or mismatched batch and bounds its count by the stored uint64 `maxValidatorsPerTopUp`. `TopupBatchConsumer.run` executes `checkLengths`; `run_success_exact_effects` derives the count bound from its success. |
| Limits are bounded values actually used by the router | `TopUpGateway.sol:195–236` builds `pubkeys` and `topUpLimits` in the witness loop, then passes these same arrays in `stakingRouter.topUp`. `_evaluateTopUpLimit:399–420` returns zero or a headroom bounded by the uint64 target, with checked balance addition. Calling it from an unchecked block does not make its function body unchecked. The model's `loop_spec` derives the limits; `moduleInput` supplies them to both the module payload and `continuationInput`. No independent limits are admitted. |
| Physical field widths are derived, not initialization premises | `TopUpGateway.Storage` puts count at bit 0 and target at bit 160 of its first word, minimum at bit 0 of its second word. `readConfig` masks these uint64 fields for every initial word. `SRTypes.RouterState` puts the cap at bit 24 of slot 5. `blockCap` reads and masks that field for every initial word. No invariant restricting reachable words is needed for these width facts. |
| Target uses the cap at the source read point | `StakingRouter.sol:696–709` reads the cap, multiplies by one gwei, takes the minimum with the module allocation, then rounds down. `target_bound` proves this for every uint256 module-allocation result. The omitted allocation calculation need not satisfy ALLOC-1 or ALLOC-2 for this inequality. The preceding gateway validation and router view calls cannot write the selected configuration: their external calls are view calls, and the gateway history write is after `stakingRouter.topUp` returns. |
| Module-selected allocations are consumed, rather than a synthetic policy | `StakingRouter.sol:717–720` calls the module at the packed address with target, keys, indices, operators and limits. `TopupModuleCall.call` reads that address and serializes these arguments; its raw response decoder supplies the actual continuation. Arbitrary module effects and an arbitrary response are allowed, with no frame or policy premise. |
| The unchecked sum equals the mathematical sum before comparison | `StakingRouter.sol:723–743` checks alignment, each allocation against the corresponding limit, and then the accumulated total against the rounded target. `guardSum_spec` derives these guards; `router_unchecked_sum_exact` uses the executed count/limit bounds to prove no wrap. The number of accepted allocations is at most the gateway's uint64 count and each is at most a uint64 target times 10^9, so the total is strictly below 2^256. The final comparison therefore bounds the mathematical sum, not merely its residue. |
| Public composition | `run_success_exact_effects` follows the same raw CALL, decoder and continuation, including empty/zero replies; `run_success_bound` projects the bound and the public theorem consumes it. Both `AllGuarantees` and `Trust` import/query this theorem. There is no successful-stage, exact-total, no-wrap, count or callee-preservation premise. |

The mapping above is a source review of the selected successful value path;
the Lean theorem is over that source execution model. It does not claim a
formal simulation of every gateway/router bytecode path. Solidity's typed
array transfer supplies the same selected values; general correctness of the
pinned compiler remains the previously accepted boundary. This review checks
which arrays, widths, operations and calls are transcribed, rather than using
compiler trust to excuse an omitted necessary calculation.

## Scope decisions and remaining external boundaries

Admission roles, pause, timing and root age can reject the call before this
value path. Their truth is not needed to upper-bound allocations that pass
the executed sum check. Witness authenticity can also reject a batch; the
arithmetic bound follows for every typed witness admitted by the model's
checks, independently of whether the root oracle authenticates real consensus
state. The cryptographic and consensus boundaries are unchanged.

Full-entry ABI/error/LOG correspondence and announced rollback are not proved
by this theorem. The documented no-code attempt-trace difference and compiler
allocation failure for oversized return arrays remain unresolved for claims
about those observations. They cannot create a successful source batch with
an excessive mathematical sum: no-code returns fail decoding, allocation
failures revert, and every successful return must pass the same count/limit
and sum checks. These are exclusions from this successful allocation promise,
not closures of error or rollback obligations required by another guarantee.

The positive continuation's `Pipeline.Bound` and its preservation through the
module remain TOPUP-1 obligations. They are not premises of this bound, and
neither the module's arbitrary storage/ledger effects nor this dossier prove
them. No new deployment, hash-injectivity, gas, compiler or Verity assumption
is introduced. Existing general boundaries retain their accepted scope.

## Verification and limits of the evidence

`validation-reuse.json` records byte comparisons with the integrated proof
and the receipts from PRs #300, #306 and #308. The current theorem's axiom
query reports only `propext`, `Classical.choice`, `Quot.sound`; the full
accepted trust inventory remains 29 exact axioms. No proof or dependency was
changed for this scope correction, so these builds are reused, not repeated.
The existing Solidity tests exercise selected count/width, arithmetic and
module-prefix cases; they are not a full contract refinement or exhaustive
proof. The universal successful bound is the Lean theorem just identified.

Registry generation and its mutation checks are rerun for this candidate.
Other guarantees and their limitations are preserved. This dossier is
evidence for the structured roadmap, not a second delivery queue.

## Exact-candidate review correction

The first exact review accepted the unchanged proof and necessary source
connection but rejected candidate `131ae229` because the exported summary,
classification and next gate still described the historical allocator. The
corrected exporter derives those display fields from a main result with no
missing internal obligation. It preserves the original three fields under
`legacy_display` and explicitly labels the retained theorem pair, fidelity
and boundary fields as historical model evidence. Other records are unchanged.
The full rejection is retained in `first-candidate-review.md`; this correction
requires a new exact-candidate review before integration.
