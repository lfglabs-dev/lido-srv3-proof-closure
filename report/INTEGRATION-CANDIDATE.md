# Sequential integration candidate for PR #918

This is one candidate on `integrate/topup-reserve-alloc-salvage-20260914`.
It requires a fresh independent audit. No source PR was closed, no merge was
performed, and no historical review or build receipt certifies the combined head.
The PR body records the final exact head and its validation results; predecessor
receipts below apply only to the stated SHA and command.

## Preserved work and attribution

The integration started from `1a84e37d9a5ab91dc80de37db6da2a6d90bdb365`.
The untouched handoff manifest and binary patches were inspected before coding:
ADDRESS base `d56a7c40b7d120ac81f26c979195357a2f3262c6`, patch SHA256
`37f9f9ed7067515201163f9ecb80bfdff36c32d8fb0419b8c7fd1a4e07f51b43`;
CONSOLIDATION patch SHA256
`95b4970efc9131f56feaaa0e29e28a9f1e70f3a7855e5a194f0d28e0ccc114e8`.
Their useful composition intent was reused against stronger current producers.
The old ADDRESS journal/metadata-fingerprint edit was inspected, not copied as
proof evidence. Original checkouts and patches remain untouched.

| Source PR | Original head | Integration decision |
| --- | --- | --- |
| #650 | `ebb1064b3d36017afcba177fdf733ac8a8225631` | Omitted: disconnected allocation-list guard. |
| #663 | `3ac8b7d150993d9c0a2d0755f54665691e1147bd` | Omitted: free-boolean wrapper. |
| #665 | `677ad0386810183d36662534d3ff6f6081bad22d` | Omitted: free-boolean wrapper. |
| #668 | `a3ac6cc4ae9f4351d9859e162d3616dae9553e6a` | Retained only three partial prefix checks; renamed honestly. |
| #659 | `06d47d0b5b4bb781a9d664e5c9aa97832c5c6577` | Omitted: independent rollback configuration. |
| #656 | `43623cd9142e5fdcb8a0f9a1f95d4bc39f1bedc9` | Redundant harness variant; useful work retained through #916. |
| #916 | `d93eb7957e66c86a71337071c62a195e79133130` | Retained TOPUP harness, attributed to #414. |
| #672 | `b0eb70165c3b71ab97a966844950f1d42c382c20` | Redundant harness variant; useful work retained through #917. |
| #917 | `f3d2ef392592e24247c4f0f3bfaf5d8994a8c893` | Retained RESERVE harness, attributed to #419. |
| #414 | `af6110cf9c9fabd41ae8c9c462023f7c985590e4` | Original TOPUP harness attribution. |
| #419 | `1652ca68e29cb413263d6a0d09db78399c447659` | Original RESERVE harness attribution. |
| #670 | `9addaf21f6b17617960362ddae274e49427da267` | Packed-buffer arithmetic retained; false seed-count interpretation removed. |
| #671 | `b30f8adfc79280b829d1c74e093c08a5df35da80` | Calldata/selector shape retained; no successful-call producer claim. |
| #674 | `700d21da395a18cdd276b693dbb85aac70248a96` | Incorrect duplicate target writer replaced by actual physical writer consumer. |
| #675 | `0b1a9beae1cb3afdf44c15b13f95936907a76284` | Synthetic queue accumulator omitted; actual physical queue finalization used. |
| #676 | `4342e2c212a38be543f2a39353a69cb5d1335ca1` | Incorrect duplicate synchronization replaced by actual physical writer consumer. |
| #652 | `a4362c13f12beb70c2a61439b880cc79a3cc3e73` | Conditional arithmetic retained; external uint64 premises remain explicit. |
| #653 | `4061464a8726ea9cdd956be951f75058a1a8ad7f` | Conditional arithmetic retained; external uint64 premises remain explicit. |
| #662 | `4751f05656653e5be749f17ff738cd7de8b80e0f` | Invented local counter-writer history and dependent theorem removed. |
| #657 | `7ce8a4e8607cbad721efb5631571a1db1943fe49` | Not additionally integrated; not needed for scoped registered parents. |
| #677 | `7da2ad85bce61576819bbed4f63bd4f95d4622ba` | Inherited observation helper retained as limited evidence; not consumed as live closure. |
| #678 | `d473d2602763109b27c03c630fb257c6b94288d4` | Not additionally integrated; unnecessary. |

Phase-1 corrective commits are `89248a7b`, `1f2c7c79`, and `8e5b4201`.
ADDRESS is `e5e35b5e`/`6f44fcae`; CONSOLIDATION is `d51c1865`;
DEPOSIT is `be77c30c`; TOPUP is `62008e7d`; ALLOC counterexample and
classification are `b0faa116`/`269a10eb`/`2f2316c7`; RESERVE history is
`e4a50820`/`7b22e3a3`/`6044da2b`. SSZ reuses its already integrated parent.

Important reused producers include physical RESERVE writers
`b06cf0dc0861b93592f1de80820b68ff10b6905f`, report accounting
`043a845b5db3ef538eff0cf4e6328f400375ccc8`, physical queue finalization
`e8d8c8964289fb1277c1dd8b8a220be781994c01`, DEPOSIT locator admission
`73c6360efdcd5b25a7188b4ed3de292001128f1d`, TOPUP router admission
`ed043832023c75e04adf76ea05c3ac96f3353897`, and root/call effects
`c0e2fe625f423c3f9b804b64e65d635c5af6d896`.

## Registered statements before and after

The exact declarations in Lean are authoritative. These are statement summaries,
not assertions that the new execution relations imply every legacy abstraction.
Legacy theorems remain available on their stated premises.

| Parent | Before | Candidate executable conclusion |
| --- | --- | --- |
| ADDRESS | Caller-blind admission and source-state renaming, with projection/journal limitations. | Same original conjuncts **and** actual physical claim-batch success chain: address-indexed owners/sets/storage, funded recipient CALL, returned callback worlds, writes/events/attempts; every root failure restores the entry World. Universal address-writer equivariance remains registered unchanged. |
| CONSOLIDATION | Slot-free projection/source correspondence; abstract gateway theorem retained a supplied value boundary and positive-fee/count premises. | `gateway_vault_live_success_and_revert` cases on actual physical-entry execution: outer fee STATICCALL, checked total/refund, produced ABI request, actual value-bearing gateway/vault frame, decoded arrays, independent inner fee STATICCALL, per-request calls and refund; complete success effects or root rollback. |
| DEPOSIT | Bounded NFrame aggregate journal under router-shape and source-link premises. | `actual_deposit_call_slot_success_and_revert` consumes actual locator/DSM, physical module admission/metadata, module reply, Lido withdrawal body and per-key beacon effects, with concrete Keccak; complete effects or root rollback. |
| TOPUP | Source/guarded-return-data simulation with legacy free-input and journal boundaries. | `actual_topup_admission_calls_wei_and_revert` consumes physical gateway/router admission, locator and credentials, root-call execution, module allocation reply, nonwrapping sum, caps/wei conversion, actual withdrawal/per-key calls, history/events and rollback. |
| ALLOC | `checked_execute` under CheckedBounds; live mapped-summary correspondence under length/binding premises. | Statements retained. A decoded ABI-valid `(exited=1, deposited=0, depositable=0)` counterexample rejects unconditional subtraction bounds and yields the executable arithmetic failure. No invented writer history substitutes for external-module invariants. |
| RESERVE | Cache freshness/source partition with limited buffer/queue helpers. | `actual_reserve_physical_history` threads actual target, rebalance, report and withdrawal transactions through returned Worlds. Physical queue finalize/getter dispatch shares concrete Keccak; spending consumes actual queue-return data and its partition; writer balances/events and per-transaction rollback are retained. |
| SSZ | Existing compiled-entry/full-declared-branch parent. | Unchanged and revalidated: executable calldata, root STATICCALL, source-selected fork/gindex, validator encoding and every declared sibling feed the independent branch relation. |

The ADDRESS parent has no singleton actor or boolean batch-success shortcut.
The CONSOLIDATION parent assumes neither desired frame equality nor equal outer
and inner fee quotes; zero-fee behavior is included. Successful callbacks can
change balances or storage, so no false final credit/preservation invariant is
asserted across arbitrary callbacks.

## Remaining obligations

- ADDRESS: global renaming across physical Worlds, code and arbitrary callees;
  other writer-body equivariance; exact error/log encoding and excluded deployed
  interpretation. The actual claim chain is covered, not a whole-deployment theorem.
- CONSOLIDATION: gateway lines 201–207 DSM/precondition, locator and withdrawal-
  credential witness prefix; already-credited outer entry/ABI inputs; memory
  allocation and malformed-ABI ordering. Predeploy body correspondence is external.
- DEPOSIT: upstream allocation/view-call producers, phase-cursor origins and
  configured identities; getter/receiver callee correspondence. Stronger global
  ledger claims still require explicit locator/role and callback contracts.
- TOPUP: outer gateway/router ABI transport and preceding allocation-view calls;
  phase cursors, SSZ configuration and callback implementation identities. The
  actual typed executor is not relabeled a derived outer CALL frame.
- ALLOC: unrestricted uint256 module-summary semantics do not imply uint64 or
  subtraction bounds. Initial/migrated registry invariants, call interleaving and
  physical-slot correspondence remain separate. Conditional #652/#653 results
  do not discharge these external interface obligations.
- RESERVE: configured pipeline identities, target writer's outer ACL/ABI frame,
  and final reserve preservation across arbitrary unknown callbacks. The partition
  is derived at actual spending entry, not assumed as final state after callbacks.
- SSZ: constructor fork/pivot/gindex identity, authentic EIP-4788 history replies,
  and opaque SHA-256/FFI correctness/width. No cryptographic or deployed binding
  follows merely from a structural branch proof.

General Yul/EVM/deployment closure remains excluded. Foundational Lean axioms
`propext`, `Classical.choice`, and `Quot.sound` are distinguished from opaque
semantic interfaces. No project axiom, sorry, admitted conclusion or new native
proof site was introduced. The inherited native inventory remains 436 sites;
its exact retained/moved/deleted records are in
`audit/metadata-reconcile/candidate-native-inventory.json`.

## Validation contract

Pinned source: `17005714f151e5502c559932319a3f2f74ac2436`.
Lean: `leanprover/lean4:v4.31.0`; Verity:
`e977aaad6e1a9e92e0132d41b3d33a14135a4d46`; EVMYul:
`f7e4ee0dc8f8d5265ce822a937ab5be771f182e9`; Mathlib:
`fabf563a7c95a166b8d7b6efca11c8b4dc9d911f`.

Heavy validation uses only registered `dgx-spark` jobs with private mutable
caches. Foundry v1.3.1, ripgrep 14.1.1, solc 0.8.25 and the ARM legacy-solc
fallback are downloaded from pinned sources and SHA256 checked by the runner
scripts. No runtime/auth configuration was copied from old missions.

```sh
REMOTE_BUILD_NODE_ID=dgx-spark REMOTE_BUILD_PASSIVE=1 remote-lean-build lake test -- repository
```

This invokes `make prove`, `make test` and the production/audit library build,
recording separate failures. `make test` includes all five pinned Solidity
MINFIRST/DEPOSIT/TOPUP/TOPUP2/RESERVE differential suites, metadata mutation
checks, proof/trust/provenance/import gates and regression builds. Merely
compiling a differential CLI is not executing its external comparisons.

Predecessor TOPUP job `666c5a01-838a-488f-93cf-e313d3280215` passed 19 tests;
RESERVE job `3f7aabf8-b410-43b2-86dc-acbab3b3d8e5` passed 15 tests. Those
suites include diagnostics of legacy model/source differences; their green
results are not proofs of full source correspondence. Each phase report names
its own targeted receipt. Job `e4196ae8-5e1e-45ca-95b1-ff827398cc03` at
`50d7cf08859e` failed in the inherited TOPUP2 CLI, before differential execution;
its obsolete function arity and missing flag input were repaired explicitly.
At `b5dd0ad9a593e9171e6011a22ed6b584299a933a`, job
`49e7f482-3cdc-40b5-8887-75f3c7984016` passed `make prove` and all five
Solidity differential suites: MINFIRST 4, DEPOSIT 17, TOPUP 19, TOPUP2 19,
RESERVE 15 (74 total, no failures or skips). The remaining repository/audit
stages were still running when this record was prepared; this is not an overall
repository-pass claim. Final combined results, including any failures, belong
to the exact SHA in the PR body and its durable remote receipts. No predecessor success is carried forward
as if it validated a later SHA.

The frozen R1 input hashes and historical report remain untouched. Current
metadata renders `CANDIDATE-ASSURANCE-REPORT.md`, explicitly pending independent
audit. Import layering was repaired by moving consumer-only proofs upward and
reusable execution-effect declarations below public facades, preserving theorem
names/statements. The frozen import ceiling was not widened; the mutable debt
list shrank. These consistency repairs are not counted as proof closure.
