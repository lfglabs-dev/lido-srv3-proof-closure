# P-DEPOSIT-1

> Round 2 (2026-08-21). Product note plus proof audit, arbitrated from GPT 5.6 Pro and Opus 5. Fable 5 was unavailable (data-retention gate). Kimi K3 was not an allowed Task model. No em dashes. Lean is authority.
>
> Post-merge honesty pass (2026-08-23, follow-up to PR #195). Three actionable review findings on the merged head are repaired in place: the pull kill-line is renamed to what it proves (`linked_hypotheses_do_not_bound_the_line_972_product`; the unreachable product is never a settled source pull), the oversized exhibit's theorems drop the deployment wording (`abstract_parent_covers_inputs_the_verity_plane_omits`, `oversized_input_exceeds_word`) and gain the commit-level regression that no in-range input can commit a word-exceeding push (`in_range_commit_is_word_bounded`), and the word-bound gap and the missing n-frame model are split into two separately witnessed disclosures, with the n-frame gap now motivated in range by `manyKeySourceInput` (nine encodable keys, `manyKey_run_commits`, `manyKey_links_source_two_legs`).
>
> Successor-head pass (2026-08-23, PR #205 review r3838278045, P2). The n-frame witness now kernel-checks the composed parent's complete hypothesis set: `manyKey_links_source_two_legs` also proves `Preconditions (nLinks canonicalSourceConfig 4) canonicalState` -- every guard-health flag, distinct modules, `valueMatches` $288 = 9 \times 32$, zero entry balance, funding $288 \le 1000$, and `noWrap` -- at the concrete entry state, instead of only `LinksSource` with the no-wrap inequality. Two regressions pin the entry state down from the other side: `manyKey_entry_state_guards_are_load_bearing` refutes the whole bundle when Lido's ledger is one wei short, and `manyKey_underfunded_entry_reverts_at_not_enough_ether` runs the executable transaction at that underfunded entry and reverts with exactly `NOT_ENOUGH_ETHER` back to the entry snapshot.

The pinned source body of `StakingRouter.deposit` (`StakingRouter.sol` 942 to 997) reads a module's allocation, caps it at the block limit, asks the module for a key batch, pulls ether from Lido, and invokes the beacon deposit helper once per key. This is a source/model description, not evidence that any deployed router or immutable uses exactly one 32 ETH unit per validator: `MAX_EFFECTIVE_BALANCE_WC_TYPE_01` is a configurable immutable (line 65), while the helper's `DEPOSIT_SIZE` source constant is 32 ether (BeaconChainDepositor.sol line 24), and their deployed identity remains open.

P-DEPOSIT-1 verifies that this push conserves ether:

- pull: $\mathrm{depositsValue} = \mathrm{actualDepositsCount} \times \mathrm{maxEBType1}$, with $\mathrm{actualDepositsCount} = \mathrm{publicKeysBatch.length} / 48$
- push: $\mathrm{pushedValue} = n \times \mathrm{DEPOSIT\_SIZE}$
- committed push: $\mathrm{pulled} = \mathrm{pushed}$, so the two independently written formulas agree
- non-conserving deployment ($\mathrm{maxEBType1} \ne \mathrm{DEPOSIT\_SIZE}$): on a nonempty batch the whole transaction reverts at the line 996 assert

These are the two conjuncts of `source_deposit_conserves_and_rolls_back`. `MAX_EFFECTIVE_BALANCE_WC_TYPE_01` is a constructor immutable while `DEPOSIT_SIZE` is the literal `32 ether`, so their equality is a deployment fact.

`NFrame.verity_tx_composes_nframe_deposit` conforms an executable Verity transaction to that source plane under generalized `NFrame.LinksSource`, a caller hypothesis. It is universal over a finite `List Batch`: the proof derives both mapped journals around one pull, proves every exact fold prefix stays below one word, and proves both frame counts equal `batches.length`. The old exactly-two shape remains as the checked `n = 2` specialization. We do not cover the allocation algorithms feeding line 953 (P-ALLOC-1, P-ALLOC-2), the top-up path (P-TOPUP-1), or per-key deposit data roots (P-SSZ-1).

## Proof limitations and recommendations

The abstract parent is an unbounded $\forall$ over `cfg` and `inp`. The Verity parent now quantifies over every finite list whose exact amount fold fits one word. That arithmetic-domain difference remains explicit; there is no longer a hidden finite-arity gap.

`linked_deployment_push_is_word_bounded` proves that `LinksSource` together with the parent's own `Preconditions.noWrap` premise forces the *executable push* $\mathrm{pushedValue} = \mathrm{actualDepositsCount} \times \mathrm{depositSize} < 2^{256}$: the composed claim only ever reaches deployments whose beacon-leg push fits one ledger word, while the abstract parent carries no word bound at all.

That bound is on the push, not on the source pull, and the two are different quantities. The pull at `StakingRouter.sol` line 983 is the line-972 $\mathrm{depositsValue} = \mathrm{actualDepositsCount} \times \mathrm{maxEBType1}$, and neither `LinksSource` nor `Preconditions` relates `maxEBType1` to `depositSize`. `linked_conserving_deployment_pull_is_word_bounded` bounds the pull under the extra hypothesis `ConservingConfig`, and conjunct (d) of the registered parent carries the pull bound with that hypothesis explicit. The kill-line `linked_hypotheses_do_not_bound_the_line_972_product` shows the hypothesis is load-bearing: at a skewed deployment whose `maxEBType1` is the largest `uint256`-encodable value $2^{256} - 1$ (encodability is itself a checked conjunct of the theorem), `LinksSource` and `Preconditions` both still hold and the push is still 160 wei, while the standalone line-972 $\mathrm{depositsValue} = 5 \times (2^{256} - 1)$ formula sits at or above one word. No deployment settles that pull, and none even reaches the line-972 multiplication: the skewed deployment's module allocation is the canonical 256 wei, so its computed cap is $\min 8\,(256 / (2^{256} - 1)) = 0$ and the path turns away at the earlier line-959 `ZeroDeposits` guard — `skewed_pull_witness_turned_away_before_line_972` is the executable regression checking that `run` returns `revertZeroDeposits` on exactly this witness. The guard structure generalizes twice over: the line-969 over-target guard bounds the line-972 product by the module allocation (`line_972_product_le_module_allocation`), so a `uint256`-encodable allocation keeps that product inside one word (`encodable_allocation_bounds_line_972_product`), and at the commit level no input with an encodable module allocation can commit a word-exceeding push at all (`in_range_commit_is_word_bounded`: a committing run passed the line-969 guard, and the line-996 assert makes it conserving, so the committed loop push equals the bounded product). A Solidity 0.8 checked-arithmetic panic at line 972 is therefore unreachable from the encodable domain. The kill-line is about the hypotheses and the computed quantity — an unbounded-`Nat` formula value, never a reached on-chain multiplication — so nothing on this row may be quoted as "every admitted deployment's whole pull fits one word".

`abstract_parent_covers_inputs_the_verity_plane_omits` exhibits the remaining word-domain quantifier gap at `oversizedSourceInput`, the pinned conserving deployment scaled to $2^{256}$ keys *together with* the per-block cap, module allocation, signature batch and depositable ether needed for the model's `run` to reach its commit. `oversized_run_commits` checks that the unbounded model's `run` is not turned away by a guard but commits a $2^{256}$-frame push of $2^{256} \times \mathrm{DEPOSIT\_SIZE}$ wei, so the abstract parent's conservation conclusion fires on that model-level committed outcome rather than vacuously. At that same input no `Inputs` at all satisfies `LinksSource` together with the no-wrap premise, for any entry state. The exhibit is scoped strictly as a quantifier gap of the abstract `Nat` model, not a pinned-source deployment: `oversized_input_is_outside_the_source_domain` checks that its per-block cap, module allocation, batch lengths and depositable ether all sit at or above $2^{256}$, so no `uint256` deployment can encode the call at all, and for encodable module allocations the source's own guards keep the line-972 product inside one word (`encodable_allocation_bounds_line_972_product`) while `in_range_commit_is_word_bounded` keeps every committed push inside one word, so checked arithmetic never panics at line 972 from inside the domain and the word-exceeding commit has no in-range witness.

The list parent `NFrame.verity_tx_composes_nframe_deposit` closes the finite-arity gap, not this deliberate arithmetic-domain gap. Adding an $n$-frame `execute` cannot close the word-domain gap: the executable ledger and `Preconditions.noWrap` bound the aggregate below $2^{256}$ regardless of frame count, and no in-range input commits past it (`in_range_commit_is_word_bounded`). The older two-leg `DepositParentTx` plane remains as a checked specialization: `manyKeySourceInput` (nine keys, every field `uint256`-encodable — `manyKey_input_is_within_the_source_domain` checks all five) commits in the model as nine per-key frames of 288 wei total (`manyKey_run_commits`), and two-leg `LinksSource` still assigns its keys 4 + 5, with the total inside one word, while the *complete* executable precondition bundle holds at the concrete entry state `canonicalState` (`manyKey_links_source_two_legs`, review r3838278045). The admission is load-bearing: with Lido's depositable ledger one wei short, the whole bundle is refuted at the funding premise (`manyKey_entry_state_guards_are_load_bearing`), and the executable transaction at that underfunded entry reverts with exactly `NOT_ENOUGH_ETHER` back to the entry snapshot (`manyKey_underfunded_entry_reverts_at_not_enough_ether`). Closing the word-domain gap still needs the abstract parent restricted to the executable word domain or an unbounded executable model.

Successful `NFrame.Preconditions` prove the list transaction commits. Separately, `wrapping_fold_reverts_without_journal` proves an overflowing exact total fails before either mapped pass emits a frame.

`alloc_derived_linkssource_kill_line_refutes_bridge` still shows raw ALLOC key counts do not imply wei amounts. `DepositNFrameCorrespondence.routerDepositInputs` instead performs the explicit `amount * depositSize` conversion for a `List Spec.Allocation`; it does not merge either ALLOC parent into DEPOSIT. Beacon-address provenance is assumed.

Kill-line `dropped_conservation_assert_breaks_pulled_eq_pushed` is adequate for conjunct 1. Conjunct 2 has no kill-line.

CHECKED does not mean the deployed router conserves ether, that ALLOC feeds this row, that a reverting deposit moves no wei on chain, or that the executable plane covers every deployment the abstract plane states.

Ranked next work: keep `NFrame.LinksSource` explicit and discharge `A-DEPOSIT-CONTRACT` and `A-DEPOSIT-32-ETHER` only from artifacts.

Theorems: `PDeposit1.source_deposit_conserves_and_rolls_back` (registered abstract parent), `PDeposit1.NFrame.verity_tx_composes_nframe_deposit` (list-batch Verity parent), `DepositNFrameTx.nframe_deposit_parent`, `DepositNFrameTx.wrapping_fold_reverts_without_journal`, `PDeposit1.NFrame.two_batch_conjunct_d_is_n_eq_two`, `DepositNFrameCorrespondence.router_links_source`, `DepositNFrameTxMutants.fixed_two_only_refutes_nframe_parent`, `PDeposit1.verity_tx_composes_deposit_conservation_and_rollback` (two-leg specialization), `PDeposit1.linked_deployment_push_is_word_bounded`, `PDeposit1.linked_conserving_deployment_pull_is_word_bounded` and `PDeposit1.abstract_parent_covers_inputs_the_verity_plane_omits` with `PDeposit1.oversized_run_commits` and `PDeposit1.oversized_input_is_outside_the_source_domain`, `PDeposit1.linked_hypotheses_do_not_bound_the_line_972_product` with `PDeposit1.skewed_pull_witness_turned_away_before_line_972` and `PDeposit1.line_972_product_le_module_allocation` / `PDeposit1.encodable_allocation_bounds_line_972_product` / `PDeposit1.in_range_commit_is_word_bounded`, `PDeposit1.manyKeySourceInput` with `PDeposit1.manyKey_input_is_within_the_source_domain`, `PDeposit1.manyKey_run_commits` and `PDeposit1.manyKey_links_source_two_legs` plus `PDeposit1.manyKey_entry_state_guards_are_load_bearing` and `PDeposit1.manyKey_underfunded_entry_reverts_at_not_enough_ether`, `DepositVectors.dropped_conservation_assert_breaks_pulled_eq_pushed` (kill-line).
Assumptions: `A-ABSTRACT-TX`, `A-SOURCE-SHAPED`, `A-VERITY-SCAFFOLD`, `A-DEPOSIT-CONTRACT`, `A-DEPOSIT-32-ETHER`.

## Intent

Lido SRv3's `StakingRouter.deposit` pulls ether from Lido and pushes it to the beacon deposit contract through a finite batch schedule. The guarantee says:

1. **Conservation**: on every committed push of the source-shaped path, the wei pulled from Lido equals the wei pushed to the beacon deposit contract, and the two independently written source formulas agree — line 972's `depositsValue = actualDepositsCount * MAX_EFFECTIVE_BALANCE_WC_TYPE_01` and the deposit loop's `pushedValue`.
2. **Rollback**: a deployment whose `MAX_EFFECTIVE_BALANCE_WC_TYPE_01 ≠ DEPOSIT_SIZE` never commits a mismatched push — on any nonempty key batch the whole transaction reverts at the line-996 assert rather than stranding the difference in the router.

## Modeling

- `A-SOURCE-SHAPED`: the Lean `SourceDepositConfig` / `SourceDepositInput` records are handwritten from the pinned Solidity spans, not extracted from an AST. Arithmetic is unbounded `Nat`; no overflow reasoning is performed.
- `A-ABSTRACT-TX`: the abstract-transaction vocabulary (`TxObservation`) the demoted rollback child is stated against; the EVM plane stays open.
- Facade plane list (wave-5 note): `PDeposit1.guarantee.checkedLayers` still lists `.abstractTx` even though the only abstract-transaction conjunct was demoted in wave 4 (PR #138) to the unregistered child `revert_restores_state_value_and_logs`. The plane list is pinned by `scripts/check_public_claim_surfaces.py` (the `P-DEPOSIT-1` `layers` entry, enforced by regex against the `def guarantee` line of `PDeposit1.lean`) and by the checked-layers example in `LidoSRv3/Audit/AllGuarantees.lean`, so the facade is left unchanged: `.abstractTx` there records that the module still states the (demoted) abstract-tx child, not that any registered conjunct lives on that plane.
- `A-VERITY-SCAFFOLD`: `Contract.run` is a non-certified Verity 4.31 interpreter, not compiled bytecode.
- `LinksSource` bridges the pinned-source model to the executable transaction's inputs. It is data-only and says nothing about the post-state.
- `Preconditions` are the transaction's own executable guards.

## The registered parent

`source_deposit_conserves_and_rolls_back` is the registered abstract parent. Its conclusion has no definitional or vacuous conjunct:

- **Conservation (commit-branch-explicit).** `∀ keys pulled pushed balanceAfter, run cfg inp = .committedDeposits keys pulled pushed balanceAfter → pulled = pushed ∧ depositsValue cfg inp = pushedValue cfg inp`. The claim is deliberately restricted to the committed-push branch: `Outcome.pulled`/`Outcome.pushed` are defined as `0` on every other branch, so the earlier whole-path accessor equality was mostly `0 = 0`. On the commit branch the equality is not definitional either: `committedDeposits` carries arbitrary `Nat`s, and only the line-996 assert gate (`depositsValue ≠ pushedValue → .revertAssertBalanceUnchanged`) forces the two sides to agree.
- **Rollback (non-definitional).** `¬ ConservingConfig cfg → 0 < actualDepositsCount cfg inp → (run cfg inp).reverts = true`. This needs the empty-batch early return at line 978 excluded (`committedNoDeposits_implies_empty_batch`) and the assert gate to exclude a mismatched commit (`committed_implies_conserving`); it is proved, not unfolded from a definition.

The earlier revision's second conjunct — a reverting outcome maps to the abstract `TxObservation`'s `.reverted` result, restoring `before` and erasing committed ETH moves and logs — is **definitional** in this model: `observation` maps `o.reverts` to `.reverted` by construction, and `TxObservation.committedState`/`committedTrace` of `.reverted` are `before`/`⟨[], [], []⟩` by definition, with `after`/`attempts`/`trace` unconstrained free parameters discarded on the revert branch. It is therefore demoted to the unregistered child `revert_restores_state_value_and_logs` (and `SolidityDeposit.reverting_outcome_rolls_back`). The load-bearing rollback evidence is on the executable plane (below).

## Composition

`NFrame.verity_tx_composes_nframe_deposit` quantifies over every `(cfg, inp, inputs, entry)` satisfying generalized `NFrame.LinksSource` and list `Preconditions`. It produces:

- (a) the registered abstract parent for `(cfg, inp)`;
- (b) `ParentConclusion` for actual `execute`: the observed journal is `batches.map moduleEntry ++ [pullEntry] ++ batches.map pushEntry`;
- (c) the word fold equals the exact total, every prefix stays below $2^{256}$, and both frame counts equal `batches.length`;
- (d) the exact executable total equals source `pushedValue`, and under `ConservingConfig` also equals `depositsValue`.

`DepositNFrameTxMutants.three_batch_preconditions` and `honest_three_batch_parent` prove list-parent non-vacuity at arity three. The same witness rejects `executeTwoOnly`, so the list quantifier is load-bearing. The two-leg specialization still has `canonical_composition_witness` on a conserving five-key deployment. `abstract_parent_covers_inputs_the_verity_plane_omits` remains the honest word-domain counterweight: it names an input of the unbounded `Nat` model whose `run` the model commits (`oversized_run_commits`) and where the executable hypotheses are jointly unsatisfiable for every `inputs`. The input is deliberately outside the `uint256` source domain (`oversized_input_is_outside_the_source_domain`).

## Kill-line mutant

The kill-line refutes the registered parent's own predicate on a mutant of the parent's own model. `SolidityDeposit.mutantRun` is the pinned `SolidityDeposit.run` with exactly one branch removed: the line-996 `assert(etherBalanceBeforeDeposits == etherBalanceAfterDeposits)` guard, modelled as the `depositsValue ≠ pushedValue → .revertAssertBalanceUnchanged` branch. Two characterization theorems pin the mutation down exactly: `mutantRun_eq_run_of_assert_passing` (where the assert passes, the mutant is the honest `run`, branch for branch) and `mutantRun_commits_where_assert_fires` (where the honest run hits the assert, the mutant commits the push the honest run rolls back).

On the skewed deployment (`MAX_EFFECTIVE_BALANCE_WC_TYPE_01` = 64 against `DEPOSIT_SIZE` = 32, three keys), `LidoSRv3.Tests.DepositVectors` proves:

- `dropped_conservation_assert_commits_skewed`: the mutant *commits* `.committedDeposits 3 192 96 1096` — 192 wei pulled from Lido against 96 wei pushed to the beacon deposit contract, stranding 96 wei in the router;
- `dropped_conservation_assert_breaks_pulled_eq_pushed` (the cited kill-line): `(mutantRun cfgSkewed inp).pulled ≠ (mutantRun cfgSkewed inp).pushed` — the same `pulled = pushed` predicate as parent conjunct 1, false of the mutant on a committing outcome;
- `dropped_conservation_assert_refutes_commit_conservation`: the same refutation in the parent's exact universally-quantified first-conjunct shape, transported onto `mutantRun`.

The honest `run` on the same skewed deployment reverts at the assert (`revertAssertBalanceUnchanged`), so the kill-line isolates exactly the load the line-996 assert carries in the registered parent.

`LidoSRv3.Tests.DepositParentTxMutants.skipped_lido_debit_breaks_pulled_eq_pushed` remains as **executable-plane sibling evidence**: it patches the Lido debit out of the Verity `DepositParentTx` execute and shows the mutant's own `Observables.pulled` (0) disagrees with its `Observables.pushed` (160). It is evidence about the Verity composition's granularity, not the kill-line for the registered abstract parent, whose predicate lives on `SolidityDeposit.run`.

`LidoSRv3.Audit.Verity.DepositLedgerTx.dropped_assert_commits_nonconserving_deployment` is a **different, disconnected model** and is not this guarantee's kill-line. `DepositLedgerTx` is a standalone single-batch ledger transaction that predates `DepositParentTx`: `PDeposit1.lean` never imports it, the `P-DEPOSIT-1` registry row and reproduction command never build it, and it has no `SourceDepositConfig`/`SourceDepositInput` link (`LinksSource`) into the registered parent at all. It remains a legitimate, independently-useful piece of evidence for its own narrower model; it is kept in the tree but must not be cited as the registered parent's kill-line.

## Blocked follow-ups

- `LinksSource` from ALLOC output only after P-ALLOC-1 and P-ALLOC-2 parents are the live loops. Composing onto +1 MinFirst or planted capacities launders the wrong fill into conservation.
- Beacon-address provenance: named assumption.
- The list-batch executable closes the finite-arity gap. Artifact provenance and the source model's unbounded-Nat domain remain separate limits; this row is a Verity EDSL theorem, not compiled-artifact correspondence. The two-leg `DepositParentTx` plane remains as the checked `n = 2` specialization.

## Reproduction

```
lake build LidoSRv3.Audit.Guarantees.PDeposit1 LidoSRv3.Audit.Verity.DepositParentTx LidoSRv3.Audit.Verity.DepositNFrameTx LidoSRv3.Audit.Spec.DepositNFrameCorrespondence LidoSRv3.Tests.DepositVectors LidoSRv3.Tests.DepositParentTxMutants LidoSRv3.Tests.DepositNFrameTxMutants
```
