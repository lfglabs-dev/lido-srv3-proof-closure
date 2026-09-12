# Finding: A-SHA256-FFI isolated to a mandatory scope boundary — retired from every consumer's assumptions list

**Category:** Assumption isolation (Thomas's requested "scinde les énoncés pour que la partie indépendante soit inconditionnelle").
**Severity:** N/A (bookkeeping — consumer-list boundary tightened; registry entry retained per audit schema).
**Scope:** `A-SHA256-FFI` was declared by `P-SSZ-1`, `P-SSZ-1.deposit-data-root`, `P-SSZ-1.abstract-digest`, `P-SSZ-1.tx-execution-simulation`, and `P-SSZ-LIVE-1`. All 5 consumer citations retired. Registry entry retained (mandatory scope-boundary per `scripts/audit_metadata.py:316`).

## Discharge (scope isolation)

The `A-SHA256-FFI` assumption records that SHA-256 functional
correctness (i.e. that the deployed precompile at address 2
implements FIPS 180-4) is not proved in this project. Its Verity
encoding sits in `Verity.Core.Model.DenoteSha256.sha256_correct` as a
named FIPS assumption a caller must supply if they want to turn the
abstract SHA-256 oracle into a concrete FIPS one.

**Every registered SSZ theorem is already structural or
compositional around the SHA-256 boundary and does not consume
`sha256_correct` at the kernel level.** Each parent's `#print axioms`
output contains only subsets of `{propext, Classical.choice,
Quot.sound}`, with no `sha256_correct` axiom in sight.

This gives the split Thomas requested:

- **Unconditional part** (does not depend on SHA-256 correctness):
  the registered theorems themselves — structural preimage shape,
  digest-chain composition, memory copies, address-2 call sequences,
  byte lengths, revert restoration, well-formed SSZ witness
  correspondence, live-consumer admission. These all fire regardless
  of whether the caller supplies a `sha256_correct` hypothesis.

- **Conditional part** (would depend on SHA-256 correctness): the
  claim "produced digests equal the FIPS SHA-256 of their preimages".
  This is *never claimed* by any registered SSZ theorem. It is
  disclosed as an intentional out-of-scope item in each
  guarantee's `fidelity.missing` array — e.g. P-SSZ-1's missing
  entries include "SHA-256 functional correctness of the opaque
  model/precompile symbol" and "refinement equating the opaque
  sha256 symbol with Sha256Engine.sha256 used by the abstract digest
  child".

## Lean proof

`LidoSRv3/Audit/Provenance/SszSha256Isolation.lean` provides six
orphelinat theorems, all clean under `{propext, Classical.choice,
Quot.sound}`:

1. `ssz1_abstract_parent_ignores_sha256_correctness` — for any
   caller-supplied `Sha256Faithful : Prop`, the registered abstract
   parent `PSsz1.deposit_root_iff` still fires.
2. `ssz1_abstract_parent_applies_universally` — same statement
   without the ignored premise.
3. `ssz1_verity_parent_ignores_sha256_correctness` — for the Verity
   parent `PSsz1.verity_tx_simulates_ssz_encoding`.
4. `deposit_data_root_parent_ignores_sha256_correctness` — for the
   subordinate `source_pinned_config_discharges_deposit_data_root`
   (SHA256_DIGEST_LENGTH pinnedConfig = 32 projection, representative
   of the parent's long conjunctive conclusion).
5. `abstract_digest_parent_ignores_sha256_correctness` — for the
   subordinate `SszAbstractDigest.abstract_digest_refinement`
   (compilation + exact digest composition).
6. `tx_execution_simulation_parent_ignores_sha256_correctness` — for
   the subordinate `SszTxSimulation.digest_preimages_length`
   (structural length claim about the seven-call digest preimage list).

Each theorem body is a single application of the corresponding
registered parent, demonstrating the `Sha256Faithful` premise is
irrelevant.

All six are registered in `LidoSRv3/Audit/Trust.lean` via
`#print axioms`; each depends only on the accepted foundational
axioms.

## Registry retention rationale

`scripts/audit_metadata.py:316` enforces:

```python
require("A-SOLC-TRUSTED" in ids and "A-SHA256-FFI" in ids,
        "explicit solc/SHA-256 trust boundaries are missing")
```

Both `A-SOLC-TRUSTED` and `A-SHA256-FFI` are mandatory in the
assumption registry as scope-boundary disclosures. The registry entry
for `A-SHA256-FFI` is retained with updated `risk` /
`justification` text pointing to the isolation module and disclosing
that no consumer's Lean parents actually depend on it. The consumer
citations are removed because they misrepresented "not proved here"
as "hypothesized here": at the kernel level, no `sha256_correct`
axiom is threaded through any registered parent.

## Boundary preserved

- The five consumers no longer cite `A-SHA256-FFI` in their
  `assumptions` lists. The registry entry is retained as a mandatory
  scope-boundary disclosure per the audit schema.
- Fidelity `missing` gaps that name SHA-256 functional correctness
  explicitly (e.g. P-SSZ-1's "SHA-256 functional correctness of the
  opaque model/precompile symbol") are kept unchanged. They disclose
  the scope exclusion at the fidelity level, where it belongs.
- No claims silently weakened. Registered parent statements and
  proofs are byte-for-byte unchanged. The trust envelope grows only
  by the six axiom-clean orphelinat theorems.

## Actions taken in this commit

- Added `LidoSRv3/Audit/Provenance/SszSha256Isolation.lean` with the
  six orphelinat theorems above.
- Registered the six theorems in `LidoSRv3/Audit/Trust.lean` via
  `#print axioms`.
- Removed `A-SHA256-FFI` from `P-SSZ-1.assumptions`,
  `P-SSZ-1.deposit-data-root.assumptions`,
  `P-SSZ-1.abstract-digest.assumptions`,
  `P-SSZ-1.tx-execution-simulation.assumptions`, and
  `P-SSZ-LIVE-1.assumptions` in `audit/guarantees.yaml`.
- Retained the `A-SHA256-FFI` registry entry in
  `audit/assumptions.yaml` with updated `risk`, `justification`,
  `violation_impact`, `validation`, and `removal_path` text pointing
  to the isolation module and disclosing the scope-boundary
  retention rationale.
- Updated `EXPECTED_CANONICAL_CLAIMS["P-SSZ-1"]` in
  `scripts/audit_metadata.py`.
- Regenerated `audit/STATUS.md`, `audit/ROADMAP.md`,
  `audit/R1-FINAL-AUDITOR-REPORT.md`.
- Advanced `R1_REVIEW_BASE` and refreshed
  `R1_REPORT_INPUT_SHA256["audit/guarantees.yaml"]` (follow-up commit).
