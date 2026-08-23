# Product-facts DAG — remaining claims after leftover close

Waves 0–3 and leftover nodes 1–6 were already on `main` at campaign
start. Nodes 1–6 product claims are now on `main`. One node, one brief,
one PR. Default was the first line of each node, not a leftover
restatement. Node 7 was optional and was not started.

```
  (1) n-frame     (2) vault hops     (3) submitReportData     (4) keccak/unbounded
   #209 merged     #207 merged        #210 merged              #204 merged
        \              |                    |                        |
         \             |                    |                        |
          \            |                    |                   (7) optional, not started
           \           |                    |
            +----------+--------------------+
                        |
                   (5) live SSZ  #206 merged
                        |
                   (6) official denote success  #212 merged
```

## Landed parents

| Node | PR | YAML theorem | Named leftovers that stay |
| --- | --- | --- | --- |
| 1 | #209 | `PDeposit1.NFrame.verity_tx_composes_nframe_deposit` | `NFrame.LinksSource` caller hyp; `A-DEPOSIT-32-ETHER`; word-domain gap `abstract_parent_covers_inputs_the_verity_plane_omits` |
| 2 | #207 | `P-VAULT-ETH-1` / `protocol_return_value_hops` | one-hop interpreter; endpoints are runtime inputs; not “Lido never drains ETH” |
| 3 | #210 | `oracle_supply_submit_report_data_computed_entry` | same ID `P-ORACLE-SUPPLY-1`; hash/sender/`smoothen` remain inputs; ACCOUNT stays order-only |
| 4 | #204 | `p_address_batch_1_unbounded_recipient_rename` | keccak physical slot maps OPEN; `PhysicalClaimSlots` caller hyp |
| 5 | #206 | `modeled_beacon_roots_live_ssz_consume` | `A-SHA256-FFI`; constructor pin is a lemma; Verity is the same list lookup, not `Contract.run` at EIP-4788 |
| 6 | #212 | `official_denote_succeeds_and_justified_forwards_msg_value` | base `denoteFunction` still reverts; `AcceptingPredeploy`; single-request `1 * fee`; `CallEnv` link params; no compiled-artifact claim |

Runner-up drafts #208 (n-frame) and #211 (vault hops) are closed. Do not
reopen P-ALLOC-EXEC-1, P-ETH-JOURNAL-1, P-ORACLE-SUPPLY-1,
P-ADDRESS-BATCH-1, P-SSZ-LIVE-1, or P-CONSOLIDATION-VALUE-1 except to
discharge a named OPEN they already list. Do not split P-ORACLE-SUPPLY-1.
Do not widen P-ACCOUNT-1. Do not claim “Lido never drains ETH” from
JournalApproved.
