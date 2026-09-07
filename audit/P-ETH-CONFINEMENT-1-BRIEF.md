# P-ETH-CONFINEMENT-1 brief — unregistered inventory result

`P-ETH-CONFINEMENT-1` is **not registered**. It is absent from
`Guarantees.Id`, from `AllGuarantees.supplemental`, and from
`audit/guarantees.yaml`. This brief records why, what is proved anyway, and
the named source sites inspected. Updating an input pin alone would not justify
registering an execution-level confinement guarantee.

This is not a claim about all SRv3 ETH and it does not discharge any
deployment-provenance assumption.

## Current integration decision (2026-09-07)

Integrate this as auxiliary, unregistered inventory evidence. It is not a
prerequisite theorem for ALLOC-1, ALLOC-2, or RESERVE-1 and is outside the
three-guarantee delivery. The theorem establishes table agreement and an
explicit residual classification, not callee behavior or complete source
coverage. A reviewed input-basis update is possible and is not an audit
certificate. No row is promoted by this integration.

The current merge preserves the already-landed Oracle #232 definitions and
regressions. Candidate modules and mutants are built by the production/test
targets; trust inspection is included separately.

## What is proved

`LidoSRv3/Audit/Guarantees/PEthConfinement1.lean` proves
`modeled_positive_value_is_confined_or_residual` over the model-layer conjuncts of
`LidoSRv3/Audit/Model/EthConfinement.lean`: for every modeled ETH-world
trace, every positive-value authorized frame is either one of three named
residual hops, or is both covered by a registered parent guarantee and landing
on a frozen `Spec.ApprovedDestination`.

Its content is the agreement of three tables written independently of one
another:

1. `EthWorld.ValueRoute.primaryParent` — the E1 coverage table;
2. `EthWorld.Destination.toSpec` — the frozen Spec approval table;
3. `Guarantees.Id.text` — the public guarantee registry.

Agreement between (1) and (2) is what makes the statement refutable rather
than a restatement of one table; (3) forbids naming a covering parent that is
not an actual registered row. `PEthConfinement1.registryId` is the function that
forces `CoveringParent.id`'s free-standing strings to denote real registry
entries.

Two stated limits are theorems rather than prose:
`confinement_does_not_bound_unmodeled_value` (the conclusion holds vacuously
on a trace where 1750 wei of owner/treasury/ops value moves) and
`residual_hops_carry_unclassified_value` (the residual hops are inhabited by
17 wei that no registered parent covers).

Axiom footprint: `propext` only. No `sorryAx`, and no `Lean.ofReduceBool` —
that is, no `native_decide` anywhere in the parent or its mutants.
`audit/trust-native-decide-allowlist.txt` is pinned to the R1 review basis, so
a new native-compiled proof term could not be added to it without presenting a
changed allowlist as R1-reviewed.

## Layering

`scripts/check_import_dag.py` (introduced by the Lake target split, #233)
rejects any model → guarantees import as a new layer inversion, and the
registry binding `CoveringParentsAreRegistered` needs `Guarantees.Id`. The
candidate parent, the four-conjunct `ConfinementConclusion`, and `registryId`
therefore live in `LidoSRv3/Audit/Guarantees/PEthConfinement1.lean`, next to
the registered guarantee modules but imported by none of them.
`LidoSRv3/Audit/Model/EthConfinement.lean` keeps the coverage/Spec agreement,
the exact residual list, route confinement, and the two stated-limit theorems,
and imports no registry. Statements are unchanged; only namespaces moved.

## Integration

This branch incorporates the landed Oracle #232, Lake target split #233,
and allocation refinement #243 from `main`. Under #233 the facade may not
import tests, so `LidoSRv3.lean` imports `LidoSRv3.Audit.Model.EthConfinement`
and `LidoSRv3.Audit.Guarantees.PEthConfinement1` only, and `make test`
compiles `LidoSRv3.Tests.EthConfinementMutants` through `lake build
LidoSRv3Test` rather than through a branch-specific recipe line. Exact-head
build evidence for the integrated head is posted on the PR as a runner
receipt (`lake build LidoSRv3 LidoSRv3Test`).

## Kill-lines

`LidoSRv3/Tests/EthConfinementMutants.lean` edits **one line of each of four
different tables** and refutes the corresponding conjunct. Each mutant is
paired with a positive control proving the copy agrees with production
everywhere except the edited case, so a "kill" cannot come from a
wholesale-mangled table.

| Edited table | One-line edit | Refuted conjunct |
|---|---|---|
| `ValueRoute.primaryParent` | `busToGateway` → `some .pConsolidationOne` | `CoverageAgreesWithSpecApproval` |
| `Destination.toSpec` | `withdrawalPredeploy` → `some .lidoPull` | `CoverageAgreesWithSpecApproval` |
| `residualRoutes` | drop `.gatewayToVault` | `ResidualIsExactlyTheUncoveredInventory` |
| `CoveringParent.id` | `pVaultEthOne` → `"P-VAULT-ETH-2"` | `CoveringParentsAreRegistered` |

Four edits against four tables is the point: the conclusion's content is their
mutual agreement, so no single table can be rewritten to satisfy it alone.

## Registration boundary

The recorded R1 input basis prevents silently presenting changed metadata as
previously reviewed. A reviewed basis update is possible, but it neither proves
source completeness nor certifies the execution. This auxiliary result remains
unregistered. There is no ready-to-register execution-confinement claim here.

## Inspection at the current source pin

The following named sites were re-read at
`lidofinance/core@17005714f151e5502c559932319a3f2f74ac2436` on 2026-09-07.
This is a bounded inspection of eight named files, not an exhaustive census of
all protocol calls or a Solidity-to-model correspondence proof.

| File and call site | Observed value movement |
|---|---|
| [0.4.24/Lido.sol:885](https://github.com/lidofinance/core/blob/17005714f151e5502c559932319a3f2f74ac2436/contracts/0.4.24/Lido.sol#L885) | `withdrawDepositableEther` calls the staking router with `_amount`. |
| [0.4.24/Lido.sol:1099](https://github.com/lidofinance/core/blob/17005714f151e5502c559932319a3f2f74ac2436/contracts/0.4.24/Lido.sol#L1099) | `collectRewardsAndProcessWithdrawals` calls queue `finalize` with `_etherToLockOnWithdrawalQueue`. |
| [0.8.25/lib/BeaconChainDepositor.sol:57](https://github.com/lidofinance/core/blob/17005714f151e5502c559932319a3f2f74ac2436/contracts/0.8.25/lib/BeaconChainDepositor.sol#L57) | The per-validator deposit carries `DEPOSIT_SIZE`; the top-up call at line 106 carries `amount`. |
| [0.8.25/consolidation/ConsolidationBus.sol:403](https://github.com/lidofinance/core/blob/17005714f151e5502c559932319a3f2f74ac2436/contracts/0.8.25/consolidation/ConsolidationBus.sol#L403) | Bus forwards `msg.value` to the consolidation gateway. |
| [0.8.25/consolidation/ConsolidationGateway.sol:220](https://github.com/lidofinance/core/blob/17005714f151e5502c559932319a3f2f74ac2436/contracts/0.8.25/consolidation/ConsolidationGateway.sol#L220) | Gateway forwards `totalFee` to the withdrawal vault; line 302 refunds the supplied recipient. |
| [0.8.9/WithdrawalVaultEIP7685.sol:105](https://github.com/lidofinance/core/blob/17005714f151e5502c559932319a3f2f74ac2436/contracts/0.8.9/WithdrawalVaultEIP7685.sol#L105) | Withdrawal request carries `fee`; the consolidation request at line 115 also carries `fee`. |
| [0.8.9/WithdrawalVault.sol:120](https://github.com/lidofinance/core/blob/17005714f151e5502c559932319a3f2f74ac2436/contracts/0.8.9/WithdrawalVault.sol#L120) | `withdrawWithdrawals` sends `_amount` to immutable `LIDO`, after the caller and amount checks. |
| [0.8.9/WithdrawalQueueBase.sol:529](https://github.com/lidofinance/core/blob/17005714f151e5502c559932319a3f2f74ac2436/contracts/0.8.9/WithdrawalQueueBase.sol#L529) | `_sendValue` sends `_amount` to `_recipient`, reverting on rejection; `_claim` reaches it at line 477. |
| [0.8.9/WithdrawalQueue.sol:253](https://github.com/lidofinance/core/blob/17005714f151e5502c559932319a3f2f74ac2436/contracts/0.8.9/WithdrawalQueue.sol#L253) | The batch forwards the caller-supplied recipient to `_claim`; lines 272 and 285 use `msg.sender`. |

### Remaining gaps

1. **WithdrawalQueue payout is outside the inventory.** The terminal payout
   at `WithdrawalQueueBase.sol:529`, reached by the queue's claim entrypoints,
   matches no `ValueRoute` and has no dedicated `UnsupportedRoute` class.
   Inherited helper behavior cannot be dismissed merely because the helper file
   is not a top-level scope entry. An arbitrary supplied recipient can reject
   or execute code; the table theorem does not model that execution.
2. **Legacy route naming does not establish its source.**
   `vaultToWithdrawalQueue` is retained for compatibility. Its source analogue
   in the inspected path is **Lido → WithdrawalQueue**, not a direct vault
   payment. The model documentation now states that distinction. No executable
   correspondence is obtained by correcting the prose.
3. **A matching call site is insufficient provenance.** `vaultToLido` remains
   `sourceShapedRuntime`: finding `WithdrawalVault.sol:120` does not prove that
   the modeled runtime implements its guards, state changes and calls.

The residual list inside the modeled inventory remains `busToGateway`,
`gatewayToVault`, and `vaultWithdrawalCall`. Naming these three does not
classify the missing queue payout or discharge any callee assumption.

No syntactic absence of particular opcodes is used to infer that dynamically
selected callees, callbacks, or other ETH exits are impossible. This result
has no executed Solidity differential test or full-source correspondence proof.
Its mutations check table agreement, not adversarial contract execution.

## Out of scope

Registering a new guarantee, widening `Spec.ApprovedDestination`, closing the
three-guarantee delivery, claiming bytecode/deployment correspondence, and
bounding all SRv3 ETH are outside this integration.
