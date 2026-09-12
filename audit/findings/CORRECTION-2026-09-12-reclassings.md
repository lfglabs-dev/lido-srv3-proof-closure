# Correction receipt (mandate 2026-09-12): reclassed, not discharged

## Context

An independent four-reviewer read of `main` at `bac04fb8` against pinned
Solidity `lidofinance/core@17005714f151e5502c559932319a3f2f74ac2436`
found no Lido bug, but concluded that the audit text promises more than
the registered parents prove. Several recent "retirements" were
reclassifications: they added derived consumer modules, orphelinat
wrappers, or ignored-premise theorems, without changing the ENUNCE of
the registered parent theorems named in `audit/guarantees.yaml`.

**Corrected rule (mandate 2026-09-12)**: retiring an assumption or a
`fidelity.missing` entry requires CHANGING THE STATEMENT of a
registered parent (the `abstract.theorem` or `verity.theorem` named in
`guarantees.yaml`). None of the following count as a retirement:

- A theorem that ignores an unused `Prop` premise.
- A wrapper that re-applies the parent.
- A hypothesis renamed on a free-parameter record.
- An `rfl` on a self-defined config.
- A "kernel-independence" argument when the hypothesis is embedded in a
  type or definition (e.g. `TxObservation.reverted ↦ before`, opaque
  `sha256`, `fuelBudget = 32`, definitional pack of `⟨b, 0, 0⟩`).

## Reinstatements

This commit reinstates the following in `audit/assumptions.yaml` and in
the corresponding guarantee-level `assumptions` lists:

### A-CONSOLIDATION-GATEWAY-NONZERO
- **Consumers**: `P-CONSOLIDATION-1`, `P-CONSOLIDATION-VALUE-1`.
- **Prior "retirement"**: PR #411 (`audit(assumption): retire A-CONSOLIDATION-GATEWAY-NONZERO post PR #263 merge`).
- **Why it was wrong**: PR #263 introduced
  `executeConsolidation_committed_forwards_msgValue` at
  `audit/trio/consolidation/Bus.lean:203`. That theorem proves the Bus
  produces a `GatewayCall` whose `.value` equals the executor-supplied
  `msgValue`. But `msgValue` is a free `Word` parameter of the Bus
  theorem; the vault still receives `count * fee`, which is zero when
  the EIP-7251 fee is zero. Neither the outer gateway payment being
  positive nor the fee itself being positive is derived. The Bus lemma
  is a forwarding statement, not a positivity discharge.
- **What actually discharges this**: derive positivity of the vault's
  forwarded value from a justified fee condition — the EIP-7251 fee
  being nonzero, live-read via STATICCALL — and a composed calling
  path; or separately revise the theorem's positive-fee claim.
- **False line corrected**: `P-CONSOLIDATION-1.fidelity.covered`
  previously read "gateway forwards msg.value to vault (PR #263)...
  Discharges A-CONSOLIDATION-GATEWAY-NONZERO down to the ABI/interpreter
  bridge gap". Replaced with a "RECLASSED not discharged" statement
  citing this file.

### A-ABSTRACT-TX
- **Consumers**: `P-TOPUP-1`, `P-CONSOLIDATION-ETH-1`.
- **Prior "retirement"**:
  - `P-DEPOSIT-1` via PR #393 (`proof(provenance): orphan A-ABSTRACT-TX from P-DEPOSIT-1`).
  - `P-TOPUP-1` and `P-CONSOLIDATION-ETH-1` via PR #401
    (`proof(provenance): isolate A-ABSTRACT-TX for P-TOPUP-1 and P-CONSOLIDATION-ETH-1 (full registry retirement)`).
- **Why it was wrong**: `LidoSRv3.Audit.TxObservation` has
  `.reverted ↦ before` and `.committedTrace = ⟨[], [], []⟩` by
  **definition**. The `RevertRestoresSnapshot` conjunct of the
  P-TOPUP-1 parent uses this abstract observation; the
  P-CONSOLIDATION-ETH-1 fuel-exhaustion revert arm uses the model's
  own `fuelBudget = 32`. Both are assumptions embedded in the type /
  definitional shape of the model. The isolation proved that no
  additional kernel axiom is required — which is true but does not
  discharge the modelling gap: an assumption embedded in a definition
  remains an assumption even when `#print axioms` does not see it.
- **What actually discharges this**: replace the abstract-TX conjunct
  with a `Verity.Contract.run` executable-plane rollback conjunct in
  the registered parent's STATEMENT (not a wrapper).
- Note: PR #393's `DepositAbstractTxOrphaned.lean` is left in the tree
  as unregistered structural evidence. The P-DEPOSIT-1 case is a
  separate matter (P-DEPOSIT-1's registered parents genuinely do not
  fold `RevertRestoresSnapshot` in as a conjunct, per the docstring at
  `LidoSRv3/Audit/Guarantees/PDeposit1.lean:108-114`); that retirement
  is not reinstated here because it does correspond to the
  parent-shape argument, but is flagged for a follow-up review under
  the corrected rule.

### A-SHA256-FFI
- **Consumers**: `P-SSZ-1`, `P-SSZ-1.deposit-data-root`,
  `P-SSZ-1.abstract-digest`, `P-SSZ-1.tx-execution-simulation`,
  `P-SSZ-LIVE-1`.
- **Prior "retirement"**: PR #400 (`proof(provenance): isolate
  A-SHA256-FFI — retired from every consumer's assumptions list`).
- **Why it was wrong**: `Compiler.Sha256.Engine.sha256` is an
  **opaque definition**. Every registered SSZ theorem consumes this
  opaque symbol. Isolation argued that no `sha256_correct` axiom is
  required at the kernel level — true but again a hypothesis embedded
  in a definition remains a hypothesis. The registry entry was
  retained per `scripts/audit_metadata.py:316` mandatory
  scope-boundary; the consumer-list retirements are reversed here.
- **What actually discharges this**: prove or import a separately
  certified SHA-256/precompile refinement theorem that CHANGES the
  ENUNCE of the registered SSZ parent, not a wrapper that ignores an
  unused `Sha256Faithful` premise.

## Missing-entry reinstatements

### `P-RESERVE-1` "live WithdrawalQueue.unfinalizedStETH call"
- **Prior removal**: PR #408 (`integrate(grok #404): P-RESERVE-1 live
  unfinalizedStETH STATICCALL`).
- **Why it was wrong**: `LidoSRv3/Audit/Source/ReserveUnfinalizedCall.lean`
  is a consumer module that derives `freshQueueCache` from a live
  STATICCALL observation, but the registered parent theorem
  `source_spend_preserves_withdrawal_reserve` still takes
  `freshQueueCache` as a hypothesis. This is a RENAMED HYPOTHESIS, not
  a change to the parent's ENUNCE.
- **Reinstated missing entry**: original text with a "RECLASSED not
  discharged" preamble.

### `P-ACCOUNT-1` "packed uint64 accounting words"
- **Prior removal**: PR #418 (`integrate(grok #399): P-ACCOUNT-1
  packed uint64 accounting words`).
- **Why it was wrong**: `LidoSRv3/Audit/Source/AccountPackedWords.lean`
  proves the pack/unpack round-trip only for the DEGENERATE case
  `pack ⟨b, 0, 0⟩` (zero exit / zero pending). The general packed
  layout with nonzero exited/pending fields is not linked to the
  parent `mint_after_read_discipline` /
  `verity_tx_simulates_oracle_report` writes.
- **Reinstated missing entry**: "packed uint64 accounting words" with
  the "RECLASSED not discharged" preamble.

## Counts

- `audit/assumptions.yaml`: 7 → 9 entries (A-CONSOLIDATION-GATEWAY-NONZERO
  and A-ABSTRACT-TX added back; A-SHA256-FFI entry text rewritten;
  count went 7 → 9 because the two were absent from the registry).
- Canonical fidelity gaps: 78 → 82 (four reinstated entries).
- Trust axiom envelope: unchanged (36).
- No Lean edits: registered parent theorem statements and proofs are
  byte-for-byte unchanged. The reinstatement is bookkeeping only; the
  actual model corrections required to properly discharge these
  assumptions are the subject of the mandate's subsequent chantiers.

## Follow-up chantiers (per mandate 2026-09-12)

- Chantier 2: P-TOPUP-1 register a real simulation+wrap theorem
  (current parent `PTopup1.lean:815` returns its own hypothesis).
- Chantier 3: P-SSZ-1 register the compiled `_verifyValidator` as
  Verity parent, demote the current Nat.pair gadget at gindex 2 to
  child.
- Chantier 4: P-TOPUP-2 reformulate on the real router mechanism
  (`StakingRouter.topUp` 703/706/729/737); the current bound is over a
  budget walk the contract does not execute.
- Chantier 5: P-CONSOLIDATION-ETH-1 integrate #410 (fuel derived);
  disclose role/pause/quota/CL-proof/fee-STATICCALL as missing;
  correct `source-map.yaml:726-730`.
- Chantier 6: P-ADDRESS-1 disclose guard-order inversions and the
  boolean-projection nature of the parent; register the Bridge
  theorems.
- Chantier 7: infra fixes (`verify_beacon_deposit_immutable.py`,
  fixture SHA in `make test`, `check_proof_escapes.py` scope,
  "31 axiomes" → 36 everywhere).
- Chantier 8: `audit/SITE-CORRECTIONS.md` for lfg_marketing #426
  cards before publication.
