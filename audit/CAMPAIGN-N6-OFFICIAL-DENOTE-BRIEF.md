# Campaign node 6 — official denote reverts, justified interpreter forwards

One node, one PR. Same guarantee ID `P-CONSOLIDATION-VALUE-1`. Keep
`A-CONSOLIDATION-GATEWAY-NONZERO`. Do not start the bus. Do not claim
official denotation success.

## What the parent says

`PConsolidationValue1.official_denote_reverts_and_justified_forwards_msg_value`

- Official `denoteFunction` reverts on the registered bind entrypoint
  for every oracle, transaction, and world.
- Independently, every successful justified execution forwards exactly
  `msg.value` and carries `noConsensusLayerVerify`.

One named conjunction. The earlier justified-only theorem stays as a
lemma. This is after the existing explicit `noConsensusLayerVerify`
parent (node 5 is not required on this branch).

## Kill-line

`official_denote_success_kill_line_refutes_parent`: claiming official
`denoteFunction` succeeds is false. Existing zero-value CALL kill-line
retained.

## Non-goals

- No bus, no consensus-layer verify.
- Gateway nonzero stays a premise.
- Official denotation success is not claimed.

## Build

    lake build LidoSRv3.Audit.Guarantees.PConsolidationValue1
    lake build LidoSRv3.Tests.PackN6ConsolValueMutants
