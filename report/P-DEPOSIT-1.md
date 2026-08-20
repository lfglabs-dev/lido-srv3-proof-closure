# P-DEPOSIT-1

> GPT-5.6 Pro round 1 (ChatGPT UI, 2026-08-20). Voice of the auditor. No em dashes. P-ETH-1 and P-TOPUP-1 notes are missing from this round (ChatGPT UI auth on those slots). P-ALLOC-1 was already written by the owner and is not restated here.

## Auditor note

P-DEPOSIT-1 covers the ETH flow through StakingRouter.depositBufferedEther and depositToModule. The router pulls ETH, divides the work into key batches, then pushes the corresponding ETH to the beacon deposit contract.

source_deposit_conserves_and_rolls_back proves that, for every configuration and input, a committed transition satisfies pulled = pushed and depositsValue = pushedValue. A non-conserving configuration reverts whenever the deposit count is positive. Every reverting transition moves exactly 0 wei.

verity_tx_composes_deposit_conservation_and_rollback transfers these guarantees to the modeled Verity transaction. Its execute path contains exactly two batches. This result depends on LinksSource, which the caller supplies as a hypothesis. It is not derived from P-ALLOC-1 or P-ALLOC-2.

Draft PR #153 makes this boundary concrete with the counterexample between a source containing 1 key and supplied execution legs containing 2 and 3 keys.

## Proof issues and recommendations

The abstract theorem is properly universal over cfg and inp. The Verity theorem is an explicit two-batch unrolling, not a production loop bound. LinksSource remains an assumption.

The clean improvement is either to compose LinksSource from the P-ALLOC guarantees and the router's batch construction, or to keep the public claim explicitly limited to two caller-linked batches. The beacon deposit contract address should come from pinned provenance, not an unconstrained modeled endpoint.


Theorems: `PDeposit1.source_deposit_conserves_and_rolls_back` (registered abstract parent), `PDeposit1.verity_tx_composes_deposit_conservation_and_rollback` (Verity composition), `DepositVectors.dropped_conservation_assert_breaks_pulled_eq_pushed` (kill-line).
Assumptions: `A-ABSTRACT-TX`, `A-SOURCE-SHAPED`, `A-VERITY-SCAFFOLD`.

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
- (c) observable correspondence: the executable transaction reproduces the pinned source observables, and whenever the source model commits its push, its `pulled`/`pushed` are exactly the executable plane's.

`canonical_composition_witness` discharges both hypothesis bundles on a conserving five-key deployment that actually commits, proving non-vacuity.

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
- The executable transaction is an exactly-two-batch unrolling of the source deposit loop, not a proved bound on the loop.

## Reproduction

```
lake build LidoSRv3.Audit.Guarantees.PDeposit1 LidoSRv3.Audit.Verity.DepositParentTx LidoSRv3.Tests.DepositVectors LidoSRv3.Tests.DepositParentTxMutants
```
