# Piste C — Chantier 2 (CONSOLIDATION-1 & CONSOLIDATION-ETH-1 ABI bridge) status

Snapshot: 2026-09-13 morning. See `~/work/goals/goal-c.md` for the
original directive; `audit/guarantees.yaml`
`P-CONSOLIDATION-1` / `P-CONSOLIDATION-ETH-1` for the authoritative
current claims.

## Thomas's Chantier 2 explicit line items — all landed

| Item | Thomas's directive | Landed as |
| --- | --- | --- |
| a | ABI/interpreter bridge `ConsolidationGateway.sol:185-223 → WithdrawalVault → predeploy`, single path, `totalFee = n * fee` forwarded (212-220), fee via STATICCALL (81-93, `FeeReadFailed`/`FeeInvalidData`) | PR #567 (fee arithmetic), PR #582 (frame-boundary scalar linkage `gatewayVaultBoundary_satisfies_exact_fee`) |
| — | `A-CONSOLIDATION-GATEWAY-NONZERO` remains explicit, derive `fee ≠ 0 → totalFee ≠ 0`, document `fee = 0` on-chain | PR #560 (assumption narrowing), PR #567 (arithmetic derivation) |
| — | Guard order: exact-fee before per-key validation (`EIP7685:66` vs `Correspondence.lean:243-247`) | PR #563 (D-* fix in registered `sourceRun`) |
| b | `RequestAdditionFailed` (`WithdrawalVaultEIP7685.sol:116-118`) as a branch | PR #570 (`sourceRunWithCallOutcomes` source model + all-success reduction + non-vacuity witness) |
| c | Retire fabricated slots `sourceMapSlot` / `targetMapSlot` | PR #579 (fabrication disclosure + retirement plan), PR #584 (retirement bridge `commit_payloads_equal_call_inputs`), PR #585 (event-log carrier + call-vs-event agreement), PR #588 (slot-independent `observeFromJournal`), PR #592 (status/payload invariants), PR #594 (slot-invariance theorem), PR #596 (`sourceRun`-level bridge) |
| — | Error names (`InsufficientFee`, `IncorrectFee`) | PR #565 (guard-by-guard error-name correspondence enumeration) |
| d | Role/pause/quota/CL-proof in ETH-1 statement by composition | PR #573 (role/pause/quota via `PhysicalEntrySettlement` / `PhysicalQuotaSettlement`), PR #577 (CL-proof cross-guarantee link to `P-SSZ-1.real_validator_correspondence`) |
| — | Integrate Grok #410 if not already done | Verified integrated in main via commit `67075346` (chantier-5 mandate 2026-09-12); no separate PR needed |

## Follow-up refactors (natural extensions, remain OPEN)

These are deeper than Thomas's explicit list, disclosed as
follow-ups in the two guarantees' `fidelity.missing`:

- **Full executable-plane `Contract.run` frame composition.** A
  chained `Contract.run` executing
  `ConsolidationGateway.addConsolidationRequests` and then
  `WithdrawalVault.addConsolidationRequests` across the frame
  boundary. Source-plane linkage is proved
  (`gatewayVaultBoundary_satisfies_exact_fee`, PR #582), and the
  role/pause/quota/CL-proof compositions are named
  (PRs #573, #577). The executable-plane composition itself is the
  remaining refactor.

- **Physical removal of the fabricated `sourceMapSlot` /
  `targetMapSlot` slots** from
  `LidoSRv3/Audit/Verity/ConsolidationTx.lean`'s 30+ downstream
  uses. The migration path is proved sound at:
  - **Source plane**, `LidoSRv3/Audit/Source/ConsolidationCorrespondence.lean`:
    - `commit_payloads_equal_call_inputs` (PR #584)
    - `commit_payloads_equal_event_payloads` (PR #585)
    - `commit_call_inputs_equal_event_payloads` (PR #585)
    - `sourceRun_committed_payloads_eq_call_inputs` (PR #596)
  - **Verity plane**, `LidoSRv3/Audit/Verity/ConsolidationTx.lean`:
    - `observeFromJournal` slot-independent observation (PR #588)
    - `observeFromJournal_revert_eq_observe` (PR #588)
    - `observeFromJournal_success_non_payload_eq_observe` (PR #588)
    - `observeFromJournal_status_success` / `_revert` (PR #592)
    - `observeFromJournal_success_payloads_eq_calls_input` (PR #592)
    - `observeFromJournal_success_slot_invariant` (PR #594)

  The physical retirement itself (removing the slot definitions
  and rewriting `observe`, `readPayloads`, `writePayloads`, and
  the ~30 downstream theorems that reference them) is the
  remaining refactor. All proof obligations for the substitution
  are already discharged.

## PR ledger (chantier-2)

PRs #560, #563, #565, #567, #570, #573, #577, #579, #582, #584,
#585, #586 (next_gate refresh), #588, #592, #594, #596 — 16 landed.

## Assumptions status

- `A-CONSOLIDATION-GATEWAY-NONZERO` is now narrowed in
  `audit/assumptions.yaml` with explicit `fee = 0` on-chain
  disclosure and the `fee ≠ 0 → totalFee ≠ 0` derivation
  (PRs #560, #567). Full discharge still needs a live callee
  model on the pinned EIP-7251 predeploy (documented in
  `removal_path`).
- `A-CONSOLIDATION-GATEWAY-NONZERO` remains a caller-supplied
  premise on the vault-side theorem; the source-plane linkage
  (PR #582) shows the vault-input scalars satisfy the exact-fee
  equation the vault checks, so composition with the gateway leg
  makes the `IncorrectFee` branch of `sourceRun` unreachable.
