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
    - `observeFromJournal_eq_of_observe_and_payload_matches_calls`
      (PR #599) — generic substitution API
    - `sourceView_payloads_eq_calls_input` + `observeFromJournal_simulates_pinned_source`
      (PR #600) — slot-independent Verity theorem
    - `observeFromJournal_writePayloads_invariant` (PR #605) —
      write-side slot invariance
    - `persistSlotFree` companion + `persist_calls_eq_persistSlotFree_calls`
      + `persist_events_eq_persistSlotFree_events` (PR #609)
    - `addRequestsSlotFree` companion executable transaction (PR #610)
  - **Guarantee namespace**, `LidoSRv3/Audit/Guarantees/PConsolidation1.lean`:
    - `verity_tx_simulates_consolidation_from_journal` (PR #602)
      — slot-independent P-CONSOLIDATION-1 consumer alias

  The physical retirement itself (switching `addRequests` to use
  `persistSlotFree`, then removing the slot definitions, and
  rewriting `observe`, `readPayloads`, `writePayloads`, and the
  ~30 downstream theorems that reference them) is the remaining
  refactor. All proof obligations for the substitution are
  already discharged: `addRequestsSlotFree` is a drop-in
  slot-free transaction usable today.

## PR ledger (chantier-2)

Original chantier-2 sweep (24 PRs, up through PR #610):
PRs #560, #563, #565, #567, #570, #573, #577, #579, #582, #584,
#585, #586, #588, #592, #594, #596, #598, #599, #600, #602,
#605, #606, #609, #610.

Consolidation refactor + A-CONSOLIDATION-GATEWAY-NONZERO retirement
sweep (subsequent PRs): #641 (retire fabricated slots from parent
statement), #642 (cleanup unconsumed drips), #644 (gateway→vault
bridge parent), #646 (value-plane parents to slot-free), #647
(A-CONSOLIDATION-GATEWAY-NONZERO derivation under bridge), #648
(direct proof `observeFromJournal_simulates_pinned_source_slotFree`),
#649 (Trio-plane grouped_tx_simulates to slot-free), #651 (item d.CL
cross-guarantee CL-proof premise), #655 (executable-frame ABI-bridge
composition premise), #658 (kill-line mutants ported to slot-free),
#661/#664/#666/#667/#669 (progressive physical-retirement PRs),
#673 (`PackFConsolidationObserveMutants` kill-line retired), #683
(culminating physical retirement, ~800 lines), #687 (fee STATICCALL
wiring into P-CONSOLIDATION-ETH-1 parent statement), #699
(A-CONSOLIDATION-GATEWAY-NONZERO retired from P-CONSOLIDATION-1 via
gateway-bridge parent-statement swap), #706 (sync P-CONSOLIDATION-1
prose), #712 (retire from P-CONSOLIDATION-VALUE-1), #715 (sync
P-CONSOLIDATION-VALUE-1 prose), #720 (stale-fidelity-bullet
cleanup), #725 (assumption removal_path update), #730
(P-CONSOLIDATION-1 stale REINSTATED phrasing), #733 (Lean docstrings
in PConsolidationValue1.lean).

## Assumptions status

- `A-CONSOLIDATION-GATEWAY-NONZERO` was originally caller-supplied
  on the vault-side theorem. The narrowing PRs (#560, #567) landed
  the `fee ≠ 0 → totalFee ≠ 0` arithmetic derivation and disclosed
  the `fee = 0` on-chain case in `audit/assumptions.yaml`.
  Subsequently RETIRED from BOTH consumer guarantees' assumption
  lists (PR #699 for P-CONSOLIDATION-1, PR #712 for
  P-CONSOLIDATION-VALUE-1) via a registered-parent statement swap
  to `..._from_gateway` variants that consume
  `PredeployStaticcallResult`-shaped pinned-source premises directly
  and derive `hGatewayAdmittedNonzero` via
  `gatewayTotalFee_ne_zero_of_fee_ne_zero`. The residual
  `hFeeNonzero : result.abiDecodedFee ≠ 0` on the outer STATICCALL
  structure remains caller-supplied; full discharge still needs a
  live-STATICCALL executable model on the pinned EIP-7251 predeploy
  `0x0000BBdDc7CE488642fb579F8B00f3a590007251` (multi-session Verity
  model work). The complementary `fee = 0` on-chain path is
  documented by `gatewayTotalFee_zero_at_fee_zero` (source plane).
  The full retirement propagation across yaml prose (summary,
  classification.work, next_gate, fidelity.covered, fidelity.missing)
  and Lean docstrings landed via PRs #706, #715, #720, #725, #730,
  #733.
