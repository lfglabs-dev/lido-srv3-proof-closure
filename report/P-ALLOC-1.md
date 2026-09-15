# P-ALLOC-1

The registered parents are `PAlloc1.checked_execute` and `PAlloc1.account_allocation_result`. The abstract theorem is unchanged: under all five `CheckedBounds` fields, checked execution succeeds and its capacity column equals `MathView`. The Verity parent now consumes the account-qualified interleaved producer directly, without the legacy successful-binding or clipped-count premises. It preserves every producer result and module-call transcript, derives successful capacity equations from executed rows, and follows the public allocation continuation on the same world.

## Source and observations

[SRLib._getModulesAllocationAndCapacity](https://github.com/lidofinance/core/blob/17005714f151e5502c559932319a3f2f74ac2436/contracts/0.8.25/sr/SRLib.sol#L493-L559) reads each summary, checks subtraction, optionally calls the type-2 stake getter, and checks the total before advancing to the next module. The registered producer follows that order and reads count, enumeration and packed fields from the executing account. `AccountFrame.enter` derives its account projection. STATICCALL world preservation does not establish order-independent returndata, errors or gas.

The [public continuation](https://github.com/lidofinance/core/blob/17005714f151e5502c559932319a3f2f74ac2436/contracts/0.8.25/sr/SRLib.sol#L391-L431) consumes the produced arrays and performs checked conversion through the byte-library executor. This is not deployed DELEGATECALL or compiler-memory refinement.

## Legacy relation and counterexamples

`Tests.TrioAlloc1.AccountProducer.RelatedStorage.Related` compares the complete ordered router input fields and count, including the legacy 32-module restriction. It does not assume final-result equality. The matched-storage regression uses the same target/payload-dependent oracle: the legacy binder reaches a reverting stake call, while physical execution stops at the earlier subtraction with `Panic(0x11)`. Explicit error and call observations therefore differ. The honest successful-columns test is a finite positive control, not universal successful-path equivalence.

The original `legacy_commits_while_physical_reverts` is preserved separately: empty unqualified storage coexists with two physical modules. It is a storage-channel counterexample, not a scheduling-only witness. Neither counterexample establishes supported-deployment behavior. All old theorem statements remain available; synthetic persisted arrays and `ALLOC_ARITHMETIC` errors are no longer the registered Verity result.

## NOR producer and writer slice

[NOR summary](../LidoSRv3/Audit/Source/NodeOperatorsRegistry/Summary.lean) derives three uint64 bounds from the loaded packed word, transports them through the router's ABI decoder, and bounds the active count of a successful `firstRow` consuming that reply. Its premise identifies the actual call response; it does not assume the desired decoded values. The getter retains SafeMath's `Error("MATH_SUB_UNDERFLOW")` bytes.

[Packed writers](../LidoSRv3/Audit/Source/Packed64x4.lean) preserve untouched fields. The [NOR exit writer](../LidoSRv3/Audit/Source/NodeOperatorsRegistry/ExitedValidators.lean) includes the target-limit and aggregate-maximum updates, derives admission alternatives, and restores state/events on failure. The equal-value return precedes the deposited-count guard. [Exit invariant preservation](../LidoSRv3/Audit/Source/NodeOperatorsRegistry/ExitedInvariant.lean) derives the exact local/aggregate change and preserves a prestate sum-and-order invariant across every transactional outcome. It then derives exited ≤ deposited for a successful post-update summary. The enumeration is explicit, unique, and includes the selected operator; its binding to registry storage, initialization, other writers, router-accounting synchronization, and compiler slots remain open. No canonical fidelity gap is discharged by this slice alone.

## Remaining obligations

- Derive supported summary/accounting/stake invariants from actual module producers and every relevant writer. The pinned `NodeOperatorsRegistry.getStakingModuleSummary` reads packed uint64 fields and checked headroom; the interface alone gives only uint256 replies. Router accounting checks relate a contemporaneous summary, not arbitrary future replies. The invented #662 history remains removed; conditional #652/#653 arithmetic is retained.
- Connect physical layout/hash and compiled memory/frame execution to pinned source. No universal legacy success equality or full legacy error/trace equality is asserted. Finish inspection and migration of meaningful legacy consumers before deletion.
- Deployment instantiation needs chain/block, actual router/library addresses, runtime bytes/codehash, link map and constructor configuration. These are distinct from modeling work and currently unavailable.
- Preserve caller, ALLOC-to-DEPOSIT and library-composition obligations. The current producer theorem does not close all runtime boundaries.

## Theorems

Every theorem declared in `LidoSRv3/Audit/Guarantees/PAlloc1.lean`, with its
plane and whether `audit/guarantees.yaml` registers it as a P-ALLOC-1 claim.
Only the two REGISTERED rows are what the `CHECKED` cells in the README and in
`audit/STATUS.md` assert. The unregistered rows build and are cited here, but no
published status cell depends on them, and no fidelity gap is closed by them.

| Theorem (`LidoSRv3.Audit.Guarantees.PAlloc1.`) | Line | Plane | Registered | Role |
| --- | --- | --- | --- | --- |
| `checked_execute` | 110 | Abstract | REGISTERED as `abstract.theorem` | Wave 2 parent. Under `CheckedBounds` the source-shaped executor succeeds and its capacity column equals `MathView.capacities`. Killed by `AllocationTxMutants.capacity_target_kill_line_refutes_parent`. |
| `verity_tx_simulates_allocation_count_from_storage` | 336 | Verity | unregistered | Retained legacy persisted-observation theorem with separate physical facts; synthetic slots/errors remain historical model evidence. |
| `account_allocation_result` | 394 | Verity | REGISTERED as `verity.theorem` | Account-qualified interleaved producer: all results, module-call transcript, world preservation, derived successful capacity equations and public continuation. |
| `active_capacity_bounded` | 76 | Abstract | unregistered | `MathView`-definitional child. `Nat.min_le_left` / `Nat.min_le_right` on a definition that already is a clamp (issue 1). Deliberately demoted out of the parent so a kill-line can exist. |
| `source_capacities_match_canonical` | 87 | Abstract | unregistered | The statement `checked_execute` restates under the public parent name. Same proof term; kept separately so the SOURCE-refinement name stays citable. |
| `router_order_preserved` | 283 | Abstract | unregistered | Structural list-map identity: a successful execute retains router index order. Says nothing about capacity values. |
| `source_capacities_and_mapped_summary_transaction` | 292 | Abstract and Verity (composite) | unregistered | Conjoins `source_capacities_match_canonical` with the bounded Phase-3 `mappedSummaryTransaction` slice. Its Verity conjunct is the stub-adversary Phase-3 call, not the registered live-summary path (issue 4). |
| `verity_tx_simulates_allocation` | 309 | Verity | unregistered | Legacy free-`count` sibling. `count` is a harness argument and summary fields are planted, not the registered physical producer. |
| `verity_tx_revert_restores_snapshot` | 429 | Verity | unregistered | Every revert of `allocate`, including the injected post-write failure, restores the pre-call snapshot. |
| `checked_execute_under_pinned_shape` | 145 | Abstract | unregistered | Conditional helper: shape plus explicit arithmetic bounds imply the source parent. |
| `checked_execute_under_pinned_shape_and_constants` | 188 | Abstract | unregistered | Conditional helper: pinned constants retain the explicit summary and allocation bounds. |
| `checked_execute_under_type_and_allocation_bounds` | 229 | Abstract | unregistered | Conditional helper deriving checked arithmetic from typed rows and allocation bounds; not a reachability theorem. |
| `checked_execute_under_type_and_available_bounds` | 260 | Abstract | unregistered | Conditional helper using available-capacity bounds; external summary validity remains a premise. |
| `verity_tx_live_revert_restores_snapshot` | 464 | Verity | unregistered | Unconditional rollback of the live storage and summary-call executor. |

Cited outside this module: `LidoSRv3.Audit.Verity.AllocationTx.bindLiveOne_decodes_summary`
(one-call ABI bridge, unregistered),
`LidoSRv3.Tests.AllocationTxMutants.capacity_target_kill_line_refutes_parent` and
`summary_field_order_kill_line_refutes_decoder` (kill-lines, not claims), and
`LidoSRv3.Audit.Guarantees.PAlloc1EugeneBound.checked_amount_le_bond`, which is
registered under the separate supplemental row `P-ALLOC-1.eugene-bound` and not
under P-ALLOC-1 (issue 18).

Assumptions: `A-SOURCE-SHAPED`, `A-VERITY-SCAFFOLD`.

## Validation

Targeted validation at `b0faa1161e7b3c3aad36839c7e492bd9ec39d100` (job `425295b7-1e7a-467f-aad4-dd9bf1a93ae2`) found two test syntax errors. Commit `269a10eb` fixes the record-update layout and comment before #guard. Corrected validation passed at `2f2316c769b7e5fc3921e473679238ad15b007c4`, job `36947603-d597-4506-9f41-619405ae6fd4` on dgx-spark, exit0 (1,235 jobs), with this command:

```sh
REMOTE_BUILD_NODE_ID=dgx-spark REMOTE_BUILD_PASSIVE=1 remote-lean-build lake build LidoSRv3.Audit.Guarantees.PAlloc1 LidoSRv3.Audit.Verity.AllocationTx LidoSRv3.Tests.AllocationTxMutants
```

Those historical runs used Lean v4.31.0 and Verity e977aaad6e1a9e92e0132d41b3d33a14135a4d46. The current dependency pin is recorded in `proofs/LOCKFILE.md`. Earlier phase1 targeted builds passed, but do not validate this new witness or the final combined SHA. Fresh independent audit remains required.


Current migration and matched-storage tests require targeted and final exact-SHA validation; the historical receipts above do not validate them.
