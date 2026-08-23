# Campaign product 5 — live SSZ verify consume

One node, one PR. Product claim (first line). Constructor-pin
`ProductionGindexBinding` and opaque 4788 admit are already done on
`P-SSZ-LIVE-1`. Reopen that ID only to discharge a named OPEN it
already lists (`A-SHA256-FFI`; `eip4788ParentRoot` opaque; constructor
pin ≠ deployed identity).

Constructor pin ≠ deployed identity. Do not say live verify if the
lookup stays opaque.

## What the parent must say

1. **`A-SHA256-FFI` / `HashIdentification`.** Either identify the
   opaque source `sha256` with `Sha256Engine.sha256` (discharge the
   named hyp on byte-bounded preimages) *or* keep `A-SHA256-FFI`
   named. Do not treat a Lean literal as deployed SHA-256.

2. **`eip4788ParentRoot`.** Either equal the modeled EIP-4788
   `BEACON_ROOTS` history (timestamp → parent root, age-checked) *or*
   stay opaque and do not say live verify.

3. **Consume.** After (1)–(2), TopUpGateway / consolidation WC
   admission *consumes* that verify: `admitTopupOrConsolidation` (or
   the live gateway) is ageCheck plus production-GI `verifyAtParent`
   against the identified parent root and the identified combine.
   A `none` lookup still admits nothing.

If (1) or (2) stay named, the parent must not claim live verify. The
existing `production_witness_admission_from_core_gindex` stays a
lemma of the constructor pin.

## Kill-line

- Identified SHA: a mutant `combine` (e.g. swapped operands or
  `· + 1`) fails admission / reconstruction at a production-path
  witness.
- Modeled BEACON_ROOTS: a mutant lookup that ignores the timestamp
  (or returns a constant root) fails the identified-root conjunct.
- If both stay named: do not add a kill-line that pretends they are
  discharged. Keep the existing skip-lookup / wrong-packed-word
  lines as lemmas.

## Non-goals

- Do not treat the TopUpGateway constructor pin as a live-deployment
  identity.
- Do not start the bus.
- Do not claim official consolidation denote success (node 6).
- Toy slots 2/3/4 stay leftover record.

## Files

Own: `Eip4788AnchorChild.lean` / new BEACON_ROOTS module,
`HashIdentificationChild.lean` / `SszCorrespondence.lean` only if
discharging the hyp, `PSszLive1.lean` for the discharged consume
parent, mutants, this brief, YAML assumptions / missing.

## Build

    lake build LidoSRv3.Audit.Guarantees.PSszLive1
    lake build LidoSRv3.Tests.PackN5SszLiveMutants
    lake build LidoSRv3.Tests.PackS1HashMutants
    # plus new BEACON_ROOTS / consume mutants

## Quality gate

YAML theorem is the consume parent or the named hyp discharge.
Kill-line builds for any identified symbol. Do not say live verify
while `eip4788ParentRoot` is opaque.
