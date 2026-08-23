# Campaign node 2 — Vault→Lido / WQ exclusion is a conclusion

One node, one PR. Same guarantee ID `P-ETH-JOURNAL-1`. Keep
`ApprovedDestination` at four constructors. Do not claim “Lido never
drains ETH”. Address pins do not close provenance.

## What the parent says

`PEthJournal1.journal_approved_excludes_protocol_return_paths`

∀ moves, `JournalApproved (consolidationCandidate moves)` →
`ProtocolReturnPathsExcluded moves`.

Exclusion is the named conclusion of a lossless Spec journal, not a
restated leftover. Vault→Lido and WithdrawalQueue stay out of
`ApprovedDestination`.

## Kill-line

`mutant_lido_approved_not_excluded_kill_line`: mutant `specDest` maps
`.lido` to `.lidoPull`, so the Lido hop looks approved while exclusion
fails. Existing fifth-destination kill-line retained.

## Non-goals

- Do not add VaultHub / WQ constructors.
- Do not claim Lido never drains ETH.
- Node 7 (pause/bunker) is not required.

## Build

    lake build LidoSRv3.Audit.Guarantees.PEthJournal1
    lake build LidoSRv3.Tests.PackN2EthJournalMutants
