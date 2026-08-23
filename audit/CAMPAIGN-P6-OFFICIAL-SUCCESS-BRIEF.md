# Campaign product 6 — official consolidation denote success

One node, one PR. Product claim (first line). Official denote reverts
∧ justified forwards `msg.value` is already done on
`P-CONSOLIDATION-VALUE-1`. Reopen that ID only to discharge the named
OPEN “does not claim official denotation success.”

This node is after product 5 (live SSZ consume) *or* the existing
explicit `noConsensusLayerVerify` parent (already on main). Do not
wait for product 5 if you keep `noConsensusLayerVerify`.

Keep `A-CONSOLIDATION-GATEWAY-NONZERO` named. Bus/delay only after
success. Do not claim bytecode if official still reverts.

## What the parent must say

Either:

**A. Product.** `denoteFunction` succeeds on value-bearing request
`CALL`s for the registered bind entrypoint, ∀ oracle / transaction /
world that satisfy the existing source guards (gateway caller,
nonempty aligned keys, exact `msg.value = n * fee`, funded vault):

1. Official denotation `.success = true`.
2. Fresh CALL frames carry fee value (not zero).
3. Forwarded value equals `msg.value`; `preservesEthBalance` holds.
4. Either consume product-5 live verify, or keep
   `noConsensusLayerVerify` as an explicit parent conjunct.

Or:

**B. Honest stop.** Keep “official reverts” as the named conclusion.
Do not claim bytecode, official success, or a bus. The existing
`official_denote_reverts_and_justified_forwards_msg_value` is then
left as the YAML theorem; this node does not reopen the ID.

Default is A. B is leftover-already-done unless you discharge a
*different* named OPEN. If A cannot be a ∀ parent, stop and do not
reopen.

## Kill-line

- A: mutant official denote that still reverts, or that succeeds with
  zero-value CALLs, fails the success / value-bearing conjunct.
- B: do not add a new kill-line that restates
  `official_denote_success_kill_line_refutes_parent`.

## Non-goals

- No bus, no delay, no quota, until A succeeds.
- Do not discharge `A-CONSOLIDATION-GATEWAY-NONZERO` without an
  ABI/interpreter bridge.
- Do not compose ETH-1 with CONSOLIDATION-1 without that bridge.

## Files

Own: `ConsolidationCallFragment.lean` / official denote path,
`ConsolidationBridgeGap.lean`, `PConsolidationValue1.lean` only for
the discharged success conjunct, mutants, this brief, YAML
missing/next_gate.

## Build

    lake build LidoSRv3.Audit.Guarantees.PConsolidationValue1
    lake build LidoSRv3.Tests.PackN6ConsolValueMutants
    # plus official-success mutants if A

## Quality gate

YAML theorem is official success or the ID is not reopened. Kill-line
builds for A. Do not claim bytecode while denote reverts.
