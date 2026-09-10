# PR #300 independent exact-head source-correspondence review

## Result

**NOT CLEAN — P-TOPUP-2 remains OPEN.**

Reviewed exact PR head: `e4c92461a393183a6f8fba16409fbb4f54ea521f`.

The source pin asserted by the PR is `lidofinance/core@17005714f151e5502c559932319a3f2f74ac2436`. The review was read-only. The preserved checkout was `/workspaces/topup-batch-review-e4c92461/repo` at that exact head; it was clean when inspected. No remote Lean build was started and no repository file was changed.

## Material reviewed

The full `main...e4c92461` PR range adds 22 files (10,503 lines): the three Lean source/test files, receipt/identity/validation material, the Forge test, and eight retained compiler dependency snapshots. The only substantive code commit is `21377aeef85001b172b9d31af0a0f571976f528c`; head commit `e4c92461` adds retained validation logs only.

Reviewed changed proof sources in full:

* `LidoSRv3/Audit/Source/TopupBatchConsumer.lean` (`sha256 5b44909287b09448f6c3e077532741417b67024e3a8a35e80e99b33e96b220b4`)
* `LidoSRv3/Audit/Guarantees/PTopup2ActualBatch.lean` (`sha256 778d8814bc676bf06572797f743fe0b163220dc7760de9e356bdfb815e932caf`)
* `LidoSRv3/Tests/TopupBatchConsumerRegression.lean` (`sha256 63900134a5a1e5dc06a3f5557110a9d230d676a7af0df6de21786d2b78fd1689`)
* the complete added `audit/topup-batch-consumer` README, receipts, identity manifests, test, logs, and retained dependency snapshots.

I also read the retained pin source at `TopUpGateway.sol:163–236` and `StakingRouter.sol:696–743`, plus the live registered consumers: `PTopup2.lean`, `PTopup2Verity.lean`, `Topup2Tx.lean`, `Topup2Correspondence.lean`, `AllGuarantees.lean`, and the relevant `Trust.lean` axiom-query surface.

## What the new candidate actually establishes

`TopupBatchConsumer.run_success_bound`, re-exported as `PTopup2.actual_module_batch_bound`, has a coherent *separate* successful-batch value path. On one supplied `before : World`, it:

1. runs the gateway witness loop and derives its keys and wei limits;
2. builds the module input from that output;
3. reads the packed uint64 router cap from router slot 5 at bit offset 24;
4. computes the module target as the rounded `min(moduleAllocation, cap)`;
5. invokes and decodes the module return; and
6. uses the router continuation guards to bound the decoded allocation sum by `blockCap * 10^9`.

This matches the relevant local router mechanics, including an arbitrary preceding `moduleAllocation`, and it covers empty/zero successful returns. The retained evidence says the supplied receipt checks passed: 1,292 Lean jobs, 1,536 identity checks, and five Forge tests with the packed-cap fuzz test at 1,024 runs. Those are evidence for this candidate and its retained inputs, not a substitute for the correspondence review.

## Blocking finding: no same-input connection to the registered promise

The requested delivery condition is not met.

`LidoSRv3.Audit.Guarantees.PTopup2.aggregate_bounded_by_block_cap` is still the old abstract-Nat theorem. Its only inputs are `TopupBatch` and `TopupConfig`, and it proves the bound from `transition = consumeBudget (transitionBudget ...) ...`. It contains no `TopupBatchConsumer.run`, no gateway witness output, no actual module CALL or decoded return, no router storage word, no rounded target, and no wei cap. It is not changed by this PR.

`LidoSRv3.Audit.Guarantees.PTopup2.verity_tx_simulates_topup2_spec` is also unchanged. It relates manually supplied `effective`, `pending`, `requested`, and `topUpLimits` arrays decoded from a supplied Verity state to the historic `allocate/sourceView` model. It has no `TopupBatchConsumer.run` input and no relation to the gateway loop's output, actual module-returned allocations, router packed cap, rounded target, or wei units.

The exact syntactic integration result confirms the semantic gap:

* `PTopup2ActualBatch.lean` imports `PTopup2.lean`, then adds a *new* theorem named `actual_module_batch_bound`.
* The only code import/reference to `PTopup2ActualBatch` is the new regression test. Neither `AllGuarantees.lean`, `PTopup2.lean`, `PTopup2Verity.lean`, `Topup2Tx.lean`, nor `Trust.lean` imports or queries it.
* `AllGuarantees` continues to expose the same `PTopup2.guarantee` containing `[.model, .source, .verityTx]`; the new theorem is not made the registered source/Verity consumer.

Thus no theorem makes **the same batch** flow through both sides. Missing is a theorem (and registration/import path) identifying, in one quantifier scope:

`gateway loop output (keys, limits, rows, before-world) = actual module CALL input`;
`actual decoded module allocations = registered aggregate/Verity allocations`;
`packed physical router cap + rounded target = registered cap/budget`; and
`gwei/wei conversion = registered bound`.

Without those equalities, the candidate can bound an actual module reply while the registered `aggregate_bounded_by_block_cap` and `verity_tx_simulates_topup2_spec` continue proving facts about different, caller-supplied abstract inputs. This is precisely the required same-input connection, not a cross-call or nested-history requirement; cross-call history remains outside the registered per-batch promise.

## Axioms and scope

The PR's retained `axioms.json` records the new value-path theorems as using only `propext, Classical.choice, Quot.sound`. Specifically, this is recorded for both `TopupBatchConsumer.run_success_bound` and `PTopup2.actual_module_batch_bound` (with narrower listed subsets for the supporting lemmas and regressions). No new project axiom or proof escape is claimed by that receipt. This observation does not cure the missing correspondence; axiom hygiene and a successfully built separate theorem are not delivery gates.

The stated accepted boundaries remain unchanged: global Solidity compiler correctness, declared Verity semantics, cryptography, general gas, and consensus are outside this review's delivery gate.

## Conclusion

The exact-head PR supplies useful, identity-pinned evidence for a separate actual-module batch bound. It does **not** connect that bound to either registered public P-TOPUP-2 consumer requested by the review. P-TOPUP-2 is therefore OPEN.

VERDICT: BLOCKED
