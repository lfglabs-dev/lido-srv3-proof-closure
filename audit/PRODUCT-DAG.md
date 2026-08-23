# Product-facts DAG — remaining claims after leftover close

Waves 0–3 and leftover nodes 1–6 are on `main`. This campaign closes
remaining *product* facts. One node, one brief, one PR. Default is the
first line of each node, not a leftover restatement.

```
  (1) n-frame     (2) vault hops     (3) submitReportData     (4) keccak/unbounded
        \              |                    |                        |
         \             |                    |                        |
          \            |                    |                   (7) optional
           \           |                    |
            +----------+--------------------+
                        |
                   (5) live SSZ
                        |
                   (6) official denote success
                       (or explicit no-CL-verify parent, already on main)
```

(1)(2)(3)(4) are independent. (5) before any live top-up / consolidation
verify consume. (6) after (5) or the existing `noConsensusLayerVerify`
parent. (7) after (4) only if token scope needs it — skip unless a later
brief says so.

Best-of-2/3 only on real forks: n-frame vs keep two-batch; how vault→Lido
enters the journal. Isolated attempts, same brief. Models: Grok, GPT-5.6
Sol, Fable 5 as third. No two attempts on the same model. Read-only judge
that did not author a candidate.

Do not reopen P-ALLOC-EXEC-1, P-ETH-JOURNAL-1, P-ORACLE-SUPPLY-1,
P-ADDRESS-BATCH-1, P-SSZ-LIVE-1, or P-CONSOLIDATION-VALUE-1 except to
discharge a named OPEN they already list. Do not split P-ORACLE-SUPPLY-1.
Do not widen P-ACCOUNT-1. Do not claim “Lido never drains ETH” from
JournalApproved.
