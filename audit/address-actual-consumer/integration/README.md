# ADDRESS integration on main

The source candidate is 99c9dab6aafc753698c9ece26e415dfe01843992.
It is merged with main ea5774a82facf0d474e68058c4645ebf4380d403, preserving
SSZ #314 and the previously integrated SSZ / consolidation / withdrawal-ledger
increments. The three new public PAddress1 consumers and all six source
candidate target modules remain unchanged.

The old batch/fuel/unbounded journal theorems and their mutants relied on the
accepted pre-#307 mapUint executor and its synthetic CALL journal. They cannot
be retargeted to arbitrary callback worlds: callbacks may overwrite those
claimed bits and journals. Integration preserves that accepted executor,
including its definitions, theorem statements and proofs, verbatim modulo an
explicit Model.AddressClaimJournalLegacy namespace and archival notice.
legacy-identity.json records the normalized byte identity to integrated main
14a96a3180ac9fb81f853db36af3b630c1d5891f. Historical consumers retain their
original propositions under that executor, with no extra premises. Their
comments are explicitly scoped to the historical journal. The supplemental
PAddressBatch1 physical-slot theorem and corresponding two physical-lens
mutants continue to use the current physical lenses, qualified explicitly.
The new actual recipient/CALL/batch theorem dependency closures do not import
the legacy model.

This preservation is compatibility work, not another proof increment. It does
not claim the historical rename/claimed-bit observations for arbitrary real
callbacks. The actual callback-world claim is the separately reviewed new
PAddress1 execution certificate. Existing accepted keccak-injectivity-dependent
historical results remain separately identifiable; the new actual consumers
do not acquire that assumption.

Trust queries for five removed unaccepted finite receipt declarations are
replaced by the actual claim, chain and kernel mutants; whole-world rollback
and zero-recipient rejection are additionally inspected. No allowlist is
expanded. Full union compilation and exact trust checking must pass before
integration acceptance, followed by independent review of this exact migration.
