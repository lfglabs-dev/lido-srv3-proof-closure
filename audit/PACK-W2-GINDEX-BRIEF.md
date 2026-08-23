# Pack W2-GINDEX brief — toy operationIndex slots

One leftover pack. No new guarantee IDs. `Ssz.operationIndex` uses toy
slots 2, 3, 4. Those remain leftover record. The constructor-pin
`ProductionGindexBinding` is inhabited on `P-SSZ-LIVE-1`; this leftover
does not invent a second GI ID.

## Frozen interfaces used

`Ssz.operationIndex` from `Audit/Ssz.lean` (slots 2, 3, 4). Existing
SOURCE child `GIndexConcatCorrespondence.source_concat_matches_spec`.

## Work

1. Record the definitional toy slots: `cl_validator_index_is_toy` (= 2),
   `cl_proof_index_is_toy` (= 3), `consolidation_index_is_toy` (= 4).
2. `ProductionGindexBinding` is the constructor-pin decode discharged on
   `P-SSZ-LIVE-1`, not `False`.
3. Instantiate `source_concat_matches_spec` on the concrete pair index 2
   / pow 7 and index 3 / pow 11. Import the existing SOURCE theorem.
   Toy operands, not production `GI_*`.

## Kill-lines

- Claiming `operationIndex .clValidatorVerifier = ⟨10, _⟩` is false.
  The in-repo slot is the toy index 2.
- `wrong_packed_word_is_not_production_binding`: packed word `0x28` is
  not `(150 * 2^40 << 8) | 40`.

## Out of scope

SHA functional correctness (`A-SHA256-FFI`), live verify, bus.
The constructor pin is not a live-deployment identity.
