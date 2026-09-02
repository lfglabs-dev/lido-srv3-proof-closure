# P-ETH-CONFINEMENT-1 brief — candidate parent, blocked registration

`P-ETH-CONFINEMENT-1` is **not registered**. It is absent from
`Guarantees.Id`, from `AllGuarantees.supplemental`, and from
`audit/guarantees.yaml`. This brief records why, what is proved anyway, and
the exact row that becomes registerable once the registry reopens.

This is not a claim about all SRv3 ETH and it does not discharge any
deployment-provenance assumption.

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

This branch is stacked in dependency order behind #232 (Oracle), which carries
#233 (the Lake target split) and `main` at UX1. Under #233 the facade may not
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

## Blocker: the R1 review basis freeze

Registering the row is blocked by a mechanism that exists precisely to stop
what registering would do.

`scripts/audit_metadata.py` pins

```python
R1_REVIEW_BASE = "25fbc6e0493948a866a49cda2962d3e897fa00e3"
```

and hashes three inputs — `audit/guarantees.yaml`, `audit/source-map.yaml`,
`audit/trust-native-decide-allowlist.txt` — so that a changed registry cannot
be presented as though it carried the R1 review.

Reproduction. On a clean tree:

```
$ python3 scripts/audit_metadata.py check
audit metadata v4 ok: 11 canonical guarantees + 18 subordinate evidence rows
```

Append the schema-valid row below to `audit/guarantees.yaml` and add
`"P-ETH-CONFINEMENT-1"` to `SUBORDINATE_IDS` in `scripts/audit_metadata.py`,
then:

```
$ python3 scripts/audit_metadata.py check
audit metadata error: R1 review basis input family differs for audit/guarantees.yaml
```

This is not a schema defect that a better-formed row would clear. The digest
covers the file, so *any* edit to `audit/guarantees.yaml` trips it. The check
compares both the historical `git show` digest at `R1_REVIEW_BASE` and the
current canonical bytes.

Corroboration that this is intended and not an accident: `R1_REVIEW_BASE` was
introduced only in commit `68c69d9` (PR #226), postdating every prior
guarantee addition, and `audit/R1-FINAL-AUDITOR-REPORT.md:51` publishes ETH
confinement as a non-claim —

> **ETH confinement:** `P-ETH-JOURNAL-1` is a modeled journal exclusion
> result, not global ETH confinement across live contracts, arbitrary calls,
> or deployment state.

Adding a registry row now would present a changed registry as carrying the R1
review while the published R1 report says the opposite. So the theorem lands
as an explicitly unregistered candidate parent, and no public claim surface
asserts it. `scripts/check_public_claim_surfaces.py` is untouched: its
`CLAIMS` table covers only `P-DEPOSIT-1` and `P-TOPUP-1`.

Registry reopening is the gate. It is not a Lean problem — the theorem is
complete and kernel-checked today.

## Unclassified and defective hops

A site-by-site read of the fourteen in-scope files at pinned
`lidofinance/core@af095e48bbc1c3841c2c9936219c8461af01056b` found that the
eleven-route inventory is **not source-complete**. The confinement statement
is therefore scoped to `ValueRoute`, not to the Solidity.

**1. UNCLASSIFIED — WithdrawalQueue claim payout.**
`contracts/0.8.9/WithdrawalQueueBase.sol:529` (`_sendValue`, L525–531),
reached from in-scope `contracts/0.8.9/WithdrawalQueue.sol:253`
(`claimWithdrawalsTo`), `:272` (`claimWithdrawals`), `:285`
(`claimWithdrawal`), each via `_claim` (L460–480, calling `_sendValue` at
L477).

```solidity
(bool success,) = _recipient.call{value: _amount}("");
```

`_recipient` is an arbitrary caller-supplied address. This is the terminal leg
of the withdrawal path: ETH deposited by `Lido.sol:1101` leaves the protocol
here. It matches **no** `ValueRoute` (no route has the WithdrawalQueue as
source) and **no** `UnsupportedRoute` exclusion class — it is not an
`ownerWithdrawal` (the claimant is an NFT holder, not a vault owner), not
`stVaultInternal`, not a `valueBoundedExit` (a claim payout, not a validator
exit), not `governanceLifecycle` (permissionless, no role gate), not
`fallbackReceive` (inbound-only class), and not `treasuryMint`/`opsTransfer`.

Scope-boundary caveat, stated rather than resolved: `WithdrawalQueueBase.sol`
is not itself in the in-scope path list. Read as "text inside the fourteen
listed files" it is out of scope; read as "the deployed contracts those files
name" it is in scope, since `WithdrawalQueue.sol:34` inherits it and exposes
the three entrypoints. The model currently does neither — it neither lists the
route nor excludes it.

**2. MISATTRIBUTED — route `vaultToWithdrawalQueue`.**
Documented as `Vault → WithdrawalQueue`. No such transfer exists in the pinned
source; `WithdrawalVault.sol` has exactly one ETH send (L120, to Lido). The
only ETH-bearing call into the queue is `contracts/0.4.24/Lido.sol:1099–1101`
in `collectRewardsAndProcessWithdrawals`, whose source is **Lido**. The
destination is right and the route is tagged `sourceShapedRuntime`, so no Lean
statement asserts the wrong endpoint — but the doc-comment table does.

**3. PROVENANCE UNDER-CLAIM — route `vaultToLido`.**
Tagged `sourceShapedRuntime` although `contracts/0.8.9/WithdrawalVault.sol:120`
(in `withdrawWithdrawals`, L107–121) is a pinned call site with a hard-coded
`LIDO` immutable destination and an `msg.sender != address(LIDO)` guard.
Conservative, but inaccurate.

**The solid negative result.** Across all fourteen in-scope files there are
zero occurrences of `delegatecall`, `callcode`, `selfdestruct`, `create`,
`create2`, zero inline-assembly `call` opcodes, and zero `.transfer(`/`.send(`
ETH sends. The only `transfer`-family hit is an ERC20 transfer
(`WithdrawalVault.sol:137`), which moves no ether. The value-moving surface is
therefore syntactically enumerable: there are no dynamically dispatched or
hidden ETH exits in the pinned text.

### Residual routes

Residual **within the modeled inventory** — no registered covering parent and
no `Spec.ApprovedDestination`:

- `busToGateway` — `ConsolidationBus.sol:403` → `consolidationGateway`
- `gatewayToVault` — `ConsolidationGateway.sol:220` → `withdrawalVault`
- `vaultWithdrawalCall` — `WithdrawalVaultEIP7685.sol:105` → EIP-7002
  `withdrawalPredeploy`

Residual **outside** the inventory: the WithdrawalQueue claim payout above.

## Ready-to-register row

Registerable once the registry reopens. Append to `guarantees` in
`audit/guarantees.yaml` and add `"P-ETH-CONFINEMENT-1"` to `SUBORDINATE_IDS`
in `scripts/audit_metadata.py`. `verity.theorem` must stay `null` while
`verity.status` is not `CHECKED`; a non-null theorem there fails the schema
with `non-checked verity may not expose a closure theorem`.

```json
{
  "id": "P-ETH-CONFINEMENT-1",
  "summary": "Supplemental parent over the E1 ETH-world inventory: every positive-value authorized frame is a named residual hop, or is both covered by a registered parent guarantee and landing on a frozen Spec.ApprovedDestination. Content is the agreement of three independently written tables (ValueRoute.primaryParent, Destination.toSpec, Guarantees.Id.text). Scoped to ValueRoute, not to the pinned Solidity: the WithdrawalQueue claim payout is outside the inventory.",
  "abstract": {
    "status": "CHECKED",
    "theorem": "LidoSRv3.Audit.Guarantees.PEthConfinement1.modeled_positive_value_is_confined_or_residual"
  },
  "verity": {
    "status": "OPEN",
    "theorem": null
  },
  "fidelity": {
    "covered": [
      "coverage table and frozen Spec approval table agree route by route",
      "every covering parent string denotes an actual Guarantees.Id registry row",
      "the literal residual list is exactly the uncovered part of the modeled inventory",
      "residual hops are unclassified on both the parent and Spec planes",
      "four one-line kill-lines across four tables, each with a positive control",
      "no native_decide; axiom footprint is propext only"
    ],
    "missing": [
      "WithdrawalQueueBase.sol:529 claim payout to an arbitrary recipient is outside the inventory and outside every exclusion class",
      "route vaultToWithdrawalQueue is documented Vault-sourced; the real site is Lido.sol:1099-1101",
      "route vaultToLido is tagged sourceShapedRuntime despite the pinned site WithdrawalVault.sol:120",
      "no executed plane: no Verity transaction, no ContractState, no compiled artifact",
      "quantifies over modeled traces, not over live contracts, arbitrary calls, or deployment state",
      "the three residual hops are named, not discharged"
    ]
  },
  "classification": {
    "kind": "IMPLEMENTATION_PENDING",
    "work": "Model the WithdrawalQueue claim payout hop or add an explicit exclusion class for it; correct the vaultToWithdrawalQueue source attribution and the vaultToLido provenance."
  },
  "assumptions": [
    "A-SOURCE-SHAPED"
  ],
  "next_gate": "Resolve the out-of-inventory WithdrawalQueue claim payout before any statement quantifying over all ETH exits from in-scope contracts.",
  "reproduction": {
    "command": "lake build LidoSRv3.Audit.Guarantees.PEthConfinement1 LidoSRv3.Tests.EthConfinementMutants",
    "expected": "modeled_positive_value_is_confined_or_residual, confinement_does_not_bound_unmodeled_value, and residual_hops_carry_unclassified_value build; the four kill-lines refute their conjuncts and the four positive controls keep the one-line-edit premise"
  }
}
```

## Out of scope

Widening `Spec.ApprovedDestination`, registering a new `Guarantees.Id`,
editing the frozen registry / source map / native-decide allowlist, claiming
any executed or bytecode plane, and treating this conclusion as a bound on all
SRv3 ETH.
