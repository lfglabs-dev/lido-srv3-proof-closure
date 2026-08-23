# Campaign node 5 — ProductionGindexBinding from the constructor pin

One node, one PR. Same guarantee ID `P-SSZ-LIVE-1`. Keep `A-SHA256-FFI`.
Keep `eip4788ParentRoot` opaque. Do not claim live verify. Do not set
`ProductionGindexBinding` to `False`.

## What the parent says

`PSszLive1.production_witness_admission_from_core_gindex`

- `ProductionGindexBinding`: the TopUpGateway constructor pin
  `g_index_first_validator_curr` equals `(150 * 2^40 << 8) | 40`.
- Gateway admission of a top-up / consolidation WC witness is `ageCheck`
  plus production-GI verify against the opaque looked-up parent root.

The pin is the in-repo constructor literal in
`audit/p-topup-2-runtime-provenance.json`. It is not a live-deployment
identity.

## Kill-line

`wrong_packed_word_is_not_production_binding`: packed word `0x28` (pow
only) is not the constructor-pin decode. Existing
`skip_lookup_kill_line_refutes_parent` still drops the lookup.

## Non-goals

- SHA-256 functional correctness stays `A-SHA256-FFI`.
- `eip4788ParentRoot` stays opaque; this is not live verify.
- Toy slots 2/3/4 stay leftover record.
- No bus.

## Build

    lake build LidoSRv3.Audit.Guarantees.PSszLive1
    lake build LidoSRv3.Tests.PackN5SszLiveMutants
    lake build LidoSRv3.Tests.PackW2GindexMutants
