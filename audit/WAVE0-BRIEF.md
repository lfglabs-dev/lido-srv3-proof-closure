# Wave 0 brief — honesty, kill-lines, frozen Spec interfaces

One node, one PR. Wave 0 is serial and is not Best-of-N. Lean theorems are
authority. This brief freezes the Spec interfaces later packs may mention.
It does not invent new guarantee IDs, does not start packs A–F, and does
not promote P-DEREF-1.

## Frozen Spec interfaces

Declared in `LidoSRv3/Audit/Spec.lean`. Cross-guarantee theorems mention
only these.

| Interface | Fields | Must not be read as |
| --- | --- | --- |
| `Allocation` | `moduleId`, `capacity`, `amount` | executed deposit/top-up wei; `LinksSource` |
| `Spend` | `amount : Wei` | P-RESERVE-RELATIONAL finalization independence |
| `EthJournal` | `ApprovedDestination × Wei` | all SRv3 ETH; VaultHub owner withdraw |
| `OracleFrame` | `balances`, `sharesMinted`, `shareRateΔ` | fee computation; submitReportData |
| `SszWitness` | `verify ⇔ encode(d) ∈ r` | SHA-256; deployed Yul; production gindices |

Named hypotheses stay named: `LinksSource`, `freshQueueCache`,
`PerfectDepositEncoding`. ALLOC ↛ `LinksSource` remains explicit until a
proved bridge exists.

Composition rule: Spec → Source → Verity. Never Verity to Verity. Widen by
conjoining parents, not mega-ifs.

## Honesty of the eleven registered parents

Each parent is the YAML `abstract.theorem`. Children stay unregistered or
named. Kill-lines below negate that exact shape on a mutant of one model
function, premises retained, non-vacuous witness.

| ID | Registered parent | Parent-shaped kill-line | Honesty note |
| --- | --- | --- | --- |
| P-ALLOC-1 | `checked_execute` | `capacity_target_kill_line_refutes_parent` | min-clamp remains an unregistered child |
| P-ALLOC-2 | `step_correspondence_and_full_loop_conservation` | `selection_kill_line_refutes_parent`, `headroom_clamp_kill_line_refutes_parent` | +1 MinFirst stays a separate child |
| P-DEPOSIT-1 | `source_deposit_conserves_and_rolls_back` | source assert-drop kill-line | `LinksSource` remains a caller hyp; ALLOC ↛ LinksSource |
| P-TOPUP-1 | `source_topup_conserves_and_rolls_back` | assert/module/WC/unwrapped-accumulator kill-lines | wrap precludes a value-moving commit; wrap-to-zero is empty commit |
| P-ACCOUNT-1 | `mint_after_read_discipline` | `mint_order_kill_line` / `reordered_mint_read_kill_line_refutes_parent` | order-only; do not widen to fee/shareRate mint |
| P-RESERVE-1 | `source_spend_preserves_withdrawal_reserve` | `guard_drop_kill_line_refutes_parent`, `partition_spend_mutant_kill_line_refutes_parent` | stale-cache is premise necessity, not a parent refutation |
| P-CONSOLIDATION-ETH-1 | `eth_flow_parent_at_canonical` | `misrouted_journal_kill_line_refutes_parent`, `zero_value_success_kill_line_refutes_parent` | former 1b absorbed; former 1a retired; not all SRv3 ETH |
| P-ADDRESS-1 | `universal_address_writer_equivariance` | `fixed_owner_gate_kill_line_refutes_parent`, **write-side** `fixed_owner_writer_kill_line_refutes_parent` | four projections; not permissionless on all four |
| P-TOPUP-2 | `aggregate_bounded_by_block_cap` | `block_cap_kill_line_refutes_parent` | 32-guard is premise/guard necessity |
| P-CONSOLIDATION-1 | `source_consolidation_preserves_eligibility_value_atomicity` | `fee_blind_commit_kill_line_refutes_parent` | gateway-nonzero is a named hyp; no ETH-1 composition |
| P-SSZ-1 | `deposit_root_iff` | **`sourceNode_mutant_kill_line_refutes_parent`** (this node); `swapped_combine_kill_line_refutes_parent` remains the traversal-child kill-line | bidirectional reconstruction is `SszWitness.Correspondence`; deposit uniqueness is the named `PerfectDepositEncoding` child, not a parent conjunct |

## This node's Lean work

1. Freeze the five Spec interfaces.
2. Register `deposit_root_iff` as `SszWitness.Correspondence` at the source
   `encode` / `verify` / `witnessOf` triple. Construction and witness
   determination stay. The uniqueness conjunct that restated
   `PerfectDepositEncoding` is demoted to the unregistered child
   `deposit_unique_of_perfect`.
3. Add a parent-shaped kill-line: mutate `encode` to `sourceNode · + 1`,
   retain `wellFormedDeposit`, inhabit with a pinned-width deposit.
4. Cite P-RESERVE-RELATIONAL as the supplemental independence row, not as
   P-RESERVE-1 spend.
5. Keep P-ACCOUNT-1 order-only. Keep P-DEREF-1 supplemental.

## Out of scope until a later node brief says so

Bonus IDs, VaultHub row, pause row, oracle split, bus row, promoting
P-DEREF-1, ALLOC↔DEPOSIT composition, live SSZ.verifyProof, SHA/Yul
identification, EIP-4788 / gateway.

## Quality gate

Parent is the YAML abstract theorem. Kill-line builds and is parent-shaped.
`lake build` of the SSZ row plus listed tests. No `sorry` / `admit` /
`native_decide` on the parent. `fidelity.missing` lists every gap the
English claim might hide. Composition uses Spec interfaces only.
`PerfectDepositEncoding` stays named. Judge criteria 1–6 are mandatory.
