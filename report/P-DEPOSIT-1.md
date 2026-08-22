# P-DEPOSIT-1

> Round 2 (2026-08-21). Product note plus proof audit, arbitrated from GPT 5.6 Pro and Opus 5. Fable 5 was unavailable (data-retention gate). Kimi K3 was not an allowed Task model. No em dashes. Lean is authority.

When the deposit security module pushes a module's keys on chain, `StakingRouter.deposit` (`StakingRouter.sol` 942 to 997) reads that module's allocation, caps it at the block limit, asks the module for a key batch, pulls the matching ether out of Lido, and forwards it to the beacon deposit contract one `DEPOSIT_SIZE` transfer per key.

P-DEPOSIT-1 verifies that this push conserves ether:

- pull: $\mathrm{depositsValue} = \mathrm{actualDepositsCount} \times \mathrm{maxEBType1}$, with $\mathrm{actualDepositsCount} = \mathrm{publicKeysBatch.length} / 48$
- push: $\mathrm{pushedValue} = n \times \mathrm{DEPOSIT\_SIZE}$
- committed push: $\mathrm{pulled} = \mathrm{pushed}$, so the two independently written formulas agree
- non-conserving deployment ($\mathrm{maxEBType1} \ne \mathrm{DEPOSIT\_SIZE}$): on a nonempty batch the whole transaction reverts at the line 996 assert

These are the two conjuncts of `source_deposit_conserves_and_rolls_back`. `MAX_EFFECTIVE_BALANCE_WC_TYPE_01` is a constructor immutable while `DEPOSIT_SIZE` is the literal `32 ether`, so their equality is a deployment fact.

`verity_tx_composes_deposit_conservation_and_rollback` conforms an executable Verity transaction to that source plane under `LinksSource`, a caller hypothesis. The executable path is exactly two batches, and the registered statement now says so itself: conjunct (d) pins the executable journal to the same five frames for every input (two `obtainDepositData` legs, one `withdrawDepositableEther` pull, exactly two `depositToBeacon` legs), pins the probe list to exactly two module ids, and records the 256-bit word bound the hypotheses impose on the linked deployment. We do not cover the allocation feeding line 953 (P-ALLOC-1, P-ALLOC-2), the top-up path (P-TOPUP-1), or per-key deposit data roots (P-SSZ-1).

## Proof limitations and recommendations

The abstract parent is an unbounded $\forall$ over `cfg` and `inp`. Conservation is a commit-branch implication whose live content is mostly `maxEBType1 = depositSize`. The Verity parent is also quantified, but it is not quantified *alike*, and that difference is now checked rather than described.

`linked_deployment_is_word_bounded` proves that `LinksSource` together with the parent's own `Preconditions.noWrap` premise forces $\mathrm{actualDepositsCount} \times \mathrm{depositSize} < 2^{256}$: the composed claim only ever reaches deployments whose whole pull fits one ledger word, while the abstract parent carries no word bound at all. `abstract_parent_covers_deployments_the_verity_plane_omits` exhibits the gap concretely at `oversizedSourceInput`, the pinned conserving deployment scaled to $2^{256}$ keys. There the abstract parent holds in full, and no `Inputs` at all satisfies `LinksSource` together with the no-wrap premise, for any entry state. So `CHECKED` on the Verity row is a finite two-leg claim about a word-bounded window of the abstract row's domain, and closing the gap needs an $n$-frame executable transaction, not a wording change.

`LinksSource` and `Preconditions` (all health booleans true) still make the registered rollback conjunct vacuous: `execute_run` proves success, so the revert antecedent never holds. Real rollback sits in the public hypothesis-free `verity_tx_revert_restores_snapshot`.

`alloc_derived_linkssource_kill_line_refutes_bridge` shows ALLOC parents plus key-count composition still fail `LinksSource.firstAmount`. Keep `LinksSource` as a hypothesis. The two-batch TX is not an unrolling of a multi-module loop: pinned `deposit` is one module, one pull, $n$ beacon frames. Beacon-address provenance is assumed.

Kill-line `dropped_conservation_assert_breaks_pulled_eq_pushed` is adequate for conjunct 1. Conjunct 2 has no kill-line.

CHECKED does not mean the deployed router conserves ether, that ALLOC feeds this row, that a reverting deposit moves no wei on chain, or that the executable plane covers every deployment the abstract plane states.

Ranked next work: keep LinksSource explicit; discharge the named OPEN `A-DEPOSIT-CONTRACT` and `A-DEPOSIT-32-ETHER` provenance assumptions from deployment artifacts; reshape TX to one-module/n-frames or keep stating the two-batch limitation.

Theorems: `PDeposit1.source_deposit_conserves_and_rolls_back` (registered abstract parent), `PDeposit1.verity_tx_composes_deposit_conservation_and_rollback` (Verity composition), `PDeposit1.linked_deployment_is_word_bounded` and `PDeposit1.abstract_parent_covers_deployments_the_verity_plane_omits` (checked statement of the finite executable scope and of the deployments it omits), `DepositVectors.dropped_conservation_assert_breaks_pulled_eq_pushed` (kill-line).
Assumptions: `A-ABSTRACT-TX`, `A-SOURCE-SHAPED`, `A-VERITY-SCAFFOLD`, `A-DEPOSIT-CONTRACT`, `A-DEPOSIT-32-ETHER`.

## Intent

Lido SRv3's `StakingRouter.deposit` pulls ether from Lido and pushes it to the beacon deposit contract in a two-batch loop. The guarantee says:

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

`verity_tx_composes_deposit_conservation_and_rollback` quantifies over every `(cfg, inp, inputs, entry)` satisfying `LinksSource` and `Preconditions`. It produces:

- (a) the registered abstract parent for `(cfg, inp)`;
- (b) executable rollback: every reverting `Contract.run` restores the entry snapshot and leaves the observation idle, including failure injections that revert *after* real storage writes and real journalled frames — this is the load-bearing rollback evidence;
- (c) observable correspondence: the executable transaction reproduces the pinned source observables, and whenever the source model commits its push, its `pulled`/`pushed` are exactly the executable plane's;
- (d) the finite scope of (b) and (c): the journal is the fixed five-frame list with exactly two `depositToBeacon` legs, the probe list has exactly two module ids regardless of `actualDepositsCount`, and the linked deployment's whole pull is below $2^{256}$.

`canonical_composition_witness` discharges both hypothesis bundles on a conserving five-key deployment that actually commits, proving non-vacuity. `abstract_parent_covers_deployments_the_verity_plane_omits` is its dual and is the honest counterweight: it names a deployment where the hypotheses are jointly unsatisfiable for every `inputs`, so non-vacuity is never mistaken for coverage.

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
- The executable transaction is an exactly-two-batch unrolling of the source deposit loop, not a proved bound on the loop. That is now explicit and checked (conjunct (d), `linked_deployment_is_word_bounded`, `abstract_parent_covers_deployments_the_verity_plane_omits`) but does not close it. Closing it requires an `execute` over a list of batches with an inductive journal and observables correspondence, together with a no-wrap argument that survives the fold; the two-leg stage lemmas in `DepositParentTx` do not generalize for free.

## Reproduction

```
lake build LidoSRv3.Audit.Guarantees.PDeposit1 LidoSRv3.Audit.Verity.DepositParentTx LidoSRv3.Tests.DepositVectors LidoSRv3.Tests.DepositParentTxMutants
```
