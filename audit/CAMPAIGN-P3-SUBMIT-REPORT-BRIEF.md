# Campaign product 3 — submitReportData mint path

One node, one PR. Product claim (first line). Live
`handleOracleReportComputed` is already done on `P-ORACLE-SUPPLY-1`.
Do not split that ID. Do not widen `P-ACCOUNT-1`. No second mint/cap
ID.

Reopen `P-ORACLE-SUPPLY-1` only to discharge the named OPEN
“submitReportData split remains out.”

## What the parent must say

Either:

**A. Product.** Model the oracle entry that *computes* `feeWei` /
`shareRate` (pinned
`AccountingOracle.submitReportData` → `_handleConsensusReportData` →
`Accounting.handleOracleReport` / `_simulateOracleReport` /
`_calculateProtocolFees`) and feed that computed pair into the
existing `handleOracleReportComputed` wrapper. ∀ report-data,
consensus hash / caller premises you actually check, and entry state:

1. The modeled entry produces `feeWei` and `shareRate`.
2. `handleOracleReportComputed i feeWei shareRate` is the mint path
   already proved.
3. No free `sharesToMintAsFees` argument at the entry.

Or:

**B. Honest stop.** A ∀ parent whose named conclusion is that the live
`submitReportData` split is out of this row, with a parent-shaped
kill-line (a mutant that claims the entry is modeled, or that a free
argument is the entry). Then stop. Do not restate
`oracle_supply_live_computed_mint`.

Default is A. B is allowed only if A cannot be a ∀ parent without
`sorry` / `admit`.

## Kill-line

- A: mutant entry that still takes a free mint, or that skips
  `_simulateOracleReport`, fails the computed-entry conjunct on a
  nonempty report witness.
- B: mutant that asserts `submitReportData` is this path fails the
  named-out conclusion.

Existing free-argument / sum-balances / raw-fee kill-lines stay as
lemmas of the computed-wrapper parent. Do not replace them.

## Non-goals

- Do not split `P-ORACLE-SUPPLY-1` into P-ORACLE-MINT-1 /
  P-ORACLE-BOUND-1.
- Do not edit `PAccount1.lean`. ACCOUNT stays order-only.
- Do not add Eugene/module-total *report* bounds here (node 7).

## Files

Own: new Spec/Source/Verity modules for the entry (if A),
`POracleSupply1.lean` only to add the discharged conjunct or the
named-out conclusion, mutants, this brief, YAML `fidelity.missing` /
`next_gate` for the discharged OPEN.

## Build

    lake build LidoSRv3.Audit.Guarantees.POracleSupply1
    lake build LidoSRv3.Tests.PackN3OracleMintMutants
    # plus new entry module / mutants if A

## Quality gate

YAML theorem is the new parent conjunct or the named-out discharge.
Kill-line builds. No second mint/cap ID. Verity quantifier matches or
is disclosed.
