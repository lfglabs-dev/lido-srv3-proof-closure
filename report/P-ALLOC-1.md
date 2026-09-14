# P-ALLOC-1

The registered parents remain `PAlloc1.checked_execute` and `PAlloc1.verity_tx_simulates_allocation_count_from_storage`. The former proves successful checked execution and equality of its capacity column with MathView under all five `CheckedBounds` fields. The latter consumes mapped summary/stake calls and decoded rows at `allocateLiveFromStorage`, under explicit length/binding premises, and compares persisted model observations with sourceView. Neither claims unconditional success for every reachable router.

At source pin `17005714f151e5502c559932319a3f2f74ac2436`, `contracts/0.8.25/sr/SRLib.sol:374-378` returns external `uint256` exited/deposited/depositable counts. Lines517-522 use those values in checked `deposited - max(externalExited, accountingExited)`. Type2 stake is another external uint256 value (529); subsequent totals, available capacity and target multiplication also use checked arithmetic (532,546,548,552). Router-local uint64 accounting and the32-module bound cannot establish unrestricted reply invariants.

The new `AllocationTxMutants` witness uses an ABI-valid `(1,0,0)` summary. It checks decoding, refutes `CheckedBounds.active_subtraction`, proves sourceExecute failure, and checks ALLOC_ARITHMETIC at the existing live callback/decoder entry. This is a counterexample to deriving unconditional bounds from the interface alone, not evidence that an honest deployed module produces it. The test does not certify exact source call ordering.

The useful conditional arithmetic from #652/#653 remains. The invented #662 addValidators/updateExitedCounters history was removed in phase1; the remaining naming-scaffold comments now identify their premises as external summary relations. No assumed uint64 bound on an external uint256 reply is presented as derived storage behavior.

Explicit remaining obligations:

- External module semantics must establish summary consistency and adequate numeric bounds. Configuration/input bounds, including nonzero maxEBType1, remain explicit. Removing CheckedBounds without these facts would make the successful-execution claim false.
- `bindLiveAll` hoists calls before arithmetic. Solidity interleaves each row's calls and arithmetic; a failure may prevent later calls. Full trace/error-order equivalence remains open.
- Model-local slots/maps and output observation arrays are not physical ERC7201 storage. Packed field decoding and model rollback do not establish general runtime/storage correspondence.
- `_addModule` rejects duplicate addresses (SRLib.sol200-205), while migration copies legacy addresses (101-113). A uniqueness history requires initial/migrated registry evidence and writers; it is not derived by this row.
- Caller getDepositAllocations, P-ALLOC-2, ALLOC-to-DEPOSIT and general deployed Yul/EVM closure remain outside this claim.

## Theorems

Every theorem declared in `LidoSRv3/Audit/Guarantees/PAlloc1.lean`, with its
plane and whether `audit/guarantees.yaml` registers it as a P-ALLOC-1 claim.
Only the two REGISTERED rows are what the `CHECKED` cells in the README and in
`audit/STATUS.md` assert. The unregistered rows build and are cited here, but no
published status cell depends on them, and no fidelity gap is closed by them.

| Theorem (`LidoSRv3.Audit.Guarantees.PAlloc1.`) | Line | Plane | Registered | Role |
| --- | --- | --- | --- | --- |
| `checked_execute` | 108 | Abstract | REGISTERED as `abstract.theorem` | Wave 2 parent. Under `CheckedBounds` the source-shaped executor succeeds and its capacity column equals `MathView.capacities`. Killed by `AllocationTxMutants.capacity_target_kill_line_refutes_parent`. |
| `verity_tx_simulates_allocation_count_from_storage` | 328 | Verity | REGISTERED as `verity.theorem` | Storage-backed live-summary transaction closure: 32-capped stored module count, packed `ModuleStateConfig`, mapped `getStakingModuleSummary` staticcall, WC02 `getTotalModuleStake()` staticcall, `observe` equals `sourceView`. |
| `active_capacity_bounded` | 74 | Abstract | unregistered | `MathView`-definitional child. `Nat.min_le_left` / `Nat.min_le_right` on a definition that already is a clamp (issue 1). Deliberately demoted out of the parent so a kill-line can exist. |
| `source_capacities_match_canonical` | 85 | Abstract | unregistered | The statement `checked_execute` restates under the public parent name. Same proof term; kept separately so the SOURCE-refinement name stays citable. |
| `router_order_preserved` | 279 | Abstract | unregistered | Structural list-map identity: a successful execute retains router index order. Says nothing about capacity values. |
| `source_capacities_and_mapped_summary_transaction` | 288 | Abstract and Verity (composite) | unregistered | Conjoins `source_capacities_match_canonical` with the bounded Phase-3 `mappedSummaryTransaction` slice. Its Verity conjunct is the stub-adversary Phase-3 call, not the registered live-summary path (issue 4). |
| `verity_tx_simulates_allocation` | 305 | Verity | unregistered | Legacy free-`count` sibling. `count` is a harness argument and summary fields are planted, which is exactly what the registered theorem closes (issues 13, 15, 19). |
| `verity_tx_revert_restores_snapshot` | 345 | Verity | unregistered | Every revert of `allocate`, including the injected post-write failure, restores the pre-call snapshot. |
| `checked_execute_under_pinned_shape` | 143 | Abstract | unregistered | Conditional helper: shape plus explicit arithmetic bounds imply the source parent. |
| `checked_execute_under_pinned_shape_and_constants` | 186 | Abstract | unregistered | Conditional helper: pinned constants retain the explicit summary and allocation bounds. |
| `checked_execute_under_type_and_allocation_bounds` | 227 | Abstract | unregistered | Conditional helper deriving checked arithmetic from typed rows and allocation bounds; not a reachability theorem. |
| `checked_execute_under_type_and_available_bounds` | 257 | Abstract | unregistered | Conditional helper using available-capacity bounds; external summary validity remains a premise. |
| `verity_tx_live_revert_restores_snapshot` | 380 | Verity | unregistered | Unconditional rollback of the live storage and summary-call executor. |

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

Lean v4.31.0 and Verity e977aaad6e1a9e92e0132d41b3d33a14135a4d46 are pinned. Earlier phase1 targeted builds passed, but do not validate this new witness or the final combined SHA. Fresh independent audit remains required.

## Account-qualified interleaved producer

The registered Verity parent retains its prior conditional persisted-observation
conclusion and now also consumes `VerityProducer.executeAccount` on the same
world and adversary for all producer inputs. Every count/enumeration/packed word
comes from `readContractSlot state.thisAddress`; `AccountFrame.enter` derives
that projection. The VM executes each STATICCALL and its reply-dependent
continuation before constructing later calls. Success, decoder failure, revert
and arithmetic failure retain their actual source result and transcript;
STATICCALL preserves the physical world. The producer does not cap count at 32.

`Tests.TrioAlloc1.AccountProducer` preserves the ABI-valid `(1,0,0)` summary
counterexample: panic after the first summary prevents both its WC02 stake call
and the next module. A conflicting empty unqualified channel would incorrectly
skip that call. The test hash is only a fixture, not deployment evidence.

This addition does not identify the legacy persisted-output executor with the
new producer. Supported-module reply invariants and reachable CheckedBounds,
actual layout/hash identity, caller context, compiler memory and gas/runtime
correspondence remain open. Independent validation dependency
`I-REVIEW-80FE-FULL-GATE-AXIOMS` remains open; no CLEAN is inferred.
