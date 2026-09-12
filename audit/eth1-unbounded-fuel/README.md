# P-CONSOLIDATION-ETH-1 — lift the model fuel bound

## CLAIM

- **Guarantee:** `P-CONSOLIDATION-ETH-1`
- **fidelity.missing entry:** `the dispatch-fuel arm quantifies over the model's own dispatcher bound (fuelBudget=32 under A-ABSTRACT-TX); it is a frame-count artifact of the abstract transaction model and carries no deployed gas-metering meaning`
- **Branch:** `grok/lido-eth1-unbounded-fuel-20260912`
- **Base:** `origin/main` @ `1a40db36df3990da9287ac7b03b7e9a1e9bcffe4`
- **Pinned Solidity:** `17005714f151e5502c559932319a3f2f74ac2436`
- **Claimed by:** grok cloud agent, 2026-09-12
- **Status:** closed on this derived consumer — Spark raccord pending
- **Outcome:** (a) derived `verity_tx_success_shape_unbounded`, not (b) contract-faithful 32-bound, not (c) contract/model counterexample

No `spark/*` branch and no open or closed PR already carries this fuel-lift
subject (`ConsolidationEthUnboundedFuel`, `eth1-unbounded-fuel`,
`unbounded-fuel` on P-CONSOLIDATION-ETH-1). Existing `spark/lido-consol-eth1-*`
and `spark/fidelity-reconcile-consolidation-eth-1-*` lots register or reconcile
the *bounded* parent; they do not quantify funded batches past `fuelBudget`.

## Targeted gap

Registered Verity parent
`Guarantees.PConsolidationEth1.verity_tx_universal_success_shape`
(`audit/guarantees.yaml`, P-CONSOLIDATION-ETH-1) requires
`batchSize + 4 ≤ fuelBudget` with `fuelBudget = 32`.  The exhaustion arm at
29+ requests is an artefact of `PConsolidationEth1CompositionTx.step`
(`fuelBudget : Nat := 32`, line 60).  The pinned Solidity does not have that
cutoff:

| Pinned Solidity | Lines | What the source does |
|---|---|---|
| `ConsolidationGateway.addConsolidationRequests` | 185–223 | Role / pause / group count / quota / fee / vault hop / refund. No 32-frame cap. |
| Gateway group loop | 195–199 | `for (uint256 i = 0; i < groupsCount; ++i)` accumulating `requestsCount`. |
| `_consumeConsolidationRequestLimit` | 209, 333–344 | Live *quota*, a different bound, not `fuelBudget = 32`. |
| `WithdrawalVault.addConsolidationRequests` | 199–208 | Gateway check then `_addConsolidationRequests`. |
| `WithdrawalVaultEIP7685._addConsolidationRequests` | 56–73 | `for (uint256 i = 0; i < requestsCount; ++i)` — unbounded in `requestsCount`. |
| `ConsolidationBus.executeConsolidation` | 383–406 | Forwards `{value: msg.value}` to the gateway. `_batchSize` (412–417) is a pending-batch config, not a 32-frame dispatcher. |

So the model bound is not the contract's ETH-plane loop bound.  This lot
does **not** treat `fuelBudget = 32` as source-faithful (outcome (b) is
false).  It also does **not** publish a contract/model divergence vector
(outcome (c)): the pinned path and the parametric dispatcher agree on every
funded, non-wrapping batch once fuel is the derived `batchSize + 4`.

The registered parent, `guarantees.yaml`, and `PConsolidationEth1.lean` are
not edited.

## What is proved

Additive files only:

- `LidoSRv3/Audit/Verity/ConsolidationEthUnboundedFuel.lean`
- `LidoSRv3/Tests/ConsolidationEthUnboundedFuelMutants.lean`
- `audit/eth1-unbounded-fuel/README.md` (this file)

| Theorem | Claim |
|---|---|
| `run_is_runWithFuel_at_fuelBudget` | Registered `run` is `runWithFuel fuelBudget`. |
| `verity_tx_success_shape_unbounded` | `∀` funded, word-sized, non-wrapping, nonzero `batchSize`: `observe (runWithFuel (batchSize+4) honest …) = successShape`. Fuel is *derived* (`n + 4`), not hypothesised. |
| `registered_parent_is_instance_at_32` | On the parent's own `batchSize+4 ≤ 32` slice, `observe (run …) = observe (runWithFuel (n+4) …)`. |
| `registered_parent_recovered_at_32` / `registered_parent_type_recovered` | The registered success statement, obtained as that 32-instance. |
| `unbounded_covers_funded_batch_29` | Funded `(30, 29, 1)` commits at derived fuel 33; the parent premise `29+4 ≤ 32` is false. |
| `truncated_fuel_batchSize_plus_three_exhausted` | Fuel `batchSize+3` exhausts whenever the remainder is positive. |

Proof method: the existing hop lemmas (`hop_bus`, `hop_gateway`, `hop_vault`,
`request_phase`, `hop_refund`) are already parametric in leftover fuel.
`observe_runWithFuel_of_le` runs that chain at `fuel = leftover + (n+4)`.
The unbounded export instantiates `leftover = 0` (`Nat.le_refl`).  Extra
frames are unused after the pending list is empty (`step` success arm).

`fuel ≥ batchSize+4` is **not** a hypothesis of
`verity_tx_success_shape_unbounded`.  A helper that takes a covering fuel is
discharged at the derived amount; that is the AddressClaim-unbounded pattern
(`le_refl` at `length`), not a renamed parent premise.

Mutants (`ConsolidationEthUnboundedFuelMutants.lean`):

- numeral `(10, 2, 3)` at fuel `5 = 2+3` is `.exhausted` and ≠ `successShape`;
- the same fact `∀` funded positive-remainder batches;
- `parent_premise_is_not_the_unbounded_statement` keeps the 29-request
  exhibit from collapsing into the parent.

Axioms of every export: only `propext` / `Classical.choice` / `Quot.sound`
(or a subset).  No `sorry`, no new axioms, no stubs.

## Spark raccord (do not apply in this lot)

Verity modules are listed with `.one` in `lakefile.lean` (not `.submodules`,
so `Audit/Verity/Tests` stays out of the production facade).  Building this
file as a Lake *library* target needs one additive line, after
`PConsolidationEth1CompositionTxUniversalRevert`:

```
.one `LidoSRv3.Audit.Verity.ConsolidationEthUnboundedFuel
```

Do not apply it here.  `LidoSRv3/Tests/` is already `.submodules`, so the
mutant file is picked up by `LidoSRv3Test` once the Verity module is
resolvable (via `lake env lean` or the line above).  No
`audit/guarantees.yaml` edit: after independent review, a later Spark lot
may add a `fidelity.covered` bullet that the dispatch-fuel arm is an
abstract-dispatcher artefact and that `verity_tx_success_shape_unbounded`
quantifies every funded non-wrapping batch at derived fuel.

## Honesty (not this entry)

- Still a model-plane ensemble.  No bytecode, Yul, or deployment claim.
- Live quota (`ConsolidationGateway.sol:209`) and Bus `_batchSize` stay open.
- Word-size / no-wrap / funding / positivity premises stay; only the
  dispatcher `fuelBudget = 32` premise is lifted.
- Zero-remainder batches succeed at `n+3` frames; this lot still *gives*
  `n+4` (one unused frame) so a single derived amount covers both arms.
- Rejecting predeploys, refund/Lido sink failures, and the live
  `executeConsolidation` ABI remain the registered parent's open gaps.

## Validation

- `cwd` = `/workspace` (repo root `lfglabs-dev/lido-srv3-proof-closure`).
- Toolchain `leanprover/lean4:v4.31.0` (`Lake 5.0.0`, Lean commit `68218e876d2a`).
- Solidity pin `17005714f151e5502c559932319a3f2f74ac2436` (Gateway 185–223,
  Vault 199–208, EIP7685 56–73, Bus 383–406).
- `lake env lean LidoSRv3/Audit/Verity/ConsolidationEthUnboundedFuel.lean`: passed.
- `lake env lean LidoSRv3/Tests/ConsolidationEthUnboundedFuelMutants.lean`: passed.
- `#print axioms` of every Verity export: `propext` / `Classical.choice` /
  `Quot.sound` (or a subset). `parent_fuel_premise_excludes_batch_29` uses none.
  No `sorryAx`.
- `lake build LidoSRv3.Audit.Verity.ConsolidationEthUnboundedFuel` is the
  documented raccord (not applied). `LidoSRv3Test` picks up the mutant file
  via `.submodules LidoSRv3.Tests`.

No rebase, force-push, or merge on this branch.
