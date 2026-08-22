# Pack W2-GINDEX brief — toy operationIndex slots

One node, one PR. No new guarantee IDs. There are no production `GI_*`
literals in-repo. `Ssz.operationIndex` uses toy slots 2, 3, 4. This pack
does not invent mainnet gindices and does not close a deployed GI
equality.

## Frozen interfaces used

`Ssz.operationIndex` from `Audit/Ssz.lean` (slots 2, 3, 4). Existing
SOURCE child `GIndexConcatCorrespondence.source_concat_matches_spec`.

## Work

1. Record the definitional toy slots: `cl_validator_index_is_toy` (= 2),
   `cl_proof_index_is_toy` (= 3), `consolidation_index_is_toy` (= 4).
2. Name that the production binding remains open:
   `ProductionGindexBinding` is `False` (no in-repo production literal;
   the hyp cannot be closed here) and
   `production_gindex_binding_remains_open`.
3. Instantiate `source_concat_matches_spec` on the concrete pair index 2
   / pow 7 and index 3 / pow 11. Import the existing SOURCE theorem.
   Toy operands, not production `GI_*`.

## Kill-lines

- Claiming `operationIndex .clValidatorVerifier = ⟨10, _⟩` is false.
  The in-repo slot is the toy index 2.

## Out of scope

EIP-4788, SHA, Yul, live `verifyProof`, deployed GI equality,
consolidation gateway/bus.
