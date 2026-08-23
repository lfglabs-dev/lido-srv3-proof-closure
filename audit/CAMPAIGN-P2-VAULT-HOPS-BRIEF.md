# Campaign product 2 — Vault→Lido / WQ value hops

One node, one PR. Product claim (first line), not the leftover
exclusion-only restatement. Real fork: new parent, or widen
`Spec.EthJournal` / `ApprovedDestination` with new constructors *and*
value-bearing frames. Isolated Best-of-2/3 uses this same brief.

Do not reopen `P-ETH-JOURNAL-1` except to discharge a named OPEN it
already lists (Vault→Lido / WithdrawalQueue stays remain outside).
Exclusion-only is already proved
(`journal_approved_excludes_protocol_return_paths`). Address pins do
not close provenance. Do not claim “Lido never drains ETH” from
`JournalApproved`.

## What the parent must say

Universal over the modeled vault-return inputs and entry state.

New `ApprovedDestination` constructors (names are local; keep them
honest) for the protocol-return hops that exclusion currently names
out — at least Vault→Lido (`LIDO.receiveWithdrawals` / protocol
rebalance) and WithdrawalQueue. Owner-controlled `VaultHub.withdraw` /
`StakingVault.withdraw` to an arbitrary recipient stay out unless you
add a constructor *and* a value-bearing frame for that exact path.

AND value-bearing frames: each new constructor is inhabited by an
`externalCallBindTo` (or official denote CALL) whose `value` is the
hop’s wei. A destination constructor without a frame is not this
parent.

Conclusion, one named conjunction:

1. Every success journal of the new (or widened) model projects onto
   `Spec.EthJournal` with the new constructors.
2. Each hop’s frame value equals the Spec leg wei.
3. Exclusion of *unmodeled* owner-withdraw recipients remains: an
   `other` / arbitrary-recipient hop is not approved.

If you keep `P-ETH-JOURNAL-1` as the exclusion parent, the YAML
theorem for *this* node is a new supplemental ID (suggested
`P-VAULT-ETH-1`) or a discharged OPEN on `P-ETH-JOURNAL-1` whose
conclusion is the hops, not exclusion-only.

## Kill-line

Parent-shaped. Mutant that journals a Vault→Lido (or WQ) hop as
`lidoPull` / `beaconDeposit` / `none`, or that adds the constructor
but moves `value = 0`, fails the value-bearing / projection conjunct.
Existing exclusion kill-line (`mutant_lido_approved_not_excluded`)
must not be restated as this parent’s kill-line.

## Non-goals

- Do not quote “Lido never drains ETH.”
- Do not treat address pins as provenance.
- Do not widen `P-ACCOUNT-1`. Node 7 (pause/bunker) is not required.
- Do not claim all SRv3 ETH.

## Files

Own: new Spec correspondence (or a *documented* widen of
`LidoSRv3/Audit/Spec.lean` `ApprovedDestination` — Wave 0 freeze is
lifted for this node only), new or widened Verity frames, new
guarantee module if a new ID, mutants, this brief, registry / YAML /
`AllGuarantees` / `LidoSRv3.lean` / `Makefile` /
`scripts/audit_metadata.py` `SUBORDINATE_IDS` if a new ID.

If you widen `ApprovedDestination`, update
`VaultHubScopeChild.approved_destination_cases` and its four-arm
kill-line so they stay true of the new inductive.

## Build

    lake build LidoSRv3.Audit.Guarantees.PEthJournal1
    # plus the new parent module and mutants
    python3 scripts/audit_metadata.py check

## Quality gate

YAML theorem is the hops parent (new ID or discharged OPEN), not
exclusion-only. Kill-line builds. `lake build`. English claim does not
hide zero-value frames or constructor-only widening.
